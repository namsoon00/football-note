import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../application/player_level_service.dart';
import '../../application/settings_service.dart';
import '../../application/training_board_service.dart';
import '../../application/training_plan_reminder_service.dart';
import '../../domain/entities/training_board.dart';
import '../../domain/repositories/option_repository.dart';
import '../models/training_method_layout.dart';

class TrainingMethodBoardScreen extends StatefulWidget {
  final String boardTitle;
  final String initialLayoutJson;
  final List<TrainingBoardPreset> presets;
  final ValueChanged<String>? onSaved;
  final OptionRepository? optionRepository;
  final List<String> initialSelectedBoardIds;
  final String? initialBoardId;

  const TrainingMethodBoardScreen({
    super.key,
    required this.boardTitle,
    required this.initialLayoutJson,
    this.presets = const <TrainingBoardPreset>[],
    this.onSaved,
    this.optionRepository,
    this.initialSelectedBoardIds = const <String>[],
    this.initialBoardId,
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
  bool _penMode = false;
  bool _pathMode = false;
  bool _routeReplaceMode = false;
  Color _penColor = const Color(0xFF000000);
  List<Offset>? _activeStroke;
  List<Offset>? _activeRoutePoints;
  late final AnimationController _playController;
  String? _playingItemId;
  Offset? _playingItemStart;
  String? _playingRouteId;
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

  bool get _isManagedMode => widget.optionRepository != null;
  _BoardPageState get _currentPage => _pages.first;
  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  bool get _hasUnsavedChanges => _serialize() != _lastSavedLayout;

  T? _firstWhereOrNull<T>(Iterable<T> items, bool Function(T) test) {
    for (final item in items) {
      if (test(item)) return item;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    if (_isManagedMode) {
      _managedBoardService = TrainingBoardService(widget.optionRepository!);
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
    if (_shouldPromptInitialBoardName) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _promptForInitialBoardName();
      });
    }
    if (_isManagedMode && _currentBoardId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _promptForManagedBoardCreation(isInitialFlow: true);
      });
    }
  }

  void _restoreStandaloneBoard() {
    final layout = TrainingMethodLayout.decode(widget.initialLayoutJson);
    final page = layout.pages.isEmpty ? null : layout.pages.first;
    final defaultBoardName = widget.boardTitle.trim().isEmpty
        ? 'Board 1'
        : widget.boardTitle.trim();
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
                points: route.points
                    .map((point) => Offset(point.x, point.y))
                    .toList(growable: true),
                color: Color(route.colorValue),
                width: route.width,
              ),
            )
            .toList(growable: true),
      ),
    ];
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
    final title = fallbackTitle.trim().isEmpty
        ? 'Board 1'
        : fallbackTitle.trim();
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
                points: route.points
                    .map((point) => Offset(point.x, point.y))
                    .toList(growable: true),
                color: Color(route.colorValue),
                width: route.width,
              ),
            )
            .toList(growable: true),
      ),
    ];
    _currentBoardId = board.id;
    _selectedItemId = null;
    _selectedRouteId = null;
    _penMode = false;
    _pathMode = false;
    _activeStroke = null;
    _activeRoutePoints = null;
    _routeReplaceMode = false;
    _playingItemId = null;
    _playingItemStart = null;
    _playingRouteId = null;
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
      builder: (context) => AlertDialog(
        title: Text(isKo ? titleKo : titleEn),
        content: TextFormField(
          initialValue: typedName,
          onChanged: (value) => typedName = value,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: isKo ? '보드명' : 'Board name',
            hintText: isKo ? '예) 패스 워밍업' : 'e.g. Pass warm-up',
            border: const OutlineInputBorder(),
          ),
          onFieldSubmitted: (value) => Navigator.of(context).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(isKo ? '취소' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(typedName.trim()),
            child: Text(isKo ? confirmKo : confirmEn),
          ),
        ],
      ),
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
    final created = await _managedBoardService!.createBoard(
      title: title,
      layoutJson: TrainingMethodLayout(
        pages: <TrainingMethodPage>[
          TrainingMethodPage(name: title, items: const <TrainingMethodItem>[]),
        ],
      ).encode(),
    );
    if (!mounted) return;
    setState(() {
      _managedBoards = _managedBoardService!.allBoards();
      _selectedBoardIds.add(created.id);
      _loadBoard(created);
    });
    final award = await PlayerLevelService(widget.optionRepository!)
        .awardForBoardSaved(
          boardId: created.id,
          boardTitle: created.title,
          savedAt: created.updatedAt,
          created: true,
        );
    await TrainingPlanReminderService(
      widget.optionRepository!,
      SettingsService(widget.optionRepository!)..load(),
    ).showXpGainAlert(
      gainedXp: award.gainedXp,
      totalXp: award.after.totalXp,
      isKo: isKo,
      sourceLabel: isKo ? '훈련 스케치' : 'Training sketch',
    );
    if (!mounted || award.gainedXp <= 0) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isKo
              ? '훈련 스케치를 만들었어요. +${award.gainedXp} XP'
              : 'Training sketch created. +${award.gainedXp} XP',
        ),
      ),
    );
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
                  points: route.points
                      .map(
                        (point) =>
                            TrainingMethodPoint(x: point.dx, y: point.dy),
                      )
                      .toList(growable: false),
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

  _BoardItem? get _playingItem {
    final id = _playingItemId;
    if (id == null) return null;
    return _firstWhereOrNull(_currentPage.items, (item) => item.id == id);
  }

  _BoardRoute? get _playingRoute {
    final id = _playingRouteId;
    if (id == null) return null;
    return _firstWhereOrNull(_currentPage.routes, (route) => route.id == id);
  }

  String _nextBoardItemId() => 'item-${_nextId++}';

  String _nextBoardRouteId() => 'route-${_nextId++}';

  List<_BoardRoute> _routesForKind(_PathDrawMode kind) {
    return _currentPage.routes
        .where((route) => route.kind == kind)
        .toList(growable: false);
  }

  _BoardRoute? _resolvePlaybackRoute() {
    final selectedRoute = _selectedRoute;
    if (selectedRoute != null) return selectedRoute;
    final sameKindRoutes = _routesForKind(_pathDrawMode);
    if (sameKindRoutes.isNotEmpty) return sameKindRoutes.last;
    if (_currentPage.routes.isNotEmpty) return _currentPage.routes.last;
    return null;
  }

  _BoardItemType _boardItemTypeForRouteKind(_PathDrawMode kind) {
    return switch (kind) {
      _PathDrawMode.player => _BoardItemType.player,
      _PathDrawMode.ball => _BoardItemType.ball,
    };
  }

  _BoardItem? _resolvePlaybackItemForRoute(_BoardRoute route) {
    final linkedId = route.linkedItemId;
    if (linkedId != null) {
      final linkedItem = _firstWhereOrNull(
        _currentPage.items,
        (item) => item.id == linkedId,
      );
      if (linkedItem != null) {
        return linkedItem;
      }
    }
    final expectedType = _boardItemTypeForRouteKind(route.kind);
    final selected = _selectedItem;
    if (selected != null && selected.type == expectedType) {
      return selected;
    }
    return _firstWhereOrNull(
      _currentPage.items,
      (item) => item.type == expectedType,
    );
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
      if (route.linkedItemId != item.id || route.points.isEmpty) continue;
      for (var i = 0; i < route.points.length; i++) {
        final point = route.points[i];
        route.points[i] = Offset(
          (point.dx + dx).clamp(0.0, 1.0).toDouble(),
          (point.dy + dy).clamp(0.0, 1.0).toDouble(),
        );
      }
    }
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
        color: _defaultColorFor(type),
      );
      _currentPage.items.add(item);
      _selectedItemId = item.id;
      _selectedRouteId = null;
      _penMode = false;
      _pathMode = false;
      _routeReplaceMode = false;
    });
  }

  void _removeSelected() {
    final id = _selectedItemId;
    if (id == null) return;
    setState(() {
      _currentPage.items.removeWhere((e) => e.id == id);
      final removedSelectedRoute = _selectedRouteId;
      _currentPage.routes.removeWhere((route) => route.linkedItemId == id);
      if (removedSelectedRoute != null &&
          !_currentPage.routes.any(
            (route) => route.id == removedSelectedRoute,
          )) {
        _selectedRouteId = null;
      }
      _selectedItemId = null;
    });
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

  Future<bool> _saveBoard(bool isKo, {bool showFeedback = true}) async {
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
      boardAward = await PlayerLevelService(
        widget.optionRepository!,
      ).awardForBoardSaved(boardId: updated.id, boardTitle: title);
      await TrainingPlanReminderService(
        widget.optionRepository!,
        SettingsService(widget.optionRepository!)..load(),
      ).showXpGainAlert(
        gainedXp: boardAward.gainedXp,
        totalXp: boardAward.after.totalXp,
        isKo: isKo,
        sourceLabel: isKo ? '훈련 스케치' : 'Training sketch',
      );
    } else {
      widget.onSaved?.call(serialized);
    }
    setState(() {
      _lastSavedLayout = serialized;
    });
    if (!mounted) return true;
    if (showFeedback) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isKo
                ? '훈련 스케치를 저장했습니다.${(boardAward?.gainedXp ?? 0) > 0 ? ' +${boardAward!.gainedXp} XP' : ''}'
                : 'Training sketch saved.${(boardAward?.gainedXp ?? 0) > 0 ? ' +${boardAward!.gainedXp} XP' : ''}',
          ),
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
          children: linkedBoards
              .map((board) {
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
              })
              .toList(growable: false),
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
              points: route.points
                  .map((point) => Offset(point.x, point.y))
                  .toList(growable: true),
              color: Color(route.colorValue),
              width: route.width,
            ),
          )
          .toList(growable: true),
    );

    setState(() {
      _pages[0] = copiedPage;
      _selectedItemId = null;
      _selectedRouteId = null;
      _penMode = false;
      _pathMode = false;
      _methodController.text = _currentPage.methodText;
      _activeRoutePoints = null;
      _routeReplaceMode = false;
    });

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
                      children: layout.pages
                          .asMap()
                          .entries
                          .map((entry) {
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
                          })
                          .toList(growable: false),
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
          children: copyCandidates
              .map((board) {
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
              })
              .toList(growable: false),
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
    final award = await PlayerLevelService(widget.optionRepository!)
        .awardForBoardSaved(
          boardId: created.id,
          boardTitle: created.title,
          savedAt: created.updatedAt,
          created: true,
        );
    await TrainingPlanReminderService(
      widget.optionRepository!,
      SettingsService(widget.optionRepository!)..load(),
    ).showXpGainAlert(
      gainedXp: award.gainedXp,
      totalXp: award.after.totalXp,
      isKo: isKo,
      sourceLabel: isKo ? '훈련 스케치' : 'Training sketch',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isKo
              ? '다른 스케치를 복사해 추가했습니다.${award.gainedXp > 0 ? ' +${award.gainedXp} XP' : ''}'
              : 'Sketch copied from another one.${award.gainedXp > 0 ? ' +${award.gainedXp} XP' : ''}',
        ),
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

  void _startStroke(Offset localPosition, double width, double height) {
    final x = (localPosition.dx / width).clamp(0.0, 1.0);
    final y = (localPosition.dy / height).clamp(0.0, 1.0);
    setState(() {
      _activeStroke = <Offset>[Offset(x, y)];
      _selectedItemId = null;
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
  }

  void _selectRoute(_BoardRoute route) {
    setState(() {
      _selectedRouteId = route.id;
      _pathDrawMode = route.kind;
      _routeReplaceMode = false;
      _pathMode = true;
      final linkedItemId = route.linkedItemId;
      if (linkedItemId != null &&
          _currentPage.items.any((item) => item.id == linkedItemId)) {
        _selectedItemId = linkedItemId;
      }
    });
  }

  void _startPlayerPath(Offset localPosition, double width, double height) {
    final x = (localPosition.dx / width).clamp(0.0, 1.0);
    final y = (localPosition.dy / height).clamp(0.0, 1.0);
    setState(() {
      _activeRoutePoints = <Offset>[Offset(x, y)];
    });
  }

  void _appendPlayerPath(Offset localPosition, double width, double height) {
    final points = _activeRoutePoints;
    if (points == null) return;
    final x = (localPosition.dx / width).clamp(0.0, 1.0);
    final y = (localPosition.dy / height).clamp(0.0, 1.0);
    setState(() {
      points.add(Offset(x, y));
    });
  }

  void _endPlayerPath() {
    final points = _activeRoutePoints;
    if (points == null || points.length < 2) {
      setState(() {
        _activeRoutePoints = null;
        _routeReplaceMode = false;
      });
      return;
    }
    setState(() {
      final selectedRoute = _selectedRoute;
      final linkedItemId =
          _selectedItem?.type == _boardItemTypeForRouteKind(_pathDrawMode)
          ? _selectedItem?.id
          : null;
      if (_routeReplaceMode &&
          selectedRoute != null &&
          selectedRoute.kind == _pathDrawMode) {
        selectedRoute.points
          ..clear()
          ..addAll(points);
        if (linkedItemId != null) {
          selectedRoute.linkedItemId = linkedItemId;
        }
        _selectedRouteId = selectedRoute.id;
      } else {
        final route = _BoardRoute(
          id: _nextBoardRouteId(),
          kind: _pathDrawMode,
          linkedItemId: linkedItemId,
          points: List<Offset>.from(points),
          color: _defaultRouteColor(_pathDrawMode),
          width: _defaultRouteWidth(_pathDrawMode),
        );
        _currentPage.routes.add(route);
        _selectedRouteId = route.id;
      }
      _activeRoutePoints = null;
      _routeReplaceMode = false;
    });
  }

  void _togglePlayerPathMode() {
    _stopRoutePlayback();
    setState(() {
      _pathMode = !_pathMode;
      if (_pathMode) {
        _penMode = false;
        final selectedRoute = _selectedRoute;
        if (selectedRoute != null) {
          _pathDrawMode = selectedRoute.kind;
        }
      }
      _activeStroke = null;
      _activeRoutePoints = null;
      _routeReplaceMode = false;
    });
  }

  void _prepareSelectedRouteRedraw() {
    final route = _selectedRoute;
    if (route == null || route.kind != _pathDrawMode) return;
    setState(() {
      _routeReplaceMode = true;
      _pathMode = true;
      _penMode = false;
      _activeRoutePoints = null;
      if (route.linkedItemId != null) {
        _selectedItemId = route.linkedItemId;
      }
    });
  }

  void _deleteSelectedRoute() {
    final route = _selectedRoute;
    if (route == null) return;
    final wasPlaying = _playingRouteId == route.id;
    if (wasPlaying) {
      _stopRoutePlayback(restoreStart: false);
    }
    setState(() {
      _currentPage.routes.removeWhere((entry) => entry.id == route.id);
      _selectedRouteId = null;
      _routeReplaceMode = false;
      _activeRoutePoints = null;
    });
  }

  void _clearAllRoutes() {
    _stopRoutePlayback(restoreStart: false);
    setState(() {
      _currentPage.routes.clear();
      _selectedRouteId = null;
      _activeRoutePoints = null;
      _routeReplaceMode = false;
    });
  }

  String _routeLabel(_PathDrawMode kind, int index) {
    return switch (kind) {
      _PathDrawMode.player => _l10n.trainingSketchPlayerRouteChip(index),
      _PathDrawMode.ball => _l10n.trainingSketchBallRouteChip(index),
    };
  }

  String _pathModeHint() {
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
    return _pathDrawMode == _PathDrawMode.player
        ? _l10n.trainingSketchPlayerRouteHint
        : _l10n.trainingSketchBallRouteHint;
  }

  void _playPlayerPath(bool isKo) {
    if (_playController.isAnimating) {
      _stopRoutePlayback();
      return;
    }
    final route = _resolvePlaybackRoute();
    if (route == null || route.points.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_l10n.trainingSketchDrawRouteFirst)),
      );
      return;
    }
    final item = _resolvePlaybackItemForRoute(route);
    if (item == null) {
      final message = route.kind == _PathDrawMode.player
          ? _l10n.trainingSketchAddPlayerFirst
          : _l10n.trainingSketchAddBallFirst;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }
    _stopRoutePlayback(restoreStart: false);
    setState(() {
      final firstPoint = route.points.first;
      _playingRouteId = route.id;
      _playingItemId = item.id;
      _playingItemStart = Offset(item.x, item.y);
      _selectedRouteId = route.id;
      _pathDrawMode = route.kind;
      item.x = firstPoint.dx.clamp(0.03, 0.97);
      item.y = firstPoint.dy.clamp(0.03, 0.97);
    });
    _playController.duration = Duration(
      milliseconds:
          (route.points.length * 40).clamp(1200, 7000) ~/
          _playSpeed.clamp(0.5, 2.0),
    );
    _playController
      ..stop()
      ..reset();
    _playController.forward(from: 0.0);
  }

  void _onPlayTick() {
    final item = _playingItem;
    final route = _playingRoute;
    setState(() {
      if (item != null && route != null && route.points.length >= 2) {
        final position = _samplePathPoint(route.points, _playController.value);
        item.x = position.dx.clamp(0.03, 0.97);
        item.y = position.dy.clamp(0.03, 0.97);
      }
    });
  }

  void _onPlayStatusChanged(AnimationStatus status) {
    if (status != AnimationStatus.completed &&
        status != AnimationStatus.dismissed) {
      return;
    }
    final item = _playingItem;
    final start = _playingItemStart;
    setState(() {
      if (item != null && start != null) {
        item.x = start.dx;
        item.y = start.dy;
      }
      _playingItemId = null;
      _playingItemStart = null;
      _playingRouteId = null;
    });
    if (status == AnimationStatus.completed) {
      _playController.reset();
    }
  }

  void _stopRoutePlayback({bool restoreStart = true}) {
    final item = _playingItem;
    final start = _playingItemStart;
    _playController.stop();
    _playController.reset();
    setState(() {
      if (restoreStart) {
        if (item != null && start != null) {
          item.x = start.dx;
          item.y = start.dy;
        }
      }
      _playingItemId = null;
      _playingItemStart = null;
      _playingRouteId = null;
    });
  }

  Future<void> _toggleMemoListening(bool isKo) async {
    final localeId = Localizations.localeOf(context).languageCode == 'ko'
        ? 'ko_KR'
        : null;
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
    final needsSpacing =
        !isKoreanLocale &&
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
  }

  Offset _samplePathPoint(List<Offset> points, double t) {
    if (points.isEmpty) return const Offset(0.5, 0.5);
    if (points.length == 1) return points.first;
    final lengths = <double>[];
    var total = 0.0;
    for (var i = 0; i < points.length - 1; i++) {
      final segment = (points[i + 1] - points[i]).distance;
      lengths.add(segment);
      total += segment;
    }
    if (total <= 0.0001) return points.last;
    final target = total * t.clamp(0.0, 1.0);
    var walked = 0.0;
    for (var i = 0; i < lengths.length; i++) {
      final len = lengths[i];
      if (walked + len >= target) {
        final localT = ((target - walked) / len).clamp(0.0, 1.0);
        return Offset.lerp(points[i], points[i + 1], localT) ?? points[i];
      }
      walked += len;
    }
    return points.last;
  }

  @override
  void dispose() {
    _memoSession++;
    unawaited(_speech.cancel());
    _playController
      ..removeListener(_onPlayTick)
      ..removeStatusListener(_onPlayStatusChanged)
      ..dispose();
    _methodController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () => _shouldPopOnSystemBack(isKo),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          leadingWidth: 152,
          titleSpacing: 0,
          title: _buildAppBarTitle(isKo),
          leading: Row(
            children: [
              IconButton(
                onPressed: () => _handleBackPressed(isKo),
                icon: const Icon(Icons.arrow_back),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              ),
              TextButton.icon(
                onPressed: () => _saveBoard(isKo),
                icon: const Icon(Icons.save_outlined),
                label: Text(isKo ? '저장' : 'Save'),
              ),
            ],
          ),
        ),
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _dismissKeyboard,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Column(
              children: [
                _buildPageHeader(isKo),
                const SizedBox(height: 8),
                _buildMethodTextInput(isKo),
                const SizedBox(height: 8),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final height = constraints.maxHeight;
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                          ),
                        ),
                        child: GestureDetector(
                          key: const ValueKey('training-board-canvas'),
                          behavior: HitTestBehavior.opaque,
                          onPanStart: _penMode
                              ? (details) => _startStroke(
                                  details.localPosition,
                                  width,
                                  height,
                                )
                              : _pathMode
                              ? (details) => _startPlayerPath(
                                  details.localPosition,
                                  width,
                                  height,
                                )
                              : null,
                          onPanUpdate: _penMode
                              ? (details) => _appendStrokePoint(
                                  details.localPosition,
                                  width,
                                  height,
                                )
                              : _pathMode
                              ? (details) => _appendPlayerPath(
                                  details.localPosition,
                                  width,
                                  height,
                                )
                              : null,
                          onPanEnd: _penMode
                              ? (_) => _endStroke()
                              : _pathMode
                              ? (_) => _endPlayerPath()
                              : null,
                          child: Stack(
                            children: [
                              CustomPaint(
                                size: Size(width, height),
                                painter: const _PitchPainter(),
                              ),
                              CustomPaint(
                                size: Size(width, height),
                                painter: _PlayerPathPainter(
                                  routes: _currentPage.routes,
                                  selectedRouteId: _selectedRouteId,
                                  activeRoutePoints: _activeRoutePoints,
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
                                ignoring:
                                    _penMode ||
                                    _pathMode ||
                                    _playController.isAnimating,
                                child: Stack(
                                  children: [
                                    for (final item in _currentPage.items)
                                      Positioned(
                                        left: (item.x * width) - 26,
                                        top: (item.y * height) - 26,
                                        child: GestureDetector(
                                          behavior: HitTestBehavior.opaque,
                                          onTap: () => setState(() {
                                            _selectedItemId = item.id;
                                            _routeReplaceMode = false;
                                          }),
                                          onLongPress: () => setState(() {
                                            _currentPage.items.removeWhere(
                                              (e) => e.id == item.id,
                                            );
                                            _currentPage.routes.removeWhere(
                                              (route) =>
                                                  route.linkedItemId == item.id,
                                            );
                                            if (_selectedItemId == item.id) {
                                              _selectedItemId = null;
                                            }
                                            if (_selectedRoute != null &&
                                                !_currentPage.routes.any(
                                                  (route) =>
                                                      route.id ==
                                                      _selectedRoute!.id,
                                                )) {
                                              _selectedRouteId = null;
                                            }
                                          }),
                                          onPanUpdate: (details) {
                                            final dx = details.delta.dx / width;
                                            final dy =
                                                details.delta.dy / height;
                                            final nextX = (item.x + dx).clamp(
                                              0.03,
                                              0.97,
                                            );
                                            final nextY = (item.y + dy).clamp(
                                              0.03,
                                              0.97,
                                            );
                                            setState(() {
                                              _moveItemWithLinkedRoutes(
                                                item,
                                                nextX: nextX,
                                                nextY: nextY,
                                              );
                                            });
                                          },
                                          child: SizedBox(
                                            width: 52,
                                            height: 52,
                                            child: Center(
                                              child: _BoardToken(
                                                item: item,
                                                selected:
                                                    item.id == _selectedItemId,
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
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                _buildToolButtons(isKo),
                const SizedBox(height: 8),
                _buildSelectedTools(isKo),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageHeader(bool isKo) {
    return Wrap(
      spacing: 2,
      runSpacing: 2,
      alignment: WrapAlignment.end,
      children: [
        if (_isManagedMode)
          IconButton(
            onPressed: () => _promptForManagedBoardCreation(),
            icon: const Icon(Icons.add_box_outlined),
            tooltip: isKo ? '스케치 추가' : 'Add sketch',
          ),
        if (_isManagedMode)
          IconButton(
            onPressed: () => _copyCurrentManagedBoard(isKo),
            icon: const Icon(Icons.copy_outlined),
            tooltip: isKo ? '다른 스케치 복사 추가' : 'Copy from another sketch',
          ),
        if (_isManagedMode)
          IconButton(
            onPressed: _currentBoardId == null
                ? null
                : () => _deleteCurrentManagedBoard(isKo),
            icon: const Icon(Icons.delete_outline),
            tooltip: isKo ? '스케치 삭제' : 'Delete sketch',
          ),
        if (widget.presets.isNotEmpty)
          IconButton(
            onPressed: () => _showPresetPicker(isKo),
            icon: const Icon(Icons.copy_all_outlined),
            tooltip: isKo ? '이전 스케치 가져오기' : 'Import previous sketch',
          ),
        IconButton(
          onPressed: () => _playPlayerPath(isKo),
          icon: Icon(
            _playController.isAnimating
                ? Icons.stop_circle_outlined
                : Icons.play_circle_outline,
          ),
          tooltip: isKo ? '플레이' : 'Play',
        ),
        PopupMenuButton<double>(
          tooltip: isKo ? '재생 속도' : 'Playback speed',
          icon: const Icon(Icons.speed_outlined),
          initialValue: _playSpeed,
          onSelected: (value) => setState(() => _playSpeed = value),
          itemBuilder: (_) => [
            const PopupMenuItem<double>(value: 0.75, child: Text('0.75x')),
            const PopupMenuItem<double>(value: 1.0, child: Text('1.0x')),
            const PopupMenuItem<double>(value: 1.25, child: Text('1.25x')),
            const PopupMenuItem<double>(value: 1.5, child: Text('1.5x')),
          ],
        ),
        IconButton(
          onPressed: () => _renameCurrentPage(isKo),
          icon: const Icon(Icons.edit_outlined),
          tooltip: isKo ? '스케치명 수정' : 'Rename sketch',
        ),
      ],
    );
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

  Widget _buildMethodTextInput(bool isKo) {
    return TextField(
      controller: _methodController,
      minLines: 2,
      maxLines: 3,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: isKo ? '훈련 스케치 메모' : 'Training sketch note',
        hintText: isKo
            ? '예) 콘 사이 2터치 드리블 후 패스'
            : 'e.g. Two-touch dribble between cones then pass',
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          onPressed: () => _toggleMemoListening(isKo),
          icon: Icon(_isListeningMemo ? Icons.mic : Icons.mic_none),
          tooltip: isKo ? '음성 입력' : 'Voice input',
        ),
      ),
      onSubmitted: (_) => _dismissKeyboard(),
      onChanged: (value) {
        _currentPage.methodText = value;
      },
    );
  }

  Widget _buildToolButtons(bool isKo) {
    final l10n = _l10n;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _toolButton(
          isKo: isKo,
          ko: '콘',
          en: 'Cone',
          icon: Icons.change_history,
          onTap: () => _addItem(_BoardItemType.cone),
        ),
        _toolButton(
          isKo: isKo,
          ko: '낮은 뜀틀',
          en: 'Low hurdle',
          icon: Icons.horizontal_rule,
          onTap: () => _addItem(_BoardItemType.hurdle),
        ),
        _toolButton(
          isKo: isKo,
          ko: '사람',
          en: 'Player',
          icon: Icons.person,
          onTap: () => _addItem(_BoardItemType.player),
        ),
        _toolButton(
          isKo: isKo,
          ko: '공',
          en: 'Ball',
          icon: Icons.sports_soccer,
          onTap: () => _addItem(_BoardItemType.ball),
        ),
        _toolButton(
          isKo: isKo,
          ko: '사다리',
          en: 'Ladder',
          icon: Icons.view_week,
          onTap: () => _addItem(_BoardItemType.ladder),
        ),
        OutlinedButton.icon(
          onPressed: () => setState(() {
            _penMode = !_penMode;
            if (_penMode) {
              _pathMode = false;
            }
            _activeRoutePoints = null;
            _routeReplaceMode = false;
          }),
          icon: Icon(_penMode ? Icons.draw : Icons.edit_note_outlined),
          label: Text(isKo ? '펜' : 'Pen'),
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            minimumSize: const Size(1, 40),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            foregroundColor: _penMode ? const Color(0xFFFFEB3B) : null,
          ),
        ),
        OutlinedButton.icon(
          key: const ValueKey('training-path-mode-button'),
          onPressed: _togglePlayerPathMode,
          icon: Icon(_pathMode ? Icons.route : Icons.route_outlined),
          label: Text(l10n.trainingSketchRoutesButton),
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            minimumSize: const Size(1, 40),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            foregroundColor: _pathMode ? const Color(0xFFFFEB3B) : null,
          ),
        ),
        OutlinedButton.icon(
          onPressed: _currentPage.strokes.isEmpty
              ? null
              : () => setState(() {
                  _currentPage.strokes.clear();
                  _activeStroke = null;
                }),
          icon: const Icon(Icons.layers_clear_outlined),
          label: Text(isKo ? '펜 지우기' : 'Clear ink'),
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            minimumSize: const Size(1, 40),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
        ),
        OutlinedButton.icon(
          onPressed: _currentPage.routes.isEmpty ? null : _clearAllRoutes,
          icon: const Icon(Icons.route_outlined),
          label: Text(l10n.trainingSketchClearAllRoutesButton),
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            minimumSize: const Size(1, 40),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
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
              _selectedItemId = null;
              _selectedRouteId = null;
              _routeReplaceMode = false;
            });
          },
          icon: const Icon(Icons.delete_sweep_outlined),
          label: Text(isKo ? '초기화' : 'Clear'),
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            minimumSize: const Size(1, 40),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _toolButton({
    required bool isKo,
    required String ko,
    required String en,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(isKo ? ko : en),
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        minimumSize: const Size(1, 40),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
    );
  }

  Widget _buildSelectedTools(bool isKo) {
    final selected = _selectedItem;
    final selectedRoute = _selectedRoute;
    final l10n = _l10n;
    if (_penMode) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isKo
                  ? '펜 모드: 보드 영역을 드래그해 그릴 수 있습니다.'
                  : 'Pen mode: drag on the board to draw.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              isKo ? '펜 색상' : 'Pen color',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _penColors
                  .map((c) {
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
                            color: selectedColor
                                ? Colors.white
                                : Colors.black26,
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
                  })
                  .toList(growable: false),
            ),
          ],
        ),
      );
    }
    if (_pathMode) {
      final routes = _routesForKind(_pathDrawMode);
      final hasSelectedCurrentRoute =
          selectedRoute != null && selectedRoute.kind == _pathDrawMode;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<_PathDrawMode>(
              segments: [
                ButtonSegment<_PathDrawMode>(
                  value: _PathDrawMode.player,
                  icon: const Icon(Icons.person),
                  label: Text(isKo ? '사람' : 'Player'),
                ),
                ButtonSegment<_PathDrawMode>(
                  value: _PathDrawMode.ball,
                  icon: const Icon(Icons.sports_soccer),
                  label: Text(isKo ? '공' : 'Ball'),
                ),
              ],
              selected: {_pathDrawMode},
              onSelectionChanged: (selection) {
                setState(() {
                  _pathDrawMode = selection.first;
                  _activeRoutePoints = null;
                  _routeReplaceMode = false;
                });
              },
              showSelectedIcon: false,
            ),
            const SizedBox(height: 8),
            Text(_pathModeHint(), style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 10),
            Text(
              _pathDrawMode == _PathDrawMode.player
                  ? l10n.trainingSketchPlayerRoutesTitle
                  : l10n.trainingSketchBallRoutesTitle,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 6),
            if (routes.isEmpty)
              Text(
                l10n.trainingSketchRoutesEmpty,
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: routes
                    .asMap()
                    .entries
                    .map((entry) {
                      final index = entry.key;
                      final route = entry.value;
                      return ChoiceChip(
                        key: ValueKey('training-route-chip-${route.id}'),
                        selected: route.id == selectedRoute?.id,
                        label: Text(_routeLabel(route.kind, index + 1)),
                        onSelected: (_) => _selectRoute(route),
                      );
                    })
                    .toList(growable: false),
              ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: hasSelectedCurrentRoute
                      ? _prepareSelectedRouteRedraw
                      : null,
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(l10n.trainingSketchRedrawRouteButton),
                ),
                OutlinedButton.icon(
                  onPressed: hasSelectedCurrentRoute
                      ? _deleteSelectedRoute
                      : null,
                  icon: const Icon(Icons.delete_outline),
                  label: Text(l10n.trainingSketchDeleteRouteButton),
                ),
              ],
            ),
          ],
        ),
      );
    }
    if (selected == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: Text(
          isKo
              ? '빠른 시작: 사람/공 추가 -> 이동선 그리기 -> 플레이(속도 조절) -> 저장'
              : 'Quick start: Add player/ball -> draw paths -> play (speed) -> save',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isKo ? '선택 요소' : 'Selected item',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              IconButton(
                onPressed: _removeSelected,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: isKo ? '삭제' : 'Delete',
              ),
            ],
          ),
          Text(
            isKo ? '색상 지정' : 'Assign color',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presetColors
                .map((c) {
                  final selectedColor =
                      c.toARGB32() == selected.color.toARGB32();
                  return InkWell(
                    onTap: () => setState(() => selected.color = c),
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
                    ),
                  );
                })
                .toList(growable: false),
          ),
          if (selected.type == _BoardItemType.player ||
              selected.type == _BoardItemType.ball) ...[
            const SizedBox(height: 10),
            Text(
              selected.type == _BoardItemType.player
                  ? l10n.trainingSketchLinkPlayerHint
                  : l10n.trainingSketchLinkBallHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
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
  final List<Offset> points;
  final Color color;
  final double width;

  _BoardRoute({
    required this.id,
    required this.kind,
    required this.points,
    required this.color,
    required this.width,
    this.linkedItemId,
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

enum _PendingBoardAction { save, discard, cancel }

enum _PathDrawMode { player, ball }

enum _BoardItemType { cone, hurdle, player, ball, ladder }

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
    _BoardItemType.player => const Color(0xFF42A5F5),
    _BoardItemType.ball => const Color(0xFFFFFFFF),
    _BoardItemType.ladder => const Color(0xFFE53935),
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
    _PathDrawMode.player => const Color(0xFF80D8FF),
    _PathDrawMode.ball => const Color(0xFFFFCA28),
  };
}

double _defaultRouteWidth(_PathDrawMode kind) {
  return switch (kind) {
    _PathDrawMode.player => 4.0,
    _PathDrawMode.ball => 3.0,
  };
}

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

  const _BoardToken({required this.item, required this.selected});

  @override
  Widget build(BuildContext context) {
    final icon = switch (item.type) {
      _BoardItemType.cone => Icons.change_history,
      _BoardItemType.hurdle => Icons.horizontal_rule,
      _BoardItemType.player => Icons.person,
      _BoardItemType.ball => Icons.sports_soccer,
      _BoardItemType.ladder => Icons.view_week,
    };
    return Transform.rotate(
      angle: (item.rotationDeg * math.pi) / 180,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.18),
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.55),
            width: selected ? 2.2 : 1.2,
          ),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Icon(icon, size: 18, color: item.color),
      ),
    );
  }
}

