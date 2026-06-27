import 'package:flutter/material.dart';
import 'package:football_note/gen/app_localizations.dart';

import '../../application/team_management_service.dart';
import '../../domain/repositories/option_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bar_action_button.dart';
import '../widgets/app_feedback.dart';

class TeamManagementScreen extends StatefulWidget {
  final OptionRepository optionRepository;

  const TeamManagementScreen({
    super.key,
    required this.optionRepository,
  });

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen> {
  static const String _unassignedPlayerId = '__unassigned__';

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
  String _formation = ManagedTeam.defaultFormation;
  String _playerRole = ManagedTeamPlayer.roleForward;
  String? _selectedSpotId;
  bool _loaded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _teamService = TeamManagementService(widget.optionRepository);
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
    _selectedSpotId = spots.isEmpty ? null : spots.first.id;
    _teamNameController.text = team.name;
    _strategyController.text = team.strategy;
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

  void _assignPlayer(String playerId) {
    final spotId = _selectedSpotId;
    if (spotId == null) return;
    final next = Map<String, String>.from(_lineup);
    if (playerId == _unassignedPlayerId) {
      next.remove(spotId);
    } else {
      next[spotId] = playerId;
    }
    setState(() {
      _lineup = TeamManagementService.normalizeLineup(
        lineup: next,
        players: _players,
        formation: _formation,
      );
    });
  }

  void _addPlayer() {
    final l10n = AppLocalizations.of(context)!;
    final name = _playerNameController.text.trim();
    if (name.isEmpty) {
      AppFeedback.showMessage(context, text: l10n.teamManagementPlayerRequired);
      return;
    }
    final player = ManagedTeamPlayer.create(
      name: name,
      number: _playerNumberController.text.trim(),
      role: _playerRole,
      note: _playerNoteController.text.trim(),
    );
    setState(() {
      _players = TeamManagementService.normalizePlayers([..._players, player]);
      _playerNameController.clear();
      _playerNumberController.clear();
      _playerNoteController.clear();
    });
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
                _TeamBasicsPanel(
                  teamNameController: _teamNameController,
                  strategyController: _strategyController,
                ),
                const SizedBox(height: AppSpacing.md),
                _FormationPanel(
                  formation: _formation,
                  players: _players,
                  lineup: _lineup,
                  selectedSpotId: _selectedSpotId,
                  onFormationChanged: _changeFormation,
                  onSpotSelected: _selectSpot,
                  onPlayerAssigned: _assignPlayer,
                ),
                const SizedBox(height: AppSpacing.md),
                _PlayersPanel(
                  players: _players,
                  lineup: _lineup,
                  playerNameController: _playerNameController,
                  playerNumberController: _playerNumberController,
                  playerNoteController: _playerNoteController,
                  playerRole: _playerRole,
                  onRoleChanged: (role) => setState(() => _playerRole = role),
                  onAddPlayer: _addPlayer,
                  onRemovePlayer: _removePlayer,
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
  final String? selectedSpotId;
  final ValueChanged<String> onFormationChanged;
  final ValueChanged<String> onSpotSelected;
  final ValueChanged<String> onPlayerAssigned;

  const _FormationPanel({
    required this.formation,
    required this.players,
    required this.lineup,
    required this.selectedSpotId,
    required this.onFormationChanged,
    required this.onSpotSelected,
    required this.onPlayerAssigned,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final spots = TeamManagementService.formationSpots(formation);
    final selectedSpot =
        spots.where((spot) => spot.id == selectedSpotId).firstOrNull;
    final selectedPlayerId = selectedSpot == null
        ? _TeamManagementScreenState._unassignedPlayerId
        : lineup[selectedSpot.id] ??
            _TeamManagementScreenState._unassignedPlayerId;
    final validPlayerIds = players.map((player) => player.id).toSet();
    final dropdownValue = validPlayerIds.contains(selectedPlayerId)
        ? selectedPlayerId
        : _TeamManagementScreenState._unassignedPlayerId;

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
          _FormationPitch(
            spots: spots,
            players: players,
            lineup: lineup,
            selectedSpotId: selectedSpotId,
            onSpotSelected: onSpotSelected,
          ),
          const SizedBox(height: AppSpacing.md),
          _AssignmentPanel(
            selectedSpot: selectedSpot,
            players: players,
            value: dropdownValue,
            onPlayerAssigned: onPlayerAssigned,
          ),
        ],
      ),
    );
  }
}

class _FormationPitch extends StatelessWidget {
  final List<TeamFormationSpot> spots;
  final List<ManagedTeamPlayer> players;
  final Map<String, String> lineup;
  final String? selectedSpotId;
  final ValueChanged<String> onSpotSelected;

