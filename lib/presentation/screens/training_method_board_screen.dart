import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
import '../utils/app_sound_effects.dart';
import '../utils/pdf_export.dart';
import '../utils/training_sketch_orientation_lock.dart';
import '../utils/training_sketch_video_export.dart';
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
  static const Duration _actionUndoVisibleDuration = Duration(seconds: 3);

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
  Offset? _pendingTargetGuidePoint;
  Offset? _pendingMoveThenPassPoint;
  Color _penColor = const Color(0xFF000000);
  List<Offset>? _activeStroke;
  List<Offset>? _activeRoutePoints;
  List<int>? _activeRouteSegmentDurationsMs;
  DateTime? _activeRouteLastPointAt;
  _RouteHandleDrag? _activeRouteHandleDrag;
  late final AnimationController _playController;
  final GlobalKey _boardPdfBoundaryKey = GlobalKey();
  final ScrollController _landscapeControlsScrollController =
      ScrollController();
  final ScrollController _portraitInspectorScrollController =
      ScrollController();
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
  int? _playbackActiveStageIndex;
  bool _isActionPreviewPlayback = false;
  Set<String> _hiddenPlaybackItemIds = <String>{};
  Timer? _autoSaveTimer;
  Timer? _actionUndoTimer;
  _SketchUndoSnapshot? _pendingActionUndoSnapshot;
  bool _autoSaveInProgress = false;
  bool _pdfExportInProgress = false;
  bool _videoExportInProgress = false;
  Timer? _reorderAutoScrollTimer;
  ScrollController? _reorderAutoScrollController;
  double _reorderAutoScrollVelocity = 0;
  bool _reorderPointerRouteAttached = false;
  String? _reorderingActionRouteId;

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

  Future<void> _exportCurrentSketchVideo() async {
    if (_videoExportInProgress || _playController.isAnimating) return;
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(_l10n.trainingSketchVideoExportUnavailableSnack)),
      );
      return;
    }
    final tracks = _resolvePlaybackTracks();
    if (tracks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_l10n.trainingSketchVideoExportFailedSnack)),
      );
      return;
    }

    final itemPositions = <String, Offset>{
      for (final item in _currentPage.items) item.id: _itemPosition(item),
    };
    final selectedItemId = _selectedItemId;
    final selectedRouteId = _selectedRouteId;
    final playbackDuration = _playbackDurationForTracks(tracks);
    const frameRate = 12;
    final frameCount = math
        .max(
          16,
          math.min(
            120,
            (playbackDuration.inMilliseconds / 1000 * frameRate).ceil(),
          ),
        )
        .toInt();

    setState(() {
      _videoExportInProgress = true;
      _selectedItemId = null;
      _selectedRouteId = null;
      _isActionPreviewPlayback = false;
      _playbackTracks = tracks;
      _applyPlaybackFrame(tracks, 0);
    });

    try {
      await WidgetsBinding.instance.endOfFrame;
      final firstFrame = await _captureBoardVideoFrame();
      await encodeAndShareTrainingSketchVideo(
        width: firstFrame.width,
        height: firstFrame.height,
        framesPerSecond: frameRate,
        frameCount: frameCount,
        filename: timestampedVideoFilename('training-sketch'),
        frameProvider: (frameIndex) async {
          if (frameIndex == 0) return firstFrame.rgbaBytes;
          final progress = frameIndex / (frameCount - 1);
          final elapsedSeconds = playbackDuration.inMicroseconds *
              progress /
              Duration.microsecondsPerSecond;
          if (!mounted) {
            throw StateError('Training sketch screen is no longer available.');
          }
          setState(() => _applyPlaybackFrame(tracks, elapsedSeconds));
          await WidgetsBinding.instance.endOfFrame;
          return (await _captureBoardVideoFrame(
            targetWidth: firstFrame.width,
            targetHeight: firstFrame.height,
          ))
              .rgbaBytes;
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_l10n.trainingSketchVideoExportedSnack)),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_l10n.trainingSketchVideoExportFailedSnack)),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          for (final item in _currentPage.items) {
            final start = itemPositions[item.id];
            if (start == null) continue;
            item
              ..x = start.dx
              ..y = start.dy;
          }
          _playbackTracks = const <_PlaybackTrack>[];
          _hiddenPlaybackItemIds = <String>{};
          _playbackActiveStageIndex = null;
          _selectedItemId = selectedItemId;
          _selectedRouteId = selectedRouteId;
          _videoExportInProgress = false;
        });
      } else {
        _videoExportInProgress = false;
      }
    }
  }

  Future<_CapturedSketchVideoFrame> _captureBoardVideoFrame({
    int? targetWidth,
    int? targetHeight,
  }) async {
    final renderObject =
        _boardPdfBoundaryKey.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) {
      throw StateError('Training sketch board is not ready to capture.');
    }
    final logicalSize = renderObject.size;
    if (logicalSize.isEmpty) {
      throw StateError('Training sketch board has no visible size.');
    }
    final targetLogicalWidth = logicalSize.width.clamp(320.0, 720.0);
    final pixelRatio = targetLogicalWidth / logicalSize.width;
    final image = await renderObject.toImage(pixelRatio: pixelRatio);
    try {
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) {
        throw StateError('Training sketch board frame is unavailable.');
      }
      final frame = _CapturedSketchVideoFrame(
        width: image.width,
        height: image.height,
        rgbaBytes: byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        ),
      );
      return frame.cropTo(
        targetWidth ?? _evenVideoDimension(frame.width),
        targetHeight ?? _evenVideoDimension(frame.height),
      );
    } finally {
      image.dispose();
    }
  }

  int _evenVideoDimension(int value) => value.isEven ? value : value - 1;

  @override
  void initState() {
    super.initState();
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
    _syncNextIdFromLayout(layout);
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

  void _syncNextIdFromLayout(TrainingMethodLayout layout) {
    var maxNumericId = 0;
    final trailingNumberPattern = RegExp(r'-(\d+)$');

    void scan(String id) {
      final match = trailingNumberPattern.firstMatch(id.trim());
      if (match == null) return;
      final value = int.tryParse(match.group(1)!);
      if (value != null) {
        maxNumericId = math.max(maxNumericId, value);
      }
    }

    for (final page in layout.pages) {
      for (final item in page.items) {
        scan(item.id);
      }
      for (final route in page.routes) {
        scan(route.id);
      }
    }
    _nextId = math.max(1, maxNumericId + 1);
  }

  void _loadBoard(TrainingBoard board) {
    final layout = TrainingMethodLayout.decode(board.layoutJson);
    _syncNextIdFromLayout(layout);
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
    _activeRouteHandleDrag = null;
    _routeReplaceMode = false;
    _playbackTracks = const <_PlaybackTrack>[];
    _hiddenPlaybackItemIds = <String>{};
    _playbackActiveStageIndex = null;
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

  _BoardPageState _copyBoardPageState(_BoardPageState page) {
    return _BoardPageState(
      name: page.name,
      methodText: page.methodText,
      items: page.items
          .map(
            (item) => _BoardItem(
              id: item.id,
              type: item.type,
              x: item.x,
              y: item.y,
              size: item.size,
              rotationDeg: item.rotationDeg,
              color: item.color,
            ),
          )
          .toList(growable: true),
      strokes: page.strokes
          .map(
            (stroke) => _BoardStroke(
              points: stroke.points.toList(growable: false),
              color: stroke.color,
              width: stroke.width,
            ),
          )
          .toList(growable: true),
      routes: page.routes
          .map(
            (route) => _BoardRoute(
              id: route.id,
              kind: route.kind,
              linkedItemId: route.linkedItemId,
              actorItemId: route.actorItemId,
              targetItemId: route.targetItemId,
              points: route.points.toList(growable: true),
              segmentDurationsMs: route.segmentDurationsMs.toList(
                growable: true,
              ),
              stageIndex: route.stageIndex,
              color: route.color,
              width: route.width,
            ),
          )
          .toList(growable: true),
    );
  }

  _SketchUndoSnapshot _captureActionUndoSnapshot() {
    return _SketchUndoSnapshot(
      page: _copyBoardPageState(_currentPage),
      nextId: _nextId,
      selectedItemId: _selectedItemId,
      selectedRouteId: _selectedRouteId,
      registeredNextActionStageIndex: _registeredNextActionStageIndex,
      pathDrawMode: _pathDrawMode,
      showSelectedColorPicker: _showSelectedColorPicker,
    );
  }

  void _restoreActionUndoSnapshot(_SketchUndoSnapshot snapshot) {
    _stopRoutePlayback(restoreStart: false);
    setState(() {
      _pages = <_BoardPageState>[_copyBoardPageState(snapshot.page)];
      _nextId = snapshot.nextId;
      _methodController.text = _currentPage.methodText;
      _selectedItemId = _currentPage.items.any(
        (item) => item.id == snapshot.selectedItemId,
      )
          ? snapshot.selectedItemId
          : null;
      _selectedRouteId = _currentPage.routes.any(
        (route) => route.id == snapshot.selectedRouteId,
      )
          ? snapshot.selectedRouteId
          : null;
      _registeredNextActionStageIndex = snapshot.registeredNextActionStageIndex;
      _pathDrawMode = snapshot.pathDrawMode;
      _showSelectedColorPicker = snapshot.showSelectedColorPicker;
      _clearPendingTargetActionState();
      _pathMode = false;
      _penMode = false;
      _routeReplaceMode = false;
      _activeStroke = null;
      _activeRoutePoints = null;
      _activeRouteSegmentDurationsMs = null;
      _activeRouteLastPointAt = null;
      _activeRouteHandleDrag = null;
      _hiddenPlaybackItemIds = <String>{};
      _playbackActiveStageIndex = null;
    });
    _scheduleAutoSave();
  }

  void _clearPendingTargetActionState() {
    _pendingTargetAction = null;
    _pendingTargetGuidePoint = null;
    _pendingMoveThenPassPoint = null;
  }

  void _showActionCreatedFeedback(_SketchUndoSnapshot snapshot) {
    _startCreatedActionPreview(snapshot);
    AppSoundEffects.playSketchMove();
    _actionUndoTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _pendingActionUndoSnapshot = snapshot;
    });
    _actionUndoTimer = Timer(_actionUndoVisibleDuration, () {
      if (!mounted) return;
      setState(() {
        _pendingActionUndoSnapshot = null;
      });
    });
  }

  void _handleActionUndoPressed() {
    final snapshot = _pendingActionUndoSnapshot;
    if (snapshot == null) return;
    _actionUndoTimer?.cancel();
    _actionUndoTimer = null;
    _restoreActionUndoSnapshot(snapshot);
    if (!mounted) return;
    setState(() {
      _pendingActionUndoSnapshot = null;
    });
  }

  Widget _buildActionUndoOverlay() {
    final hasUndoSnapshot = _pendingActionUndoSnapshot != null;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom + 12;
    return Positioned(
      left: 16,
      right: 16,
      bottom: bottomPadding,
      child: IgnorePointer(
        ignoring: !hasUndoSnapshot,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: hasUndoSnapshot
              ? Align(
                  key: const ValueKey('training-action-undo-overlay'),
                  alignment: Alignment.bottomCenter,
                  child: Semantics(
                    button: true,
                    label: _l10n.undo,
                    child: Material(
                      elevation: 0,
                      borderRadius: BorderRadius.circular(8),
                      color: colors.surfaceContainerHighest.withValues(
                        alpha: 0.94,
                      ),
                      child: InkWell(
                        key: const ValueKey('training-action-undo-button'),
                        onTap: _handleActionUndoPressed,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.undo,
                                size: 18,
                                color: colors.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _l10n.undo,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: colors.onSurfaceVariant,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(
                  key: ValueKey('training-action-undo-empty'),
                ),
        ),
      ),
    );
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

  _BoardRoute? _routeById(String id) {
    return _firstWhereOrNull(_currentPage.routes, (route) => route.id == id);
  }

  int _routeableItemCount(_PathDrawMode kind) {
    return _routeableItems(kind).length;
  }

  List<_BoardItem> _routeableItems(_PathDrawMode kind) {
    if (kind == _PathDrawMode.ball) {
      return const <_BoardItem>[];
    }
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
          _BoardItemType.base,
          _BoardItemType.target,
          _BoardItemType.cone,
        ],
      SportCatalog.basketballId => const <_BoardItemType>[
          _BoardItemType.player,
          _BoardItemType.basket,
          _BoardItemType.target,
          _BoardItemType.cone,
        ],
      SportCatalog.tennisId => const <_BoardItemType>[
          _BoardItemType.player,
          _BoardItemType.target,
          _BoardItemType.cone,
        ],
      _ => const <_BoardItemType>[
          _BoardItemType.player,
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
    for (final route in _currentPage.routes.reversed) {
      if (route.kind == kind &&
          route.id != excludingRouteId &&
          route.linkedItemId == itemId) {
        return route;
      }
    }
    return null;
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

  Offset _playerActionPointAtStage(_BoardItem player, int stageIndex) {
    final candidates = _currentPage.routes
        .where(
          (route) =>
              route.kind == _PathDrawMode.player &&
              route.points.isNotEmpty &&
              _normalizedRouteStageIndex(route.stageIndex) <= stageIndex &&
              (route.linkedItemId == player.id ||
                  route.actorItemId == player.id),
        )
        .toList(growable: false)
      ..sort((a, b) {
        final stageComparison = _normalizedRouteStageIndex(
          a.stageIndex,
        ).compareTo(_normalizedRouteStageIndex(b.stageIndex));
        if (stageComparison != 0) return stageComparison;
        return _currentPage.routes.indexOf(a).compareTo(
              _currentPage.routes.indexOf(b),
            );
      });
    return candidates.isEmpty
        ? _itemPosition(player)
        : candidates.last.points.last;
  }

  void _refreshTargetedPassRouteEndpoints() {
    for (final route in _currentPage.routes) {
      if (route.kind != _PathDrawMode.ball ||
          route.points.length < 2 ||
          route.targetItemId == null ||
          route.targetItemId == route.actorItemId) {
        continue;
      }
      final target = _itemById(route.targetItemId!);
      if (target == null || target.type != _BoardItemType.player) continue;
      route.points[route.points.length - 1] = _playerActionPointAtStage(
        target,
        _normalizedRouteStageIndex(route.stageIndex),
      );
    }
  }

  Offset _boardItemDisplayPoint(_BoardItem item) {
    final action = _pendingTargetAction;
    if (action != null &&
        _requiresReceiverTargetAction(action) &&
        item.type == _BoardItemType.player &&
        _isValidBoardItemTargetForAction(action, item)) {
      return _itemActionPoint(item);
    }
    return _itemPosition(item);
  }

  Offset? _pendingTargetGuideStartPoint() {
    final action = _pendingTargetAction;
    final selected = _selectedItem;
    if (action == null ||
        selected == null ||
        !_usesDestinationGuideForAction(action)) {
      return null;
    }
    final player = _playerForTargetAction(selected);
    if (player == null) return null;
    if (action == _SketchTargetAction.moveThenPass) {
      return _playerFlowOriginPoint(player);
    }
    if (_requiresBallTargetAction(action)) {
      final ballRoute = _currentBallRouteForPlayer(player);
      if (ballRoute != null && ballRoute.points.isNotEmpty) {
        return ballRoute.points.last;
      }
      final controlledBall = _controlledBallForPlayer(player);
      if (controlledBall != null) {
        return _itemPosition(controlledBall);
      }
    }
    return _playerFlowOriginPoint(player);
  }

  Offset _initialTargetGuidePointForAction(
    _SketchTargetAction action,
    _BoardItem selected,
  ) {
    final start = _playerForTargetAction(selected) == null
        ? _itemPosition(selected)
        : _pendingTargetGuideStartPoint() ?? _playerFlowOriginPoint(selected);
    final forwardX = start.dx <= 0.5 ? 0.20 : -0.20;
    final verticalOffset = start.dy < 0.5 ? 0.08 : -0.08;
    final goalX = start.dx <= 0.5 ? 0.88 : 0.12;
    return switch (action) {
      _SketchTargetAction.shot ||
      _SketchTargetAction.cross ||
      _SketchTargetAction.throwBall ||
      _SketchTargetAction.serve ||
      _SketchTargetAction.rally =>
        _clampedBoardPoint(goalX, start.dy + verticalOffset),
      _SketchTargetAction.returnMove =>
        _clampedBoardPoint(start.dx - forwardX, start.dy),
      _ => _clampedBoardPoint(start.dx + forwardX, start.dy + verticalOffset),
    };
  }

  void _refreshPendingTargetGuidePoint() {
    final action = _pendingTargetAction;
    final selected = _selectedItem;
    _pendingTargetGuidePoint = action != null &&
            selected != null &&
            _usesDestinationGuideForAction(action) &&
            action != _SketchTargetAction.move
        ? _initialTargetGuidePointForAction(action, selected)
        : null;
  }

  void _updatePendingTargetGuidePoint(
    Offset localPosition,
    double width,
    double height,
  ) {
    final action = _pendingTargetAction;
    if (action == null || !_usesDestinationGuideForAction(action)) return;
    final point = _boardPointFromLocal(localPosition, width, height);
    if (_pendingTargetGuidePoint != null &&
        (_pendingTargetGuidePoint! - point).distance < 0.003) {
      return;
    }
    setState(() => _pendingTargetGuidePoint = point);
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
          (latestRoute.actorItemId == null &&
              latestRoute.targetItemId == null &&
              (_itemPosition(ball) - _itemPosition(player)).distance <=
                  _ballPossessionRadius) ||
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

  _BoardItem? _nearestPlayerActionPointToPoint(
    Offset point, {
    required double radius,
  }) {
    final players = _itemsOfType(_BoardItemType.player);
    if (players.isEmpty) return null;
    players.sort((a, b) {
      final aDistance = (_itemActionPoint(a) - point).distance;
      final bDistance = (_itemActionPoint(b) - point).distance;
      return aDistance.compareTo(bDistance);
    });
    final nearest = players.first;
    return (_itemActionPoint(nearest) - point).distance <= radius
        ? nearest
        : null;
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

  Offset _currentBallPoint(_BoardItem ball) {
    final latestRoute = _latestBallRouteForBall(ball);
    if (latestRoute != null && latestRoute.points.isNotEmpty) {
      return latestRoute.points.last;
    }
    return _itemPosition(ball);
  }

  _BoardItem? _nearestUnownedBallNearPlayer(
    _BoardItem player, {
    double radius = _ballPossessionRadius,
  }) {
    final origin = _playerFlowOriginPoint(player);
    final balls = _itemsOfType(_BoardItemType.ball)
        .where((ball) => _currentBallOwner(ball) == null)
        .toList(growable: false);
    if (balls.isEmpty) return null;
    balls.sort((a, b) {
      final aDistance = (_currentBallPoint(a) - origin).distance;
      final bDistance = (_currentBallPoint(b) - origin).distance;
      return aDistance.compareTo(bDistance);
    });
    final nearest = balls.first;
    return (_currentBallPoint(nearest) - origin).distance <= radius
        ? nearest
        : null;
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
      _SketchTargetAction.moveToBall ||
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
      _SketchTargetAction.moveThenPass ||
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
      _SketchTargetAction.moveToBall ||
      _SketchTargetAction.passAndMove ||
      _SketchTargetAction.moveThenPass ||
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

  bool _requiresReceiverTargetAction(_SketchTargetAction action) {
    return action == _SketchTargetAction.pass ||
        action == _SketchTargetAction.passAndMove ||
        action == _SketchTargetAction.moveThenPass;
  }

  _BoardItemType? _requiredBoardItemTargetTypeForAction(
    _SketchTargetAction action,
  ) {
    return switch (action) {
      _SketchTargetAction.coneTurn ||
      _SketchTargetAction.coneJump =>
        _BoardItemType.cone,
      _SketchTargetAction.hurdleJump => _BoardItemType.hurdle,
      _ => null,
    };
  }

  bool _usesDestinationGuideForAction(_SketchTargetAction action) {
    if (_requiresReceiverTargetAction(action) &&
        action != _SketchTargetAction.moveThenPass) {
      return false;
    }
    if (_requiredBoardItemTargetTypeForAction(action) != null) return false;
    return switch (action) {
      _SketchTargetAction.move ||
      _SketchTargetAction.dribble ||
      _SketchTargetAction.receiveMove ||
      _SketchTargetAction.returnMove ||
      _SketchTargetAction.overlap ||
      _SketchTargetAction.shot ||
      _SketchTargetAction.cross ||
      _SketchTargetAction.drive ||
      _SketchTargetAction.cut ||
      _SketchTargetAction.screen ||
      _SketchTargetAction.runBase ||
      _SketchTargetAction.fielding ||
      _SketchTargetAction.throwBall ||
      _SketchTargetAction.serve ||
      _SketchTargetAction.rally ||
      _SketchTargetAction.recover =>
        true,
      _SketchTargetAction.moveThenPass => _pendingMoveThenPassPoint == null,
      _SketchTargetAction.moveToBall ||
      _SketchTargetAction.pass ||
      _SketchTargetAction.passAndMove ||
      _SketchTargetAction.coneTurn ||
      _SketchTargetAction.coneJump ||
      _SketchTargetAction.hurdleJump =>
        false,
    };
  }

  List<_BoardItem> _passTargetPlayersFor(_BoardItem player) {
    return _itemsOfType(_BoardItemType.player, excludingId: player.id);
  }

  bool _isValidBoardItemTargetForAction(
    _SketchTargetAction action,
    _BoardItem target,
  ) {
    final selected = _selectedItem;
    if (action == _SketchTargetAction.moveThenPass &&
        _pendingMoveThenPassPoint == null) {
      return false;
    }
    if (_requiresReceiverTargetAction(action)) {
      return selected != null &&
          target.type == _BoardItemType.player &&
          target.id != selected.id;
    }
    final requiredType = _requiredBoardItemTargetTypeForAction(action);
    if (requiredType != null) {
      return target.type == requiredType;
    }
    return false;
  }

  bool _isHighlightedTargetItem(_BoardItem item) {
    final action = _pendingTargetAction;
    return action != null && _isValidBoardItemTargetForAction(action, item);
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

  bool _ballRouteImplicitlyCarriesWithPlayer(
    _BoardRoute route,
    _BoardItem player,
  ) {
    if (route.actorItemId != player.id || route.points.length < 3) {
      return false;
    }
    final routeStage = _normalizedRouteStageIndex(route.stageIndex);
    return _currentPage.routes.any((playerRoute) {
      if (playerRoute.kind != _PathDrawMode.player ||
          playerRoute.points.isEmpty ||
          playerRoute.linkedItemId != player.id ||
          _normalizedRouteStageIndex(playerRoute.stageIndex) != routeStage) {
        return false;
      }
      return (playerRoute.points.last - route.points.last).distance <=
          _ballPossessionRadius;
    });
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
    return _ballRouteImplicitlyCarriesWithPlayer(route, player);
  }

  bool _playerHasBallForFlow(_BoardItem player) {
    return _itemsOfType(_BoardItemType.ball).any(
      (ball) => _currentBallOwner(ball)?.id == player.id,
    );
  }

  bool _canUsePlayerFlowBallActions(_BoardItem player) {
    return _playerHasBallForFlow(player) ||
        _itemsOfType(_BoardItemType.ball).isEmpty;
  }

  bool _canUsePlayerFlowMovementAction(
    _BoardItem player,
    _SketchTargetAction action,
  ) {
    final hasBall = _playerHasBallForFlow(player);
    if (hasBall) {
      return switch (action) {
        _SketchTargetAction.moveToBall ||
        _SketchTargetAction.receiveMove ||
        _SketchTargetAction.overlap ||
        _SketchTargetAction.cut ||
        _SketchTargetAction.screen =>
          false,
        _ => true,
      };
    }
    if (action == _SketchTargetAction.moveToBall) {
      return _nearestUnownedBallNearPlayer(player) != null;
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
      _refreshTargetedPassRouteEndpoints();
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
    _refreshTargetedPassRouteEndpoints();
    return created;
  }

  void _normalizeCurrentPageRoutes() {
    final assignedUnlinkedItemIdsByKind = <_PathDrawMode, Set<String>>{
      _PathDrawMode.player: <String>{},
      _PathDrawMode.ball: <String>{},
    };
    final normalizedRoutes = <_BoardRoute>[];
    for (final route in _currentPage.routes.reversed) {
      final hasLinkedItem = route.linkedItemId?.trim().isNotEmpty == true;
      final assignedItemIds = hasLinkedItem
          ? const <String>{}
          : assignedUnlinkedItemIdsByKind[route.kind]!;
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
      if (!hasLinkedItem) {
        assignedUnlinkedItemIdsByKind[route.kind]!.add(linkedItem.id);
      }
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
    _refreshTargetedPassRouteEndpoints();
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
    return _currentPage.routes
        .where((route) => route.points.length >= 2)
        .toList(growable: false);
  }

  List<_PlaybackTrack> _resolvePlaybackTracks({
    List<_BoardRoute>? sourceRoutes,
  }) {
    final orderedRoutes = (sourceRoutes ?? _orderedPlaybackRoutes())
        .where((route) => route.points.length >= 2)
        .toList(growable: false);
    final usesStages = _usesRouteStages(orderedRoutes);
    final routeOrder = <String, int>{
      for (var index = 0; index < orderedRoutes.length; index++)
        orderedRoutes[index].id: index,
    };
    final assignedUnlinkedItemIds = <String>{};
    final itemsByTrackKey = <String, _BoardItem>{};
    final routesByTrackKey = <String, List<_BoardRoute>>{};
    final routeTrackKeys = <String, String>{};

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
      routeTrackKeys[route.id] = trackKey;
      routesByTrackKey.putIfAbsent(trackKey, () => <_BoardRoute>[]).add(route);
    }

    final routeStartOffsetsMs = usesStages
        ? _routeStartOffsetsForPlayback(
            orderedRoutes: orderedRoutes,
            routeTrackKeys: routeTrackKeys,
            routeOrder: routeOrder,
          )
        : const <String, int>{};
    final tracks = <_PlaybackTrack>[];
    for (final entry in routesByTrackKey.entries) {
      final item = itemsByTrackKey[entry.key];
      if (item == null) continue;
      final routes = entry.value.toList(growable: false)
        ..sort((a, b) {
          if (usesStages) {
            final startCompare = (routeStartOffsetsMs[a.id] ?? 0).compareTo(
              routeStartOffsetsMs[b.id] ?? 0,
            );
            if (startCompare != 0) return startCompare;
          }
          final stageCompare = _normalizedRouteStageIndex(
            a.stageIndex,
          ).compareTo(_normalizedRouteStageIndex(b.stageIndex));
          if (stageCompare != 0) return stageCompare;
          return (routeOrder[a.id] ?? 0).compareTo(routeOrder[b.id] ?? 0);
        });
      final segments = <_PlaybackSegment>[];
      var elapsedMs = 0;
      for (final route in routes) {
        final routeStage = _normalizedRouteStageIndex(route.stageIndex);
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
          stageIndex: routeStage,
        );
        if (routeSegments.isEmpty) continue;
        if (usesStages) {
          final routeStartMs = routeStartOffsetsMs[route.id] ?? elapsedMs;
          if (routeStartMs > elapsedMs) {
            final waitPoint =
                segments.isEmpty ? timing.points.first : segments.last.end;
            final hideWait = segments.isEmpty &&
                _shouldHidePlaybackWaitForRoute(
                  route: route,
                  routeStartMs: routeStartMs,
                );
            segments.add(
              _PlaybackSegment(
                start: waitPoint,
                end: waitPoint,
                durationSeconds: (routeStartMs - elapsedMs) / 1000,
                visible: !hideWait,
              ),
            );
            elapsedMs = routeStartMs;
          }
        }
        segments.addAll(routeSegments);
        elapsedMs += routeSegments.fold<int>(
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

  bool _shouldHidePlaybackWaitForRoute({
    required _BoardRoute route,
    required int routeStartMs,
  }) {
    if (routeStartMs <= 0 ||
        route.kind != _PathDrawMode.ball ||
        route.actorItemId == null ||
        route.targetItemId == route.actorItemId) {
      return false;
    }
    return !_currentPage.routes.any(
      (candidate) =>
          candidate.id != route.id &&
          candidate.kind == _PathDrawMode.ball &&
          candidate.linkedItemId == route.linkedItemId &&
          candidate.points.length >= 2 &&
          _normalizedRouteStageIndex(candidate.stageIndex) <
              _normalizedRouteStageIndex(route.stageIndex),
    );
  }

  Map<String, int> _routeStartOffsetsForPlayback({
    required List<_BoardRoute> orderedRoutes,
    required Map<String, String> routeTrackKeys,
    required Map<String, int> routeOrder,
  }) {
    final routes = orderedRoutes
        .where(
          (route) =>
              route.points.length >= 2 && routeTrackKeys.containsKey(route.id),
        )
        .toList(growable: false)
      ..sort((a, b) {
        final stageCompare = _normalizedRouteStageIndex(
          a.stageIndex,
        ).compareTo(_normalizedRouteStageIndex(b.stageIndex));
        if (stageCompare != 0) return stageCompare;
        return (routeOrder[a.id] ?? 0).compareTo(routeOrder[b.id] ?? 0);
      });
    final startOffsets = <String, int>{};
    final trackEndMs = <String, int>{};
    final playerEndsByPlayerId = <String, List<_PlaybackStageEnd>>{};
    final incomingBallEndsByPlayerId = <String, List<_PlaybackStageEnd>>{};

    for (final route in routes) {
      final trackKey = routeTrackKeys[route.id];
      if (trackKey == null) continue;
      final routeTiming = _routeTimingWithoutLeadingWait(route);
      final durationMs = _routeTimingPlaybackDurationMs(
        kind: route.kind,
        timing: routeTiming,
      );
      if (durationMs <= 0) continue;
      final stage = _normalizedRouteStageIndex(route.stageIndex);
      var startMs = trackEndMs[trackKey] ?? 0;
      if (route.kind == _PathDrawMode.ball) {
        final actorId = route.actorItemId;
        if (actorId != null) {
          startMs = math.max(
            startMs,
            _latestActorMovementDependencyEndBeforeStage(
              playerEndsByPlayerId[actorId],
              stage,
              routeTiming.points.first,
            ),
          );
          startMs = math.max(
            startMs,
            _latestPlaybackDependencyEndBeforeStage(
              incomingBallEndsByPlayerId[actorId],
              stage,
            ),
          );
        }
      } else {
        final playerId = route.linkedItemId ?? route.actorItemId;
        if (playerId != null) {
          startMs = math.max(
            startMs,
            _latestPlaybackDependencyEndBeforeStage(
              incomingBallEndsByPlayerId[playerId],
              stage,
            ),
          );
        }
      }

      startOffsets[route.id] = startMs;
      final endMs = startMs + durationMs;
      trackEndMs[trackKey] = math.max(trackEndMs[trackKey] ?? 0, endMs);
      if (route.kind == _PathDrawMode.player) {
        final playerId = route.linkedItemId ?? route.actorItemId;
        if (playerId != null) {
          playerEndsByPlayerId
              .putIfAbsent(playerId, () => <_PlaybackStageEnd>[])
              .add(
                _PlaybackStageEnd(
                  stageIndex: stage,
                  endMs: endMs,
                  start: routeTiming.points.first,
                  end: routeTiming.points.last,
                ),
              );
        }
      } else {
        final targetId = route.targetItemId;
        if (targetId != null && targetId != route.actorItemId) {
          incomingBallEndsByPlayerId
              .putIfAbsent(targetId, () => <_PlaybackStageEnd>[])
              .add(
                _PlaybackStageEnd(
                  stageIndex: stage,
                  endMs: endMs,
                  start: routeTiming.points.first,
                  end: routeTiming.points.last,
                ),
              );
        }
      }
    }
    return startOffsets;
  }

  int _latestActorMovementDependencyEndBeforeStage(
    List<_PlaybackStageEnd>? dependencies,
    int stageIndex,
    Offset ballStart,
  ) {
    if (dependencies == null || dependencies.isEmpty) return 0;
    var latestEndMs = 0;
    for (final dependency in dependencies) {
      if (dependency.stageIndex >= stageIndex) continue;
      if (!_ballStartFollowsPlayerRouteEnd(ballStart, dependency)) {
        continue;
      }
      latestEndMs = math.max(latestEndMs, dependency.endMs);
    }
    return latestEndMs;
  }

  bool _ballStartFollowsPlayerRouteEnd(
    Offset ballStart,
    _PlaybackStageEnd dependency,
  ) {
    final distanceFromRouteEnd = (ballStart - dependency.end).distance;
    if (distanceFromRouteEnd > _playbackBallCarryPointRadius) {
      return false;
    }
    final distanceFromRouteStart = (ballStart - dependency.start).distance;
    return distanceFromRouteStart > _playbackBallCarryPointRadius;
  }

  int _latestPlaybackDependencyEndBeforeStage(
    List<_PlaybackStageEnd>? dependencies,
    int stageIndex,
  ) {
    if (dependencies == null || dependencies.isEmpty) return 0;
    var latestEndMs = 0;
    for (final dependency in dependencies) {
      if (dependency.stageIndex < stageIndex) {
        latestEndMs = math.max(latestEndMs, dependency.endMs);
      }
    }
    return latestEndMs;
  }

  void _moveItemWithLinkedRoutes(
    _BoardItem item, {
    required double nextX,
    required double nextY,
  }) {
    final oldPosition = _itemPosition(item);
    final ownedBalls = item.type == _BoardItemType.player
        ? _itemsOfType(_BoardItemType.ball)
            .where((ball) => _currentBallOwner(ball)?.id == item.id)
            .toList(growable: false)
        : const <_BoardItem>[];
    final dx = nextX - item.x;
    final dy = nextY - item.y;
    if (dx.abs() < 0.0001 && dy.abs() < 0.0001) return;
    final delta = Offset(dx, dy);
    item.x = nextX;
    item.y = nextY;
    for (final ball in ownedBalls) {
      // A controlled ball follows the player and stays visibly in front of
      // the new movement direction instead of being left at its old offset.
      _placeBallInFrontOfPlayer(
        item,
        ball,
        toward: Offset(nextX + delta.dx, nextY + delta.dy),
      );
    }
    for (final route in _currentPage.routes) {
      if (route.points.isEmpty) continue;
      if (route.linkedItemId == item.id) {
        if (_linkedRouteUsesSetupAnchor(route, item, oldPosition)) {
          _shiftRoutePoints(route, delta, endIndex: 0);
        } else if (route.actorItemId == null) {
          _shiftRoutePoints(route, delta);
        }
        continue;
      }
      if (route.actorItemId == item.id &&
          route.kind == _PathDrawMode.ball &&
          _routeEndpointFollowsItemSetup(route.points.first, oldPosition)) {
        _shiftRoutePoints(route, delta, endIndex: 0);
      }
      if (route.targetItemId == item.id) {
        if (_isTargetProp(item) && route.kind == _PathDrawMode.player) {
          _shiftRoutePoints(route, delta, startIndex: 1);
          _shiftPossessedBallRoutesForTargetedPlayerRoute(route, delta);
        } else if (_isTargetProp(item)) {
          _shiftRoutePoints(route, delta, startIndex: route.points.length - 1);
        } else if (route.actorItemId != item.id ||
            _routeEndpointFollowsItemSetup(route.points.last, oldPosition)) {
          _shiftRoutePoints(route, delta, startIndex: route.points.length - 1);
        }
      }
    }
  }

  bool _linkedRouteUsesSetupAnchor(
    _BoardRoute route,
    _BoardItem item,
    Offset oldPosition,
  ) {
    if (route.kind != _PathDrawMode.player ||
        item.type != _BoardItemType.player ||
        route.actorItemId == null) {
      return false;
    }
    return _routeEndpointFollowsItemSetup(route.points.first, oldPosition);
  }

  bool _routeEndpointFollowsItemSetup(Offset point, Offset oldPosition) {
    return (point - oldPosition).distance <= 0.09;
  }

  bool _isTargetProp(_BoardItem item) {
    return switch (item.type) {
      _BoardItemType.cone ||
      _BoardItemType.hurdle ||
      _BoardItemType.ladder ||
      _BoardItemType.target ||
      _BoardItemType.base ||
      _BoardItemType.basket =>
        true,
      _BoardItemType.player || _BoardItemType.ball => false,
    };
  }

  void _shiftRoutePoints(
    _BoardRoute route,
    Offset delta, {
    int startIndex = 0,
    int? endIndex,
  }) {
    if (route.points.isEmpty) return;
    final start = startIndex.clamp(0, route.points.length - 1).toInt();
    final end = (endIndex ?? route.points.length - 1)
        .clamp(start, route.points.length - 1)
        .toInt();
    for (var index = start; index <= end; index++) {
      final point = route.points[index];
      route.points[index] = Offset(
        (point.dx + delta.dx).clamp(0.0, 1.0).toDouble(),
        (point.dy + delta.dy).clamp(0.0, 1.0).toDouble(),
      );
    }
  }

  void _shiftPossessedBallRoutesForTargetedPlayerRoute(
    _BoardRoute playerRoute,
    Offset delta,
  ) {
    final actorId = playerRoute.actorItemId ?? playerRoute.linkedItemId;
    if (actorId == null) return;
    final stageIndex = _normalizedRouteStageIndex(playerRoute.stageIndex);
    for (final route in _currentPage.routes) {
      if (route.kind != _PathDrawMode.ball ||
          route.actorItemId != actorId ||
          route.targetItemId != actorId ||
          _normalizedRouteStageIndex(route.stageIndex) != stageIndex ||
          route.points.length < 2) {
        continue;
      }
      _shiftRoutePoints(route, delta, startIndex: 1);
    }
  }

  _PathDrawMode? _routeKindForItem(_BoardItem item) {
    return switch (item.type) {
      _BoardItemType.player => _PathDrawMode.player,
      _ => null,
    };
  }

  String? _selectableItemIdForRoute(_BoardRoute route) {
    if (route.kind == _PathDrawMode.player) {
      return route.linkedItemId ?? route.actorItemId;
    }
    final target =
        route.targetItemId == null ? null : _itemById(route.targetItemId!);
    if (target?.type == _BoardItemType.player) {
      return target?.id;
    }
    final actor =
        route.actorItemId == null ? null : _itemById(route.actorItemId!);
    if (actor?.type == _BoardItemType.player) {
      return actor?.id;
    }
    final ball =
        route.linkedItemId == null ? null : _itemById(route.linkedItemId!);
    if (ball != null && ball.type == _BoardItemType.ball) {
      return _currentBallOwner(ball)?.id;
    }
    return null;
  }

  int _boardItemPaintPriority(_BoardItem item) {
    if (_isHighlightedTargetItem(item)) return 5;
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
    if (item.type == _BoardItemType.ball) {
      final owner = _currentBallOwner(item);
      if (owner != null) {
        _selectBoardItem(owner);
      }
      return;
    }
    if (item.type != _BoardItemType.player) {
      return;
    }
    final kind = _routeKindForItem(item);
    setState(() {
      final wasSelected = _selectedItemId == item.id;
      if (_selectedItemId != item.id) {
        _showSelectedColorPicker = false;
      }
      _selectedItemId = item.id;
      _clearPendingTargetActionState();
      if (wasSelected &&
          item.type == _BoardItemType.player &&
          !_pathMode &&
          _kickRouteStageForImmediateMove(item) == null) {
        _registeredNextActionStageIndex = _nextStageForPlayerFlow(item);
      }
      _routeReplaceMode = false;
      _activeRoutePoints = null;
      _activeRouteSegmentDurationsMs = null;
      _activeRouteLastPointAt = null;
      _activeRouteHandleDrag = null;
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
      if (!_isValidBoardItemTargetForAction(action, item)) {
        return;
      }
      _applyPendingTargetActionToItem(action: action, target: item);
      return;
    }
    _selectBoardItem(item);
  }

  void _startItemMove(_BoardItem item) {
    if (widget.readOnly || _playController.isAnimating) return;
    if (item.type == _BoardItemType.ball) return;
    _stopRoutePlayback(restoreStart: false);
    unawaited(HapticFeedback.selectionClick());
    if (item.type != _BoardItemType.player) {
      setState(() {
        _movingItemId = item.id;
        _lastLongPressMoveOffset = Offset.zero;
        _selectedItemId = item.id;
        _selectedRouteId = null;
        _showSelectedColorPicker = false;
        _clearPendingTargetActionState();
      });
      return;
    }
    final kind = _routeKindForItem(item);
    setState(() {
      _movingItemId = item.id;
      _lastLongPressMoveOffset = Offset.zero;
      _showSelectedColorPicker = false;
      _selectedItemId = item.id;
      _clearPendingTargetActionState();
      _routeReplaceMode = false;
      _activeStroke = null;
      _activeRoutePoints = null;
      _activeRouteSegmentDurationsMs = null;
      _activeRouteLastPointAt = null;
      _activeRouteHandleDrag = null;
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
      _selectedItemId = type == _BoardItemType.player ? item.id : null;
      _selectedRouteId = null;
      _showSelectedColorPicker = false;
      _penMode = false;
      _pathMode = false;
      _clearPendingTargetActionState();
      _routeReplaceMode = false;
      _activeStroke = null;
      _activeRoutePoints = null;
      _activeRouteSegmentDurationsMs = null;
      _activeRouteLastPointAt = null;
      _activeRouteHandleDrag = null;
    });
    _scheduleAutoSave();
  }

  void _removeSelected() {
    final id = _selectedItemId;
    if (id == null) return;
    _stopRoutePlayback(restoreStart: false);
    setState(() {
      final selectedItem = _itemById(id);
      final itemIdsToRemove = <String>{id};
      if (selectedItem?.type == _BoardItemType.player) {
        itemIdsToRemove.addAll(
          _itemsOfType(_BoardItemType.ball).where((ball) {
            final owner = _currentBallOwner(ball);
            return owner == null || owner.id == id;
          }).map((ball) => ball.id),
        );
      }
      _currentPage.items.removeWhere((e) => itemIdsToRemove.contains(e.id));
      final removedSelectedRoute = _selectedRouteId;
      _currentPage.routes.removeWhere(
        (route) => itemIdsToRemove.contains(route.linkedItemId),
      );
      for (final route in _currentPage.routes) {
        if (itemIdsToRemove.contains(route.targetItemId)) {
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
      _clearPendingTargetActionState();
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
      AppSoundEffects.playRewardClaimed();
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
      _activeRouteHandleDrag = null;
      _routeReplaceMode = false;
      _playbackTracks = const <_PlaybackTrack>[];
      _hiddenPlaybackItemIds = <String>{};
      _playbackActiveStageIndex = null;
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

  double _distanceToSegment(Offset point, Offset start, Offset end) {
    final segment = end - start;
    final lengthSquared = segment.distanceSquared;
    if (lengthSquared <= 0.0001) return (point - start).distance;
    final t =
        ((point - start).dx * segment.dx + (point - start).dy * segment.dy) /
            lengthSquared;
    final projected = start + segment * t.clamp(0.0, 1.0).toDouble();
    return (point - projected).distance;
  }

  double _distanceToRouteLocal(
    _BoardRoute route,
    Offset localPosition,
    double width,
    double height,
  ) {
    if (route.points.length < 2) return double.infinity;
    var nearest = double.infinity;
    for (var index = 0; index < route.points.length - 1; index++) {
      final start = _routePointToLocal(route.points[index], width, height);
      final end = _routePointToLocal(route.points[index + 1], width, height);
      nearest = math.min(
        nearest,
        _distanceToSegment(localPosition, start, end),
      );
    }
    return nearest;
  }

  _BoardRoute? _routeNearLocalPoint(
    Offset localPosition,
    double width,
    double height, {
    double hitRadius = 24,
  }) {
    _BoardRoute? nearest;
    var nearestDistance = hitRadius;
    for (final route in _currentPage.routes.reversed) {
      if (route.points.length < 2) continue;
      final distance = _distanceToRouteLocal(
        route,
        localPosition,
        width,
        height,
      );
      if (distance <= nearestDistance) {
        nearest = route;
        nearestDistance = distance;
      }
    }
    return nearest;
  }

  _BoardItem? _boardItemNearLocalPoint(
    Offset localPosition,
    double width,
    double height,
  ) {
    for (final item in _boardItemsInPaintOrder().reversed) {
      if (_hiddenPlaybackItemIds.contains(item.id)) continue;
      final itemLocal = _routePointToLocal(
        _boardItemDisplayPoint(item),
        width,
        height,
      );
      if ((itemLocal - localPosition).distance <= 30) {
        return item;
      }
    }
    return null;
  }

  void _selectRouteFromBoard(_BoardRoute route) {
    if (widget.readOnly || _playController.isAnimating) return;
    _stopRoutePlayback(restoreStart: false);
    setState(() {
      _selectedItemId = _selectableItemIdForRoute(route);
      _selectedRouteId = route.id;
      _registeredNextActionStageIndex =
          _normalizedRouteStageIndex(route.stageIndex);
      _pathDrawMode = route.kind;
      _showSelectedColorPicker = false;
      _pathMode = false;
      _penMode = false;
      _clearPendingTargetActionState();
      _routeReplaceMode = false;
      _activeStroke = null;
      _activeRoutePoints = null;
      _activeRouteSegmentDurationsMs = null;
      _activeRouteLastPointAt = null;
      _activeRouteHandleDrag = null;
    });
  }

  void _handleBoardSelectionTap(
    Offset localPosition,
    double width,
    double height,
  ) {
    if (widget.readOnly || _playController.isAnimating) return;
    if (_boardItemNearLocalPoint(localPosition, width, height) != null) return;
    final route = _routeNearLocalPoint(localPosition, width, height);
    if (route == null) return;
    _selectRouteFromBoard(route);
  }

  _BoardRoute? _routeWithEndNearLocalPoint(
    Offset localPosition,
    double width,
    double height,
  ) {
    const hitRadius = 28.0;
    final selectedRoute = _selectedRoute;
    if (selectedRoute != null &&
        selectedRoute.kind == _PathDrawMode.player &&
        selectedRoute.points.length >= 2) {
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
      if (route.kind != _PathDrawMode.player ||
          route.points.length < 2 ||
          route.id == selectedRoute?.id) {
        continue;
      }
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
      _clearPendingTargetActionState();
      _showSelectedColorPicker = false;
      _activeRoutePoints = List<Offset>.from(route.points);
      _activeRouteSegmentDurationsMs = _normalizedRouteSegmentDurations(
        pointCount: route.points.length,
        rawDurationsMs: route.segmentDurationsMs,
      ).toList(growable: true);
      _activeRouteLastPointAt = DateTime.now();
      final selectableItemId = _selectableItemIdForRoute(route);
      if (selectableItemId != null) {
        _selectedItemId = selectableItemId;
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
        _activeRouteHandleDrag = null;
        _routeReplaceMode = false;
      });
      return;
    }
    _endPlayerPath();
  }

  void _selectRouteForHandleDrag(_BoardRoute route) {
    _selectedRouteId = route.id;
    _selectedItemId = _selectableItemIdForRoute(route);
    _registeredNextActionStageIndex =
        _normalizedRouteStageIndex(route.stageIndex);
    _pathDrawMode = route.kind;
    _showSelectedColorPicker = false;
    _pathMode = false;
    _penMode = false;
    _clearPendingTargetActionState();
    _routeReplaceMode = false;
    _activeStroke = null;
    _activeRoutePoints = null;
    _activeRouteSegmentDurationsMs = null;
    _activeRouteLastPointAt = null;
    _activeRouteHandleDrag = null;
  }

  void _startRoutePointHandleDrag(
    _BoardRoute route,
    int pointIndex, {
    required Key handleKey,
  }) {
    if (widget.readOnly ||
        _playController.isAnimating ||
        pointIndex <= 0 ||
        pointIndex >= route.points.length - 1) {
      return;
    }
    unawaited(HapticFeedback.selectionClick());
    _selectRouteForHandleDrag(route);
    _activeRouteHandleDrag = _RouteHandleDrag(
      routeId: route.id,
      pointIndex: pointIndex,
      handleKey: handleKey,
    );
  }

  void _startRouteSegmentHandleDrag(
    _BoardRoute route,
    int segmentIndex, {
    required Key handleKey,
  }) {
    if (widget.readOnly ||
        _playController.isAnimating ||
        segmentIndex < 0 ||
        segmentIndex >= route.points.length - 1) {
      return;
    }
    unawaited(HapticFeedback.selectionClick());
    _selectRouteForHandleDrag(route);
    _activeRouteHandleDrag = _RouteHandleDrag(
      routeId: route.id,
      segmentIndex: segmentIndex,
      handleKey: handleKey,
    );
  }

  void _updateRouteHandleDragByDelta(
    Offset delta, {
    required double boardWidth,
    required double boardHeight,
  }) {
    if (widget.readOnly || _playController.isAnimating) return;
    final drag = _activeRouteHandleDrag;
    if (drag == null || delta.distance < 0.5) return;
    final route = _routeById(drag.routeId);
    if (route == null) return;
    setState(() {
      var pointIndex = drag.pointIndex;
      if (pointIndex == null) {
        final segmentIndex = drag.segmentIndex;
        if (segmentIndex == null ||
            segmentIndex < 0 ||
            segmentIndex >= route.points.length - 1) {
          return;
        }
        final originalDurations = _normalizedRouteSegmentDurations(
          pointCount: route.points.length,
          rawDurationsMs: route.segmentDurationsMs,
        ).toList(growable: true);
        final originalDurationMs = originalDurations[segmentIndex];
        final firstDurationMs = math.max(
          16,
          (originalDurationMs / 2).round(),
        );
        final secondDurationMs = math.max(
          16,
          originalDurationMs - firstDurationMs,
        );
        final insertIndex = segmentIndex + 1;
        route.points.insert(
          insertIndex,
          Offset.lerp(
            route.points[segmentIndex],
            route.points[insertIndex],
            0.5,
          )!,
        );
        originalDurations.replaceRange(
          segmentIndex,
          segmentIndex + 1,
          <int>[firstDurationMs, secondDurationMs],
        );
        route.segmentDurationsMs
          ..clear()
          ..addAll(originalDurations);
        pointIndex = insertIndex;
        _activeRouteHandleDrag = _RouteHandleDrag(
          routeId: drag.routeId,
          pointIndex: pointIndex,
          handleKey: drag.handleKey,
        );
      }
      if (pointIndex <= 0 || pointIndex >= route.points.length - 1) {
        return;
      }
      final current = route.points[pointIndex];
      final next = Offset(
        (current.dx + delta.dx / boardWidth).clamp(0.0, 1.0).toDouble(),
        (current.dy + delta.dy / boardHeight).clamp(0.0, 1.0).toDouble(),
      );
      route.points[pointIndex] = next;
      _trimRouteDurations(route);
    });
  }

  void _endRouteHandleDrag() {
    if (_activeRouteHandleDrag == null) return;
    setState(() {
      _activeRouteHandleDrag = null;
    });
    _scheduleAutoSave();
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
        _activeRouteHandleDrag = null;
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
        _activeRouteHandleDrag = null;
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
      _activeRouteHandleDrag = null;
      _routeReplaceMode = false;
    });
    _scheduleAutoSave();
    AppSoundEffects.playSketchMove();
  }

  bool _isPossessedCarryBallRoute(_BoardRoute route) {
    final actorItemId = route.actorItemId;
    return route.kind == _PathDrawMode.ball &&
        actorItemId != null &&
        route.targetItemId == actorItemId;
  }

  bool _isBallPickupRoute(_BoardRoute route) {
    final actorItemId = route.actorItemId;
    return route.kind == _PathDrawMode.ball &&
        actorItemId != null &&
        route.targetItemId == actorItemId &&
        route.points.length >= 2 &&
        _pathDistanceMeters(route.points) <= _minPlaybackSegmentDistanceMeters;
  }

  Set<String> _actionRouteIdsForDeletion(_BoardRoute route) {
    final routeIds = <String>{route.id};
    final stageIndex = _normalizedRouteStageIndex(route.stageIndex);
    String? playerId;
    if (route.kind == _PathDrawMode.player) {
      playerId = route.linkedItemId ?? route.actorItemId;
    } else if (_isPossessedCarryBallRoute(route)) {
      playerId = route.actorItemId;
    }
    if (playerId == null) return routeIds;

    for (final candidate in _currentPage.routes) {
      if (candidate.id == route.id ||
          _normalizedRouteStageIndex(candidate.stageIndex) != stageIndex) {
        continue;
      }
      if (route.kind == _PathDrawMode.player) {
        if (_isPossessedCarryBallRoute(candidate) &&
            candidate.actorItemId == playerId) {
          routeIds.add(candidate.id);
        }
      } else if (_isPossessedCarryBallRoute(route) &&
          candidate.kind == _PathDrawMode.player &&
          (candidate.linkedItemId == playerId ||
              candidate.actorItemId == playerId)) {
        routeIds.add(candidate.id);
      }
    }
    return routeIds;
  }

  void _removeIdleBallIfUnowned(String ballId) {
    final ball = _itemById(ballId);
    if (ball == null || ball.type != _BoardItemType.ball) return;
    final hasBallRoute = _currentPage.routes.any(
      (route) =>
          route.kind == _PathDrawMode.ball &&
          route.linkedItemId == ball.id &&
          route.points.length >= 2,
    );
    if (hasBallRoute || _currentBallOwner(ball) != null) return;
    _currentPage.items.removeWhere((item) => item.id == ball.id);
    _currentPage.routes.removeWhere((route) => route.linkedItemId == ball.id);
    if (_selectedItemId == ball.id) {
      _selectedItemId = null;
    }
  }

  void _deleteRouteById(String routeId) {
    final route = _firstWhereOrNull(
      _currentPage.routes,
      (entry) => entry.id == routeId,
    );
    if (route == null) return;
    final routeIds = _actionRouteIdsForDeletion(route);
    final linkedBallIds = _currentPage.routes
        .where(
          (entry) =>
              routeIds.contains(entry.id) &&
              entry.kind == _PathDrawMode.ball &&
              entry.linkedItemId != null,
        )
        .map((entry) => entry.linkedItemId!)
        .toSet();
    final wasPlaying = _playbackTracks.any(
      (track) => routeIds.contains(track.route.id),
    );
    if (wasPlaying) {
      _stopRoutePlayback(restoreStart: false);
    }
    setState(() {
      _currentPage.routes.removeWhere((entry) => routeIds.contains(entry.id));
      _refreshTargetedPassRouteEndpoints();
      if (_selectedRouteId != null && routeIds.contains(_selectedRouteId)) {
        _selectedRouteId = null;
      }
      for (final ballId in linkedBallIds) {
        _removeIdleBallIfUnowned(ballId);
      }
      _routeReplaceMode = false;
      _activeRoutePoints = null;
      _activeRouteSegmentDurationsMs = null;
      _activeRouteLastPointAt = null;
      _activeRouteHandleDrag = null;
      _clearPendingTargetActionState();
    });
    _scheduleAutoSave();
  }

  int _normalizedRouteStageIndex(int value) {
    return value.clamp(1, _maxRouteStageIndex).toInt();
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

  bool _playerParticipatesInRoute(_BoardItem player, _BoardRoute route) {
    if (route.points.length < 2) return false;
    if (route.kind == _PathDrawMode.player) {
      return route.linkedItemId == player.id || route.actorItemId == player.id;
    }
    return route.actorItemId == player.id ||
        route.targetItemId == player.id ||
        _ballRouteGivesPlayerPossession(route, player);
  }

  int? _stageAfterSelectedRouteForPlayer(_BoardItem player) {
    final route = _selectedRoute;
    if (route == null || !_playerParticipatesInRoute(player, route)) {
      return null;
    }
    return _normalizedRouteStageIndex(route.stageIndex + 1);
  }

  int? _latestStageForPlayer(_BoardItem player) {
    int? latestStage;
    for (final route in _currentPage.routes) {
      if (!_playerParticipatesInRoute(player, route)) continue;
      final stage = _normalizedRouteStageIndex(route.stageIndex);
      latestStage = latestStage == null ? stage : math.max(latestStage, stage);
    }
    return latestStage;
  }

  int _nextStageForPlayerFlow(_BoardItem player) {
    final latestStage = _latestStageForPlayer(player);
    if (latestStage == null) return 1;
    return _normalizedRouteStageIndex(latestStage + 1);
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

  List<_BoardRoute> _actionTimelineRoutes() {
    final routeOrder = <String, int>{
      for (var index = 0; index < _currentPage.routes.length; index++)
        _currentPage.routes[index].id: index,
    };
    return _currentPage.routes
        .where((route) => route.points.length >= 2)
        .toList()
      ..sort((a, b) {
        final stageCompare = _normalizedRouteStageIndex(
          a.stageIndex,
        ).compareTo(_normalizedRouteStageIndex(b.stageIndex));
        if (stageCompare != 0) return stageCompare;
        return (routeOrder[a.id] ?? 0).compareTo(routeOrder[b.id] ?? 0);
      });
  }

  List<bool> _actionTimelineConcurrentFlags(List<_BoardRoute> routes) {
    return <bool>[
      for (var index = 0; index < routes.length; index++)
        index > 0 &&
            _normalizedRouteStageIndex(routes[index].stageIndex) ==
                _normalizedRouteStageIndex(routes[index - 1].stageIndex),
    ];
  }

  void _applyActionTimelineOrder(
    List<_BoardRoute> routes,
    List<bool> concurrentWithPrevious,
  ) {
    if (routes.length != concurrentWithPrevious.length) return;
    var stageIndex = 1;
    final stageByRouteId = <String, int>{};
    for (var index = 0; index < routes.length; index++) {
      if (index > 0 && !concurrentWithPrevious[index]) {
        stageIndex++;
      }
      stageByRouteId[routes[index].id] = stageIndex;
    }
    var timelineIndex = 0;
    for (var index = 0; index < _currentPage.routes.length; index++) {
      if (_currentPage.routes[index].points.length < 2) continue;
      final route = routes[timelineIndex++];
      route.stageIndex = stageByRouteId[route.id] ?? 1;
      _currentPage.routes[index] = route;
    }
    _refreshTargetedPassRouteEndpoints();
    final selectedRouteId = _selectedRouteId;
    _registeredNextActionStageIndex =
        selectedRouteId == null ? null : stageByRouteId[selectedRouteId];
  }

  void _reorderActionTimeline(int oldIndex, int newIndex) {
    if (widget.readOnly ||
        _playController.isAnimating ||
        _pendingTargetAction != null) {
      return;
    }
    final routes = _actionTimelineRoutes();
    if (oldIndex < 0 ||
        oldIndex >= routes.length ||
        newIndex < 0 ||
        newIndex > routes.length) {
      return;
    }
    if (newIndex > oldIndex) newIndex -= 1;
    if (oldIndex == newIndex) return;
    final concurrentWithPrevious = _actionTimelineConcurrentFlags(routes);
    final moved = routes.removeAt(oldIndex);
    concurrentWithPrevious.removeAt(oldIndex);
    if (oldIndex < concurrentWithPrevious.length) {
      concurrentWithPrevious[oldIndex] = false;
    }
    routes.insert(newIndex, moved);
    concurrentWithPrevious.insert(newIndex, false);
    if (newIndex + 1 < concurrentWithPrevious.length) {
      concurrentWithPrevious[newIndex + 1] = false;
    }

    _stopRoutePlayback(restoreStart: false);
    setState(() {
      _applyActionTimelineOrder(routes, concurrentWithPrevious);
    });
    unawaited(HapticFeedback.selectionClick());
    _scheduleAutoSave();
  }

  void _toggleActionTimelineConcurrency(String routeId) {
    if (widget.readOnly ||
        _playController.isAnimating ||
        _pendingTargetAction != null) {
      return;
    }
    final routes = _actionTimelineRoutes();
    final index = routes.indexWhere((route) => route.id == routeId);
    if (index <= 0) return;
    final concurrentWithPrevious = _actionTimelineConcurrentFlags(routes);
    concurrentWithPrevious[index] = !concurrentWithPrevious[index];
    _stopRoutePlayback(restoreStart: false);
    setState(() {
      _applyActionTimelineOrder(routes, concurrentWithPrevious);
    });
    unawaited(HapticFeedback.selectionClick());
    _scheduleAutoSave();
  }

  ScrollController _stagePlannerScrollController() {
    final size = MediaQuery.sizeOf(context);
    return size.width > size.height
        ? _landscapeControlsScrollController
        : _portraitInspectorScrollController;
  }

  void _startReorderAutoScroll() {
    _reorderAutoScrollController = _stagePlannerScrollController();
    if (!_reorderPointerRouteAttached) {
      WidgetsBinding.instance.pointerRouter.addGlobalRoute(
        _handleReorderPointerEvent,
      );
      _reorderPointerRouteAttached = true;
    }
    _reorderAutoScrollTimer ??= Timer.periodic(
      const Duration(milliseconds: 16),
      (_) {
        final controller = _reorderAutoScrollController;
        if (controller == null ||
            !controller.hasClients ||
            _reorderAutoScrollVelocity == 0) {
          return;
        }
        final position = controller.position;
        final target = (position.pixels + _reorderAutoScrollVelocity)
            .clamp(position.minScrollExtent, position.maxScrollExtent)
            .toDouble();
        if ((target - position.pixels).abs() > 0.1) {
          controller.jumpTo(target);
        }
      },
    );
  }

  void _handleReorderPointerEvent(PointerEvent event) {
    if (event is PointerUpEvent || event is PointerCancelEvent) {
      _stopReorderAutoScroll();
      return;
    }
    if (event is! PointerMoveEvent) return;
    final height = MediaQuery.sizeOf(context).height;
    const edgeExtent = 92.0;
    final distanceFromTop = event.position.dy;
    final distanceFromBottom = height - event.position.dy;
    if (distanceFromTop < edgeExtent) {
      _reorderAutoScrollVelocity =
          -((edgeExtent - distanceFromTop) / edgeExtent * 18)
              .clamp(4.0, 18.0)
              .toDouble();
    } else if (distanceFromBottom < edgeExtent) {
      _reorderAutoScrollVelocity =
          ((edgeExtent - distanceFromBottom) / edgeExtent * 18)
              .clamp(4.0, 18.0)
              .toDouble();
    } else {
      _reorderAutoScrollVelocity = 0;
    }
  }

  void _stopReorderAutoScroll() {
    _reorderAutoScrollTimer?.cancel();
    _reorderAutoScrollTimer = null;
    _reorderAutoScrollController = null;
    _reorderAutoScrollVelocity = 0;
    if (_reorderPointerRouteAttached) {
      WidgetsBinding.instance.pointerRouter.removeGlobalRoute(
        _handleReorderPointerEvent,
      );
      _reorderPointerRouteAttached = false;
    }
  }

  int? _registeredStageForNextAction() {
    final registered = _registeredNextActionStageIndex;
    return registered == null ? null : _normalizedRouteStageIndex(registered);
  }

  int _nextGlobalStageForNewAction() {
    final summaries = _globalStageSummaries();
    if (summaries.isEmpty) return 1;
    return _normalizedRouteStageIndex(summaries.last.stageIndex + 1);
  }

  int? _stageForNextPlayerAction(_BoardItem player) {
    final registered = _registeredStageForNextAction();
    if (registered != null) return registered;
    final selectedRouteStage = _stageAfterSelectedRouteForPlayer(player);
    if (selectedRouteStage != null) return selectedRouteStage;
    final possessionStage = _stageAfterCurrentBallPossession(player);
    if (possessionStage != null) return possessionStage;
    return _nextStageForPlayerFlow(player);
  }

  int? _kickRouteStageForImmediateMove(_BoardItem player) {
    final route = _selectedRoute;
    if (route != null &&
        route.kind == _PathDrawMode.ball &&
        route.actorItemId == player.id &&
        route.points.length >= 2) {
      return _normalizedRouteStageIndex(route.stageIndex);
    }
    final summaries = _globalStageSummaries();
    if (summaries.isEmpty) return null;
    final lastStage = summaries.last.stageIndex;
    final playerKickRoutes = _currentPage.routes
        .where(
          (entry) =>
              entry.kind == _PathDrawMode.ball &&
              entry.actorItemId == player.id &&
              entry.points.length >= 2,
        )
        .toList(growable: false);
    if (playerKickRoutes.isEmpty) return null;
    playerKickRoutes.sort((a, b) {
      final stageCompare = _normalizedRouteStageIndex(
        a.stageIndex,
      ).compareTo(_normalizedRouteStageIndex(b.stageIndex));
      if (stageCompare != 0) return stageCompare;
      return _currentPage.routes.indexOf(a).compareTo(
            _currentPage.routes.indexOf(b),
          );
    });
    final latestStage = _normalizedRouteStageIndex(
      playerKickRoutes.last.stageIndex,
    );
    return latestStage == lastStage ? latestStage : null;
  }

  int _stageForPlayerMoveAction(
    _BoardItem player,
    _BoardRoute? existingRoute,
  ) {
    final selectedRoute = _selectedRoute;
    final selectedBallRouteStage = selectedRoute?.kind == _PathDrawMode.ball
        ? _stageAfterSelectedRouteForPlayer(player)
        : null;
    return _registeredStageForNextAction() ??
        _kickRouteStageForImmediateMove(player) ??
        selectedBallRouteStage ??
        _stageAfterCurrentBallPossession(player) ??
        existingRoute?.stageIndex ??
        _nextStageForPlayerFlow(player);
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
      stageIndex: 1,
    );
    return segments.fold<int>(
      0,
      (sum, segment) => sum + (segment.durationSeconds * 1000).round(),
    );
  }

  Future<void> _setSketchOrientationLock({required bool landscape}) async {
    await SystemChrome.setPreferredOrientations(
      landscape
          ? const <DeviceOrientation>[
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ]
          : const <DeviceOrientation>[
              DeviceOrientation.portraitUp,
              DeviceOrientation.portraitDown,
            ],
    );
    await setTrainingSketchBrowserOrientation(landscape: landscape);
  }

  Future<void> _clearSketchOrientationLock() async {
    await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    await setTrainingSketchBrowserOrientation(landscape: false);
  }

  void _clearAllRoutes() {
    _stopRoutePlayback(restoreStart: false);
    setState(() {
      _currentPage.routes.clear();
      _selectedRouteId = null;
      _activeRoutePoints = null;
      _activeRouteSegmentDurationsMs = null;
      _activeRouteLastPointAt = null;
      _activeRouteHandleDrag = null;
      _routeReplaceMode = false;
      _clearPendingTargetActionState();
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
    if (item.type != _BoardItemType.player) return;
    const kind = _PathDrawMode.player;
    setState(() {
      _selectedItemId = item.id;
      _selectedRouteId = _routeForItem(item.id, kind)?.id;
      _showSelectedColorPicker = false;
      _pathDrawMode = kind;
      _pathMode = true;
      _penMode = false;
      _clearPendingTargetActionState();
      _routeReplaceMode = false;
      _activeStroke = null;
      _activeRoutePoints = null;
      _activeRouteSegmentDurationsMs = null;
      _activeRouteLastPointAt = null;
      _activeRouteHandleDrag = null;
    });
  }

  void _beginTargetAction(_SketchTargetAction action) {
    final selected = _selectedItem;
    if (selected == null) return;
    final player = _playerForTargetAction(selected);
    if (_requiresPlayerTargetAction(action) && player == null) {
      return;
    }
    if (_requiresReceiverTargetAction(action) &&
        (player == null || _passTargetPlayersFor(player).isEmpty)) {
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
      _pendingMoveThenPassPoint = null;
      _refreshPendingTargetGuidePoint();
      _showSelectedColorPicker = false;
      _pathMode = false;
      _penMode = false;
      _routeReplaceMode = false;
      _activeStroke = null;
      _activeRoutePoints = null;
      _activeRouteSegmentDurationsMs = null;
      _activeRouteLastPointAt = null;
      _activeRouteHandleDrag = null;
    });
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

  bool _applyPendingTargetActionToItem({
    required _SketchTargetAction action,
    required _BoardItem target,
  }) {
    return _applyPendingTargetActionToPoint(
      action: action,
      target: _itemActionPoint(target),
      targetItem: target,
    );
  }

  bool _applyPendingTargetActionToPoint({
    required _SketchTargetAction action,
    required Offset target,
    _BoardItem? targetItem,
  }) {
    final selected = _selectedItem;
    if (selected == null) return false;
    if (action == _SketchTargetAction.moveThenPass &&
        _pendingMoveThenPassPoint == null) {
      setState(() {
        _pendingMoveThenPassPoint = target;
        _pendingTargetGuidePoint = null;
      });
      unawaited(HapticFeedback.selectionClick());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_l10n.trainingSketchMoveThenPassReceiverPrompt),
        ),
      );
      return false;
    }
    final snapshot = _captureActionUndoSnapshot();
    final applied = switch (action) {
      _SketchTargetAction.move => _applyMoveTargetAction(selected, target),
      _SketchTargetAction.moveToBall => _applyMoveToBallAction(selected),
      _SketchTargetAction.pass => _applyPassTargetAction(
          selected,
          target,
          targetItem: targetItem,
        ),
      _SketchTargetAction.passAndMove => _applyPassAndMoveToPlayerTargetAction(
          selected,
          target,
          targetItem: targetItem,
        ),
      _SketchTargetAction.moveThenPass =>
        _applyMoveThenPassToPlayerTargetAction(
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
      _SketchTargetAction.shot => _applyShotTargetAction(
          selected,
          target,
          targetItem: targetItem,
        ),
      _SketchTargetAction.cross => _applyCrossTargetAction(
          selected,
          target,
          targetItem: targetItem,
        ),
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
          targetItem: targetItem,
        ),
      _SketchTargetAction.serve => _applyServeTargetAction(
          selected,
          target,
          targetItem: targetItem,
        ),
      _SketchTargetAction.rally => _applyRallyTargetAction(
          selected,
          target,
          targetItem: targetItem,
        ),
      _SketchTargetAction.recover => _applyMoveTargetAction(
          selected,
          target,
          durationMs: 640,
          carryPossessedBall: false,
        ),
    };
    if (!applied) return false;
    _showActionCreatedFeedback(snapshot);
    return true;
  }

  void _selectQuickActionRoute(
    _BoardRoute route,
    _BoardItem item, {
    _BoardItem? selectedItemOverride,
  }) {
    _selectedItemId = selectedItemOverride?.id ??
        _selectableItemIdForRoute(route) ??
        (item.type == _BoardItemType.ball ? null : item.id);
    _selectedRouteId = route.id;
    _registeredNextActionStageIndex = null;
    _showSelectedColorPicker = false;
    _pathDrawMode = route.kind;
    _pathMode = false;
    _penMode = false;
    _clearPendingTargetActionState();
    _routeReplaceMode = false;
    _activeStroke = null;
    _activeRoutePoints = null;
    _activeRouteSegmentDurationsMs = null;
    _activeRouteLastPointAt = null;
    _activeRouteHandleDrag = null;
    AppSoundEffects.playSketchMove();
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

  bool _shouldCreateNewPlayerStageRoute(
    _BoardRoute? existingRoute,
    int stageIndex,
  ) {
    if (existingRoute == null) return false;
    return _normalizedRouteStageIndex(existingRoute.stageIndex) !=
        _normalizedRouteStageIndex(stageIndex);
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

  int _stageForMoveToBallAction(
    _BoardItem player,
    _BoardItem ball,
    _BoardRoute? existingRoute,
  ) {
    final registered = _registeredStageForNextAction();
    if (registered != null) return registered;
    final playerStage = _stageForPlayerMoveAction(player, existingRoute);
    final latestBallRoute = _latestBallRouteForBall(ball);
    final ballStage = latestBallRoute == null
        ? playerStage
        : _normalizedRouteStageIndex(latestBallRoute.stageIndex + 1);
    return _normalizedRouteStageIndex(math.max(playerStage, ballStage));
  }

  bool _applyMoveToBallAction(_BoardItem selected) {
    final player = _playerForTargetAction(selected);
    if (player == null) return false;
    final ball = _nearestUnownedBallNearPlayer(player);
    if (ball == null) return false;
    _stopRoutePlayback(restoreStart: false);
    setState(() {
      final existingRoute = _playerRouteForChainedAction(player);
      final basePoints = _playerActionBasePoints(player, existingRoute);
      final start = basePoints.last;
      final ballPoint = _currentBallPoint(ball);
      final actionPoints = <Offset>[start, ballPoint];
      final stageIndex = _stageForMoveToBallAction(
        player,
        ball,
        existingRoute,
      );
      final createNewStageRoute = _shouldCreateNewPlayerStageRoute(
        existingRoute,
        stageIndex,
      );
      _upsertRouteForItem(
        kind: _PathDrawMode.ball,
        item: ball,
        points: <Offset>[ballPoint, ballPoint],
        segmentDurationsMs: const <int>[80],
        stageIndex: stageIndex,
        actorItemId: player.id,
        targetItemId: player.id,
        createNewRoute: true,
      );
      final route = _upsertRouteForItem(
        kind: _PathDrawMode.player,
        item: player,
        points: createNewStageRoute
            ? actionPoints
            : <Offset>[...basePoints, ballPoint],
        segmentDurationsMs: createNewStageRoute
            ? const <int>[620]
            : <int>[
                ..._playerActionBaseDurations(existingRoute),
                620,
              ],
        stageIndex: stageIndex,
        actorItemId: player.id,
        replacementRoute: createNewStageRoute ? null : existingRoute,
        createNewRoute: createNewStageRoute,
      );
      _selectQuickActionRoute(route, player);
    });
    _scheduleAutoSave();
    return true;
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
    bool retainActorPossessionWhenUntargeted = true,
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
      targetItemId: targetItem?.id ??
          (retainActorPossessionWhenUntargeted ? player.id : null),
      createNewRoute: true,
    );
  }

  _BoardItem? _resolvePlayerPassTarget(
    _BoardItem selected,
    Offset target,
    _BoardItem? targetItem,
  ) {
    if (targetItem?.type == _BoardItemType.player &&
        targetItem?.id != selected.id) {
      return targetItem;
    }
    final nearest = _nearestPlayerActionPointToPoint(target, radius: 0.075);
    if (nearest == null || nearest.id == selected.id) return null;
    return nearest;
  }

  bool _applyPassTargetAction(
    _BoardItem selected,
    Offset target, {
    _BoardItem? targetItem,
  }) {
    final receiver = _resolvePlayerPassTarget(selected, target, targetItem);
    if (receiver == null) return false;
    return _applyBallTargetAction(
      selected: selected,
      target: _itemActionPoint(receiver),
      targetItem: receiver,
      durationMs: 680,
    );
  }

  bool _applyPassAndMoveToPlayerTargetAction(
    _BoardItem selected,
    Offset target, {
    _BoardItem? targetItem,
  }) {
    final receiver = _resolvePlayerPassTarget(selected, target, targetItem);
    if (receiver == null) return false;
    return _applyPassAndMoveTargetAction(
      selected,
      _itemActionPoint(receiver),
      targetItem: receiver,
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
    _stopRoutePlayback(restoreStart: false);
    setState(() {
      final kickStage = _stageForNextPlayerAction(player) ??
          (existingRoute == null
              ? 1
              : _normalizedRouteStageIndex(existingRoute.stageIndex + 1));
      final passRoute = _upsertRouteForItem(
        kind: _PathDrawMode.ball,
        item: ball,
        points: <Offset>[resolvedBallStart, passEnd],
        segmentDurationsMs: const <int>[680],
        stageIndex: kickStage,
        actorItemId: player.id,
        targetItemId: targetItem?.id,
        createNewRoute: true,
      );
      _selectQuickActionRoute(passRoute, ball, selectedItemOverride: player);
      _pendingTargetAction = _SketchTargetAction.move;
      _refreshPendingTargetGuidePoint();
    });
    _scheduleAutoSave();
    return true;
  }

  bool _applyMoveThenPassToPlayerTargetAction(
    _BoardItem selected,
    Offset target, {
    _BoardItem? targetItem,
  }) {
    final receiver = _resolvePlayerPassTarget(selected, target, targetItem);
    final moveTarget = _pendingMoveThenPassPoint;
    final player = _playerForTargetAction(selected);
    if (receiver == null || moveTarget == null || player == null) {
      return false;
    }
    final existingRoute = _playerRouteForChainedAction(player);
    final basePoints = _playerActionBasePoints(player, existingRoute);
    final start = basePoints.last;
    final passTarget = _itemActionPoint(receiver);
    final carryStart = existingRoute == null
        ? null
        : _ballCarryPointFromOrigin(start, toward: moveTarget);
    final possession = _ballPossessionForNextPlayerAction(
      player,
      target: passTarget,
      startOverride: carryStart,
    );
    if (possession == null) return false;

    _stopRoutePlayback(restoreStart: false);
    setState(() {
      final moveStage = _stageForPlayerMoveAction(player, existingRoute);
      final createNewStageRoute = _shouldCreateNewPlayerStageRoute(
        existingRoute,
        moveStage,
      );
      _upsertRouteForItem(
        kind: _PathDrawMode.player,
        item: player,
        points: createNewStageRoute
            ? <Offset>[start, moveTarget]
            : <Offset>[...basePoints, moveTarget],
        segmentDurationsMs: createNewStageRoute
            ? const <int>[720]
            : <int>[..._playerActionBaseDurations(existingRoute), 720],
        stageIndex: moveStage,
        actorItemId: player.id,
        replacementRoute: createNewStageRoute ? null : existingRoute,
        createNewRoute: createNewStageRoute,
      );
      final passStart = _ballCarryPointFromOrigin(
        moveTarget,
        toward: passTarget,
      );
      _upsertRouteForItem(
        kind: _PathDrawMode.ball,
        item: possession.ball,
        points: <Offset>[possession.start, passStart],
        segmentDurationsMs: const <int>[720],
        stageIndex: moveStage,
        actorItemId: player.id,
        targetItemId: player.id,
        createNewRoute: true,
      );
      final passRoute = _upsertRouteForItem(
        kind: _PathDrawMode.ball,
        item: possession.ball,
        points: <Offset>[passStart, passTarget],
        segmentDurationsMs: const <int>[680],
        stageIndex: _normalizedRouteStageIndex(moveStage + 1),
        actorItemId: player.id,
        targetItemId: receiver.id,
        createNewRoute: true,
      );
      _selectQuickActionRoute(
        passRoute,
        possession.ball,
        selectedItemOverride: player,
      );
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
    final playerMiddle = _midTargetPoint(
      playerStart,
      target,
      yOffset: curveYOffset,
    );
    final actionPoints = <Offset>[playerStart, playerMiddle, target];
    final projectedBallStart = _projectedCarryPoint(
      actionPoints,
      0,
      fallbackTarget: target,
    );
    final ballStart = existingRoute == null
        ? (_stageAfterSelectedRoute() == null ? null : projectedBallStart)
        : projectedBallStart;
    final possession = _ballPossessionForNextPlayerAction(
      player,
      target: target,
      startOverride: ballStart,
    );
    if (possession == null) return false;
    final ball = possession.ball;
    final resolvedBallStart = possession.start;
    final possessionRoute = _latestBallRouteForBall(ball);
    final ballPoints = <Offset>[
      resolvedBallStart,
      for (var i = 1; i < actionPoints.length; i++)
        _projectedCarryPoint(
          actionPoints,
          i,
          fallbackTarget: target,
        ),
    ];
    final pairedStage = _pairedCarryStageFor(player: player, ball: ball);
    final continueUnownedPossessionRoute = possessionRoute != null &&
        possessionRoute.actorItemId == null &&
        possessionRoute.targetItemId == null;
    final stageIndex = _registeredStageForNextAction() ??
        (continueUnownedPossessionRoute
            ? pairedStage
            : _stageForNextPlayerAction(player) ?? pairedStage);
    final createNewStageRoute = _shouldCreateNewPlayerStageRoute(
      existingRoute,
      stageIndex,
    );
    _stopRoutePlayback(restoreStart: false);
    setState(() {
      _upsertRouteForItem(
        kind: _PathDrawMode.ball,
        item: ball,
        points: ballPoints,
        segmentDurationsMs: segmentDurationsMs,
        stageIndex: stageIndex,
        actorItemId: player.id,
        createNewRoute: true,
      );
      final playerRoute = _upsertRouteForItem(
        kind: _PathDrawMode.player,
        item: player,
        points: createNewStageRoute
            ? actionPoints
            : <Offset>[...basePoints, ...actionPoints.skip(1)],
        segmentDurationsMs: createNewStageRoute
            ? segmentDurationsMs
            : <int>[
                ..._playerActionBaseDurations(existingRoute),
                ...segmentDurationsMs,
              ],
        stageIndex: stageIndex,
        actorItemId: player.id,
        replacementRoute: createNewStageRoute ? null : existingRoute,
        createNewRoute: createNewStageRoute,
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

  bool _applyShotTargetAction(
    _BoardItem selected,
    Offset target, {
    _BoardItem? targetItem,
  }) {
    return _applyBallTargetAction(
      selected: selected,
      target: target,
      durationMs: 620,
      targetItem: targetItem,
      retainActorPossessionWhenUntargeted: false,
    );
  }

  bool _applyCrossTargetAction(
    _BoardItem selected,
    Offset target, {
    _BoardItem? targetItem,
  }) {
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
      targetItemId: targetItem?.id,
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
      final stageIndex = _stageForPlayerMoveAction(player, existingRoute);
      final createNewStageRoute = _shouldCreateNewPlayerStageRoute(
        existingRoute,
        stageIndex,
      );
      _upsertPossessedBallCarryRoute(
        player: player,
        actionPoints: actionPoints,
        segmentDurationsMs: actionDurations,
        stageIndex: stageIndex,
      );
      final route = _upsertRouteForItem(
        kind: _PathDrawMode.player,
        item: player,
        points: createNewStageRoute
            ? actionPoints
            : <Offset>[...basePoints, ...actionPoints.skip(1)],
        segmentDurationsMs: createNewStageRoute
            ? actionDurations
            : <int>[
                ..._playerActionBaseDurations(existingRoute),
                ...actionDurations,
              ],
        stageIndex: stageIndex,
        actorItemId: player.id,
        targetItemId: cone.id,
        replacementRoute: createNewStageRoute ? null : existingRoute,
        createNewRoute: createNewStageRoute,
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
      final stageIndex = _stageForPlayerMoveAction(player, existingRoute);
      final createNewStageRoute = _shouldCreateNewPlayerStageRoute(
        existingRoute,
        stageIndex,
      );
      _upsertPossessedBallCarryRoute(
        player: player,
        actionPoints: actionPoints,
        segmentDurationsMs: actionDurations,
        stageIndex: stageIndex,
      );
      final route = _upsertRouteForItem(
        kind: _PathDrawMode.player,
        item: player,
        points: createNewStageRoute
            ? actionPoints
            : <Offset>[...basePoints, ...actionPoints.skip(1)],
        segmentDurationsMs: createNewStageRoute
            ? actionDurations
            : <int>[
                ..._playerActionBaseDurations(existingRoute),
                ...actionDurations,
              ],
        stageIndex: stageIndex,
        actorItemId: player.id,
        targetItemId: obstacle.id,
        replacementRoute: createNewStageRoute ? null : existingRoute,
        createNewRoute: createNewStageRoute,
      );
      _selectQuickActionRoute(route, player);
    });
    _scheduleAutoSave();
    return true;
  }

  bool _applyServeTargetAction(
    _BoardItem selected,
    Offset target, {
    _BoardItem? targetItem,
  }) {
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
      targetItemId: targetItem?.id,
      createNewRoute: true,
    );
  }

  bool _applyRallyTargetAction(
    _BoardItem selected,
    Offset target, {
    _BoardItem? targetItem,
  }) {
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
      targetItemId: targetItem?.id,
      createNewRoute: true,
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
    if (actorItemId == null) return false;
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
      final stageIndex = _stageForPlayerMoveAction(player, existingRoute);
      final createNewStageRoute = _shouldCreateNewPlayerStageRoute(
        existingRoute,
        stageIndex,
      );
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
        points: createNewStageRoute
            ? actionPoints
            : <Offset>[...basePoints, ...actionPoints.skip(1)],
        segmentDurationsMs: createNewStageRoute
            ? actionDurations
            : <int>[
                ..._playerActionBaseDurations(existingRoute),
                ...actionDurations,
              ],
        stageIndex: stageIndex,
        actorItemId: player.id,
        replacementRoute: createNewStageRoute ? null : existingRoute,
        createNewRoute: createNewStageRoute,
      );
      _selectQuickActionRoute(route, player);
    });
    _scheduleAutoSave();
    return true;
  }

  bool _routePointListsEqual(List<Offset> a, List<Offset> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if ((a[i] - b[i]).distance > 0.0001) return false;
    }
    return true;
  }

  bool _intListsEqual(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  _BoardRoute _copyRouteForPreview(
    _BoardRoute route, {
    List<Offset>? points,
    List<int>? segmentDurationsMs,
  }) {
    return _BoardRoute(
      id: route.id,
      kind: route.kind,
      linkedItemId: route.linkedItemId,
      actorItemId: route.actorItemId,
      targetItemId: route.targetItemId,
      points: List<Offset>.from(points ?? route.points),
      segmentDurationsMs: List<int>.from(
        segmentDurationsMs ?? route.segmentDurationsMs,
      ),
      stageIndex: route.stageIndex,
      color: route.color,
      width: route.width,
    );
  }

  bool _routePrefixMatches(_BoardRoute before, _BoardRoute after) {
    if (after.points.length <= before.points.length) return false;
    for (var i = 0; i < before.points.length; i++) {
      if ((before.points[i] - after.points[i]).distance > 0.0001) {
        return false;
      }
    }
    return true;
  }

  bool _routeChangedForActionPreview(_BoardRoute before, _BoardRoute after) {
    return before.kind != after.kind ||
        before.linkedItemId != after.linkedItemId ||
        before.actorItemId != after.actorItemId ||
        before.targetItemId != after.targetItemId ||
        _normalizedRouteStageIndex(before.stageIndex) !=
            _normalizedRouteStageIndex(after.stageIndex) ||
        !_routePointListsEqual(before.points, after.points) ||
        !_intListsEqual(before.segmentDurationsMs, after.segmentDurationsMs);
  }

  _BoardRoute? _previewRouteForChangedRoute(
    _BoardRoute before,
    _BoardRoute after,
  ) {
    if (!_routeChangedForActionPreview(before, after)) return null;
    if (_routePrefixMatches(before, after) && before.points.isNotEmpty) {
      final startIndex = before.points.length - 1;
      final points = <Offset>[
        before.points.last,
        ...after.points.skip(before.points.length),
      ];
      final durations = _normalizedRouteSegmentDurations(
        pointCount: after.points.length,
        rawDurationsMs: after.segmentDurationsMs,
      ).skip(startIndex).toList(growable: false);
      if (points.length >= 2) {
        return _copyRouteForPreview(
          after,
          points: points,
          segmentDurationsMs: durations,
        );
      }
    }
    return _copyRouteForPreview(after);
  }

  List<_BoardRoute> _createdActionPreviewRoutes(_BoardPageState beforePage) {
    final beforeRoutesById = <String, _BoardRoute>{
      for (final route in beforePage.routes) route.id: route,
    };
    final previewRoutes = <_BoardRoute>[];
    for (final route in _currentPage.routes) {
      if (route.points.length < 2) continue;
      final beforeRoute = beforeRoutesById[route.id];
      if (beforeRoute == null) {
        previewRoutes.add(_copyRouteForPreview(route));
        continue;
      }
      final changedRoute = _previewRouteForChangedRoute(beforeRoute, route);
      if (changedRoute != null && changedRoute.points.length >= 2) {
        previewRoutes.add(changedRoute);
      }
    }
    return previewRoutes;
  }

  List<_PlaybackTrack> _compressedActionPreviewTracks(
    List<_PlaybackTrack> tracks,
  ) {
    if (tracks.isEmpty) return tracks;
    final slowestTrackMs = tracks.fold<int>(
      0,
      (currentMax, track) =>
          math.max(currentMax, (track.durationSeconds * 1000).round()),
    );
    if (slowestTrackMs <= 0) return tracks;
    final targetMs = slowestTrackMs
        .clamp(
          _actionPreviewMinDuration.inMilliseconds,
          _actionPreviewMaxDuration.inMilliseconds,
        )
        .toInt();
    final scale = targetMs / slowestTrackMs;
    return tracks
        .map(
          (track) => _PlaybackTrack(
            item: track.item,
            route: track.route,
            startPosition: track.startPosition,
            segments: track.segments
                .map(
                  (segment) => _PlaybackSegment(
                    start: segment.start,
                    end: segment.end,
                    durationSeconds: math.max(
                      segment.durationSeconds * scale,
                      0.016,
                    ),
                    stageIndex: segment.stageIndex,
                    visible: segment.visible,
                  ),
                )
                .toList(growable: false),
          ),
        )
        .toList(growable: false);
  }

  Duration _durationForActionPreviewTracks(List<_PlaybackTrack> tracks) {
    if (tracks.isEmpty) return _actionPreviewMinDuration;
    final slowestTrackMs = tracks.fold<int>(
      0,
      (currentMax, track) =>
          math.max(currentMax, (track.durationSeconds * 1000).round()),
    );
    return Duration(
      milliseconds: slowestTrackMs
          .clamp(
            _actionPreviewMinDuration.inMilliseconds,
            _actionPreviewMaxDuration.inMilliseconds,
          )
          .toInt(),
    );
  }

  void _startCreatedActionPreview(_SketchUndoSnapshot snapshot) {
    final previewRoutes = _createdActionPreviewRoutes(snapshot.page);
    if (previewRoutes.isEmpty) return;
    final tracks = _compressedActionPreviewTracks(
      _resolvePlaybackTracks(sourceRoutes: previewRoutes),
    );
    if (tracks.isEmpty) return;
    _stopRoutePlayback(restoreStart: true);
    setState(() {
      _isActionPreviewPlayback = true;
      _playbackTracks = tracks;
      _playbackActiveStageIndex = _activeStageForPlaybackElapsed(tracks, 0);
      _hiddenPlaybackItemIds = _hiddenPlaybackItemIdsForPlaybackElapsed(
        tracks,
        0,
      );
      for (final track in _playbackTracks) {
        final firstPoint = track.segments.first.start;
        track.item.x = firstPoint.dx.clamp(0.03, 0.97);
        track.item.y = firstPoint.dy.clamp(0.03, 0.97);
      }
    });
    _playController.duration = _durationForActionPreviewTracks(tracks);
    _playController
      ..stop()
      ..reset();
    _playController.forward(from: 0.0);
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
    if (_routeReplaceMode) {
      return _l10n.trainingSketchRouteReplaceHint;
    }
    final routeableCount = _routeableItemCount(_pathDrawMode);
    if (routeableCount == 0) {
      return _pathDrawMode == _PathDrawMode.player
          ? _l10n.trainingSketchAddPlayerFirst
          : _l10n.trainingSketchAddBallFirst;
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
      _isActionPreviewPlayback = false;
      _playbackTracks = tracks;
      _playbackActiveStageIndex = _activeStageForPlaybackElapsed(tracks, 0);
      _hiddenPlaybackItemIds = _hiddenPlaybackItemIdsForPlaybackElapsed(
        tracks,
        0,
      );
      for (final track in _playbackTracks) {
        final firstPoint = track.segments.first.start;
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
    setState(
      () => _applyPlaybackFrame(_playbackTracks, routeElapsedSeconds),
    );
  }

  void _applyPlaybackFrame(
    List<_PlaybackTrack> tracks,
    double routeElapsedSeconds,
  ) {
    _playbackActiveStageIndex = _activeStageForPlaybackElapsed(
      tracks,
      routeElapsedSeconds,
    );
    _hiddenPlaybackItemIds = _hiddenPlaybackItemIdsForPlaybackElapsed(
      tracks,
      routeElapsedSeconds,
    );
    for (final track in tracks) {
      if (track.segments.isEmpty) continue;
      final position = _samplePlaybackTrack(track, routeElapsedSeconds);
      track.item.x = position.dx.clamp(0.03, 0.97);
      track.item.y = position.dy.clamp(0.03, 0.97);
    }
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
      _isActionPreviewPlayback = false;
      _hiddenPlaybackItemIds = <String>{};
      _playbackActiveStageIndex = null;
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
      _isActionPreviewPlayback = false;
      _hiddenPlaybackItemIds = <String>{};
      _playbackActiveStageIndex = null;
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

  _PlaybackSegment? _segmentForPlaybackElapsed(
    _PlaybackTrack track,
    double elapsedSeconds,
  ) {
    if (track.segments.isEmpty) return null;
    if (elapsedSeconds > track.durationSeconds) return null;
    final adjustedElapsedSeconds = _acceleratedPlaybackElapsedSeconds(
      elapsedSeconds: elapsedSeconds,
      durationSeconds: track.durationSeconds,
      kind: track.route.kind,
    );
    final target = adjustedElapsedSeconds.clamp(0.0, 1000000.0).toDouble();
    var walkedSeconds = 0.0;
    for (final segment in track.segments) {
      final next = walkedSeconds + segment.durationSeconds;
      if (next >= target) {
        return segment;
      }
      walkedSeconds = next;
    }
    return track.segments.last;
  }

  int? _activeStageForPlaybackElapsed(
    List<_PlaybackTrack> tracks,
    double elapsedSeconds,
  ) {
    int? activeStage;
    for (final track in tracks) {
      final stage = _segmentForPlaybackElapsed(
        track,
        elapsedSeconds,
      )?.stageIndex;
      if (stage == null) continue;
      activeStage =
          activeStage == null ? stage : math.min(activeStage, stage).toInt();
    }
    return activeStage;
  }

  Set<String> _hiddenPlaybackItemIdsForPlaybackElapsed(
    List<_PlaybackTrack> tracks,
    double elapsedSeconds,
  ) {
    final hiddenItemIds = <String>{};
    for (final track in tracks) {
      final segment = _segmentForPlaybackElapsed(track, elapsedSeconds);
      if (segment != null && !segment.visible) {
        hiddenItemIds.add(track.item.id);
      }
    }
    return hiddenItemIds;
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
    required int stageIndex,
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
          stageIndex: stageIndex,
        ),
      );
    }
    if (segments.isEmpty) {
      return <_PlaybackSegment>[
        _PlaybackSegment(
          start: points.first,
          end: points.last,
          durationSeconds: totalDistanceMeters / speedMetersPerSecond,
          stageIndex: stageIndex,
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
    _actionUndoTimer?.cancel();
    _stopReorderAutoScroll();
    unawaited(_speech.cancel());
    unawaited(_clearSketchOrientationLock());
    _playController
      ..removeListener(_onPlayTick)
      ..removeStatusListener(_onPlayStatusChanged)
      ..dispose();
    _methodController.dispose();
    _landscapeControlsScrollController.dispose();
    _portraitInspectorScrollController.dispose();
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
          child: Stack(
            children: [
              Positioned.fill(
                child: isLandscape
                    ? _buildLandscapeBody(isKo)
                    : _buildPortraitBody(isKo),
              ),
              if (!widget.readOnly) _buildActionUndoOverlay(),
            ],
          ),
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
    final showSelectedFirst = _selectedItem?.type == _BoardItemType.player ||
        _pendingTargetAction != null;
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
        controller: _landscapeControlsScrollController,
        children: showSelectedFirst
            ? [
                _buildSelectedTools(isKo),
                const SizedBox(height: 12),
                _buildToolButtons(isKo),
              ]
            : [
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
      child: SingleChildScrollView(
        controller: _portraitInspectorScrollController,
        child: _buildSelectedTools(isKo),
      ),
    );
  }

  List<Widget> _buildSelectedRouteHandles(double width, double height) {
    if (widget.readOnly ||
        _playController.isAnimating ||
        _videoExportInProgress ||
        _pathMode ||
        _penMode ||
        _pendingTargetAction != null ||
        _activeRoutePoints != null) {
      return const <Widget>[];
    }
    final route = _selectedRoute;
    if (route == null || route.points.length < 2) return const <Widget>[];
    final handles = <Widget>[];
    for (var index = 1; index < route.points.length - 1; index++) {
      final defaultKey =
          ValueKey('training-route-point-handle-${route.id}-$index');
      final activeDrag = _activeRouteHandleDrag;
      final handleKey = activeDrag != null &&
              activeDrag.routeId == route.id &&
              activeDrag.pointIndex == index
          ? activeDrag.handleKey
          : defaultKey;
      handles.add(
        _buildRouteHandle(
          key: handleKey,
          point: route.points[index],
          width: width,
          height: height,
          color: route.color,
          filled: true,
          onPanStart: () => _startRoutePointHandleDrag(
            route,
            index,
            handleKey: handleKey,
          ),
        ),
      );
    }
    final activeDrag = _activeRouteHandleDrag;
    for (var index = 0; index < route.points.length - 1; index++) {
      final handleKey =
          ValueKey('training-route-segment-handle-${route.id}-$index');
      // After a segment drag inserts its midpoint, keep the original pointer
      // listener on that new point instead of rebuilding a duplicate key.
      if (activeDrag != null &&
          activeDrag.routeId == route.id &&
          activeDrag.pointIndex != null &&
          activeDrag.handleKey == handleKey) {
        continue;
      }
      handles.add(
        _buildRouteHandle(
          key: handleKey,
          point:
              Offset.lerp(route.points[index], route.points[index + 1], 0.5)!,
          width: width,
          height: height,
          color: route.color,
          filled: false,
          onPanStart: () => _startRouteSegmentHandleDrag(
            route,
            index,
            handleKey: handleKey,
          ),
        ),
      );
    }
    return handles;
  }

  Widget _buildRouteHandle({
    required Key key,
    required Offset point,
    required double width,
    required double height,
    required Color color,
    required bool filled,
    required VoidCallback onPanStart,
  }) {
    const handleSize = 30.0;
    return Positioned(
      left: (point.dx * width) - handleSize / 2,
      top: (point.dy * height) - handleSize / 2,
      child: Listener(
        key: key,
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => onPanStart(),
        onPointerMove: (event) => _updateRouteHandleDragByDelta(
          event.delta,
          boardWidth: width,
          boardHeight: height,
        ),
        onPointerUp: (_) => _endRouteHandleDrag(),
        onPointerCancel: (_) => _endRouteHandleDrag(),
        child: SizedBox(
          width: handleSize,
          height: handleSize,
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled
                    ? color.withValues(alpha: 0.94)
                    : Colors.white.withValues(alpha: 0.92),
                border: Border.all(
                  color: filled
                      ? Colors.white.withValues(alpha: 0.96)
                      : color.withValues(alpha: 0.96),
                  width: filled ? 2.2 : 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SizedBox(
                width: filled ? 16 : 13,
                height: filled ? 16 : 13,
              ),
            ),
          ),
        ),
      ),
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
                  : (details) {
                      if (_pathMode || _pendingTargetAction != null) {
                        _handleBoardTap(
                          details.localPosition,
                          width,
                          height,
                        );
                      } else {
                        _handleBoardSelectionTap(
                          details.localPosition,
                          width,
                          height,
                        );
                      }
                    },
              onTapDown: widget.readOnly || _pendingTargetAction == null
                  ? null
                  : (details) => _updatePendingTargetGuidePoint(
                        details.localPosition,
                        width,
                        height,
                      ),
              child: MouseRegion(
                onHover: widget.readOnly || _pendingTargetAction == null
                    ? null
                    : (event) => _updatePendingTargetGuidePoint(
                          event.localPosition,
                          width,
                          height,
                        ),
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
                        routes: _playController.isAnimating ||
                                _videoExportInProgress
                            ? const <_BoardRoute>[]
                            : _currentPage.routes,
                        selectedRouteId: _selectedRouteId,
                        activeRoutePoints: _activeRoutePoints,
                        activeRouteColor: _activeRoutePreviewColor(),
                        activeRouteKind: _pathDrawMode,
                      ),
                    ),
                    if (_pendingTargetGuideStartPoint() != null &&
                        _pendingTargetGuidePoint != null)
                      CustomPaint(
                        key: const ValueKey(
                          'training-action-destination-guide',
                        ),
                        size: Size(width, height),
                        painter: _TargetActionGuidePainter(
                          start: _pendingTargetGuideStartPoint()!,
                          target: _pendingTargetGuidePoint!,
                          color: Theme.of(context).colorScheme.secondary,
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
                      ignoring:
                          _playController.isAnimating || _videoExportInProgress,
                      child: Stack(
                        children: [
                          for (final item in _boardItemsInPaintOrder())
                            if (!_hiddenPlaybackItemIds.contains(item.id))
                              Positioned(
                                left:
                                    (_boardItemDisplayPoint(item).dx * width) -
                                        26,
                                top:
                                    (_boardItemDisplayPoint(item).dy * height) -
                                        26,
                                child: IgnorePointer(
                                  ignoring: item.type == _BoardItemType.ball,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: item.type == _BoardItemType.ball
                                        ? null
                                        : () => _handleBoardItemTap(item),
                                    onPanStart: widget.readOnly ||
                                            item.type == _BoardItemType.ball
                                        ? null
                                        : (_) => _startItemMove(item),
                                    onPanUpdate: widget.readOnly ||
                                            item.type == _BoardItemType.ball
                                        ? null
                                        : (details) => _updateItemMoveByDelta(
                                              item,
                                              delta: details.delta,
                                              boardWidth: width,
                                              boardHeight: height,
                                            ),
                                    onPanEnd: widget.readOnly ||
                                            item.type == _BoardItemType.ball
                                        ? null
                                        : (_) => _endItemMove(),
                                    onPanCancel: widget.readOnly ||
                                            item.type == _BoardItemType.ball
                                        ? null
                                        : _endItemMove,
                                    onLongPressStart: widget.readOnly ||
                                            item.type == _BoardItemType.ball
                                        ? null
                                        : (_) => _startLongPressItemMove(item),
                                    onLongPressMoveUpdate: widget.readOnly ||
                                            item.type == _BoardItemType.ball
                                        ? null
                                        : (details) => _updateLongPressItemMove(
                                              item,
                                              offsetFromOrigin:
                                                  details.offsetFromOrigin,
                                              boardWidth: width,
                                              boardHeight: height,
                                            ),
                                    onLongPressEnd: widget.readOnly ||
                                            item.type == _BoardItemType.ball
                                        ? null
                                        : (_) => _endItemMove(),
                                    onLongPressCancel: widget.readOnly ||
                                            item.type == _BoardItemType.ball
                                        ? null
                                        : _endItemMove,
                                    child: SizedBox(
                                      width: 52,
                                      height: 52,
                                      child: Center(
                                        child: _BoardToken(
                                          key: _isHighlightedTargetItem(item)
                                              ? ValueKey(
                                                  'training-action-target-valid-${item.id}',
                                                )
                                              : null,
                                          item: item,
                                          selected: item.id == _selectedItemId,
                                          highlighted:
                                              _isHighlightedTargetItem(item),
                                          moving: item.id == _movingItemId,
                                          label: _boardTokenLabelFor(item),
                                          sportId: _currentSportIdOrDefault,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ..._buildSelectedRouteHandles(width, height),
                        ],
                      ),
                    ),
                    if (_isActionPreviewPlayback)
                      const SizedBox(
                        key: ValueKey('training-action-preview-active'),
                      ),
                  ],
                ),
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
        key: const ValueKey('training-sketch-video-button'),
        onPressed: _videoExportInProgress ||
                _playController.isAnimating ||
                _pendingTargetAction != null
            ? null
            : _exportCurrentSketchVideo,
        icon: Icons.movie_creation_outlined,
        tooltip: _l10n.trainingSketchVideoExportTooltip,
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
          unawaited(_setSketchOrientationLock(landscape: !isLandscape));
        },
        icon: isLandscape
            ? Icons.stay_current_portrait_outlined
            : Icons.stay_current_landscape_outlined,
        tooltip: isLandscape
            ? _l10n.trainingSketchPortraitModeTooltip
            : _l10n.trainingSketchLandscapeModeTooltip,
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
          _activeRouteHandleDrag = null;
          _routeReplaceMode = false;
          _clearPendingTargetActionState();
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
            _activeRouteHandleDrag = null;
            _selectedItemId = null;
            _selectedRouteId = null;
            _showSelectedColorPicker = false;
            _routeReplaceMode = false;
            _clearPendingTargetActionState();
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
      _SketchTargetAction.moveToBall =>
        l10n.trainingSketchQuickMoveToBallButton,
      _SketchTargetAction.pass => l10n.trainingSketchQuickPassButton,
      _SketchTargetAction.passAndMove =>
        l10n.trainingSketchQuickPassAndMoveButton,
      _SketchTargetAction.moveThenPass => l10n.trainingSketchMoveThenPassButton,
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

  Widget _buildPlayerFlowStarter(_BoardItem player) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final hasBall = _playerHasBallForFlow(player);
    final entries = _playerFlowActionEntries(player);
    final nextStage = _stageForNextPlayerAction(player) ?? 1;
    return Container(
      key: ValueKey('training-player-next-action-${player.id}'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
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
              _buildSelectedColorButton(player),
              if (!widget.readOnly)
                Tooltip(
                  message: _l10n.delete,
                  child: Semantics(
                    button: true,
                    label: _l10n.delete,
                    child: Material(
                      color: Colors.transparent,
                      shape: const CircleBorder(),
                      child: InkWell(
                        key: const ValueKey(
                          'training-selected-item-delete-button',
                        ),
                        customBorder: const CircleBorder(),
                        onTap: _removeSelected,
                        child: SizedBox(
                          width: 36,
                          height: 36,
                          child: Icon(
                            Icons.delete_outline,
                            color: colors.error,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              Chip(
                visualDensity: VisualDensity.compact,
                label: Text(
                  _l10n.trainingSketchPlayerFlowNextStageChip(nextStage),
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
          if (_showSelectedColorPicker) ...[
            const SizedBox(height: 8),
            _buildSelectedColorPicker(
              player,
              _colorChoicesForItemType(player.type),
            ),
          ],
          if (entries.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in entries)
                  _playerFlowEntryButton(player: player, entry: entry),
              ],
            ),
          ],
        ],
      ),
    );
  }

  List<_PlayerFlowActionEntry> _playerFlowActionEntries(_BoardItem player) {
    final canUseBallActions = _canUsePlayerFlowBallActions(player);
    final sportId = _currentSportIdOrDefault;
    final targetPlayers = _passTargetPlayersFor(player);
    final ballActions = canUseBallActions
        ? _playerFlowBallActions(sportId)
            .where(
              (action) => _canUsePlayerFlowBallAction(
                action,
                hasPlayerPassTarget: targetPlayers.isNotEmpty,
              ),
            )
            .toList(growable: false)
        : const <_SketchTargetAction>[];
    final movementActions = _playerFlowMovementActions(sportId)
        .where(
          (action) =>
              _canUsePlayerFlowMovementAction(player, action) &&
              _hasPlayerFlowActionTarget(action),
        )
        .toList(growable: false);
    final propActions = _playerFlowPropActions(movementActions);
    return <_PlayerFlowActionEntry>[
      for (final action in ballActions) _PlayerFlowActionEntry.action(action),
      for (final action in movementActions)
        _PlayerFlowActionEntry.action(action),
      for (final propAction in propActions)
        _PlayerFlowActionEntry.target(propAction.action, propAction.target),
    ];
  }

  bool _hasPlayerFlowActionTarget(_SketchTargetAction action) {
    final targetType = _requiredBoardItemTargetTypeForAction(action);
    return targetType == null || _itemsOfType(targetType).isNotEmpty;
  }

  List<_PlayerFlowPropAction> _playerFlowPropActions(
    List<_SketchTargetAction> movementActions,
  ) {
    final enabledActions = movementActions.toSet();
    final actions = <_PlayerFlowPropAction>[];
    final cones = _itemsOfType(_BoardItemType.cone);
    final hurdles = _itemsOfType(_BoardItemType.hurdle);
    if (enabledActions.contains(_SketchTargetAction.coneTurn)) {
      for (final cone in cones) {
        actions.add(_PlayerFlowPropAction(_SketchTargetAction.coneTurn, cone));
      }
    }
    if (enabledActions.contains(_SketchTargetAction.coneJump)) {
      for (final cone in cones) {
        actions.add(_PlayerFlowPropAction(_SketchTargetAction.coneJump, cone));
      }
    }
    if (enabledActions.contains(_SketchTargetAction.hurdleJump)) {
      for (final hurdle in hurdles) {
        actions.add(
          _PlayerFlowPropAction(_SketchTargetAction.hurdleJump, hurdle),
        );
      }
    }
    return actions;
  }

  String _playerFlowPropActionLabel(
    _SketchTargetAction action,
    _BoardItem target,
  ) {
    final index = _itemIndexOfType(target);
    return switch (action) {
      _SketchTargetAction.coneTurn =>
        _l10n.trainingSketchConeTurnTargetButton(index),
      _SketchTargetAction.coneJump =>
        _l10n.trainingSketchConeJumpTargetButton(index),
      _SketchTargetAction.hurdleJump =>
        _l10n.trainingSketchHurdleJumpTargetButton(index),
      _ => _targetActionLabel(action),
    };
  }

  Widget _playerFlowEntryButton({
    required _BoardItem player,
    required _PlayerFlowActionEntry entry,
  }) {
    final key = entry.target == null
        ? ValueKey('training-player-flow-action-${player.id}-'
            '${entry.action.name}')
        : ValueKey('training-player-flow-prop-action-${player.id}-'
            '${entry.action.name}-${entry.target!.id}');
    final label = entry.target == null
        ? _targetActionLabel(entry.action)
        : _playerFlowPropActionLabel(entry.action, entry.target!);
    final icon = Icon(_targetActionIcon(entry.action), size: 18);
    void handlePressed() => _handlePlayerFlowActionEntry(player, entry);
    return OutlinedButton.icon(
      key: key,
      onPressed: handlePressed,
      icon: icon,
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(44, 44),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  bool _isImmediatePlayerFlowAction(_SketchTargetAction action) {
    return action == _SketchTargetAction.moveToBall;
  }

  void _preparePlayerForFlowAction(_BoardItem player) {
    setState(() {
      _selectedItemId = player.id;
      _selectedRouteId = null;
      _showSelectedColorPicker = false;
      _pathMode = false;
      _penMode = false;
      _routeReplaceMode = false;
      _activeStroke = null;
      _activeRoutePoints = null;
      _activeRouteSegmentDurationsMs = null;
      _activeRouteLastPointAt = null;
      _activeRouteHandleDrag = null;
    });
  }

  void _handlePlayerFlowActionEntry(
    _BoardItem player,
    _PlayerFlowActionEntry entry,
  ) {
    if (widget.readOnly) return;
    _preparePlayerForFlowAction(player);
    final target = entry.target;
    if (target != null) {
      _applyPendingTargetActionToItem(action: entry.action, target: target);
      return;
    }
    if (_isImmediatePlayerFlowAction(entry.action)) {
      final snapshot = _captureActionUndoSnapshot();
      final applied = _applyMoveToBallAction(player);
      if (applied) {
        _showActionCreatedFeedback(snapshot);
      }
      return;
    }
    _beginTargetAction(entry.action);
  }

  IconData _targetActionIcon(_SketchTargetAction action) {
    return switch (action) {
      _SketchTargetAction.move => Icons.directions_run,
      _SketchTargetAction.moveToBall => Icons.sports_soccer_outlined,
      _SketchTargetAction.pass => Icons.near_me_outlined,
      _SketchTargetAction.passAndMove => Icons.sync_alt,
      _SketchTargetAction.moveThenPass => Icons.turn_slight_right_outlined,
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
      SportCatalog.baseballId => <_SketchTargetAction>[
          _SketchTargetAction.throwBall,
        ],
      SportCatalog.basketballId => <_SketchTargetAction>[
          _SketchTargetAction.pass,
          _SketchTargetAction.drive,
          _SketchTargetAction.shot,
        ],
      SportCatalog.tennisId => <_SketchTargetAction>[
          _SketchTargetAction.serve,
          _SketchTargetAction.rally,
        ],
      _ => <_SketchTargetAction>[
          _SketchTargetAction.pass,
          _SketchTargetAction.passAndMove,
          _SketchTargetAction.moveThenPass,
          _SketchTargetAction.dribble,
          _SketchTargetAction.shot,
          _SketchTargetAction.cross,
        ],
    };
  }

  bool _canUsePlayerFlowBallAction(
    _SketchTargetAction action, {
    required bool hasPlayerPassTarget,
  }) {
    return switch (action) {
      _SketchTargetAction.pass ||
      _SketchTargetAction.passAndMove ||
      _SketchTargetAction.moveThenPass =>
        hasPlayerPassTarget,
      _ => true,
    };
  }

  List<_SketchTargetAction> _playerFlowMovementActions(String sportId) {
    return switch (sportId) {
      SportCatalog.baseballId => <_SketchTargetAction>[
          _SketchTargetAction.move,
          _SketchTargetAction.moveToBall,
          _SketchTargetAction.runBase,
          _SketchTargetAction.fielding,
          _SketchTargetAction.coneTurn,
          _SketchTargetAction.coneJump,
        ],
      SportCatalog.basketballId => <_SketchTargetAction>[
          _SketchTargetAction.move,
          _SketchTargetAction.moveToBall,
          _SketchTargetAction.cut,
          _SketchTargetAction.screen,
          _SketchTargetAction.coneTurn,
          _SketchTargetAction.coneJump,
        ],
      SportCatalog.tennisId => <_SketchTargetAction>[
          _SketchTargetAction.move,
          _SketchTargetAction.moveToBall,
          _SketchTargetAction.recover,
          _SketchTargetAction.coneTurn,
          _SketchTargetAction.coneJump,
        ],
      _ => <_SketchTargetAction>[
          _SketchTargetAction.move,
          _SketchTargetAction.moveToBall,
          _SketchTargetAction.receiveMove,
          _SketchTargetAction.returnMove,
          _SketchTargetAction.overlap,
          _SketchTargetAction.coneTurn,
          _SketchTargetAction.coneJump,
          _SketchTargetAction.hurdleJump,
        ],
    };
  }

  Widget _buildSelectedTools(bool isKo) {
    if (!widget.readOnly &&
        !_penMode &&
        !_pathMode &&
        _pendingTargetAction == null &&
        _selectedItem != null &&
        _selectedItem?.type != _BoardItemType.player) {
      return const SizedBox.shrink();
    }
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

  Widget _buildActiveRouteControls() {
    final l10n = _l10n;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
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

  void _selectStageActionRoute(
    _BoardRoute route, {
    int? registeredStage,
  }) {
    setState(() {
      _selectedItemId = _selectableItemIdForRoute(route);
      _selectedRouteId = route.id;
      _registeredNextActionStageIndex =
          registeredStage ?? _normalizedRouteStageIndex(route.stageIndex);
      _pathDrawMode = route.kind;
      _showSelectedColorPicker = false;
      _pathMode = false;
      _penMode = false;
      _clearPendingTargetActionState();
      _routeReplaceMode = false;
      _activeStroke = null;
      _activeRoutePoints = null;
      _activeRouteSegmentDurationsMs = null;
      _activeRouteLastPointAt = null;
      _activeRouteHandleDrag = null;
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
      if (_isPlayerStayRoute(route)) {
        return _l10n.trainingSketchStageActionPlayerStay(
          _stageItemLabel(linkedItem ?? actorItem),
        );
      }
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
    if (_isBallPickupRoute(route) && actorItem != null) {
      return _l10n.trainingSketchStageActionBallPickup(
        _stageItemLabel(actorItem),
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

  bool _isPlayerStayRoute(_BoardRoute route) {
    if (route.kind != _PathDrawMode.player || route.points.length < 2) {
      return false;
    }
    final durations = _normalizedRouteSegmentDurations(
      pointCount: route.points.length,
      rawDurationsMs: route.segmentDurationsMs,
    );
    if (durations.isEmpty || durations.last < _stayActionDurationMs) {
      return false;
    }
    final lastIndex = route.points.length - 1;
    final lastDistance = _segmentDistanceMeters(
      route.points[lastIndex - 1],
      route.points[lastIndex],
    );
    return lastDistance <= _stayActionMaxDistanceMeters;
  }

  Widget _buildActionTimelineItem(
    _BoardRoute route, {
    required int index,
    required bool runsWithPrevious,
    required Color accentColor,
    required ThemeData theme,
    required bool compact,
    required bool canReorder,
  }) {
    final colors = theme.colorScheme;
    final isSelected = route.id == _selectedRouteId;
    final isPlaying = _playController.isAnimating &&
        _normalizedRouteStageIndex(route.stageIndex) ==
            _playbackActiveStageIndex;
    final isReordering = route.id == _reorderingActionRouteId;
    final isHighlighted = isSelected || isPlaying || isReordering;
    final simultaneousTooltip = runsWithPrevious
        ? _l10n.trainingSketchRunAfterPreviousTooltip
        : _l10n.trainingSketchRunWithPreviousTooltip;
    final timelineItem = Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('training-action-timeline-row-${route.id}'),
          onTap: () => _selectStageActionRoute(route),
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: EdgeInsets.fromLTRB(compact ? 2 : 6, 4, 0, 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: isReordering
                  ? colors.secondaryContainer.withValues(alpha: 0.82)
                  : isHighlighted
                      ? colors.primaryContainer.withValues(alpha: 0.56)
                      : Colors.transparent,
              border: Border.all(
                color: isReordering
                    ? colors.secondary.withValues(alpha: 0.96)
                    : isHighlighted
                        ? colors.primary.withValues(alpha: 0.72)
                        : Colors.transparent,
                width: isReordering ? 2 : 1,
              ),
              boxShadow: isReordering
                  ? <BoxShadow>[
                      BoxShadow(
                        color: colors.secondary.withValues(alpha: 0.30),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                if (canReorder)
                  Tooltip(
                    message: _l10n.trainingSketchReorderActionTooltip,
                    child: SizedBox(
                      key: ValueKey(
                        'training-action-timeline-reorder-handle-${route.id}',
                      ),
                      width: compact ? 24 : 30,
                      height: 32,
                      child: Icon(
                        Icons.drag_indicator,
                        size: 18,
                        color: isReordering
                            ? colors.secondary
                            : colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                Icon(
                  isSelected ? Icons.check_circle_outline : Icons.bolt_outlined,
                  size: 14,
                  color: isHighlighted ? colors.primary : accentColor,
                ),
                SizedBox(width: compact ? 3 : 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _stageRouteActionDescription(route),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w500,
                        ),
                        maxLines: compact ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isSelected)
                        SizedBox(
                          key: ValueKey(
                            'training-action-timeline-selected-${route.id}',
                          ),
                          width: 1,
                          height: 1,
                        ),
                      if (isPlaying)
                        SizedBox(
                          key: ValueKey(
                            'training-action-timeline-active-stage-'
                            '${_normalizedRouteStageIndex(route.stageIndex)}',
                          ),
                          width: 1,
                          height: 1,
                        ),
                    ],
                  ),
                ),
                if (index > 0)
                  Tooltip(
                    message: simultaneousTooltip,
                    child: Semantics(
                      button: true,
                      label: simultaneousTooltip,
                      child: Material(
                        color: Colors.transparent,
                        shape: const CircleBorder(),
                        child: InkWell(
                          key: ValueKey(
                            'training-action-timeline-concurrent-${route.id}',
                          ),
                          customBorder: const CircleBorder(),
                          onTap: widget.readOnly
                              ? null
                              : () =>
                                  _toggleActionTimelineConcurrency(route.id),
                          child: SizedBox(
                            width: compact ? 28 : 32,
                            height: 32,
                            child: Icon(
                              runsWithPrevious ? Icons.link : Icons.link_off,
                              size: 16,
                              color: runsWithPrevious
                                  ? colors.primary
                                  : colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                Tooltip(
                  message: _l10n.trainingSketchDeleteActionTooltip,
                  child: Semantics(
                    button: true,
                    enabled: !widget.readOnly,
                    label: _l10n.trainingSketchDeleteActionTooltip,
                    child: Material(
                      color: Colors.transparent,
                      shape: const CircleBorder(),
                      child: InkWell(
                        key: ValueKey(
                            'training-action-timeline-delete-${route.id}'),
                        customBorder: const CircleBorder(),
                        onTap: widget.readOnly
                            ? null
                            : () => _deleteRouteById(route.id),
                        child: SizedBox(
                          width: compact ? 28 : 32,
                          height: 32,
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: colors.error,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!canReorder) {
      return KeyedSubtree(
        key: ValueKey('training-action-timeline-item-${route.id}'),
        child: timelineItem,
      );
    }
    return ReorderableDelayedDragStartListener(
      key: ValueKey('training-action-timeline-item-${route.id}'),
      index: index,
      child: timelineItem,
    );
  }

  Widget _buildGlobalStagePlanner() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final size = MediaQuery.sizeOf(context);
    final compact = size.width > size.height;
    final routes = _actionTimelineRoutes();
    final concurrentWithPrevious = _actionTimelineConcurrentFlags(routes);
    final canReorder = !widget.readOnly &&
        routes.length > 1 &&
        !_playController.isAnimating &&
        _pendingTargetAction == null;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        compact ? 8 : 12,
        compact ? 6 : 10,
        compact ? 8 : 12,
        compact ? 6 : 10,
      ),
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
              Icon(Icons.view_timeline_outlined,
                  size: 18, color: colors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _l10n.trainingSketchActionTimelineTitle,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 4 : 8),
          if (routes.isEmpty)
            Text(
              _l10n.trainingSketchActionTimelineEmpty,
              style: theme.textTheme.bodySmall,
            )
          else if (canReorder)
            ReorderableListView(
              key: const ValueKey('training-action-timeline-reorderable-list'),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              onReorder: _reorderActionTimeline,
              onReorderStart: (index) {
                setState(() => _reorderingActionRouteId = routes[index].id);
                _startReorderAutoScroll();
              },
              onReorderEnd: (_) {
                _stopReorderAutoScroll();
                if (mounted) {
                  setState(() => _reorderingActionRouteId = null);
                }
              },
              proxyDecorator: (child, _, animation) {
                return AnimatedBuilder(
                  animation: animation,
                  child: child,
                  builder: (context, child) {
                    final progress = Curves.easeOutCubic.transform(
                      animation.value,
                    );
                    return Transform.scale(
                      scale: 1 + (progress * 0.035),
                      child: Container(
                        key: const ValueKey(
                          'training-action-timeline-drag-proxy',
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: colors.secondaryContainer,
                          border: Border.all(
                            color: colors.secondary,
                            width: 2,
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: colors.secondary.withValues(alpha: 0.34),
                              blurRadius: 18,
                              spreadRadius: 2,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: child,
                      ),
                    );
                  },
                );
              },
              children: [
                for (var index = 0; index < routes.length; index++)
                  _buildActionTimelineItem(
                    routes[index],
                    index: index,
                    runsWithPrevious: concurrentWithPrevious[index],
                    accentColor: colors.primary,
                    theme: theme,
                    compact: compact,
                    canReorder: true,
                  ),
              ],
            )
          else
            Column(
              children: [
                for (var index = 0; index < routes.length; index++)
                  _buildActionTimelineItem(
                    routes[index],
                    index: index,
                    runsWithPrevious: concurrentWithPrevious[index],
                    accentColor: colors.primary,
                    theme: theme,
                    compact: compact,
                    canReorder: false,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSelectedToolsContent(bool isKo) {
    final selected = _selectedItem;
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
      final accentColor = _routeGroupAccentColor(_pathDrawMode);
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
          const SizedBox(height: 6),
          if (routes.isEmpty)
            Text(
              l10n.trainingSketchRoutesEmpty,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          const SizedBox(height: 10),
          _buildActiveRouteControls(),
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
    if (selected.type == _BoardItemType.player) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPlayerFlowStarter(selected),
          const SizedBox(height: 10),
          _buildGlobalStagePlanner(),
        ],
      );
    }
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
              key: const ValueKey('training-selected-item-delete-button'),
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

class _SketchUndoSnapshot {
  final _BoardPageState page;
  final int nextId;
  final String? selectedItemId;
  final String? selectedRouteId;
  final int? registeredNextActionStageIndex;
  final _PathDrawMode pathDrawMode;
  final bool showSelectedColorPicker;

  const _SketchUndoSnapshot({
    required this.page,
    required this.nextId,
    required this.selectedItemId,
    required this.selectedRouteId,
    required this.registeredNextActionStageIndex,
    required this.pathDrawMode,
    required this.showSelectedColorPicker,
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

class _RouteHandleDrag {
  final String routeId;
  final int? pointIndex;
  final int? segmentIndex;
  final Key handleKey;

  const _RouteHandleDrag({
    required this.routeId,
    this.pointIndex,
    this.segmentIndex,
    required this.handleKey,
  });
}

class _PlaybackStageEnd {
  final int stageIndex;
  final int endMs;
  final Offset start;
  final Offset end;

  const _PlaybackStageEnd({
    required this.stageIndex,
    required this.endMs,
    required this.start,
    required this.end,
  });
}

class _PlaybackSegment {
  final Offset start;
  final Offset end;
  final double durationSeconds;
  final int? stageIndex;
  final bool visible;

  const _PlaybackSegment({
    required this.start,
    required this.end,
    required this.durationSeconds,
    this.stageIndex,
    this.visible = true,
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
  moveToBall,
  pass,
  passAndMove,
  moveThenPass,
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

class _PlayerFlowPropAction {
  final _SketchTargetAction action;
  final _BoardItem target;

  const _PlayerFlowPropAction(this.action, this.target);
}

class _PlayerFlowActionEntry {
  final _SketchTargetAction action;
  final _BoardItem? target;

  const _PlayerFlowActionEntry.action(this.action) : target = null;

  const _PlayerFlowActionEntry.target(this.action, this.target);
}

class _CapturedSketchVideoFrame {
  final int width;
  final int height;
  final Uint8List rgbaBytes;

  const _CapturedSketchVideoFrame({
    required this.width,
    required this.height,
    required this.rgbaBytes,
  });

  _CapturedSketchVideoFrame cropTo(int targetWidth, int targetHeight) {
    if (targetWidth <= 0 ||
        targetHeight <= 0 ||
        targetWidth > width ||
        targetHeight > height) {
      throw StateError('Training sketch video frame has an invalid crop.');
    }
    if (targetWidth == width && targetHeight == height) return this;
    final cropped = Uint8List(targetWidth * targetHeight * 4);
    for (var row = 0; row < targetHeight; row++) {
      final sourceOffset = row * width * 4;
      final targetOffset = row * targetWidth * 4;
      cropped.setRange(
        targetOffset,
        targetOffset + (targetWidth * 4),
        rgbaBytes,
        sourceOffset,
      );
    }
    return _CapturedSketchVideoFrame(
      width: targetWidth,
      height: targetHeight,
      rgbaBytes: cropped,
    );
  }
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
const double _playbackBallCarryPointRadius = 0.10;
const double _stayActionMaxDistanceMeters = 0.12;
const int _stayActionDurationMs = 900;
const double _ballPossessionRadius = 0.23;
const int _maxRouteStageIndex = 99;
const Duration _minPlaybackDuration = Duration(milliseconds: 900);
const Duration _actionPreviewMinDuration = Duration(milliseconds: 420);
const Duration _actionPreviewMaxDuration = Duration(milliseconds: 760);
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
  final bool highlighted;
  final bool moving;
  final String? label;
  final String sportId;

  const _BoardToken({
    super.key,
    required this.item,
    required this.selected,
    required this.highlighted,
    required this.moving,
    required this.label,
    required this.sportId,
  });

  @override
  Widget build(BuildContext context) {
    final icon = _boardItemIcon(item.type, sportId: sportId);
    final borderColor = highlighted
        ? const Color(0xFFFFF176)
        : selected
            ? Colors.white
            : Colors.white.withValues(alpha: 0.55);
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
        : highlighted
            ? const <BoxShadow>[
                BoxShadow(
                  color: Color(0xAAFFF176),
                  blurRadius: 14,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 8,
                  offset: Offset(0, 2),
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
    final token = Transform.rotate(
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
                  width: highlighted
                      ? 2.8
                      : selected
                          ? 2.2
                          : 1.2,
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
    );
    if (highlighted && !moving) {
      return TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          final pulse = math.sin(value * math.pi) * 0.08;
          return Transform.scale(scale: 1.08 + pulse, child: child);
        },
        child: token,
      );
    }
    return AnimatedScale(
      scale: moving
          ? 1.12
          : highlighted
              ? 1.08
              : 1.0,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: token,
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

class _TargetActionGuidePainter extends CustomPainter {
  final Offset start;
  final Offset target;
  final Color color;

  const _TargetActionGuidePainter({
    required this.start,
    required this.target,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scaledStart = Offset(start.dx * size.width, start.dy * size.height);
    final scaledTarget = Offset(
      target.dx * size.width,
      target.dy * size.height,
    );
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.54)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    _drawDashedLine(canvas, scaledStart, scaledTarget, linePaint);
    _drawGuideMarker(
      canvas,
      scaledStart,
      color: Colors.white.withValues(alpha: 0.92),
      radius: 7.0,
      filled: true,
    );
    _drawGuideMarker(
      canvas,
      scaledTarget,
      color: color,
      radius: 10.0,
      filled: false,
    );
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
  ) {
    final vector = end - start;
    final distance = vector.distance;
    if (distance <= 0.5) return;
    final direction = vector / distance;
    const dash = 10.0;
    const gap = 7.0;
    var drawn = 0.0;
    while (drawn < distance) {
      final segmentStart = start + direction * drawn;
      final segmentEnd = start + direction * math.min(drawn + dash, distance);
      canvas.drawLine(segmentStart, segmentEnd, paint);
      drawn += dash + gap;
    }
  }

  void _drawGuideMarker(
    Canvas canvas,
    Offset center, {
    required Color color,
    required double radius,
    required bool filled,
  }) {
    final outerPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius + 3, outerPaint);
    final markerPaint = Paint()
      ..color = filled ? color : color.withValues(alpha: 0.16)
      ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 2.8;
    canvas.drawCircle(center, radius, markerPaint);
  }

  @override
  bool shouldRepaint(covariant _TargetActionGuidePainter oldDelegate) {
    return oldDelegate.start != start ||
        oldDelegate.target != target ||
        oldDelegate.color != color;
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