class _PlayerPathPainter extends CustomPainter {
  final List<_BoardRoute> routes;
  final String? selectedRouteId;
  final List<Offset>? activeRoutePoints;
  final _PathDrawMode activeRouteKind;

  const _PlayerPathPainter({
    required this.routes,
    required this.selectedRouteId,
    required this.activeRoutePoints,
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
      _draw(
        canvas: canvas,
        size: size,
        points: route.points,
        color: route.color.withValues(alpha: 0.7),
        width: route.width,
      );
    }
    if (selectedRoute != null) {
      _drawSelectedRoute(canvas, size, selectedRoute);
    }
    final active = activeRoutePoints;
    if (active != null && active.length > 1) {
      _draw(
        canvas: canvas,
        size: size,
        points: active,
        color: _defaultRouteColor(activeRouteKind).withValues(alpha: 0.72),
        width: 3.0,
      );
    }
  }

  void _drawSelectedRoute(Canvas canvas, Size size, _BoardRoute route) {
    _draw(
      canvas: canvas,
      size: size,
      points: route.points,
      color: Colors.black.withValues(alpha: 0.22),
      width: route.width + 10,
    );
    _draw(
      canvas: canvas,
      size: size,
      points: route.points,
      color: Colors.white.withValues(alpha: 0.96),
      width: route.width + 6,
    );
    _draw(
      canvas: canvas,
      size: size,
      points: route.points,
      color: route.color.withValues(alpha: 1.0),
      width: route.width + 1.8,
    );
    _drawMarker(
      canvas: canvas,
      size: size,
      point: route.points.first,
      color: route.color,
      radius: 6.8,
      filled: true,
    );
    _drawMarker(
      canvas: canvas,
      size: size,
      point: route.points.last,
      color: route.color,
      radius: 7.8,
      filled: false,
    );
  }

