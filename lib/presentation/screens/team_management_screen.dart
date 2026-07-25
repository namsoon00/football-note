import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:image_picker/image_picker.dart';

import '../../application/family_access_service.dart';
import '../../application/locale_service.dart';
import '../../application/match_competition_service.dart';
import '../../application/settings_service.dart';
import '../../application/sport_capabilities.dart';
import '../../application/sport_service.dart';
import '../../application/team_management_service.dart';
import '../../application/training_service.dart';
import '../../domain/entities/training_entry.dart';
import '../../domain/repositories/option_repository.dart';
import '../theme/app_theme.dart';
import '../utils/match_entry_format.dart';
import '../widgets/app_page_route.dart';
import '../widgets/app_bar_action_button.dart';
import '../widgets/app_feedback.dart';
import 'competition_management_screen.dart';
import 'match_record_screen.dart';
import 'match_records_screen.dart';

enum _TacticBoardMode { assign, movement, press, zone }

enum _TeamManagementSection { players, matches }

enum _TeamManagementWorkspace { board }

enum _RosterConditionFilter { all, ready, watch, rest }

enum _MatchHubView { upcoming, results }

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
  String? _selectedTacticLineId;
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

  Future<void> _openMatchRecord({
    DateTime? initialDate,
    TrainingEntry? editingEntry,
    MatchCompetitionRecord? initialCompetition,
    CompetitionFixture? initialFixture,
  }) async {
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
          editingEntry: editingEntry,
          initialCompetition: initialCompetition,
          initialFixture: initialFixture,
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
    _selectedTacticLineId = null;
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
      _selectedTacticLineId = null;
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

  Future<void> _saveTeamNameNow() async {
    await _persistTeam(force: true, showFeedback: true);
  }

  Future<void> _openTeamNameEditor() async {
    if (_blockReadOnlyMutation()) return;
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: _teamNameController.text);
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        void submit() {
          FocusScope.of(context).unfocus();
          Navigator.of(context).pop(controller.text);
        }

        return AlertDialog(
          title: Text(l10n.teamManagementTeamNameLabel),
          content: TextField(
            key: const ValueKey('team-name-field'),
            controller: controller,
            autofocus: true,
            maxLength: 40,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: l10n.teamManagementTeamNameHint,
            ),
            onSubmitted: (_) => submit(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton.icon(
              key: const ValueKey('team-name-save'),
              onPressed: submit,
              icon: const Icon(Icons.save_outlined),
              label: Text(l10n.save),
            ),
          ],
        );
      },
    );
    unawaited(
      Future<void>.delayed(
        const Duration(milliseconds: 350),
        controller.dispose,
      ),
    );
    if (!mounted || result == null) return;
    final nextName = result.trim();
    if (nextName.isEmpty) {
      AppFeedback.showMessage(context, text: l10n.teamManagementNameRequired);
      return;
    }
    _teamNameController.text = nextName;
    await _saveTeamNameNow();
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
      _selectedTacticLineId = null;
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
      _selectedTacticLineId = null;
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
      _selectedTacticLineId = null;
      _boardMode = _TacticBoardMode.assign;
    });
    _scheduleAutoSave();
  }

  void _updateTacticBoard(
    String boardId,
    String title,
    String description,
  ) {
    if (_blockReadOnlyMutation()) return;
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    _rememberTacticUndoState();
    setState(() {
      _tacticBoards = [
        for (final board in _syncedTacticBoards())
          if (board.id == boardId)
            board.copyWith(
              title: trimmed,
              description: description.trim(),
              updatedAt: DateTime.now(),
            )
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
      _selectedTacticLineId = null;
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
      _selectedTacticLineId = null;
    });
  }

  void _selectTacticLine(String? lineId) {
    if (_selectedTacticLineId == lineId) return;
    setState(() => _selectedTacticLineId = lineId);
  }

  void _deleteSelectedTacticLine() {
    if (_blockReadOnlyMutation()) return;
    final lineId = _selectedTacticLineId;
    if (lineId == null || lineId.isEmpty) return;
    if (!_tacticLines.any((line) => line.id == lineId)) return;
    _rememberTacticUndoState();
    setState(() {
      _tacticLines = _tacticLines
          .where((line) => line.id != lineId)
          .toList(growable: false);
      _selectedTacticLineId = null;
      _syncActiveTacticBoardState();
    });
    _scheduleAutoSave();
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
      _selectedTacticLineId = null;
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
                        saving: _saving,
                        readOnly: readOnly,
                        onSave: () => unawaited(
                          _persistTeam(force: true, showFeedback: true),
                        ),
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
            teamName: _teamNameController.text,
            saving: _saving,
            readOnly: readOnly,
            onEditTeamName: () => unawaited(_openTeamNameEditor()),
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
    final trainingService = widget.trainingService;
    final matchActionsEnabled = widget.trainingService != null &&
        widget.localeService != null &&
        widget.settingsService != null;
    return _MatchManagementPanel(
      matchActionsEnabled: matchActionsEnabled,
      trainingService: trainingService,
      optionRepository: widget.optionRepository,
      teamName: _teamNameController.text,
      onRecordMatch: () => unawaited(_openMatchRecord()),
      onRecordFixture: (competition, fixture) => unawaited(
        _openMatchRecord(
          initialCompetition: competition,
          initialFixture: fixture,
        ),
      ),
      onManageCompetitions: () => unawaited(_openCompetitionManagement()),
      onEditMatch: _isReadOnlySupportMode
          ? null
          : (entry) => unawaited(_openMatchRecord(editingEntry: entry)),
    );
  }

  Widget _buildPlayersPanel(bool readOnly) {
    return _PlayersPanel(
      players: _players,
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
          selectedTacticLineId: _selectedTacticLineId,
          boardMode: _boardMode,
          landscapeMode: _boardLandscapeMode,
          readOnly: readOnly,
          onTacticBoardSelected: _selectTacticBoard,
          onAddTacticBoard: _addTacticBoard,
          onDuplicateTacticBoard: _duplicateTacticBoard,
          onUpdateTacticBoard: _updateTacticBoard,
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
          onTacticLineSelected: _selectTacticLine,
          onDeleteSelectedTacticLine: _deleteSelectedTacticLine,
          onClearTacticLines: _clearTacticLines,
        );
    }
  }
}

class _WorkspaceScreenHeader extends StatelessWidget {
  final VoidCallback onBackToMenu;
  final bool landscapeMode;
  final VoidCallback onToggleLandscape;
  final bool saving;
  final bool readOnly;
  final VoidCallback onSave;

