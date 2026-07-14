import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:intl/intl.dart';

import '../../application/club_schedule_service.dart';
import '../../application/family_access_service.dart';
import '../../application/match_competition_service.dart';
import '../../application/team_management_service.dart';
import '../../domain/repositories/option_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/app_page_route.dart';
import '../widgets/app_bar_action_button.dart';
import '../widgets/app_feedback.dart';
import '../widgets/uniform_jersey_swatch.dart';
import 'club_schedule_screen.dart';

enum _TacticBoardMode { assign, movement, press, zone }

enum _TeamManagementWorkspace { roster, board, profile, operations }

typedef _PlayerBoardDropCallback = void Function({
  required String playerId,
  required Offset point,
});

class TeamManagementScreen extends StatefulWidget {
  final OptionRepository optionRepository;
  final String? sportId;
  final bool readOnly;

  const TeamManagementScreen({
    super.key,
    required this.optionRepository,
    this.sportId,
    this.readOnly = false,
  });

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen> {
  late final TeamManagementService _teamService;
  late final ClubScheduleService _clubScheduleService;
  late final MatchCompetitionService _competitionService;
  final TextEditingController _teamNameController = TextEditingController();
  final TextEditingController _strategyController = TextEditingController();
  final TextEditingController _playerNameController = TextEditingController();
  final TextEditingController _playerNumberController = TextEditingController();
  final TextEditingController _playerNoteController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _autoSaveDebounce;

  ClubScheduleProfile _clubProfile = ClubScheduleProfile.empty();
  List<MatchCompetitionRecord> _competitions = const <MatchCompetitionRecord>[];
  ManagedTeam? _selectedTeam;
  List<ManagedTeamPlayer> _players = const <ManagedTeamPlayer>[];
  Map<String, String> _lineup = const <String, String>{};
  Map<String, ManagedPlayerPlacement> _playerPlacements =
      const <String, ManagedPlayerPlacement>{};
  List<ManagedTacticLine> _tacticLines = const <ManagedTacticLine>[];
  String _formation = ManagedTeam.defaultFormation;
  String _playerRole = ManagedTeamPlayer.roleForward;
  String _playerFoot = ManagedTeamPlayer.footRight;
  String _playerCondition = ManagedTeamPlayer.conditionReady;
  String? _editingPlayerId;
  _TeamManagementWorkspace _activeWorkspace = _TeamManagementWorkspace.roster;
  _TacticBoardMode _boardMode = _TacticBoardMode.assign;
  ManagedTacticLine? _draftTacticLine;
  bool _loaded = false;
  bool _saving = false;
  bool _hasPendingAutoSave = false;
  bool _suppressAutoSave = false;
  int _changeRevision = 0;
  int _savedRevision = 0;
  DateTime? _lastAutoSavedAt;

  @override
  void initState() {
    super.initState();
    _teamService = TeamManagementService(
      widget.optionRepository,
      sportId: widget.sportId,
    );
    _clubScheduleService = ClubScheduleService(
      widget.optionRepository,
      sportId: widget.sportId,
    );
    _competitionService = MatchCompetitionService(
      widget.optionRepository,
      sportId: widget.sportId,
    );
    _refreshOperationsData(setStateAfterLoad: false);
    _teamNameController.addListener(_handleTextFieldChanged);
    _strategyController.addListener(_handleTextFieldChanged);
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
    _playerNameController.dispose();
    _playerNumberController.dispose();
    _playerNoteController.dispose();
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
    _hasPendingAutoSave = false;
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

  void _refreshOperationsData({bool setStateAfterLoad = true}) {
    final nextProfile = _clubScheduleService.loadProfile();
    final nextCompetitions = _competitionService.allCompetitions();
    if (!setStateAfterLoad || !mounted) {
      _clubProfile = nextProfile;
      _competitions = nextCompetitions;
      return;
    }
    setState(() {
      _clubProfile = nextProfile;
      _competitions = nextCompetitions;
    });
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
    if (!mounted) return;
    _refreshOperationsData();
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
    return ManagedTeam.create(name: l10n.teamManagementDefaultTeamName);
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
    _playerPlacements = team.playerPlacements.isNotEmpty
        ? Map<String, ManagedPlayerPlacement>.from(team.playerPlacements)
        : TeamManagementService.placementsFromLineup(
            lineup: _lineup,
            players: _players,
            formation: _formation,
          );
    _tacticLines = List<ManagedTacticLine>.from(team.tacticLines);
    _editingPlayerId = null;
    _playerRole = ManagedTeamPlayer.roleForward;
    _playerFoot = ManagedTeamPlayer.footRight;
    _playerCondition = ManagedTeamPlayer.conditionReady;
    _boardMode = _TacticBoardMode.assign;
    _draftTacticLine = null;
    _hasPendingAutoSave = false;
    _changeRevision = 0;
    _savedRevision = 0;
    _lastAutoSavedAt = saved ? team.updatedAt : null;
    _suppressAutoSave = true;
    _teamNameController.text = team.name;
    _strategyController.text = team.strategy;
    _clearPlayerForm();
    _suppressAutoSave = false;
    setState(() {});
  }

  ManagedTeam _currentTeam() {
    final base = _selectedTeam ?? ManagedTeam.create(name: '');
    return base.copyWith(
      name: _teamNameController.text.trim(),
      formation: _formation,
      strategy: _strategyController.text.trim(),
      players: _players,
      lineup: _lineup,
      playerPlacements: _playerPlacements,
      tacticLines: _tacticLines,
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
      setState(() => _hasPendingAutoSave = true);
    } else {
      _hasPendingAutoSave = true;
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
      if (mounted) setState(() => _hasPendingAutoSave = false);
      return;
    }
    final name = _teamNameController.text.trim();
    if (name.isEmpty) {
      if (showFeedback) {
        AppFeedback.showMessage(context, text: l10n.teamManagementNameRequired);
      }
      if (mounted) setState(() => _hasPendingAutoSave = false);
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
        _hasPendingAutoSave = _changeRevision > _savedRevision;
        _lastAutoSavedAt = DateTime.now();
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

  void _savePlayer() {
    if (_blockReadOnlyMutation()) return;
    final l10n = AppLocalizations.of(context)!;
    final name = _playerNameController.text.trim();
    if (name.isEmpty) {
      AppFeedback.showMessage(context, text: l10n.teamManagementPlayerRequired);
      return;
    }
    final editingPlayerId = _editingPlayerId;
    setState(() {
      if (editingPlayerId == null) {
        final player = ManagedTeamPlayer.create(
          name: name,
          number: _playerNumberController.text.trim(),
          role: _playerRole,
          foot: _playerFoot,
          condition: _playerCondition,
          note: _playerNoteController.text.trim(),
        );
        _players =
            TeamManagementService.normalizePlayers([..._players, player]);
      } else {
        _players = TeamManagementService.normalizePlayers(
          _players.map((player) {
            if (player.id != editingPlayerId) return player;
            return player.copyWith(
              name: name,
              number: _playerNumberController.text.trim(),
              role: _playerRole,
              foot: _playerFoot,
              condition: _playerCondition,
              note: _playerNoteController.text.trim(),
            );
          }),
        );
      }
      _clearPlayerForm();
    });
    _scheduleAutoSave();
  }

  void _editPlayer(ManagedTeamPlayer player) {
    if (_blockReadOnlyMutation()) return;
    setState(() {
      _editingPlayerId = player.id;
      _playerNameController.text = player.name;
      _playerNumberController.text = player.number;
      _playerRole = player.role;
      _playerFoot = player.foot;
      _playerCondition = player.condition;
      _playerNoteController.text = player.note;
    });
  }

  void _cancelPlayerEdit() {
    setState(_clearPlayerForm);
  }

  void _clearPlayerForm() {
    _editingPlayerId = null;
    _playerNameController.clear();
    _playerNumberController.clear();
    _playerNoteController.clear();
    _playerRole = ManagedTeamPlayer.roleForward;
    _playerFoot = ManagedTeamPlayer.footRight;
    _playerCondition = ManagedTeamPlayer.conditionReady;
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
    });
    _scheduleAutoSave();
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
    setState(() {
      if (distance >= 0.04) {
        _tacticLines = TeamManagementService.normalizeTacticLines([
          ..._tacticLines,
          draft.copyWith(
              id: TeamManagementService.tacticLineId(
            now: DateTime.now(),
          )),
        ]);
      }
      _draftTacticLine = null;
    });
    if (distance >= 0.04) {
      _scheduleAutoSave();
    }
  }

  void _clearTacticLines() {
    if (_blockReadOnlyMutation()) return;
    setState(() {
      _tacticLines = const <ManagedTacticLine>[];
      _draftTacticLine = null;
    });
    _scheduleAutoSave();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final readOnly = _isReadOnlySupportMode;
    final totalBoardPlayers = _players.length;
    final placedCount = _playerPlacements.length;
    final activeCompetitions =
        _competitions.where((competition) => !competition.isFinished).length;
    return Scaffold(
      body: ColoredBox(
        color: theme.scaffoldBackgroundColor,
        child: SafeArea(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TeamManagementHeader(
                  onBack: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(height: AppSpacing.sm),
                _TeamWorkspaceSwitcher(
                  activeWorkspace: _activeWorkspace,
                  playerCount: _players.length,
                  placedCount: placedCount,
                  totalPlayers: totalBoardPlayers,
                  activeCompetitions: activeCompetitions,
                  totalCompetitions: _competitions.length,
                  onWorkspaceChanged: (workspace) {
                    setState(() => _activeWorkspace = workspace);
                    if (_scrollController.hasClients) {
                      unawaited(
                        _scrollController.animateTo(
                          0,
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                _TeamManagementHero(
                  teamName: _teamNameController.text.trim().isEmpty
                      ? l10n.teamManagementDefaultTeamName
                      : _teamNameController.text.trim(),
                  playerCount: _players.length,
                  placedCount: placedCount,
                  totalPlayers: totalBoardPlayers,
                  tacticLineCount: _tacticLines.length,
                  saving: _saving,
                  pending: !readOnly &&
                      (_hasPendingAutoSave || _changeRevision > _savedRevision),
                  needsName: _teamNameController.text.trim().isEmpty,
                  lastSavedAt: _lastAutoSavedAt,
                ),
                const SizedBox(height: AppSpacing.md),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: KeyedSubtree(
                    key: ValueKey<_TeamManagementWorkspace>(_activeWorkspace),
                    child: _buildActiveWorkspace(readOnly),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveWorkspace(bool readOnly) {
    switch (_activeWorkspace) {
      case _TeamManagementWorkspace.roster:
        return _PlayersPanel(
          players: _players,
          lineup: _lineup,
          playerPlacements: _playerPlacements,
          playerNameController: _playerNameController,
          playerNumberController: _playerNumberController,
          playerNoteController: _playerNoteController,
          playerRole: _playerRole,
          playerFoot: _playerFoot,
          playerCondition: _playerCondition,
          editingPlayerId: _editingPlayerId,
          readOnly: readOnly,
          onRoleChanged: (role) => setState(() => _playerRole = role),
          onFootChanged: (foot) => setState(() => _playerFoot = foot),
          onConditionChanged: (condition) =>
              setState(() => _playerCondition = condition),
          onSavePlayer: _savePlayer,
          onCancelPlayerEdit: _cancelPlayerEdit,
          onEditPlayer: _editPlayer,
          onRemovePlayer: _removePlayer,
        );
      case _TeamManagementWorkspace.board:
        return _TacticsBoardPanel(
          players: _players,
          playerPlacements: _playerPlacements,
          tacticLines: _tacticLines,
          draftTacticLine: _draftTacticLine,
          boardMode: _boardMode,
          readOnly: readOnly,
          onPlayerPlaced: _placePlayerOnBoard,
          onBoardModeChanged: _changeBoardMode,
          onTacticLineStarted: _startTacticLine,
          onTacticLineUpdated: _updateTacticLine,
          onTacticLineFinished: _finishTacticLine,
          onClearTacticLines: _clearTacticLines,
        );
      case _TeamManagementWorkspace.profile:
        return _TeamBasicsPanel(
          teamNameController: _teamNameController,
          strategyController: _strategyController,
          readOnly: readOnly,
        );
      case _TeamManagementWorkspace.operations:
        return _ScheduleCompetitionPanel(
          profile: _clubProfile,
          competitions: _competitions,
          onOpenSchedule: () => unawaited(_openClubSchedule()),
        );
    }
  }
}

class _TeamWorkspaceSwitcher extends StatelessWidget {
  final _TeamManagementWorkspace activeWorkspace;
  final int playerCount;
  final int placedCount;
  final int totalPlayers;
  final int activeCompetitions;
  final int totalCompetitions;
  final ValueChanged<_TeamManagementWorkspace> onWorkspaceChanged;

  const _TeamWorkspaceSwitcher({
    required this.activeWorkspace,
    required this.playerCount,
    required this.placedCount,
    required this.totalPlayers,
    required this.activeCompetitions,
    required this.totalCompetitions,
    required this.onWorkspaceChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final items = [
      _WorkspaceItem(
        workspace: _TeamManagementWorkspace.roster,
        icon: Icons.groups_2_outlined,
        label: l10n.teamManagementWorkspaceRosterTab,
        value: l10n.teamManagementPlayerCount(playerCount),
      ),
      _WorkspaceItem(
        workspace: _TeamManagementWorkspace.board,
        icon: Icons.grid_view_outlined,
        label: l10n.teamManagementWorkspaceBoardTab,
        value: l10n.teamManagementBoardPlacementValue(
          placedCount,
          totalPlayers,
        ),
      ),
      _WorkspaceItem(
        workspace: _TeamManagementWorkspace.profile,
        icon: Icons.route_outlined,
        label: l10n.teamManagementWorkspaceProfileTab,
        value: l10n.teamManagementWorkspaceProfileValue,
      ),
      _WorkspaceItem(
        workspace: _TeamManagementWorkspace.operations,
        icon: Icons.event_available_outlined,
        label: l10n.teamManagementWorkspaceOperationsTab,
        value: l10n.teamManagementOperationsCompetitionsValue(
          activeCompetitions,
          totalCompetitions,
        ),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.34)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.72),
        borderRadius: AppRadius.small,
        border: Border.all(
          color: AppSurfaces.borderColor(scheme, theme.brightness),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 128),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.dashboard_customize_outlined,
                    color: scheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  Flexible(
                    child: Text(
                      l10n.teamManagementWorkspaceTitle,
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
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final item in items) ...[
                    _WorkspaceTabButton(
                      item: item,
                      selected: activeWorkspace == item.workspace,
                      onTap: () => onWorkspaceChanged(item.workspace),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceItem {
  final _TeamManagementWorkspace workspace;
  final IconData icon;
  final String label;
  final String value;

  const _WorkspaceItem({
    required this.workspace,
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _WorkspaceTabButton extends StatelessWidget {
  final _WorkspaceItem item;
  final bool selected;
  final VoidCallback onTap;

  const _WorkspaceTabButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final foreground = selected ? scheme.onPrimary : scheme.onSurface;
    final helperColor = selected
        ? scheme.onPrimary.withValues(alpha: 0.78)
        : scheme.onSurfaceVariant;
    final background = selected ? scheme.primary : scheme.surface;
    return Material(
      color: background,
      borderRadius: AppRadius.small,
      child: InkWell(
        onTap: selected ? null : onTap,
        borderRadius: AppRadius.small,
        child: Container(
          constraints: const BoxConstraints(
            minWidth: 136,
            maxWidth: 168,
            minHeight: 48,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.small,
            border: Border.all(
              color: selected
                  ? scheme.primary
                  : AppSurfaces.borderColor(scheme, theme.brightness),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, color: foreground, size: 18),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      item.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: helperColor,
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

class _TeamManagementHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _TeamManagementHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Row(
      children: [
        AppBarActionButton.icon(
          icon: Icons.arrow_back,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: onBack,
          margin: EdgeInsets.zero,
        ),
        const SizedBox(width: AppSpacing.sm),
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
              const SizedBox(height: AppSpacing.xxs),
              Text(
                l10n.teamManagementSubtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TeamManagementHero extends StatelessWidget {
  final String teamName;
  final int playerCount;
  final int placedCount;
  final int totalPlayers;
  final int tacticLineCount;
  final bool saving;
  final bool pending;
  final bool needsName;
  final DateTime? lastSavedAt;

  const _TeamManagementHero({
    required this.teamName,
    required this.playerCount,
    required this.placedCount,
    required this.totalPlayers,
    required this.tacticLineCount,
    required this.saving,
    required this.pending,
    required this.needsName,
    required this.lastSavedAt,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      decoration: AppSurfaces.heroDecoration(
        scheme,
        theme.brightness,
        accent: const Color(0xFF1F8A70),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: AppRadius.small,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.24),
                  ),
                ),
                child: const Icon(
                  Icons.groups_2_outlined,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      teamName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      l10n.teamManagementSaveHint,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.84),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _AutoSaveChip(
                saving: saving,
                pending: pending,
                needsName: needsName,
                saved: lastSavedAt != null,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _TeamHeroMetricPill(
                label: l10n.teamManagementPlayersTitle,
                value: l10n.teamManagementPlayerCount(playerCount),
              ),
              _TeamHeroMetricPill(
                label: l10n.teamManagementBoardPlacementLabel,
                value: l10n.teamManagementBoardPlacementValue(
                  placedCount,
                  totalPlayers,
                ),
              ),
              _TeamHeroMetricPill(
                label: l10n.teamManagementBoardMarkerLabel,
                value: l10n.teamManagementTacticLinesCount(tacticLineCount),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TeamHeroMetricPill extends StatelessWidget {
  final String label;
  final String value;

  const _TeamHeroMetricPill({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 136),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: AppRadius.small,
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.78),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _AutoSaveChip extends StatelessWidget {
  final bool saving;
  final bool pending;
  final bool needsName;
  final bool saved;

  const _AutoSaveChip({
    required this.saving,
    required this.pending,
    required this.needsName,
    required this.saved,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = needsName
        ? l10n.teamManagementAutoSaveNeedsName
        : saving
            ? l10n.teamManagementAutoSaveSaving
            : pending
                ? l10n.teamManagementAutoSavePending
                : saved
                    ? l10n.teamManagementAutoSaveSaved
                    : l10n.teamManagementAutoSaveReady;
    final icon = needsName
        ? Icons.info_outline
        : saving || pending
            ? Icons.sync_outlined
            : Icons.cloud_done_outlined;
    return Container(
      constraints: const BoxConstraints(maxWidth: 148),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: AppRadius.full,
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: AppSpacing.xxs),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamBasicsPanel extends StatelessWidget {
  final TextEditingController teamNameController;
  final TextEditingController strategyController;
  final bool readOnly;

  const _TeamBasicsPanel({
    required this.teamNameController,
    required this.strategyController,
    required this.readOnly,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      decoration: AppSurfaces.cardDecoration(scheme, theme.brightness),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelTitle(
            icon: Icons.route_outlined,
            title: l10n.teamManagementBasicsTitle,
            helper: l10n.teamManagementBasicsHelper,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: teamNameController,
            readOnly: readOnly,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: l10n.teamManagementTeamNameLabel,
              hintText: l10n.teamManagementTeamNameHint,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: strategyController,
            readOnly: readOnly,
            minLines: 3,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: l10n.teamManagementStrategyLabel,
              hintText: l10n.teamManagementStrategyHint,
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleCompetitionPanel extends StatelessWidget {
  final ClubScheduleProfile profile;
  final List<MatchCompetitionRecord> competitions;
  final VoidCallback onOpenSchedule;

  const _ScheduleCompetitionPanel({
    required this.profile,
    required this.competitions,
    required this.onOpenSchedule,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final upcomingTraining = profile.upcomingTraining(DateTime.now());
    final activeCompetitions =
        competitions.where((competition) => !competition.isFinished).length;

    return Container(
      decoration: AppSurfaces.cardDecoration(scheme, theme.brightness),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelTitle(
            icon: Icons.event_available_outlined,
            title: l10n.teamManagementOperationsScheduleTitle,
            helper: l10n.teamManagementOperationsScheduleHelper,
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 720 ? 2 : 1;
              final gap = AppSpacing.sm * (columns - 1);
              final itemWidth = (constraints.maxWidth - gap) / columns;
              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: _OperationsDetailPanel(
                      icon: Icons.schedule_outlined,
                      title: l10n.teamManagementOperationsScheduleTitle,
                      body: upcomingTraining == null
                          ? l10n.teamManagementOperationsNoTraining
                          : l10n.clubScheduleNextTraining(
                              _teamScheduleWeekdayLabel(
                                context,
                                upcomingTraining.date,
                              ),
                              _teamScheduleTimeRange(
                                context,
                                upcomingTraining.schedule,
                              ),
                            ),
                      trailing: FilledButton.icon(
                        onPressed: onOpenSchedule,
                        icon: const Icon(Icons.edit_calendar_outlined),
                        label: Text(
                          l10n.teamManagementOperationsOpenScheduleButton,
                        ),
                      ),
                      children: [
                        const SizedBox(height: AppSpacing.sm),
                        _UniformSummary(profile: profile),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _OperationsDetailPanel(
                      icon: Icons.emoji_events_outlined,
                      title: l10n.teamManagementOperationsCompetitionTitle,
                      body: l10n.teamManagementOperationsCompetitionsValue(
                        activeCompetitions,
                        competitions.length,
                      ),
                      children: [
                        const SizedBox(height: AppSpacing.sm),
                        if (competitions.isEmpty)
                          Text(
                            l10n.teamManagementOperationsNoCompetitions,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.3,
                            ),
                          )
                        else
                          ...competitions.take(3).map(
                                (competition) => Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.xs,
                                  ),
                                  child: _CompetitionStatusRow(
                                    competition: competition,
                                  ),
                                ),
                              ),
                      ],
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

class _OperationsDetailPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Widget? trailing;
  final List<Widget> children;

  const _OperationsDetailPanel({
    required this.icon,
    required this.title,
    required this.body,
    this.trailing,
    this.children = const <Widget>[],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 188),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppSurfaces.subtleDecoration(
        scheme,
        theme.brightness,
        accent: scheme.primary,
        accentAlpha: 0.04,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: scheme.primary, size: 22),
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
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (children.isNotEmpty) ...children,
          if (trailing != null) ...[
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: trailing,
            ),
          ],
        ],
      ),
    );
  }
}

class _UniformSummary extends StatelessWidget {
  final ClubScheduleProfile profile;

  const _UniformSummary({required this.profile});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final items = [
      (
        label: l10n.clubScheduleHomeKitLabel,
        color: Color(profile.homeUniformColorValue),
      ),
      (
        label: l10n.clubScheduleAwayKitLabel,
        color: Color(profile.awayUniformColorValue),
      ),
      (
        label: l10n.clubScheduleKeeperKitLabel,
        color: Color(profile.keeperUniformColorValue),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.teamManagementOperationsUniformLabel,
          style: theme.textTheme.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            for (final item in items)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  UniformJerseySwatch(
                    color: item.color,
                    size: 28,
                    borderColor: scheme.outlineVariant,
                    semanticLabel: item.label,
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  Text(
                    item.label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class _CompetitionStatusRow extends StatelessWidget {
  final MatchCompetitionRecord competition;

  const _CompetitionStatusRow({required this.competition});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isLeague = competition.kind == MatchCompetitionRecord.kindLeague;
    final label = competition.isFinished
        ? l10n.matchCompetitionStatusFinished
        : l10n.matchCompetitionStatusActive;
    return Row(
      children: [
        Icon(
          isLeague ? Icons.table_chart_outlined : Icons.account_tree,
          color: scheme.primary,
          size: 18,
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            competition.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        _MiniStatusChip(label: label, active: !competition.isFinished),
      ],
    );
  }
}

class _MiniStatusChip extends StatelessWidget {
  final String label;
  final bool active;

  const _MiniStatusChip({
    required this.label,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = active ? scheme.primary : scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: AppRadius.full,
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _TacticsBoardPanel extends StatelessWidget {
  final List<ManagedTeamPlayer> players;
  final Map<String, ManagedPlayerPlacement> playerPlacements;
  final List<ManagedTacticLine> tacticLines;
  final ManagedTacticLine? draftTacticLine;
  final _TacticBoardMode boardMode;
  final bool readOnly;
  final _PlayerBoardDropCallback onPlayerPlaced;
  final ValueChanged<_TacticBoardMode> onBoardModeChanged;
  final ValueChanged<Offset> onTacticLineStarted;
  final ValueChanged<Offset> onTacticLineUpdated;
  final VoidCallback onTacticLineFinished;
  final VoidCallback onClearTacticLines;

  const _TacticsBoardPanel({
    required this.players,
    required this.playerPlacements,
    required this.tacticLines,
    required this.draftTacticLine,
    required this.boardMode,
    required this.readOnly,
    required this.onPlayerPlaced,
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

    return Container(
      decoration: AppSurfaces.cardDecoration(scheme, theme.brightness),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelTitle(
            icon: Icons.grid_view_outlined,
            title: l10n.teamManagementFormationTitle,
            helper: l10n.teamManagementFormationHelper,
          ),
          const SizedBox(height: AppSpacing.md),
          _BoardModeToolbar(
            mode: boardMode,
            tacticLineCount: tacticLines.length,
            readOnly: readOnly,
            onModeChanged: onBoardModeChanged,
            onClearTacticLines: onClearTacticLines,
          ),
          const SizedBox(height: AppSpacing.sm),
          _BoardPlayerTray(
            players: players,
            playerPlacements: playerPlacements,
            readOnly: readOnly,
          ),
          const SizedBox(height: AppSpacing.md),
          _TacticsPitch(
            players: players,
            playerPlacements: playerPlacements,
            tacticLines: tacticLines,
            draftTacticLine: draftTacticLine,
            boardMode: boardMode,
            readOnly: readOnly,
            onPlayerPlaced: onPlayerPlaced,
            onTacticLineStarted: onTacticLineStarted,
            onTacticLineUpdated: onTacticLineUpdated,
            onTacticLineFinished: onTacticLineFinished,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.teamManagementFormationDropHint,
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

class _BoardModeToolbar extends StatelessWidget {
  final _TacticBoardMode mode;
  final int tacticLineCount;
  final bool readOnly;
  final ValueChanged<_TacticBoardMode> onModeChanged;
  final VoidCallback onClearTacticLines;

  const _BoardModeToolbar({
    required this.mode,
    required this.tacticLineCount,
    required this.readOnly,
    required this.onModeChanged,
    required this.onClearTacticLines,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SegmentedButton<_TacticBoardMode>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment<_TacticBoardMode>(
              value: _TacticBoardMode.assign,
              icon: const Icon(Icons.open_with_outlined),
              label: Text(l10n.teamManagementBoardMovePlayersMode),
            ),
            ButtonSegment<_TacticBoardMode>(
              value: _TacticBoardMode.movement,
              icon: const Icon(Icons.timeline_outlined),
              label: Text(l10n.teamManagementBoardMovementMode),
            ),
            ButtonSegment<_TacticBoardMode>(
              value: _TacticBoardMode.press,
              icon: const Icon(Icons.keyboard_double_arrow_up_outlined),
              label: Text(l10n.teamManagementBoardPressMode),
            ),
            ButtonSegment<_TacticBoardMode>(
              value: _TacticBoardMode.zone,
              icon: const Icon(Icons.crop_free_outlined),
              label: Text(l10n.teamManagementBoardZoneMode),
            ),
          ],
          selected: {mode},
          onSelectionChanged:
              readOnly ? null : (values) => onModeChanged(values.first),
        ),
        OutlinedButton.icon(
          onPressed:
              readOnly || tacticLineCount == 0 ? null : onClearTacticLines,
          icon: const Icon(Icons.cleaning_services_outlined),
          label: Text(l10n.teamManagementBoardClearMarkersButton),
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

class _BoardPlayerTray extends StatelessWidget {
  final List<ManagedTeamPlayer> players;
  final Map<String, ManagedPlayerPlacement> playerPlacements;
  final bool readOnly;

  const _BoardPlayerTray({
    required this.players,
    required this.playerPlacements,
    required this.readOnly,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    if (players.isEmpty) {
      return _InlineEmptyMessage(
        icon: Icons.swipe_outlined,
        title: l10n.teamManagementPlayerTrayTitle,
        body: l10n.teamManagementPlayerTrayEmpty,
      );
    }
    final assignedPlayerIds = playerPlacements.keys.toSet();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.teamManagementPlayerTrayTitle,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final player in players) ...[
                if (readOnly)
                  _BoardPlayerChip(
                    player: player,
                    assigned: assignedPlayerIds.contains(player.id),
                  )
                else
                  Draggable<String>(
                    data: player.id,
                    feedback: Material(
                      color: Colors.transparent,
                      child: _BoardPlayerChip(
                        player: player,
                        assigned: assignedPlayerIds.contains(player.id),
                        elevated: true,
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.42,
                      child: _BoardPlayerChip(
                        player: player,
                        assigned: assignedPlayerIds.contains(player.id),
                      ),
                    ),
                    child: _BoardPlayerChip(
                      player: player,
                      assigned: assignedPlayerIds.contains(player.id),
                    ),
                  ),
                const SizedBox(width: AppSpacing.xs),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _BoardPlayerChip extends StatelessWidget {
  final ManagedTeamPlayer player;
  final bool assigned;
  final bool elevated;

  const _BoardPlayerChip({
    required this.player,
    required this.assigned,
    this.elevated = false,
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
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.drag_indicator,
              size: 18,
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
  final bool readOnly;
  final _PlayerBoardDropCallback onPlayerPlaced;
  final ValueChanged<Offset> onTacticLineStarted;
  final ValueChanged<Offset> onTacticLineUpdated;
  final VoidCallback onTacticLineFinished;

  const _TacticsPitch({
    required this.players,
    required this.playerPlacements,
    required this.tacticLines,
    required this.draftTacticLine,
    required this.boardMode,
    required this.readOnly,
    required this.onPlayerPlaced,
    required this.onTacticLineStarted,
    required this.onTacticLineUpdated,
    required this.onTacticLineFinished,
  });

  @override
  Widget build(BuildContext context) {
    final playerById = {for (final player in players) player.id: player};
    return LayoutBuilder(
      builder: (context, outerConstraints) {
        final boardHeight = outerConstraints.maxWidth >= 700 ? 680.0 : 560.0;
        return SizedBox(
          height: boardHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              const markerWidth = 76.0;
              const markerHeight = 60.0;
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
                    : (details) => onPlayerPlaced(
                          playerId: details.data,
                          point: normalizeFromGlobal(details.offset),
                        ),
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
        );
      },
    );
  }
}

class _BoardPlacedPlayer extends StatelessWidget {
  final ManagedTeamPlayer player;
  final bool draggable;

  const _BoardPlacedPlayer({
    required this.player,
    required this.draggable,
  });

  @override
  Widget build(BuildContext context) {
    final marker = _PitchPlayerMarker(player: player);
    if (!draggable) return marker;
    return Draggable<String>(
      data: player.id,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(width: 76, height: 60, child: marker),
      ),
      childWhenDragging: Opacity(opacity: 0.36, child: marker),
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
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxs,
        ),
        child: Stack(
          children: [
            PositionedDirectional(
              top: 0,
              end: 0,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: condition,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
            Center(
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
                    ),
                  ),
                  Text(
                    _playerInitialLabel(player),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF111827),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
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

class _PitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF166534), Color(0xFF0F5132)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint);

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.52)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final thinLinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.26)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final rect = Rect.fromLTWH(14, 14, size.width - 28, size.height - 28);
    canvas.drawRect(rect, linePaint);
    canvas.drawLine(
      Offset(14, size.height / 2),
      Offset(size.width - 14, size.height / 2),
      linePaint,
    );
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 42, linePaint);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 3, linePaint);
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.width / 2, 14),
        width: size.width * 0.46,
        height: size.height * 0.16,
      ),
      thinLinePaint,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height - 14),
        width: size.width * 0.46,
        height: size.height * 0.16,
      ),
      thinLinePaint,
    );
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
  final TextEditingController playerNameController;
  final TextEditingController playerNumberController;
  final TextEditingController playerNoteController;
  final String playerRole;
  final String playerFoot;
  final String playerCondition;
  final String? editingPlayerId;
  final bool readOnly;
  final ValueChanged<String> onRoleChanged;
  final ValueChanged<String> onFootChanged;
  final ValueChanged<String> onConditionChanged;
  final VoidCallback onSavePlayer;
  final VoidCallback onCancelPlayerEdit;
  final ValueChanged<ManagedTeamPlayer> onEditPlayer;
  final ValueChanged<ManagedTeamPlayer> onRemovePlayer;

  const _PlayersPanel({
    required this.players,
    required this.lineup,
    required this.playerPlacements,
    required this.playerNameController,
    required this.playerNumberController,
    required this.playerNoteController,
    required this.playerRole,
    required this.playerFoot,
    required this.playerCondition,
    required this.editingPlayerId,
    required this.readOnly,
    required this.onRoleChanged,
    required this.onFootChanged,
    required this.onConditionChanged,
    required this.onSavePlayer,
    required this.onCancelPlayerEdit,
    required this.onEditPlayer,
    required this.onRemovePlayer,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      decoration: AppSurfaces.cardDecoration(scheme, theme.brightness),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelTitle(
            icon: Icons.person_add_alt_outlined,
            title: l10n.teamManagementPlayersTitle,
            helper: l10n.teamManagementPlayersHelper,
          ),
          const SizedBox(height: AppSpacing.md),
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
                  selected: playerRole == role,
                  onSelected: readOnly ? null : (_) => onRoleChanged(role),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 620;
              final nameField = TextField(
                controller: playerNameController,
                readOnly: readOnly,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.teamManagementPlayerNameLabel,
                  hintText: l10n.teamManagementPlayerNameHint,
                ),
              );
              final numberField = TextField(
                controller: playerNumberController,
                readOnly: readOnly,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.teamManagementPlayerNumberLabel,
                  hintText: l10n.teamManagementPlayerNumberHint,
                ),
              );
              final saveButton = FilledButton.icon(
                onPressed: readOnly ? null : onSavePlayer,
                icon: Icon(
                  editingPlayerId == null
                      ? Icons.add_outlined
                      : Icons.save_outlined,
                ),
                label: Text(
                  editingPlayerId == null
                      ? l10n.teamManagementAddPlayerButton
                      : l10n.teamManagementUpdatePlayerButton,
                ),
              );
              final cancelButton = OutlinedButton.icon(
                onPressed: readOnly ? null : onCancelPlayerEdit,
                icon: const Icon(Icons.close_outlined),
                label: Text(l10n.teamManagementCancelPlayerEditButton),
              );
              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(flex: 3, child: nameField),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: numberField),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        if (editingPlayerId != null) ...[
                          Expanded(child: cancelButton),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        Expanded(flex: 2, child: saveButton),
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
                  if (editingPlayerId != null) ...[
                    SizedBox(width: 140, child: cancelButton),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  SizedBox(width: 148, child: saveButton),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          LayoutBuilder(
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
                      initialValue: playerFoot,
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
                      onChanged: readOnly
                          ? null
                          : (foot) {
                              if (foot == null) return;
                              onFootChanged(foot);
                            },
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: DropdownButtonFormField<String>(
                      initialValue: playerCondition,
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
                      onChanged: readOnly
                          ? null
                          : (condition) {
                              if (condition == null) return;
                              onConditionChanged(condition);
                            },
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: playerNoteController,
            readOnly: readOnly,
            minLines: 2,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: l10n.teamManagementPlayerNoteLabel,
              hintText: l10n.teamManagementPlayerNoteHint,
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.10),
                borderRadius: AppRadius.small,
              ),
              child: Icon(
                Icons.view_module_outlined,
                color: scheme.primary,
                size: 19,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.teamManagementRosterBoardTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    l10n.teamManagementRosterBoardHelper,
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
    final scheme = theme.colorScheme;
    final accent = _playerRoleAccent(role);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppRadius.small,
        border: Border.all(color: accent.withValues(alpha: 0.26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: AppRadius.small,
                ),
                child: Icon(
                  _playerRoleIcon(role),
                  color: accent,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  l10n.teamManagementRoleGroupCount(
                    teamPlayerRoleLabel(l10n, role),
                    players.length,
                  ),
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
          for (final player in players) ...[
            _PlayerRosterCard(
              player: player,
              assignedCount: assignedCountFor(player),
              accent: accent,
              onEdit: () => onEditPlayer(player),
              onRemove: () => onRemovePlayer(player),
              readOnly: readOnly,
            ),
            if (player != players.last) const SizedBox(height: AppSpacing.xs),
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
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.36)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: AppRadius.small,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 56,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.13),
                  borderRadius: AppRadius.small,
                  border: Border.all(color: accent.withValues(alpha: 0.28)),
                ),
                alignment: Alignment.center,
                child: Text(
                  player.number.isEmpty
                      ? teamPlayerRoleShortLabel(player.role)
                      : player.number,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Wrap(
                      spacing: AppSpacing.xxs,
                      runSpacing: AppSpacing.xxs,
                      children: [
                        _RosterMetaChip(
                          label: teamPlayerFootLabel(l10n, player.foot),
                          color: accent,
                        ),
                        _RosterMetaChip(
                          label: teamPlayerConditionLabel(
                            l10n,
                            player.condition,
                          ),
                          color: conditionAccent,
                        ),
                        _RosterMetaChip(
                          label: assignedCount > 0
                              ? l10n.teamManagementRosterPlacementCount(
                                  assignedCount,
                                )
                              : l10n.teamManagementRosterNoPlacement,
                          color: assignedCount > 0
                              ? scheme.primary
                              : scheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 38,
                    height: 38,
                    child: IconButton.outlined(
                      onPressed: readOnly ? null : onEdit,
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: l10n.teamManagementEditPlayerButton,
                      style: IconButton.styleFrom(
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  SizedBox(
                    width: 38,
                    height: 38,
                    child: IconButton.outlined(
                      onPressed: readOnly ? null : onRemove,
                      icon: const Icon(Icons.delete_outline),
                      tooltip: l10n.teamManagementRemovePlayerButton,
                      style: IconButton.styleFrom(
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (player.note.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              player.note.trim(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RosterMetaChip extends StatelessWidget {
  final String label;
  final Color color;

  const _RosterMetaChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: AppRadius.full,
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
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

class _PanelTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String helper;

  const _PanelTitle({
    required this.icon,
    required this.title,
    required this.helper,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.10),
            borderRadius: AppRadius.small,
          ),
          child: Icon(icon, color: scheme.primary, size: 20),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                helper,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.3,
                ),
              ),
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

String _teamScheduleWeekdayLabel(BuildContext context, DateTime date) {
  final locale = Localizations.localeOf(context).toString();
  return DateFormat.E(locale).format(date);
}

String _teamScheduleTimeRange(
  BuildContext context,
  ClubTrainingSchedule schedule,
) {
  return '${_teamScheduleTimeLabel(context, schedule.startMinutes)}-'
      '${_teamScheduleTimeLabel(context, schedule.endMinutes)}';
}

String _teamScheduleTimeLabel(BuildContext context, int minutes) {
  final time = TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
  return MaterialLocalizations.of(context).formatTimeOfDay(
    time,
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );
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