  const _FormationPitch({
    required this.spots,
    required this.players,
    required this.lineup,
    required this.selectedSpotId,
    required this.onSpotSelected,
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
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(painter: _PitchPainter()),
                for (final spot in spots)
                  Positioned(
                    left: (constraints.maxWidth * spot.x) - (slotSize / 2),
                    top: (constraints.maxHeight * spot.y) - (slotSize / 2),
                    width: slotSize,
                    height: slotSize,
                    child: _PitchSlotButton(
                      spot: spot,
                      player: playerById[lineup[spot.id]],
                      selected: spot.id == selectedSpotId,
                      onTap: () => onSpotSelected(spot.id),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
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

class _PitchSlotButton extends StatelessWidget {
  final TeamFormationSpot spot;
  final ManagedTeamPlayer? player;
  final bool selected;
  final VoidCallback onTap;

  const _PitchSlotButton({
    required this.spot,
    required this.player,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = selected ? scheme.tertiary : Colors.white;
    final foreground = selected ? scheme.onTertiary : const Color(0xFF064E3B);
    final name = player == null ? spot.label : _playerShortLabel(player!);
    return Material(
      color: color,
      elevation: selected ? 8 : 3,
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

class _AssignmentPanel extends StatelessWidget {
  final TeamFormationSpot? selectedSpot;
  final List<ManagedTeamPlayer> players;
  final String value;
  final ValueChanged<String> onPlayerAssigned;

  const _AssignmentPanel({
    required this.selectedSpot,
    required this.players,
    required this.value,
    required this.onPlayerAssigned,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final spot = selectedSpot;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          spot == null
              ? l10n.teamManagementSelectPositionPrompt
              : l10n.teamManagementSelectedPosition(
                  l10n.teamManagementFormationSpotLabel(spot.label),
                ),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        DropdownButtonFormField<String>(
          initialValue: value,
          decoration: InputDecoration(
            labelText: l10n.teamManagementAssignedPlayerLabel,
          ),
          items: [
            DropdownMenuItem<String>(
              value: _TeamManagementScreenState._unassignedPlayerId,
              child: Text(l10n.teamManagementUnassignedPlayer),
            ),
            for (final player in players)
              DropdownMenuItem<String>(
                value: player.id,
                child: Text(_playerDisplayName(player)),
              ),
          ],
          onChanged: spot == null
              ? null
              : (next) {
                  if (next == null) return;
                  onPlayerAssigned(next);
                },
        ),
      ],
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
  final ValueChanged<String> onRoleChanged;
  final VoidCallback onAddPlayer;
  final ValueChanged<ManagedTeamPlayer> onRemovePlayer;

  const _PlayersPanel({
    required this.players,
    required this.lineup,
    required this.playerNameController,
    required this.playerNumberController,
    required this.playerNoteController,
    required this.playerRole,
    required this.onRoleChanged,
    required this.onAddPlayer,
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
          FilledButton.icon(
            onPressed: onAddPlayer,
            icon: const Icon(Icons.add_outlined),
            label: Text(l10n.teamManagementAddPlayerButton),
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
  final VoidCallback onRemove;

  const _PlayerRosterRow({
    required this.player,
    required this.assignedCount,
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
                  l10n.teamManagementPlayerMeta(
                    teamPlayerRoleLabel(l10n, player.role),
                    assignedCount,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          OutlinedButton(
            onPressed: onRemove,
            child: Text(l10n.teamManagementRemovePlayerButton),
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

String teamPlayerRoleLabel(AppLocalizations l10n, String role) {
  return switch (role) {
    ManagedTeamPlayer.roleGoalkeeper => l10n.teamManagementRoleGoalkeeper,
    ManagedTeamPlayer.roleDefender => l10n.teamManagementRoleDefender,
    ManagedTeamPlayer.roleMidfielder => l10n.teamManagementRoleMidfielder,
    _ => l10n.teamManagementRoleForward,
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