  const _WorkspaceScreenHeader({
    required this.onBackToMenu,
    required this.landscapeMode,
    required this.onToggleLandscape,
    required this.saving,
    required this.readOnly,
    required this.onSave,
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
        const SizedBox(width: AppSpacing.xs),
        AppBarActionButton.label(
          key: const ValueKey('team-board-save'),
          icon: saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: l10n.save,
          tooltip: l10n.save,
          onPressed: readOnly || saving ? null : onSave,
          margin: EdgeInsets.zero,
          maxLabelWidth: 64,
        ),
      ],
    );
  }
}

class _TeamManagementHeader extends StatelessWidget {
  final VoidCallback onBack;
  final String teamName;
  final bool saving;
  final bool readOnly;
  final VoidCallback onEditTeamName;
  final VoidCallback onOpenBoard;
  final VoidCallback? onManageCompetitions;

  const _TeamManagementHeader({
    required this.onBack,
    required this.teamName,
    required this.saving,
    required this.readOnly,
    required this.onEditTeamName,
    required this.onOpenBoard,
    required this.onManageCompetitions,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        BackButton(onPressed: onBack),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: _TeamNameButton(
            teamName: teamName,
            saving: saving,
            readOnly: readOnly,
            onPressed: onEditTeamName,
          ),
        ),
        AppBarActionButton.label(
          key: const ValueKey('team-header-board'),
          icon: const Icon(Icons.account_tree_outlined),
          label: l10n.teamManagementBoardHeaderButton,
          tooltip: l10n.teamManagementWorkspaceBoardTab,
          onPressed: onOpenBoard,
          margin: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
          maxLabelWidth: 54,
        ),
        if (onManageCompetitions != null)
          AppBarActionButton.label(
            key: const ValueKey('team-header-competition'),
            icon: const Icon(Icons.emoji_events_outlined),
            label: l10n.teamManagementCompetitionHeaderButton,
            tooltip: l10n.matchCompetitionOpenButton,
            onPressed: onManageCompetitions,
            margin: EdgeInsets.zero,
            maxLabelWidth: 54,
          ),
      ],
    );
  }
}

class _TeamNameButton extends StatelessWidget {
  final String teamName;
  final bool saving;
  final bool readOnly;
  final VoidCallback onPressed;

