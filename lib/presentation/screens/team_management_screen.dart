import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:image_picker/image_picker.dart';

import '../../application/family_access_service.dart';
import '../../application/locale_service.dart';
import '../../application/settings_service.dart';
import '../../application/team_management_service.dart';
import '../../application/training_service.dart';
import '../../domain/repositories/option_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/app_page_route.dart';
import '../widgets/app_bar_action_button.dart';
import '../widgets/app_feedback.dart';
import 'club_schedule_screen.dart';
import 'competition_management_screen.dart';
import 'match_record_screen.dart';
import 'match_records_screen.dart';

enum _TacticBoardMode { assign, movement, press, zone }

enum _TeamManagementSection { players, matches }

enum _TeamManagementWorkspace { board }

class _TacticUndoSnapshot {
  final List<ManagedTacticBoard> boards;
  final String activeBoardId;
  final _TacticBoardMode boardMode;

  const _TacticUndoSnapshot({
    required this.boards,
    required this.activeBoardId,
    required this.boardMode,
  });
}

typedef _PlayerBoardDropCallback = void Function({
  required String playerId,
  required Offset point,
});

class TeamManagementScreen extends StatefulWidget {
  final OptionRepository optionRepository;
  final TrainingService? trainingService;
  final LocaleService? localeService;
  final SettingsService? settingsService;
  final VoidCallback? onOpenMatchStats;
  final String? sportId;
  final bool readOnly;
  final bool openRecordOnStart;
  final DateTime? initialRecordDate;

