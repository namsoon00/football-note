import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../application/player_level_service.dart';
import '../../application/settings_service.dart';
import '../../application/sport_service.dart';
import '../../application/training_board_service.dart';
import '../../application/training_plan_reminder_service.dart';
import '../../domain/entities/sport_definition.dart';
import '../../domain/entities/training_board.dart';
import '../../domain/repositories/option_repository.dart';
import '../models/training_method_layout.dart';
import '../models/training_board_templates.dart';
import '../utils/pdf_export.dart';
import '../utils/training_sketch_orientation_lock.dart';
import '../widgets/app_bar_action_button.dart';
import '../widgets/app_page_route.dart';
import 'training_board_template_gallery_screen.dart';

class TrainingMethodBoardScreen extends StatefulWidget {
  final String boardTitle;
  final String initialLayoutJson;
  final List<TrainingBoardPreset> presets;
  final ValueChanged<String>? onSaved;
  final OptionRepository? optionRepository;
  final List<String> initialSelectedBoardIds;
  final String? initialBoardId;
  final String? sportId;
  final bool readOnly;

  const TrainingMethodBoardScreen({
    super.key,
    required this.boardTitle,
    required this.initialLayoutJson,
    this.presets = const <TrainingBoardPreset>[],
    this.onSaved,
    this.optionRepository,
    this.initialSelectedBoardIds = const <String>[],
    this.initialBoardId,
    this.sportId,
    this.readOnly = false,
  });

  @override
  State<TrainingMethodBoardScreen> createState() =>
      _TrainingMethodBoardScreenState();
}

