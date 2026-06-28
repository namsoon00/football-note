import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:football_note/gen/app_localizations.dart';

import '../../application/team_management_service.dart';
import '../../domain/repositories/option_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bar_action_button.dart';
import '../widgets/app_feedback.dart';

enum _TacticBoardMode { assign, draw }

typedef _PlayerDropCallback = void Function({
  required String spotId,
  required String playerId,
});

class TeamManagementScreen extends StatefulWidget {
  final OptionRepository optionRepository;
  final String? sportId;

  const TeamManagementScreen({
    super.key,
    required this.optionRepository,
    this.sportId,
  });

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen> {
  late final TeamManagementService _teamService;
  final TextEditingController _teamNameController = TextEditingController();
  final TextEditingController _strategyController = TextEditingController();
  final TextEditingController _playerNameController = TextEditingController();
  final TextEditingController _playerNumberController = TextEditingController();
  final TextEditingController _playerNoteController = TextEditingController();

  List<ManagedTeam> _teams = const <ManagedTeam>[];
  ManagedTeam? _selectedTeam;
  List<ManagedTeamPlayer> _players = const <ManagedTeamPlayer>[];
  Map<String, String> _lineup = const <String, String>{};
  List<ManagedTacticLine> _tacticLines = const <ManagedTacticLine>[];
  String _formation = ManagedTeam.defaultFormation;
  String _playerRole = ManagedTeamPlayer.roleForward;
  String _playerFoot = ManagedTeamPlayer.footRight;
  String _playerCondition = ManagedTeamPlayer.conditionReady;
  String? _selectedSpotId;
  String? _editingPlayerId;
  _TacticBoardMode _boardMode = _TacticBoardMode.assign;
  ManagedTacticLine? _draftTacticLine;
  bool _loaded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _teamService = TeamManagementService(
      widget.optionRepository,
      sportId: widget.sportId,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    _loadTeams(AppLocalizations.of(context)!);
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    _strategyController.dispose();
    _playerNameController.dispose();
    _playerNumberController.dispose();
    _playerNoteController.dispose();
    super.dispose();
  }

  void _loadTeams(AppLocalizations l10n, {String? preferredTeamId}) {
    final teams = _teamService.allTeams();
    final selected = preferredTeamId == null
        ? null
        : teams.where((team) => team.id == preferredTeamId).firstOrNull;
    setState(() {
      _teams = teams;
    });
    _selectTeam(selected ?? (teams.isEmpty ? _draftTeam(l10n) : teams.first));
  }

  ManagedTeam _draftTeam(AppLocalizations l10n) {
    return ManagedTeam.create(name: l10n.teamManagementDefaultTeamName);
  }

  void _selectTeam(ManagedTeam team) {
    final spots = TeamManagementService.formationSpots(team.formation);
    _selectedTeam = team;
    _formation = team.formation;
    _players = List<ManagedTeamPlayer>.from(team.players);
    _lineup = TeamManagementService.normalizeLineup(
      lineup: team.lineup,
      players: _players,
      formation: _formation,
    );
    _tacticLines = List<ManagedTacticLine>.from(team.tacticLines);
    _selectedSpotId = spots.isEmpty ? null : spots.first.id;
    _editingPlayerId = null;
    _playerRole = ManagedTeamPlayer.roleForward;
    _playerFoot = ManagedTeamPlayer.footRight;
    _playerCondition = ManagedTeamPlayer.conditionReady;
    _boardMode = _TacticBoardMode.assign;
    _draftTacticLine = null;
    _teamNameController.text = team.name;
    _strategyController.text = team.strategy;
    _clearPlayerForm();
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
      tacticLines: _tacticLines,
    );
  }