  const TeamManagementScreen({
    super.key,
    required this.optionRepository,
    this.trainingService,
    this.localeService,
    this.settingsService,
    this.onOpenMatchStats,
    this.sportId,
    this.readOnly = false,
    this.openRecordOnStart = false,
    this.initialRecordDate,
  });

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen> {
  late final TeamManagementService _teamService;
  final TextEditingController _teamNameController = TextEditingController();
  final TextEditingController _strategyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _autoSaveDebounce;

  ManagedTeam? _selectedTeam;
  List<ManagedTeamPlayer> _players = const <ManagedTeamPlayer>[];
  Map<String, String> _lineup = const <String, String>{};
  Map<String, ManagedPlayerPlacement> _playerPlacements =
      const <String, ManagedPlayerPlacement>{};
  List<ManagedTacticLine> _tacticLines = const <ManagedTacticLine>[];
  List<ManagedTacticBoard> _tacticBoards = const <ManagedTacticBoard>[];
  String _activeTacticBoardId = '';
  String _formation = ManagedTeam.defaultFormation;
  _TeamManagementSection _activeSection = _TeamManagementSection.players;
  _TeamManagementWorkspace? _activeWorkspace;
  _TacticBoardMode _boardMode = _TacticBoardMode.assign;
  ManagedTacticLine? _draftTacticLine;
  final List<_TacticUndoSnapshot> _tacticUndoStack = <_TacticUndoSnapshot>[];
  String? _activePlacementUndoPlayerId;
  bool _boardLandscapeMode = false;
  bool _loaded = false;
  bool _saving = false;
  bool _suppressAutoSave = false;
  int _changeRevision = 0;
  int _savedRevision = 0;

  @override
  void initState() {
    super.initState();
    _teamService = TeamManagementService(
      widget.optionRepository,
      sportId: widget.sportId,
    );
    _teamNameController.addListener(_handleTextFieldChanged);
    _strategyController.addListener(_handleTextFieldChanged);
    if (widget.openRecordOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_openMatchRecord(initialDate: widget.initialRecordDate));
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    _loadTeam(AppLocalizations.of(context)!);
  }

  @override
  void dispose() {
    _resetBoardLandscapeMode();
    _autoSaveDebounce?.cancel();
    if (!_isReadOnlySupportMode && _changeRevision > _savedRevision) {
      final team = _currentTeam();
      if (team.name.trim().isNotEmpty) {
        unawaited(_teamService.upsertTeam(team));
      }
    }
    _teamNameController.removeListener(_handleTextFieldChanged);
    _strategyController.removeListener(_handleTextFieldChanged);
    _scrollController.dispose();
    _teamNameController.dispose();
    _strategyController.dispose();
    super.dispose();
  }

  void _handleTextFieldChanged() {
    if (_suppressAutoSave || _isReadOnlySupportMode) return;
    _scheduleAutoSave();
  }

  bool get _isReadOnlySupportMode =>
      widget.readOnly ||
      FamilyAccessService(
        widget.optionRepository,
      ).loadState().isReadOnlySupportMode;

  bool _blockReadOnlyMutation({bool showMessage = true}) {
    if (!_isReadOnlySupportMode) return false;
    _autoSaveDebounce?.cancel();
    _changeRevision = _savedRevision;
    if (mounted) {
      setState(() {});
      if (showMessage) {
        AppFeedback.showMessage(
          context,
          text: AppLocalizations.of(context)!.parentReadOnlyCoreDataMessage,
        );
      }
    }
    return true;
  }

  Future<void> _openClubSchedule() async {
    await _flushAutoSave();
    if (!mounted) return;
    await Navigator.of(context).push(
      AppPageRoute(
        builder: (_) => ClubScheduleScreen(
          optionRepository: widget.optionRepository,
          sportId: widget.sportId,
          readOnly: _isReadOnlySupportMode,
        ),
      ),
    );
  }

  Future<void> _openMatchRecord({DateTime? initialDate}) async {
    if (_isReadOnlySupportMode) {
      AppFeedback.showMessage(
        context,
        text: AppLocalizations.of(context)!.parentReadOnlyCoreDataMessage,
      );
      return;
    }
    final trainingService = widget.trainingService;
    final localeService = widget.localeService;
    final settingsService = widget.settingsService;
    if (trainingService == null ||
        localeService == null ||
        settingsService == null) {
      return;
    }
    await _flushAutoSave();
    if (!mounted) return;
    await Navigator.of(context).push(
      AppPageRoute(
        builder: (_) => MatchRecordScreen(
          trainingService: trainingService,
          localeService: localeService,
          optionRepository: widget.optionRepository,
          settingsService: settingsService,
          initialDate: initialDate,
        ),
      ),
    );
  }

  Future<void> _openCompetitionManagement() async {
    final trainingService = widget.trainingService;
    if (trainingService == null) return;
    await _flushAutoSave();
    if (!mounted) return;
    await Navigator.of(context).push(
      AppPageRoute(
        builder: (_) => CompetitionManagementScreen(
          trainingService: trainingService,
          optionRepository: widget.optionRepository,
          sportId: widget.sportId,
          readOnly: _isReadOnlySupportMode,
        ),
      ),
    );
  }

  Future<void> _openMatchRecords() async {
    final trainingService = widget.trainingService;
    if (trainingService == null) return;
    await _flushAutoSave();
    if (!mounted) return;
    await Navigator.of(context).push(
      AppPageRoute(
        builder: (_) => MatchRecordsScreen(
          trainingService: trainingService,
          optionRepository: widget.optionRepository,
        ),
      ),
    );
  }

  void _openMatchStats() {
    final onOpenMatchStats = widget.onOpenMatchStats;
    if (onOpenMatchStats == null) return;
    Navigator.of(context).maybePop();
    WidgetsBinding.instance.addPostFrameCallback((_) => onOpenMatchStats());
  }

  void _loadTeam(AppLocalizations l10n) {
    final teams = _teamService.allTeams();
    if (teams.isEmpty) {
      _selectTeam(_draftTeam(l10n));
      return;
    }
    _selectTeam(teams.first, saved: true);
  }

  ManagedTeam _draftTeam(AppLocalizations l10n) {
    final board = ManagedTacticBoard.create(
      title: l10n.teamManagementTacticBoardDefaultTitle(1),
    );
    return ManagedTeam.create(
      name: l10n.teamManagementDefaultTeamName,
      tacticBoards: [board],
      activeTacticBoardId: board.id,
    );
  }

  void _selectTeam(ManagedTeam team, {bool saved = false}) {
    _autoSaveDebounce?.cancel();
    _selectedTeam = team;
    _formation = team.formation;
    _players = List<ManagedTeamPlayer>.from(team.players);
    _lineup = TeamManagementService.normalizeLineup(
      lineup: team.lineup,
      players: _players,
      formation: _formation,
    );
    _tacticBoards = _normalizedTacticBoards(
      boards: team.tacticBoards,
      fallbackPlacements: team.playerPlacements.isNotEmpty
          ? team.playerPlacements
          : TeamManagementService.placementsFromLineup(
              lineup: _lineup,
              players: _players,
              formation: _formation,
            ),
      fallbackLines: team.tacticLines,
    );
    _activeTacticBoardId = TeamManagementService.normalizeActiveTacticBoardId(
      team.activeTacticBoardId,
      _tacticBoards,
    );
    _loadActiveTacticBoardState();
    _boardMode = _TacticBoardMode.assign;
    _draftTacticLine = null;
    _tacticUndoStack.clear();
    _activePlacementUndoPlayerId = null;
    _changeRevision = 0;
    _savedRevision = 0;
    _suppressAutoSave = true;
    _teamNameController.text = team.name;
    _strategyController.text = team.strategy;
    _suppressAutoSave = false;
    setState(() {});
  }

  ManagedTeam _currentTeam() {
    final base = _selectedTeam ?? ManagedTeam.create(name: '');
    final tacticBoards = _syncedTacticBoards();
    final activeBoard = TeamManagementService.activeTacticBoard(
      tacticBoards,
      _activeTacticBoardId,
    );
    return base.copyWith(
      name: _teamNameController.text.trim(),
      formation: _formation,
      strategy: _strategyController.text.trim(),
      players: _players,
      lineup: _lineup,
      playerPlacements: activeBoard.playerPlacements,
      tacticLines: activeBoard.tacticLines,
      tacticBoards: tacticBoards,
      activeTacticBoardId: activeBoard.id,
    );
  }

  List<ManagedTacticBoard> _normalizedTacticBoards({
    required List<ManagedTacticBoard> boards,
    required Map<String, ManagedPlayerPlacement> fallbackPlacements,
    required List<ManagedTacticLine> fallbackLines,
  }) {
    final normalized = TeamManagementService.normalizeTacticBoards(
      boards,
      players: _players,
    );
    if (normalized.isNotEmpty) return normalized;
    return [
      ManagedTacticBoard.create(
        title: TeamManagementService.defaultTacticBoardTitle(1),
        playerPlacements: TeamManagementService.normalizePlayerPlacements(
          placements: fallbackPlacements,
          players: _players,
        ),
        tacticLines: fallbackLines,
      ),
    ];
  }

  List<ManagedTacticBoard> _syncedTacticBoards() {
    final normalized = TeamManagementService.normalizeTacticBoards(
      _tacticBoards,
      players: _players,
    );
    final boards = normalized.isNotEmpty
        ? normalized
        : [
            ManagedTacticBoard.create(
              title: TeamManagementService.defaultTacticBoardTitle(1),
              playerPlacements: _playerPlacements,
              tacticLines: _tacticLines,
            ),
          ];
    final activeBoardId = TeamManagementService.normalizeActiveTacticBoardId(
      _activeTacticBoardId,
      boards,
    );
    final normalizedPlacements =
        TeamManagementService.normalizePlayerPlacements(
      placements: _playerPlacements,
      players: _players,
    );
    final normalizedLines = TeamManagementService.normalizeTacticLines(
      _tacticLines,
    );
    return [
      for (final board in boards)
        if (board.id == activeBoardId)
          board.copyWith(
            playerPlacements: normalizedPlacements,
            tacticLines: normalizedLines,
          )
        else
          board,
    ];
  }

  void _loadActiveTacticBoardState() {
    final activeBoard = TeamManagementService.activeTacticBoard(
      _tacticBoards,
      _activeTacticBoardId,
    );
    _activeTacticBoardId = activeBoard.id;
    _playerPlacements = Map<String, ManagedPlayerPlacement>.from(
      activeBoard.playerPlacements,
    );
    _tacticLines = List<ManagedTacticLine>.from(activeBoard.tacticLines);
  }

  void _syncActiveTacticBoardState() {
    _tacticBoards = _syncedTacticBoards();
    _activeTacticBoardId = TeamManagementService.normalizeActiveTacticBoardId(
      _activeTacticBoardId,
      _tacticBoards,
    );
  }

  _TacticUndoSnapshot _captureTacticUndoSnapshot() {
    final boards = _syncedTacticBoards();
    final activeBoardId = TeamManagementService.normalizeActiveTacticBoardId(
      _activeTacticBoardId,
      boards,
    );
    return _TacticUndoSnapshot(
      boards: List<ManagedTacticBoard>.from(boards),
      activeBoardId: activeBoardId,
      boardMode: _boardMode,
    );
  }

  void _rememberTacticUndoState() {
    if (_isReadOnlySupportMode) return;
    _tacticUndoStack.add(_captureTacticUndoSnapshot());
    if (_tacticUndoStack.length > 30) {
      _tacticUndoStack.removeAt(0);
    }
  }

  void _undoLastTacticAction() {
    if (_blockReadOnlyMutation()) return;
    if (_tacticUndoStack.isEmpty) return;
    final snapshot = _tacticUndoStack.removeLast();
    setState(() {
      _tacticBoards = List<ManagedTacticBoard>.from(snapshot.boards);
      _activeTacticBoardId = snapshot.activeBoardId;
      _loadActiveTacticBoardState();
      _boardMode = snapshot.boardMode;
      _draftTacticLine = null;
      _activePlacementUndoPlayerId = null;
    });
    _scheduleAutoSave();
    AppFeedback.showSuccess(
      context,
      text: AppLocalizations.of(context)!.teamManagementTacticBoardUndoFeedback,
    );
  }

  void _scheduleAutoSave({
    Duration delay = const Duration(milliseconds: 650),
    bool markChanged = true,
  }) {
    if (_suppressAutoSave || _blockReadOnlyMutation(showMessage: false)) return;
    _autoSaveDebounce?.cancel();
    if (markChanged) {
      _changeRevision++;
    }
    if (mounted) {
      setState(() {});
    }
    _autoSaveDebounce = Timer(
      delay,
      () => unawaited(_persistTeam()),
    );
  }

  Future<void> _flushAutoSave() async {
    if (_blockReadOnlyMutation(showMessage: false)) return;
    _autoSaveDebounce?.cancel();
    await _persistTeam();
  }

  Future<void> _persistTeam({
    bool force = false,
    bool showFeedback = false,
  }) async {
    if (_blockReadOnlyMutation(showMessage: showFeedback)) return;
    final l10n = AppLocalizations.of(context)!;
    final revisionToSave = _changeRevision;
    if (!force && revisionToSave <= _savedRevision) {
      return;
    }
    final name = _teamNameController.text.trim();
    if (name.isEmpty) {
      if (showFeedback) {
        AppFeedback.showMessage(context, text: l10n.teamManagementNameRequired);
      }
      return;
    }
    if (_saving) {
      _scheduleAutoSave(
        delay: const Duration(milliseconds: 300),
        markChanged: false,
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final team = _currentTeam();
      await _teamService.upsertTeam(team);
      if (!mounted) return;
      final savedTeam = _teamService.findTeamById(team.id);
      setState(() {
        _selectedTeam = savedTeam ?? team;
        if (_savedRevision < revisionToSave) {
          _savedRevision = revisionToSave;
        }
      });
      if (showFeedback) {
        AppFeedback.showSuccess(context,
            text: l10n.teamManagementSavedFeedback);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
        if (_changeRevision > _savedRevision) {
          _scheduleAutoSave(
            delay: const Duration(milliseconds: 300),
            markChanged: false,
          );
        }
      }
    }
  }

  Future<void> _openPlayerRegistration({
    ManagedTeamPlayer? player,
  }) async {
    if (_blockReadOnlyMutation()) return;
    final registeredPlayer =
        await Navigator.of(context).push<ManagedTeamPlayer>(
      AppPageRoute(
        builder: (_) => _PlayerRegistrationScreen(
          player: player,
          readOnly: _isReadOnlySupportMode,
        ),
      ),
    );
    if (!mounted || registeredPlayer == null) {
      return;
    }
    setState(() {
      if (player == null) {
        _players = TeamManagementService.normalizePlayers([
          ..._players,
          registeredPlayer,
        ]);
      } else {
        _players = TeamManagementService.normalizePlayers(
          _players.map((item) {
            if (item.id != player.id) return item;
            return registeredPlayer.copyWith(
              id: player.id,
            );
          }),
        );
      }
    });
    _scheduleAutoSave();
  }

  void _selectTacticBoard(String boardId) {
    final key = boardId.trim();
    if (key.isEmpty || key == _activeTacticBoardId) return;
    setState(() {
      _tacticBoards = _syncedTacticBoards();
      _activeTacticBoardId = key;
      _loadActiveTacticBoardState();
      _draftTacticLine = null;
      _boardMode = _TacticBoardMode.assign;
    });
    if (_isReadOnlySupportMode) return;
    _scheduleAutoSave();
  }

  void _addTacticBoard() {
    if (_blockReadOnlyMutation()) return;
    final l10n = AppLocalizations.of(context)!;
    final synced = _syncedTacticBoards();
    _rememberTacticUndoState();
    final next = ManagedTacticBoard.create(
      title: l10n.teamManagementTacticBoardDefaultTitle(synced.length + 1),
    );
    setState(() {
      _tacticBoards = [...synced, next];
      _activeTacticBoardId = next.id;
      _loadActiveTacticBoardState();
      _draftTacticLine = null;
      _boardMode = _TacticBoardMode.assign;
    });
    _scheduleAutoSave();
  }

  void _duplicateTacticBoard() {
    if (_blockReadOnlyMutation()) return;
    final l10n = AppLocalizations.of(context)!;
    final synced = _syncedTacticBoards();
    final source = TeamManagementService.activeTacticBoard(
      synced,
      _activeTacticBoardId,
    );
    final sourceIndex = synced.indexWhere((board) => board.id == source.id);
    final duplicate = ManagedTacticBoard.create(
      title: l10n.teamManagementTacticBoardCopyTitle(
        _tacticBoardDisplayTitle(
          l10n,
          source,
          sourceIndex < 0 ? 0 : sourceIndex,
        ),
      ),
      playerPlacements: source.playerPlacements,
      tacticLines: source.tacticLines,
    );
    _rememberTacticUndoState();
    setState(() {
      _tacticBoards = [...synced, duplicate];
      _activeTacticBoardId = duplicate.id;
      _loadActiveTacticBoardState();
      _draftTacticLine = null;
      _boardMode = _TacticBoardMode.assign;
    });
    _scheduleAutoSave();
  }

  void _renameTacticBoard(String boardId, String title) {
    if (_blockReadOnlyMutation()) return;
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    _rememberTacticUndoState();
    setState(() {
      _tacticBoards = [
        for (final board in _syncedTacticBoards())
          if (board.id == boardId)
            board.copyWith(title: trimmed, updatedAt: DateTime.now())
          else
            board,
      ];
    });
    _scheduleAutoSave();
  }

  Future<void> _deleteActiveTacticBoard() async {
    if (_blockReadOnlyMutation()) return;
    final l10n = AppLocalizations.of(context)!;
    final synced = _syncedTacticBoards();
    if (synced.length <= 1) return;
    final currentIndex = synced.indexWhere(
      (board) => board.id == _activeTacticBoardId,
    );
    final activeBoard = TeamManagementService.activeTacticBoard(
      synced,
      _activeTacticBoardId,
    );
    final activeTitle = _tacticBoardDisplayTitle(
      l10n,
      activeBoard,
      currentIndex < 0 ? 0 : currentIndex,
    );
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.teamManagementTacticBoardDeleteDialogTitle),
        content: Text(
          l10n.teamManagementTacticBoardDeleteDialogBody(activeTitle),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (!mounted || shouldDelete != true) return;
    final nextBoards = synced
        .where((board) => board.id != _activeTacticBoardId)
        .toList(growable: false);
    final nextIndex = currentIndex <= 0
        ? 0
        : math.min(currentIndex - 1, nextBoards.length - 1);
    _rememberTacticUndoState();
    setState(() {
      _tacticBoards = nextBoards;
      _activeTacticBoardId = nextBoards[nextIndex].id;
      _loadActiveTacticBoardState();
      _draftTacticLine = null;
      _boardMode = _TacticBoardMode.assign;
    });
    _scheduleAutoSave();
    AppFeedback.showUndo(
      context,
      text: l10n.teamManagementTacticBoardDeletedFeedback,
      undoLabel: l10n.undo,
      onUndo: _undoLastTacticAction,
    );
  }

  void _removePlayer(ManagedTeamPlayer player) {
    if (_blockReadOnlyMutation()) return;
    setState(() {
      _players = _players
          .where((item) => item.id != player.id)
          .toList(growable: false);
      final next = Map<String, String>.from(_lineup)
        ..removeWhere((_, playerId) => playerId == player.id);
      _lineup = next;
      _playerPlacements = Map<String, ManagedPlayerPlacement>.from(
        _playerPlacements,
      )..remove(player.id);
      _tacticBoards = [
        for (final board in _syncedTacticBoards())
          board.copyWith(
            playerPlacements:
                Map<String, ManagedPlayerPlacement>.from(board.playerPlacements)
                  ..remove(player.id),
          ),
      ];
      _loadActiveTacticBoardState();
    });
    _scheduleAutoSave();
  }

  void _placePlayerOnBoard({
    required String playerId,
    required Offset point,
  }) {
    if (_blockReadOnlyMutation()) return;
    final normalizedPlayerId = playerId.trim();
    if (!_players.any((player) => player.id == normalizedPlayerId)) return;
    if (_activePlacementUndoPlayerId != normalizedPlayerId) {
      _beginPlayerPlacementUndo(normalizedPlayerId);
    }
    final placement = ManagedPlayerPlacement.create(
      playerId: normalizedPlayerId,
      x: point.dx,
      y: point.dy,
    );
    setState(() {
      _playerPlacements = {
        ..._playerPlacements,
        normalizedPlayerId: placement,
      };
      _syncActiveTacticBoardState();
    });
    _scheduleAutoSave();
  }

  void _beginPlayerPlacementUndo(String playerId) {
    if (_isReadOnlySupportMode) return;
    final normalizedPlayerId = playerId.trim();
    if (normalizedPlayerId.isEmpty ||
        _activePlacementUndoPlayerId == normalizedPlayerId) {
      return;
    }
    _rememberTacticUndoState();
    _activePlacementUndoPlayerId = normalizedPlayerId;
  }

  void _finishPlayerPlacementUndo() {
    _activePlacementUndoPlayerId = null;
  }

  void _changeBoardMode(_TacticBoardMode mode) {
    if (_blockReadOnlyMutation()) return;
    setState(() {
      _boardMode = mode;
      _draftTacticLine = null;
    });
  }

  String _markerTypeForBoardMode(_TacticBoardMode mode) {
    return switch (mode) {
      _TacticBoardMode.press => ManagedTacticLine.typePress,
      _TacticBoardMode.zone => ManagedTacticLine.typeZone,
      _ => ManagedTacticLine.typeMovement,
    };
  }

  void _startTacticLine(Offset point) {
    if (_isReadOnlySupportMode) return;
    if (_boardMode == _TacticBoardMode.assign) return;
    setState(() {
      _draftTacticLine = ManagedTacticLine.create(
        type: _markerTypeForBoardMode(_boardMode),
        startX: point.dx,
        startY: point.dy,
        endX: point.dx,
        endY: point.dy,
      );
    });
  }

  void _updateTacticLine(Offset point) {
    if (_isReadOnlySupportMode) return;
    final draft = _draftTacticLine;
    if (_boardMode == _TacticBoardMode.assign || draft == null) return;
    setState(() {
      _draftTacticLine = draft.copyWith(endX: point.dx, endY: point.dy);
    });
  }

  void _finishTacticLine() {
    if (_blockReadOnlyMutation(showMessage: false)) return;
    final draft = _draftTacticLine;
    if (draft == null) return;
    final distance = math.sqrt(
      math.pow(draft.endX - draft.startX, 2) +
          math.pow(draft.endY - draft.startY, 2),
    );
    if (distance >= 0.04) {
      _rememberTacticUndoState();
    }
    setState(() {
      if (distance >= 0.04) {
        _tacticLines = TeamManagementService.normalizeTacticLines([
          ..._tacticLines,
          draft.copyWith(
              id: TeamManagementService.tacticLineId(
            now: DateTime.now(),
          )),
        ]);
        _syncActiveTacticBoardState();
      }
      _draftTacticLine = null;
    });
    if (distance >= 0.04) {
      _scheduleAutoSave();
    }
  }

  void _clearTacticLines() {
    if (_blockReadOnlyMutation()) return;
    if (_tacticLines.isEmpty && _draftTacticLine == null) return;
    _rememberTacticUndoState();
    setState(() {
      _tacticLines = const <ManagedTacticLine>[];
      _draftTacticLine = null;
      _syncActiveTacticBoardState();
    });
    _scheduleAutoSave();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final readOnly = _isReadOnlySupportMode;
    final workspace = _activeWorkspace;
    return Scaffold(
      body: ColoredBox(
        color: theme.scaffoldBackgroundColor,
        child: SafeArea(
          child: workspace == _TeamManagementWorkspace.board
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.sm,
                    AppSpacing.sm,
                    AppSpacing.sm,
                    AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _WorkspaceScreenHeader(
                        onBackToMenu: _closeWorkspace,
                        landscapeMode: _boardLandscapeMode,
                        onToggleLandscape: _toggleBoardLandscapeMode,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Expanded(
                        child: _buildActiveWorkspace(workspace!, readOnly),
                      ),
                    ],
                  ),
                )
              : _buildMainManagementContent(readOnly),
        ),
      ),
    );
  }