  const _TeamNameButton({
    required this.teamName,
    required this.saving,
    required this.readOnly,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final visibleName = teamName.trim().isEmpty
        ? l10n.teamManagementDefaultTeamName
        : teamName.trim();
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Tooltip(
        message: l10n.teamManagementTeamNameLabel,
        child: Semantics(
          button: true,
          child: InkWell(
            key: const ValueKey('team-name-open'),
            onTap: readOnly || saving ? null : onPressed,
            borderRadius: AppRadius.small,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      visibleName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  if (saving)
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.onSurfaceVariant,
                      ),
                    )
                  else
                    Icon(
                      Icons.edit_outlined,
                      size: 15,
                      color: readOnly
                          ? scheme.onSurface.withValues(alpha: 0.38)
                          : scheme.onSurface,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
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

class _MatchManagementPanel extends StatefulWidget {
  final bool matchActionsEnabled;
  final TrainingService? trainingService;
  final OptionRepository optionRepository;
  final String teamName;
  final VoidCallback onRecordMatch;
  final void Function(MatchCompetitionRecord, CompetitionFixture)
      onRecordFixture;
  final VoidCallback onManageCompetitions;
  final ValueChanged<TrainingEntry>? onEditMatch;

  const _MatchManagementPanel({
    required this.matchActionsEnabled,
    required this.trainingService,
    required this.optionRepository,
    required this.teamName,
    required this.onRecordMatch,
    required this.onRecordFixture,
    required this.onManageCompetitions,
    required this.onEditMatch,
  });

  @override
  State<_MatchManagementPanel> createState() => _MatchManagementPanelState();
}

class _MatchManagementPanelState extends State<_MatchManagementPanel> {
  _MatchHubView _view = _MatchHubView.upcoming;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final trainingService = widget.trainingService;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _PanelTitle(
                icon: Icons.event_note_outlined,
                title: l10n.teamManagementMatchSectionTitle,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            AppBarActionButton.label(
              key: const ValueKey('team-match-friendly-action'),
              icon: const Icon(Icons.handshake_outlined),
              label: l10n.matchKindFriendly,
              tooltip: l10n.matchKindFriendly,
              onPressed:
                  widget.matchActionsEnabled ? widget.onRecordMatch : null,
              margin: EdgeInsets.zero,
              maxLabelWidth: 96,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (trainingService == null)
          _InlineEmptyMessage(
            icon: Icons.fact_check_outlined,
            title: l10n.matchHubEmptyTitle,
            body: l10n.matchHubEmptySubtitle,
          )
        else ...[
          SegmentedButton<_MatchHubView>(
            key: const ValueKey('team-match-hub-view-switcher'),
            showSelectedIcon: false,
            segments: [
              ButtonSegment<_MatchHubView>(
                value: _MatchHubView.upcoming,
                icon: const Icon(Icons.event_available_outlined),
                label: Text(l10n.teamMatchHubUpcomingTab),
              ),
              ButtonSegment<_MatchHubView>(
                value: _MatchHubView.results,
                icon: const Icon(Icons.history_outlined),
                label: Text(l10n.teamMatchHubResultsTab),
              ),
            ],
            selected: {_view},
            onSelectionChanged: (selection) {
              setState(() => _view = selection.single);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          if (_view == _MatchHubView.upcoming)
            _UpcomingCompetitionFixtures(
              trainingService: trainingService,
              optionRepository: widget.optionRepository,
              teamName: widget.teamName,
              canRecord: widget.matchActionsEnabled,
              onRecordFixture: widget.onRecordFixture,
              onManageCompetitions: widget.onManageCompetitions,
            )
          else
            MatchRecordsContent(
              key: const ValueKey('team-match-records-content'),
              trainingService: trainingService,
              optionRepository: widget.optionRepository,
              showHeader: false,
              showSummary: false,
              scrollable: false,
              onEditEntry: widget.onEditMatch,
            ),
        ],
      ],
    );
  }
}

class _UpcomingCompetitionFixtures extends StatelessWidget {
  final TrainingService trainingService;
  final OptionRepository optionRepository;
  final String teamName;
  final bool canRecord;
  final void Function(MatchCompetitionRecord, CompetitionFixture)
      onRecordFixture;
  final VoidCallback onManageCompetitions;

  const _UpcomingCompetitionFixtures({
    required this.trainingService,
    required this.optionRepository,
    required this.teamName,
    required this.canRecord,
    required this.onRecordFixture,
    required this.onManageCompetitions,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sportId = SportService(optionRepository).currentSportId();
    final competitionService = MatchCompetitionService(
      optionRepository,
      sportId: sportId,
    );
    return StreamBuilder<List<TrainingEntry>>(
      stream: trainingService.watchEntries(),
      builder: (context, snapshot) {
        final entries = filterEntriesForSport(
          snapshot.data ?? const <TrainingEntry>[],
          sportId,
        ).where((entry) => entry.isMatch);
        final activeCompetitions = competitionService
            .allCompetitions()
            .where((record) => !record.isFinished);
        final ownTeamName = teamName.trim().isEmpty
            ? l10n.matchCompetitionMyTeamFallback
            : teamName.trim();
        final fixtures = MatchCompetitionService.fixturesForTeam(
          competitions: activeCompetitions,
          entries: entries,
          teamName: ownTeamName,
          teamAliases: [l10n.matchCompetitionMyTeamFallback],
          includeRecorded: false,
        ).where((fixture) => fixture.isReady).toList(growable: false);
        if (fixtures.isEmpty) {
          return _InlineEmptyMessage(
            icon: Icons.event_available_outlined,
            title: l10n.teamMatchHubUpcomingEmptyTitle,
            body: l10n.teamMatchHubUpcomingEmptyBody,
            actionLabel: l10n.matchCompetitionManagerNewTitle,
            onAction: onManageCompetitions,
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.teamMatchHubUpcomingTitle,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final fixture in fixtures)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _UpcomingFixtureCard(
                  fixture: fixture,
                  canRecord: canRecord,
                  onRecord: () => onRecordFixture(
                    fixture.competition,
                    fixture.fixture,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _UpcomingFixtureCard extends StatelessWidget {
  final CompetitionFixtureState fixture;
  final bool canRecord;
  final VoidCallback onRecord;

  const _UpcomingFixtureCard({
    required this.fixture,
    required this.canRecord,
    required this.onRecord,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isLeague =
        fixture.competition.kind == MatchCompetitionRecord.kindLeague;
    final stage = isLeague
        ? l10n.matchCompetitionFixtureRound(fixture.fixture.roundNumber)
        : matchTournamentStageLabel(l10n, fixture.fixture.stage);
    final date = fixture.fixture.scheduledAt == null
        ? l10n.teamMatchHubDateUnset
        : MaterialLocalizations.of(
            context,
          ).formatMediumDate(fixture.fixture.scheduledAt!);
    final venue = fixture.fixture.venue.trim();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppSurfaces.cardDecoration(scheme, theme.brightness)
          .copyWith(borderRadius: AppRadius.small),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                isLeague
                    ? Icons.leaderboard_outlined
                    : Icons.account_tree_outlined,
                color: isLeague ? scheme.primary : scheme.tertiary,
                size: 19,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  fixture.competition.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                stage,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${fixture.homeTeam}  vs  ${fixture.awayTeam}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            venue.isEmpty ? date : '$date · $venue',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FilledButton.icon(
              onPressed: canRecord ? onRecord : null,
              icon: const Icon(Icons.edit_note_outlined, size: 18),
              label: Text(l10n.teamMatchHubRecordFixtureAction),
            ),
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
  final String? selectedTacticLineId;
  final _TacticBoardMode boardMode;
  final bool landscapeMode;
  final bool readOnly;
  final ValueChanged<String> onTacticBoardSelected;
  final VoidCallback onAddTacticBoard;
  final VoidCallback onDuplicateTacticBoard;
  final void Function(String boardId, String title, String description)
      onUpdateTacticBoard;
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
  final ValueChanged<String?> onTacticLineSelected;
  final VoidCallback onDeleteSelectedTacticLine;
  final VoidCallback onClearTacticLines;

  const _TacticsBoardPanel({
    required this.players,
    required this.tacticBoards,
    required this.activeTacticBoardId,
    required this.playerPlacements,
    required this.tacticLines,
    required this.draftTacticLine,
    required this.selectedTacticLineId,
    required this.boardMode,
    required this.landscapeMode,
    required this.readOnly,
    required this.onTacticBoardSelected,
    required this.onAddTacticBoard,
    required this.onDuplicateTacticBoard,
    required this.onUpdateTacticBoard,
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
    required this.onTacticLineSelected,
    required this.onDeleteSelectedTacticLine,
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
          activeDescription: activeBoard.description,
          players: players,
          playerPlacements: playerPlacements,
          tacticLines: tacticLines,
          draftTacticLine: draftTacticLine,
          selectedTacticLineId: selectedTacticLineId,
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
          onTacticLineSelected: onTacticLineSelected,
          onDeleteSelectedTacticLine: onDeleteSelectedTacticLine,
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
              onUpdateBoard: (boardId, title, description) {
                closeThen(
                  () => onUpdateTacticBoard(boardId, title, description),
                );
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
  final void Function(String boardId, String title, String description)
      onUpdateBoard;
  final VoidCallback onDeleteBoard;

  const _TacticListPanel({
    required this.boards,
    required this.activeBoardId,
    required this.readOnly,
    required this.vertical,
    required this.onBoardSelected,
    required this.onAddBoard,
    required this.onDuplicateBoard,
    required this.onUpdateBoard,
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
                          _showTacticDetailsDialog(
                            context,
                            activeBoard,
                            activeBoardIndex < 0 ? 0 : activeBoardIndex,
                          ),
                        ),
                icon: Icons.edit_note_outlined,
                label: l10n.teamManagementTacticBoardEditButton,
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

  Future<void> _showTacticDetailsDialog(
    BuildContext context,
    ManagedTacticBoard board,
    int boardIndex,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final titleController = TextEditingController(
      text: _tacticBoardDisplayTitle(l10n, board, boardIndex),
    );
    final descriptionController = TextEditingController(
      text: board.description,
    );
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.teamManagementTacticBoardEditDialogTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const ValueKey('team-tactic-board-name-field'),
                controller: titleController,
                autofocus: true,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.teamManagementTacticBoardNameLabel,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                key: const ValueKey('team-tactic-board-description-field'),
                controller: descriptionController,
                minLines: 3,
                maxLines: 5,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: l10n.teamManagementTacticBoardDescriptionLabel,
                  hintText: l10n.teamManagementTacticBoardDescriptionHint,
                  alignLabelWithHint: true,
                ),
                onSubmitted: (_) => Navigator.of(context).pop(true),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            FilledButton(
              key: const ValueKey('team-tactic-board-details-save'),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );
    final title = titleController.text;
    final description = descriptionController.text;
    if (shouldSave == true) {
      onUpdateBoard(board.id, title, description);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      titleController.dispose();
      descriptionController.dispose();
    });
  }
}

class _TacticDetailHeader extends StatelessWidget {
  final String title;
  final String meta;
  final String description;
  final bool canUndo;
  final VoidCallback onOpenList;
  final VoidCallback onUndo;

  const _TacticDetailHeader({
    required this.title,
    required this.meta,
    required this.description,
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
              if (description.trim().isNotEmpty)
                Text(
                  description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
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
  final String activeDescription;
  final List<ManagedTeamPlayer> players;
  final Map<String, ManagedPlayerPlacement> playerPlacements;
  final List<ManagedTacticLine> tacticLines;
  final ManagedTacticLine? draftTacticLine;
  final String? selectedTacticLineId;
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
  final ValueChanged<String?> onTacticLineSelected;
  final VoidCallback onDeleteSelectedTacticLine;
  final VoidCallback onClearTacticLines;

  const _TacticDetailPanel({
    required this.activeTitle,
    required this.activeMeta,
    required this.activeDescription,
    required this.players,
    required this.playerPlacements,
    required this.tacticLines,
    required this.draftTacticLine,
    required this.selectedTacticLineId,
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
    required this.onTacticLineSelected,
    required this.onDeleteSelectedTacticLine,
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
      selectedTacticLineId: selectedTacticLineId,
      boardMode: boardMode,
      landscapeMode: landscapeMode,
      readOnly: readOnly,
      onPlayerPlaced: onPlayerPlaced,
      onPlayerMoveStarted: onPlayerMoveStarted,
      onPlayerMoveFinished: onPlayerMoveFinished,
      onTacticLineStarted: onTacticLineStarted,
      onTacticLineUpdated: onTacticLineUpdated,
      onTacticLineFinished: onTacticLineFinished,
      onTacticLineSelected: onTacticLineSelected,
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
            description: activeDescription,
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
                    selectedTacticLineId: selectedTacticLineId,
                    readOnly: readOnly,
                    compact: true,
                    onModeChanged: onBoardModeChanged,
                    onClearTacticLines: onClearTacticLines,
                    onDeleteSelectedTacticLine: onDeleteSelectedTacticLine,
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
              selectedTacticLineId: selectedTacticLineId,
              readOnly: readOnly,
              compact: false,
              onModeChanged: onBoardModeChanged,
              onClearTacticLines: onClearTacticLines,
              onDeleteSelectedTacticLine: onDeleteSelectedTacticLine,
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
    final secondary = board.description.trim().isEmpty
        ? l10n.teamManagementTacticBoardPageMeta(
            board.playerPlacements.length,
            board.tacticLines.length,
          )
        : board.description.trim();
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
                      secondary,
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
  final String? selectedTacticLineId;
  final bool readOnly;
  final bool compact;
  final ValueChanged<_TacticBoardMode> onModeChanged;
  final VoidCallback onClearTacticLines;
  final VoidCallback onDeleteSelectedTacticLine;

  const _BoardModeToolbar({
    required this.mode,
    required this.tacticLineCount,
    required this.selectedTacticLineId,
    required this.readOnly,
    required this.compact,
    required this.onModeChanged,
    required this.onClearTacticLines,
    required this.onDeleteSelectedTacticLine,
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
          key: const ValueKey('team-tactic-board-delete-selected'),
          onPressed: readOnly || selectedTacticLineId == null
              ? null
              : onDeleteSelectedTacticLine,
          icon: Icons.delete_outline,
          label: l10n.teamManagementBoardDeleteSelectedMarkerButton,
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
            _PositionCodeGlyph(
              player: player,
              size: compact ? 18 : 20,
              fill: assigned
                  ? scheme.primaryContainer
                  : scheme.surfaceContainerHighest,
              stroke: assigned ? scheme.primary : scheme.outlineVariant,
              foreground:
                  assigned ? scheme.onPrimaryContainer : scheme.onSurface,
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
  final String? selectedTacticLineId;
  final _TacticBoardMode boardMode;
  final bool landscapeMode;
  final bool readOnly;
  final _PlayerBoardDropCallback onPlayerPlaced;
  final ValueChanged<String> onPlayerMoveStarted;
  final VoidCallback onPlayerMoveFinished;
  final ValueChanged<Offset> onTacticLineStarted;
  final ValueChanged<Offset> onTacticLineUpdated;
  final VoidCallback onTacticLineFinished;
  final ValueChanged<String?> onTacticLineSelected;

  const _TacticsPitch({
    required this.players,
    required this.playerPlacements,
    required this.tacticLines,
    required this.draftTacticLine,
    required this.selectedTacticLineId,
    required this.boardMode,
    required this.landscapeMode,
    required this.readOnly,
    required this.onPlayerPlaced,
    required this.onPlayerMoveStarted,
    required this.onPlayerMoveFinished,
    required this.onTacticLineStarted,
    required this.onTacticLineUpdated,
    required this.onTacticLineFinished,
    required this.onTacticLineSelected,
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
                        onTapUp: (details) => onTacticLineSelected(
                          _findTacticLineAt(
                            tacticLines,
                            details.localPosition,
                            constraints.biggest,
                          ),
                        ),
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
                                selectedLineId: selectedTacticLineId,
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
    final scheme = theme.colorScheme;
    final condition = _playerConditionAccent(player.condition);
    return Semantics(
      label:
          '${player.name}, ${teamPlayerPositionCode(player.effectivePosition, role: player.role)}',
      child: Material(
        color: Colors.transparent,
        elevation: 8,
        child: _PositionMarkerSurface(
          player: player,
          fill: scheme.surface,
          stroke: scheme.primary,
          child: Stack(
            fit: StackFit.expand,
            children: [
              PositionedDirectional(
                top: 2,
                end: 4,
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
                            ? _playerInitialLabel(player)
                            : player.number.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          height: 1.0,
                          shadows: [
                            Shadow(
                              color: scheme.surfaceContainerHighest,
                              blurRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        teamPlayerPositionCode(
                          player.effectivePosition,
                          role: player.role,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 9,
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

String? _findTacticLineAt(
  List<ManagedTacticLine> lines,
  Offset point,
  Size size,
) {
  if (size.isEmpty) return null;
  for (final line in lines.reversed) {
    final start = Offset(line.startX * size.width, line.startY * size.height);
    final end = Offset(line.endX * size.width, line.endY * size.height);
    if (line.type == ManagedTacticLine.typeZone) {
      final zone = Rect.fromLTRB(
        math.min(start.dx, end.dx),
        math.min(start.dy, end.dy),
        math.max(start.dx, end.dx),
        math.max(start.dy, end.dy),
      ).inflate(10);
      if (zone.contains(point)) return line.id;
      continue;
    }
    final distance = _distanceToSegment(point, start, end);
    final threshold = math.max(16.0, size.shortestSide * 0.04);
    if (distance <= threshold) return line.id;
  }
  return null;
}

double _distanceToSegment(Offset point, Offset start, Offset end) {
  final segment = end - start;
  final lengthSquared = segment.dx * segment.dx + segment.dy * segment.dy;
  if (lengthSquared == 0) return (point - start).distance;
  final relative = point - start;
  final projection =
      ((relative.dx * segment.dx) + (relative.dy * segment.dy)) / lengthSquared;
  final clamped = projection.clamp(0.0, 1.0).toDouble();
  final closest = start + segment * clamped;
  return (point - closest).distance;
}

class _TacticLinesPainter extends CustomPainter {
  final List<ManagedTacticLine> lines;
  final ManagedTacticLine? draftLine;
  final String? selectedLineId;

  const _TacticLinesPainter({
    required this.lines,
    required this.draftLine,
    required this.selectedLineId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final draft = draftLine;
    for (final line in lines.where(_isZoneMarker)) {
      _drawZone(
        canvas,
        size,
        line,
        draft: false,
        selected: line.id == selectedLineId,
      );
    }
    if (draft != null && _isZoneMarker(draft)) {
      _drawZone(canvas, size, draft, draft: true, selected: false);
    }
    for (final line in lines.where((line) => !_isZoneMarker(line))) {
      _drawMarkerLine(
        canvas,
        size,
        line,
        draft: false,
        selected: line.id == selectedLineId,
      );
    }
    if (draft != null) {
      if (!_isZoneMarker(draft)) {
        _drawMarkerLine(canvas, size, draft, draft: true, selected: false);
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
    required bool selected,
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
    if (selected) {
      final selectionPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.94)
        ..strokeWidth = paint.strokeWidth + 5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(start, end, selectionPaint);
    }
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
    required bool selected,
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
    if (selected) {
      final selectedStroke = Paint()
        ..color = Colors.white.withValues(alpha: 0.94)
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.inflate(3), const Radius.circular(14)),
        selectedStroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TacticLinesPainter oldDelegate) {
    return oldDelegate.lines != lines ||
        oldDelegate.draftLine != draftLine ||
        oldDelegate.selectedLineId != selectedLineId;
  }
}

class _PlayersPanel extends StatefulWidget {
  final List<ManagedTeamPlayer> players;
  final bool readOnly;
  final VoidCallback onStartPlayerRegistration;
  final ValueChanged<ManagedTeamPlayer> onEditPlayer;
  final ValueChanged<ManagedTeamPlayer> onRemovePlayer;

  const _PlayersPanel({
    required this.players,
    required this.readOnly,
    required this.onStartPlayerRegistration,
    required this.onEditPlayer,
    required this.onRemovePlayer,
  });

  @override
  State<_PlayersPanel> createState() => _PlayersPanelState();
}

class _PlayersPanelState extends State<_PlayersPanel> {
  final TextEditingController _searchController = TextEditingController();
  _RosterConditionFilter _conditionFilter = _RosterConditionFilter.all;
  bool _searchVisible = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ManagedTeamPlayer> get _visiblePlayers {
    final query = _searchController.text.trim().toLowerCase();
    return widget.players.where((player) {
      final matchesCondition = switch (_conditionFilter) {
        _RosterConditionFilter.all => true,
        _RosterConditionFilter.ready =>
          player.condition == ManagedTeamPlayer.conditionReady,
        _RosterConditionFilter.watch =>
          player.condition == ManagedTeamPlayer.conditionWatch,
        _RosterConditionFilter.rest =>
          player.condition == ManagedTeamPlayer.conditionRest,
      };
      if (!matchesCondition) return false;
      if (query.isEmpty) return true;
      return player.name.toLowerCase().contains(query) ||
          player.number.toLowerCase().contains(query) ||
          player.grade.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  void _toggleSearch() {
    setState(() {
      _searchVisible = !_searchVisible;
      if (!_searchVisible) _searchController.clear();
    });
  }

  void _clearFilters() {
    setState(() {
      _conditionFilter = _RosterConditionFilter.all;
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final visiblePlayers = _visiblePlayers;
    final readyCount = widget.players
        .where((player) => player.condition == ManagedTeamPlayer.conditionReady)
        .length;
    final watchCount = widget.players
        .where((player) => player.condition == ManagedTeamPlayer.conditionWatch)
        .length;
    final restCount = widget.players
        .where((player) => player.condition == ManagedTeamPlayer.conditionRest)
        .length;
    return Column(
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
            AppBarActionButton.icon(
              key: const ValueKey('team-player-search-toggle'),
              icon: _searchVisible ? Icons.close : Icons.search,
              tooltip: _searchVisible
                  ? l10n.teamManagementPlayerSearchCloseTooltip
                  : l10n.teamManagementPlayerSearchTooltip,
              onPressed: _toggleSearch,
              selected: _searchVisible,
              margin: EdgeInsets.zero,
            ),
            const SizedBox(width: AppSpacing.xxs),
            AppBarActionMenuButton<_RosterConditionFilter>(
              key: const ValueKey('team-player-condition-filter'),
              icon: Icons.filter_list_outlined,
              tooltip: l10n.teamManagementPlayerFilterTooltip,
              initialValue: _conditionFilter,
              onSelected: (value) => setState(() => _conditionFilter = value),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: _RosterConditionFilter.all,
                  child: Text(l10n.filterAll),
                ),
                PopupMenuItem(
                  value: _RosterConditionFilter.ready,
                  child: Text(l10n.teamManagementPlayerConditionReady),
                ),
                PopupMenuItem(
                  value: _RosterConditionFilter.watch,
                  child: Text(l10n.teamManagementPlayerConditionWatch),
                ),
                PopupMenuItem(
                  value: _RosterConditionFilter.rest,
                  child: Text(l10n.teamManagementPlayerConditionRest),
                ),
              ],
              margin: EdgeInsets.zero,
            ),
            const SizedBox(width: AppSpacing.xxs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 116),
              child: FilledButton.icon(
                onPressed:
                    widget.readOnly ? null : widget.onStartPlayerRegistration,
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
        if (_searchVisible) ...[
          const SizedBox(height: AppSpacing.sm),
          TextField(
            key: const ValueKey('team-player-search-field'),
            controller: _searchController,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: l10n.teamManagementPlayerSearchHint,
              prefixIcon: const Icon(Icons.search),
              isDense: true,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        if (widget.players.isEmpty)
          _InlineEmptyMessage(
            icon: Icons.groups_2_outlined,
            title: l10n.teamManagementNoPlayersTitle,
            body: l10n.teamManagementNoPlayersBody,
          )
        else ...[
          _RosterSummaryBar(
            totalCount: widget.players.length,
            readyCount: readyCount,
            watchCount: watchCount,
            restCount: restCount,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (visiblePlayers.isEmpty)
            _InlineEmptyMessage(
              icon: Icons.search_off_outlined,
              title: l10n.teamManagementPlayerFilterEmptyTitle,
              body: l10n.teamManagementPlayerFilterEmptyBody,
              actionLabel: l10n.filterReset,
              onAction: _clearFilters,
            )
          else
            _RosterBoard(
              players: visiblePlayers,
              onEditPlayer: widget.onEditPlayer,
              onRemovePlayer: widget.onRemovePlayer,
              readOnly: widget.readOnly,
            ),
        ],
      ],
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
  late String _position;
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
    _position = TeamManagementService.normalizePlayerPosition(
      player?.position ?? '',
      role: _role,
    );
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
            position: _position,
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
            position: _position,
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
                playerPosition: _position,
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
                              : (_) => setState(() {
                                    _role = role;
                                    _position = TeamManagementService
                                        .defaultPlayerPositionForRole(role);
                                  }),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<String>(
                    key: ValueKey<String>(
                      'team-player-position-field-$_role',
                    ),
                    initialValue: _position,
                    decoration: InputDecoration(
                      labelText: l10n.teamManagementPlayerPositionLabel,
                    ),
                    items: [
                      for (final position
                          in TeamManagementService.playerPositionsForRole(
                        _role,
                      ))
                        DropdownMenuItem<String>(
                          value: position,
                          child: Text(teamPlayerPositionLabel(l10n, position)),
                        ),
                    ],
                    onChanged: widget.readOnly
                        ? null
                        : (position) {
                            if (position == null) return;
                            setState(() => _position = position);
                          },
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
  final String playerPosition;
  final bool pickingImage;
  final bool readOnly;
  final VoidCallback onPickImage;
  final VoidCallback? onRemoveImage;

  const _PlayerImagePickerPanel({
    required this.imageDataUrl,
    required this.playerName,
    required this.playerNumber,
    required this.playerRole,
    required this.playerPosition,
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _PlayerPhotoFrame(
          imageDataUrl: imageDataUrl,
          playerName: playerName,
          playerNumber: playerNumber,
          playerRole: playerRole,
          playerPosition: playerPosition,
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
                  teamPlayerPositionLabel(l10n, playerPosition),
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
                      backgroundColor: scheme.primary,
                      foregroundColor: scheme.onPrimary,
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
  final String playerPosition;
  final double size;

  const _PlayerPhotoFrame({
    required this.imageDataUrl,
    required this.playerName,
    required this.playerNumber,
    required this.playerRole,
    required this.playerPosition,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
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
        color: scheme.surfaceContainerHighest,
        borderRadius: borderRadius,
        border: Border.all(color: scheme.outlineVariant),
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
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  teamPlayerPositionCode(playerPosition, role: playerRole),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.primary,
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
                      color: scheme.onSurface,
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
                      ? teamPlayerPositionCode(
                          playerPosition,
                          role: playerRole,
                        )
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

enum _PositionMarkerShape { hexagon, square, circle, diamond }

class _PlayerPositionCoordinate {
  final double x;
  final double y;
  final _PositionMarkerShape shape;

  const _PlayerPositionCoordinate({
    required this.x,
    required this.y,
    required this.shape,
  });
}

class _PlayerPositionMiniPitch extends StatelessWidget {
  final ManagedTeamPlayer player;

  const _PlayerPositionMiniPitch({required this.player});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final coordinate = _playerPositionCoordinate(player);
    const markerSize = 10.0;
    return Semantics(
      label: teamPlayerPositionLabel(l10n, player.effectivePosition),
      child: SizedBox(
        key: ValueKey<String>('team-player-mini-pitch-${player.id}'),
        width: 34,
        height: 42,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final markerLeft =
                (constraints.maxWidth * coordinate.x) - (markerSize / 2);
            final markerTop =
                (constraints.maxHeight * coordinate.y) - (markerSize / 2);
            return Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: _MiniPitchCoordinatePainter(
                    lineColor: scheme.outlineVariant,
                  ),
                ),
                Positioned(
                  left: markerLeft
                      .clamp(0.0, constraints.maxWidth - markerSize)
                      .toDouble(),
                  top: markerTop
                      .clamp(0.0, constraints.maxHeight - markerSize)
                      .toDouble(),
                  width: markerSize,
                  height: markerSize,
                  child: _PositionMarkerSurface(
                    player: player,
                    fill: scheme.primary,
                    stroke: scheme.primary,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PositionCodeGlyph extends StatelessWidget {
  final ManagedTeamPlayer player;
  final double size;
  final Color fill;
  final Color stroke;
  final Color foreground;

  const _PositionCodeGlyph({
    required this.player,
    required this.size,
    required this.fill,
    required this.stroke,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: _PositionMarkerSurface(
        player: player,
        fill: fill,
        stroke: stroke,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              teamPlayerPositionCode(
                player.effectivePosition,
                role: player.role,
              ),
              style: theme.textTheme.labelSmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w900,
                fontSize: size < 20 ? 8 : 9,
                height: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PositionMarkerSurface extends StatelessWidget {
  final ManagedTeamPlayer player;
  final Color fill;
  final Color stroke;
  final Widget? child;

  const _PositionMarkerSurface({
    required this.player,
    required this.fill,
    required this.stroke,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PositionMarkerPainter(
        shape: _playerPositionCoordinate(player).shape,
        fill: fill,
        stroke: stroke,
      ),
      child: child,
    );
  }
}

class _MiniPitchCoordinatePainter extends CustomPainter {
  final Color lineColor;

  const _MiniPitchCoordinatePainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final field = Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1);
    final line = Paint()
      ..color = lineColor.withValues(alpha: 0.82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(
      RRect.fromRectAndRadius(field, const Radius.circular(3)),
      line,
    );
    for (final fraction in const <double>[1 / 3, 2 / 3]) {
      final x = field.left + (field.width * fraction);
      canvas.drawLine(Offset(x, field.top), Offset(x, field.bottom), line);
    }
    for (final fraction in const <double>[1 / 4, 2 / 4, 3 / 4]) {
      final y = field.top + (field.height * fraction);
      canvas.drawLine(Offset(field.left, y), Offset(field.right, y), line);
    }
  }

  @override
  bool shouldRepaint(covariant _MiniPitchCoordinatePainter oldDelegate) {
    return oldDelegate.lineColor != lineColor;
  }
}

class _PositionMarkerPainter extends CustomPainter {
  final _PositionMarkerShape shape;
  final Color fill;
  final Color stroke;

  const _PositionMarkerPainter({
    required this.shape,
    required this.fill,
    required this.stroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = _markerPath(shape, Offset.zero & size);
    final fillPaint = Paint()
      ..color = fill
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, size.shortestSide * 0.09);
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  Path _markerPath(_PositionMarkerShape shape, Rect rect) {
    switch (shape) {
      case _PositionMarkerShape.hexagon:
        return Path()
          ..moveTo(rect.left + (rect.width * 0.25), rect.top)
          ..lineTo(rect.left + (rect.width * 0.75), rect.top)
          ..lineTo(rect.right, rect.center.dy)
          ..lineTo(rect.left + (rect.width * 0.75), rect.bottom)
          ..lineTo(rect.left + (rect.width * 0.25), rect.bottom)
          ..lineTo(rect.left, rect.center.dy)
          ..close();
      case _PositionMarkerShape.square:
        return Path()
          ..addRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(3)),
          );
      case _PositionMarkerShape.circle:
        return Path()..addOval(rect);
      case _PositionMarkerShape.diamond:
        return Path()
          ..moveTo(rect.center.dx, rect.top)
          ..lineTo(rect.right, rect.center.dy)
          ..lineTo(rect.center.dx, rect.bottom)
          ..lineTo(rect.left, rect.center.dy)
          ..close();
    }
  }

  @override
  bool shouldRepaint(covariant _PositionMarkerPainter oldDelegate) {
    return oldDelegate.shape != shape ||
        oldDelegate.fill != fill ||
        oldDelegate.stroke != stroke;
  }
}

_PlayerPositionCoordinate _playerPositionCoordinate(ManagedTeamPlayer player) {
  final position = player.effectivePosition;
  final shape = switch (player.role) {
    ManagedTeamPlayer.roleGoalkeeper => _PositionMarkerShape.hexagon,
    ManagedTeamPlayer.roleDefender => _PositionMarkerShape.square,
    ManagedTeamPlayer.roleMidfielder => _PositionMarkerShape.circle,
    _ => _PositionMarkerShape.diamond,
  };
  final point = switch (position) {
    ManagedTeamPlayer.positionGoalkeeper => const Offset(0.5, 0.88),
    ManagedTeamPlayer.positionLeftBack => const Offset(0.22, 0.67),
    ManagedTeamPlayer.positionCenterBack => const Offset(0.5, 0.67),
    ManagedTeamPlayer.positionRightBack => const Offset(0.78, 0.67),
    ManagedTeamPlayer.positionDefensiveMidfielder => const Offset(0.5, 0.54),
    ManagedTeamPlayer.positionLeftMidfielder => const Offset(0.22, 0.46),
    ManagedTeamPlayer.positionCentralMidfielder => const Offset(0.5, 0.44),
    ManagedTeamPlayer.positionRightMidfielder => const Offset(0.78, 0.46),
    ManagedTeamPlayer.positionAttackingMidfielder => const Offset(0.5, 0.33),
    ManagedTeamPlayer.positionLeftWinger => const Offset(0.2, 0.18),
    ManagedTeamPlayer.positionRightWinger => const Offset(0.8, 0.18),
    _ => const Offset(0.5, 0.15),
  };
  return _PlayerPositionCoordinate(x: point.dx, y: point.dy, shape: shape);
}

class _RosterBoard extends StatelessWidget {
  final List<ManagedTeamPlayer> players;
  final ValueChanged<ManagedTeamPlayer> onEditPlayer;
  final ValueChanged<ManagedTeamPlayer> onRemovePlayer;
  final bool readOnly;

  const _RosterBoard({
    required this.players,
    required this.onEditPlayer,
    required this.onRemovePlayer,
    required this.readOnly,
  });

  @override
  Widget build(BuildContext context) {
    final groupedPlayers = {
      for (final role in _playerRoles)
        role: _sortRosterPlayers(
          players.where((player) => player.role == role).toList(),
        ),
    };
    final visibleGroups = _playerRoles
        .where((role) => groupedPlayers[role]!.isNotEmpty)
        .toList(growable: false);
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 620 ? 2 : 1;
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
                  onEditPlayer: onEditPlayer,
                  onRemovePlayer: onRemovePlayer,
                  readOnly: readOnly,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _RosterSummaryBar extends StatelessWidget {
  final int totalCount;
  final int readyCount;
  final int watchCount;
  final int restCount;

  const _RosterSummaryBar({
    required this.totalCount,
    required this.readyCount,
    required this.watchCount,
    required this.restCount,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final items = [
      _RosterSummaryItem(
        icon: Icons.groups_2_outlined,
        label: l10n.teamManagementRosterSummaryAll,
        value: totalCount,
        color: scheme.primary,
      ),
      _RosterSummaryItem(
        icon: Icons.verified_outlined,
        label: l10n.teamManagementRosterSummaryReady,
        value: readyCount,
        color: _playerConditionAccent(
          ManagedTeamPlayer.conditionReady,
        ),
      ),
      _RosterSummaryItem(
        icon: Icons.monitor_heart_outlined,
        label: l10n.teamManagementRosterSummaryWatch,
        value: watchCount,
        color: watchCount > 0
            ? _playerConditionAccent(ManagedTeamPlayer.conditionWatch)
            : scheme.onSurfaceVariant,
      ),
      _RosterSummaryItem(
        icon: Icons.bedtime_outlined,
        label: l10n.teamManagementRosterSummaryRest,
        value: restCount,
        color: restCount > 0
            ? _playerConditionAccent(ManagedTeamPlayer.conditionRest)
            : scheme.onSurfaceVariant,
      ),
    ];
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.46),
        borderRadius: AppRadius.small,
      ),
      child: Row(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            Expanded(child: items[index]),
            if (index != items.length - 1)
              Container(
                width: 1,
                height: 18,
                color: scheme.outlineVariant.withValues(alpha: 0.72),
              ),
          ],
        ],
      ),
    );
  }
}

class _RosterSummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  const _RosterSummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              '$label $value',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
              ),
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
  final ValueChanged<ManagedTeamPlayer> onEditPlayer;
  final ValueChanged<ManagedTeamPlayer> onRemovePlayer;
  final bool readOnly;

  const _RoleRosterSection({
    required this.role,
    required this.players,
    required this.onEditPlayer,
    required this.onRemovePlayer,
    required this.readOnly,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      decoration: AppSurfaces.cardDecoration(scheme, theme.brightness),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ColoredBox(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.62),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Icon(_playerRoleIcon(role), color: scheme.primary, size: 17),
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
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          for (var index = 0; index < players.length; index++) ...[
            _PlayerRosterCard(
              player: players[index],
              onEdit: () => onEditPlayer(players[index]),
              onRemove: () => onRemovePlayer(players[index]),
              readOnly: readOnly,
            ),
            if (index != players.length - 1)
              Divider(
                height: 1,
                indent: 58,
                color: scheme.outlineVariant.withValues(alpha: 0.62),
              ),
          ],
        ],
      ),
    );
  }
}

class _PlayerRosterCard extends StatelessWidget {
  final ManagedTeamPlayer player;
  final VoidCallback onEdit;
  final VoidCallback onRemove;
  final bool readOnly;

  const _PlayerRosterCard({
    required this.player,
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
    final metaLabel = [
      teamPlayerPositionLabel(l10n, player.effectivePosition),
      if (player.grade.trim().isNotEmpty) player.grade.trim(),
    ].join(' · ');
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: readOnly ? null : onEdit,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.sm,
            AppSpacing.xs,
            AppSpacing.xxs,
            AppSpacing.xs,
          ),
          child: Row(
            children: [
              _PlayerPhotoFrame(
                imageDataUrl: player.imageDataUrl,
                playerName: player.name,
                playerNumber: player.number,
                playerRole: player.role,
                playerPosition: player.effectivePosition,
                size: 42,
              ),
              const SizedBox(width: AppSpacing.xs),
              _PlayerPositionMiniPitch(player: player),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
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
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        _RosterConditionBadge(
                          label: teamPlayerConditionLabel(
                            l10n,
                            player.condition,
                          ),
                          color: conditionAccent,
                        ),
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
      ),
    );
  }
}

class _RosterConditionBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _RosterConditionBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(maxWidth: 76),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: AppRadius.small,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RosterStatusDot(color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
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

List<ManagedTeamPlayer> _sortRosterPlayers(List<ManagedTeamPlayer> players) {
  final sorted = List<ManagedTeamPlayer>.from(players);
  sorted.sort((a, b) {
    final positionOrder = _playerPositionSortIndex(a).compareTo(
      _playerPositionSortIndex(b),
    );
    if (positionOrder != 0) return positionOrder;
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

int _playerPositionSortIndex(ManagedTeamPlayer player) {
  return switch (player.effectivePosition) {
    ManagedTeamPlayer.positionGoalkeeper => 0,
    ManagedTeamPlayer.positionLeftBack => 10,
    ManagedTeamPlayer.positionCenterBack => 20,
    ManagedTeamPlayer.positionRightBack => 30,
    ManagedTeamPlayer.positionDefensiveMidfielder => 40,
    ManagedTeamPlayer.positionLeftMidfielder => 50,
    ManagedTeamPlayer.positionCentralMidfielder => 60,
    ManagedTeamPlayer.positionRightMidfielder => 70,
    ManagedTeamPlayer.positionAttackingMidfielder => 80,
    ManagedTeamPlayer.positionLeftWinger => 90,
    ManagedTeamPlayer.positionStriker => 100,
    ManagedTeamPlayer.positionRightWinger => 110,
    _ => 999,
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

  const _PanelTitle({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.10),
            borderRadius: AppRadius.small,
          ),
          child: Icon(icon, color: scheme.primary, size: 18),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
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
  final String? actionLabel;
  final VoidCallback? onAction;

  const _InlineEmptyMessage({
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
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
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                      onPressed: onAction,
                      child: Text(actionLabel!),
                    ),
                  ),
                ],
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

String teamPlayerPositionLabel(AppLocalizations l10n, String position) {
  return switch (position) {
    ManagedTeamPlayer.positionGoalkeeper =>
      l10n.teamManagementPositionGoalkeeper,
    ManagedTeamPlayer.positionLeftBack => l10n.teamManagementPositionLeftBack,
    ManagedTeamPlayer.positionCenterBack =>
      l10n.teamManagementPositionCenterBack,
    ManagedTeamPlayer.positionRightBack => l10n.teamManagementPositionRightBack,
    ManagedTeamPlayer.positionDefensiveMidfielder =>
      l10n.teamManagementPositionDefensiveMidfielder,
    ManagedTeamPlayer.positionLeftMidfielder =>
      l10n.teamManagementPositionLeftMidfielder,
    ManagedTeamPlayer.positionCentralMidfielder =>
      l10n.teamManagementPositionCentralMidfielder,
    ManagedTeamPlayer.positionRightMidfielder =>
      l10n.teamManagementPositionRightMidfielder,
    ManagedTeamPlayer.positionAttackingMidfielder =>
      l10n.teamManagementPositionAttackingMidfielder,
    ManagedTeamPlayer.positionLeftWinger =>
      l10n.teamManagementPositionLeftWinger,
    ManagedTeamPlayer.positionRightWinger =>
      l10n.teamManagementPositionRightWinger,
    _ => l10n.teamManagementPositionStriker,
  };
}

String teamPlayerPositionCode(String position, {required String role}) {
  return TeamManagementService.playerPositionCode(position, role: role);
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