  void _draw({
    required Canvas canvas,
    required Size size,
    required List<Offset> points,
    required Color color,
    required double width,
  }) {
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

  void _drawMarker({
    required Canvas canvas,
    required Size size,
    required Offset point,
    required Color color,
    required double radius,
    required bool filled,
  }) {
    final center = Offset(point.dx * size.width, point.dy * size.height);
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
    return oldDelegate.routes != routes ||
        oldDelegate.selectedRouteId != selectedRouteId ||
        oldDelegate.activeRoutePoints != activeRoutePoints ||
        oldDelegate.activeRouteKind != activeRouteKind;
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
    return oldDelegate.strokes != strokes ||
        oldDelegate.activeStrokePoints != activeStrokePoints ||
        oldDelegate.activeStrokeColor != activeStrokeColor;
  }
}

class _PitchPainter extends CustomPainter {
  const _PitchPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    canvas.drawRect(
      Rect.fromLTWH(8, 8, size.width - 16, size.height - 16),
      line,
    );
    canvas.drawLine(Offset(centerX, 8), Offset(centerX, size.height - 8), line);
    canvas.drawCircle(Offset(centerX, centerY), 42, line);
    canvas.drawRect(Rect.fromLTWH(8, (size.height / 2) - 56, 74, 112), line);
    canvas.drawRect(
      Rect.fromLTWH(size.width - 82, (size.height / 2) - 56, 74, 112),
      line,
    );
  }

  @override
  bool shouldRepaint(covariant _PitchPainter oldDelegate) {
    return false;
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