  Widget _buildMainManagementContent(bool readOnly) {
    return _buildMainManagementScrollView(readOnly);
  }

  Widget _buildMainManagementScrollView(bool readOnly) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TeamManagementHeader(
            onBack: () => Navigator.of(context).maybePop(),
            onOpenBoard: () => _openWorkspace(_TeamManagementWorkspace.board),
            onManageCompetitions: widget.trainingService == null
                ? null
                : () => unawaited(_openCompetitionManagement()),
          ),
          const SizedBox(height: AppSpacing.sm),
          _TeamManagementSectionSwitcher(
            selectedSection: _activeSection,
            onSectionChanged: _changeSection,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildTeamManagementHome(readOnly),
        ],
      ),
    );
  }

  Widget _buildTeamManagementHome(bool readOnly) {
    return switch (_activeSection) {
      _TeamManagementSection.players => _buildPlayerManagementHome(readOnly),
      _TeamManagementSection.matches => _buildMatchManagementHome(),
    };
  }

  Widget _buildPlayerManagementHome(bool readOnly) {
    return _buildPlayersPanel(readOnly);
  }

  Widget _buildMatchManagementHome() {
    final matchActionsEnabled = widget.trainingService != null &&
        widget.localeService != null &&
        widget.settingsService != null;
    return _MatchManagementPanel(
      matchActionsEnabled: matchActionsEnabled,
      recordsEnabled: widget.trainingService != null,
      onRecordMatch: () => unawaited(_openMatchRecord()),
      onOpenMatchRecords: () => unawaited(_openMatchRecords()),
      onOpenMatchStats:
          widget.onOpenMatchStats == null ? null : _openMatchStats,
      onOpenSchedule: () => unawaited(_openClubSchedule()),
    );
  }

  Widget _buildPlayersPanel(bool readOnly) {
    return _PlayersPanel(
      players: _players,
      lineup: _lineup,
      playerPlacements: _playerPlacements,
      readOnly: readOnly,
      onStartPlayerRegistration: () => unawaited(_openPlayerRegistration()),
      onEditPlayer: (player) => unawaited(
        _openPlayerRegistration(player: player),
      ),
      onRemovePlayer: _removePlayer,
    );
  }

  void _openWorkspace(_TeamManagementWorkspace workspace) {
    setState(() => _activeWorkspace = workspace);
    _scrollToTop();
  }

  void _changeSection(_TeamManagementSection section) {
    if (_activeSection == section) return;
    setState(() => _activeSection = section);
    _scrollToTop();
  }

  void _closeWorkspace() {
    setState(() => _activeWorkspace = null);
    _resetBoardLandscapeMode();
    _scrollToTop();
  }

  void _toggleBoardLandscapeMode() {
    final next = !_boardLandscapeMode;
    setState(() => _boardLandscapeMode = next);
    unawaited(
      SystemChrome.setPreferredOrientations(
        next
            ? const [
                DeviceOrientation.landscapeLeft,
                DeviceOrientation.landscapeRight,
              ]
            : DeviceOrientation.values,
      ),
    );
  }

  void _resetBoardLandscapeMode() {
    if (!_boardLandscapeMode) return;
    _boardLandscapeMode = false;
    unawaited(SystemChrome.setPreferredOrientations(DeviceOrientation.values));
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) return;
    unawaited(
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      ),
    );
  }

  Widget _buildActiveWorkspace(
    _TeamManagementWorkspace workspace,
    bool readOnly,
  ) {
    switch (workspace) {
      case _TeamManagementWorkspace.board:
        return _TacticsBoardPanel(
          players: _players,
          tacticBoards: _syncedTacticBoards(),
          activeTacticBoardId: _activeTacticBoardId,
          playerPlacements: _playerPlacements,
          tacticLines: _tacticLines,
          draftTacticLine: _draftTacticLine,
          boardMode: _boardMode,
          landscapeMode: _boardLandscapeMode,
          readOnly: readOnly,
          onTacticBoardSelected: _selectTacticBoard,
          onAddTacticBoard: _addTacticBoard,
          onDuplicateTacticBoard: _duplicateTacticBoard,
          onRenameTacticBoard: _renameTacticBoard,
          onDeleteTacticBoard: () => unawaited(_deleteActiveTacticBoard()),
          onPlayerPlaced: _placePlayerOnBoard,
          onPlayerMoveStarted: _beginPlayerPlacementUndo,
          onPlayerMoveFinished: _finishPlayerPlacementUndo,
          onBoardModeChanged: _changeBoardMode,
          canUndoTacticAction: _tacticUndoStack.isNotEmpty,
          onUndoTacticAction: _undoLastTacticAction,
          onTacticLineStarted: _startTacticLine,
          onTacticLineUpdated: _updateTacticLine,
          onTacticLineFinished: _finishTacticLine,
          onClearTacticLines: _clearTacticLines,
        );
    }
  }
}

class _WorkspaceScreenHeader extends StatelessWidget {
  final VoidCallback onBackToMenu;
  final bool landscapeMode;
  final VoidCallback onToggleLandscape;

  const _WorkspaceScreenHeader({
    required this.onBackToMenu,
    required this.landscapeMode,
    required this.onToggleLandscape,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        BackButton(
          key: const ValueKey('team-workspace-back'),
          onPressed: onBackToMenu,
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            l10n.teamManagementWorkspaceBoardTab,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        AppBarActionButton.label(
          key: const ValueKey('team-board-landscape-toggle'),
          icon: Icon(
            landscapeMode
                ? Icons.stay_current_portrait_outlined
                : Icons.stay_current_landscape_outlined,
          ),
          label: landscapeMode
              ? l10n.teamManagementBoardPortraitButton
              : l10n.teamManagementBoardLandscapeButton,
          tooltip: landscapeMode
              ? l10n.teamManagementBoardPortraitButton
              : l10n.teamManagementBoardLandscapeButton,
          onPressed: onToggleLandscape,
          margin: EdgeInsets.zero,
          maxLabelWidth: 88,
        ),
      ],
    );
  }
}