  Future<void> _saveTeam() async {
    final l10n = AppLocalizations.of(context)!;
    final name = _teamNameController.text.trim();
    if (name.isEmpty) {
      AppFeedback.showMessage(context, text: l10n.teamManagementNameRequired);
      return;
    }
    setState(() => _saving = true);
    try {
      final team = _currentTeam();
      await _teamService.upsertTeam(team);
      if (!mounted) return;
      AppFeedback.showSuccess(context, text: l10n.teamManagementSavedFeedback);
      _loadTeams(l10n, preferredTeamId: team.id);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteTeam() async {
    final l10n = AppLocalizations.of(context)!;
    final team = _selectedTeam;
    if (team == null || !_teams.any((item) => item.id == team.id)) return;
    await _teamService.deleteTeam(team.id);
    if (!mounted) return;
    AppFeedback.showSuccess(context, text: l10n.teamManagementDeletedFeedback);
    _loadTeams(l10n);
  }

  void _startNewTeam() {
    _selectTeam(_draftTeam(AppLocalizations.of(context)!));
  }

  void _changeFormation(String formation) {
    final normalized = TeamManagementService.normalizeFormation(formation);
    final spots = TeamManagementService.formationSpots(normalized);
    setState(() {
      _formation = normalized;
      _lineup = TeamManagementService.normalizeLineup(
        lineup: _lineup,
        players: _players,
        formation: normalized,
      );
      _selectedSpotId = spots.isEmpty ? null : spots.first.id;
    });
  }

  void _selectSpot(String spotId) {
    setState(() => _selectedSpotId = spotId);
  }

  void _assignPlayerToSpot({
    required String spotId,
    required String playerId,
  }) {
    final normalizedPlayerId = playerId.trim();
    final next = Map<String, String>.from(_lineup);
    if (normalizedPlayerId.isEmpty) {
      next.remove(spotId);
    } else {
      next.removeWhere(
        (_, assignedPlayerId) => assignedPlayerId == normalizedPlayerId,
      );
      next[spotId] = normalizedPlayerId;
    }
    setState(() {
      _selectedSpotId = spotId;
      _lineup = TeamManagementService.normalizeLineup(
        lineup: next,
        players: _players,
        formation: _formation,
      );
    });
  }

  void _savePlayer() {
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
  }

  void _editPlayer(ManagedTeamPlayer player) {
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
    setState(() {
      _players = _players
          .where((item) => item.id != player.id)
          .toList(growable: false);
      final next = Map<String, String>.from(_lineup)
        ..removeWhere((_, playerId) => playerId == player.id);
      _lineup = next;
    });
  }

  void _changeBoardMode(_TacticBoardMode mode) {
    setState(() {
      _boardMode = mode;
      _draftTacticLine = null;
    });
  }

  void _startTacticLine(Offset point) {
    if (_boardMode != _TacticBoardMode.draw) return;
    setState(() {
      _draftTacticLine = ManagedTacticLine.create(
        startX: point.dx,
        startY: point.dy,
        endX: point.dx,
        endY: point.dy,
      );
    });
  }

  void _updateTacticLine(Offset point) {
    final draft = _draftTacticLine;
    if (_boardMode != _TacticBoardMode.draw || draft == null) return;
    setState(() {
      _draftTacticLine = draft.copyWith(endX: point.dx, endY: point.dy);
    });
  }

  void _finishTacticLine() {
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
  }

  void _clearTacticLines() {
    setState(() {
      _tacticLines = const <ManagedTacticLine>[];
      _draftTacticLine = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      body: ColoredBox(
        color: theme.scaffoldBackgroundColor,
        child: SafeArea(
          child: SingleChildScrollView(
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
                const SizedBox(height: AppSpacing.md),
                _TeamSelectorPanel(
                  teams: _teams,
                  selectedTeamId: _selectedTeam?.id ?? '',
                  onSelectTeam: _selectTeam,
                  onNewTeam: _startNewTeam,
                ),
                const SizedBox(height: AppSpacing.md),
                _PlayersPanel(
                  players: _players,
                  lineup: _lineup,
                  playerNameController: _playerNameController,
                  playerNumberController: _playerNumberController,
                  playerNoteController: _playerNoteController,
                  playerRole: _playerRole,
                  playerFoot: _playerFoot,
                  playerCondition: _playerCondition,
                  editingPlayerId: _editingPlayerId,
                  onRoleChanged: (role) => setState(() => _playerRole = role),
                  onFootChanged: (foot) => setState(() => _playerFoot = foot),
                  onConditionChanged: (condition) =>
                      setState(() => _playerCondition = condition),
                  onSavePlayer: _savePlayer,
                  onCancelPlayerEdit: _cancelPlayerEdit,
                  onEditPlayer: _editPlayer,
                  onRemovePlayer: _removePlayer,
                ),
                const SizedBox(height: AppSpacing.md),
                _TeamBasicsPanel(
                  teamNameController: _teamNameController,
                  strategyController: _strategyController,
                ),
                const SizedBox(height: AppSpacing.md),
                _FormationPanel(
                  formation: _formation,
                  players: _players,
                  lineup: _lineup,
                  tacticLines: _tacticLines,
                  draftTacticLine: _draftTacticLine,
                  selectedSpotId: _selectedSpotId,
                  boardMode: _boardMode,
                  onFormationChanged: _changeFormation,
                  onSpotSelected: _selectSpot,
                  onPlayerDropped: _assignPlayerToSpot,
                  onBoardModeChanged: _changeBoardMode,
                  onTacticLineStarted: _startTacticLine,
                  onTacticLineUpdated: _updateTacticLine,
                  onTacticLineFinished: _finishTacticLine,
                  onClearTacticLines: _clearTacticLines,
                ),
                const SizedBox(height: AppSpacing.lg),
                _SaveTeamActions(
                  canDelete: _selectedTeam != null &&
                      _teams.any((team) => team.id == _selectedTeam!.id),
                  saving: _saving,
                  onDelete: _deleteTeam,
                  onSave: _saveTeam,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.teamManagementSaveHint,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
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
    final scheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppBarActionButton.icon(
          icon: Icons.arrow_back,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: onBack,
          margin: EdgeInsets.zero,
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Container(
            decoration: AppSurfaces.heroDecoration(
              scheme,
              theme.brightness,
              accent: const Color(0xFF2563EB),
            ),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.groups_2_outlined,
                  color: Colors.white.withValues(alpha: 0.92),
                  size: 28,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.teamManagementTitle,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.teamManagementSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.84),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TeamSelectorPanel extends StatelessWidget {
  final List<ManagedTeam> teams;
  final String selectedTeamId;
  final ValueChanged<ManagedTeam> onSelectTeam;
  final VoidCallback onNewTeam;

  const _TeamSelectorPanel({
    required this.teams,
    required this.selectedTeamId,
    required this.onSelectTeam,
    required this.onNewTeam,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final brightness = theme.brightness;
    return Container(
      decoration: AppSurfaces.cardDecoration(scheme, brightness),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelTitle(
            icon: Icons.shield_outlined,
            title: l10n.teamManagementSavedTeamsTitle,
            helper: teams.isEmpty
                ? l10n.teamManagementNoTeamsBody
                : l10n.teamManagementSavedTeamsHelper,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (teams.isNotEmpty)
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final team in teams)
                  ChoiceChip(
                    label: Text(team.name),
                    selected: team.id == selectedTeamId,
                    onSelected: (_) => onSelectTeam(team),
                  ),
              ],
            )
          else
            Text(
              l10n.teamManagementNoTeamsTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: onNewTeam,
            icon: const Icon(Icons.add_outlined),
            label: Text(l10n.teamManagementNewTeamButton),
          ),
        ],
      ),
    );
  }
}

class _TeamBasicsPanel extends StatelessWidget {
  final TextEditingController teamNameController;
  final TextEditingController strategyController;

  const _TeamBasicsPanel({
    required this.teamNameController,
    required this.strategyController,
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
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: l10n.teamManagementTeamNameLabel,
              hintText: l10n.teamManagementTeamNameHint,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: strategyController,
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

class _FormationPanel extends StatelessWidget {
  final String formation;
  final List<ManagedTeamPlayer> players;
  final Map<String, String> lineup;
  final List<ManagedTacticLine> tacticLines;
  final ManagedTacticLine? draftTacticLine;
  final String? selectedSpotId;
  final _TacticBoardMode boardMode;
  final ValueChanged<String> onFormationChanged;
  final ValueChanged<String> onSpotSelected;
  final _PlayerDropCallback onPlayerDropped;
  final ValueChanged<_TacticBoardMode> onBoardModeChanged;
  final ValueChanged<Offset> onTacticLineStarted;
  final ValueChanged<Offset> onTacticLineUpdated;
  final VoidCallback onTacticLineFinished;
  final VoidCallback onClearTacticLines;

  const _FormationPanel({
    required this.formation,
    required this.players,
    required this.lineup,
    required this.tacticLines,
    required this.draftTacticLine,
    required this.selectedSpotId,
    required this.boardMode,
    required this.onFormationChanged,
    required this.onSpotSelected,
    required this.onPlayerDropped,
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
    final spots = TeamManagementService.formationSpots(formation);

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
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: [
              for (final option in TeamManagementService.supportedFormations)
                ButtonSegment<String>(
                  value: option,
                  label: Text(option),
                ),
            ],
            selected: {formation},
            onSelectionChanged: (values) => onFormationChanged(values.first),
          ),
          const SizedBox(height: AppSpacing.md),
          _BoardModeToolbar(
            mode: boardMode,
            tacticLineCount: tacticLines.length,
            onModeChanged: onBoardModeChanged,
            onClearTacticLines: onClearTacticLines,
          ),
          const SizedBox(height: AppSpacing.sm),
          _BoardPlayerTray(
            players: players,
            lineup: lineup,
          ),
          const SizedBox(height: AppSpacing.md),
          _FormationPitch(
            spots: spots,
            players: players,
            lineup: lineup,
            tacticLines: tacticLines,
            draftTacticLine: draftTacticLine,
            selectedSpotId: selectedSpotId,
            boardMode: boardMode,
            onSpotSelected: onSpotSelected,
            onPlayerDropped: onPlayerDropped,
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
  final ValueChanged<_TacticBoardMode> onModeChanged;
  final VoidCallback onClearTacticLines;

  const _BoardModeToolbar({
    required this.mode,
    required this.tacticLineCount,
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
              value: _TacticBoardMode.draw,
              icon: const Icon(Icons.timeline_outlined),
              label: Text(l10n.teamManagementBoardDrawMode),
            ),
          ],
          selected: {mode},
          onSelectionChanged: (values) => onModeChanged(values.first),
        ),
        OutlinedButton.icon(
          onPressed: tacticLineCount == 0 ? null : onClearTacticLines,
          icon: const Icon(Icons.cleaning_services_outlined),
          label: Text(l10n.teamManagementBoardClearLinesButton),
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
  final Map<String, String> lineup;

  const _BoardPlayerTray({
    required this.players,
    required this.lineup,
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
    final assignedPlayerIds = lineup.values.toSet();
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

class _FormationPitch extends StatelessWidget {
  final List<TeamFormationSpot> spots;
  final List<ManagedTeamPlayer> players;
  final Map<String, String> lineup;
  final List<ManagedTacticLine> tacticLines;
  final ManagedTacticLine? draftTacticLine;
  final String? selectedSpotId;
  final _TacticBoardMode boardMode;
  final ValueChanged<String> onSpotSelected;
  final _PlayerDropCallback onPlayerDropped;
  final ValueChanged<Offset> onTacticLineStarted;
  final ValueChanged<Offset> onTacticLineUpdated;
  final VoidCallback onTacticLineFinished;

  const _FormationPitch({
    required this.spots,
    required this.players,
    required this.lineup,
    required this.tacticLines,
    required this.draftTacticLine,
    required this.selectedSpotId,
    required this.boardMode,
    required this.onSpotSelected,
    required this.onPlayerDropped,
    required this.onTacticLineStarted,
    required this.onTacticLineUpdated,
    required this.onTacticLineFinished,
  });

  @override
  Widget build(BuildContext context) {
    final playerById = {for (final player in players) player.id: player};
    return AspectRatio(
      aspectRatio: 0.72,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const slotSize = 56.0;
          return ClipRRect(
            borderRadius: AppRadius.surface,
            child: GestureDetector(
              key: const ValueKey('team-tactics-board-pitch'),
              behavior: HitTestBehavior.opaque,
              onPanStart: boardMode == _TacticBoardMode.draw
                  ? (details) => onTacticLineStarted(
                        _normalizeBoardPoint(
                          details.localPosition,
                          constraints.biggest,
                        ),
                      )
                  : null,
              onPanUpdate: boardMode == _TacticBoardMode.draw
                  ? (details) => onTacticLineUpdated(
                        _normalizeBoardPoint(
                          details.localPosition,
                          constraints.biggest,
                        ),
                      )
                  : null,
              onPanEnd: boardMode == _TacticBoardMode.draw
                  ? (_) => onTacticLineFinished()
                  : null,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(painter: _PitchPainter()),
                  CustomPaint(
                    painter: _TacticLinesPainter(
                      lines: tacticLines,
                      draftLine: draftTacticLine,
                    ),
                  ),
                  for (final spot in spots)
                    Positioned(
                      left: (constraints.maxWidth * spot.x) - (slotSize / 2),
                      top: (constraints.maxHeight * spot.y) - (slotSize / 2),
                      width: slotSize,
                      height: slotSize,
                      child: DragTarget<String>(
                        key: ValueKey('formation-slot-${spot.id}'),
                        onWillAcceptWithDetails: (details) =>
                            playerById.containsKey(details.data),
                        onAcceptWithDetails: (details) => onPlayerDropped(
                          spotId: spot.id,
                          playerId: details.data,
                        ),
                        builder: (context, candidateData, rejectedData) {
                          final player = playerById[lineup[spot.id]];
                          final slot = _PitchSlotButton(
                            spot: spot,
                            player: player,
                            selected: spot.id == selectedSpotId,
                            dropHighlighted: candidateData.isNotEmpty,
                            onTap: () => onSpotSelected(spot.id),
                          );
                          if (player == null ||
                              boardMode == _TacticBoardMode.draw) {
                            return slot;
                          }
                          return Draggable<String>(
                            data: player.id,
                            feedback: Material(
                              color: Colors.transparent,
                              child: SizedBox(
                                width: slotSize,
                                height: slotSize,
                                child: _PitchSlotButton(
                                  spot: spot,
                                  player: player,
                                  selected: true,
                                  dropHighlighted: false,
                                  onTap: () {},
                                ),
                              ),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.36,
                              child: slot,
                            ),
                            child: slot,
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
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
    final paint = Paint()
      ..color = const Color(0xFFFACC15).withValues(alpha: 0.9)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final draftPaint = Paint()
      ..color = const Color(0xFF60A5FA).withValues(alpha: 0.86)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final line in lines) {
      _drawArrow(canvas, size, line, paint);
    }
    final draft = draftLine;
    if (draft != null) {
      _drawArrow(canvas, size, draft, draftPaint);
    }
  }

  void _drawArrow(
    Canvas canvas,
    Size size,
    ManagedTacticLine line,
    Paint paint,
  ) {
    final start = Offset(line.startX * size.width, line.startY * size.height);
    final end = Offset(line.endX * size.width, line.endY * size.height);
    canvas.drawLine(start, end, paint);

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

  @override
  bool shouldRepaint(covariant _TacticLinesPainter oldDelegate) {
    return oldDelegate.lines != lines || oldDelegate.draftLine != draftLine;
  }
}

class _PitchSlotButton extends StatelessWidget {
  final TeamFormationSpot spot;
  final ManagedTeamPlayer? player;
  final bool selected;
  final bool dropHighlighted;
  final VoidCallback onTap;

  const _PitchSlotButton({
    required this.spot,
    required this.player,
    required this.selected,
    required this.dropHighlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = dropHighlighted
        ? scheme.secondaryContainer
        : selected
            ? scheme.tertiary
            : Colors.white;
    final foreground = dropHighlighted
        ? scheme.onSecondaryContainer
        : selected
            ? scheme.onTertiary
            : const Color(0xFF064E3B);
    final name = player == null ? spot.label : _playerShortLabel(player!);
    return Material(
      color: color,
      elevation: selected || dropHighlighted ? 8 : 3,
      borderRadius: AppRadius.small,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.small,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                spot.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: foreground.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayersPanel extends StatelessWidget {
  final List<ManagedTeamPlayer> players;
  final Map<String, String> lineup;
  final TextEditingController playerNameController;
  final TextEditingController playerNumberController;
  final TextEditingController playerNoteController;
  final String playerRole;
  final String playerFoot;
  final String playerCondition;
  final String? editingPlayerId;
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
    required this.playerNameController,
    required this.playerNumberController,
    required this.playerNoteController,
    required this.playerRole,
    required this.playerFoot,
    required this.playerCondition,
    required this.editingPlayerId,
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
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: playerNameController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.teamManagementPlayerNameLabel,
                    hintText: l10n.teamManagementPlayerNameHint,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: playerNumberController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.teamManagementPlayerNumberLabel,
                    hintText: l10n.teamManagementPlayerNumberHint,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String>(
            initialValue: playerRole,
            decoration: InputDecoration(
              labelText: l10n.teamManagementPlayerRoleLabel,
            ),
            items: [
              for (final role in _playerRoles)
                DropdownMenuItem<String>(
                  value: role,
                  child: Text(teamPlayerRoleLabel(l10n, role)),
                ),
            ],
            onChanged: (role) {
              if (role == null) return;
              onRoleChanged(role);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String>(
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
            onChanged: (foot) {
              if (foot == null) return;
              onFootChanged(foot);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String>(
            initialValue: playerCondition,
            decoration: InputDecoration(
              labelText: l10n.teamManagementPlayerConditionLabel,
            ),
            items: [
              for (final condition in _playerConditions)
                DropdownMenuItem<String>(
                  value: condition,
                  child: Text(teamPlayerConditionLabel(l10n, condition)),
                ),
            ],
            onChanged: (condition) {
              if (condition == null) return;
              onConditionChanged(condition);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: playerNoteController,
            minLines: 2,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: l10n.teamManagementPlayerNoteLabel,
              hintText: l10n.teamManagementPlayerNoteHint,
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              if (editingPlayerId != null) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCancelPlayerEdit,
                    icon: const Icon(Icons.close_outlined),
                    label: Text(l10n.teamManagementCancelPlayerEditButton),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: onSavePlayer,
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
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (players.isEmpty)
            _InlineEmptyMessage(
              icon: Icons.groups_2_outlined,
              title: l10n.teamManagementNoPlayersTitle,
              body: l10n.teamManagementNoPlayersBody,
            )
          else
            ...players.map(
              (player) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _PlayerRosterRow(
                  player: player,
                  assignedCount: lineup.values
                      .where((playerId) => playerId == player.id)
                      .length,
                  onEdit: () => onEditPlayer(player),
                  onRemove: () => onRemovePlayer(player),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlayerRosterRow extends StatelessWidget {
  final ManagedTeamPlayer player;
  final int assignedCount;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const _PlayerRosterRow({
    required this.player,
    required this.assignedCount,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      decoration: AppSurfaces.subtleDecoration(
        scheme,
        theme.brightness,
        accent: scheme.primary,
        accentAlpha: 0.04,
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              borderRadius: AppRadius.small,
            ),
            alignment: Alignment.center,
            child: Text(
              player.number.isEmpty
                  ? teamPlayerRoleShortLabel(player.role)
                  : player.number,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.primary,
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
                Text(
                  l10n.teamManagementPlayerDetailMeta(
                    teamPlayerRoleLabel(l10n, player.role),
                    teamPlayerFootLabel(l10n, player.foot),
                    teamPlayerConditionLabel(l10n, player.condition),
                    assignedCount,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (player.note.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    player.note.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton.outlined(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                tooltip: l10n.teamManagementEditPlayerButton,
              ),
              const SizedBox(height: AppSpacing.xxs),
              IconButton.outlined(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline),
                tooltip: l10n.teamManagementRemovePlayerButton,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SaveTeamActions extends StatelessWidget {
  final bool canDelete;
  final bool saving;
  final VoidCallback onDelete;
  final VoidCallback onSave;

  const _SaveTeamActions({
    required this.canDelete,
    required this.saving,
    required this.onDelete,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        if (canDelete) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: saving ? null : onDelete,
              icon: const Icon(Icons.delete_outline),
              label: Text(l10n.teamManagementDeleteTeamButton),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed: saving ? null : onSave,
            icon: const Icon(Icons.save_outlined),
            label: Text(l10n.teamManagementSaveTeamButton),
          ),
        ),
      ],
    );
  }
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

String _playerShortLabel(ManagedTeamPlayer player) {
  final number = player.number.trim();
  if (number.isNotEmpty) return number;
  final trimmed = player.name.trim();
  if (trimmed.length <= 2) return trimmed;
  return trimmed.characters.take(2).toString();
}