class _TrainingMethodBoardScreenState extends State<TrainingMethodBoardScreen>
    with SingleTickerProviderStateMixin {
  late List<_BoardPageState> _pages;
  final TextEditingController _methodController = TextEditingController();
  TrainingBoardService? _managedBoardService;
  List<TrainingBoard> _managedBoards = const <TrainingBoard>[];
  Set<String> _selectedBoardIds = <String>{};
  String? _currentBoardId;
  int _nextId = 1;
  String? _selectedItemId;
  String? _selectedRouteId;
  String? _movingItemId;
  Offset _lastLongPressMoveOffset = Offset.zero;
  bool _penMode = false;
  bool _pathMode = false;
  bool _routeReplaceMode = false;
  _SketchTargetAction? _pendingTargetAction;
  Color _penColor = const Color(0xFF000000);
  List<Offset>? _activeStroke;
  List<Offset>? _activeRoutePoints;
  List<int>? _activeRouteSegmentDurationsMs;
  DateTime? _activeRouteLastPointAt;
  late final AnimationController _playController;
  final GlobalKey _boardPdfBoundaryKey = GlobalKey();
  List<_PlaybackTrack> _playbackTracks = const <_PlaybackTrack>[];
  _PathDrawMode _pathDrawMode = _PathDrawMode.player;
  String _lastSavedLayout = '';
  bool _shouldPromptInitialBoardName = false;
  final _speech = stt.SpeechToText();
  bool _speechInitialized = false;
  bool _speechAvailable = false;
  bool _isListeningMemo = false;
  String _memoRecognizedWords = '';
  bool _memoCommitted = false;
  int _memoSession = 0;
  double _playSpeed = 1.0;
  bool _showLandscapeControls = true;
  bool _showLandscapeMemo = false;
  bool _showPortraitMemo = false;
  bool _showPortraitInspector = true;
  bool _showTacticalOverlay = true;
  bool _showSelectedColorPicker = false;
  int? _registeredNextActionStageIndex;
  Timer? _autoSaveTimer;
  bool _autoSaveInProgress = false;
  bool _pdfExportInProgress = false;

  bool get _isManagedMode => widget.optionRepository != null;
  _BoardPageState get _currentPage => _pages.first;
  AppLocalizations get _l10n => AppLocalizations.of(context)!;
  String get _currentSportIdOrDefault =>
      SportCatalog.normalizeSportId(_currentSportId);

  bool get _hasUnsavedChanges => _serialize() != _lastSavedLayout;

  Future<void> _presentBoardXpAward(
    PlayerLevelAward award, {
    required bool isKo,
  }) async {
    final optionRepository = widget.optionRepository;
    if (optionRepository == null) return;
    final reminderService = TrainingPlanReminderService(
      optionRepository,
      SettingsService(optionRepository)..load(),
    );
    await reminderService.showXpGainAlert(
      gainedXp: award.gainedXp,
      totalXp: award.after.totalXp,
      isKo: isKo,
      sourceLabel: _l10n.trainingXpSourceTrainingSketch,
    );
    if (award.didLevelUp) {
      await reminderService.showLevelUpAlert(
        level: award.after.level,
        isKo: isKo,
      );
    }
  }

  T? _firstWhereOrNull<T>(Iterable<T> items, bool Function(T) test) {
    for (final item in items) {
      if (test(item)) return item;
    }
    return null;
  }

  void _scheduleAutoSave() {
    if (widget.readOnly) return;
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 800), () {
      unawaited(_runAutoSave());
    });
  }

  Future<void> _runAutoSave() async {
    if (widget.readOnly || _autoSaveInProgress || !_hasUnsavedChanges) {
      return;
    }
    if (_playbackTracks.isNotEmpty) {
      _scheduleAutoSave();
      return;
    }
    _autoSaveInProgress = true;
    try {
      final isKo = mounted
          ? Localizations.localeOf(context).languageCode == 'ko'
          : false;
      await _saveBoard(
        isKo,
        showFeedback: false,
        awardXp: true,
        showAwardFeedback: false,
      );
    } finally {
      _autoSaveInProgress = false;
      if (mounted && _hasUnsavedChanges) {
        _scheduleAutoSave();
      }
    }
  }

  Future<void> _exportCurrentSketchPdf() async {
    if (_pdfExportInProgress) return;
    setState(() => _pdfExportInProgress = true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      final pngBytes = await captureRepaintBoundaryPng(_boardPdfBoundaryKey);
      await sharePngAsPdf(
        pngImage: pngBytes,
        filename: timestampedPdfFilename('training-sketch'),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_l10n.trainingSketchPdfExportedSnack)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_l10n.trainingSketchPdfExportFailedSnack)),
      );
    } finally {
      if (mounted) {
        setState(() => _pdfExportInProgress = false);
      } else {
        _pdfExportInProgress = false;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    unawaited(_setSketchOrientationLock(landscape: true));
    if (_isManagedMode) {
      _managedBoardService = TrainingBoardService(
        widget.optionRepository!,
        sportId: widget.sportId,
      );
      _selectedBoardIds = widget.initialSelectedBoardIds.toSet();
      _restoreManagedBoardState();
    } else {
      _restoreStandaloneBoard();
    }
    _playController = AnimationController(vsync: this)
      ..addListener(_onPlayTick)
      ..addStatusListener(_onPlayStatusChanged);
    _methodController.text = _currentPage.methodText;
    _lastSavedLayout = _serialize();
    _syncCurrentPageRouteColors();
    if (_shouldPromptInitialBoardName && !widget.readOnly) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _promptForInitialBoardName();
      });
    }
    if (_isManagedMode && _currentBoardId == null && !widget.readOnly) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _promptForManagedBoardCreation(isInitialFlow: true);
      });
    }
  }

  void _restoreStandaloneBoard() {
    final layout = TrainingMethodLayout.decode(widget.initialLayoutJson);
    final page = layout.pages.isEmpty ? null : layout.pages.first;
    final defaultBoardName =
        widget.boardTitle.trim().isEmpty ? 'Board 1' : widget.boardTitle.trim();
    _pages = <_BoardPageState>[
      _BoardPageState(
        name: page == null
            ? defaultBoardName
            : (page.name.trim().isEmpty ? defaultBoardName : page.name),
        methodText: page?.methodText ?? '',
        items: (page?.items ?? const <TrainingMethodItem>[])
            .map(
              (e) => _BoardItem(
                id: e.id.trim().isEmpty ? _nextBoardItemId() : e.id,
                type: _boardItemTypeFromString(e.type) ?? _BoardItemType.cone,
                x: e.x,
                y: e.y,
                size: 32,
                rotationDeg: e.rotationDeg,
                color: Color(e.colorValue),
              ),
            )
            .toList(growable: true),
        strokes: (page?.strokes ?? const <TrainingMethodStroke>[])
            .map(
              (stroke) => _BoardStroke(
                points: stroke.points
                    .map((point) => Offset(point.x, point.y))
                    .toList(growable: false),
                color: Color(stroke.colorValue),
                width: stroke.width,
              ),
            )
            .toList(growable: true),
        routes: (page?.routes ?? const <TrainingMethodRoute>[])
            .map(
              (route) => _BoardRoute(
                id: route.id.trim().isEmpty ? _nextBoardRouteId() : route.id,
                kind: _pathDrawModeFromRouteKind(route.kind),
                linkedItemId: route.linkedItemId,
                actorItemId: route.actorItemId,
                targetItemId: route.targetItemId,
                points: route.points
                    .map((point) => Offset(point.x, point.y))
                    .toList(growable: true),
                segmentDurationsMs: route.segmentDurationsMs.toList(
                  growable: true,
                ),
                stageIndex: route.stageIndex,
                color: Color(route.colorValue),
                width: route.width,
              ),
            )
            .toList(growable: true),
      ),
    ];
    _normalizeCurrentPageRoutes();
    _syncCurrentPageRouteColors();
    if (page == null) {
      _shouldPromptInitialBoardName = widget.boardTitle.trim().isEmpty;
    }
  }

  void _restoreManagedBoardState() {
    _managedBoards = _managedBoardService!.allBoards();
    _selectedBoardIds = _selectedBoardIds
        .where((id) => _managedBoards.any((board) => board.id == id))
        .toSet();
    final linkedBoards = _managedBoards
        .where((board) => _selectedBoardIds.contains(board.id))
        .toList(growable: false);
    if (linkedBoards.isEmpty) {
      _pages = <_BoardPageState>[_emptyBoardPage(widget.boardTitle)];
      _currentBoardId = null;
      _shouldPromptInitialBoardName = false;
      return;
    }
    final requestedId = widget.initialBoardId?.trim();
    final initialBoard =
        _firstWhereOrNull(linkedBoards, (board) => board.id == requestedId) ??
            linkedBoards.first;
    _loadBoard(initialBoard);
  }

  _BoardPageState _emptyBoardPage(String fallbackTitle) {
    final title =
        fallbackTitle.trim().isEmpty ? 'Board 1' : fallbackTitle.trim();
    return _BoardPageState(
      name: title,
      methodText: '',
      items: <_BoardItem>[],
      strokes: <_BoardStroke>[],
      routes: <_BoardRoute>[],
    );
  }

  void _loadBoard(TrainingBoard board) {
    final layout = TrainingMethodLayout.decode(board.layoutJson);
    final page = layout.pages.isEmpty ? null : layout.pages.first;
    _pages = <_BoardPageState>[
      _BoardPageState(
        name: page == null
            ? board.title
            : (page.name.trim().isEmpty ? board.title : page.name),
        methodText: page?.methodText ?? '',
        items: (page?.items ?? const <TrainingMethodItem>[])
            .map(
              (e) => _BoardItem(
                id: e.id.trim().isEmpty ? _nextBoardItemId() : e.id,
                type: _boardItemTypeFromString(e.type) ?? _BoardItemType.cone,
                x: e.x,
                y: e.y,
                size: 32,
                rotationDeg: e.rotationDeg,
                color: Color(e.colorValue),
              ),
            )
            .toList(growable: true),
        strokes: (page?.strokes ?? const <TrainingMethodStroke>[])
            .map(
              (stroke) => _BoardStroke(
                points: stroke.points
                    .map((point) => Offset(point.x, point.y))
                    .toList(growable: false),
                color: Color(stroke.colorValue),
                width: stroke.width,
              ),
            )
            .toList(growable: true),
        routes: (page?.routes ?? const <TrainingMethodRoute>[])
            .map(
              (route) => _BoardRoute(
                id: route.id.trim().isEmpty ? _nextBoardRouteId() : route.id,
                kind: _pathDrawModeFromRouteKind(route.kind),
                linkedItemId: route.linkedItemId,
                actorItemId: route.actorItemId,
                targetItemId: route.targetItemId,
                points: route.points
                    .map((point) => Offset(point.x, point.y))
                    .toList(growable: true),
                segmentDurationsMs: route.segmentDurationsMs.toList(
                  growable: true,
                ),
                stageIndex: route.stageIndex,
                color: Color(route.colorValue),
                width: route.width,
              ),
            )
            .toList(growable: true),
      ),
    ];
    _normalizeCurrentPageRoutes();
    _syncCurrentPageRouteColors();
    _currentBoardId = board.id;
    _selectedItemId = null;
    _selectedRouteId = null;
    _showSelectedColorPicker = false;
    _penMode = false;
    _pathMode = false;
    _activeStroke = null;
    _activeRoutePoints = null;
    _activeRouteSegmentDurationsMs = null;
    _activeRouteLastPointAt = null;
    _routeReplaceMode = false;
    _playbackTracks = const <_PlaybackTrack>[];
    _methodController.text = _currentPage.methodText;
    _lastSavedLayout = _serialize();
  }

  Future<String?> _showBoardNameDialog({
    required bool isKo,
    required String titleKo,
    required String titleEn,
    required String confirmKo,
    required String confirmEn,
    String initialValue = '',
  }) async {
    var typedName = initialValue;
    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        final availableWidth = MediaQuery.sizeOf(context).width - 96;
        final fieldWidth = availableWidth.clamp(280.0, 420.0).toDouble();
        return AlertDialog(
          title: Text(isKo ? titleKo : titleEn),
          content: SizedBox(
            width: fieldWidth,
            child: TextFormField(
              initialValue: typedName,
              onChanged: (value) => typedName = value,
              autofocus: true,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: l10n.trainingSketchBoardNameLabel,
                hintText: l10n.trainingSketchBoardNameHint,
                border: const OutlineInputBorder(),
              ),
              onFieldSubmitted: (value) =>
                  Navigator.of(context).pop(value.trim()),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(typedName.trim()),
              child: Text(isKo ? confirmKo : confirmEn),
            ),
          ],
        );
      },
    );
    final trimmed = (name ?? '').trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
  }

  Future<void> _promptForInitialBoardName() async {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final name = await _showBoardNameDialog(
      isKo: isKo,
      titleKo: '스케치 추가',
      titleEn: 'Add sketch',
      confirmKo: '추가',
      confirmEn: 'Add',
    );
    if (!mounted || name == null) return;
    setState(() {
      _currentPage.name = name;
    });
  }

  Future<void> _promptForManagedBoardCreation({
    bool isInitialFlow = false,
  }) async {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    if (!isInitialFlow && _hasUnsavedChanges) {
      final action = await _showPendingBoardActionDialog(isKo);
      if (!mounted || action == null || action == _PendingBoardAction.cancel) {
        return;
      }
      if (action == _PendingBoardAction.save) {
        final saved = await _saveBoard(isKo, showFeedback: false);
        if (!mounted || !saved) return;
      }
    }
    final template = await showTrainingBoardTemplatePicker(
      context,
      onOpenGallery: _openTemplateGallery,
      sportId: _currentSportId,
    );
    if (!mounted) return;
    if (template == null) {
      if (isInitialFlow) {
        Navigator.of(context).pop(widget.initialSelectedBoardIds);
      }
      return;
    }
    final title = await _showBoardNameDialog(
      isKo: isKo,
      titleKo: '훈련 스케치 제목',
      titleEn: 'Training sketch title',
      confirmKo: '생성',
      confirmEn: 'Create',
      initialValue: '',
    );
    if (!mounted) return;
    if (title == null) {
      if (isInitialFlow) {
        Navigator.of(context).pop(widget.initialSelectedBoardIds);
      }
      return;
    }
    final layout = template.buildLayout(title);
    final created = await _managedBoardService!.createBoard(
      title: title,
      layoutJson: layout.encode(),
    );
    if (!mounted) return;
    setState(() {
      _managedBoards = _managedBoardService!.allBoards();
      _selectedBoardIds.add(created.id);
      _loadBoard(created);
    });
    final award = await PlayerLevelService(
      widget.optionRepository!,
      sportId: widget.sportId,
    ).awardForBoardSaved(
      boardId: created.id,
      boardTitle: created.title,
      savedAt: created.updatedAt,
      created: true,
    );
    await _presentBoardXpAward(award, isKo: isKo);
  }

  String _serialize() {
    final p = _currentPage;
    final layout = TrainingMethodLayout(
      pages: <TrainingMethodPage>[
        TrainingMethodPage(
          name: p.name,
          methodText: p.methodText,
          items: p.items
              .map(
                (e) => TrainingMethodItem(
                  id: e.id,
                  type: e.type.name,
                  x: e.x,
                  y: e.y,
                  size: e.size,
                  rotationDeg: e.rotationDeg,
                  colorValue: e.color.toARGB32(),
                ),
              )
              .toList(growable: false),
          strokes: p.strokes
              .map(
                (stroke) => TrainingMethodStroke(
                  points: stroke.points
                      .map(
                        (point) =>
                            TrainingMethodPoint(x: point.dx, y: point.dy),
                      )
                      .toList(growable: false),
                  colorValue: stroke.color.toARGB32(),
                  width: stroke.width,
                ),
              )
              .toList(growable: false),
          routes: p.routes
              .map(
                (route) => TrainingMethodRoute(
                  id: route.id,
                  kind: _routeKindFromPathDrawMode(route.kind),
                  linkedItemId: route.linkedItemId,
                  actorItemId: route.actorItemId,
                  targetItemId: route.targetItemId,
                  points: route.points
                      .map(
                        (point) =>
                            TrainingMethodPoint(x: point.dx, y: point.dy),
                      )
                      .toList(growable: false),
                  segmentDurationsMs: route.segmentDurationsMs.toList(
                    growable: false,
                  ),
                  stageIndex: route.stageIndex,
                  colorValue: route.color.toARGB32(),
                  width: route.width,
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
    return layout.encode();
  }

  _BoardItem? get _selectedItem {
    final id = _selectedItemId;
    if (id == null) return null;
    for (final item in _currentPage.items) {
      if (item.id == id) return item;
    }
    return null;
  }

  _BoardRoute? get _selectedRoute {
    final id = _selectedRouteId;
    if (id == null) return null;
    return _firstWhereOrNull(_currentPage.routes, (route) => route.id == id);
  }

  int _routeableItemCount(_PathDrawMode kind) {
    return _routeableItems(kind).length;
  }

  List<_BoardItem> _routeableItems(_PathDrawMode kind) {
    final expectedType = _boardItemTypeForRouteKind(kind);
    return _currentPage.items
        .where((item) => item.type == expectedType)
        .toList(growable: false);
  }

  String _routeGroupTitle(_PathDrawMode kind) {
    return switch (kind) {
      _PathDrawMode.player => _l10n.trainingSketchPlayerRoutesTitle,
      _PathDrawMode.ball => _l10n.trainingSketchBallRoutesTitle,
    };
  }

  IconData _routeGroupIcon(_PathDrawMode kind) {
    return switch (kind) {
      _PathDrawMode.player => Icons.person,
      _PathDrawMode.ball => Icons.sports_soccer,
    };
  }

  Color _routeGroupAccentColor(_PathDrawMode kind) {
    return switch (kind) {
      _PathDrawMode.player => _playerItemColors.first,
      _PathDrawMode.ball => _ballItemColors.first,
    };
  }

  List<Color> _colorChoicesForItemType(_BoardItemType? type) {
    return switch (type) {
      _BoardItemType.player => _playerItemColors,
      _BoardItemType.ball => _ballItemColors,
      _ => _presetColors,
    };
  }

  List<_BoardToolSpec> _boardToolSpecsForCurrentSport() {
    final sportId = _currentSportIdOrDefault;
    final types = switch (sportId) {
      SportCatalog.baseballId => const <_BoardItemType>[
          _BoardItemType.player,
          _BoardItemType.ball,
          _BoardItemType.base,
          _BoardItemType.target,
          _BoardItemType.cone,
        ],
      SportCatalog.basketballId => const <_BoardItemType>[
          _BoardItemType.player,
          _BoardItemType.ball,
          _BoardItemType.basket,
          _BoardItemType.target,
          _BoardItemType.cone,
        ],
      SportCatalog.tennisId => const <_BoardItemType>[
          _BoardItemType.player,
          _BoardItemType.ball,
          _BoardItemType.target,
          _BoardItemType.cone,
        ],
      _ => const <_BoardItemType>[
          _BoardItemType.player,
          _BoardItemType.ball,
          _BoardItemType.cone,
          _BoardItemType.hurdle,
          _BoardItemType.ladder,
        ],
    };
    return types
        .map(
          (type) => _BoardToolSpec(
            type: type,
            icon: _boardItemIcon(type, sportId: sportId),
            label: _boardToolLabel(type),
          ),
        )
        .toList(growable: false);
  }

  String _boardToolLabel(_BoardItemType type) {
    final l10n = _l10n;
    return switch (type) {
      _BoardItemType.cone => l10n.trainingSketchConeButton,
      _BoardItemType.hurdle => l10n.trainingSketchLowHurdleButton,
      _BoardItemType.player => l10n.trainingSketchPlayerButton,
      _BoardItemType.ball => l10n.trainingSketchBallButton,
      _BoardItemType.ladder => l10n.trainingSketchLadderButton,
      _BoardItemType.target => l10n.trainingSketchTargetButton,
      _BoardItemType.base => l10n.trainingSketchBaseButton,
      _BoardItemType.basket => l10n.trainingSketchBasketButton,
    };
  }

  _BoardItem? _itemById(String id) {
    return _firstWhereOrNull(_currentPage.items, (item) => item.id == id);
  }

  _BoardItem? _linkedItemForRoute(_BoardRoute route) {
    final linkedItemId = route.linkedItemId;
    if (linkedItemId == null) return null;
    final item = _itemById(linkedItemId);
    if (item == null) return null;
    return item.type == _boardItemTypeForRouteKind(route.kind) ? item : null;
  }

  _BoardItem? _nearestRouteItem({
    required _PathDrawMode kind,
    required List<Offset> points,
    Set<String> excludedItemIds = const <String>{},
    bool allowExcludedFallback = false,
  }) {
    List<_BoardItem> candidates = _currentPage.items
        .where(
          (item) =>
              item.type == _boardItemTypeForRouteKind(kind) &&
              !excludedItemIds.contains(item.id),
        )
        .toList(growable: false);
    if (candidates.isEmpty && allowExcludedFallback) {
      candidates = _currentPage.items
          .where((item) => item.type == _boardItemTypeForRouteKind(kind))
          .toList(growable: false);
    }
    if (candidates.isEmpty) return null;
    if (points.isEmpty) return candidates.first;
    final start = points.first;
    candidates.sort((a, b) {
      final aDistance =
          math.pow(a.x - start.dx, 2) + math.pow(a.y - start.dy, 2);
      final bDistance =
          math.pow(b.x - start.dx, 2) + math.pow(b.y - start.dy, 2);
      return aDistance.compareTo(bDistance);
    });
    return candidates.first;
  }

  _BoardItem? _resolveRouteItem({
    required _PathDrawMode kind,
    required List<Offset> points,
    String? preferredItemId,
    Set<String> excludedItemIds = const <String>{},
    bool allowExcludedFallback = false,
  }) {
    final preferred =
        preferredItemId == null ? null : _itemById(preferredItemId);
    if (preferred != null &&
        preferred.type == _boardItemTypeForRouteKind(kind)) {
      return preferred;
    }
    return _nearestRouteItem(
      kind: kind,
      points: points,
      excludedItemIds: excludedItemIds,
      allowExcludedFallback: allowExcludedFallback,
    );
  }

  Set<String> _linkedRouteItemIds(
    _PathDrawMode kind, {
    String? excludingRouteId,
  }) {
    return _currentPage.routes
        .where(
          (route) =>
              route.kind == kind &&
              route.id != excludingRouteId &&
              route.linkedItemId != null,
        )
        .map((route) => route.linkedItemId!)
        .toSet();
  }

  _BoardRoute? _routeForItem(
    String itemId,
    _PathDrawMode kind, {
    String? excludingRouteId,
  }) {
    return _firstWhereOrNull(
      _currentPage.routes,
      (route) =>
          route.kind == kind &&
          route.id != excludingRouteId &&
          route.linkedItemId == itemId,
    );
  }

  _BoardRoute? _routeToUpdateForPath(_PathDrawMode kind) {
    final selectedRoute = _selectedRoute;
    if (_routeReplaceMode &&
        selectedRoute != null &&
        selectedRoute.kind == kind) {
      return selectedRoute;
    }
    final selectedItem = _selectedItem;
    if (selectedItem == null ||
        selectedItem.type != _boardItemTypeForRouteKind(kind)) {
      return null;
    }
    return _routeForItem(selectedItem.id, kind);
  }

  Offset _itemPosition(_BoardItem item) => Offset(item.x, item.y);

  Offset _itemActionPoint(_BoardItem item) {
    if (item.type == _BoardItemType.player) {
      final route = _routeForItem(item.id, _PathDrawMode.player);
      if (route != null && route.points.isNotEmpty) {
        return route.points.last;
      }
    }
    return _itemPosition(item);
  }

  Offset _boardPointFromLocal(
    Offset localPosition,
    double width,
    double height,
  ) {
    return Offset(
      (localPosition.dx / width).clamp(0.0, 1.0).toDouble(),
      (localPosition.dy / height).clamp(0.0, 1.0).toDouble(),
    );
  }

  Offset _clampedBoardPoint(double x, double y) {
    return Offset(
      x.clamp(0.04, 0.96).toDouble(),
      y.clamp(0.04, 0.96).toDouble(),
    );
  }

  _BoardItem? _nearestItemOfType(
    _BoardItemType type,
    Offset origin, {
    String? excludingId,
  }) {
    final candidates = _currentPage.items
        .where((item) => item.type == type && item.id != excludingId)
        .toList(growable: false);
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) {
      final aDistance =
          math.pow(a.x - origin.dx, 2) + math.pow(a.y - origin.dy, 2);
      final bDistance =
          math.pow(b.x - origin.dx, 2) + math.pow(b.y - origin.dy, 2);
      return aDistance.compareTo(bDistance);
    });
    return candidates.first;
  }

  List<_BoardItem> _itemsOfType(_BoardItemType type, {String? excludingId}) {
    return _currentPage.items
        .where((item) => item.type == type && item.id != excludingId)
        .toList(growable: false);
  }

  int _itemIndexOfType(_BoardItem item) {
    final items = _itemsOfType(item.type);
    final index = items.indexWhere((entry) => entry.id == item.id);
    return index < 0 ? 1 : index + 1;
  }

  _BoardItem? _controlledBallForPlayer(_BoardItem player) {
    final balls = _itemsOfType(_BoardItemType.ball).where((ball) {
      final latestRoute = _latestBallRouteForBall(ball);
      return latestRoute == null ||
          _ballRouteGivesPlayerPossession(latestRoute, player);
    }).toList(growable: false);
    if (balls.isEmpty) return null;
    balls.sort((a, b) {
      final playerPosition = _itemPosition(player);
      final aDistance = (_itemPosition(a) - playerPosition).distance;
      final bDistance = (_itemPosition(b) - playerPosition).distance;
      return aDistance.compareTo(bDistance);
    });
    final nearest = balls.first;
    return (_itemPosition(nearest) - _itemPosition(player)).distance <=
            _ballPossessionRadius
        ? nearest
        : null;
  }

  _BoardItem? _nearestPlayerToPoint(Offset point, {required double radius}) {
    final players = _itemsOfType(_BoardItemType.player);
    if (players.isEmpty) return null;
    players.sort((a, b) {
      final aDistance = (_itemPosition(a) - point).distance;
      final bDistance = (_itemPosition(b) - point).distance;
      return aDistance.compareTo(bDistance);
    });
    final nearest = players.first;
    return (_itemPosition(nearest) - point).distance <= radius ? nearest : null;
  }

  _BoardItem? _currentBallOwner(_BoardItem ball) {
    final latestRoute = _latestBallRouteForBall(ball);
    if (latestRoute == null) {
      return _nearestPlayerToPoint(
        _itemPosition(ball),
        radius: _ballPossessionRadius,
      );
    }
    final targetItemId = latestRoute.targetItemId;
    if (targetItemId != null) {
      final target = _itemById(targetItemId);
      if (target != null &&
          target.type == _BoardItemType.player &&
          _ballRouteGivesPlayerPossession(latestRoute, target)) {
        return target;
      }
      return null;
    }
    for (final player in _itemsOfType(_BoardItemType.player)) {
      if (_ballRouteGivesPlayerPossession(latestRoute, player)) {
        return player;
      }
    }
    return null;
  }

  bool _hasBallOwnedByAnotherPlayer(_BoardItem player) {
    return _itemsOfType(_BoardItemType.ball).any((ball) {
      final owner = _currentBallOwner(ball);
      return owner != null && owner.id != player.id;
    });
  }

  bool _canStartBallActionForPlayer(_BoardItem player) {
    return _playerHasBallForFlow(player) ||
        !_hasBallOwnedByAnotherPlayer(player);
  }

  void _showBallPossessionRequiredSnackBar(_BoardItem player) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _l10n.trainingSketchBallPossessionRequiredSnack(
            _stageItemLabel(player),
          ),
        ),
      ),
    );
  }

  _BoardRoute? _latestBallRouteForBall(_BoardItem ball) {
    final routes = _currentPage.routes
        .where(
          (route) =>
              route.kind == _PathDrawMode.ball &&
              route.linkedItemId == ball.id &&
              route.points.length >= 2,
        )
        .toList(growable: false);
    if (routes.isEmpty) return null;
    routes.sort((a, b) {
      final stageCompare = _normalizedRouteStageIndex(
        a.stageIndex,
      ).compareTo(_normalizedRouteStageIndex(b.stageIndex));
      if (stageCompare != 0) return stageCompare;
      return _currentPage.routes.indexOf(a).compareTo(
            _currentPage.routes.indexOf(b),
          );
    });
    return routes.last;
  }

  Offset _directionalBoardPoint({
    required Offset origin,
    required Offset? toward,
    required double distance,
    required Offset fallback,
  }) {
    final delta = toward == null ? Offset.zero : toward - origin;
    if (delta.distance < 0.01) {
      return _clampedBoardPoint(
        origin.dx + fallback.dx,
        origin.dy + fallback.dy,
      );
    }
    final direction = delta / delta.distance;
    return _clampedBoardPoint(
      origin.dx + (direction.dx * distance),
      origin.dy + (direction.dy * distance),
    );
  }

  Offset _ballCarryPointFromOrigin(Offset origin, {Offset? toward}) {
    final offsetX = origin.dx > 0.82 ? -0.07 : 0.07;
    return _directionalBoardPoint(
      origin: origin,
      toward: toward,
      distance: 0.07,
      fallback: Offset(offsetX, 0.024),
    );
  }

  Offset _ballCarryPointForPlayer(_BoardItem player, {Offset? toward}) {
    return _ballCarryPointFromOrigin(_itemPosition(player), toward: toward);
  }

  void _placeBallInFrontOfPlayer(
    _BoardItem player,
    _BoardItem ball, {
    Offset? toward,
  }) {
    final ballPoint = _ballCarryPointForPlayer(player, toward: toward);
    ball
      ..x = ballPoint.dx
      ..y = ballPoint.dy;
  }

  _BoardItem _createControlledBallForPlayer(
    _BoardItem player, {
    Offset? toward,
  }) {
    final ballPoint = _ballCarryPointForPlayer(player, toward: toward);
    final ball = _BoardItem(
      id: _nextBoardItemId(),
      type: _BoardItemType.ball,
      x: ballPoint.dx,
      y: ballPoint.dy,
      size: 32,
      rotationDeg: 0,
      color: _nextItemColor(_BoardItemType.ball),
    );
    _currentPage.items.add(ball);
    return ball;
  }

  bool _requiresBallTargetAction(_SketchTargetAction action) {
    return switch (action) {
      _SketchTargetAction.move ||
      _SketchTargetAction.receiveMove ||
      _SketchTargetAction.returnMove ||
      _SketchTargetAction.overlap ||
      _SketchTargetAction.cut ||
      _SketchTargetAction.screen ||
      _SketchTargetAction.coneTurn ||
      _SketchTargetAction.coneJump ||
      _SketchTargetAction.hurdleJump ||
      _SketchTargetAction.runBase ||
      _SketchTargetAction.fielding ||
      _SketchTargetAction.recover =>
        false,
      _SketchTargetAction.pass ||
      _SketchTargetAction.passAndMove ||
      _SketchTargetAction.dribble ||
      _SketchTargetAction.shot ||
      _SketchTargetAction.cross ||
      _SketchTargetAction.drive ||
      _SketchTargetAction.throwBall ||
      _SketchTargetAction.serve ||
      _SketchTargetAction.rally =>
        true,
    };
  }

  bool _requiresPlayerTargetAction(_SketchTargetAction action) {
    return switch (action) {
      _SketchTargetAction.move ||
      _SketchTargetAction.passAndMove ||
      _SketchTargetAction.receiveMove ||
      _SketchTargetAction.returnMove ||
      _SketchTargetAction.overlap ||
      _SketchTargetAction.cut ||
      _SketchTargetAction.screen ||
      _SketchTargetAction.coneTurn ||
      _SketchTargetAction.coneJump ||
      _SketchTargetAction.hurdleJump ||
      _SketchTargetAction.runBase ||
      _SketchTargetAction.fielding ||
      _SketchTargetAction.recover =>
        true,
      _SketchTargetAction.pass ||
      _SketchTargetAction.dribble ||
      _SketchTargetAction.shot ||
      _SketchTargetAction.cross ||
      _SketchTargetAction.drive ||
      _SketchTargetAction.throwBall ||
      _SketchTargetAction.serve ||
      _SketchTargetAction.rally =>
        false,
    };
  }

  _BoardItem? _playerForTargetAction(_BoardItem selected) {
    return selected.type == _BoardItemType.player ? selected : null;
  }

  _BoardItem? _ballForTargetAction(_BoardItem selected, {Offset? target}) {
    if (selected.type != _BoardItemType.player) return null;
    final controlledBall = _controlledBallForPlayer(selected);
    if (controlledBall != null) {
      _placeBallInFrontOfPlayer(selected, controlledBall, toward: target);
      return controlledBall;
    }
    if (!_canStartBallActionForPlayer(selected)) {
      return null;
    }
    final ball = _createControlledBallForPlayer(selected, toward: target);
    _placeBallInFrontOfPlayer(selected, ball, toward: target);
    return ball;
  }

  bool _ballRouteEndsNearPlayer(_BoardRoute route, _BoardItem player) {
    if (route.points.isEmpty) return false;
    final playerRoute = _routeForItem(player.id, _PathDrawMode.player);
    final candidatePoints = <Offset>[
      _itemPosition(player),
      if (playerRoute != null && playerRoute.points.isNotEmpty)
        playerRoute.points.last,
    ];
    final routeEnd = route.points.last;
    return candidatePoints.any(
      (point) => (point - routeEnd).distance <= _ballPossessionRadius,
    );
  }

  bool _ballRouteGivesPlayerPossession(
    _BoardRoute route,
    _BoardItem player,
  ) {
    if (route.kind != _PathDrawMode.ball ||
        route.linkedItemId == null ||
        route.points.length < 2) {
      return false;
    }
    final targetItemId = route.targetItemId;
    if (targetItemId != null) {
      return targetItemId == player.id;
    }
    return _ballRouteEndsNearPlayer(route, player);
  }

  bool _playerHasBallForFlow(_BoardItem player) {
    return _itemsOfType(_BoardItemType.ball).any(
      (ball) => _currentBallOwner(ball)?.id == player.id,
    );
  }

  bool _canUsePlayerFlowBallActions(_BoardItem player) {
    return _canStartBallActionForPlayer(player);
  }

  bool _canUsePlayerFlowMovementAction(
    _BoardItem player,
    _SketchTargetAction action,
  ) {
    final hasBall = _playerHasBallForFlow(player);
    if (hasBall) {
      return switch (action) {
        _SketchTargetAction.receiveMove ||
        _SketchTargetAction.overlap ||
        _SketchTargetAction.cut ||
        _SketchTargetAction.screen =>
          false,
        _ => true,
      };
    }
    if (action == _SketchTargetAction.receiveMove) {
      return _currentPage.routes.any(
        (route) => route.kind == _PathDrawMode.ball && route.points.length >= 2,
      );
    }
    return true;
  }

  _BoardRoute? _currentBallRouteForPlayer(_BoardItem player) {
    final selectedRoute = _selectedRoute;
    final selectedLinkedBall = selectedRoute?.linkedItemId == null
        ? null
        : _itemById(selectedRoute!.linkedItemId!);
    if (selectedRoute != null &&
        selectedLinkedBall?.type == _BoardItemType.ball &&
        _latestBallRouteForBall(selectedLinkedBall!)?.id == selectedRoute.id &&
        _ballRouteGivesPlayerPossession(selectedRoute, player)) {
      return selectedRoute;
    }

    final candidates = _itemsOfType(_BoardItemType.ball)
        .map(_latestBallRouteForBall)
        .whereType<_BoardRoute>()
        .where((route) => _ballRouteGivesPlayerPossession(route, player))
        .toList(growable: false);
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) {
      final stageCompare = _normalizedRouteStageIndex(
        a.stageIndex,
      ).compareTo(_normalizedRouteStageIndex(b.stageIndex));
      if (stageCompare != 0) return stageCompare;
      return _currentPage.routes.indexOf(a).compareTo(
            _currentPage.routes.indexOf(b),
          );
    });
    return candidates.last;
  }

  Offset _playerFlowOriginPoint(_BoardItem player) {
    final route = _routeForItem(player.id, _PathDrawMode.player);
    if (route != null && route.points.isNotEmpty) {
      return route.points.last;
    }
    return _itemPosition(player);
  }

  Offset _suggestedPassReceiverPoint(_BoardItem player) {
    final origin = _playerFlowOriginPoint(player);
    final xStep = origin.dx < 0.68 ? 0.24 : -0.24;
    final yOffsets = <double>[0, -0.10, 0.10, -0.18, 0.18];
    final players = _itemsOfType(_BoardItemType.player);
    Offset bestPoint = _clampedBoardPoint(origin.dx + xStep, origin.dy);
    var bestDistance = -1.0;
    for (final yOffset in yOffsets) {
      final candidate = _clampedBoardPoint(
        origin.dx + xStep,
        origin.dy + yOffset,
      );
      final nearestDistance = players.fold<double>(1.0, (nearest, item) {
        if (item.id == player.id) return nearest;
        return math.min(nearest, (_itemPosition(item) - candidate).distance);
      });
      if (nearestDistance > bestDistance) {
        bestDistance = nearestDistance;
        bestPoint = candidate;
      }
    }
    return bestPoint;
  }

  _BoardItem _createPassReceiverForPlayer(_BoardItem player) {
    final point = _suggestedPassReceiverPoint(player);
    final receiver = _BoardItem(
      id: _nextBoardItemId(),
      type: _BoardItemType.player,
      x: point.dx,
      y: point.dy,
      size: 32,
      rotationDeg: 0,
      color: _nextItemColor(_BoardItemType.player),
    );
    _currentPage.items.add(receiver);
    return receiver;
  }

  _PlayerBallPossession? _ballPossessionForNextPlayerAction(
    _BoardItem player, {
    Offset? target,
    Offset? startOverride,
  }) {
    final currentRoute = _currentBallRouteForPlayer(player);
    if (currentRoute != null) {
      final linkedBallId = currentRoute.linkedItemId;
      final linkedBall = linkedBallId == null ? null : _itemById(linkedBallId);
      if (linkedBall != null && linkedBall.type == _BoardItemType.ball) {
        return _PlayerBallPossession(
          ball: linkedBall,
          start: startOverride ?? currentRoute.points.last,
        );
      }
    }

    if (!_canStartBallActionForPlayer(player)) {
      _showBallPossessionRequiredSnackBar(player);
      return null;
    }
    final ball = _ballForTargetAction(player, target: target);
    if (ball == null) return null;
    return _PlayerBallPossession(
      ball: ball,
      start: startOverride ?? _itemPosition(ball),
    );
  }

  int _suggestedStageForNewRoute(_PathDrawMode _) {
    final registered = _registeredStageForNextAction();
    if (registered != null) return registered;
    final selectedRoute = _selectedRoute;
    if (selectedRoute != null && selectedRoute.points.length >= 2) {
      return _normalizedRouteStageIndex(selectedRoute.stageIndex + 1);
    }
    return _nextGlobalStageForNewAction();
  }

  int _pairedCarryStageFor({
    required _BoardItem player,
    required _BoardItem ball,
  }) {
    final playerRoute = _routeForItem(player.id, _PathDrawMode.player);
    final ballRoute = _routeForItem(ball.id, _PathDrawMode.ball);
    return _normalizedRouteStageIndex(
      playerRoute?.stageIndex ?? ballRoute?.stageIndex ?? 1,
    );
  }

  _BoardRoute _upsertRouteForItem({
    required _PathDrawMode kind,
    required _BoardItem item,
    required List<Offset> points,
    List<int>? segmentDurationsMs,
    int? stageIndex,
    String? actorItemId,
    String? targetItemId,
    _BoardRoute? replacementRoute,
    bool createNewRoute = false,
  }) {
    final route = replacementRoute ??
        (createNewRoute ? null : _routeForItem(item.id, kind));
    final durations = _normalizedRouteSegmentDurations(
      pointCount: points.length,
      rawDurationsMs: segmentDurationsMs,
    );
    final nextStage = _normalizedRouteStageIndex(
      stageIndex ?? route?.stageIndex ?? _suggestedStageForNewRoute(kind),
    );
    if (route != null) {
      route.points
        ..clear()
        ..addAll(points);
      route.segmentDurationsMs
        ..clear()
        ..addAll(durations);
      route.linkedItemId = item.id;
      route.actorItemId = actorItemId ?? route.actorItemId;
      route.targetItemId = targetItemId;
      route.stageIndex = nextStage;
      route.color = item.color;
      return route;
    }
    final created = _BoardRoute(
      id: _nextBoardRouteId(),
      kind: kind,
      linkedItemId: item.id,
      points: List<Offset>.from(points),
      segmentDurationsMs: List<int>.from(durations),
      stageIndex: nextStage,
      actorItemId: actorItemId,
      targetItemId: targetItemId,
      color: item.color,
      width: _defaultRouteWidth(kind),
    );
    _currentPage.routes.add(created);
    return created;
  }

  void _normalizeCurrentPageRoutes() {
    final assignedItemIdsByKind = <_PathDrawMode, Set<String>>{
      _PathDrawMode.player: <String>{},
      _PathDrawMode.ball: <String>{},
    };
    final normalizedRoutes = <_BoardRoute>[];
    for (final route in _currentPage.routes.reversed) {
      final assignedItemIds = assignedItemIdsByKind[route.kind]!;
      final linkedItem = _resolveRouteItem(
        kind: route.kind,
        points: route.points,
        preferredItemId: route.linkedItemId,
        excludedItemIds: assignedItemIds,
      );
      if (linkedItem == null) continue;
      route.linkedItemId = linkedItem.id;
      route.color = linkedItem.color;
      route.stageIndex = _normalizedRouteStageIndex(route.stageIndex);
      assignedItemIds.add(linkedItem.id);
      normalizedRoutes.add(route);
    }
    _currentPage.routes
      ..clear()
      ..addAll(normalizedRoutes.reversed);
    final selectedRouteId = _selectedRouteId;
    if (selectedRouteId != null &&
        !_currentPage.routes.any((route) => route.id == selectedRouteId)) {
      _selectedRouteId = null;
    }
  }

  void _showRouteCapacitySnackBar(_PathDrawMode kind) {
    final message = kind == _PathDrawMode.player
        ? _l10n.trainingSketchPlayerRouteLimitReached
        : _l10n.trainingSketchBallRouteLimitReached;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _syncCurrentPageRouteColors() {
    final autoLinkedItemIds = <String>{};
    for (final route in _currentPage.routes) {
      final linkedItem = _resolveRouteItem(
        kind: route.kind,
        points: route.points,
        preferredItemId: route.linkedItemId,
        excludedItemIds: autoLinkedItemIds,
        allowExcludedFallback: true,
      );
      route.linkedItemId = linkedItem?.id;
      route.color = linkedItem?.color ?? _defaultRouteColor(route.kind);
      if (linkedItem != null) {
        autoLinkedItemIds.add(linkedItem.id);
      }
    }
  }

  void _syncLinkedRouteColors(String itemId) {
    final item = _itemById(itemId);
    if (item == null) return;
    for (final route in _currentPage.routes) {
      if (route.linkedItemId != item.id) continue;
      route.color = item.color;
    }
  }

  Color _nextItemColor(_BoardItemType type) {
    if (type != _BoardItemType.player && type != _BoardItemType.ball) {
      return _defaultColorFor(type);
    }
    final palette = _colorChoicesForItemType(type);
    final sameTypeItems = _currentPage.items
        .where((item) => item.type == type)
        .toList(growable: false);
    final usedColors =
        sameTypeItems.map((item) => item.color.toARGB32()).toSet();
    for (var i = 0; i < palette.length; i++) {
      final color = palette[(sameTypeItems.length + i) % palette.length];
      if (!usedColors.contains(color.toARGB32())) {
        return color;
      }
    }
    return palette[sameTypeItems.length % palette.length];
  }

  String _nextBoardItemId() => 'item-${_nextId++}';

  String _nextBoardRouteId() => 'route-${_nextId++}';

  List<_BoardRoute> _routesForKind(_PathDrawMode kind) {
    return _currentPage.routes
        .where((route) => route.kind == kind)
        .toList(growable: false);
  }

  _BoardItemType _boardItemTypeForRouteKind(_PathDrawMode kind) {
    return switch (kind) {
      _PathDrawMode.player => _BoardItemType.player,
      _PathDrawMode.ball => _BoardItemType.ball,
    };
  }

  _BoardItem? _resolvePlaybackItemForRoute(
    _BoardRoute route, {
    Set<String> assignedItemIds = const <String>{},
  }) {
    final linkedItem = _linkedItemForRoute(route);
    if (linkedItem != null) {
      return assignedItemIds.contains(linkedItem.id) ? null : linkedItem;
    }
    return _nearestRouteItem(
      kind: route.kind,
      points: route.points,
      excludedItemIds: assignedItemIds,
    );
  }

  List<_BoardRoute> _orderedPlaybackRoutes() {
    final selectedRoute = _selectedRoute;
    final orderedRoutes = _currentPage.routes
        .where((route) => route.points.length >= 2)
        .toList(growable: true);
    if (selectedRoute != null) {
      orderedRoutes.removeWhere((route) => route.id == selectedRoute.id);
      orderedRoutes.add(selectedRoute);
    }
    return orderedRoutes;
  }

  List<_PlaybackTrack> _resolvePlaybackTracks() {
    final orderedRoutes = _orderedPlaybackRoutes();
    final usesStages = _usesRouteStages(orderedRoutes);
    final stageStartOffsetsMs =
        usesStages ? _stageStartOffsetsMs(orderedRoutes) : const <int, int>{};
    final routeOrder = <String, int>{
      for (var index = 0; index < orderedRoutes.length; index++)
        orderedRoutes[index].id: index,
    };
    final assignedUnlinkedItemIds = <String>{};
    final itemsByTrackKey = <String, _BoardItem>{};
    final routesByTrackKey = <String, List<_BoardRoute>>{};

    for (final route in orderedRoutes) {
      final linkedItem = _linkedItemForRoute(route);
      final item = linkedItem ??
          _resolvePlaybackItemForRoute(
            route,
            assignedItemIds: assignedUnlinkedItemIds,
          );
      if (item == null) continue;
      if (linkedItem == null) {
        assignedUnlinkedItemIds.add(item.id);
      }
      final trackKey = '${route.kind.name}:${item.id}';
      itemsByTrackKey[trackKey] = item;
      routesByTrackKey.putIfAbsent(trackKey, () => <_BoardRoute>[]).add(route);
    }

    final tracks = <_PlaybackTrack>[];
    for (final entry in routesByTrackKey.entries) {
      final item = itemsByTrackKey[entry.key];
      if (item == null) continue;
      final routes = entry.value.toList(growable: false)
        ..sort((a, b) {
          if (usesStages) {
            final stageCompare = _normalizedRouteStageIndex(
              a.stageIndex,
            ).compareTo(_normalizedRouteStageIndex(b.stageIndex));
            if (stageCompare != 0) return stageCompare;
          }
          return (routeOrder[a.id] ?? 0).compareTo(routeOrder[b.id] ?? 0);
        });
      final segments = <_PlaybackSegment>[];
      var elapsedMs = 0;
      for (final route in routes) {
        final timing = usesStages
            ? _routeTimingWithoutLeadingWait(route)
            : _RouteTiming(
                points: route.points,
                segmentDurationsMs: route.segmentDurationsMs,
              );
        final totalDistanceMeters = _pathDistanceMeters(timing.points);
        if (totalDistanceMeters <= 0.01) continue;
        final routeSegments = _playbackSegmentsForRoute(
          points: timing.points,
          segmentDurationsMs: timing.segmentDurationsMs,
          totalDistanceMeters: totalDistanceMeters,
          speedMetersPerSecond: _playbackSpeedMetersPerSecond(route.kind),
        );
        if (routeSegments.isEmpty) continue;
        if (usesStages) {
          final stageStartMs = stageStartOffsetsMs[
                  _normalizedRouteStageIndex(route.stageIndex)] ??
              elapsedMs;
          if (stageStartMs > elapsedMs) {
            final waitPoint =
                segments.isEmpty ? timing.points.first : segments.last.end;
            segments.add(
              _PlaybackSegment(
                start: waitPoint,
                end: waitPoint,
                durationSeconds: (stageStartMs - elapsedMs) / 1000,
              ),
            );
            elapsedMs = stageStartMs;
          }
        }
        segments.addAll(routeSegments);
        elapsedMs = segments.fold<int>(
          0,
          (sum, segment) => sum + (segment.durationSeconds * 1000).round(),
        );
      }
      if (segments.isEmpty) continue;
      tracks.add(
        _PlaybackTrack(
          item: item,
          route: routes.first,
          startPosition: Offset(item.x, item.y),
          segments: segments,
        ),
      );
    }
    return tracks;
  }

  void _moveItemWithLinkedRoutes(
    _BoardItem item, {
    required double nextX,
    required double nextY,
  }) {
    final dx = nextX - item.x;
    final dy = nextY - item.y;
    if (dx.abs() < 0.0001 && dy.abs() < 0.0001) return;
    item.x = nextX;
    item.y = nextY;
    for (final route in _currentPage.routes) {
      if (route.points.isEmpty) continue;
      if (route.linkedItemId == item.id) {
        for (var i = 0; i < route.points.length; i++) {
          final point = route.points[i];
          route.points[i] = Offset(
            (point.dx + dx).clamp(0.0, 1.0).toDouble(),
            (point.dy + dy).clamp(0.0, 1.0).toDouble(),
          );
        }
        continue;
      }
      if (route.targetItemId == item.id) {
        final moveWholeRoute =
            route.kind == _PathDrawMode.ball && route.actorItemId == item.id;
        final startIndex = moveWholeRoute ? 0 : route.points.length - 1;
        for (var i = startIndex; i < route.points.length; i++) {
          final point = route.points[i];
          route.points[i] = Offset(
            (point.dx + dx).clamp(0.0, 1.0).toDouble(),
            (point.dy + dy).clamp(0.0, 1.0).toDouble(),
          );
        }
      }
    }
  }

  _PathDrawMode? _routeKindForItem(_BoardItem item) {
    return switch (item.type) {
      _BoardItemType.player => _PathDrawMode.player,
      _BoardItemType.ball => _PathDrawMode.ball,
      _ => null,
    };
  }

  int _boardItemPaintPriority(_BoardItem item) {
    if (item.id == _movingItemId || item.id == _selectedItemId) return 4;
    if (item.type == _BoardItemType.player ||
        item.type == _BoardItemType.ball) {
      return 3;
    }
    if (item.type == _BoardItemType.target ||
        item.type == _BoardItemType.base ||
        item.type == _BoardItemType.basket) {
      return 2;
    }
    return 1;
  }

  List<_BoardItem> _boardItemsInPaintOrder() {
    final items = List<_BoardItem>.from(_currentPage.items);
    items.sort((a, b) {
      final priority = _boardItemPaintPriority(a).compareTo(
        _boardItemPaintPriority(b),
      );
      if (priority != 0) return priority;
      return _currentPage.items.indexOf(a).compareTo(
            _currentPage.items.indexOf(b),
          );
    });
    return items;
  }

  void _selectBoardItem(_BoardItem item) {
    final kind = _routeKindForItem(item);
    setState(() {
      if (_selectedItemId != item.id) {
        _showSelectedColorPicker = false;
      }
      _selectedItemId = item.id;
      _pendingTargetAction = null;
      _routeReplaceMode = false;
      _activeRoutePoints = null;
      _activeRouteSegmentDurationsMs = null;
      _activeRouteLastPointAt = null;
      if (kind != null) {
        if (_pathMode) {
          _pathDrawMode = kind;
        }
        _selectedRouteId = _routeForItem(item.id, kind)?.id;
      } else if (!_pathMode) {
        _selectedRouteId = null;
      }
    });
  }

  void _handleBoardItemTap(_BoardItem item) {
    final action = _pendingTargetAction;
    if (action != null && !widget.readOnly && !_playController.isAnimating) {
      _applyPendingTargetActionToItem(action: action, target: item);
      return;
    }
    _selectBoardItem(item);
  }

  void _startItemMove(_BoardItem item) {
    if (widget.readOnly || _playController.isAnimating) return;
    _stopRoutePlayback(restoreStart: false);
    unawaited(HapticFeedback.selectionClick());
    final kind = _routeKindForItem(item);
    setState(() {
      _movingItemId = item.id;
      _lastLongPressMoveOffset = Offset.zero;
      _showSelectedColorPicker = false;
      _selectedItemId = item.id;
      _pendingTargetAction = null;
      _routeReplaceMode = false;
      _activeStroke = null;
      _activeRoutePoints = null;
      _activeRouteSegmentDurationsMs = null;
      _activeRouteLastPointAt = null;
      if (kind != null) {
        if (_pathMode) {
          _pathDrawMode = kind;
        }
        _selectedRouteId = _routeForItem(item.id, kind)?.id;
      } else if (!_pathMode) {
        _selectedRouteId = null;
      }
    });
  }

  void _updateItemMoveByDelta(
    _BoardItem item, {
    required Offset delta,
    required double boardWidth,
    required double boardHeight,
  }) {
    if (widget.readOnly || _playController.isAnimating) return;
    if (_movingItemId != item.id) return;
    if (delta.distance < 0.5) return;
    final nextX =
        (item.x + (delta.dx / boardWidth)).clamp(0.03, 0.97).toDouble();
    final nextY =
        (item.y + (delta.dy / boardHeight)).clamp(0.03, 0.97).toDouble();
    setState(() {
      _moveItemWithLinkedRoutes(item, nextX: nextX, nextY: nextY);
    });
    _scheduleAutoSave();
  }

  void _startLongPressItemMove(_BoardItem item) {
    _startItemMove(item);
    _lastLongPressMoveOffset = Offset.zero;
  }

  void _updateLongPressItemMove(
    _BoardItem item, {
    required Offset offsetFromOrigin,
    required double boardWidth,
    required double boardHeight,
  }) {
    if (_movingItemId != item.id) return;
    final delta = offsetFromOrigin - _lastLongPressMoveOffset;
    _lastLongPressMoveOffset = offsetFromOrigin;
    _updateItemMoveByDelta(
      item,
      delta: delta,
      boardWidth: boardWidth,
      boardHeight: boardHeight,
    );
  }

  void _endItemMove() {
    if (_movingItemId == null) return;
    setState(() {
      _movingItemId = null;
      _lastLongPressMoveOffset = Offset.zero;
    });
  }

  void _addItem(_BoardItemType type) {
    setState(() {
      final item = _BoardItem(
        id: _nextBoardItemId(),
        type: type,
        x: 0.5,
        y: 0.5,
        size: 32,
        rotationDeg: 0,
        color: _nextItemColor(type),
      );
      _currentPage.items.add(item);
      _selectedItemId = item.id;
      _selectedRouteId = null;
      _showSelectedColorPicker = false;
      _penMode = false;
      _pathMode = false;
      _pendingTargetAction = null;
      _routeReplaceMode = false;
      _activeStroke = null;
      _activeRoutePoints = null;
      _activeRouteSegmentDurationsMs = null;
      _activeRouteLastPointAt = null;
    });
    _scheduleAutoSave();
  }

  void _removeSelected() {
    final id = _selectedItemId;
    if (id == null) return;
    _stopRoutePlayback(restoreStart: false);
    setState(() {
      _currentPage.items.removeWhere((e) => e.id == id);
      final removedSelectedRoute = _selectedRouteId;
      _currentPage.routes.removeWhere((route) => route.linkedItemId == id);
      for (final route in _currentPage.routes) {
        if (route.targetItemId == id) {
          route.targetItemId = null;
        }
      }
      if (removedSelectedRoute != null &&
          !_currentPage.routes.any(
            (route) => route.id == removedSelectedRoute,
          )) {
        _selectedRouteId = null;
      }
      _selectedItemId = null;
      _showSelectedColorPicker = false;
      _pendingTargetAction = null;
    });
    _scheduleAutoSave();
  }

  Future<void> _renameCurrentPage(bool isKo) async {
    final renamed = await _showBoardNameDialog(
      isKo: isKo,
      titleKo: '스케치명 수정',
      titleEn: 'Rename sketch',
      confirmKo: '저장',
      confirmEn: 'Save',
      initialValue: _currentPage.name,
    );
    if (renamed == null) return;
    setState(() {
      _currentPage.name = renamed;
    });
    _scheduleAutoSave();
  }

  Future<void> _openTemplateGallery() {
    return Navigator.of(context).push<void>(
      AppPageRoute(
        builder: (_) => TrainingBoardTemplateGalleryScreen(
          sportId: _currentSportId,
        ),
      ),
    );
  }

  String? get _currentSportId {
    final widgetSportId = widget.sportId;
    if (widgetSportId != null) {
      return SportCatalog.normalizeSportId(widgetSportId);
    }
    final optionRepository = widget.optionRepository;
    if (optionRepository == null) return null;
    return SportService(optionRepository).currentSportId();
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  Future<bool> _confirmReset(bool isKo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isKo ? '훈련 스케치 초기화' : 'Reset training sketch'),
        content: Text(
          isKo
              ? '현재 보드를 정말 초기화할까요?'
              : 'Do you really want to clear this board?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(isKo ? '취소' : 'Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(isKo ? '초기화' : 'Reset'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<bool> _saveBoard(
    bool isKo, {
    bool showFeedback = true,
    bool awardXp = true,
    bool showAwardFeedback = true,
  }) async {
    if (widget.readOnly) return false;
    if (_playbackTracks.isNotEmpty) {
      _stopRoutePlayback();
    }
    if (mounted) {
      setState(_normalizeCurrentPageRoutes);
    } else {
      _normalizeCurrentPageRoutes();
    }
    final serialized = _serialize();
    PlayerLevelAward? boardAward;
    if (_isManagedMode) {
      final boardId = _currentBoardId;
      if (boardId == null) return false;
      final currentBoard = _firstWhereOrNull(
        _managedBoards,
        (board) => board.id == boardId,
      );
      if (currentBoard == null) return false;
      final title = _resolvedCurrentBoardTitle(isKo);
      final updated = currentBoard.copyWith(
        title: title,
        layoutJson: serialized,
      );
      await _managedBoardService!.saveBoard(updated);
      _managedBoards = _managedBoardService!.allBoards();
      if (awardXp) {
        boardAward = await PlayerLevelService(
          widget.optionRepository!,
          sportId: widget.sportId,
        ).awardForBoardSaved(boardId: updated.id, boardTitle: title);
        if (showAwardFeedback) {
          await _presentBoardXpAward(boardAward, isKo: isKo);
        }
      }
    } else {
      widget.onSaved?.call(serialized);
    }
    setState(() {
      _lastSavedLayout = serialized;
    });
    if (!mounted) return true;
    if (showFeedback && (boardAward?.gainedXp ?? 0) <= 0) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.trainingSketchSavedSnack),
        ),
      );
    }
    return true;
  }

  String _resolvedCurrentBoardTitle(bool isKo) {
    final currentName = _currentPage.name.trim();
    if (currentName.isNotEmpty) return currentName;
    final widgetTitle = widget.boardTitle.trim();
    if (widgetTitle.isNotEmpty) return widgetTitle;
    return isKo ? '훈련 스케치' : 'Training Sketch';
  }

  Future<void> _showManagedBoardPicker(bool isKo) async {
    final linkedBoards = _managedBoards
        .where((board) => _selectedBoardIds.contains(board.id))
        .toList(growable: false);
    if (linkedBoards.isEmpty) return;
    final selectedBoard = await showModalBottomSheet<TrainingBoard>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: linkedBoards.map((board) {
            final isCurrent = board.id == _currentBoardId;
            return ListTile(
              leading: Icon(
                isCurrent
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off_outlined,
              ),
              title: Text(board.title),
              trailing: isCurrent ? const Icon(Icons.check) : null,
              onTap: () => Navigator.of(context).pop(board),
            );
          }).toList(growable: false),
        ),
      ),
    );
    if (!mounted || selectedBoard == null) return;
    await _switchManagedBoard(selectedBoard, isKo);
  }

  Future<void> _deleteCurrentManagedBoard(bool isKo) async {
    if (!_isManagedMode) return;
    final boardId = _currentBoardId;
    if (boardId == null) return;

    if (_hasUnsavedChanges) {
      final action = await _showPendingBoardActionDialog(isKo);
      if (!mounted || action == null || action == _PendingBoardAction.cancel) {
        return;
      }
      if (action == _PendingBoardAction.save) {
        final saved = await _saveBoard(isKo, showFeedback: false);
        if (!mounted || !saved) return;
      }
    }

    final currentBoard = _firstWhereOrNull(
      _managedBoards,
      (board) => board.id == boardId,
    );
    if (currentBoard == null) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isKo ? '훈련 스케치 삭제' : 'Delete training sketch'),
        content: Text(
          isKo
              ? '"${currentBoard.title}" 보드를 삭제할까요?'
              : 'Delete board "${currentBoard.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(isKo ? '취소' : 'Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(isKo ? '삭제' : 'Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete != true) return;

    await _managedBoardService!.deleteBoard(boardId);
    if (!mounted) return;

    setState(() {
      _managedBoards = _managedBoardService!.allBoards();
      _selectedBoardIds.remove(boardId);
      final linkedBoards = _managedBoards
          .where((board) => _selectedBoardIds.contains(board.id))
          .toList(growable: false);
      if (linkedBoards.isNotEmpty) {
        _loadBoard(linkedBoards.first);
      } else {
        _currentBoardId = null;
        _pages = <_BoardPageState>[_emptyBoardPage(widget.boardTitle)];
        _selectedItemId = null;
        _showSelectedColorPicker = false;
        _methodController.text = _currentPage.methodText;
        _lastSavedLayout = _serialize();
      }
    });

    if (_currentBoardId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _promptForManagedBoardCreation(isInitialFlow: true);
      });
    }
  }

  Future<void> _switchManagedBoard(TrainingBoard nextBoard, bool isKo) async {
    if (nextBoard.id == _currentBoardId) return;
    if (_hasUnsavedChanges) {
      final action = await _showPendingBoardActionDialog(isKo);
      if (!mounted || action == null || action == _PendingBoardAction.cancel) {
        return;
      }
      if (action == _PendingBoardAction.save) {
        final saved = await _saveBoard(isKo, showFeedback: false);
        if (!mounted || !saved) return;
      }
    }
    _stopRoutePlayback(restoreStart: false);
    setState(() {
      _loadBoard(nextBoard);
    });
  }

  Future<_PendingBoardAction?> _showPendingBoardActionDialog(bool isKo) {
    return showDialog<_PendingBoardAction>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isKo ? '저장되지 않은 변경사항' : 'Unsaved changes'),
        content: Text(
          isKo
              ? '현재 편집 내용을 어떻게 할까요?'
              : 'What should happen to your current edits?',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(_PendingBoardAction.cancel),
            child: Text(isKo ? '취소' : 'Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(_PendingBoardAction.discard),
            child: Text(isKo ? '버리기' : 'Discard'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(_PendingBoardAction.save),
            child: Text(isKo ? '저장' : 'Save'),
          ),
        ],
      ),
    );
  }

  void _copyPresetBoard({
    required TrainingBoardPreset preset,
    required TrainingMethodPage page,
    required bool isKo,
  }) {
    final copiedPage = _BoardPageState(
      name: page.name.trim().isEmpty ? _currentPage.name : page.name,
      methodText: page.methodText,
      items: page.items
          .map(
            (e) => _BoardItem(
              id: e.id.trim().isEmpty ? _nextBoardItemId() : e.id,
              type: _boardItemTypeFromString(e.type) ?? _BoardItemType.cone,
              x: e.x,
              y: e.y,
              size: 32,
              rotationDeg: e.rotationDeg,
              color: Color(e.colorValue),
            ),
          )
          .toList(growable: true),
      strokes: page.strokes
          .map(
            (stroke) => _BoardStroke(
              points: stroke.points
                  .map((point) => Offset(point.x, point.y))
                  .toList(growable: false),
              color: Color(stroke.colorValue),
              width: stroke.width,
            ),
          )
          .toList(growable: true),
      routes: page.routes
          .map(
            (route) => _BoardRoute(
              id: route.id.trim().isEmpty ? _nextBoardRouteId() : route.id,
              kind: _pathDrawModeFromRouteKind(route.kind),
              linkedItemId: route.linkedItemId,
              actorItemId: route.actorItemId,
              targetItemId: route.targetItemId,
              points: route.points
                  .map((point) => Offset(point.x, point.y))
                  .toList(growable: true),
              segmentDurationsMs: route.segmentDurationsMs.toList(
                growable: true,
              ),
              stageIndex: route.stageIndex,
              color: Color(route.colorValue),
              width: route.width,
            ),
          )
          .toList(growable: true),
    );
    for (final route in copiedPage.routes) {
      final linkedItemId = route.linkedItemId;
      if (linkedItemId == null) continue;
      final linkedItem = _firstWhereOrNull(
        copiedPage.items,
        (item) => item.id == linkedItemId,
      );
      if (linkedItem != null) {
        route.color = linkedItem.color;
      }
    }

    setState(() {
      _pages[0] = copiedPage;
      _normalizeCurrentPageRoutes();
      _selectedItemId = null;
      _selectedRouteId = null;
      _showSelectedColorPicker = false;
      _penMode = false;
      _pathMode = false;
      _methodController.text = _currentPage.methodText;
      _activeRoutePoints = null;
      _activeRouteSegmentDurationsMs = null;
      _activeRouteLastPointAt = null;
      _routeReplaceMode = false;
      _playbackTracks = const <_PlaybackTrack>[];
    });
    _scheduleAutoSave();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isKo
              ? '${preset.title} 스케치를 복사했습니다.'
              : 'Sketch copied from ${preset.title}.',
        ),
      ),
    );
  }

  Future<void> _showPresetPicker(bool isKo) async {
    final selected = await showModalBottomSheet<_PresetBoardSelection>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: widget.presets.length,
                  itemBuilder: (context, index) {
                    final preset = widget.presets[index];
                    final layout = TrainingMethodLayout.decode(
                      preset.layoutJson,
                    );
                    if (layout.pages.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return ExpansionTile(
                      leading: const Icon(Icons.copy_all_outlined),
                      title: Text(preset.title),
                      subtitle: preset.subtitle.trim().isEmpty
                          ? null
                          : Text(
                              preset.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                      children: layout.pages.asMap().entries.map((entry) {
                        final pageIndex = entry.key;
                        final page = entry.value;
                        final boardName = page.name.trim().isEmpty
                            ? 'Board ${pageIndex + 1}'
                            : page.name.trim();
                        final memo = page.methodText.trim();
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.content_paste_outlined),
                          title: Text(boardName),
                          subtitle: memo.isEmpty
                              ? null
                              : Text(
                                  memo,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.of(context).pop(
                              _PresetBoardSelection(
                                preset: preset,
                                page: page,
                              ),
                            );
                          },
                        );
                      }).toList(growable: false),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(isKo ? '취소' : 'Cancel'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (!mounted || selected == null) return;
    _copyPresetBoard(preset: selected.preset, page: selected.page, isKo: isKo);
  }

  Future<void> _copyCurrentManagedBoard(bool isKo) async {
    if (!_isManagedMode || _managedBoardService == null) return;
    final copyCandidates = _managedBoards
        .where((board) => board.id != _currentBoardId)
        .toList(growable: false);
    if (copyCandidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isKo
                ? '복사해서 추가할 다른 스케치가 없습니다.'
                : 'There is no other sketch to copy from.',
          ),
        ),
      );
      return;
    }
    final source = await showModalBottomSheet<TrainingBoard>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: copyCandidates.map((board) {
            return ListTile(
              leading: const Icon(Icons.copy_all_outlined),
              title: Text(board.title),
              subtitle: Text(
                isKo
                    ? '업데이트 ${board.updatedAt.month}.${board.updatedAt.day}'
                    : 'Updated ${board.updatedAt.month}/${board.updatedAt.day}',
              ),
              onTap: () => Navigator.of(context).pop(board),
            );
          }).toList(growable: false),
        ),
      ),
    );
    if (!mounted || source == null) return;
    final title = await _showBoardNameDialog(
      isKo: isKo,
      titleKo: '스케치 복사',
      titleEn: 'Copy sketch',
      confirmKo: '복사',
      confirmEn: 'Copy',
      initialValue: isKo ? '${source.title} 복사본' : '${source.title} Copy',
    );
    if (!mounted || title == null) return;
    final created = await _managedBoardService!.createBoard(
      title: title,
      layoutJson: source.layoutJson,
    );
    if (!mounted) return;
    setState(() {
      _managedBoards = _managedBoardService!.allBoards();
      _selectedBoardIds.add(created.id);
      _loadBoard(created);
    });
    final award = await PlayerLevelService(
      widget.optionRepository!,
      sportId: widget.sportId,
    ).awardForBoardSaved(
      boardId: created.id,
      boardTitle: created.title,
      savedAt: created.updatedAt,
      created: true,
    );
    await _presentBoardXpAward(award, isKo: isKo);
    if (!mounted || award.gainedXp > 0) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.trainingSketchCopiedFromAnotherSnack),
      ),
    );
  }

  Future<void> _handleBackPressed(bool isKo) async {
    final shouldPop = await _shouldPopOnSystemBack(isKo);
    if (!mounted || !shouldPop) return;
    Navigator.of(
      context,
    ).pop(_isManagedMode ? _selectedBoardIds.toList(growable: false) : null);
  }

  Future<bool> _shouldPopOnSystemBack(bool isKo) async {
    if (widget.readOnly) {
      return true;
    }
    if (_playbackTracks.isNotEmpty) {
      _stopRoutePlayback();
    }
    if (!_hasUnsavedChanges) {
      return true;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isKo ? '저장되지 않은 변경사항' : 'Unsaved changes'),
        content: Text(
          isKo
              ? '저장하지 않은 편집 내용이 있습니다. 페이지를 나가시겠어요?'
              : 'You have unsaved edits. Leave this page?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(isKo ? '계속 편집' : 'Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(isKo ? '나가기' : 'Leave'),
          ),
        ],
      ),
    );
    return discard == true;
  }

  void _syncRouteResult() {
    final route = ModalRoute.of(context);
    if (route is! AppPageRoute<List<String>>) {
      return;
    }
    route.currentResultValue =
        _isManagedMode ? _selectedBoardIds.toList(growable: false) : null;
  }

  void _startStroke(Offset localPosition, double width, double height) {
    final x = (localPosition.dx / width).clamp(0.0, 1.0);
    final y = (localPosition.dy / height).clamp(0.0, 1.0);
    setState(() {
      _activeStroke = <Offset>[Offset(x, y)];
      _selectedItemId = null;
      _showSelectedColorPicker = false;
    });
  }

  void _appendStrokePoint(Offset localPosition, double width, double height) {
    final points = _activeStroke;
    if (points == null) return;
    final x = (localPosition.dx / width).clamp(0.0, 1.0);
    final y = (localPosition.dy / height).clamp(0.0, 1.0);
    setState(() {
      points.add(Offset(x, y));
    });
  }

  void _endStroke() {
    final points = _activeStroke;
    if (points == null || points.length < 2) {
      setState(() {
        _activeStroke = null;
      });
      return;
    }
    setState(() {
      _currentPage.strokes.add(
        _BoardStroke(
          points: List<Offset>.from(points),
          color: _penColor,
          width: 3.0,
        ),
      );
      _activeStroke = null;
    });
    _scheduleAutoSave();
  }

  void _startPlayerPath(Offset localPosition, double width, double height) {
    final point = _boardPointFromLocal(localPosition, width, height);
    final selectedItem = _selectedItem;
    final expectedType = _boardItemTypeForRouteKind(_pathDrawMode);
    setState(() {
      _activeRoutePoints = <Offset>[
        if (selectedItem != null && selectedItem.type == expectedType)
          _itemPosition(selectedItem)
        else
          point,
      ];
      _activeRouteSegmentDurationsMs = <int>[];
      _activeRouteLastPointAt = DateTime.now();
    });
    if (selectedItem != null && selectedItem.type == expectedType) {
      _appendRoutePoint(point, durationMs: 420);
    }
  }

  void _appendPlayerPath(Offset localPosition, double width, double height) {
    _appendRoutePoint(_boardPointFromLocal(localPosition, width, height));
  }

  Offset _routePointToLocal(Offset point, double width, double height) {
    return Offset(point.dx * width, point.dy * height);
  }

  _BoardRoute? _routeWithEndNearLocalPoint(
    Offset localPosition,
    double width,
    double height,
  ) {
    const hitRadius = 28.0;
    final selectedRoute = _selectedRoute;
    if (selectedRoute != null && selectedRoute.points.length >= 2) {
      final selectedEnd = _routePointToLocal(
        selectedRoute.points.last,
        width,
        height,
      );
      if ((selectedEnd - localPosition).distance <= hitRadius) {
        return selectedRoute;
      }
    }

    _BoardRoute? nearest;
    var nearestDistance = hitRadius;
    for (final route in _currentPage.routes.reversed) {
      if (route.points.length < 2 || route.id == selectedRoute?.id) continue;
      final end = _routePointToLocal(route.points.last, width, height);
      final distance = (end - localPosition).distance;
      if (distance <= nearestDistance) {
        nearest = route;
        nearestDistance = distance;
      }
    }
    return nearest;
  }

  void _prepareRouteExtensionDraft(_BoardRoute route) {
    _stopRoutePlayback(restoreStart: false);
    setState(() {
      _selectedRouteId = route.id;
      _routeReplaceMode = true;
      _pathMode = false;
      _pathDrawMode = route.kind;
      _penMode = false;
      _pendingTargetAction = null;
      _showSelectedColorPicker = false;
      _activeRoutePoints = List<Offset>.from(route.points);
      _activeRouteSegmentDurationsMs = _normalizedRouteSegmentDurations(
        pointCount: route.points.length,
        rawDurationsMs: route.segmentDurationsMs,
      ).toList(growable: true);
      _activeRouteLastPointAt = DateTime.now();
      if (route.linkedItemId != null) {
        _selectedItemId = route.linkedItemId;
      }
    });
  }

  void _startSelectedRouteEndDrag(
    Offset localPosition,
    double width,
    double height,
  ) {
    if (widget.readOnly || _playController.isAnimating) return;
    final route = _routeWithEndNearLocalPoint(localPosition, width, height);
    if (route == null) return;
    unawaited(HapticFeedback.selectionClick());
    _prepareRouteExtensionDraft(route);
  }

  void _updateSelectedRouteEndDrag(
    Offset localPosition,
    double width,
    double height,
  ) {
    final route = _selectedRoute;
    final points = _activeRoutePoints;
    if (route == null ||
        points == null ||
        !_routeReplaceMode ||
        _pathMode ||
        _penMode) {
      return;
    }
    final point = _boardPointFromLocal(localPosition, width, height);
    final basePointCount = route.points.length;
    if (points.length <= basePointCount &&
        (point - points.last).distance < 0.004) {
      return;
    }
    setState(() {
      if (points.length <= basePointCount) {
        points.add(point);
      } else {
        points[points.length - 1] = point;
      }
      final durations = _activeRouteSegmentDurationsMs;
      while (durations != null && durations.length < points.length - 1) {
        durations.add(420);
      }
      _activeRouteLastPointAt = DateTime.now();
    });
  }

  void _endSelectedRouteEndDrag() {
    final route = _selectedRoute;
    final points = _activeRoutePoints;
    if (route == null ||
        points == null ||
        !_routeReplaceMode ||
        _pathMode ||
        _penMode) {
      return;
    }
    if (points.length <= route.points.length) {
      setState(() {
        _activeRoutePoints = null;
        _activeRouteSegmentDurationsMs = null;
        _activeRouteLastPointAt = null;
        _routeReplaceMode = false;
      });
      return;
    }
    _endPlayerPath();
  }

  void _appendRoutePoint(Offset point, {int? durationMs}) {
    final points = _activeRoutePoints;
    if (points == null) return;
    if (points.isNotEmpty && (point - points.last).distance < 0.004) return;
    final now = DateTime.now();
    final lastPointAt = _activeRouteLastPointAt ?? now;
    final segmentMs = durationMs ??
        now.difference(lastPointAt).inMilliseconds.clamp(16, 4000).toInt();
    setState(() {
      points.add(point);
      _activeRouteSegmentDurationsMs?.add(segmentMs);
      _activeRouteLastPointAt = now;
    });
  }

  void _handleRouteTap(Offset localPosition, double width, double height) {
    if (!_pathMode || widget.readOnly || _playController.isAnimating) return;
    final point = _boardPointFromLocal(localPosition, width, height);
    final activePoints = _activeRoutePoints;
    if (activePoints != null) {
      _appendRoutePoint(point, durationMs: 420);
      return;
    }
    final selectedItem = _selectedItem;
    final expectedType = _boardItemTypeForRouteKind(_pathDrawMode);
    setState(() {
      _activeRoutePoints = <Offset>[
        if (selectedItem != null && selectedItem.type == expectedType)
          _itemPosition(selectedItem)
        else
          point,
      ];
      _activeRouteSegmentDurationsMs = <int>[];
      _activeRouteLastPointAt = DateTime.now();
    });
    if (selectedItem != null && selectedItem.type == expectedType) {
      _appendRoutePoint(point, durationMs: 420);
    }
  }

  bool get _canFinishActiveRoute => (_activeRoutePoints?.length ?? 0) >= 2;

  bool get _canUndoLastRoutePoint => (_activeRoutePoints?.length ?? 0) > 1;

  void _finishActiveRoute() {
    if (!_canFinishActiveRoute) return;
    _endPlayerPath();
  }

  void _undoLastRoutePoint() {
    final points = _activeRoutePoints;
    if (points == null || points.length <= 1) return;
    setState(() {
      points.removeLast();
      final durations = _activeRouteSegmentDurationsMs;
      if (durations != null && durations.isNotEmpty) {
        durations.removeLast();
      }
      _activeRouteLastPointAt = DateTime.now();
    });
  }

  void _endPlayerPath() {
    final points = _activeRoutePoints;
    if (points == null || points.length < 2) {
      setState(() {
        _activeRoutePoints = null;
        _activeRouteSegmentDurationsMs = null;
        _activeRouteLastPointAt = null;
        _routeReplaceMode = false;
      });
      return;
    }
    final segmentDurationsMs = _normalizedRouteSegmentDurations(
      pointCount: points.length,
      rawDurationsMs: _activeRouteSegmentDurationsMs,
    );
    final replacementRoute = _routeToUpdateForPath(_pathDrawMode);
    final selectedItem = _selectedItem;
    final preferredItemId =
        selectedItem?.type == _boardItemTypeForRouteKind(_pathDrawMode)
            ? selectedItem?.id
            : replacementRoute?.linkedItemId;
    final resolvedLinkedItem = _resolveRouteItem(
      kind: _pathDrawMode,
      points: points,
      preferredItemId: preferredItemId,
      excludedItemIds: _linkedRouteItemIds(
        _pathDrawMode,
        excludingRouteId: replacementRoute?.id,
      ),
    );
    if (resolvedLinkedItem == null) {
      setState(() {
        _activeRoutePoints = null;
        _activeRouteSegmentDurationsMs = null;
        _activeRouteLastPointAt = null;
        _routeReplaceMode = false;
      });
      _showRouteCapacitySnackBar(_pathDrawMode);
      return;
    }
    setState(() {
      final route = _upsertRouteForItem(
        kind: _pathDrawMode,
        item: resolvedLinkedItem,
        points: List<Offset>.from(points),
        segmentDurationsMs: segmentDurationsMs,
        replacementRoute: replacementRoute,
      );
      _selectedRouteId = route.id;
      _selectedItemId = resolvedLinkedItem.id;
      _showSelectedColorPicker = false;
      _activeRoutePoints = null;
      _activeRouteSegmentDurationsMs = null;
      _activeRouteLastPointAt = null;
      _routeReplaceMode = false;
    });
    _scheduleAutoSave();
  }

  void _prepareSelectedRouteRedraw() {
    final route = _selectedRoute;
    if (route == null) return;
    setState(() {
      _routeReplaceMode = true;
      _pathMode = true;
      _pathDrawMode = route.kind;
      _penMode = false;
      _pendingTargetAction = null;
      _showSelectedColorPicker = false;
      _activeRoutePoints = null;
      _activeRouteSegmentDurationsMs = null;
      _activeRouteLastPointAt = null;
      if (route.linkedItemId != null) {
        _selectedItemId = route.linkedItemId;
      }
    });
  }

  void _prepareSelectedRouteExtension() {
    final route = _selectedRoute;
    if (route == null || route.points.length < 2) return;
    _prepareRouteExtensionDraft(route);
    setState(() {
      _pathMode = true;
    });
  }

  void _reverseSelectedRoute() {
    final route = _selectedRoute;
    if (route == null || route.points.length < 2) return;
    _stopRoutePlayback(restoreStart: false);
    final reversedPoints = route.points.reversed.toList(growable: false);
    final reversedDurations =
        route.segmentDurationsMs.reversed.toList(growable: false);
    setState(() {
      route.points.setAll(0, reversedPoints);
      route.segmentDurationsMs.setAll(0, reversedDurations);
      _trimRouteDurations(route);
      _pathDrawMode = route.kind;
      _routeReplaceMode = false;
      _activeRoutePoints = null;
      _activeRouteSegmentDurationsMs = null;
      _activeRouteLastPointAt = null;
      _pendingTargetAction = null;
    });
    _scheduleAutoSave();
  }

  void _deleteSelectedRoute() {
    final route = _selectedRoute;
    if (route == null) return;
    final wasPlaying = _playbackTracks.any(
      (track) => track.route.id == route.id,
    );
    if (wasPlaying) {
      _stopRoutePlayback(restoreStart: false);
    }
    setState(() {
      _currentPage.routes.removeWhere((entry) => entry.id == route.id);
      _selectedRouteId = null;
      _routeReplaceMode = false;
      _activeRoutePoints = null;
      _activeRouteSegmentDurationsMs = null;
      _activeRouteLastPointAt = null;
      _pendingTargetAction = null;
    });
    _scheduleAutoSave();
  }

  List<_BoardRoute> _sequenceableRoutes() {
    return _currentPage.routes
        .where((route) => route.points.length >= 2)
        .toList(growable: false);
  }

  int _normalizedRouteStageIndex(int value) {
    return value.clamp(1, _maxRouteStageIndex).toInt();
  }

  int _maxRouteStageInPage() {
    var maxStage = 1;
    for (final route in _currentPage.routes) {
      maxStage =
          math.max(maxStage, _normalizedRouteStageIndex(route.stageIndex));
    }
    final registered = _registeredStageForNextAction();
    if (registered != null) {
      maxStage = math.max(maxStage, registered);
    }
    return maxStage;
  }

  List<int> _visibleRouteStages() {
    final routeCount = _sequenceableRoutes().length;
    final maxStage = _maxRouteStageInPage();
    final count = math.min(
      _maxRouteStageIndex,
      routeCount <= 1 ? maxStage : math.max(2, maxStage + 1),
    );
    return List<int>.generate(count, (index) => index + 1, growable: false);
  }

  bool _usesRouteStages(List<_BoardRoute> routes) {
    return routes
        .any((route) => _normalizedRouteStageIndex(route.stageIndex) > 1);
  }

  int? _stageAfterSelectedRoute() {
    final route = _selectedRoute;
    if (route == null || route.points.length < 2) return null;
    return _normalizedRouteStageIndex(route.stageIndex + 1);
  }

  int? _stageAfterCurrentBallPossession(_BoardItem player) {
    final route = _currentBallRouteForPlayer(player);
    if (route == null || route.points.length < 2) return null;
    return _normalizedRouteStageIndex(route.stageIndex + 1);
  }

  List<_StageSummary> _globalStageSummaries() {
    final routesByStage = <int, List<_BoardRoute>>{};
    for (final route in _currentPage.routes) {
      if (route.points.length < 2) continue;
      final stage = _normalizedRouteStageIndex(route.stageIndex);
      routesByStage.putIfAbsent(stage, () => <_BoardRoute>[]).add(route);
    }
    final stages = routesByStage.keys.toList(growable: false)..sort();
    return stages
        .map(
          (stage) => _StageSummary(
            stageIndex: stage,
            routes: List<_BoardRoute>.unmodifiable(routesByStage[stage]!),
          ),
        )
        .toList(growable: false);
  }

  int? _registeredStageForNextAction() {
    final registered = _registeredNextActionStageIndex;
    return registered == null ? null : _normalizedRouteStageIndex(registered);
  }

  int _sameStageForNextAction() {
    final selectedRoute = _selectedRoute;
    if (selectedRoute != null && selectedRoute.points.length >= 2) {
      return _normalizedRouteStageIndex(selectedRoute.stageIndex);
    }
    final summaries = _globalStageSummaries();
    if (summaries.isEmpty) return 1;
    return _normalizedRouteStageIndex(summaries.last.stageIndex);
  }

  int _nextGlobalStageForNewAction() {
    final summaries = _globalStageSummaries();
    if (summaries.isEmpty) return 1;
    return _normalizedRouteStageIndex(summaries.last.stageIndex + 1);
  }

  int _defaultStageForNextGlobalAction() {
    final selected = _selectedItem;
    if (selected != null && selected.type == _BoardItemType.player) {
      final selectedRouteStage = _stageAfterSelectedRoute();
      if (selectedRouteStage != null) return selectedRouteStage;
      final possessionStage = _stageAfterCurrentBallPossession(selected);
      if (possessionStage != null) return possessionStage;
    }
    final selectedRouteStage = _stageAfterSelectedRoute();
    if (selectedRouteStage != null) return selectedRouteStage;
    return _nextGlobalStageForNewAction();
  }

  int _activeStageForNextAction() {
    return _registeredStageForNextAction() ??
        _defaultStageForNextGlobalAction();
  }

  int? _stageForNextPlayerAction(_BoardItem player) {
    final registered = _registeredStageForNextAction();
    if (registered != null) return registered;
    final selectedRouteStage = _stageAfterSelectedRoute();
    if (selectedRouteStage != null) return selectedRouteStage;
    final possessionStage = _stageAfterCurrentBallPossession(player);
    if (possessionStage != null) return possessionStage;
    return _nextGlobalStageForNewAction();
  }

  void _registerSameStageForNextAction() {
    setState(() {
      _registeredNextActionStageIndex = _sameStageForNextAction();
    });
  }

  void _registerNextStageForNextAction() {
    setState(() {
      _registeredNextActionStageIndex = _nextGlobalStageForNewAction();
    });
  }

  String _routeStageLabel(int stageIndex) {
    return _l10n.trainingSketchRouteStageChip(
      _normalizedRouteStageIndex(stageIndex),
    );
  }

  void _trimRouteDurations(_BoardRoute route) {
    final expectedCount = math.max(0, route.points.length - 1);
    if (route.segmentDurationsMs.length > expectedCount) {
      route.segmentDurationsMs.removeRange(
        expectedCount,
        route.segmentDurationsMs.length,
      );
    }
  }

  void _removeLeadingRouteWait(_BoardRoute route) {
    while (route.points.length >= 2 &&
        _segmentDistanceMeters(route.points[0], route.points[1]) <=
            _minPlaybackSegmentDistanceMeters) {
      route.points.removeAt(0);
      if (route.segmentDurationsMs.isNotEmpty) {
        route.segmentDurationsMs.removeAt(0);
      }
    }
    _trimRouteDurations(route);
  }

  _RouteTiming _routeTimingWithoutLeadingWait(_BoardRoute route) {
    final points = route.points.toList(growable: true);
    final durations = route.segmentDurationsMs.toList(growable: true);
    while (points.length >= 2 &&
        _segmentDistanceMeters(points[0], points[1]) <=
            _minPlaybackSegmentDistanceMeters) {
      points.removeAt(0);
      if (durations.isNotEmpty) {
        durations.removeAt(0);
      }
    }
    final expectedCount = math.max(0, points.length - 1);
    if (durations.length > expectedCount) {
      durations.removeRange(expectedCount, durations.length);
    }
    return _RouteTiming(points: points, segmentDurationsMs: durations);
  }

  int _routeTimingPlaybackDurationMs({
    required _PathDrawMode kind,
    required _RouteTiming timing,
  }) {
    final totalDistanceMeters = _pathDistanceMeters(timing.points);
    final segments = _playbackSegmentsForRoute(
      points: timing.points,
      segmentDurationsMs: timing.segmentDurationsMs,
      totalDistanceMeters: totalDistanceMeters,
      speedMetersPerSecond: _playbackSpeedMetersPerSecond(kind),
    );
    return segments.fold<int>(
      0,
      (sum, segment) => sum + (segment.durationSeconds * 1000).round(),
    );
  }

  int _routePlaybackDurationMs(_BoardRoute route) {
    return _routeTimingPlaybackDurationMs(
      kind: route.kind,
      timing: _routeTimingWithoutLeadingWait(route),
    );
  }

  Map<int, int> _stageStartOffsetsMs(List<_BoardRoute> routes) {
    final stageDurationsMs = <int, int>{};
    for (final route in routes) {
      if (route.points.length < 2) continue;
      final stageIndex = _normalizedRouteStageIndex(route.stageIndex);
      final durationMs = _routePlaybackDurationMs(route);
      if (durationMs <= 0) continue;
      stageDurationsMs[stageIndex] = math.max(
        stageDurationsMs[stageIndex] ?? 0,
        durationMs,
      );
    }
    final stages = stageDurationsMs.keys.toList(growable: false)..sort();
    final offsets = <int, int>{};
    var elapsedMs = 0;
    for (final stage in stages) {
      offsets[stage] = elapsedMs;
      elapsedMs += stageDurationsMs[stage] ?? 0;
    }
    return offsets;
  }

  void _setRouteStage(_BoardRoute route, int stageIndex) {
    route.stageIndex = _normalizedRouteStageIndex(stageIndex);
    _removeLeadingRouteWait(route);
  }

  void _setRouteStageAndSelect(_BoardRoute route, int stageIndex) {
    _stopRoutePlayback(restoreStart: false);
    setState(() {
      _selectedRouteId = route.id;
      _pathDrawMode = route.kind;
      _setRouteStage(route, stageIndex);
      _routeReplaceMode = false;
      _activeRoutePoints = null;
      _activeRouteSegmentDurationsMs = null;
      _activeRouteLastPointAt = null;
      _pendingTargetAction = null;
    });
    _scheduleAutoSave();
  }

  void _shiftRouteStage(_BoardRoute route, int delta) {
    _setRouteStageAndSelect(route, route.stageIndex + delta);
  }

  void _moveRouteAfterBall(_BoardRoute route) {
    if (route.kind != _PathDrawMode.player) return;
    final ballStages = _currentPage.routes
        .where(
          (entry) =>
              entry.kind == _PathDrawMode.ball && entry.points.length >= 2,
        )
        .map((entry) => _normalizedRouteStageIndex(entry.stageIndex))
        .toList(growable: false);
    if (ballStages.isEmpty) return;
    final nextStage = ballStages.fold<int>(1, math.max) + 1;
    _setRouteStageAndSelect(route, nextStage);
  }

  void _splitRoutesIntoStages() {
    final routes = _sequenceableRoutes();
    if (routes.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_l10n.trainingSketchAutoStagesNeedTwoSnack)),
      );
      return;
    }
    _stopRoutePlayback(restoreStart: false);
    setState(() {
      for (var index = 0; index < routes.length; index++) {
        final route = routes[index];
        _removeLeadingRouteWait(route);
        route.stageIndex = _normalizedRouteStageIndex(index + 1);
      }
      _selectedRouteId = routes.first.id;
      _pathDrawMode = routes.first.kind;
      _routeReplaceMode = false;
      _activeRoutePoints = null;
      _activeRouteSegmentDurationsMs = null;
      _activeRouteLastPointAt = null;
    });
    _scheduleAutoSave();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_l10n.trainingSketchAutoStagesSnack)),
    );
  }

  Future<void> _setSketchOrientationLock({required bool landscape}) async {
    await SystemChrome.setPreferredOrientations(
      landscape
          ? const <DeviceOrientation>[
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ]
          : DeviceOrientation.values,
    );
    await setTrainingSketchBrowserOrientation(landscape: landscape);
  }

  void _clearAllRoutes() {
    _stopRoutePlayback(restoreStart: false);
    setState(() {
      _currentPage.routes.clear();
      _selectedRouteId = null;
      _activeRoutePoints = null;
      _activeRouteSegmentDurationsMs = null;
      _activeRouteLastPointAt = null;
      _routeReplaceMode = false;
      _pendingTargetAction = null;
    });
    _scheduleAutoSave();
  }

  String _routeLabel(_PathDrawMode kind, int index) {
    return switch (kind) {
      _PathDrawMode.player => _l10n.trainingSketchPlayerRouteChip(index),
      _PathDrawMode.ball => _l10n.trainingSketchBallRouteChip(index),
    };
  }

  String _routeableItemLabel(_BoardItem item) {
    final kind = item.type == _BoardItemType.ball
        ? _PathDrawMode.ball
        : _PathDrawMode.player;
    final items = _routeableItems(kind);
    final index = items.indexWhere((entry) => entry.id == item.id);
    return _routeLabel(kind, index < 0 ? 1 : index + 1);
  }

  void _selectRouteableItem(_BoardItem item) {
    final kind = item.type == _BoardItemType.ball
        ? _PathDrawMode.ball
        : _PathDrawMode.player;
    setState(() {
      _selectedItemId = item.id;
      _selectedRouteId = _routeForItem(item.id, kind)?.id;
      _showSelectedColorPicker = false;
      _pathDrawMode = kind;
      _pathMode = true;
      _penMode = false;
      _pendingTargetAction = null;
      _routeReplaceMode = false;
      _activeStroke = null;
      _activeRoutePoints = null;
      _activeRouteSegmentDurationsMs = null;
      _activeRouteLastPointAt = null;
    });
  }

  void _activateRouteToolForSelectedItem() {
    final selected = _selectedItem;
    if (selected == null ||
        (selected.type != _BoardItemType.player &&
            selected.type != _BoardItemType.ball)) {
      return;
    }
    _selectRouteableItem(selected);
  }

  void _beginTargetAction(_SketchTargetAction action) {
    final selected = _selectedItem;
    if (selected == null) return;
    final player = _playerForTargetAction(selected);
    if (_requiresPlayerTargetAction(action) && player == null) {
      return;
    }
    if (_requiresBallTargetAction(action)) {
      if (player == null) return;
      if (!_canStartBallActionForPlayer(player)) {
        _showBallPossessionRequiredSnackBar(player);
        return;
      }
    }
    _stopRoutePlayback(restoreStart: false);
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      _pendingTargetAction = action;
      _showSelectedColorPicker = false;
      _pathMode = false;
      _penMode = false;
      _routeReplaceMode = false;
      _activeStroke = null;
      _activeRoutePoints = null;
      _activeRouteSegmentDurationsMs = null;
      _activeRouteLastPointAt = null;
    });
  }

  void _cancelTargetAction() {
    if (_pendingTargetAction == null) return;
    setState(() => _pendingTargetAction = null);
  }

  void _handleBoardTap(Offset localPosition, double width, double height) {
    if (widget.readOnly || _playController.isAnimating) return;
    final point = _boardPointFromLocal(localPosition, width, height);
    final action = _pendingTargetAction;
    if (action != null) {
      _applyPendingTargetActionToPoint(action: action, target: point);
      return;
    }
    if (_pathMode) {
      _handleRouteTap(localPosition, width, height);
    }
  }

  void _applyPendingTargetActionToItem({
    required _SketchTargetAction action,
    required _BoardItem target,
  }) {
    _applyPendingTargetActionToPoint(
      action: action,
      target: _itemActionPoint(target),
      targetItem: target,
    );
  }

  void _applyPendingTargetActionToPoint({
    required _SketchTargetAction action,
    required Offset target,
    _BoardItem? targetItem,
  }) {
    final selected = _selectedItem;
    if (selected == null) return;
    final applied = switch (action) {
      _SketchTargetAction.move => _applyMoveTargetAction(selected, target),
      _SketchTargetAction.pass => _applyBallTargetAction(
          selected: selected,
          target: target,
          targetItem: targetItem,
          durationMs: 680,
        ),
      _SketchTargetAction.passAndMove => _applyPassAndMoveTargetAction(
          selected,
          target,
          targetItem: targetItem,
        ),
      _SketchTargetAction.dribble => _applyDribbleTargetAction(
          selected,
          target,
        ),
      _SketchTargetAction.receiveMove => _applyReceiveMoveTargetAction(
          selected,
          target,
        ),
      _SketchTargetAction.returnMove => _applyReturnMoveTargetAction(
          selected,
          target,
        ),
      _SketchTargetAction.overlap => _applyOverlapTargetAction(
          selected,
          target,
        ),
      _SketchTargetAction.shot => _applyShotTargetAction(selected, target),
      _SketchTargetAction.cross => _applyCrossTargetAction(selected, target),
      _SketchTargetAction.drive => _applyDriveTargetAction(selected, target),
      _SketchTargetAction.cut => _applyMoveTargetAction(
          selected,
          target,
          durationMs: 760,
          carryPossessedBall: false,
        ),
      _SketchTargetAction.screen => _applyScreenTargetAction(selected, target),
      _SketchTargetAction.coneTurn => _applyConeTurnTargetAction(
          selected,
          target,
          targetItem: targetItem,
        ),
      _SketchTargetAction.coneJump => _applyConeJumpTargetAction(
          selected,
          target,
          targetItem: targetItem,
        ),
      _SketchTargetAction.hurdleJump => _applyHurdleJumpTargetAction(
          selected,
          target,
          targetItem: targetItem,
        ),
      _SketchTargetAction.runBase => _applyMoveTargetAction(
          selected,
          target,
          durationMs: 780,
          carryPossessedBall: false,
        ),
      _SketchTargetAction.fielding => _applyMoveTargetAction(
          selected,
          target,
          durationMs: 700,
          carryPossessedBall: false,
        ),
      _SketchTargetAction.throwBall => _applyBallTargetAction(
          selected: selected,
          target: target,
          durationMs: 620,
        ),
      _SketchTargetAction.serve => _applyServeTargetAction(selected, target),
      _SketchTargetAction.rally => _applyRallyTargetAction(selected, target),
      _SketchTargetAction.recover => _applyMoveTargetAction(
          selected,
          target,
          durationMs: 640,
          carryPossessedBall: false,
        ),
    };
    if (applied) {
      unawaited(HapticFeedback.lightImpact());
    }
  }

  void _selectQuickActionRoute(
    _BoardRoute route,
    _BoardItem item, {
    _BoardItem? selectedItemOverride,
  }) {
    _selectedItemId = selectedItemOverride?.id ?? item.id;
    _selectedRouteId = route.id;
    _registeredNextActionStageIndex = null;
    _showSelectedColorPicker = false;
    _pathDrawMode = route.kind;
    _pathMode = false;
    _penMode = false;
    _pendingTargetAction = null;
    _routeReplaceMode = false;
    _activeStroke = null;
    _activeRoutePoints = null;
    _activeRouteSegmentDurationsMs = null;
    _activeRouteLastPointAt = null;
  }

  Offset _midTargetPoint(
    Offset start,
    Offset end, {
    double xOffset = 0,
    double yOffset = 0,
  }) {
    return _clampedBoardPoint(
      start.dx + ((end.dx - start.dx) * 0.5) + xOffset,
      start.dy + ((end.dy - start.dy) * 0.5) + yOffset,
    );
  }

  _BoardRoute? _playerRouteForChainedAction(_BoardItem player) {
    final selectedRoute = _selectedRoute;
    if (selectedRoute != null &&
        selectedRoute.kind == _PathDrawMode.player &&
        selectedRoute.linkedItemId == player.id &&
        selectedRoute.points.length >= 2) {
      return selectedRoute;
    }
    final route = _routeForItem(player.id, _PathDrawMode.player);
    return route != null && route.points.length >= 2 ? route : null;
  }

  List<Offset> _playerActionBasePoints(
    _BoardItem player,
    _BoardRoute? existingRoute,
  ) {
    return existingRoute == null
        ? <Offset>[_itemPosition(player)]
        : existingRoute.points.toList(growable: true);
  }

  List<int> _playerActionBaseDurations(_BoardRoute? existingRoute) {
    return existingRoute == null
        ? <int>[]
        : _normalizedRouteSegmentDurations(
            pointCount: existingRoute.points.length,
            rawDurationsMs: existingRoute.segmentDurationsMs,
          ).toList(growable: true);
  }

  List<Offset> _playerActionPointsFromBase({
    required Offset start,
    required Offset end,
    List<Offset>? points,
  }) {
    if (points == null || points.length < 2) {
      return <Offset>[start, end];
    }
    return <Offset>[start, ...points.skip(1)];
  }

  Offset _projectedCarryPoint(
    List<Offset> points,
    int index, {
    required Offset fallbackTarget,
  }) {
    final current = points[index];
    if (index + 1 < points.length) {
      return _ballCarryPointFromOrigin(current, toward: points[index + 1]);
    }
    if (index > 0) {
      final previous = points[index - 1];
      final projected = _clampedBoardPoint(
        current.dx + (current.dx - previous.dx),
        current.dy + (current.dy - previous.dy),
      );
      return _ballCarryPointFromOrigin(current, toward: projected);
    }
    return _ballCarryPointFromOrigin(current, toward: fallbackTarget);
  }

  void _upsertPossessedBallCarryRoute({
    required _BoardItem player,
    required List<Offset> actionPoints,
    required List<int> segmentDurationsMs,
    required int stageIndex,
  }) {
    if (actionPoints.length < 2 || !_playerHasBallForFlow(player)) {
      return;
    }
    final startOverride = _projectedCarryPoint(
      actionPoints,
      0,
      fallbackTarget: actionPoints.last,
    );
    final possession = _ballPossessionForNextPlayerAction(
      player,
      target: actionPoints.last,
      startOverride: startOverride,
    );
    if (possession == null) return;
    final ballPoints = <Offset>[
      possession.start,
      for (var i = 1; i < actionPoints.length; i++)
        _projectedCarryPoint(
          actionPoints,
          i,
          fallbackTarget: actionPoints.last,
        ),
    ];
    _upsertRouteForItem(
      kind: _PathDrawMode.ball,
      item: possession.ball,
      points: ballPoints,
      segmentDurationsMs: segmentDurationsMs,
      stageIndex: stageIndex,
      actorItemId: player.id,
      targetItemId: player.id,
      createNewRoute: true,
    );
  }

  bool _applyMoveTargetAction(
    _BoardItem selected,
    Offset target, {
    int durationMs = 720,
    List<Offset>? points,
    bool carryPossessedBall = true,
  }) {
    final player = _playerForTargetAction(selected);
    if (player == null) return false;
    return _applyQuickPlayerToPointTemplate(
      player: player,
      end: target,
      points: points,
      segmentDurationsMs: <int>[durationMs],
      carryPossessedBall: carryPossessedBall,
    );
  }

  bool _applyBallTargetAction({
    required _BoardItem selected,
    required Offset target,
    required int durationMs,
    List<Offset>? points,
    List<int>? segmentDurationsMs,
    _BoardItem? targetItem,
    _BoardItem? selectedItemOverride,
    int? stageIndex,
  }) {
    final player = _playerForTargetAction(selected);
    if (player == null) return false;
    final chainedPlayerRoute = _playerRouteForChainedAction(player);
    final chainedBallStart = chainedPlayerRoute == null
        ? null
        : _ballCarryPointFromOrigin(
            chainedPlayerRoute.points.last,
            toward: target,
          );
    final possession = _ballPossessionForNextPlayerAction(
      player,
      target: target,
      startOverride: chainedBallStart,
    );
    if (possession == null) return false;
    final ball = possession.ball;
    final resolvedBallStart = possession.start;
    final nextSelectedItem = selectedItemOverride ??
        (targetItem?.type == _BoardItemType.player ? targetItem : null) ??
        selected;
    final nextStage = stageIndex ??
        _stageForNextPlayerAction(player) ??
        (chainedPlayerRoute == null
            ? 1
            : _normalizedRouteStageIndex(chainedPlayerRoute.stageIndex + 1));
    return _applyQuickBallToPointTemplate(
      ball: ball,
      end: target,
      points: points ?? <Offset>[resolvedBallStart, target],
      segmentDurationsMs: segmentDurationsMs ?? <int>[durationMs],
      selectedItemOverride: nextSelectedItem,
      stageIndex: nextStage,
      actorItemId: player.id,
      targetItemId: targetItem?.id,
      createNewRoute: true,
    );
  }

  bool _applyPassAndMoveTargetAction(
    _BoardItem selected,
    Offset target, {
    _BoardItem? targetItem,
  }) {
    final player = _playerForTargetAction(selected);
    if (player == null) return false;
    final existingRoute = _playerRouteForChainedAction(player);
    final basePoints = _playerActionBasePoints(player, existingRoute);
    final start = basePoints.last;
    final passEnd = target;
    final ballStart = existingRoute == null
        ? null
        : _ballCarryPointFromOrigin(start, toward: passEnd);
    final possession = _ballPossessionForNextPlayerAction(
      player,
      target: target,
      startOverride: ballStart,
    );
    if (possession == null) return false;
    final ball = possession.ball;
    final resolvedBallStart = possession.start;
    final supportY = start.dy < 0.5 ? 0.08 : -0.08;
    final moveEnd = targetItem?.type == _BoardItemType.player
        ? _midTargetPoint(start, passEnd, yOffset: supportY)
        : passEnd;
    _stopRoutePlayback(restoreStart: false);
    setState(() {
      _upsertRouteForItem(
        kind: _PathDrawMode.ball,
        item: ball,
        points: <Offset>[resolvedBallStart, passEnd],
        segmentDurationsMs: const <int>[680],
        stageIndex: _stageForNextPlayerAction(player) ??
            (existingRoute == null
                ? 1
                : _normalizedRouteStageIndex(existingRoute.stageIndex + 1)),
        actorItemId: player.id,
        targetItemId: targetItem?.id,
        createNewRoute: true,
      );
      final moveRoute = _upsertRouteForItem(
        kind: _PathDrawMode.player,
        item: player,
        points: <Offset>[...basePoints, moveEnd],
        segmentDurationsMs: <int>[
          ..._playerActionBaseDurations(existingRoute),
          760,
        ],
        stageIndex: _registeredStageForNextAction() ??
            existingRoute?.stageIndex ??
            _suggestedStageForNewRoute(_PathDrawMode.player),
        actorItemId: player.id,
        replacementRoute: existingRoute,
      );
      _selectQuickActionRoute(moveRoute, player);
      _pendingTargetAction = _SketchTargetAction.move;
    });
    _scheduleAutoSave();
    return true;
  }

  bool _applyReceiveMoveTargetAction(_BoardItem selected, Offset target) {
    final player = _playerForTargetAction(selected);
    if (player == null) return false;
    final hasBallRoute = _currentPage.routes.any(
      (route) => route.kind == _PathDrawMode.ball && route.points.length >= 2,
    );
    if (!hasBallRoute) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_l10n.trainingSketchAddBallFirst)),
      );
      return false;
    }
    return _applyQuickPlayerToPointTemplate(
      player: player,
      end: target,
      segmentDurationsMs: const <int>[760],
    );
  }

  bool _applyReturnMoveTargetAction(_BoardItem selected, Offset target) {
    final player = _playerForTargetAction(selected);
    if (player == null) return false;
    final start = _itemPosition(player);
    return _applyQuickPlayerToPointTemplate(
      player: player,
      end: start,
      points: <Offset>[start, target, start],
      segmentDurationsMs: const <int>[540, 620],
      carryPossessedBall: _playerHasBallForFlow(player),
    );
  }

  bool _applyOverlapTargetAction(_BoardItem selected, Offset target) {
    final player = _playerForTargetAction(selected);
    if (player == null) return false;
    final start = _itemPosition(player);
    final laneOffset = start.dy < 0.5 ? 0.08 : -0.08;
    final lane = _midTargetPoint(start, target, yOffset: laneOffset);
    return _applyQuickPlayerToPointTemplate(
      player: player,
      end: target,
      points: <Offset>[start, lane, target],
      segmentDurationsMs: const <int>[520, 720],
    );
  }

  bool _applyCarryBallTargetAction(
    _BoardItem selected,
    Offset target, {
    required List<int> segmentDurationsMs,
    double curveYOffset = 0,
  }) {
    final player = _playerForTargetAction(selected);
    if (player == null) return false;

    final existingRoute = _playerRouteForChainedAction(player);
    final basePoints = _playerActionBasePoints(player, existingRoute);
    final playerStart = basePoints.last;
    final ballStart = existingRoute == null
        ? (_stageAfterSelectedRoute() == null
            ? null
            : _ballCarryPointForPlayer(player, toward: target))
        : _ballCarryPointFromOrigin(playerStart, toward: target);
    final possessionRoute = _currentBallRouteForPlayer(player);
    final possession = _ballPossessionForNextPlayerAction(
      player,
      target: target,
      startOverride: ballStart,
    );
    if (possession == null) return false;
    final ball = possession.ball;
    final resolvedBallStart = possession.start;
    final playerMiddle = _midTargetPoint(
      playerStart,
      target,
      yOffset: curveYOffset,
    );
    final ballMiddle = _midTargetPoint(
      resolvedBallStart,
      target,
      yOffset: curveYOffset,
    );
    final pairedStage = _pairedCarryStageFor(player: player, ball: ball);
    final continueUnownedPossessionRoute = possessionRoute != null &&
        possessionRoute.actorItemId == null &&
        possessionRoute.targetItemId == null;
    final stageIndex = _registeredStageForNextAction() ??
        existingRoute?.stageIndex ??
        (continueUnownedPossessionRoute
            ? pairedStage
            : _stageForNextPlayerAction(player) ?? pairedStage);
    _stopRoutePlayback(restoreStart: false);
    setState(() {
      _upsertRouteForItem(
        kind: _PathDrawMode.ball,
        item: ball,
        points: <Offset>[resolvedBallStart, ballMiddle, target],
        segmentDurationsMs: segmentDurationsMs,
        stageIndex: stageIndex,
        actorItemId: player.id,
        createNewRoute: true,
      );
      final playerRoute = _upsertRouteForItem(
        kind: _PathDrawMode.player,
        item: player,
        points: <Offset>[...basePoints, playerMiddle, target],
        segmentDurationsMs: <int>[
          ..._playerActionBaseDurations(existingRoute),
          ...segmentDurationsMs,
        ],
        stageIndex: stageIndex,
        actorItemId: player.id,
        replacementRoute: existingRoute,
      );
      _selectQuickActionRoute(playerRoute, player);
    });
    _scheduleAutoSave();
    return true;
  }

  bool _applyDribbleTargetAction(_BoardItem selected, Offset target) {
    return _applyCarryBallTargetAction(
      selected,
      target,
      segmentDurationsMs: const <int>[440, 520],
      curveYOffset: -0.035,
    );
  }

  bool _applyShotTargetAction(_BoardItem selected, Offset target) {
    return _applyBallTargetAction(
      selected: selected,
      target: target,
      durationMs: 620,
    );
  }

  bool _applyCrossTargetAction(_BoardItem selected, Offset target) {
    final player = _playerForTargetAction(selected);
    if (player == null) return false;
    final possession = _ballPossessionForNextPlayerAction(
      player,
      target: target,
    );
    if (possession == null) return false;
    final ball = possession.ball;
    final start = possession.start;
    final middle = _midTargetPoint(start, target, yOffset: -0.04);
    return _applyQuickBallToPointTemplate(
      ball: ball,
      end: target,
      points: <Offset>[start, middle, target],
      segmentDurationsMs: const <int>[520, 680],
      selectedItemOverride:
          selected.type == _BoardItemType.player ? selected : null,
      stageIndex: _stageForNextPlayerAction(player),
      actorItemId: player.id,
      createNewRoute: true,
    );
  }

  bool _applyDriveTargetAction(_BoardItem selected, Offset target) {
    return _applyCarryBallTargetAction(
      selected,
      target,
      segmentDurationsMs: const <int>[420, 560],
    );
  }

  bool _applyScreenTargetAction(_BoardItem selected, Offset target) {
    final player = _playerForTargetAction(selected);
    if (player == null) return false;
    return _applyQuickPlayerToPointTemplate(
      player: player,
      end: target,
      points: <Offset>[_itemPosition(player), target, target],
      segmentDurationsMs: const <int>[520, 420],
    );
  }

  _BoardItem _ensureTrainingPropForAction({
    required _BoardItemType type,
    required Offset target,
    _BoardItem? targetItem,
  }) {
    if (targetItem?.type == type) return targetItem!;
    final nearest = _nearestItemOfType(type, target);
    if (nearest != null &&
        (_itemPosition(nearest) - target).distance <= 0.055) {
      return nearest;
    }
    final prop = _BoardItem(
      id: _nextBoardItemId(),
      type: type,
      x: target.dx,
      y: target.dy,
      size: 32,
      rotationDeg: 0,
      color: _defaultColorFor(type),
    );
    _currentPage.items.add(prop);
    return prop;
  }

  bool _applyConeTurnTargetAction(
    _BoardItem selected,
    Offset target, {
    _BoardItem? targetItem,
  }) {
    final player = _playerForTargetAction(selected);
    if (player == null) return false;
    _stopRoutePlayback(restoreStart: false);
    setState(() {
      final cone = _ensureTrainingPropForAction(
        type: _BoardItemType.cone,
        target: target,
        targetItem: targetItem,
      );
      final existingRoute = _playerRouteForChainedAction(player);
      final basePoints = _playerActionBasePoints(player, existingRoute);
      final start = basePoints.last;
      final center = _itemPosition(cone);
      final delta = center - start;
      final direction =
          delta.distance < 0.01 ? const Offset(1, 0) : delta / delta.distance;
      final normal = Offset(-direction.dy, direction.dx);
      final approach = _clampedBoardPoint(
        center.dx - (direction.dx * 0.09),
        center.dy - (direction.dy * 0.09),
      );
      final sideA = _clampedBoardPoint(
        center.dx + (normal.dx * 0.045),
        center.dy + (normal.dy * 0.045),
      );
      final around = _clampedBoardPoint(
        center.dx + (direction.dx * 0.045),
        center.dy + (direction.dy * 0.045),
      );
      final sideB = _clampedBoardPoint(
        center.dx - (normal.dx * 0.045),
        center.dy - (normal.dy * 0.045),
      );
      final exit = _clampedBoardPoint(
        center.dx + (direction.dx * 0.11),
        center.dy + (direction.dy * 0.11),
      );
      final actionPoints = <Offset>[
        start,
        approach,
        sideA,
        around,
        sideB,
        exit,
      ];
      final actionDurations = <int>[360, 280, 260, 260, 420];
      final stageIndex = _registeredStageForNextAction() ??
          existingRoute?.stageIndex ??
          _suggestedStageForNewRoute(_PathDrawMode.player);
      _upsertPossessedBallCarryRoute(
        player: player,
        actionPoints: actionPoints,
        segmentDurationsMs: actionDurations,
        stageIndex: stageIndex,
      );
      final route = _upsertRouteForItem(
        kind: _PathDrawMode.player,
        item: player,
        points: <Offset>[...basePoints, ...actionPoints.skip(1)],
        segmentDurationsMs: <int>[
          ..._playerActionBaseDurations(existingRoute),
          ...actionDurations,
        ],
        stageIndex: stageIndex,
        actorItemId: player.id,
        replacementRoute: existingRoute,
      );
      _selectQuickActionRoute(route, player);
    });
    _scheduleAutoSave();
    return true;
  }

  bool _applyHurdleJumpTargetAction(
    _BoardItem selected,
    Offset target, {
    _BoardItem? targetItem,
  }) {
    return _applyObstacleJumpTargetAction(
      selected,
      target,
      type: _BoardItemType.hurdle,
      targetItem: targetItem,
    );
  }

  bool _applyConeJumpTargetAction(
    _BoardItem selected,
    Offset target, {
    _BoardItem? targetItem,
  }) {
    return _applyObstacleJumpTargetAction(
      selected,
      target,
      type: _BoardItemType.cone,
      targetItem: targetItem,
    );
  }

  bool _applyObstacleJumpTargetAction(
    _BoardItem selected,
    Offset target, {
    required _BoardItemType type,
    _BoardItem? targetItem,
  }) {
    final player = _playerForTargetAction(selected);
    if (player == null) return false;
    _stopRoutePlayback(restoreStart: false);
    setState(() {
      final obstacle = _ensureTrainingPropForAction(
        type: type,
        target: target,
        targetItem: targetItem,
      );
      final existingRoute = _playerRouteForChainedAction(player);
      final basePoints = _playerActionBasePoints(player, existingRoute);
      final start = basePoints.last;
      final center = _itemPosition(obstacle);
      final delta = center - start;
      final direction =
          delta.distance < 0.01 ? const Offset(1, 0) : delta / delta.distance;
      if (type == _BoardItemType.hurdle) {
        obstacle.rotationDeg =
            (math.atan2(direction.dy, direction.dx) * 180) / math.pi + 90;
      }
      final takeoff = _clampedBoardPoint(
        center.dx - (direction.dx * 0.075),
        center.dy - (direction.dy * 0.075),
      );
      final landing = _clampedBoardPoint(
        center.dx + (direction.dx * 0.095),
        center.dy + (direction.dy * 0.095),
      );
      final actionPoints = <Offset>[start, takeoff, center, landing];
      final actionDurations = <int>[360, 240, 420];
      final stageIndex = _registeredStageForNextAction() ??
          existingRoute?.stageIndex ??
          _suggestedStageForNewRoute(_PathDrawMode.player);
      _upsertPossessedBallCarryRoute(
        player: player,
        actionPoints: actionPoints,
        segmentDurationsMs: actionDurations,
        stageIndex: stageIndex,
      );
      final route = _upsertRouteForItem(
        kind: _PathDrawMode.player,
        item: player,
        points: <Offset>[...basePoints, ...actionPoints.skip(1)],
        segmentDurationsMs: <int>[
          ..._playerActionBaseDurations(existingRoute),
          ...actionDurations,
        ],
        stageIndex: stageIndex,
        actorItemId: player.id,
        replacementRoute: existingRoute,
      );
      _selectQuickActionRoute(route, player);
    });
    _scheduleAutoSave();
    return true;
  }

  bool _applyServeTargetAction(_BoardItem selected, Offset target) {
    final player = _playerForTargetAction(selected);
    if (player == null) return false;
    final possession = _ballPossessionForNextPlayerAction(
      player,
      target: target,
    );
    if (possession == null) return false;
    final ball = possession.ball;
    final start = possession.start;
    final middle = _clampedBoardPoint(
      start.dx + ((target.dx - start.dx) * 0.45),
      0.50,
    );
    return _applyQuickBallToPointTemplate(
      ball: ball,
      end: target,
      points: <Offset>[start, middle, target],
      segmentDurationsMs: const <int>[360, 620],
      selectedItemOverride:
          selected.type == _BoardItemType.player ? selected : null,
      stageIndex: _stageForNextPlayerAction(player),
      actorItemId: player.id,
      createNewRoute: true,
    );
  }

  bool _applyRallyTargetAction(_BoardItem selected, Offset target) {
    final player = _playerForTargetAction(selected);
    if (player == null) return false;
    final possession = _ballPossessionForNextPlayerAction(
      player,
      target: target,
    );
    if (possession == null) return false;
    final ball = possession.ball;
    final start = possession.start;
    final middle = _clampedBoardPoint(
      start.dx + ((target.dx - start.dx) * 0.50),
      0.50,
    );
    return _applyQuickBallToPointTemplate(
      ball: ball,
      end: target,
      points: <Offset>[start, middle, target],
      segmentDurationsMs: const <int>[460, 560],
      selectedItemOverride:
          selected.type == _BoardItemType.player ? selected : null,
      stageIndex: _stageForNextPlayerAction(player),
      actorItemId: player.id,
      createNewRoute: true,
    );
  }

  void _applyQuickBallToItemTemplate(_BoardItem target) {
    final selected = _selectedItem;
    if (selected == null) return;
    _applyBallTargetAction(
      selected: selected,
      target: _itemActionPoint(target),
      targetItem: target,
      durationMs: 680,
    );
  }

  void _applyQuickBallToNewReceiverTemplate(_BoardItem player) {
    late final _BoardItem receiver;
    setState(() {
      receiver = _createPassReceiverForPlayer(player);
      _selectedItemId = player.id;
      _selectedRouteId = null;
    });
    _applyBallTargetAction(
      selected: player,
      target: _itemActionPoint(receiver),
      targetItem: receiver,
      durationMs: 680,
    );
  }

  bool _applyQuickBallToPointTemplate({
    required _BoardItem ball,
    required Offset end,
    List<Offset>? points,
    List<int>? segmentDurationsMs,
    _BoardItem? selectedItemOverride,
    int? stageIndex,
    String? actorItemId,
    String? targetItemId,
    bool createNewRoute = false,
  }) {
    _stopRoutePlayback(restoreStart: false);
    setState(() {
      final start = _itemPosition(ball);
      final route = _upsertRouteForItem(
        kind: _PathDrawMode.ball,
        item: ball,
        points: points ?? <Offset>[start, end],
        segmentDurationsMs: segmentDurationsMs ?? const <int>[680],
        stageIndex: stageIndex ?? 1,
        actorItemId: actorItemId,
        targetItemId: targetItemId,
        createNewRoute: createNewRoute,
      );
      _selectQuickActionRoute(
        route,
        ball,
        selectedItemOverride: selectedItemOverride,
      );
    });
    _scheduleAutoSave();
    return true;
  }

  bool _applyQuickPlayerToPointTemplate({
    required _BoardItem player,
    required Offset end,
    List<Offset>? points,
    List<int>? segmentDurationsMs,
    bool carryPossessedBall = false,
  }) {
    _stopRoutePlayback(restoreStart: false);
    setState(() {
      final existingRoute = _playerRouteForChainedAction(player);
      final basePoints = _playerActionBasePoints(player, existingRoute);
      final actionPoints = _playerActionPointsFromBase(
        start: basePoints.last,
        end: end,
        points: points,
      );
      final actionDurations = _normalizedRouteSegmentDurations(
        pointCount: actionPoints.length,
        rawDurationsMs: segmentDurationsMs ?? const <int>[720],
      );
      final stageIndex = _registeredStageForNextAction() ??
          existingRoute?.stageIndex ??
          _suggestedStageForNewRoute(_PathDrawMode.player);
      if (carryPossessedBall) {
        _upsertPossessedBallCarryRoute(
          player: player,
          actionPoints: actionPoints,
          segmentDurationsMs: actionDurations,
          stageIndex: stageIndex,
        );
      }
      final route = _upsertRouteForItem(
        kind: _PathDrawMode.player,
        item: player,
        points: <Offset>[...basePoints, ...actionPoints.skip(1)],
        segmentDurationsMs: <int>[
          ..._playerActionBaseDurations(existingRoute),
          ...actionDurations,
        ],
        stageIndex: stageIndex,
        actorItemId: player.id,
        replacementRoute: existingRoute,
      );
      _selectQuickActionRoute(route, player);
    });
    _scheduleAutoSave();
    return true;
  }

  Color _activeRoutePreviewColor() {
    final replacementRoute = _routeToUpdateForPath(_pathDrawMode);
    if (replacementRoute != null) {
      return replacementRoute.color;
    }
    final selectedItem = _selectedItem;
    if (selectedItem != null &&
        selectedItem.type == _boardItemTypeForRouteKind(_pathDrawMode)) {
      return selectedItem.color;
    }
    return _defaultRouteColor(_pathDrawMode);
  }

  String _pathModeHint() {
    final routeableCount = _routeableItemCount(_pathDrawMode);
    if (routeableCount == 0) {
      return _pathDrawMode == _PathDrawMode.player
          ? _l10n.trainingSketchAddPlayerFirst
          : _l10n.trainingSketchAddBallFirst;
    }
    if (_routeReplaceMode) {
      return _l10n.trainingSketchRouteReplaceHint;
    }
    final selectedItem = _selectedItem;
    final expectedType = _boardItemTypeForRouteKind(_pathDrawMode);
    if (selectedItem != null && selectedItem.type == expectedType) {
      return _pathDrawMode == _PathDrawMode.player
          ? _l10n.trainingSketchSelectedPlayerRouteHint
          : _l10n.trainingSketchSelectedBallRouteHint;
    }
    if (_routesForKind(_pathDrawMode).length >= routeableCount) {
      return _pathDrawMode == _PathDrawMode.player
          ? _l10n.trainingSketchPlayerRouteLimitReached
          : _l10n.trainingSketchBallRouteLimitReached;
    }
    return _pathDrawMode == _PathDrawMode.player
        ? _l10n.trainingSketchPlayerRouteHint
        : _l10n.trainingSketchBallRouteHint;
  }

  void _playPlayerPath(bool isKo) {
    if (_playController.isAnimating) {
      _stopRoutePlayback();
      return;
    }
    final playableRoutes = _currentPage.routes
        .where((route) => route.points.length >= 2)
        .toList(growable: false);
    if (playableRoutes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_l10n.trainingSketchDrawRouteFirst)),
      );
      return;
    }
    _syncCurrentPageRouteColors();
    final tracks = _resolvePlaybackTracks();
    if (tracks.isEmpty) {
      final firstRoute = playableRoutes.first;
      final message = firstRoute.kind == _PathDrawMode.player
          ? _l10n.trainingSketchAddPlayerFirst
          : _l10n.trainingSketchAddBallFirst;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }
    _stopRoutePlayback(restoreStart: false);
    final playbackDuration = _playbackDurationForTracks(tracks);
    setState(() {
      _playbackTracks = tracks;
      for (final track in _playbackTracks) {
        final firstPoint = track.route.points.first;
        track.item.x = firstPoint.dx.clamp(0.03, 0.97);
        track.item.y = firstPoint.dy.clamp(0.03, 0.97);
      }
    });
    _playController.duration = playbackDuration;
    _playController
      ..stop()
      ..reset();
    _playController.forward(from: 0.0);
  }

  void _onPlayTick() {
    if (_playbackTracks.isEmpty) return;
    final duration = _playController.duration;
    if (duration == null || duration.inMicroseconds <= 0) return;
    final elapsedSeconds = (duration.inMicroseconds * _playController.value) /
        Duration.microsecondsPerSecond;
    final routeElapsedSeconds =
        elapsedSeconds * _playSpeed.clamp(0.75, 1.5).toDouble();
    setState(() {
      for (final track in _playbackTracks) {
        if (track.segments.isEmpty) continue;
        final position = _samplePlaybackTrack(track, routeElapsedSeconds);
        track.item.x = position.dx.clamp(0.03, 0.97);
        track.item.y = position.dy.clamp(0.03, 0.97);
      }
    });
  }

  void _onPlayStatusChanged(AnimationStatus status) {
    if (status != AnimationStatus.completed) {
      return;
    }
    setState(() {
      for (final track in _playbackTracks) {
        track.item.x = track.startPosition.dx;
        track.item.y = track.startPosition.dy;
      }
      _playbackTracks = const <_PlaybackTrack>[];
    });
    _playController.reset();
  }

  void _stopRoutePlayback({bool restoreStart = true}) {
    _playController.stop();
    _playController.reset();
    setState(() {
      if (restoreStart) {
        for (final track in _playbackTracks) {
          track.item.x = track.startPosition.dx;
          track.item.y = track.startPosition.dy;
        }
      }
      _playbackTracks = const <_PlaybackTrack>[];
    });
  }

  Future<void> _toggleMemoListening(bool isKo) async {
    final localeId =
        Localizations.localeOf(context).languageCode == 'ko' ? 'ko_KR' : null;
    if (_isListeningMemo) {
      _memoSession++;
      final recognized = _memoRecognizedWords;
      final shouldCommit = !_memoCommitted;
      if (mounted) {
        setState(() {
          _isListeningMemo = false;
          _memoRecognizedWords = '';
          _memoCommitted = false;
        });
      }
      await _speech.cancel();
      if (!mounted) return;
      if (shouldCommit && recognized.trim().isNotEmpty) {
        _commitMemoRecognizedText(
          recognized: recognized,
          isKoreanLocale: Localizations.localeOf(context).languageCode == 'ko',
        );
      }
      return;
    }
    final available = await _ensureSpeechInitialized();
    if (!available) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isKo ? '마이크를 사용할 수 없습니다.' : 'Voice input is unavailable.',
          ),
        ),
      );
      return;
    }
    final session = ++_memoSession;
    setState(() {
      _isListeningMemo = true;
      _memoRecognizedWords = '';
      _memoCommitted = false;
    });
    await _speech.listen(
      localeId: localeId,
      onResult: (result) {
        if (session != _memoSession) return;
        final text = result.recognizedWords.trim();
        if (text.isEmpty) return;
        _memoRecognizedWords = text;
      },
    );
  }

  Future<bool> _ensureSpeechInitialized() async {
    if (_speechInitialized) return _speechAvailable;
    _speechInitialized = true;
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {
        if (!_isListeningMemo) return;
        if (status == 'done' || status == 'notListening') {
          final recognized = _memoRecognizedWords;
          if (!_memoCommitted && recognized.trim().isNotEmpty) {
            _commitMemoRecognizedText(
              recognized: recognized,
              isKoreanLocale:
                  Localizations.localeOf(context).languageCode == 'ko',
            );
          }
          if (!mounted) return;
          setState(() {
            _isListeningMemo = false;
            _memoRecognizedWords = '';
            _memoCommitted = false;
          });
        }
      },
      onError: (_) {
        if (!mounted) return;
        setState(() {
          _isListeningMemo = false;
          _memoRecognizedWords = '';
          _memoCommitted = false;
        });
      },
    );
    return _speechAvailable;
  }

  void _commitMemoRecognizedText({
    required String recognized,
    required bool isKoreanLocale,
  }) {
    final normalized = recognized.trim();
    if (normalized.isEmpty || _memoCommitted) return;
    final currentText = _methodController.text;
    final normalizedCurrent = currentText.trimRight();
    if (normalizedCurrent.isNotEmpty &&
        normalizedCurrent.endsWith(normalized)) {
      _memoCommitted = true;
      return;
    }
    final needsSpacing = !isKoreanLocale &&
        currentText.isNotEmpty &&
        !RegExp(r'\s$').hasMatch(currentText);
    final separator = needsSpacing ? ' ' : '';
    final nextText = '$currentText$separator$normalized';
    _methodController.value = _methodController.value.copyWith(
      text: nextText,
      selection: TextSelection.collapsed(offset: nextText.length),
      composing: TextRange.empty,
    );
    _currentPage.methodText = nextText;
    _memoCommitted = true;
    _scheduleAutoSave();
  }

  Duration _playbackDurationForTracks(List<_PlaybackTrack> tracks) {
    if (tracks.isEmpty) {
      return _minPlaybackDuration;
    }
    final slowestTrackMs = tracks.fold<int>(
      0,
      (currentMax, track) =>
          math.max(currentMax, (track.durationSeconds * 1000).round()),
    );
    final adjustedMs =
        (slowestTrackMs / _playSpeed.clamp(0.75, 1.5).toDouble()).round();
    return Duration(
      milliseconds: math.max(adjustedMs, _minPlaybackDuration.inMilliseconds),
    );
  }

  double _playbackSpeedMetersPerSecond(_PathDrawMode kind) {
    return switch (kind) {
      _PathDrawMode.player => _playerPlaybackSpeedMetersPerSecond,
      _PathDrawMode.ball => _ballPlaybackSpeedMetersPerSecond,
    };
  }

  List<int> _normalizedRouteSegmentDurations({
    required int pointCount,
    required List<int>? rawDurationsMs,
  }) {
    final segmentCount = math.max(0, pointCount - 1);
    if (segmentCount == 0) return const <int>[];
    final source = rawDurationsMs ?? const <int>[];
    return List<int>.generate(segmentCount, (index) {
      if (index >= source.length) return 120;
      return source[index].clamp(16, 4000).toInt();
    }, growable: false);
  }

  List<_PlaybackSegment> _playbackSegmentsForRoute({
    required List<Offset> points,
    required List<int> segmentDurationsMs,
    required double totalDistanceMeters,
    required double speedMetersPerSecond,
  }) {
    if (points.length < 2 || totalDistanceMeters <= 0) {
      return const <_PlaybackSegment>[];
    }
    final segmentDistances = <double>[];
    for (var i = 0; i < points.length - 1; i++) {
      segmentDistances.add(_segmentDistanceMeters(points[i], points[i + 1]));
    }
    final segments = <_PlaybackSegment>[];
    for (var index = 0; index < segmentDistances.length; index++) {
      final distanceMeters = segmentDistances[index];
      final explicitDurationMs =
          index < segmentDurationsMs.length ? segmentDurationsMs[index] : 0;
      if (distanceMeters <= _minPlaybackSegmentDistanceMeters &&
          explicitDurationMs <= 0) {
        continue;
      }
      final durationSeconds = explicitDurationMs > 0
          ? explicitDurationMs / 1000
          : distanceMeters / speedMetersPerSecond;
      segments.add(
        _PlaybackSegment(
          start: points[index],
          end: points[index + 1],
          durationSeconds: math.max(durationSeconds, 0.016),
        ),
      );
    }
    if (segments.isEmpty) {
      return <_PlaybackSegment>[
        _PlaybackSegment(
          start: points.first,
          end: points.last,
          durationSeconds: totalDistanceMeters / speedMetersPerSecond,
        ),
      ];
    }
    return segments;
  }

  Offset _samplePlaybackTrack(_PlaybackTrack track, double elapsedSeconds) {
    final durationSeconds = track.durationSeconds;
    if (durationSeconds <= 0) return track.segments.last.end;
    final acceleratedElapsedSeconds = _acceleratedPlaybackElapsedSeconds(
      elapsedSeconds: elapsedSeconds,
      durationSeconds: durationSeconds,
      kind: track.route.kind,
    );
    return _samplePlaybackSegments(track.segments, acceleratedElapsedSeconds);
  }

  double _acceleratedPlaybackElapsedSeconds({
    required double elapsedSeconds,
    required double durationSeconds,
    required _PathDrawMode kind,
  }) {
    if (durationSeconds <= 0) return 0;
    final progress =
        (elapsedSeconds / durationSeconds).clamp(0.0, 1.0).toDouble();
    final rampFraction = switch (kind) {
      _PathDrawMode.player => _playerPlaybackAccelerationFraction,
      _PathDrawMode.ball => _ballPlaybackAccelerationFraction,
    };
    return _acceleratedPlaybackProgress(progress, rampFraction: rampFraction) *
        durationSeconds;
  }

  double _acceleratedPlaybackProgress(
    double progress, {
    required double rampFraction,
  }) {
    final t = progress.clamp(0.0, 1.0).toDouble();
    final ramp = rampFraction.clamp(0.05, 0.35).toDouble();
    final linearSpan = math.max(0.0, 1 - (ramp * 2));
    final peakSpeed = 1 / (linearSpan + ramp);
    if (t <= ramp) {
      return (0.5 * peakSpeed * t * t / ramp).clamp(0.0, 1.0).toDouble();
    }
    final rampDistance = 0.5 * peakSpeed * ramp;
    if (t <= ramp + linearSpan) {
      return (rampDistance + peakSpeed * (t - ramp)).clamp(0.0, 1.0).toDouble();
    }
    final decelT = t - ramp - linearSpan;
    final beforeDecel = rampDistance + peakSpeed * linearSpan;
    return (beforeDecel +
            peakSpeed * decelT -
            (0.5 * peakSpeed * decelT * decelT / ramp))
        .clamp(0.0, 1.0)
        .toDouble();
  }

  Offset _samplePlaybackSegments(
    List<_PlaybackSegment> segments,
    double elapsedSeconds,
  ) {
    if (segments.isEmpty) return const Offset(0.5, 0.5);
    final target = elapsedSeconds.clamp(0.0, 1000000.0).toDouble();
    var walkedSeconds = 0.0;
    for (final segment in segments) {
      final next = walkedSeconds + segment.durationSeconds;
      if (next >= target) {
        final localT = ((target - walkedSeconds) / segment.durationSeconds)
            .clamp(0.0, 1.0)
            .toDouble();
        return Offset.lerp(segment.start, segment.end, localT) ?? segment.start;
      }
      walkedSeconds = next;
    }
    return segments.last.end;
  }

  double _pathDistanceMeters(List<Offset> points) {
    if (points.length < 2) return 0;
    var total = 0.0;
    for (var i = 0; i < points.length - 1; i++) {
      total += _segmentDistanceMeters(points[i], points[i + 1]);
    }
    return total;
  }

  double _segmentDistanceMeters(Offset start, Offset end) {
    final dxMeters =
        (end.dx - start.dx).abs() * _trainingBoardReferenceLengthMeters;
    final dyMeters =
        (end.dy - start.dy).abs() * _trainingBoardReferenceWidthMeters;
    return math.sqrt((dxMeters * dxMeters) + (dyMeters * dyMeters));
  }

  @override
  void dispose() {
    _memoSession++;
    _autoSaveTimer?.cancel();
    unawaited(_speech.cancel());
    unawaited(_setSketchOrientationLock(landscape: false));
    _playController
      ..removeListener(_onPlayTick)
      ..removeStatusListener(_onPlayStatusChanged)
      ..dispose();
    _methodController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _syncRouteResult();
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final size = MediaQuery.sizeOf(context);
    final isLandscape = size.width > size.height;
    final canPopWithoutPrompt = widget.readOnly || !_hasUnsavedChanges;
    return PopScope(
      canPop: canPopWithoutPrompt,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || canPopWithoutPrompt) return;
        final navigator = Navigator.of(context);
        final shouldPop = await _shouldPopOnSystemBack(isKo);
        if (!mounted || !shouldPop) return;
        navigator.pop(
          _isManagedMode ? _selectedBoardIds.toList(growable: false) : null,
        );
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: isLandscape
            ? null
            : AppBar(
                title: _buildAppBarTitle(isKo),
                leading: IconButton(
                  onPressed: () => _handleBackPressed(isKo),
                  icon: const Icon(Icons.arrow_back),
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                ),
                actions: _buildTopBarActions(isKo, isLandscape: false),
              ),
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _dismissKeyboard,
          child: isLandscape
              ? _buildLandscapeBody(isKo)
              : _buildPortraitBody(isKo),
        ),
      ),
    );
  }

  Widget _buildPortraitBody(bool isKo) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Column(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: !_showPortraitMemo
                ? const SizedBox.shrink()
                : Padding(
                    key: const ValueKey('training-portrait-memo-panel'),
                    padding: const EdgeInsets.only(top: 8),
                    child: _buildPortraitMemoPanel(isKo),
                  ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildBoardCanvas()),
          if (!widget.readOnly) ...[
            const SizedBox(height: 8),
            _buildPortraitToolStrip(isKo),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: !_showPortraitInspector
                  ? const SizedBox.shrink()
                  : Padding(
                      key: const ValueKey('training-portrait-inspector-panel'),
                      padding: const EdgeInsets.only(top: 8),
                      child: _buildPortraitInspectorPanel(isKo),
                    ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            _buildReadOnlyInfoPanel(),
          ],
        ],
      ),
    );
  }

  Widget _buildLandscapeBody(bool isKo) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          children: [
            _buildLandscapeTopBar(isKo),
            const SizedBox(height: 8),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final showSidePanel =
                      _showLandscapeMemo || _showLandscapeControls;
                  final panelWidth = math.min(
                    360.0,
                    constraints.maxWidth * 0.34,
                  );
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _buildBoardCanvas()),
                      if (showSidePanel) ...[
                        const SizedBox(width: 10),
                        SizedBox(
                          width: panelWidth,
                          child: _buildLandscapeSidePanel(isKo),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLandscapeTopBar(bool isKo) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: theme.colorScheme.surface.withValues(alpha: 0.96),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _handleBackPressed(isKo),
            icon: const Icon(Icons.arrow_back),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          ),
          const SizedBox(width: 4),
          Expanded(child: _buildAppBarTitle(isKo)),
          ..._buildTopBarActions(isKo, isLandscape: true),
        ],
      ),
    );
  }

  Widget _buildLandscapeSidePanel(bool isKo) {
    final showMemo = _showLandscapeMemo;
    final showControls = _showLandscapeControls;
    if (showMemo && showControls) {
      return Column(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 180),
            child: _buildLandscapeMemoPanel(isKo),
          ),
          const SizedBox(height: 10),
          Expanded(child: _buildLandscapeControlPanel(isKo)),
        ],
      );
    }
    if (showControls) {
      return _buildLandscapeControlPanel(isKo);
    }
    return _buildLandscapeMemoPanel(isKo);
  }

  Widget _buildLandscapeControlPanel(bool isKo) {
    if (widget.readOnly) {
      return _buildReadOnlyInfoPanel();
    }
    return Container(
      key: const ValueKey('training-landscape-control-panel'),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.96),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ListView(
        children: [
          _buildToolButtons(isKo),
          const SizedBox(height: 12),
          _buildSelectedTools(isKo),
        ],
      ),
    );
  }

  Widget _buildLandscapeMemoPanel(bool isKo) {
    return Container(
      key: const ValueKey('training-landscape-memo-panel'),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.96),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () => setState(() => _showLandscapeMemo = false),
              icon: const Icon(Icons.close),
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            ),
          ),
          _buildMethodTextInput(isKo, compact: true),
        ],
      ),
    );
  }

  Widget _buildPortraitMemoPanel(bool isKo) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 168),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: SingleChildScrollView(child: _buildMethodTextInput(isKo)),
    );
  }

  Widget _buildPortraitToolStrip(bool isKo) {
    final buttons = _buildToolButtonsList(isKo);
    return SizedBox(
      height: 46,
      child: ListView.separated(
        key: const ValueKey('training-portrait-tool-strip'),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) => buttons[index],
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemCount: buttons.length,
      ),
    );
  }

  Widget _buildPortraitInspectorPanel(bool isKo) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 228),
      child: SingleChildScrollView(child: _buildSelectedTools(isKo)),
    );
  }

  Widget _buildBoardCanvas() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final surface = _boardSurfaceForSport(_currentSportId);
        return RepaintBoundary(
          key: _boardPdfBoundaryKey,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: _boardSurfaceGradient(surface),
            ),
            clipBehavior: Clip.antiAlias,
            child: GestureDetector(
              key: const ValueKey('training-board-canvas'),
              behavior: HitTestBehavior.opaque,
              onPanStart: widget.readOnly
                  ? null
                  : _penMode
                      ? (details) =>
                          _startStroke(details.localPosition, width, height)
                      : _pathMode
                          ? (details) => _startPlayerPath(
                              details.localPosition, width, height)
                          : (details) => _startSelectedRouteEndDrag(
                                details.localPosition,
                                width,
                                height,
                              ),
              onPanUpdate: widget.readOnly
                  ? null
                  : _penMode
                      ? (details) => _appendStrokePoint(
                          details.localPosition, width, height)
                      : _pathMode
                          ? (details) => _appendPlayerPath(
                              details.localPosition, width, height)
                          : (details) => _updateSelectedRouteEndDrag(
                                details.localPosition,
                                width,
                                height,
                              ),
              onPanEnd: widget.readOnly
                  ? null
                  : _penMode
                      ? (_) => _endStroke()
                      : _pathMode
                          ? (_) => _endPlayerPath()
                          : (_) => _endSelectedRouteEndDrag(),
              onTapUp: widget.readOnly
                  ? null
                  : (_pathMode || _pendingTargetAction != null)
                      ? (details) => _handleBoardTap(
                            details.localPosition,
                            width,
                            height,
                          )
                      : null,
              child: Stack(
                children: [
                  CustomPaint(
                    key: ValueKey<String>(
                      'training-board-surface-${surface.name}',
                    ),
                    size: Size(width, height),
                    painter: _SportSurfacePainter(
                      surface: surface,
                      showTacticalOverlay: _showTacticalOverlay,
                    ),
                  ),
                  CustomPaint(
                    size: Size(width, height),
                    painter: _PlayerPathPainter(
                      routes: _playController.isAnimating
                          ? const <_BoardRoute>[]
                          : _currentPage.routes,
                      selectedRouteId: _selectedRouteId,
                      activeRoutePoints: _activeRoutePoints,
                      activeRouteColor: _activeRoutePreviewColor(),
                      activeRouteKind: _pathDrawMode,
                    ),
                  ),
                  CustomPaint(
                    size: Size(width, height),
                    painter: _InkPainter(
                      strokes: _currentPage.strokes,
                      activeStrokePoints: _activeStroke,
                      activeStrokeColor: _penColor,
                    ),
                  ),
                  IgnorePointer(
                    ignoring: _playController.isAnimating,
                    child: Stack(
                      children: [
                        for (final item in _boardItemsInPaintOrder())
                          Positioned(
                            left: (item.x * width) - 26,
                            top: (item.y * height) - 26,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _handleBoardItemTap(item),
                              onPanStart: widget.readOnly
                                  ? null
                                  : (_) => _startItemMove(item),
                              onPanUpdate: widget.readOnly
                                  ? null
                                  : (details) => _updateItemMoveByDelta(
                                        item,
                                        delta: details.delta,
                                        boardWidth: width,
                                        boardHeight: height,
                                      ),
                              onPanEnd: widget.readOnly
                                  ? null
                                  : (_) => _endItemMove(),
                              onPanCancel:
                                  widget.readOnly ? null : _endItemMove,
                              onLongPressStart: widget.readOnly
                                  ? null
                                  : (_) => _startLongPressItemMove(item),
                              onLongPressMoveUpdate: widget.readOnly
                                  ? null
                                  : (details) => _updateLongPressItemMove(
                                        item,
                                        offsetFromOrigin:
                                            details.offsetFromOrigin,
                                        boardWidth: width,
                                        boardHeight: height,
                                      ),
                              onLongPressEnd: widget.readOnly
                                  ? null
                                  : (_) => _endItemMove(),
                              onLongPressCancel:
                                  widget.readOnly ? null : _endItemMove,
                              child: SizedBox(
                                width: 52,
                                height: 52,
                                child: Center(
                                  child: _BoardToken(
                                    item: item,
                                    selected: item.id == _selectedItemId,
                                    moving: item.id == _movingItemId,
                                    label: _boardTokenLabelFor(item),
                                    sportId: _currentSportIdOrDefault,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  LinearGradient _boardSurfaceGradient(_BoardSurface surface) {
    return switch (surface) {
      _BoardSurface.tennis => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2F8F57), Color(0xFF17653D)],
        ),
      _BoardSurface.baseball => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2E7D32), Color(0xFF0F5132)],
        ),
      _BoardSurface.basketball => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFB87935), Color(0xFF6D4C2D)],
        ),
      _BoardSurface.football => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
        ),
    };
  }

  String? _boardTokenLabelFor(_BoardItem item) {
    if (item.type != _BoardItemType.player &&
        item.type != _BoardItemType.ball) {
      return null;
    }
    final typeIndex = _currentPage.items
        .where((entry) => entry.type == item.type)
        .toList(growable: false)
        .indexWhere((entry) => entry.id == item.id);
    return typeIndex < 0 ? null : '${typeIndex + 1}';
  }

  List<Widget> _buildTopBarActions(bool isKo, {required bool isLandscape}) {
    return [
      if (!widget.readOnly)
        AppBarActionButton.label(
          onPressed: () => _saveBoard(isKo),
          tooltip: _l10n.save,
          icon: const Icon(Icons.save_outlined),
          label: _l10n.save,
          maxLabelWidth: 72,
        ),
      AppBarActionButton.icon(
        key: const ValueKey('training-sketch-pdf-button'),
        onPressed: _pdfExportInProgress ? null : _exportCurrentSketchPdf,
        icon: Icons.picture_as_pdf_outlined,
        tooltip: _l10n.trainingSketchPdfExportTooltip,
      ),
      AppBarActionButton.icon(
        onPressed: () => _playPlayerPath(isKo),
        icon: _playController.isAnimating
            ? Icons.stop_circle_outlined
            : Icons.play_circle_outline,
        selected: _playController.isAnimating,
        tooltip: _l10n.trainingSketchPlayTooltip,
      ),
      AppBarActionButton.icon(
        key: const ValueKey('training-sketch-orientation-button'),
        onPressed: () {
          unawaited(_setSketchOrientationLock(landscape: true));
        },
        icon: Icons.stay_current_landscape_outlined,
        tooltip: _l10n.trainingSketchLandscapeModeTooltip,
      ),
      _buildTopBarMenuButton(isKo, isLandscape: isLandscape),
    ];
  }

  Widget _buildTopBarMenuButton(bool isKo, {required bool isLandscape}) {
    final notesExpanded = isLandscape ? _showLandscapeMemo : _showPortraitMemo;
    final controlsExpanded =
        isLandscape ? _showLandscapeControls : _showPortraitInspector;
    final l10n = _l10n;
    return AppBarActionMenuButton<_TopBarMenuAction>(
      key: ValueKey(
        isLandscape
            ? 'training-landscape-topbar-menu'
            : 'training-portrait-topbar-menu',
      ),
      tooltip: MaterialLocalizations.of(context).showMenuTooltip,
      icon: Icons.more_horiz_rounded,
      onSelected: (action) {
        unawaited(
          _handleTopBarMenuAction(action, isKo, isLandscape: isLandscape),
        );
      },
      itemBuilder: (_) => [
        PopupMenuItem<_TopBarMenuAction>(
          key: const ValueKey('training-topbar-menu-tactical-overlay'),
          value: _TopBarMenuAction.toggleTacticalOverlay,
          child: _buildTopBarMenuEntry(
            icon: _showTacticalOverlay
                ? Icons.grid_on_rounded
                : Icons.grid_off_rounded,
            label: l10n.trainingSketchTacticalOverlay,
          ),
        ),
        PopupMenuItem<_TopBarMenuAction>(
          key: const ValueKey('training-topbar-menu-notes'),
          value: _TopBarMenuAction.toggleNotes,
          child: _buildTopBarMenuEntry(
            icon: notesExpanded
                ? Icons.description_rounded
                : Icons.description_outlined,
            label: l10n.notes,
          ),
        ),
        PopupMenuItem<_TopBarMenuAction>(
          value: _TopBarMenuAction.viewTemplates,
          child: _buildTopBarMenuEntry(
            icon: Icons.grid_view_rounded,
            label: l10n.trainingSketchTemplateGalleryAction,
          ),
        ),
        if (!widget.readOnly)
          PopupMenuItem<_TopBarMenuAction>(
            key: const ValueKey('training-topbar-menu-controls'),
            value: _TopBarMenuAction.toggleControls,
            child: _buildTopBarMenuEntry(
              icon: controlsExpanded ? Icons.tune_rounded : Icons.tune_outlined,
              label: l10n.trainingSketchControlsPanel,
            ),
          ),
        const PopupMenuDivider(),
        ...[0.75, 1.0, 1.25, 1.5].map<PopupMenuEntry<_TopBarMenuAction>>((
          speed,
        ) {
          final action = switch (speed) {
            0.75 => _TopBarMenuAction.speed075,
            1.0 => _TopBarMenuAction.speed100,
            1.25 => _TopBarMenuAction.speed125,
            _ => _TopBarMenuAction.speed150,
          };
          final selected = (_playSpeed - speed).abs() < 0.001;
          return PopupMenuItem<_TopBarMenuAction>(
            key: ValueKey(
              'training-topbar-menu-speed-${speed.toStringAsFixed(2)}',
            ),
            value: action,
            child: _buildTopBarMenuEntry(
              icon: selected ? Icons.check : Icons.speed_outlined,
              label:
                  '${speed.toStringAsFixed(speed == 1.0 || speed == 1.5 ? 1 : 2)}x',
            ),
          );
        }),
        if (!widget.readOnly &&
            (_isManagedMode || widget.presets.isNotEmpty)) ...[
          const PopupMenuDivider(),
          if (_isManagedMode)
            PopupMenuItem<_TopBarMenuAction>(
              value: _TopBarMenuAction.addSketch,
              child: _buildTopBarMenuEntry(
                icon: Icons.add_box_outlined,
                label: l10n.trainingSketchAddSketchTooltip,
              ),
            ),
          if (_isManagedMode)
            PopupMenuItem<_TopBarMenuAction>(
              value: _TopBarMenuAction.copySketch,
              child: _buildTopBarMenuEntry(
                icon: Icons.copy_outlined,
                label: l10n.trainingSketchCopySketchTooltip,
              ),
            ),
          if (_isManagedMode && _currentBoardId != null)
            PopupMenuItem<_TopBarMenuAction>(
              value: _TopBarMenuAction.deleteSketch,
              child: _buildTopBarMenuEntry(
                icon: Icons.delete_outline,
                label: l10n.trainingSketchDeleteSketchTooltip,
              ),
            ),
          if (widget.presets.isNotEmpty)
            PopupMenuItem<_TopBarMenuAction>(
              value: _TopBarMenuAction.importSketch,
              child: _buildTopBarMenuEntry(
                icon: Icons.copy_all_outlined,
                label: l10n.trainingSketchImportSketchTooltip,
              ),
            ),
          PopupMenuItem<_TopBarMenuAction>(
            value: _TopBarMenuAction.renameSketch,
            child: _buildTopBarMenuEntry(
              icon: Icons.edit_outlined,
              label: l10n.trainingSketchRenameSketchTooltip,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTopBarMenuEntry({
    required IconData icon,
    required String label,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(label)),
      ],
    );
  }

  Future<void> _handleTopBarMenuAction(
    _TopBarMenuAction action,
    bool isKo, {
    required bool isLandscape,
  }) async {
    switch (action) {
      case _TopBarMenuAction.toggleTacticalOverlay:
        setState(() => _showTacticalOverlay = !_showTacticalOverlay);
        break;
      case _TopBarMenuAction.toggleNotes:
        setState(() {
          if (isLandscape) {
            _showLandscapeMemo = !_showLandscapeMemo;
          } else {
            _showPortraitMemo = !_showPortraitMemo;
          }
        });
        break;
      case _TopBarMenuAction.viewTemplates:
        await _openTemplateGallery();
        break;
      case _TopBarMenuAction.toggleControls:
        if (widget.readOnly) return;
        setState(() {
          if (isLandscape) {
            _showLandscapeControls = !_showLandscapeControls;
          } else {
            _showPortraitInspector = !_showPortraitInspector;
          }
        });
        break;
      case _TopBarMenuAction.speed075:
        setState(() => _playSpeed = 0.75);
        break;
      case _TopBarMenuAction.speed100:
        setState(() => _playSpeed = 1.0);
        break;
      case _TopBarMenuAction.speed125:
        setState(() => _playSpeed = 1.25);
        break;
      case _TopBarMenuAction.speed150:
        setState(() => _playSpeed = 1.5);
        break;
      case _TopBarMenuAction.addSketch:
        if (_isManagedMode) {
          await _promptForManagedBoardCreation();
        }
        break;
      case _TopBarMenuAction.copySketch:
        if (_isManagedMode) {
          await _copyCurrentManagedBoard(isKo);
        }
        break;
      case _TopBarMenuAction.deleteSketch:
        if (_isManagedMode && _currentBoardId != null) {
          await _deleteCurrentManagedBoard(isKo);
        }
        break;
      case _TopBarMenuAction.importSketch:
        if (widget.presets.isNotEmpty) {
          await _showPresetPicker(isKo);
        }
        break;
      case _TopBarMenuAction.renameSketch:
        if (!widget.readOnly) {
          await _renameCurrentPage(isKo);
        }
        break;
    }
  }

  Widget _buildAppBarTitle(bool isKo) {
    final canSwitchBoard = _isManagedMode && _currentBoardId != null;
    return InkWell(
      onTap: canSwitchBoard ? () => _showManagedBoardPicker(isKo) : null,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _resolvedCurrentBoardTitle(isKo),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (canSwitchBoard)
              Icon(
                Icons.unfold_more,
                size: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodTextInput(bool isKo, {bool compact = false}) {
    final l10n = _l10n;
    return TextField(
      controller: _methodController,
      minLines: compact ? 1 : 2,
      maxLines: compact ? 5 : 3,
      readOnly: widget.readOnly,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      decoration: InputDecoration(
        labelText: l10n.trainingSketchMemoLabel,
        hintText: l10n.trainingSketchMemoHint,
        border: const OutlineInputBorder(),
        suffixIcon: widget.readOnly
            ? null
            : IconButton(
                onPressed: () => _toggleMemoListening(isKo),
                icon: Icon(_isListeningMemo ? Icons.mic : Icons.mic_none),
                tooltip: l10n.trainingSketchVoiceInputTooltip,
              ),
      ),
      onChanged: widget.readOnly
          ? null
          : (value) {
              _currentPage.methodText = value;
              _scheduleAutoSave();
            },
    );
  }

  Widget _buildToolButtons(bool isKo) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _buildToolButtonsList(isKo),
    );
  }

  List<Widget> _buildToolButtonsList(bool isKo) {
    final selected = _selectedItem;
    if (selected != null && !_penMode && !_pathMode) {
      return <Widget>[
        _addElementMenuButton(),
        ..._buildUtilityToolButtons(isKo),
      ];
    }
    return <Widget>[
      for (final tool in _boardToolSpecsForCurrentSport())
        _toolButton(
          label: tool.label,
          icon: tool.icon,
          onTap: () => _addItem(tool.type),
        ),
      ..._buildUtilityToolButtons(isKo),
    ];
  }

  Widget _addElementMenuButton() {
    return MenuAnchor(
      key: const ValueKey('training-add-element-menu'),
      menuChildren: <Widget>[
        for (final tool in _boardToolSpecsForCurrentSport())
          MenuItemButton(
            leadingIcon: Icon(tool.icon),
            onPressed: () => _addItem(tool.type),
            child: Text(tool.label),
          ),
      ],
      builder: (context, controller, _) {
        return OutlinedButton.icon(
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          icon: const Icon(Icons.add_circle_outline),
          label: Text(_l10n.trainingSketchAddElementMenuButton),
          style: _toolButtonStyle(),
        );
      },
    );
  }

  List<Widget> _buildUtilityToolButtons(bool isKo) {
    final l10n = _l10n;
    return <Widget>[
      OutlinedButton.icon(
        onPressed: () => setState(() {
          _penMode = !_penMode;
          if (_penMode) {
            _pathMode = false;
          }
          _activeRoutePoints = null;
          _activeRouteSegmentDurationsMs = null;
          _activeRouteLastPointAt = null;
          _routeReplaceMode = false;
          _pendingTargetAction = null;
        }),
        icon: Icon(_penMode ? Icons.draw : Icons.edit_note_outlined),
        label: Text(l10n.trainingSketchPenButton),
        style: _toolButtonStyle(
          foregroundColor: _penMode ? const Color(0xFFFFEB3B) : null,
        ),
      ),
      OutlinedButton.icon(
        onPressed: _currentPage.strokes.isEmpty
            ? null
            : () {
                setState(() {
                  _currentPage.strokes.clear();
                  _activeStroke = null;
                });
                _scheduleAutoSave();
              },
        icon: const Icon(Icons.layers_clear_outlined),
        label: Text(l10n.trainingSketchClearInkButton),
        style: _toolButtonStyle(),
      ),
      OutlinedButton.icon(
        onPressed: _currentPage.routes.isEmpty ? null : _clearAllRoutes,
        icon: const Icon(Icons.route_outlined),
        label: Text(l10n.trainingSketchClearAllRoutesButton),
        style: _toolButtonStyle(),
      ),
      OutlinedButton.icon(
        onPressed: () async {
          final shouldReset = await _confirmReset(isKo);
          if (!shouldReset || !mounted) return;
          _stopRoutePlayback(restoreStart: false);
          setState(() {
            _currentPage.items.clear();
            _currentPage.strokes.clear();
            _currentPage.routes.clear();
            _activeStroke = null;
            _activeRoutePoints = null;
            _activeRouteSegmentDurationsMs = null;
            _activeRouteLastPointAt = null;
            _selectedItemId = null;
            _selectedRouteId = null;
            _showSelectedColorPicker = false;
            _routeReplaceMode = false;
            _pendingTargetAction = null;
          });
          _scheduleAutoSave();
        },
        icon: const Icon(Icons.delete_sweep_outlined),
        label: Text(l10n.trainingSketchResetButton),
        style: _toolButtonStyle(),
      ),
    ];
  }

  ButtonStyle _toolButtonStyle({
    Color? foregroundColor,
    Color? backgroundColor,
    BorderSide? side,
  }) {
    return OutlinedButton.styleFrom(
      visualDensity: VisualDensity.compact,
      minimumSize: const Size(1, 40),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
      side: side,
    );
  }

  Widget _toolButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: _toolButtonStyle(),
    );
  }

  String _targetActionLabel(_SketchTargetAction action) {
    final l10n = _l10n;
    return switch (action) {
      _SketchTargetAction.move => l10n.trainingSketchQuickMoveButton,
      _SketchTargetAction.pass => l10n.trainingSketchQuickPassButton,
      _SketchTargetAction.passAndMove =>
        l10n.trainingSketchQuickPassAndMoveButton,
      _SketchTargetAction.dribble => l10n.trainingSketchQuickDribbleButton,
      _SketchTargetAction.receiveMove =>
        l10n.trainingSketchQuickReceiveMoveButton,
      _SketchTargetAction.returnMove =>
        l10n.trainingSketchQuickReturnMoveButton,
      _SketchTargetAction.overlap => l10n.trainingSketchQuickOverlapButton,
      _SketchTargetAction.shot => l10n.trainingSketchQuickShotButton,
      _SketchTargetAction.cross => l10n.trainingSketchQuickCrossButton,
      _SketchTargetAction.drive => l10n.trainingSketchQuickDriveButton,
      _SketchTargetAction.cut => l10n.trainingSketchQuickCutButton,
      _SketchTargetAction.screen => l10n.trainingSketchQuickScreenButton,
      _SketchTargetAction.coneTurn => l10n.trainingSketchQuickConeTurnButton,
      _SketchTargetAction.coneJump => l10n.trainingSketchQuickConeJumpButton,
      _SketchTargetAction.hurdleJump =>
        l10n.trainingSketchQuickHurdleJumpButton,
      _SketchTargetAction.runBase => l10n.trainingSketchQuickRunBaseButton,
      _SketchTargetAction.fielding => l10n.trainingSketchQuickFieldingButton,
      _SketchTargetAction.throwBall => l10n.trainingSketchQuickThrowButton,
      _SketchTargetAction.serve => l10n.trainingSketchQuickServeButton,
      _SketchTargetAction.rally => l10n.trainingSketchQuickRallyButton,
      _SketchTargetAction.recover => l10n.trainingSketchQuickRecoverButton,
    };
  }

  ButtonStyle _targetActionButtonStyle(_SketchTargetAction action) {
    final colors = Theme.of(context).colorScheme;
    final selected = _pendingTargetAction == action;
    return _toolButtonStyle(
      foregroundColor: selected ? colors.onSecondaryContainer : null,
      backgroundColor: selected ? colors.secondaryContainer : null,
      side: selected ? BorderSide(color: colors.secondary, width: 1.4) : null,
    );
  }

  Widget _targetActionButton({
    required _SketchTargetAction action,
    required IconData icon,
  }) {
    return OutlinedButton.icon(
      onPressed: () => _beginTargetAction(action),
      icon: Icon(icon),
      label: Text(_targetActionLabel(action)),
      style: _targetActionButtonStyle(action),
    );
  }

  Future<void> _openPlayerFlowBuilder(_BoardItem player) async {
    final selection = await showModalBottomSheet<_PlayerFlowSelection>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _buildPlayerFlowSheet(context, player),
    );
    if (!mounted || selection == null) return;
    if (selection.createPassReceiver) {
      _applyQuickBallToNewReceiverTemplate(player);
      return;
    }
    if (selection.targetItemId case final targetItemId?) {
      final target = _itemById(targetItemId);
      if (target != null) {
        _applyQuickBallToItemTemplate(target);
      }
      return;
    }
    if (selection.action case final action?) {
      _beginTargetAction(action);
    }
  }

  Widget _buildPlayerFlowStarter(_BoardItem player) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final hasBall = _playerHasBallForFlow(player);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: colors.primaryContainer.withValues(alpha: 0.52),
        border: Border.all(color: colors.primary.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_tree_outlined, color: colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _l10n.trainingSketchPlayerFlowTitle(
                    _itemIndexOfType(player),
                  ),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Chip(
                visualDensity: VisualDensity.compact,
                label: Text(
                  hasBall
                      ? _l10n.trainingSketchPlayerFlowWithBall
                      : _l10n.trainingSketchPlayerFlowWithoutBall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _l10n.trainingSketchPlayerFlowHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: ValueKey('training-player-next-action-${player.id}'),
              onPressed: () => unawaited(_openPlayerFlowBuilder(player)),
              icon: const Icon(Icons.add_circle_outline),
              label: Text(_l10n.trainingSketchNextActionButton),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerFlowSheet(BuildContext sheetContext, _BoardItem player) {
    final theme = Theme.of(sheetContext);
    final hasBall = _playerHasBallForFlow(player);
    final canUseBallActions = _canUsePlayerFlowBallActions(player);
    final sportId = _currentSportIdOrDefault;
    final targetPlayers = _itemsOfType(
      _BoardItemType.player,
      excludingId: player.id,
    );
    final ballActions = canUseBallActions
        ? _playerFlowBallActions(sportId)
        : const <_SketchTargetAction>[];
    final movementActions = _playerFlowMovementActions(sportId)
        .where((action) => _canUsePlayerFlowMovementAction(player, action))
        .toList(growable: false);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.78,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _l10n.trainingSketchPlayerFlowTitle(
                          _itemIndexOfType(player),
                        ),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(
                        hasBall
                            ? _l10n.trainingSketchPlayerFlowWithBall
                            : _l10n.trainingSketchPlayerFlowWithoutBall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _l10n.trainingSketchPlayerFlowHint,
                  style: theme.textTheme.bodySmall,
                ),
                if (canUseBallActions) ...[
                  const SizedBox(height: 16),
                  _buildPlayerFlowSectionTitle(
                    _l10n.trainingSketchPlayerFlowPassSection,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final target in targetPlayers)
                        _playerFlowTargetButton(
                          sheetContext: sheetContext,
                          player: player,
                          target: target,
                          sportId: sportId,
                        ),
                      _playerFlowNewReceiverButton(
                        sheetContext: sheetContext,
                        player: player,
                        sportId: sportId,
                      ),
                    ],
                  ),
                ],
                if (ballActions.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildPlayerFlowSectionTitle(
                    _l10n.trainingSketchPlayerFlowBallSection,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final action in ballActions)
                        _playerFlowActionButton(
                          sheetContext: sheetContext,
                          player: player,
                          action: action,
                          icon: _targetActionIcon(action),
                        ),
                    ],
                  ),
                ],
                if (movementActions.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildPlayerFlowSectionTitle(
                    _l10n.trainingSketchPlayerFlowMoveSection,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final action in movementActions)
                        _playerFlowActionButton(
                          sheetContext: sheetContext,
                          player: player,
                          action: action,
                          icon: _targetActionIcon(action),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerFlowSectionTitle(String label) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w900,
          ),
    );
  }

  Widget _playerFlowTargetButton({
    required BuildContext sheetContext,
    required _BoardItem player,
    required _BoardItem target,
    required String sportId,
  }) {
    final index = _itemIndexOfType(target);
    final label = switch (sportId) {
      SportCatalog.baseballId => _l10n.trainingSketchThrowToPlayerButton(index),
      SportCatalog.tennisId => _l10n.trainingSketchRallyToPlayerButton(index),
      _ => _l10n.trainingSketchPassToPlayerButton(index),
    };
    final icon = switch (sportId) {
      SportCatalog.baseballId => Icons.sports_baseball,
      SportCatalog.tennisId => Icons.sports_tennis,
      _ => Icons.near_me_outlined,
    };
    return FilledButton.icon(
      key: ValueKey('training-player-flow-target-${player.id}-${target.id}'),
      onPressed: () => Navigator.of(sheetContext).pop(
        _PlayerFlowSelection.target(target.id),
      ),
      icon: Icon(icon),
      label: Text(label),
    );
  }

  Widget _playerFlowNewReceiverButton({
    required BuildContext sheetContext,
    required _BoardItem player,
    required String sportId,
  }) {
    final label = switch (sportId) {
      SportCatalog.baseballId => _l10n.trainingSketchThrowToNewPlayerButton,
      SportCatalog.tennisId => _l10n.trainingSketchRallyToNewPlayerButton,
      _ => _l10n.trainingSketchPassToNewPlayerButton,
    };
    final icon = switch (sportId) {
      SportCatalog.baseballId => Icons.person_add_alt_1,
      SportCatalog.tennisId => Icons.person_add_alt_1,
      _ => Icons.person_add_alt_1,
    };
    return FilledButton.tonalIcon(
      key: ValueKey('training-player-flow-new-receiver-${player.id}'),
      onPressed: () => Navigator.of(sheetContext).pop(
        const _PlayerFlowSelection.createPassReceiver(),
      ),
      icon: Icon(icon),
      label: Text(label),
    );
  }

  Widget _playerFlowActionButton({
    required BuildContext sheetContext,
    required _BoardItem player,
    required _SketchTargetAction action,
    required IconData icon,
  }) {
    return OutlinedButton.icon(
      key: ValueKey('training-player-flow-action-${player.id}-${action.name}'),
      onPressed: () => Navigator.of(sheetContext).pop(
        _PlayerFlowSelection.action(action),
      ),
      icon: Icon(icon),
      label: Text(_targetActionLabel(action)),
    );
  }

  IconData _targetActionIcon(_SketchTargetAction action) {
    return switch (action) {
      _SketchTargetAction.move => Icons.directions_run,
      _SketchTargetAction.pass => Icons.near_me_outlined,
      _SketchTargetAction.passAndMove => Icons.sync_alt,
      _SketchTargetAction.dribble => Icons.sports_soccer_outlined,
      _SketchTargetAction.receiveMove => Icons.call_received,
      _SketchTargetAction.returnMove => Icons.keyboard_return,
      _SketchTargetAction.overlap => Icons.moving,
      _SketchTargetAction.shot => Icons.ads_click,
      _SketchTargetAction.cross => Icons.north_east,
      _SketchTargetAction.drive => Icons.sports_basketball_outlined,
      _SketchTargetAction.cut => Icons.call_split,
      _SketchTargetAction.screen => Icons.block,
      _SketchTargetAction.coneTurn => Icons.change_history,
      _SketchTargetAction.coneJump => Icons.arrow_upward,
      _SketchTargetAction.hurdleJump => Icons.arrow_upward,
      _SketchTargetAction.runBase => Icons.signpost_outlined,
      _SketchTargetAction.fielding => Icons.front_hand_outlined,
      _SketchTargetAction.throwBall => Icons.near_me_outlined,
      _SketchTargetAction.serve => Icons.sports_tennis,
      _SketchTargetAction.rally => Icons.sync_alt,
      _SketchTargetAction.recover => Icons.keyboard_return,
    };
  }

  List<_SketchTargetAction> _playerFlowBallActions(String sportId) {
    return switch (sportId) {
      SportCatalog.baseballId => const <_SketchTargetAction>[],
      SportCatalog.basketballId => <_SketchTargetAction>[
          _SketchTargetAction.drive,
          _SketchTargetAction.shot,
        ],
      SportCatalog.tennisId => <_SketchTargetAction>[
          _SketchTargetAction.serve,
        ],
      _ => <_SketchTargetAction>[
          _SketchTargetAction.dribble,
          _SketchTargetAction.shot,
          _SketchTargetAction.cross,
        ],
    };
  }

  List<_SketchTargetAction> _playerFlowMovementActions(String sportId) {
    return switch (sportId) {
      SportCatalog.baseballId => <_SketchTargetAction>[
          _SketchTargetAction.move,
          _SketchTargetAction.runBase,
          _SketchTargetAction.fielding,
          _SketchTargetAction.coneTurn,
        ],
      SportCatalog.basketballId => <_SketchTargetAction>[
          _SketchTargetAction.move,
          _SketchTargetAction.cut,
          _SketchTargetAction.screen,
          _SketchTargetAction.coneTurn,
        ],
      SportCatalog.tennisId => <_SketchTargetAction>[
          _SketchTargetAction.move,
          _SketchTargetAction.recover,
          _SketchTargetAction.coneTurn,
        ],
      _ => <_SketchTargetAction>[
          _SketchTargetAction.move,
          _SketchTargetAction.receiveMove,
          _SketchTargetAction.coneTurn,
          _SketchTargetAction.hurdleJump,
        ],
    };
  }

  Widget _buildPendingTargetActionBanner() {
    final action = _pendingTargetAction;
    if (action == null) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: colors.secondaryContainer,
        border: Border.all(color: colors.secondary.withValues(alpha: 0.42)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.touch_app_outlined,
            size: 20,
            color: colors.onSecondaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _l10n.trainingSketchActionTargetHint(
                _targetActionLabel(action),
              ),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _cancelTargetAction,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: colors.onSecondaryContainer,
            ),
            child: Text(_l10n.trainingSketchActionTargetCancelButton),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSelectedQuickActionButtons(
    _BoardItem selected, {
    required bool includeRouteTool,
  }) {
    final l10n = _l10n;
    final sportId = _currentSportIdOrDefault;
    final buttons = <Widget>[];
    if (selected.type != _BoardItemType.player) {
      return buttons;
    }
    buttons.addAll(_buildPlayerQuickActionButtons(selected, sportId));
    if (_canStartBallActionForPlayer(selected)) {
      buttons.addAll(_buildTargetPlayerActionButtons(selected, sportId));
    }
    if (includeRouteTool) {
      buttons.add(
        OutlinedButton.icon(
          onPressed: _activateRouteToolForSelectedItem,
          icon: const Icon(Icons.add_road_outlined),
          label: Text(l10n.trainingSketchCreateMoveRouteButton),
        ),
      );
    }
    return buttons;
  }

  List<_SketchTargetAction> _playerQuickActionsForSport(String sportId) {
    return switch (sportId) {
      SportCatalog.baseballId => <_SketchTargetAction>[
          _SketchTargetAction.move,
          _SketchTargetAction.coneTurn,
          _SketchTargetAction.coneJump,
          _SketchTargetAction.runBase,
          _SketchTargetAction.fielding,
          _SketchTargetAction.throwBall,
        ],
      SportCatalog.basketballId => <_SketchTargetAction>[
          _SketchTargetAction.move,
          _SketchTargetAction.coneTurn,
          _SketchTargetAction.coneJump,
          _SketchTargetAction.drive,
          _SketchTargetAction.pass,
          _SketchTargetAction.shot,
          _SketchTargetAction.cut,
          _SketchTargetAction.screen,
        ],
      SportCatalog.tennisId => <_SketchTargetAction>[
          _SketchTargetAction.move,
          _SketchTargetAction.coneTurn,
          _SketchTargetAction.coneJump,
          _SketchTargetAction.serve,
          _SketchTargetAction.rally,
          _SketchTargetAction.recover,
        ],
      _ => <_SketchTargetAction>[
          _SketchTargetAction.move,
          _SketchTargetAction.coneTurn,
          _SketchTargetAction.coneJump,
          _SketchTargetAction.hurdleJump,
          _SketchTargetAction.dribble,
          _SketchTargetAction.pass,
          _SketchTargetAction.passAndMove,
          _SketchTargetAction.shot,
          _SketchTargetAction.cross,
          _SketchTargetAction.receiveMove,
          _SketchTargetAction.returnMove,
          _SketchTargetAction.overlap,
        ],
    };
  }

  List<Widget> _buildPlayerQuickActionButtons(
    _BoardItem player,
    String sportId,
  ) {
    final actions = _playerQuickActionsForSport(sportId).where((action) {
      if (_requiresBallTargetAction(action) &&
          !_canStartBallActionForPlayer(player)) {
        return false;
      }
      if (_requiresPlayerTargetAction(action) &&
          !_canUsePlayerFlowMovementAction(player, action)) {
        return false;
      }
      return true;
    });
    return actions
        .map(
          (action) => _targetActionButton(
            action: action,
            icon: _targetActionIcon(action),
          ),
        )
        .toList(growable: false);
  }

  List<Widget> _buildTargetPlayerActionButtons(
    _BoardItem selected,
    String sportId,
  ) {
    final excludingId =
        selected.type == _BoardItemType.player ? selected.id : null;
    final players = _itemsOfType(
      _BoardItemType.player,
      excludingId: excludingId,
    );
    final l10n = _l10n;
    final buttons = players.map<Widget>((player) {
      final index = _itemIndexOfType(player);
      final label = switch (sportId) {
        SportCatalog.baseballId =>
          l10n.trainingSketchThrowToPlayerButton(index),
        SportCatalog.tennisId => l10n.trainingSketchRallyToPlayerButton(index),
        _ => l10n.trainingSketchPassToPlayerButton(index),
      };
      final icon = switch (sportId) {
        SportCatalog.baseballId => Icons.sports_baseball,
        SportCatalog.tennisId => Icons.sports_tennis,
        _ => Icons.near_me_outlined,
      };
      return OutlinedButton.icon(
        onPressed: () => _applyQuickBallToItemTemplate(player),
        icon: Icon(icon),
        label: Text(label),
      );
    }).toList(growable: true);
    buttons.addAll(_buildTargetSpotActionButtons(selected, sportId));
    return buttons;
  }

  bool _isPassTargetSpot(_BoardItem item) {
    return switch (item.type) {
      _BoardItemType.cone ||
      _BoardItemType.target ||
      _BoardItemType.base =>
        true,
      _ => false,
    };
  }

  List<Widget> _buildTargetSpotActionButtons(
    _BoardItem selected,
    String sportId,
  ) {
    final spots = _currentPage.items
        .where((item) => item.id != selected.id && _isPassTargetSpot(item))
        .toList(growable: false);
    if (spots.isEmpty) return const <Widget>[];
    final l10n = _l10n;
    return spots.map((spot) {
      final targetName = _boardToolLabel(spot.type);
      final index = _itemIndexOfType(spot);
      final label = switch (sportId) {
        SportCatalog.baseballId =>
          l10n.trainingSketchThrowToSpotButton(targetName, index),
        SportCatalog.tennisId =>
          l10n.trainingSketchRallyToSpotButton(targetName, index),
        _ => l10n.trainingSketchPassToSpotButton(targetName, index),
      };
      return OutlinedButton.icon(
        onPressed: () => _applyQuickBallToItemTemplate(spot),
        icon: Icon(_boardItemIcon(spot.type, sportId: sportId)),
        label: Text(label),
      );
    }).toList(growable: false);
  }

  Widget _buildSelectedTools(bool isKo) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: widget.readOnly
          ? Text(
              _l10n.parentReadOnlySketchMessage,
              style: Theme.of(context).textTheme.bodySmall,
            )
          : _buildSelectedToolsContent(isKo),
    );
  }

  Widget _buildReadOnlyInfoPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Text(
        _l10n.parentReadOnlySketchMessage,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  _BoardRoute? _stageRouteForSelectedItem(
    _BoardItem selected,
    _BoardRoute? selectedRoute,
  ) {
    if (selectedRoute != null) {
      return selectedRoute;
    }
    final kind = _routeKindForItem(selected);
    if (kind == null) return null;
    return _routeForItem(selected.id, kind);
  }

  Widget _buildRouteStageControls({
    required _BoardRoute? route,
    required List<int> visibleStages,
    required Color accentColor,
    required bool showStageChoices,
    required bool includeActiveRouteControls,
    required bool includeRouteEditControls,
  }) {
    final l10n = _l10n;
    final hasRoute = route != null;
    final selectedRouteStage =
        hasRoute ? _normalizedRouteStageIndex(route.stageIndex) : 1;
    final canMoveRouteAfterBall = hasRoute &&
        route.kind == _PathDrawMode.player &&
        _currentPage.routes.any(
          (entry) =>
              entry.kind == _PathDrawMode.ball && entry.points.length >= 2,
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showStageChoices) ...[
          Text(
            l10n.trainingSketchRouteStageTitle,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: visibleStages
                .map(
                  (stage) => ChoiceChip(
                    selected: hasRoute && selectedRouteStage == stage,
                    showCheckmark: false,
                    label: Text(_routeStageLabel(stage)),
                    avatar: CircleAvatar(
                      radius: 10,
                      backgroundColor: hasRoute && stage == selectedRouteStage
                          ? accentColor
                          : accentColor.withValues(alpha: 0.18),
                      child: Text(
                        '$stage',
                        style: TextStyle(
                          color: hasRoute && stage == selectedRouteStage
                              ? Colors.white
                              : accentColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    onSelected: hasRoute
                        ? (_) => _setRouteStageAndSelect(route, stage)
                        : null,
                  ),
                )
                .toList(growable: false),
          ),
          if (!hasRoute) ...[
            const SizedBox(height: 6),
            Text(
              l10n.trainingSketchSelectRouteForStageHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 10),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (includeActiveRouteControls) ...[
              OutlinedButton.icon(
                onPressed: _canFinishActiveRoute ? _finishActiveRoute : null,
                icon: const Icon(Icons.check_circle_outline),
                label: Text(l10n.trainingSketchFinishRouteButton),
              ),
              OutlinedButton.icon(
                onPressed: _canUndoLastRoutePoint ? _undoLastRoutePoint : null,
                icon: const Icon(Icons.undo),
                label: Text(l10n.trainingSketchUndoLastRoutePointButton),
              ),
            ],
            OutlinedButton.icon(
              onPressed: _splitRoutesIntoStages,
              icon: const Icon(Icons.view_timeline_outlined),
              label: Text(l10n.trainingSketchAutoStagesButton),
            ),
            OutlinedButton.icon(
              onPressed: hasRoute && selectedRouteStage > 1
                  ? () => _shiftRouteStage(route, -1)
                  : null,
              icon: const Icon(Icons.chevron_left),
              label: Text(l10n.trainingSketchPreviousStageButton),
            ),
            OutlinedButton.icon(
              onPressed: hasRoute && selectedRouteStage < _maxRouteStageIndex
                  ? () => _shiftRouteStage(route, 1)
                  : null,
              icon: const Icon(Icons.chevron_right),
              label: Text(l10n.trainingSketchNextStageButton),
            ),
            OutlinedButton.icon(
              onPressed: canMoveRouteAfterBall
                  ? () => _moveRouteAfterBall(route)
                  : null,
              icon: const Icon(Icons.sports_soccer_outlined),
              label: Text(l10n.trainingSketchRouteAfterBallButton),
            ),
            if (includeRouteEditControls) ...[
              OutlinedButton.icon(
                onPressed: hasRoute ? _prepareSelectedRouteExtension : null,
                icon: const Icon(Icons.add_road_outlined),
                label: Text(l10n.trainingSketchExtendRouteButton),
              ),
              OutlinedButton.icon(
                onPressed: hasRoute && route.points.length >= 2
                    ? _reverseSelectedRoute
                    : null,
                icon: const Icon(Icons.swap_vert),
                label: Text(l10n.trainingSketchReverseRouteButton),
              ),
              OutlinedButton.icon(
                onPressed: hasRoute ? _prepareSelectedRouteRedraw : null,
                icon: const Icon(Icons.edit_outlined),
                label: Text(l10n.trainingSketchRedrawRouteButton),
              ),
              OutlinedButton.icon(
                onPressed: hasRoute ? _deleteSelectedRoute : null,
                icon: const Icon(Icons.delete_outline),
                label: Text(l10n.trainingSketchDeleteRouteButton),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildSelectedColorButton(_BoardItem selected) {
    final iconColor = selected.color.computeLuminance() < 0.45
        ? Colors.white
        : Colors.black87;
    final label = _l10n.trainingSketchAssignColorLabel;
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        selected: _showSelectedColorPicker,
        child: Material(
          color: _showSelectedColorPicker
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.10)
              : Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            key: const ValueKey('training-selected-color-button'),
            customBorder: const CircleBorder(),
            onTap: () {
              setState(() {
                _showSelectedColorPicker = !_showSelectedColorPicker;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected.color,
                      border: Border.all(
                        color: _showSelectedColorPicker
                            ? Theme.of(context).colorScheme.primary
                            : Colors.black26,
                        width: _showSelectedColorPicker ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.palette_outlined, size: 16, color: iconColor),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedColorPicker(
    _BoardItem selected,
    List<Color> colorChoices,
  ) {
    return Wrap(
      key: const ValueKey('training-selected-color-picker'),
      spacing: 8,
      runSpacing: 8,
      children: colorChoices.map((c) {
        final selectedColor = c.toARGB32() == selected.color.toARGB32();
        return InkWell(
          key: ValueKey(
            'training-selected-color-option-${c.toARGB32().toRadixString(16)}',
          ),
          onTap: () {
            setState(() {
              selected.color = c;
              _syncLinkedRouteColors(selected.id);
              _showSelectedColorPicker = false;
            });
            _scheduleAutoSave();
          },
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c,
              border: Border.all(
                color: selectedColor ? Colors.white : Colors.black26,
                width: selectedColor ? 2.4 : 1.0,
              ),
            ),
            child: selectedColor
                ? Icon(
                    Icons.check,
                    size: 14,
                    color: c.computeLuminance() < 0.45
                        ? Colors.white
                        : Colors.black87,
                  )
                : null,
          ),
        );
      }).toList(growable: false),
    );
  }

  void _selectGlobalStageSummary(_StageSummary summary) {
    final route = summary.routes.first;
    setState(() {
      _selectedItemId = route.linkedItemId ?? route.actorItemId;
      _selectedRouteId = route.id;
      _registeredNextActionStageIndex = summary.stageIndex;
      _pathDrawMode = route.kind;
      _showSelectedColorPicker = false;
      _pathMode = false;
      _penMode = false;
      _pendingTargetAction = null;
      _routeReplaceMode = false;
      _activeStroke = null;
      _activeRoutePoints = null;
      _activeRouteSegmentDurationsMs = null;
      _activeRouteLastPointAt = null;
    });
  }

  String _stageItemLabel(_BoardItem? item) {
    if (item == null) return _l10n.trainingSketchStageActionUnknownItem;
    return '${_boardToolLabel(item.type)} ${_itemIndexOfType(item)}';
  }

  String _stageRouteActionDescription(_BoardRoute route) {
    final linkedItem = _linkedItemForRoute(route);
    final actorItem =
        route.actorItemId == null ? null : _itemById(route.actorItemId!);
    final targetItem =
        route.targetItemId == null ? null : _itemById(route.targetItemId!);
    if (route.kind == _PathDrawMode.player) {
      return _l10n.trainingSketchStageActionPlayerMove(
        _stageItemLabel(linkedItem ?? actorItem),
      );
    }
    if (actorItem != null &&
        targetItem != null &&
        actorItem.id != targetItem.id) {
      return _l10n.trainingSketchStageActionBallToTarget(
        _stageItemLabel(actorItem),
        _stageItemLabel(targetItem),
      );
    }
    if (actorItem != null) {
      return _l10n.trainingSketchStageActionBallMove(
        _stageItemLabel(actorItem),
      );
    }
    return _l10n.trainingSketchStageActionUnownedBallMove(
      _stageItemLabel(linkedItem),
    );
  }

  String _ballOwnershipDescription(_BoardItem ball) {
    final ballLabel = _stageItemLabel(ball);
    final owner = _currentBallOwner(ball);
    if (owner != null) {
      return _l10n.trainingSketchBallOwnedBy(
        ballLabel,
        _stageItemLabel(owner),
      );
    }
    final latestRoute = _latestBallRouteForBall(ball);
    final actorItem = latestRoute?.actorItemId == null
        ? null
        : _itemById(latestRoute!.actorItemId!);
    final targetItem = latestRoute?.targetItemId == null
        ? null
        : _itemById(latestRoute!.targetItemId!);
    if (actorItem != null &&
        targetItem != null &&
        actorItem.id != targetItem.id) {
      return _l10n.trainingSketchBallMovingToTarget(
        ballLabel,
        _stageItemLabel(actorItem),
        _stageItemLabel(targetItem),
      );
    }
    return _l10n.trainingSketchBallUnowned(ballLabel);
  }

  Widget _buildBallOwnershipSummary({
    required ThemeData theme,
    required ColorScheme colors,
  }) {
    final balls = _itemsOfType(_BoardItemType.ball);
    if (balls.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: colors.secondaryContainer.withValues(alpha: 0.42),
        border: Border.all(
          color: colors.secondary.withValues(alpha: 0.24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.sports_soccer_outlined,
                size: 16,
                color: colors.onSecondaryContainer,
              ),
              const SizedBox(width: 6),
              Text(
                _l10n.trainingSketchBallOwnershipTitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSecondaryContainer,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (final ball in balls)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                _ballOwnershipDescription(ball),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSecondaryContainer,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGlobalStageSummaryItem(
    _StageSummary summary, {
    required Color accentColor,
    required bool isActive,
    required ThemeData theme,
  }) {
    final descriptions = summary.routes
        .map(_stageRouteActionDescription)
        .toList(growable: false);
    final colors = theme.colorScheme;
    return InkWell(
      key: ValueKey('training-global-stage-${summary.stageIndex}'),
      onTap: () => _selectGlobalStageSummary(summary),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isActive
              ? colors.primaryContainer.withValues(alpha: 0.46)
              : Colors.transparent,
          border: Border.all(
            color: isActive ? colors.primary : Colors.transparent,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: accentColor,
                child: Text(
                  '${summary.stageIndex}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _l10n.trainingSketchGlobalStageChip(
                        summary.stageIndex,
                        summary.routes.length,
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    for (final description in descriptions)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.subdirectory_arrow_right,
                              size: 14,
                              color: accentColor,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                description,
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlobalStagePlanner() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final summaries = _globalStageSummaries();
    final registeredStage = _registeredStageForNextAction();
    final activeStage = _activeStageForNextAction();
    final sameStage = _sameStageForNextAction();
    final nextStage = _nextGlobalStageForNewAction();
    final accentColor = colors.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: colors.surface.withValues(alpha: 0.48),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.view_timeline_outlined, size: 18, color: accentColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _l10n.trainingSketchGlobalStagesTitle,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _l10n.trainingSketchGlobalStagesHint,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          if (summaries.isEmpty)
            Text(
              _l10n.trainingSketchGlobalStagesEmpty,
              style: theme.textTheme.bodySmall,
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final summary in summaries)
                  _buildGlobalStageSummaryItem(
                    summary,
                    accentColor: accentColor,
                    isActive: summary.stageIndex == activeStage,
                    theme: theme,
                  ),
              ],
            ),
          if (_itemsOfType(_BoardItemType.ball).isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildBallOwnershipSummary(theme: theme, colors: colors),
          ],
          const SizedBox(height: 8),
          Text(
            _l10n.trainingSketchRegisteredNextGlobalStageHint(
              activeStage,
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: registeredStage == null
                  ? theme.colorScheme.onSurfaceVariant
                  : theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                key: const ValueKey('training-register-same-stage'),
                onPressed: _registerSameStageForNextAction,
                icon: const Icon(Icons.add_link_outlined),
                label: Text(
                  _l10n.trainingSketchAddSameStageButton(sameStage),
                ),
              ),
              FilledButton.icon(
                key: const ValueKey('training-register-next-stage'),
                onPressed: _registerNextStageForNextAction,
                icon: const Icon(Icons.add_task_outlined),
                label: Text(
                  _l10n.trainingSketchAddNextStageButton(nextStage),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedToolsContent(bool isKo) {
    final selected = _selectedItem;
    final selectedRoute = _selectedRoute;
    final l10n = _l10n;
    final colorChoices = _colorChoicesForItemType(selected?.type);
    if (_penMode) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.trainingSketchPenModeHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.trainingSketchPenColorLabel,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _penColors.map((c) {
              final selectedColor = c.toARGB32() == _penColor.toARGB32();
              return InkWell(
                onTap: () => setState(() => _penColor = c),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c,
                    border: Border.all(
                      color: selectedColor ? Colors.white : Colors.black26,
                      width: selectedColor ? 2.4 : 1.0,
                    ),
                  ),
                  child: selectedColor
                      ? Icon(
                          Icons.check,
                          size: 14,
                          color: c.computeLuminance() < 0.45
                              ? Colors.white
                              : Colors.black87,
                        )
                      : null,
                ),
              );
            }).toList(growable: false),
          ),
        ],
      );
    }
    if (_pathMode) {
      final routes = _routesForKind(_pathDrawMode);
      final routeableItems = _routeableItems(_pathDrawMode);
      final routeableCount = routeableItems.length;
      final hasSelectedCurrentRoute =
          selectedRoute != null && selectedRoute.kind == _pathDrawMode;
      final pathStageRoute = hasSelectedCurrentRoute ? selectedRoute : null;
      final accentColor = _routeGroupAccentColor(_pathDrawMode);
      final visibleStages = _visibleRouteStages();
      final selectedPathItem =
          selected?.type == _boardItemTypeForRouteKind(_pathDrawMode)
              ? selected
              : null;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: accentColor.withValues(alpha: 0.12),
              border: Border.all(color: accentColor.withValues(alpha: 0.28)),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor.withValues(alpha: 0.18),
                  ),
                  child: Icon(
                    _routeGroupIcon(_pathDrawMode),
                    size: 18,
                    color: accentColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _routeGroupTitle(_pathDrawMode),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                Text(
                  '${routes.length}/$routeableCount',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: accentColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(_pathModeHint(), style: Theme.of(context).textTheme.bodySmall),
          if (routeableItems.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: routeableItems.map((item) {
                final route = _routeForItem(item.id, _pathDrawMode);
                final isSelected = selected?.id == item.id;
                final textColor = item.color.computeLuminance() < 0.45
                    ? Colors.white
                    : Colors.black87;
                return ChoiceChip(
                  key: ValueKey(
                    'training-route-target-${_pathDrawMode.name}-${item.id}',
                  ),
                  selected: isSelected,
                  showCheckmark: false,
                  avatar: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: item.color,
                    ),
                    child: Icon(
                      _routeGroupIcon(_pathDrawMode),
                      size: 14,
                      color: textColor,
                    ),
                  ),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_routeableItemLabel(item)),
                      const SizedBox(width: 4),
                      Icon(
                        route == null ? Icons.route_outlined : Icons.route,
                        size: 14,
                        color: route?.color ?? accentColor,
                      ),
                      if (route != null) ...[
                        const SizedBox(width: 4),
                        _RouteStageBadge(
                          label:
                              '${_normalizedRouteStageIndex(route.stageIndex)}',
                          color: route.color,
                        ),
                      ],
                    ],
                  ),
                  selectedColor: accentColor.withValues(alpha: 0.18),
                  side: BorderSide(
                    color: (route?.color ?? accentColor).withValues(
                      alpha: isSelected ? 0.82 : 0.34,
                    ),
                  ),
                  onSelected: (_) => _selectRouteableItem(item),
                );
              }).toList(growable: false),
            ),
          ],
          if (selectedPathItem != null) ...[
            const SizedBox(height: 10),
            Text(
              l10n.trainingSketchSelectedItemActionsTitle,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _buildSelectedQuickActionButtons(
                selectedPathItem,
                includeRouteTool: false,
              ),
            ),
          ],
          const SizedBox(height: 6),
          if (routes.isEmpty)
            Text(
              l10n.trainingSketchRoutesEmpty,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          const SizedBox(height: 10),
          _buildRouteStageControls(
            route: pathStageRoute,
            visibleStages: visibleStages,
            accentColor: accentColor,
            showStageChoices: routes.isNotEmpty,
            includeActiveRouteControls: true,
            includeRouteEditControls: true,
          ),
        ],
      );
    }
    if (selected == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.trainingSketchQuickStart,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          _buildGlobalStagePlanner(),
        ],
      );
    }
    final selectedStageRoute = _stageRouteForSelectedItem(
      selected,
      selectedRoute,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.trainingSketchSelectedItemTitle,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            _buildSelectedColorButton(selected),
            IconButton(
              onPressed: _removeSelected,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: l10n.delete,
            ),
          ],
        ),
        if (_showSelectedColorPicker) ...[
          const SizedBox(height: 6),
          _buildSelectedColorPicker(selected, colorChoices),
        ],
        if (selected.type == _BoardItemType.player) ...[
          const SizedBox(height: 10),
          Text(
            l10n.trainingSketchLinkPlayerHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (_pendingTargetAction != null) ...[
            const SizedBox(height: 10),
            _buildPendingTargetActionBanner(),
          ],
          const SizedBox(height: 10),
          Text(
            l10n.trainingSketchPlayerActionsTitle,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _buildSelectedQuickActionButtons(
              selected,
              includeRouteTool: true,
            ),
          ),
          const SizedBox(height: 10),
          _buildPlayerFlowStarter(selected),
          const SizedBox(height: 10),
          _buildGlobalStagePlanner(),
          if (selectedStageRoute != null) ...[
            const SizedBox(height: 10),
            _buildRouteStageControls(
              route: selectedStageRoute,
              visibleStages: _visibleRouteStages(),
              accentColor: _routeGroupAccentColor(selectedStageRoute.kind),
              showStageChoices: true,
              includeActiveRouteControls: false,
              includeRouteEditControls: true,
            ),
          ],
        ],
      ],
    );
  }
}

class _BoardPageState {
  String name;
  String methodText;
  final List<_BoardItem> items;
  final List<_BoardStroke> strokes;
  final List<_BoardRoute> routes;

  _BoardPageState({
    required this.name,
    required this.methodText,
    required this.items,
    required this.strokes,
    required this.routes,
  });
}

class _BoardItem {
  final String id;
  final _BoardItemType type;
  double x;
  double y;
  double size;
  double rotationDeg;
  Color color;

  _BoardItem({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.size,
    required this.rotationDeg,
    required this.color,
  });
}

class _BoardRoute {
  final String id;
  final _PathDrawMode kind;
  String? linkedItemId;
  String? actorItemId;
  String? targetItemId;
  final List<Offset> points;
  final List<int> segmentDurationsMs;
  int stageIndex;
  Color color;
  final double width;

  _BoardRoute({
    required this.id,
    required this.kind,
    required this.points,
    required this.segmentDurationsMs,
    this.stageIndex = 1,
    required this.color,
    required this.width,
    this.linkedItemId,
    this.actorItemId,
    this.targetItemId,
  });
}

class _StageSummary {
  final int stageIndex;
  final List<_BoardRoute> routes;

  const _StageSummary({
    required this.stageIndex,
    required this.routes,
  });
}

class _BoardStroke {
  final List<Offset> points;
  final Color color;
  final double width;

  const _BoardStroke({
    required this.points,
    required this.color,
    required this.width,
  });
}

class _PresetBoardSelection {
  final TrainingBoardPreset preset;
  final TrainingMethodPage page;

  const _PresetBoardSelection({required this.preset, required this.page});
}

class _PlayerBallPossession {
  final _BoardItem ball;
  final Offset start;

  const _PlayerBallPossession({
    required this.ball,
    required this.start,
  });
}

class _PlaybackTrack {
  final _BoardItem item;
  final _BoardRoute route;
  final Offset startPosition;
  final List<_PlaybackSegment> segments;

  const _PlaybackTrack({
    required this.item,
    required this.route,
    required this.startPosition,
    required this.segments,
  });

  double get durationSeconds =>
      segments.fold<double>(0, (sum, segment) => sum + segment.durationSeconds);
}

class _RouteTiming {
  final List<Offset> points;
  final List<int> segmentDurationsMs;

  const _RouteTiming({
    required this.points,
    required this.segmentDurationsMs,
  });
}

class _PlaybackSegment {
  final Offset start;
  final Offset end;
  final double durationSeconds;

  const _PlaybackSegment({
    required this.start,
    required this.end,
    required this.durationSeconds,
  });
}

enum _PendingBoardAction { save, discard, cancel }

enum _TopBarMenuAction {
  toggleTacticalOverlay,
  toggleNotes,
  viewTemplates,
  toggleControls,
  speed075,
  speed100,
  speed125,
  speed150,
  addSketch,
  copySketch,
  deleteSketch,
  importSketch,
  renameSketch,
}

enum _PathDrawMode { player, ball }

enum _SketchTargetAction {
  move,
  pass,
  passAndMove,
  dribble,
  receiveMove,
  returnMove,
  overlap,
  shot,
  cross,
  drive,
  cut,
  screen,
  coneTurn,
  coneJump,
  hurdleJump,
  runBase,
  fielding,
  throwBall,
  serve,
  rally,
  recover,
}

class _PlayerFlowSelection {
  final _SketchTargetAction? action;
  final String? targetItemId;
  final bool createPassReceiver;

  const _PlayerFlowSelection.action(this.action)
      : targetItemId = null,
        createPassReceiver = false;

  const _PlayerFlowSelection.target(this.targetItemId)
      : action = null,
        createPassReceiver = false;

  const _PlayerFlowSelection.createPassReceiver()
      : action = null,
        targetItemId = null,
        createPassReceiver = true;
}

enum _BoardItemType { cone, hurdle, player, ball, ladder, target, base, basket }

enum _BoardSurface { football, baseball, basketball, tennis }

class _BoardToolSpec {
  final _BoardItemType type;
  final IconData icon;
  final String label;

  const _BoardToolSpec({
    required this.type,
    required this.icon,
    required this.label,
  });
}

_BoardSurface _boardSurfaceForSport(String? sportId) {
  return switch (SportCatalog.normalizeSportId(sportId)) {
    SportCatalog.baseballId => _BoardSurface.baseball,
    SportCatalog.basketballId => _BoardSurface.basketball,
    SportCatalog.tennisId => _BoardSurface.tennis,
    _ => _BoardSurface.football,
  };
}

_BoardItemType? _boardItemTypeFromString(String raw) {
  for (final value in _BoardItemType.values) {
    if (value.name == raw) return value;
  }
  return null;
}

Color _defaultColorFor(_BoardItemType type) {
  return switch (type) {
    _BoardItemType.cone => const Color(0xFFFFB300),
    _BoardItemType.hurdle => const Color(0xFFFFF176),
    _BoardItemType.player => _playerItemColors.first,
    _BoardItemType.ball => _ballItemColors.first,
    _BoardItemType.ladder => const Color(0xFFE53935),
    _BoardItemType.target => const Color(0xFFEC407A),
    _BoardItemType.base => const Color(0xFFFFFFFF),
    _BoardItemType.basket => const Color(0xFFFFA726),
  };
}

IconData _boardItemIcon(_BoardItemType type, {String? sportId}) {
  return switch (type) {
    _BoardItemType.cone => Icons.change_history,
    _BoardItemType.hurdle => Icons.horizontal_rule,
    _BoardItemType.player => Icons.person,
    _BoardItemType.ball => switch (SportCatalog.normalizeSportId(sportId)) {
        SportCatalog.baseballId => Icons.sports_baseball,
        SportCatalog.basketballId => Icons.sports_basketball,
        SportCatalog.tennisId => Icons.sports_tennis,
        _ => Icons.sports_soccer,
      },
    _BoardItemType.ladder => Icons.view_week,
    _BoardItemType.target => Icons.gps_fixed,
    _BoardItemType.base => Icons.home_outlined,
    _BoardItemType.basket => Icons.sports_basketball,
  };
}

_PathDrawMode _pathDrawModeFromRouteKind(TrainingMethodRouteKind kind) {
  return switch (kind) {
    TrainingMethodRouteKind.player => _PathDrawMode.player,
    TrainingMethodRouteKind.ball => _PathDrawMode.ball,
  };
}

TrainingMethodRouteKind _routeKindFromPathDrawMode(_PathDrawMode mode) {
  return switch (mode) {
    _PathDrawMode.player => TrainingMethodRouteKind.player,
    _PathDrawMode.ball => TrainingMethodRouteKind.ball,
  };
}

Color _defaultRouteColor(_PathDrawMode kind) {
  return switch (kind) {
    _PathDrawMode.player => _playerItemColors.first,
    _PathDrawMode.ball => _ballItemColors.first,
  };
}

double _defaultRouteWidth(_PathDrawMode kind) {
  return switch (kind) {
    _PathDrawMode.player => 4.0,
    _PathDrawMode.ball => 3.0,
  };
}

// Use a compact drill-board reference area so playback reads like a coaching
// sketch instead of full-pitch broadcast tracking.
const double _trainingBoardReferenceLengthMeters = 60.0;
const double _trainingBoardReferenceWidthMeters = 40.0;
const double _playerPlaybackSpeedMetersPerSecond = 6.2;
const double _ballPlaybackSpeedMetersPerSecond = 9.2;
const double _playerPlaybackAccelerationFraction = 0.20;
const double _ballPlaybackAccelerationFraction = 0.05;
const double _minPlaybackSegmentDistanceMeters = 0.05;
const double _ballPossessionRadius = 0.23;
const int _maxRouteStageIndex = 9;
const Duration _minPlaybackDuration = Duration(milliseconds: 900);
const List<double> _laneFractions = <double>[0.18, 0.38, 0.62, 0.82];

const List<Color> _playerItemColors = <Color>[
  Color(0xFF42A5F5),
  Color(0xFF1E88E5),
  Color(0xFF26C6DA),
  Color(0xFF5C6BC0),
  Color(0xFF00897B),
  Color(0xFF7E57C2),
];

const List<Color> _ballItemColors = <Color>[
  Color(0xFFFFCA28),
  Color(0xFFFF7043),
  Color(0xFFFFB300),
  Color(0xFFEF5350),
  Color(0xFFFF8A65),
  Color(0xFFFFD54F),
];

const List<Color> _presetColors = <Color>[
  Color(0xFFFFB300),
  Color(0xFF42A5F5),
  Color(0xFF43A047),
  Color(0xFFFB8C00),
  Color(0xFFE53935),
];

const List<Color> _penColors = <Color>[
  Color(0xFF000000),
  Color(0xFFFFFFFF),
  Color(0xFFFFEB3B),
  Color(0xFF42A5F5),
  Color(0xFF43A047),
  Color(0xFFFB8C00),
  Color(0xFFE53935),
];

class _BoardToken extends StatelessWidget {
  final _BoardItem item;
  final bool selected;
  final bool moving;
  final String? label;
  final String sportId;

  const _BoardToken({
    required this.item,
    required this.selected,
    required this.moving,
    required this.label,
    required this.sportId,
  });

  @override
  Widget build(BuildContext context) {
    final icon = _boardItemIcon(item.type, sportId: sportId);
    final borderColor =
        selected ? Colors.white : Colors.white.withValues(alpha: 0.55);
    final shadows = moving
        ? <BoxShadow>[
            BoxShadow(
              color: item.color.withValues(alpha: 0.52),
              blurRadius: 14,
              spreadRadius: 1,
            ),
            const BoxShadow(
              color: Colors.black54,
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ]
        : selected
            ? const <BoxShadow>[
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ]
            : null;
    return AnimatedScale(
      scale: moving ? 1.12 : 1.0,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: Transform.rotate(
        angle: (item.rotationDeg * math.pi) / 180,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 110),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: moving ? 0.26 : 0.18),
            shape: BoxShape.circle,
            border: moving
                ? null
                : Border.all(
                    color: borderColor,
                    width: selected ? 2.2 : 1.2,
                  ),
            boxShadow: shadows,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(icon, size: 18, color: item.color),
              if (!moving && label != null)
                Positioned(
                  right: -5,
                  bottom: -5,
                  child: _TokenNumberBadge(label: label!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TokenNumberBadge extends StatelessWidget {
  final String label;

  const _TokenNumberBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 17,
      height: 17,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black.withValues(alpha: 0.42)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}

class _RouteStageBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _RouteStageBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 18),
      height: 18,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color.computeLuminance() < 0.35 ? color : Colors.black87,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}

class _PlayerPathPainter extends CustomPainter {
  final List<_BoardRoute> routes;
  final String? selectedRouteId;
  final List<Offset>? activeRoutePoints;
  final Color activeRouteColor;
  final _PathDrawMode activeRouteKind;

  const _PlayerPathPainter({
    required this.routes,
    required this.selectedRouteId,
    required this.activeRoutePoints,
    required this.activeRouteColor,
    required this.activeRouteKind,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _BoardRoute? selectedRoute;
    for (final route in routes) {
      if (route.points.length < 2) continue;
      if (route.id == selectedRouteId) {
        selectedRoute = route;
        continue;
      }
      _drawRoute(
        canvas,
        size,
        kind: route.kind,
        points: route.points,
        color: route.color,
        width: route.width,
        alpha: 0.38,
        selected: false,
      );
    }
    if (selectedRoute != null) {
      _drawSelectedRoute(canvas, size, selectedRoute);
    }
    final active = activeRoutePoints;
    if (active != null && active.length > 1) {
      _drawRoute(
        canvas,
        size,
        kind: activeRouteKind,
        points: active,
        color: activeRouteColor,
        width: _defaultRouteWidth(activeRouteKind),
        alpha: 0.78,
        selected: false,
      );
    }
  }

  void _drawSelectedRoute(Canvas canvas, Size size, _BoardRoute route) {
    _drawRoute(
      canvas,
      size,
      kind: route.kind,
      points: route.points,
      color: route.color,
      width: route.width,
      alpha: 0.96,
      selected: true,
    );
  }

  void _drawRoute(
    Canvas canvas,
    Size size, {
    required _PathDrawMode kind,
    required List<Offset> points,
    required Color color,
    required double width,
    required double alpha,
    required bool selected,
  }) {
    final scaled = points
        .map((point) => Offset(point.dx * size.width, point.dy * size.height))
        .toList(growable: false);
    final lineColor = color.withValues(alpha: alpha);
    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (kind == _PathDrawMode.ball) {
      _drawDashedPolyline(canvas, scaled, paint);
    } else {
      canvas.drawPath(_smoothPath(scaled), paint);
    }

    if (selected) {
      _drawMarker(
        canvas: canvas,
        center: scaled.first,
        color: color,
        radius: 6.8,
        filled: true,
      );
      _drawMarker(
        canvas: canvas,
        center: scaled.last,
        color: color,
        radius: 7.8,
        filled: false,
      );
    } else {
      _drawRouteStart(canvas, scaled.first, lineColor, width);
    }
    _drawArrowHead(canvas, scaled, lineColor, width);
  }

  Path _smoothPath(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    if (points.length == 2) {
      return path..lineTo(points.last.dx, points.last.dy);
    }
    for (var i = 1; i < points.length; i++) {
      if (i == points.length - 1) {
        path.lineTo(points[i].dx, points[i].dy);
        break;
      }
      final current = points[i];
      final next = points[i + 1];
      final mid = Offset(
        (current.dx + next.dx) / 2,
        (current.dy + next.dy) / 2,
      );
      path.quadraticBezierTo(current.dx, current.dy, mid.dx, mid.dy);
    }
    return path;
  }

  void _drawDashedPolyline(Canvas canvas, List<Offset> points, Paint paint) {
    const dash = 14.0;
    const gap = 9.0;
    for (var i = 1; i < points.length; i++) {
      final start = points[i - 1];
      final end = points[i];
      final vector = end - start;
      final distance = vector.distance;
      if (distance < 0.1) continue;
      final direction = vector / distance;
      var drawn = 0.0;
      while (drawn < distance) {
        final segmentStart = start + direction * drawn;
        final segmentEnd = start + direction * math.min(drawn + dash, distance);
        canvas.drawLine(segmentStart, segmentEnd, paint);
        drawn += dash + gap;
      }
    }
  }

  void _drawRouteStart(
    Canvas canvas,
    Offset center,
    Color color,
    double width,
  ) {
    final outerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.82)
      ..style = PaintingStyle.fill;
    final innerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, math.max(3.6, width * 1.15), outerPaint);
    canvas.drawCircle(center, math.max(2.0, width * 0.62), innerPaint);
  }

  void _drawArrowHead(
    Canvas canvas,
    List<Offset> points,
    Color color,
    double width,
  ) {
    if (points.length < 2) return;
    final tip = points.last;
    final tail = _arrowTailPoint(points, math.max(18.0, width * 4.0));
    if (tail == null) return;
    final angle = math.atan2(tip.dy - tail.dy, tip.dx - tail.dx);
    final length = math.max(12.0, width * 3.2);
    const spread = math.pi / 6;
    final left = Offset(
      tip.dx - math.cos(angle - spread) * length,
      tip.dy - math.sin(angle - spread) * length,
    );
    final right = Offset(
      tip.dx - math.cos(angle + spread) * length,
      tip.dy - math.sin(angle + spread) * length,
    );
    final arrowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(left.dx, left.dy)
        ..lineTo(right.dx, right.dy)
        ..close(),
      arrowPaint,
    );
  }

  Offset? _arrowTailPoint(List<Offset> points, double lookbackDistance) {
    final tip = points.last;
    var cursor = tip;
    var remaining = lookbackDistance;
    for (var i = points.length - 2; i >= 0; i--) {
      final start = points[i];
      final vector = cursor - start;
      final distance = vector.distance;
      if (distance <= 0.5) {
        cursor = start;
        continue;
      }
      final direction = vector / distance;
      if (distance >= remaining) {
        return cursor - direction * remaining;
      }
      remaining -= distance;
      cursor = start;
    }
    return (tip - cursor).distance > 0.5 ? cursor : null;
  }

  void _drawMarker({
    required Canvas canvas,
    required Offset center,
    required Color color,
    required double radius,
    required bool filled,
  }) {
    final ringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.98)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, ringPaint);
    final innerPaint = Paint()
      ..color = filled ? color : Colors.black.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 2.4, innerPaint);
    if (!filled) {
      final accentPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2;
      canvas.drawCircle(center, radius - 3.2, accentPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PlayerPathPainter oldDelegate) {
    return true;
  }
}

class _InkPainter extends CustomPainter {
  final List<_BoardStroke> strokes;
  final List<Offset>? activeStrokePoints;
  final Color activeStrokeColor;

  const _InkPainter({
    required this.strokes,
    required this.activeStrokePoints,
    required this.activeStrokeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      _drawStroke(canvas, size, stroke.points, stroke.color, stroke.width);
    }
    final active = activeStrokePoints;
    if (active != null && active.length > 1) {
      _drawStroke(canvas, size, active, activeStrokeColor, 3.0);
    }
  }

  void _drawStroke(
    Canvas canvas,
    Size size,
    List<Offset> points,
    Color color,
    double width,
  ) {
    if (points.length < 2) return;
    final paint = Paint()
      ..color = color.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(points.first.dx * size.width, points.first.dy * size.height);
    for (var i = 1; i < points.length; i++) {
      final p = points[i];
      path.lineTo(p.dx * size.width, p.dy * size.height);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _InkPainter oldDelegate) {
    return true;
  }
}

class _SportSurfacePainter extends CustomPainter {
  final _BoardSurface surface;
  final bool showTacticalOverlay;

  const _SportSurfacePainter({
    required this.surface,
    required this.showTacticalOverlay,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (surface) {
      case _BoardSurface.baseball:
        _drawBaseballSurface(canvas, size);
        return;
      case _BoardSurface.basketball:
        _drawBasketballSurface(canvas, size);
        return;
      case _BoardSurface.tennis:
        _drawTennisSurface(canvas, size);
        return;
      case _BoardSurface.football:
        break;
    }
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, math.min(size.width, size.height) * 0.004);
    final fieldRect = Rect.fromLTWH(8, 8, size.width - 16, size.height - 16);
    final stripePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.045)
      ..style = PaintingStyle.fill;
    final stripeWidth = fieldRect.width / 10;
    for (var i = 0; i < 10; i += 2) {
      canvas.drawRect(
        Rect.fromLTWH(
          fieldRect.left + stripeWidth * i,
          fieldRect.top,
          stripeWidth,
          fieldRect.height,
        ),
        stripePaint,
      );
    }
    if (showTacticalOverlay) {
      _drawTacticalOverlay(canvas, fieldRect);
    }

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(fieldRect, const Radius.circular(12)),
      line,
    );
    canvas.drawLine(
      Offset(centerX, fieldRect.top),
      Offset(centerX, fieldRect.bottom),
      line,
    );
    canvas.drawCircle(
      Offset(centerX, centerY),
      math.min(42, fieldRect.shortestSide * 0.13),
      line,
    );
    final boxDepth = math.min(fieldRect.width * 0.17, 92.0);
    final boxHeight = math.min(fieldRect.height * 0.42, 136.0);
    final boxTop = centerY - boxHeight / 2;
    canvas.drawRect(
      Rect.fromLTWH(fieldRect.left, boxTop, boxDepth, boxHeight),
      line,
    );
    canvas.drawRect(
      Rect.fromLTWH(fieldRect.right - boxDepth, boxTop, boxDepth, boxHeight),
      line,
    );
    final goalDepth = math.min(fieldRect.width * 0.022, 12.0);
    final goalHeight = math.min(fieldRect.height * 0.18, 58.0);
    canvas.drawRect(
      Rect.fromLTWH(
        fieldRect.left - goalDepth,
        centerY - goalHeight / 2,
        goalDepth,
        goalHeight,
      ),
      line,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        fieldRect.right,
        centerY - goalHeight / 2,
        goalDepth,
        goalHeight,
      ),
      line,
    );
    final spotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.72)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX, centerY), 2.6, spotPaint);
  }

  void _drawBaseballSurface(Canvas canvas, Size size) {
    final fieldRect = Rect.fromLTWH(8, 8, size.width - 16, size.height - 16);
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.4, fieldRect.shortestSide * 0.004);
    final dirtPaint = Paint()
      ..color = const Color(0xFFC47A39).withValues(alpha: 0.88)
      ..style = PaintingStyle.fill;
    final moundPaint = Paint()
      ..color = const Color(0xFFE0A75D).withValues(alpha: 0.92)
      ..style = PaintingStyle.fill;
    final basePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.94)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(fieldRect, const Radius.circular(12)),
      line,
    );
    final home = Offset(fieldRect.center.dx, fieldRect.bottom - 26);
    final first = Offset(fieldRect.right - 58, fieldRect.center.dy + 18);
    final second = Offset(fieldRect.center.dx, fieldRect.top + 64);
    final third = Offset(fieldRect.left + 58, fieldRect.center.dy + 18);
    final diamond = Path()
      ..moveTo(home.dx, home.dy)
      ..lineTo(first.dx, first.dy)
      ..lineTo(second.dx, second.dy)
      ..lineTo(third.dx, third.dy)
      ..close();
    canvas.drawPath(diamond, dirtPaint);
    canvas.drawPath(diamond, line);
    canvas.drawLine(home, first, line);
    canvas.drawLine(home, third, line);
    canvas.drawLine(
        first, Offset(fieldRect.right - 12, fieldRect.top + 20), line);
    canvas.drawLine(
        third, Offset(fieldRect.left + 12, fieldRect.top + 20), line);
    canvas.drawCircle(
      Offset(fieldRect.center.dx, fieldRect.center.dy + 8),
      math.min(24, fieldRect.shortestSide * 0.075),
      moundPaint,
    );
    canvas.drawCircle(
      Offset(fieldRect.center.dx, fieldRect.center.dy + 8),
      2.8,
      basePaint,
    );
    for (final base in <Offset>[home, first, second, third]) {
      canvas.save();
      canvas.translate(base.dx, base.dy);
      canvas.rotate(math.pi / 4);
      canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: 9, height: 9), basePaint);
      canvas.restore();
    }
    final grassArcPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawArc(
      Rect.fromCircle(center: home, radius: fieldRect.width * 0.48),
      -math.pi * 0.80,
      math.pi * 0.60,
      false,
      grassArcPaint,
    );
  }

  void _drawBasketballSurface(Canvas canvas, Size size) {
    final courtRect = Rect.fromLTWH(8, 8, size.width - 16, size.height - 16);
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.76)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, courtRect.shortestSide * 0.004);
    final keyPaint = Paint()
      ..color = const Color(0xFF1E88E5).withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;
    final centerPaint = Paint()
      ..color = const Color(0xFFFFCA28).withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(courtRect, const Radius.circular(12)),
      line,
    );
    final center = courtRect.center;
    canvas.drawCircle(
        center, math.min(46, courtRect.shortestSide * 0.15), centerPaint);
    canvas.drawCircle(
        center, math.min(46, courtRect.shortestSide * 0.15), line);
    canvas.drawLine(
      Offset(courtRect.center.dx, courtRect.top),
      Offset(courtRect.center.dx, courtRect.bottom),
      line,
    );
    final keyWidth = math.min(courtRect.height * 0.42, 122.0);
    final keyDepth = math.min(courtRect.width * 0.18, 92.0);
    final keyTop = courtRect.center.dy - keyWidth / 2;
    final leftKey = Rect.fromLTWH(courtRect.left, keyTop, keyDepth, keyWidth);
    final rightKey = Rect.fromLTWH(
      courtRect.right - keyDepth,
      keyTop,
      keyDepth,
      keyWidth,
    );
    canvas.drawRect(leftKey, keyPaint);
    canvas.drawRect(rightKey, keyPaint);
    canvas.drawRect(leftKey, line);
    canvas.drawRect(rightKey, line);
    canvas.drawCircle(
      Offset(leftKey.right, courtRect.center.dy),
      keyWidth * 0.28,
      line,
    );
    canvas.drawCircle(
      Offset(rightKey.left, courtRect.center.dy),
      keyWidth * 0.28,
      line,
    );
    final hoopPaint = Paint()
      ..color = const Color(0xFFFFB300).withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawCircle(
        Offset(courtRect.left + 18, courtRect.center.dy), 5, hoopPaint);
    canvas.drawCircle(
        Offset(courtRect.right - 18, courtRect.center.dy), 5, hoopPaint);
    _drawDashedLine(
      canvas,
      Offset(courtRect.left + courtRect.width * 0.28, courtRect.top + 10),
      Offset(courtRect.left + courtRect.width * 0.28, courtRect.bottom - 10),
      line,
      dash: 10,
      gap: 7,
    );
    _drawDashedLine(
      canvas,
      Offset(courtRect.right - courtRect.width * 0.28, courtRect.top + 10),
      Offset(courtRect.right - courtRect.width * 0.28, courtRect.bottom - 10),
      line,
      dash: 10,
      gap: 7,
    );
  }

  void _drawTennisSurface(Canvas canvas, Size size) {
    final courtRect = Rect.fromLTWH(8, 8, size.width - 16, size.height - 16);
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, courtRect.shortestSide * 0.004);
    final servicePaint = Paint()
      ..color = const Color(0xFF1565C0).withValues(alpha: 0.16)
      ..style = PaintingStyle.fill;
    final doublesLanePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.055)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(courtRect, const Radius.circular(12)),
      line,
    );
    final topLane = courtRect.top + courtRect.height * 0.13;
    final bottomLane = courtRect.bottom - courtRect.height * 0.13;
    canvas.drawRect(
      Rect.fromLTRB(courtRect.left, courtRect.top, courtRect.right, topLane),
      doublesLanePaint,
    );
    canvas.drawRect(
      Rect.fromLTRB(
          courtRect.left, bottomLane, courtRect.right, courtRect.bottom),
      doublesLanePaint,
    );
    canvas.drawLine(Offset(courtRect.left, topLane),
        Offset(courtRect.right, topLane), line);
    canvas.drawLine(
      Offset(courtRect.left, bottomLane),
      Offset(courtRect.right, bottomLane),
      line,
    );
    final netX = courtRect.center.dx;
    final leftService = courtRect.left + courtRect.width * 0.28;
    final rightService = courtRect.right - courtRect.width * 0.28;
    final singlesCenterY = courtRect.center.dy;
    canvas.drawRect(
      Rect.fromLTRB(leftService, topLane, rightService, bottomLane),
      servicePaint,
    );
    canvas.drawLine(
        Offset(netX, courtRect.top), Offset(netX, courtRect.bottom), line);
    canvas.drawLine(
      Offset(leftService, topLane),
      Offset(leftService, bottomLane),
      line,
    );
    canvas.drawLine(
      Offset(rightService, topLane),
      Offset(rightService, bottomLane),
      line,
    );
    canvas.drawLine(
      Offset(leftService, singlesCenterY),
      Offset(rightService, singlesCenterY),
      line,
    );
    final netPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
    canvas.drawLine(
      Offset(netX, courtRect.top + 5),
      Offset(netX, courtRect.bottom - 5),
      netPaint,
    );
  }

  void _drawTacticalOverlay(Canvas canvas, Rect fieldRect) {
    final halfSpacePaint = Paint()
      ..color = const Color(0xFFFFF59D).withValues(alpha: 0.075)
      ..style = PaintingStyle.fill;
    final centralPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..style = PaintingStyle.fill;
    final laneYs = _laneFractions
        .map((fraction) => fieldRect.top + fieldRect.height * fraction)
        .toList(growable: false);
    canvas.drawRect(
      Rect.fromLTRB(fieldRect.left, laneYs[0], fieldRect.right, laneYs[1]),
      halfSpacePaint,
    );
    canvas.drawRect(
      Rect.fromLTRB(fieldRect.left, laneYs[2], fieldRect.right, laneYs[3]),
      halfSpacePaint,
    );
    canvas.drawRect(
      Rect.fromLTRB(fieldRect.left, laneYs[1], fieldRect.right, laneYs[2]),
      centralPaint,
    );

    final thirdPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final fraction in const [1 / 3, 2 / 3]) {
      final x = fieldRect.left + fieldRect.width * fraction;
      _drawDashedLine(
        canvas,
        Offset(x, fieldRect.top),
        Offset(x, fieldRect.bottom),
        thirdPaint,
        dash: 12,
        gap: 8,
      );
    }

    final lanePaint = Paint()
      ..color = const Color(0xFFE0F7FA).withValues(alpha: 0.32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    for (final y in laneYs) {
      _drawDashedLine(
        canvas,
        Offset(fieldRect.left, y),
        Offset(fieldRect.right, y),
        lanePaint,
        dash: 9,
        gap: 7,
      );
    }
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint, {
    required double dash,
    required double gap,
  }) {
    final vector = end - start;
    final distance = vector.distance;
    if (distance <= 0) return;
    final direction = vector / distance;
    var drawn = 0.0;
    while (drawn < distance) {
      final segmentStart = start + direction * drawn;
      final segmentEnd = start + direction * math.min(drawn + dash, distance);
      canvas.drawLine(segmentStart, segmentEnd, paint);
      drawn += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _SportSurfacePainter oldDelegate) {
    return oldDelegate.surface != surface ||
        oldDelegate.showTacticalOverlay != showTacticalOverlay;
  }
}

class TrainingBoardPreset {
  final String title;
  final String subtitle;
  final String layoutJson;

  const TrainingBoardPreset({
    required this.title,
    required this.subtitle,
    required this.layoutJson,
  });
}