class _TeamManagementHeader extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onOpenBoard;
  final VoidCallback? onManageCompetitions;

  const _TeamManagementHeader({
    required this.onBack,
    required this.onOpenBoard,
    required this.onManageCompetitions,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Row(
      children: [
        BackButton(
          onPressed: onBack,
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.teamManagementTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        AppBarActionButton.label(
          key: const ValueKey('team-header-board'),
          icon: const Icon(Icons.account_tree_outlined),
          label: l10n.teamManagementWorkspaceBoardTab,
          tooltip: l10n.teamManagementWorkspaceBoardTab,
          onPressed: onOpenBoard,
          margin: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
          maxLabelWidth: 96,
        ),
        if (onManageCompetitions != null)
          AppBarActionButton.label(
            key: const ValueKey('team-header-competition'),
            icon: const Icon(Icons.emoji_events_outlined),
            label: l10n.matchCompetitionOpenButton,
            tooltip: l10n.matchCompetitionOpenButton,
            onPressed: onManageCompetitions,
            margin: EdgeInsets.zero,
            maxLabelWidth: 132,
          ),
      ],
    );
  }
}

class _TeamManagementSectionSwitcher extends StatelessWidget {
  final _TeamManagementSection selectedSection;
  final ValueChanged<_TeamManagementSection> onSectionChanged;

  const _TeamManagementSectionSwitcher({
    required this.selectedSection,
    required this.onSectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SegmentedButton<_TeamManagementSection>(
      key: const ValueKey('team-management-section-switcher'),
      showSelectedIcon: false,
      segments: [
        ButtonSegment<_TeamManagementSection>(
          value: _TeamManagementSection.players,
          icon: const Icon(Icons.groups_2_outlined),
          label: Text(
            l10n.teamManagementPlayerSectionTab,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        ButtonSegment<_TeamManagementSection>(
          value: _TeamManagementSection.matches,
          icon: const Icon(Icons.event_note_outlined),
          label: Text(
            l10n.teamManagementMatchSectionTab,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
      selected: {selectedSection},
      onSelectionChanged: (selection) => onSectionChanged(selection.single),
    );
  }
}

class _MatchManagementPanel extends StatelessWidget {
  final bool matchActionsEnabled;
  final bool recordsEnabled;
  final VoidCallback onRecordMatch;
  final VoidCallback onOpenMatchRecords;
  final VoidCallback? onOpenMatchStats;
  final VoidCallback onOpenSchedule;

  const _MatchManagementPanel({
    required this.matchActionsEnabled,
    required this.recordsEnabled,
    required this.onRecordMatch,
    required this.onOpenMatchRecords,
    required this.onOpenMatchStats,
    required this.onOpenSchedule,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _StructuredSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelTitle(
            icon: Icons.event_note_outlined,
            title: l10n.teamManagementMatchSectionTitle,
            helper: l10n.teamManagementMatchSectionHelper,
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 640 ? 2 : 1;
              final gap = AppSpacing.sm * (columns - 1);
              final width = (constraints.maxWidth - gap) / columns;
              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  SizedBox(
                    width: width,
                    child: FilledButton.icon(
                      onPressed: matchActionsEnabled ? onRecordMatch : null,
                      icon: const Icon(Icons.edit_note_outlined),
                      label: Text(l10n.matchHubRecordButton),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _InlineActionButton(
                      onPressed: recordsEnabled ? onOpenMatchRecords : null,
                      icon: Icons.fact_check_outlined,
                      label: l10n.matchRecordsOpenButton,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _InlineActionButton(
                      onPressed: onOpenMatchStats,
                      icon: Icons.analytics_outlined,
                      label: l10n.matchHubStatsButton,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _InlineActionButton(
                      onPressed: onOpenSchedule,
                      icon: Icons.calendar_month_outlined,
                      label: l10n.clubScheduleTitle,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TacticsBoardPanel extends StatelessWidget {
  final List<ManagedTeamPlayer> players;
  final List<ManagedTacticBoard> tacticBoards;
  final String activeTacticBoardId;
  final Map<String, ManagedPlayerPlacement> playerPlacements;
  final List<ManagedTacticLine> tacticLines;
  final ManagedTacticLine? draftTacticLine;
  final _TacticBoardMode boardMode;
  final bool landscapeMode;
  final bool readOnly;
  final ValueChanged<String> onTacticBoardSelected;
  final VoidCallback onAddTacticBoard;
  final VoidCallback onDuplicateTacticBoard;
  final void Function(String boardId, String title) onRenameTacticBoard;
  final VoidCallback onDeleteTacticBoard;
  final _PlayerBoardDropCallback onPlayerPlaced;
  final ValueChanged<String> onPlayerMoveStarted;
  final VoidCallback onPlayerMoveFinished;
  final ValueChanged<_TacticBoardMode> onBoardModeChanged;
  final bool canUndoTacticAction;
  final VoidCallback onUndoTacticAction;
  final ValueChanged<Offset> onTacticLineStarted;
  final ValueChanged<Offset> onTacticLineUpdated;
  final VoidCallback onTacticLineFinished;
  final VoidCallback onClearTacticLines;

  const _TacticsBoardPanel({
    required this.players,
    required this.tacticBoards,
    required this.activeTacticBoardId,
    required this.playerPlacements,
    required this.tacticLines,
    required this.draftTacticLine,
    required this.boardMode,
    required this.landscapeMode,
    required this.readOnly,
    required this.onTacticBoardSelected,
    required this.onAddTacticBoard,
    required this.onDuplicateTacticBoard,
    required this.onRenameTacticBoard,
    required this.onDeleteTacticBoard,
    required this.onPlayerPlaced,
    required this.onPlayerMoveStarted,
    required this.onPlayerMoveFinished,
    required this.onBoardModeChanged,
    required this.canUndoTacticAction,
    required this.onUndoTacticAction,
    required this.onTacticLineStarted,
    required this.onTacticLineUpdated,
    required this.onTacticLineFinished,
    required this.onClearTacticLines,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final activeBoard = TeamManagementService.activeTacticBoard(
          tacticBoards,
          activeTacticBoardId,
        );
        final activeBoardIndex = tacticBoards.indexWhere(
          (board) => board.id == activeBoard.id,
        );
        final l10n = AppLocalizations.of(context)!;
        final detailPanel = _TacticDetailPanel(
          activeTitle: _tacticBoardDisplayTitle(
            l10n,
            activeBoard,
            activeBoardIndex < 0 ? 0 : activeBoardIndex,
          ),
          activeMeta: l10n.teamManagementTacticBoardPageMeta(
            activeBoard.playerPlacements.length,
            activeBoard.tacticLines.length,
          ),
          players: players,
          playerPlacements: playerPlacements,
          tacticLines: tacticLines,
          draftTacticLine: draftTacticLine,
          boardMode: boardMode,
          landscapeMode: landscapeMode,
          readOnly: readOnly,
          canUndoTacticAction: canUndoTacticAction,
          onPlayerPlaced: onPlayerPlaced,
          onPlayerMoveStarted: onPlayerMoveStarted,
          onPlayerMoveFinished: onPlayerMoveFinished,
          onOpenTacticList: () => _showTacticListSheet(context),
          onUndoTacticAction: onUndoTacticAction,
          onBoardModeChanged: onBoardModeChanged,
          onTacticLineStarted: onTacticLineStarted,
          onTacticLineUpdated: onTacticLineUpdated,
          onTacticLineFinished: onTacticLineFinished,
          onClearTacticLines: onClearTacticLines,
        );
        if (constraints.maxHeight.isFinite) return detailPanel;
        return SizedBox(height: 560, child: detailPanel);
      },
    );
  }

  void _showTacticListSheet(BuildContext context) {
    final heightFactor = landscapeMode ? 0.86 : 0.72;
    final sheetHeight = MediaQuery.sizeOf(context).height * heightFactor;
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        void closeThen(VoidCallback action) {
          Navigator.of(sheetContext).pop();
          WidgetsBinding.instance.addPostFrameCallback((_) => action());
        }

        return SizedBox(
          height: sheetHeight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.xs,
              AppSpacing.sm,
              AppSpacing.sm,
            ),
            child: _TacticListPanel(
              boards: tacticBoards,
              activeBoardId: activeTacticBoardId,
              readOnly: readOnly,
              vertical: true,
              onBoardSelected: (boardId) {
                closeThen(() => onTacticBoardSelected(boardId));
              },
              onAddBoard: () {
                closeThen(onAddTacticBoard);
              },
              onDuplicateBoard: () {
                closeThen(onDuplicateTacticBoard);
              },
              onRenameBoard: (boardId, title) {
                closeThen(() => onRenameTacticBoard(boardId, title));
              },
              onDeleteBoard: () {
                closeThen(onDeleteTacticBoard);
              },
            ),
          ),
        );
      },
    );
  }
}

class _TacticListPanel extends StatelessWidget {
  final List<ManagedTacticBoard> boards;
  final String activeBoardId;
  final bool readOnly;
  final bool vertical;
  final ValueChanged<String> onBoardSelected;
  final VoidCallback onAddBoard;
  final VoidCallback onDuplicateBoard;
  final void Function(String boardId, String title) onRenameBoard;
  final VoidCallback onDeleteBoard;

  const _TacticListPanel({
    required this.boards,
    required this.activeBoardId,
    required this.readOnly,
    required this.vertical,
    required this.onBoardSelected,
    required this.onAddBoard,
    required this.onDuplicateBoard,
    required this.onRenameBoard,
    required this.onDeleteBoard,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final activeBoard = TeamManagementService.activeTacticBoard(
      boards,
      activeBoardId,
    );
    final activeBoardIndex = boards.indexWhere(
      (board) => board.id == activeBoard.id,
    );
    final boardList = ListView.separated(
      scrollDirection: vertical ? Axis.vertical : Axis.horizontal,
      shrinkWrap: !vertical,
      itemCount: boards.length,
      separatorBuilder: (_, __) => SizedBox(
        width: vertical ? 0 : AppSpacing.xs,
        height: vertical ? AppSpacing.xs : 0,
      ),
      itemBuilder: (context, index) {
        final board = boards[index];
        return _TacticListItem(
          index: index,
          board: board,
          selected: board.id == activeBoard.id,
          vertical: vertical,
          onTap: () => onBoardSelected(board.id),
        );
      },
    );
    return _StructuredSection(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.list_alt_outlined, color: scheme.primary, size: 20),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.teamManagementTacticBookTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      l10n.teamManagementTacticBookPageCount(boards.length),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                key: const ValueKey('team-tactic-board-add'),
                onPressed: readOnly ? null : onAddBoard,
                icon: const Icon(Icons.add_outlined),
                label: Text(l10n.teamManagementTacticBoardAddButton),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          if (vertical)
            Expanded(child: boardList)
          else
            SizedBox(height: 72, child: boardList),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xxs,
            children: [
              _InlineActionButton(
                key: const ValueKey('team-tactic-board-duplicate'),
                onPressed: readOnly ? null : onDuplicateBoard,
                icon: Icons.copy_all_outlined,
                label: l10n.teamManagementTacticBoardDuplicateButton,
              ),
              _InlineActionButton(
                key: const ValueKey('team-tactic-board-rename'),
                onPressed: readOnly
                    ? null
                    : () => unawaited(
                          _showRenameDialog(
                            context,
                            activeBoard,
                            activeBoardIndex < 0 ? 0 : activeBoardIndex,
                          ),
                        ),
                icon: Icons.drive_file_rename_outline,
                label: l10n.teamManagementTacticBoardRenameButton,
              ),
              _InlineActionButton(
                key: const ValueKey('team-tactic-board-delete'),
                onPressed:
                    readOnly || boards.length <= 1 ? null : onDeleteBoard,
                icon: Icons.delete_outline,
                label: l10n.teamManagementTacticBoardDeleteButton,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showRenameDialog(
    BuildContext context,
    ManagedTacticBoard board,
    int boardIndex,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(
      text: _tacticBoardDisplayTitle(l10n, board, boardIndex),
    );
    final title = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.teamManagementTacticBoardRenameDialogTitle),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: l10n.teamManagementTacticBoardNameLabel,
            ),
            onSubmitted: (value) => Navigator.of(context).pop(value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: Text(l10n.teamManagementTacticBoardRenameSaveButton),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (title == null) return;
    onRenameBoard(board.id, title);
  }
}

class _TacticDetailHeader extends StatelessWidget {
  final String title;
  final String meta;
  final bool canUndo;
  final VoidCallback onOpenList;
  final VoidCallback onUndo;

  const _TacticDetailHeader({
    required this.title,
    required this.meta,
    required this.canUndo,
    required this.onOpenList,
    required this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      children: [
        Icon(Icons.account_tree_outlined, color: scheme.primary, size: 20),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                meta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        AppBarActionButton.label(
          key: const ValueKey('team-tactic-board-list-open'),
          icon: const Icon(Icons.list_alt_outlined),
          label: l10n.teamManagementTacticBookTitle,
          tooltip: l10n.teamManagementTacticBookTitle,
          onPressed: onOpenList,
          maxLabelWidth: 96,
        ),
        AppBarActionButton.label(
          key: const ValueKey('team-tactic-board-undo'),
          icon: const Icon(Icons.undo_outlined),
          label: l10n.undo,
          tooltip: l10n.undo,
          onPressed: canUndo ? onUndo : null,
          margin: EdgeInsets.zero,
          maxLabelWidth: 76,
        ),
      ],
    );
  }
}

class _TacticDetailPanel extends StatelessWidget {
  final String activeTitle;
  final String activeMeta;
  final List<ManagedTeamPlayer> players;
  final Map<String, ManagedPlayerPlacement> playerPlacements;
  final List<ManagedTacticLine> tacticLines;
  final ManagedTacticLine? draftTacticLine;
  final _TacticBoardMode boardMode;
  final bool landscapeMode;
  final bool readOnly;
  final bool canUndoTacticAction;
  final _PlayerBoardDropCallback onPlayerPlaced;
  final ValueChanged<String> onPlayerMoveStarted;
  final VoidCallback onPlayerMoveFinished;
  final VoidCallback onOpenTacticList;
  final VoidCallback onUndoTacticAction;
  final ValueChanged<_TacticBoardMode> onBoardModeChanged;
  final ValueChanged<Offset> onTacticLineStarted;
  final ValueChanged<Offset> onTacticLineUpdated;
  final VoidCallback onTacticLineFinished;
  final VoidCallback onClearTacticLines;

  const _TacticDetailPanel({
    required this.activeTitle,
    required this.activeMeta,
    required this.players,
    required this.playerPlacements,
    required this.tacticLines,
    required this.draftTacticLine,
    required this.boardMode,
    required this.landscapeMode,
    required this.readOnly,
    required this.canUndoTacticAction,
    required this.onPlayerPlaced,
    required this.onPlayerMoveStarted,
    required this.onPlayerMoveFinished,
    required this.onOpenTacticList,
    required this.onUndoTacticAction,
    required this.onBoardModeChanged,
    required this.onTacticLineStarted,
    required this.onTacticLineUpdated,
    required this.onTacticLineFinished,
    required this.onClearTacticLines,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final pitch = _TacticsPitch(
      players: players,
      playerPlacements: playerPlacements,
      tacticLines: tacticLines,
      draftTacticLine: draftTacticLine,
      boardMode: boardMode,
      landscapeMode: landscapeMode,
      readOnly: readOnly,
      onPlayerPlaced: onPlayerPlaced,
      onPlayerMoveStarted: onPlayerMoveStarted,
      onPlayerMoveFinished: onPlayerMoveFinished,
      onTacticLineStarted: onTacticLineStarted,
      onTacticLineUpdated: onTacticLineUpdated,
      onTacticLineFinished: onTacticLineFinished,
    );
    return _StructuredSection(
      accent: scheme.primary,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TacticDetailHeader(
            title: activeTitle,
            meta: activeMeta,
            canUndo: canUndoTacticAction,
            onOpenList: onOpenTacticList,
            onUndo: onUndoTacticAction,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (landscapeMode)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 7,
                  child: _BoardModeToolbar(
                    mode: boardMode,
                    tacticLineCount: tacticLines.length,
                    readOnly: readOnly,
                    compact: true,
                    onModeChanged: onBoardModeChanged,
                    onClearTacticLines: onClearTacticLines,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 5,
                  child: _BoardPlayerTray(
                    players: players,
                    playerPlacements: playerPlacements,
                    readOnly: readOnly,
                    compact: true,
                  ),
                ),
              ],
            )
          else ...[
            _BoardModeToolbar(
              mode: boardMode,
              tacticLineCount: tacticLines.length,
              readOnly: readOnly,
              compact: false,
              onModeChanged: onBoardModeChanged,
              onClearTacticLines: onClearTacticLines,
            ),
            const SizedBox(height: AppSpacing.sm),
            _BoardPlayerTray(
              players: players,
              playerPlacements: playerPlacements,
              readOnly: readOnly,
              compact: false,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Expanded(child: pitch),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.teamManagementFormationDropHint,
            maxLines: landscapeMode ? 1 : 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TacticListItem extends StatelessWidget {
  final int index;
  final ManagedTacticBoard board;
  final bool selected;
  final bool vertical;
  final VoidCallback onTap;

  const _TacticListItem({
    required this.index,
    required this.board,
    required this.selected,
    required this.vertical,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final foreground = selected ? scheme.primary : scheme.onSurface;
    final title = _tacticBoardDisplayTitle(l10n, board, index);
    final borderColor = selected
        ? scheme.primary
        : AppSurfaces.borderColor(scheme, theme.brightness);
    return Material(
      color: selected
          ? scheme.primary.withValues(alpha: 0.08)
          : scheme.surface.withValues(alpha: 0.72),
      borderRadius: AppRadius.small,
      child: InkWell(
        onTap: selected ? null : onTap,
        borderRadius: AppRadius.small,
        child: Container(
          width: vertical ? double.infinity : 178,
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            borderRadius: AppRadius.small,
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? scheme.primary
                      : scheme.surfaceContainerHighest,
                  borderRadius: AppRadius.small,
                ),
                child: Text(
                  (index + 1).toString().padLeft(2, '0'),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: selected ? scheme.onPrimary : scheme.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.teamManagementTacticBoardPageMeta(
                        board.playerPlacements.length,
                        board.tacticLines.length,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: selected
                            ? scheme.primary.withValues(alpha: 0.76)
                            : scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
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
}

String _tacticBoardDisplayTitle(
  AppLocalizations l10n,
  ManagedTacticBoard board,
  int index,
) {
  final normalizedIndex = index < 0 ? 0 : index;
  final title = board.title.trim();
  final legacyDefaultTitle = TeamManagementService.defaultTacticBoardTitle(
    normalizedIndex + 1,
  );
  if (title.isEmpty || title == legacyDefaultTitle) {
    return l10n.teamManagementTacticBoardDefaultTitle(normalizedIndex + 1);
  }
  return title;
}

class _BoardModeToolbar extends StatelessWidget {
  final _TacticBoardMode mode;
  final int tacticLineCount;
  final bool readOnly;
  final bool compact;
  final ValueChanged<_TacticBoardMode> onModeChanged;
  final VoidCallback onClearTacticLines;

  const _BoardModeToolbar({
    required this.mode,
    required this.tacticLineCount,
    required this.readOnly,
    required this.compact,
    required this.onModeChanged,
    required this.onClearTacticLines,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tools = [
      (
        mode: _TacticBoardMode.assign,
        icon: Icons.open_with_outlined,
        label: l10n.teamManagementBoardMovePlayersMode,
      ),
      (
        mode: _TacticBoardMode.movement,
        icon: Icons.timeline_outlined,
        label: l10n.teamManagementBoardMovementMode,
      ),
      (
        mode: _TacticBoardMode.press,
        icon: Icons.keyboard_double_arrow_up_outlined,
        label: l10n.teamManagementBoardPressMode,
      ),
      (
        mode: _TacticBoardMode.zone,
        icon: Icons.crop_free_outlined,
        label: l10n.teamManagementBoardZoneMode,
      ),
    ];
    return Wrap(
      spacing: compact ? AppSpacing.xs : AppSpacing.sm,
      runSpacing: compact ? AppSpacing.xxs : AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final tool in tools)
          _BoardModeButton(
            icon: tool.icon,
            label: tool.label,
            selected: mode == tool.mode,
            compact: compact,
            onTap: readOnly ? null : () => onModeChanged(tool.mode),
          ),
        _InlineActionButton(
          onPressed:
              readOnly || tacticLineCount == 0 ? null : onClearTacticLines,
          icon: Icons.cleaning_services_outlined,
          label: l10n.teamManagementBoardClearMarkersButton,
        ),
        Text(
          l10n.teamManagementTacticLinesCount(tacticLineCount),
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _InlineActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;

  const _InlineActionButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxs,
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        textStyle: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: AppSpacing.xxs),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _BoardModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool compact;
  final VoidCallback? onTap;

  const _BoardModeButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final foreground = selected ? scheme.onPrimary : scheme.onSurface;
    return Material(
      color: selected ? scheme.primary : Colors.transparent,
      borderRadius: AppRadius.small,
      child: InkWell(
        onTap: selected ? null : onTap,
        borderRadius: AppRadius.small,
        child: Container(
          constraints: BoxConstraints(
            minHeight: compact ? 32 : 36,
            minWidth: compact ? 68 : 88,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? AppSpacing.xxs : AppSpacing.xs,
            vertical: compact ? AppSpacing.xxs : AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.small,
            color: selected ? scheme.primary : Colors.transparent,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: compact ? 15 : 17, color: foreground),
              const SizedBox(width: AppSpacing.xxs),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w900,
                  fontSize: compact ? 11 : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BoardPlayerTray extends StatelessWidget {
  final List<ManagedTeamPlayer> players;
  final Map<String, ManagedPlayerPlacement> playerPlacements;
  final bool readOnly;
  final bool compact;

  const _BoardPlayerTray({
    required this.players,
    required this.playerPlacements,
    required this.readOnly,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (players.isEmpty) {
      return SizedBox(
        height: 40,
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(l10n.teamManagementPlayerTrayEmpty),
        ),
      );
    }
    final assignedPlayerIds = playerPlacements.keys.toSet();
    return SizedBox(
      height: compact ? 32 : 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: players.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          final player = players[index];
          final chip = _BoardPlayerChip(
            player: player,
            assigned: assignedPlayerIds.contains(player.id),
            compact: compact,
          );
          if (readOnly) return chip;
          return Draggable<String>(
            data: player.id,
            dragAnchorStrategy: pointerDragAnchorStrategy,
            feedback: Material(
              color: Colors.transparent,
              child: _BoardPlayerChip(
                player: player,
                assigned: assignedPlayerIds.contains(player.id),
                elevated: true,
                compact: compact,
              ),
            ),
            childWhenDragging: Opacity(opacity: 0.42, child: chip),
            child: chip,
          );
        },
      ),
    );
  }
}

class _BoardPlayerChip extends StatelessWidget {
  final ManagedTeamPlayer player;
  final bool assigned;
  final bool elevated;
  final bool compact;

  const _BoardPlayerChip({
    required this.player,
    required this.assigned,
    this.elevated = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: assigned
          ? scheme.primaryContainer
          : scheme.surfaceContainerHighest.withValues(alpha: 0.72),
      elevation: elevated ? 8 : 0,
      borderRadius: AppRadius.small,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.drag_indicator,
              size: compact ? 14 : 16,
              color: assigned ? scheme.onPrimaryContainer : scheme.primary,
            ),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              _playerDisplayName(player),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                color: assigned ? scheme.onPrimaryContainer : scheme.onSurface,
                fontWeight: FontWeight.w900,
                fontSize: compact ? 11 : 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TacticsPitch extends StatelessWidget {
  final List<ManagedTeamPlayer> players;
  final Map<String, ManagedPlayerPlacement> playerPlacements;
  final List<ManagedTacticLine> tacticLines;
  final ManagedTacticLine? draftTacticLine;
  final _TacticBoardMode boardMode;
  final bool landscapeMode;
  final bool readOnly;
  final _PlayerBoardDropCallback onPlayerPlaced;
  final ValueChanged<String> onPlayerMoveStarted;
  final VoidCallback onPlayerMoveFinished;
  final ValueChanged<Offset> onTacticLineStarted;
  final ValueChanged<Offset> onTacticLineUpdated;
  final VoidCallback onTacticLineFinished;

  const _TacticsPitch({
    required this.players,
    required this.playerPlacements,
    required this.tacticLines,
    required this.draftTacticLine,
    required this.boardMode,
    required this.landscapeMode,
    required this.readOnly,
    required this.onPlayerPlaced,
    required this.onPlayerMoveStarted,
    required this.onPlayerMoveFinished,
    required this.onTacticLineStarted,
    required this.onTacticLineUpdated,
    required this.onTacticLineFinished,
  });

  @override
  Widget build(BuildContext context) {
    final playerById = {for (final player in players) player.id: player};
    return LayoutBuilder(
      builder: (context, outerConstraints) {
        final targetAspectRatio = landscapeMode
            ? 16 / 9
            : outerConstraints.maxWidth >= 600
                ? 1.35
                : 1.05;
        var boardWidth = outerConstraints.maxWidth;
        var boardHeight = boardWidth / targetAspectRatio;
        if (!landscapeMode && boardHeight < 380) {
          boardHeight = 380;
          boardWidth = math.min(boardWidth, boardHeight * targetAspectRatio);
        }
        if (outerConstraints.maxHeight.isFinite &&
            boardHeight > outerConstraints.maxHeight) {
          boardHeight = outerConstraints.maxHeight;
          boardWidth = math.min(
            outerConstraints.maxWidth,
            boardHeight * targetAspectRatio,
          );
        }
        return Center(
          child: SizedBox(
            width: boardWidth,
            height: boardHeight,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final markerWidth = landscapeMode
                    ? 46.0
                    : constraints.maxWidth < 420
                        ? 50.0
                        : 56.0;
                final markerHeight = markerWidth * 0.78;
                Offset normalizeFromGlobal(Offset globalPosition) {
                  final renderObject = context.findRenderObject();
                  if (renderObject is! RenderBox) {
                    return Offset.zero;
                  }
                  return _normalizeBoardPoint(
                    renderObject.globalToLocal(globalPosition),
                    constraints.biggest,
                  );
                }

                return DragTarget<String>(
                  onWillAcceptWithDetails: (details) {
                    return !readOnly &&
                        boardMode == _TacticBoardMode.assign &&
                        playerById.containsKey(details.data);
                  },
                  onAcceptWithDetails: readOnly
                      ? null
                      : (details) {
                          onPlayerMoveStarted(details.data);
                          onPlayerPlaced(
                            playerId: details.data,
                            point: normalizeFromGlobal(details.offset),
                          );
                          onPlayerMoveFinished();
                        },
                  builder: (context, candidateData, rejectedData) {
                    final dropHighlighted = candidateData.isNotEmpty;
                    return ClipRRect(
                      borderRadius: AppRadius.surface,
                      child: GestureDetector(
                        key: const ValueKey('team-tactics-board-pitch'),
                        behavior: HitTestBehavior.opaque,
                        onPanStart:
                            !readOnly && boardMode != _TacticBoardMode.assign
                                ? (details) => onTacticLineStarted(
                                      _normalizeBoardPoint(
                                        details.localPosition,
                                        constraints.biggest,
                                      ),
                                    )
                                : null,
                        onPanUpdate:
                            !readOnly && boardMode != _TacticBoardMode.assign
                                ? (details) => onTacticLineUpdated(
                                      _normalizeBoardPoint(
                                        details.localPosition,
                                        constraints.biggest,
                                      ),
                                    )
                                : null,
                        onPanEnd:
                            !readOnly && boardMode != _TacticBoardMode.assign
                                ? (_) => onTacticLineFinished()
                                : null,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CustomPaint(painter: _PitchPainter()),
                            if (dropHighlighted)
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.62),
                                    width: 3,
                                  ),
                                ),
                              ),
                            CustomPaint(
                              painter: _TacticLinesPainter(
                                lines: tacticLines,
                                draftLine: draftTacticLine,
                              ),
                            ),
                            for (final placement in playerPlacements.values)
                              if (playerById[placement.playerId] != null)
                                Positioned(
                                  left: (constraints.maxWidth * placement.x) -
                                      (markerWidth / 2),
                                  top: (constraints.maxHeight * placement.y) -
                                      (markerHeight / 2),
                                  width: markerWidth,
                                  height: markerHeight,
                                  child: _BoardPlacedPlayer(
                                    player: playerById[placement.playerId]!,
                                    draggable: !readOnly &&
                                        boardMode == _TacticBoardMode.assign,
                                    onMoveStarted: () =>
                                        onPlayerMoveStarted(placement.playerId),
                                    onMoveFinished: onPlayerMoveFinished,
                                    onMoveToGlobal: (globalPosition) {
                                      onPlayerPlaced(
                                        playerId: placement.playerId,
                                        point: normalizeFromGlobal(
                                          globalPosition,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _BoardPlacedPlayer extends StatelessWidget {
  final ManagedTeamPlayer player;
  final bool draggable;
  final VoidCallback onMoveStarted;
  final VoidCallback onMoveFinished;
  final ValueChanged<Offset> onMoveToGlobal;

  const _BoardPlacedPlayer({
    required this.player,
    required this.draggable,
    required this.onMoveStarted,
    required this.onMoveFinished,
    required this.onMoveToGlobal,
  });

  @override
  Widget build(BuildContext context) {
    final marker = _PitchPlayerMarker(player: player);
    if (!draggable) return marker;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (details) {
        onMoveStarted();
        onMoveToGlobal(details.globalPosition);
      },
      onPanUpdate: (details) => onMoveToGlobal(details.globalPosition),
      onPanEnd: (_) => onMoveFinished(),
      onPanCancel: onMoveFinished,
      child: marker,
    );
  }
}

class _PitchPlayerMarker extends StatelessWidget {
  final ManagedTeamPlayer player;

  const _PitchPlayerMarker({required this.player});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _playerRoleAccent(player.role);
    final condition = _playerConditionAccent(player.condition);
    return Material(
      color: Colors.white,
      elevation: 8,
      borderRadius: AppRadius.small,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.small,
          border: Border.all(color: accent, width: 2),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxs,
          vertical: 2,
        ),
        child: Stack(
          children: [
            PositionedDirectional(
              top: 0,
              end: 0,
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: condition,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
            Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      player.number.trim().isEmpty
                          ? teamPlayerRoleShortLabel(player.role)
                          : player.number.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      _playerInitialLabel(player),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF111827),
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Offset _normalizeBoardPoint(Offset localPosition, Size size) {
  final width = size.width == 0 ? 1.0 : size.width;
  final height = size.height == 0 ? 1.0 : size.height;
  return Offset(
    TeamManagementService.normalizeBoardCoordinate(localPosition.dx / width),
    TeamManagementService.normalizeBoardCoordinate(localPosition.dy / height),
  );
}

const List<double> _teamBoardLaneFractions = <double>[0.18, 0.38, 0.62, 0.82];

class _PitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, backgroundPaint);

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

    _drawTacticalOverlay(canvas, fieldRect);

    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, math.min(size.width, size.height) * 0.004);
    final center = fieldRect.center;
    canvas.drawRRect(
      RRect.fromRectAndRadius(fieldRect, const Radius.circular(12)),
      line,
    );
    canvas.drawLine(
      Offset(center.dx, fieldRect.top),
      Offset(center.dx, fieldRect.bottom),
      line,
    );
    canvas.drawCircle(
      center,
      math.min(42, fieldRect.shortestSide * 0.13),
      line,
    );
    final boxDepth = math.min(fieldRect.width * 0.17, 92.0);
    final boxHeight = math.min(fieldRect.height * 0.42, 136.0);
    final boxTop = center.dy - boxHeight / 2;
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
        center.dy - goalHeight / 2,
        goalDepth,
        goalHeight,
      ),
      line,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        fieldRect.right,
        center.dy - goalHeight / 2,
        goalDepth,
        goalHeight,
      ),
      line,
    );
    final spotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.72)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 2.6, spotPaint);
  }

  void _drawTacticalOverlay(Canvas canvas, Rect fieldRect) {
    final halfSpacePaint = Paint()
      ..color = const Color(0xFFFFF59D).withValues(alpha: 0.075)
      ..style = PaintingStyle.fill;
    final centralPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..style = PaintingStyle.fill;
    final laneYs = _teamBoardLaneFractions
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
      _drawDashedGuide(
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
      _drawDashedGuide(
        canvas,
        Offset(fieldRect.left, y),
        Offset(fieldRect.right, y),
        lanePaint,
        dash: 9,
        gap: 7,
      );
    }
  }

  void _drawDashedGuide(
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
    var covered = 0.0;
    while (covered < distance) {
      final segmentStart = start + direction * covered;
      final segmentEnd = start + direction * math.min(covered + dash, distance);
      canvas.drawLine(segmentStart, segmentEnd, paint);
      covered += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TacticLinesPainter extends CustomPainter {
  final List<ManagedTacticLine> lines;
  final ManagedTacticLine? draftLine;

  const _TacticLinesPainter({
    required this.lines,
    required this.draftLine,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final draft = draftLine;
    for (final line in lines.where(_isZoneMarker)) {
      _drawZone(canvas, size, line, draft: false);
    }
    if (draft != null && _isZoneMarker(draft)) {
      _drawZone(canvas, size, draft, draft: true);
    }
    for (final line in lines.where((line) => !_isZoneMarker(line))) {
      _drawMarkerLine(canvas, size, line, draft: false);
    }
    if (draft != null) {
      if (!_isZoneMarker(draft)) {
        _drawMarkerLine(canvas, size, draft, draft: true);
      }
    }
  }

  bool _isZoneMarker(ManagedTacticLine line) {
    return line.type == ManagedTacticLine.typeZone;
  }

  void _drawMarkerLine(
    Canvas canvas,
    Size size,
    ManagedTacticLine line, {
    required bool draft,
  }) {
    final isPress = line.type == ManagedTacticLine.typePress;
    final color = draft
        ? const Color(0xFF60A5FA)
        : isPress
            ? const Color(0xFFF97316)
            : const Color(0xFFFACC15);
    final paint = Paint()
      ..color = color.withValues(alpha: draft ? 0.82 : 0.92)
      ..strokeWidth = isPress ? 3.4 : 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final start = Offset(line.startX * size.width, line.startY * size.height);
    final end = Offset(line.endX * size.width, line.endY * size.height);
    if (isPress) {
      _drawDashedLine(canvas, start, end, paint);
    } else {
      canvas.drawLine(start, end, paint);
    }

    _drawArrowHead(canvas, start, end, paint);
  }

  void _drawArrowHead(Canvas canvas, Offset start, Offset end, Paint paint) {
    final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
    const headLength = 14.0;
    const headAngle = math.pi / 7;
    final path = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(
        end.dx - headLength * math.cos(angle - headAngle),
        end.dy - headLength * math.sin(angle - headAngle),
      )
      ..moveTo(end.dx, end.dy)
      ..lineTo(
        end.dx - headLength * math.cos(angle + headAngle),
        end.dy - headLength * math.sin(angle + headAngle),
      );
    canvas.drawPath(path, paint);
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
  ) {
    const dash = 14.0;
    const gap = 9.0;
    final delta = end - start;
    final distance = delta.distance;
    if (distance == 0) return;
    final direction = delta / distance;
    var traveled = 0.0;
    while (traveled < distance) {
      final segmentStart = start + direction * traveled;
      final segmentEnd =
          start + direction * math.min(traveled + dash, distance);
      canvas.drawLine(segmentStart, segmentEnd, paint);
      traveled += dash + gap;
    }
  }

  void _drawZone(
    Canvas canvas,
    Size size,
    ManagedTacticLine line, {
    required bool draft,
  }) {
    final start = Offset(line.startX * size.width, line.startY * size.height);
    final end = Offset(line.endX * size.width, line.endY * size.height);
    final rect = Rect.fromLTRB(
      math.min(start.dx, end.dx),
      math.min(start.dy, end.dy),
      math.max(start.dx, end.dx),
      math.max(start.dy, end.dy),
    );
    if (rect.width < 2 || rect.height < 2) return;
    final color = draft ? const Color(0xFF60A5FA) : const Color(0xFF38BDF8);
    final fill = Paint()
      ..color = color.withValues(alpha: draft ? 0.18 : 0.22)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = color.withValues(alpha: draft ? 0.86 : 0.92)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _TacticLinesPainter oldDelegate) {
    return oldDelegate.lines != lines || oldDelegate.draftLine != draftLine;
  }
}

class _PlayersPanel extends StatelessWidget {
  final List<ManagedTeamPlayer> players;
  final Map<String, String> lineup;
  final Map<String, ManagedPlayerPlacement> playerPlacements;
  final bool readOnly;
  final VoidCallback onStartPlayerRegistration;
  final ValueChanged<ManagedTeamPlayer> onEditPlayer;
  final ValueChanged<ManagedTeamPlayer> onRemovePlayer;

  const _PlayersPanel({
    required this.players,
    required this.lineup,
    required this.playerPlacements,
    required this.readOnly,
    required this.onStartPlayerRegistration,
    required this.onEditPlayer,
    required this.onRemovePlayer,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _StructuredSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _PanelTitle(
                  icon: Icons.groups_2_outlined,
                  title: l10n.teamManagementPlayersTitle,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 124),
                child: FilledButton.icon(
                  onPressed: readOnly ? null : onStartPlayerRegistration,
                  icon: const Icon(Icons.person_add_alt_outlined, size: 18),
                  label: Text(
                    l10n.teamManagementAddPlayerButton,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (players.isEmpty)
            _InlineEmptyMessage(
              icon: Icons.groups_2_outlined,
              title: l10n.teamManagementNoPlayersTitle,
              body: l10n.teamManagementNoPlayersBody,
            )
          else
            _RosterBoard(
              players: players,
              lineup: lineup,
              playerPlacements: playerPlacements,
              onEditPlayer: onEditPlayer,
              onRemovePlayer: onRemovePlayer,
              readOnly: readOnly,
            ),
        ],
      ),
    );
  }
}

class _PlayerRegistrationScreen extends StatefulWidget {
  final ManagedTeamPlayer? player;
  final bool readOnly;

  const _PlayerRegistrationScreen({
    this.player,
    required this.readOnly,
  });

  @override
  State<_PlayerRegistrationScreen> createState() =>
      _PlayerRegistrationScreenState();
}

class _PlayerRegistrationScreenState extends State<_PlayerRegistrationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _gradeController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  late String _role;
  late String _foot;
  late String _condition;
  String _imageDataUrl = '';
  bool _pickingImage = false;

  @override
  void initState() {
    super.initState();
    final player = widget.player;
    _nameController.text = player?.name ?? '';
    _numberController.text = player?.number ?? '';
    _gradeController.text = player?.grade ?? '';
    _heightController.text = _measurementFieldText(player?.heightCm ?? 0);
    _weightController.text = _measurementFieldText(player?.weightKg ?? 0);
    _noteController.text = player?.note ?? '';
    _role = player?.role ?? ManagedTeamPlayer.roleForward;
    _foot = player?.foot ?? ManagedTeamPlayer.footRight;
    _condition = player?.condition ?? ManagedTeamPlayer.conditionReady;
    _imageDataUrl = player?.imageDataUrl ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _gradeController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (widget.readOnly || _pickingImage) return;
    setState(() => _pickingImage = true);
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 68,
        maxWidth: 768,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      final mimeType = picked.mimeType ?? _imageMimeType(picked.name);
      setState(() {
        _imageDataUrl = 'data:$mimeType;base64,${base64Encode(bytes)}';
      });
    } catch (_) {
      if (!mounted) return;
      AppFeedback.showMessage(
        context,
        text: AppLocalizations.of(context)!.teamManagementPlayerImagePickFailed,
      );
    } finally {
      if (mounted) {
        setState(() => _pickingImage = false);
      }
    }
  }

  void _removeImage() {
    if (widget.readOnly) return;
    setState(() => _imageDataUrl = '');
  }

  void _save() {
    if (widget.readOnly) return;
    final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      AppFeedback.showMessage(context, text: l10n.teamManagementPlayerRequired);
      return;
    }
    final existing = widget.player;
    final player = existing == null
        ? ManagedTeamPlayer.create(
            name: name,
            number: _numberController.text.trim(),
            role: _role,
            foot: _foot,
            condition: _condition,
            note: _noteController.text.trim(),
            grade: _gradeController.text.trim(),
            heightCm: _measurement(_heightController),
            weightKg: _measurement(_weightController),
            imageDataUrl: _imageDataUrl,
          )
        : existing.copyWith(
            name: name,
            number: _numberController.text.trim(),
            role: _role,
            foot: _foot,
            condition: _condition,
            note: _noteController.text.trim(),
            grade: _gradeController.text.trim(),
            heightCm: _measurement(_heightController),
            weightKg: _measurement(_weightController),
            imageDataUrl: _imageDataUrl,
          );
    Navigator.of(context).pop(player);
  }

  double _measurement(TextEditingController controller) {
    return TeamManagementService.normalizeBodyMeasurement(controller.text);
  }

  String _imageMimeType(String name) {
    final normalized = name.toLowerCase();
    if (normalized.endsWith('.png')) return 'image/png';
    if (normalized.endsWith('.webp')) return 'image/webp';
    if (normalized.endsWith('.gif')) return 'image/gif';
    if (normalized.endsWith('.heic')) return 'image/heic';
    if (normalized.endsWith('.heif')) return 'image/heif';
    return 'image/jpeg';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final editing = widget.player != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          editing
              ? l10n.teamManagementPlayerEditTitle
              : l10n.teamManagementPlayerRegistrationTitle,
        ),
        actions: [
          AppBarActionButton.label(
            icon: Icon(
              editing ? Icons.save_outlined : Icons.person_add_alt_outlined,
            ),
            label: editing
                ? l10n.teamManagementUpdatePlayerButton
                : l10n.teamManagementRegisterPlayerButton,
            tooltip: editing
                ? l10n.teamManagementUpdatePlayerButton
                : l10n.teamManagementRegisterPlayerButton,
            onPressed: widget.readOnly ? null : _save,
            maxLabelWidth: 120,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _PlayerRegistrationCard(
              title: l10n.teamManagementPlayerImageTitle,
              icon: Icons.badge_outlined,
              child: _PlayerImagePickerPanel(
                imageDataUrl: _imageDataUrl,
                playerName: _nameController.text,
                playerNumber: _numberController.text,
                playerRole: _role,
                pickingImage: _pickingImage,
                readOnly: widget.readOnly,
                onPickImage: _pickImage,
                onRemoveImage: _imageDataUrl.isEmpty ? null : _removeImage,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _PlayerRegistrationCard(
              title: l10n.teamManagementPlayerBasicInfoTitle,
              icon: Icons.assignment_ind_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 620;
                      final nameField = TextField(
                        key: const ValueKey('team-player-name-field'),
                        controller: _nameController,
                        readOnly: widget.readOnly,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: l10n.teamManagementPlayerNameLabel,
                          hintText: l10n.teamManagementPlayerNameHint,
                        ),
                      );
                      final numberOptions = _withCurrentOption(
                        _playerNumberOptions,
                        _numberController.text.trim(),
                      );
                      final numberField = DropdownButtonFormField<String>(
                        key: const ValueKey('team-player-number-field'),
                        initialValue: _selectedOptionValue(
                          numberOptions,
                          _numberController.text.trim(),
                        ),
                        decoration: InputDecoration(
                          labelText: l10n.teamManagementPlayerNumberLabel,
                        ),
                        items: [
                          for (final number in numberOptions)
                            DropdownMenuItem<String>(
                              value: number,
                              child: Text(
                                number.isEmpty
                                    ? l10n.teamManagementPlayerNumberEmpty
                                    : l10n.teamManagementPlayerNumberPreview(
                                        number,
                                      ),
                              ),
                            ),
                        ],
                        onChanged: widget.readOnly
                            ? null
                            : (value) => setState(
                                  () => _numberController.text = value ?? '',
                                ),
                      );
                      final gradeOptions = _withCurrentOption(
                        _gradeOptions(l10n),
                        _gradeController.text.trim(),
                      );
                      final gradeField = DropdownButtonFormField<String>(
                        key: const ValueKey('team-player-grade-field'),
                        initialValue: _selectedOptionValue(
                          gradeOptions,
                          _gradeController.text.trim(),
                        ),
                        decoration: InputDecoration(
                          labelText: l10n.teamManagementPlayerGradeLabel,
                        ),
                        items: [
                          for (final grade in gradeOptions)
                            DropdownMenuItem<String>(
                              value: grade,
                              child: Text(
                                grade.isEmpty
                                    ? l10n.teamManagementPlayerGradeUnset
                                    : grade,
                              ),
                            ),
                        ],
                        onChanged: widget.readOnly
                            ? null
                            : (value) => setState(
                                  () => _gradeController.text = value ?? '',
                                ),
                      );
                      if (compact) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            nameField,
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              children: [
                                Expanded(child: numberField),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(flex: 2, child: gradeField),
                              ],
                            ),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(flex: 4, child: nameField),
                          const SizedBox(width: AppSpacing.sm),
                          SizedBox(width: 112, child: numberField),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(flex: 3, child: gradeField),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.teamManagementPlayerRoleLabel,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final role in _playerRoles)
                        ChoiceChip(
                          label: Text(teamPlayerRoleLabel(l10n, role)),
                          selected: _role == role,
                          onSelected: widget.readOnly
                              ? null
                              : (_) => setState(() => _role = role),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _PlayerRegistrationCard(
              title: l10n.teamManagementPlayerBodySizeTitle,
              icon: Icons.straighten_outlined,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 520;
                  final heightOptions = _withCurrentOption(
                    _heightOptions,
                    _heightController.text.trim(),
                  );
                  final weightOptions = _withCurrentOption(
                    _weightOptions,
                    _weightController.text.trim(),
                  );
                  final heightField = DropdownButtonFormField<String>(
                    key: const ValueKey('team-player-height-field'),
                    initialValue: _selectedOptionValue(
                      heightOptions,
                      _heightController.text.trim(),
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.teamManagementPlayerHeightLabel,
                    ),
                    items: [
                      for (final height in heightOptions)
                        DropdownMenuItem<String>(
                          value: height,
                          child: Text(
                            _bodySizeOptionLabel(
                              l10n,
                              height,
                              l10n.teamManagementPlayerHeightUnit,
                            ),
                          ),
                        ),
                    ],
                    onChanged: widget.readOnly
                        ? null
                        : (value) => setState(
                              () => _heightController.text = value ?? '',
                            ),
                  );
                  final weightField = DropdownButtonFormField<String>(
                    key: const ValueKey('team-player-weight-field'),
                    initialValue: _selectedOptionValue(
                      weightOptions,
                      _weightController.text.trim(),
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.teamManagementPlayerWeightLabel,
                    ),
                    items: [
                      for (final weight in weightOptions)
                        DropdownMenuItem<String>(
                          value: weight,
                          child: Text(
                            _bodySizeOptionLabel(
                              l10n,
                              weight,
                              l10n.teamManagementPlayerWeightUnit,
                            ),
                          ),
                        ),
                    ],
                    onChanged: widget.readOnly
                        ? null
                        : (value) => setState(
                              () => _weightController.text = value ?? '',
                            ),
                  );
                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        heightField,
                        const SizedBox(height: AppSpacing.sm),
                        weightField,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: heightField),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: weightField),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _PlayerRegistrationCard(
              title: l10n.teamManagementPlayerStatusTitle,
              icon: Icons.monitor_heart_outlined,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 520 ? 2 : 1;
                  final gap = AppSpacing.sm * (columns - 1);
                  final fieldWidth =
                      math.max(150.0, (constraints.maxWidth - gap) / columns);
                  return Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      SizedBox(
                        width: fieldWidth,
                        child: DropdownButtonFormField<String>(
                          initialValue: _foot,
                          decoration: InputDecoration(
                            labelText: l10n.teamManagementPlayerFootLabel,
                          ),
                          items: [
                            for (final foot in _playerFeet)
                              DropdownMenuItem<String>(
                                value: foot,
                                child: Text(teamPlayerFootLabel(l10n, foot)),
                              ),
                          ],
                          onChanged: widget.readOnly
                              ? null
                              : (foot) {
                                  if (foot == null) return;
                                  setState(() => _foot = foot);
                                },
                        ),
                      ),
                      SizedBox(
                        width: fieldWidth,
                        child: DropdownButtonFormField<String>(
                          initialValue: _condition,
                          decoration: InputDecoration(
                            labelText: l10n.teamManagementPlayerConditionLabel,
                          ),
                          items: [
                            for (final condition in _playerConditions)
                              DropdownMenuItem<String>(
                                value: condition,
                                child: Text(
                                  teamPlayerConditionLabel(l10n, condition),
                                ),
                              ),
                          ],
                          onChanged: widget.readOnly
                              ? null
                              : (condition) {
                                  if (condition == null) return;
                                  setState(() => _condition = condition);
                                },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _PlayerRegistrationCard(
              title: l10n.teamManagementPlayerNoteLabel,
              icon: Icons.sticky_note_2_outlined,
              child: TextField(
                key: const ValueKey('team-player-note-field'),
                controller: _noteController,
                readOnly: widget.readOnly,
                minLines: 4,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: l10n.teamManagementPlayerNoteHint,
                  alignLabelWithHint: true,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(AppSpacing.md),
        child: FilledButton.icon(
          key: const ValueKey('team-player-save-button'),
          onPressed: widget.readOnly ? null : _save,
          icon: Icon(
            editing ? Icons.save_outlined : Icons.person_add_alt_outlined,
          ),
          label: Text(
            editing
                ? l10n.teamManagementUpdatePlayerButton
                : l10n.teamManagementRegisterPlayerButton,
          ),
        ),
      ),
    );
  }
}

final List<String> _playerNumberOptions = [
  '',
  for (var number = 1; number <= 99; number++) number.toString(),
];

final List<String> _heightOptions = [
  '',
  for (var height = 110; height <= 205; height++) height.toString(),
];

final List<String> _weightOptions = [
  '',
  for (var weight = 20; weight <= 120; weight++) weight.toString(),
];

List<String> _gradeOptions(AppLocalizations l10n) {
  return [
    '',
    for (var grade = 1; grade <= 6; grade++)
      l10n.teamManagementPlayerElementaryGradeOption(grade),
    for (var grade = 1; grade <= 3; grade++)
      l10n.teamManagementPlayerMiddleGradeOption(grade),
    for (var grade = 1; grade <= 3; grade++)
      l10n.teamManagementPlayerHighGradeOption(grade),
  ];
}

List<String> _withCurrentOption(List<String> options, String currentValue) {
  final current = currentValue.trim();
  if (current.isEmpty || options.contains(current)) return options;
  return [...options, current];
}

String _selectedOptionValue(List<String> options, String value) {
  final trimmed = value.trim();
  return options.contains(trimmed) ? trimmed : '';
}

String _bodySizeOptionLabel(
  AppLocalizations l10n,
  String value,
  String unit,
) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return l10n.teamManagementPlayerBodySizeUnset;
  return '$trimmed$unit';
}

class _PlayerRegistrationCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _PlayerRegistrationCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return _StructuredSection(
      padding: const EdgeInsets.all(AppSpacing.sm),
      accent: scheme.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: scheme.primary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _PlayerImagePickerPanel extends StatelessWidget {
  final String imageDataUrl;
  final String playerName;
  final String playerNumber;
  final String playerRole;
  final bool pickingImage;
  final bool readOnly;
  final VoidCallback onPickImage;
  final VoidCallback? onRemoveImage;

  const _PlayerImagePickerPanel({
    required this.imageDataUrl,
    required this.playerName,
    required this.playerNumber,
    required this.playerRole,
    required this.pickingImage,
    required this.readOnly,
    required this.onPickImage,
    required this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = _playerRoleAccent(playerRole);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _PlayerPhotoFrame(
          imageDataUrl: imageDataUrl,
          playerName: playerName,
          playerNumber: playerNumber,
          playerRole: playerRole,
          size: 96,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                playerName.trim().isEmpty
                    ? l10n.teamManagementPlayerImageEmptyTitle
                    : playerName.trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                [
                  playerNumber.trim().isEmpty
                      ? l10n.teamManagementPlayerNumberEmpty
                      : l10n.teamManagementPlayerNumberPreview(
                          playerNumber.trim(),
                        ),
                  teamPlayerRoleLabel(l10n, playerRole),
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  FilledButton.icon(
                    onPressed: readOnly || pickingImage ? null : onPickImage,
                    icon: pickingImage
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: scheme.onPrimary,
                            ),
                          )
                        : const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(
                      imageDataUrl.trim().isEmpty
                          ? l10n.teamManagementPlayerImageSelectButton
                          : l10n.teamManagementPlayerImageReplaceButton,
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  if (onRemoveImage != null)
                    OutlinedButton.icon(
                      onPressed: readOnly ? null : onRemoveImage,
                      icon: const Icon(Icons.delete_outline),
                      label: Text(
                        l10n.teamManagementPlayerImageRemoveButton,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlayerPhotoFrame extends StatelessWidget {
  final String imageDataUrl;
  final String playerName;
  final String playerNumber;
  final String playerRole;
  final double size;

  const _PlayerPhotoFrame({
    required this.imageDataUrl,
    required this.playerName,
    required this.playerNumber,
    required this.playerRole,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _playerRoleAccent(playerRole);
    final imageProvider = _teamPlayerImageProvider(imageDataUrl);
    final compact = size < 64;
    final borderRadius = AppRadius.small;
    final fallbackText = playerNumber.trim().isEmpty
        ? _playerInitials(playerName)
        : playerNumber.trim();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: borderRadius,
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageProvider == null)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  fallbackText.isEmpty ? '-' : fallbackText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: (compact
                          ? theme.textTheme.titleMedium
                          : theme.textTheme.headlineSmall)
                      ?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  teamPlayerRoleShortLabel(playerRole),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
              ],
            )
          else
            Image(
              image: imageProvider,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Center(
                  child: Text(
                    fallbackText.isEmpty ? '-' : fallbackText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                );
              },
            ),
          if (imageProvider != null)
            PositionedDirectional(
              start: 4,
              end: 4,
              bottom: 4,
              child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 3 : AppSpacing.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.56),
                  borderRadius: AppRadius.small,
                ),
                child: Text(
                  playerNumber.trim().isEmpty
                      ? teamPlayerRoleShortLabel(playerRole)
                      : playerNumber.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RosterBoard extends StatelessWidget {
  final List<ManagedTeamPlayer> players;
  final Map<String, String> lineup;
  final Map<String, ManagedPlayerPlacement> playerPlacements;
  final ValueChanged<ManagedTeamPlayer> onEditPlayer;
  final ValueChanged<ManagedTeamPlayer> onRemovePlayer;
  final bool readOnly;

  const _RosterBoard({
    required this.players,
    required this.lineup,
    required this.playerPlacements,
    required this.onEditPlayer,
    required this.onRemovePlayer,
    required this.readOnly,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final groupedPlayers = {
      for (final role in _playerRoles)
        role: _sortRosterPlayers(
          players.where((player) => player.role == role).toList(),
        ),
    };
    final visibleGroups = _playerRoles
        .where((role) => groupedPlayers[role]!.isNotEmpty)
        .toList(growable: false);
    final placedCount =
        players.where((player) => _assignedCountFor(player) > 0).length;
    final readyCount = players
        .where((player) => player.condition == ManagedTeamPlayer.conditionReady)
        .length;
    final watchCount = players
        .where((player) => player.condition == ManagedTeamPlayer.conditionWatch)
        .length;
    final restCount = players
        .where((player) => player.condition == ManagedTeamPlayer.conditionRest)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.10),
                borderRadius: AppRadius.small,
              ),
              child: Icon(
                Icons.view_module_outlined,
                color: scheme.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                l10n.teamManagementRosterBoardTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _RosterSummaryBar(
          totalCount: players.length,
          placedCount: placedCount,
          readyCount: readyCount,
          watchCount: watchCount,
          restCount: restCount,
        ),
        const SizedBox(height: AppSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 920
                ? 2
                : constraints.maxWidth >= 620
                    ? 2
                    : 1;
            final gap = AppSpacing.sm * (columns - 1);
            final width = (constraints.maxWidth - gap) / columns;
            return Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final role in visibleGroups)
                  SizedBox(
                    width: width,
                    child: _RoleRosterSection(
                      role: role,
                      players: groupedPlayers[role]!,
                      assignedCountFor: _assignedCountFor,
                      onEditPlayer: onEditPlayer,
                      onRemovePlayer: onRemovePlayer,
                      readOnly: readOnly,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  int _assignedCountFor(ManagedTeamPlayer player) {
    if (playerPlacements.containsKey(player.id)) return 1;
    return lineup.values.where((playerId) => playerId == player.id).length;
  }
}

class _RosterSummaryBar extends StatelessWidget {
  final int totalCount;
  final int placedCount;
  final int readyCount;
  final int watchCount;
  final int restCount;

  const _RosterSummaryBar({
    required this.totalCount,
    required this.placedCount,
    required this.readyCount,
    required this.watchCount,
    required this.restCount,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final items = [
      _RosterSummaryChip(
        icon: Icons.groups_2_outlined,
        label: l10n.teamManagementPlayerCount(totalCount),
        color: scheme.primary,
      ),
      _RosterSummaryChip(
        icon: Icons.account_tree_outlined,
        label: l10n.teamManagementBoardPlacementValue(
          placedCount,
          totalCount,
        ),
        color: scheme.tertiary,
      ),
      _RosterSummaryChip(
        icon: Icons.verified_outlined,
        label: l10n.teamManagementRosterReadyCount(readyCount),
        color: _playerConditionAccent(
          ManagedTeamPlayer.conditionReady,
        ),
      ),
      _RosterSummaryChip(
        icon: Icons.monitor_heart_outlined,
        label: l10n.teamManagementRosterManagedCount(watchCount + restCount),
        color: watchCount + restCount > 0
            ? _playerConditionAccent(ManagedTeamPlayer.conditionWatch)
            : scheme.onSurfaceVariant,
      ),
    ];
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) => items[index],
      ),
    );
  }
}

class _RosterSummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _RosterSummaryChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 32, minWidth: 104),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: AppRadius.small,
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleRosterSection extends StatelessWidget {
  final String role;
  final List<ManagedTeamPlayer> players;
  final int Function(ManagedTeamPlayer player) assignedCountFor;
  final ValueChanged<ManagedTeamPlayer> onEditPlayer;
  final ValueChanged<ManagedTeamPlayer> onRemovePlayer;
  final bool readOnly;

  const _RoleRosterSection({
    required this.role,
    required this.players,
    required this.assignedCountFor,
    required this.onEditPlayer,
    required this.onRemovePlayer,
    required this.readOnly,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final accent = _playerRoleAccent(role);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(_playerRoleIcon(role), color: accent, size: 17),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  l10n.teamManagementRoleGroupCount(
                    teamPlayerRoleLabel(l10n, role),
                    players.length,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final player in players) ...[
            _PlayerRosterCard(
              player: player,
              assignedCount: assignedCountFor(player),
              accent: accent,
              onEdit: () => onEditPlayer(player),
              onRemove: () => onRemovePlayer(player),
              readOnly: readOnly,
            ),
            if (player != players.last) const SizedBox(height: AppSpacing.xxs),
          ],
        ],
      ),
    );
  }
}

class _PlayerRosterCard extends StatelessWidget {
  final ManagedTeamPlayer player;
  final int assignedCount;
  final Color accent;
  final VoidCallback onEdit;
  final VoidCallback onRemove;
  final bool readOnly;

  const _PlayerRosterCard({
    required this.player,
    required this.assignedCount,
    required this.accent,
    required this.onEdit,
    required this.onRemove,
    required this.readOnly,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final conditionAccent = _playerConditionAccent(player.condition);
    final note = player.note.trim();
    final placementLabel = assignedCount > 0
        ? l10n.teamManagementRosterPlacementCount(assignedCount)
        : l10n.teamManagementRosterNoPlacement;
    final supplementaryMeta = _teamPlayerSupplementaryMeta(l10n, player);
    final metaLabel = [
      teamPlayerRoleLabel(l10n, player.role),
      teamPlayerFootLabel(l10n, player.foot),
      teamPlayerConditionLabel(l10n, player.condition),
      if (supplementaryMeta.isNotEmpty) supplementaryMeta,
      placementLabel,
    ].join(' · ');
    return Material(
      color: theme.brightness == Brightness.dark
          ? scheme.surfaceContainerHighest.withValues(alpha: 0.30)
          : scheme.surfaceContainerHighest.withValues(alpha: 0.30),
      borderRadius: AppRadius.small,
      child: Container(
        constraints: const BoxConstraints(minHeight: 54),
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.xs,
          AppSpacing.xxs,
          AppSpacing.xxs,
          AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          borderRadius: AppRadius.small,
          boxShadow: [
            if (theme.brightness == Brightness.light)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            _PlayerPhotoFrame(
              imageDataUrl: player.imageDataUrl,
              playerName: player.name,
              playerNumber: player.number,
              playerRole: player.role,
              size: 42,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          player.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      _RosterStatusDot(color: conditionAccent),
                      if (note.isNotEmpty) ...[
                        const SizedBox(width: AppSpacing.xxs),
                        Icon(
                          Icons.sticky_note_2_outlined,
                          size: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    metaLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xxs),
            MenuAnchor(
              menuChildren: [
                MenuItemButton(
                  leadingIcon: const Icon(Icons.edit_outlined),
                  onPressed: onEdit,
                  child: Text(l10n.teamManagementEditPlayerButton),
                ),
                MenuItemButton(
                  leadingIcon: const Icon(Icons.delete_outline),
                  onPressed: onRemove,
                  child: Text(l10n.teamManagementRemovePlayerButton),
                ),
              ],
              builder: (context, controller, child) {
                return Tooltip(
                  message: l10n.teamManagementEditPlayerButton,
                  child: SizedBox(
                    width: 34,
                    height: 40,
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: AppRadius.small,
                      child: InkWell(
                        borderRadius: AppRadius.small,
                        onTap: readOnly
                            ? null
                            : () {
                                if (controller.isOpen) {
                                  controller.close();
                                } else {
                                  controller.open();
                                }
                              },
                        child: Icon(
                          Icons.more_vert,
                          size: 20,
                          color: readOnly
                              ? scheme.onSurface.withValues(alpha: 0.38)
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RosterStatusDot extends StatelessWidget {
  final Color color;

  const _RosterStatusDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.28),
            blurRadius: 8,
          ),
        ],
      ),
    );
  }
}

ImageProvider? _teamPlayerImageProvider(String imageDataUrl) {
  final source = imageDataUrl.trim();
  if (!source.startsWith('data:image/')) return null;
  final commaIndex = source.indexOf(',');
  if (commaIndex < 0 || commaIndex == source.length - 1) return null;
  try {
    return MemoryImage(base64Decode(source.substring(commaIndex + 1)));
  } catch (_) {
    return null;
  }
}

String _playerInitials(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '';
  final parts = trimmed.split(RegExp(r'\s+'));
  if (parts.length == 1) {
    return trimmed.characters.take(2).toString();
  }
  return parts
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part.characters.first)
      .join();
}

String _measurementFieldText(double value) {
  if (value <= 0) return '';
  return _formatMeasurement(value);
}

String _formatMeasurement(double value) {
  if (value <= 0) return '';
  final rounded = value.roundToDouble();
  if ((value - rounded).abs() < 0.01) {
    return rounded.toInt().toString();
  }
  return value.toStringAsFixed(1);
}

String _teamPlayerSupplementaryMeta(
  AppLocalizations l10n,
  ManagedTeamPlayer player,
) {
  final parts = <String>[
    if (player.grade.trim().isNotEmpty)
      l10n.teamManagementPlayerGradeMeta(player.grade.trim()),
    if (player.heightCm > 0)
      l10n.teamManagementPlayerHeightMeta(
        _formatMeasurement(player.heightCm),
      ),
    if (player.weightKg > 0)
      l10n.teamManagementPlayerWeightMeta(
        _formatMeasurement(player.weightKg),
      ),
  ];
  return parts.join(' · ');
}

List<ManagedTeamPlayer> _sortRosterPlayers(List<ManagedTeamPlayer> players) {
  final sorted = List<ManagedTeamPlayer>.from(players);
  sorted.sort((a, b) {
    final numberA = int.tryParse(a.number.trim());
    final numberB = int.tryParse(b.number.trim());
    if (numberA != null && numberB != null && numberA != numberB) {
      return numberA.compareTo(numberB);
    }
    if (numberA != null && numberB == null) return -1;
    if (numberA == null && numberB != null) return 1;
    return a.name.compareTo(b.name);
  });
  return sorted;
}

Color _playerRoleAccent(String role) {
  return switch (role) {
    ManagedTeamPlayer.roleGoalkeeper => const Color(0xFFD97706),
    ManagedTeamPlayer.roleDefender => const Color(0xFF0F766E),
    ManagedTeamPlayer.roleMidfielder => const Color(0xFF2563EB),
    _ => const Color(0xFFDC2626),
  };
}

Color _playerConditionAccent(String condition) {
  return switch (condition) {
    ManagedTeamPlayer.conditionWatch => const Color(0xFFD97706),
    ManagedTeamPlayer.conditionRest => const Color(0xFFDC2626),
    _ => const Color(0xFF15803D),
  };
}

IconData _playerRoleIcon(String role) {
  return switch (role) {
    ManagedTeamPlayer.roleGoalkeeper => Icons.back_hand_outlined,
    ManagedTeamPlayer.roleDefender => Icons.shield_outlined,
    ManagedTeamPlayer.roleMidfielder => Icons.hub_outlined,
    _ => Icons.sports_soccer_outlined,
  };
}

class _StructuredSection extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? accent;

  const _StructuredSection({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final brightness = theme.brightness;
    final tint = accent ?? scheme.outline;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: brightness == Brightness.dark
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.24)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.46),
        borderRadius: AppRadius.small,
        border: Border.all(
          color: tint.withValues(alpha: accent == null ? 0.42 : 0.24),
        ),
      ),
      child: child,
    );
  }
}

class _PanelTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? helper;

  const _PanelTitle({
    required this.icon,
    required this.title,
    this.helper,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final helper = this.helper;
    return Row(
      crossAxisAlignment:
          helper == null ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Container(
          width: helper == null ? 34 : 38,
          height: helper == null ? 34 : 38,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.10),
            borderRadius: AppRadius.small,
          ),
          child:
              Icon(icon, color: scheme.primary, size: helper == null ? 18 : 20),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (helper != null) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  helper,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _InlineEmptyMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _InlineEmptyMessage({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.48),
        borderRadius: AppRadius.small,
      ),
      child: Row(
        children: [
          Icon(icon, color: scheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  body,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const List<String> _playerRoles = <String>[
  ManagedTeamPlayer.roleGoalkeeper,
  ManagedTeamPlayer.roleDefender,
  ManagedTeamPlayer.roleMidfielder,
  ManagedTeamPlayer.roleForward,
];

const List<String> _playerFeet = <String>[
  ManagedTeamPlayer.footRight,
  ManagedTeamPlayer.footLeft,
  ManagedTeamPlayer.footBoth,
];

const List<String> _playerConditions = <String>[
  ManagedTeamPlayer.conditionReady,
  ManagedTeamPlayer.conditionWatch,
  ManagedTeamPlayer.conditionRest,
];

String teamPlayerRoleLabel(AppLocalizations l10n, String role) {
  return switch (role) {
    ManagedTeamPlayer.roleGoalkeeper => l10n.teamManagementRoleGoalkeeper,
    ManagedTeamPlayer.roleDefender => l10n.teamManagementRoleDefender,
    ManagedTeamPlayer.roleMidfielder => l10n.teamManagementRoleMidfielder,
    _ => l10n.teamManagementRoleForward,
  };
}

String teamPlayerFootLabel(AppLocalizations l10n, String foot) {
  return switch (foot) {
    ManagedTeamPlayer.footLeft => l10n.teamManagementPlayerFootLeft,
    ManagedTeamPlayer.footBoth => l10n.teamManagementPlayerFootBoth,
    _ => l10n.teamManagementPlayerFootRight,
  };
}

String teamPlayerConditionLabel(AppLocalizations l10n, String condition) {
  return switch (condition) {
    ManagedTeamPlayer.conditionWatch => l10n.teamManagementPlayerConditionWatch,
    ManagedTeamPlayer.conditionRest => l10n.teamManagementPlayerConditionRest,
    _ => l10n.teamManagementPlayerConditionReady,
  };
}

String teamPlayerRoleShortLabel(String role) {
  return switch (role) {
    ManagedTeamPlayer.roleGoalkeeper => 'GK',
    ManagedTeamPlayer.roleDefender => 'DF',
    ManagedTeamPlayer.roleMidfielder => 'MF',
    _ => 'FW',
  };
}

String _playerDisplayName(ManagedTeamPlayer player) {
  return player.number.trim().isEmpty
      ? player.name
      : '${player.number.trim()} ${player.name}';
}

String _playerInitialLabel(ManagedTeamPlayer player) {
  final trimmed = player.name.trim();
  if (trimmed.length <= 2) return trimmed;
  return trimmed.characters.take(2).toString();
}
