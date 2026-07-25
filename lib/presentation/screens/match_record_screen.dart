import 'dart:async';

import 'package:flutter/material.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:intl/intl.dart';

import '../../application/family_access_service.dart';
import '../../application/locale_service.dart';
import '../../application/match_competition_service.dart';
import '../../application/player_level_service.dart';
import '../../application/settings_service.dart';
import '../../application/sport_capabilities.dart';
import '../../application/sport_service.dart';
import '../../application/team_management_service.dart';
import '../../application/training_plan_reminder_service.dart';
import '../../application/training_service.dart';
import '../../domain/entities/training_entry.dart';
import '../../domain/repositories/option_repository.dart';
import '../theme/app_theme.dart';
import '../utils/app_sound_effects.dart';
import '../utils/match_entry_format.dart';
import '../widgets/app_bar_action_button.dart';
import '../widgets/app_feedback.dart';
import '../widgets/app_page_route.dart';
import 'competition_management_screen.dart';

class MatchRecordScreen extends StatefulWidget {
  final TrainingService trainingService;
  final LocaleService localeService;
  final OptionRepository optionRepository;
  final SettingsService settingsService;
  final DateTime? initialDate;
  final TrainingEntry? editingEntry;
  final MatchCompetitionRecord? initialCompetition;
  final CompetitionFixture? initialFixture;

  const MatchRecordScreen({
    super.key,
    required this.trainingService,
    required this.localeService,
    required this.optionRepository,
    required this.settingsService,
    this.initialDate,
    this.editingEntry,
    this.initialCompetition,
    this.initialFixture,
  });

  @override
  State<MatchRecordScreen> createState() => _MatchRecordScreenState();
}

class _MatchRecordScreenState extends State<MatchRecordScreen> {
  static const String _resultUnset = 'unset';
  static const String _resultWin = 'win';
  static const String _resultDraw = 'draw';
  static const String _resultLoss = 'loss';

  late DateTime _matchDay;
  late String _matchKind;
  late String _opponent;
  late String _location;
  late String _selectedCompetitionId;
  late String _leagueRound;
  late String _tournamentStage;
  late String _tournamentOutcome;
  late List<String> _teams;
  late int? _ourScore;
  late int? _opponentScore;
  late int? _penaltyShootoutGoalsFor;
  late int? _penaltyShootoutGoalsAgainst;
  late int? _playerGoals;
  late int? _playerAssists;
  late int? _shotsOnTarget;
  late int? _ballsWon;
  late int? _yellowCards;
  late int? _redCards;
  late int? _minutesPlayed;
  late String _memo;

  final TextEditingController _opponentController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _roundController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();

  List<TrainingEntry> _contextEntries = const <TrainingEntry>[];
  MatchCompetitionRecord? _initialCompetition;
  CompetitionFixture? _initialFixture;
  bool _saving = false;
  bool _showValidationErrors = false;
  Timer? _autoSaveTimer;
  bool _autoSaveInFlight = false;
  bool _autoSaveQueued = false;

  bool get _isCompetitionMatch =>
      _matchKind == MatchCompetitionRecord.kindLeague ||
      _matchKind == MatchCompetitionRecord.kindTournament;

  bool get _isFixtureBound =>
      widget.initialCompetition != null && widget.initialFixture != null;

  bool get _isParentMode =>
      FamilyAccessService(widget.optionRepository).loadState().isParentMode;

  bool get _canAutoSaveExistingMatch =>
      !_isParentMode && widget.editingEntry?.key is int;

  @override
  void initState() {
    super.initState();
    _seedFromEntry(widget.editingEntry);
    unawaited(_loadContextEntries());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final competition = _initialCompetition;
    final fixture = _initialFixture;
    if (competition == null) return;
    _initialCompetition = null;
    _applyCompetition(competition);
    if (fixture != null) _applyFixture(competition, fixture);
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _opponentController.dispose();
    _locationController.dispose();
    _roundController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  void _seedFromEntry(TrainingEntry? entry) {
    final initial = entry?.date ?? widget.initialDate ?? DateTime.now();
    _matchDay = DateTime(initial.year, initial.month, initial.day);
    _matchKind = entry?.isTournamentMatch == true
        ? MatchCompetitionRecord.kindTournament
        : entry?.isLeagueMatch == true
            ? MatchCompetitionRecord.kindLeague
            : 'friendly';
    _opponent = entry?.opponentTeam ?? entry?.club ?? '';
    _location = entry?.effectiveMatchLocation ?? '';
    final competitionName = entry?.matchCompetitionName ?? '';
    _selectedCompetitionId = '';
    _leagueRound = entry?.isLeagueMatch == true ? entry?.matchStage ?? '' : '';
    _tournamentStage = normalizeMatchTournamentStage(
      entry?.isTournamentMatch == true ? entry?.matchStage ?? '' : '',
    );
    _tournamentOutcome = normalizeMatchTournamentOutcome(
      entry?.isTournamentMatch == true ? entry?.tournamentOutcome ?? '' : '',
    );
    _teams =
        MatchCompetitionService.normalizeTeams(entry?.leagueTeamNames ?? []);
    _ourScore = entry?.scoredGoals;
    _opponentScore = entry?.concededGoals;
    _penaltyShootoutGoalsFor = entry?.penaltyShootoutGoalsFor;
    _penaltyShootoutGoalsAgainst = entry?.penaltyShootoutGoalsAgainst;
    _playerGoals = entry?.playerGoals;
    _playerAssists = entry?.playerAssists;
    _shotsOnTarget = entry?.shotsOnTarget;
    _ballsWon = entry?.ballsWon;
    _yellowCards = entry?.yellowCards;
    _redCards = entry?.redCards;
    _minutesPlayed = entry?.minutesPlayed;
    _memo = entry?.notes ?? '';

    _opponentController.text = _opponent;
    _locationController.text = _location;
    _roundController.text = _leagueRound;
    _memoController.text = _memo;

    final sportId = entry?.sportId ??
        SportService(widget.optionRepository).currentSportId();
    final competition = MatchCompetitionService(
      widget.optionRepository,
      sportId: sportId,
    ).findCompetition(kind: _matchKind, name: competitionName);
    if (competition != null) {
      _initialCompetition = competition;
    }
    if (widget.initialCompetition != null && widget.initialFixture != null) {
      _initialCompetition = widget.initialCompetition;
      _initialFixture = widget.initialFixture;
    }
  }

  Future<void> _loadContextEntries() async {
    final sportId = widget.editingEntry?.sportId ??
        SportService(widget.optionRepository).currentSportId();
    final entries = await widget.trainingService.recentEntries(
      limit: 300,
      sportId: sportId,
    );
    if (!mounted) return;
    setState(() {
      _contextEntries = entries;
      final competition = widget.initialCompetition;
      final fixture = widget.initialFixture;
      if (competition != null && fixture != null) {
        _applyFixture(competition, fixture);
      }
    });
  }

  Future<void> _openCompetitionManagement() async {
    final sportId = widget.editingEntry?.sportId ??
        SportService(widget.optionRepository).currentSportId();
    await Navigator.of(context).push(
      AppPageRoute(
        builder: (_) => CompetitionManagementScreen(
          trainingService: widget.trainingService,
          optionRepository: widget.optionRepository,
          sportId: sportId,
          readOnly: _isParentMode,
        ),
      ),
    );
    if (!mounted) return;
    setState(() {});
  }

  void _updateAndScheduleAutoSave(VoidCallback update) {
    setState(update);
    _scheduleAutoSave();
  }

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    if (!_canAutoSaveExistingMatch || _saving) {
      return;
    }
    if (_autoSaveInFlight) {
      _autoSaveQueued = true;
      return;
    }
    _autoSaveTimer = Timer(const Duration(milliseconds: 700), () {
      unawaited(_autoSaveMatch());
    });
  }

  Future<void> _autoSaveMatch() async {
    if (!_canAutoSaveExistingMatch || _saving) return;
    if (_autoSaveInFlight) {
      _autoSaveQueued = true;
      return;
    }
    _autoSaveInFlight = true;
    try {
      await _saveMatch(closeAfterSave: false);
    } finally {
      _autoSaveInFlight = false;
      if (_autoSaveQueued && mounted) {
        _autoSaveQueued = false;
        _scheduleAutoSave();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    if (_isParentMode && widget.editingEntry == null) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: AppSpacing.screen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: BackButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _InfoPanel(
                  icon: Icons.lock_outline,
                  title: l10n.parentReadOnlyCalendarSummary,
                  body: l10n.parentReadOnlyCalendarMessage,
                ),
              ],
            ),
          ),
        ),
      );
    }

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
                _buildHeader(context),
                const SizedBox(height: AppSpacing.md),
                _buildMatchBoardSection(context),
                if (_isCompetitionMatch && !_isFixtureBound) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _buildCompetitionSection(context),
                ],
                const SizedBox(height: AppSpacing.sm),
                _buildMatchDetailsSection(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        BackButton(
          onPressed: _saving ? null : () => Navigator.of(context).maybePop(),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            widget.editingEntry == null
                ? l10n.matchAddTitle
                : l10n.matchEditTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        AppBarActionButton.label(
          key: const ValueKey('match-record-save-action'),
          icon: _saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: l10n.save,
          tooltip: l10n.save,
          onPressed: _saving ? null : _saveMatch,
          margin: EdgeInsets.zero,
          maxLabelWidth: 56,
        ),
      ],
    );
  }

  Widget _buildMatchBoardSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final sportId = widget.editingEntry?.sportId ??
        SportService(widget.optionRepository).currentSportId();
    final labels = SportMatchLabels.forSport(l10n: l10n, sportId: sportId);
    final savedCompetitions = _isCompetitionMatch
        ? MatchCompetitionService(
            widget.optionRepository,
            sportId: sportId,
          ).competitionsForKind(_matchKind)
        : const <MatchCompetitionRecord>[];
    final selectedCompetition = _selectedManagedCompetition();
    final opponentOptions = _opponentOptions();
    final managedTeam = _managedTeam(sportId);
    final managedTeamName = managedTeam?.name.trim().isNotEmpty == true
        ? managedTeam!.name.trim()
        : l10n.matchCompetitionMyTeamFallback;
    return _MatchRecordSection(
      step: 1,
      icon: Icons.sports_soccer_outlined,
      title: l10n.matchBoardTitle,
      children: [
        _buildMatchSetupControls(context),
        const SizedBox(height: AppSpacing.xs),
        _MatchFlowContextStrip(
          teamName: managedTeamName,
          playerCount: managedTeam?.players.length ?? 0,
          matchKindLabel: _matchKindLabel(l10n),
          competitionName: selectedCompetition?.name ?? '',
          opponentName: _opponent,
        ),
        if (!_isFixtureBound &&
            _isCompetitionMatch &&
            savedCompetitions.isEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          _ManagedCompetitionRequiredNotice(
            onOpenCompetitionManagement: _openCompetitionManagement,
          ),
        ] else if (!_isFixtureBound && savedCompetitions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          _SavedCompetitionLoader(
            competitions: savedCompetitions,
            selectedCompetitionId: _selectedCompetitionId,
            enabled: !_saving,
            onSelected: (record) {
              _updateAndScheduleAutoSave(() => _applyCompetition(record));
            },
          ),
        ],
        if (!_isFixtureBound) ...[
          const SizedBox(height: AppSpacing.sm),
          _buildOpponentControl(context, opponentOptions),
        ],
        if (_showValidationErrors && _opponent.trim().isEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          _RequiredFieldError(text: l10n.matchOpponentRequired),
        ],
        const SizedBox(height: AppSpacing.sm),
        _LiveScoreboard(
          homeLabel: managedTeamName,
          awayLabel: _opponent.trim().isEmpty
              ? l10n.matchOpponentTeamLabel
              : _opponent.trim(),
          homeScore: _ourScore,
          awayScore: _opponentScore,
          onHomeScoreChanged: (value) => _updateAndScheduleAutoSave(() {
            _ourScore = value;
            if (value != null && _opponentScore == null) {
              _opponentScore = 0;
            }
            _clearTournamentShootoutIfNotRequired();
          }),
          onAwayScoreChanged: (value) => _updateAndScheduleAutoSave(() {
            _opponentScore = value;
            if (value != null && _ourScore == null) {
              _ourScore = 0;
            }
            _clearTournamentShootoutIfNotRequired();
          }),
        ),
        if (_showValidationErrors &&
            (_ourScore == null || _opponentScore == null)) ...[
          const SizedBox(height: AppSpacing.xs),
          _RequiredFieldError(text: l10n.matchScoreRequired),
        ],
        if (_requiresTournamentShootout) ...[
          const SizedBox(height: AppSpacing.sm),
          _TournamentShootoutScoreboard(
            title: l10n.matchTournamentShootoutTitle,
            helper: l10n.matchTournamentShootoutHelper,
            homeLabel: managedTeamName,
            awayLabel: _opponent.trim().isEmpty
                ? l10n.matchOpponentTeamLabel
                : _opponent.trim(),
            homeScore: _penaltyShootoutGoalsFor,
            awayScore: _penaltyShootoutGoalsAgainst,
            onHomeScoreChanged: (value) => _updateAndScheduleAutoSave(
              () => _penaltyShootoutGoalsFor = value,
            ),
            onAwayScoreChanged: (value) => _updateAndScheduleAutoSave(
              () => _penaltyShootoutGoalsAgainst = value,
            ),
          ),
          if (_showValidationErrors &&
              _tournamentShootoutValidationMessage(l10n) != null) ...[
            const SizedBox(height: AppSpacing.xs),
            _RequiredFieldError(
              text: _tournamentShootoutValidationMessage(l10n)!,
            ),
          ],
        ],
        const SizedBox(height: AppSpacing.sm),
        _ResultChoiceStrip(
          selected: _matchResultValue(),
          onSelected: _saving
              ? null
              : (value) => _updateAndScheduleAutoSave(
                    () => _applyMatchResult(value),
                  ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.matchBoardEventsTitle,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        _DynamicCounterGrid(
          children: [
            _TouchCounter(
              label: labels.primary.label,
              icon: Icons.sports_soccer_outlined,
              value: _playerGoals,
              increaseKey: const ValueKey<String>(
                'match-board-primary-stat-increase',
              ),
              decreaseKey: const ValueKey<String>(
                'match-board-primary-stat-decrease',
              ),
              onChanged: (value) =>
                  _updateAndScheduleAutoSave(() => _playerGoals = value),
            ),
            _TouchCounter(
              label: labels.secondary.label,
              icon: Icons.call_split_outlined,
              value: _playerAssists,
              increaseKey: const ValueKey<String>(
                'match-board-secondary-stat-increase',
              ),
              decreaseKey: const ValueKey<String>(
                'match-board-secondary-stat-decrease',
              ),
              onChanged: (value) =>
                  _updateAndScheduleAutoSave(() => _playerAssists = value),
            ),
            _TouchCounter(
              label: labels.tertiary.label,
              icon: Icons.track_changes_outlined,
              value: _shotsOnTarget,
              increaseKey: const ValueKey<String>(
                'match-board-tertiary-stat-increase',
              ),
              decreaseKey: const ValueKey<String>(
                'match-board-tertiary-stat-decrease',
              ),
              onChanged: (value) =>
                  _updateAndScheduleAutoSave(() => _shotsOnTarget = value),
            ),
            _TouchCounter(
              label: labels.quaternary.label,
              icon: Icons.shield_outlined,
              value: _ballsWon,
              increaseKey: const ValueKey<String>(
                'match-board-quaternary-stat-increase',
              ),
              decreaseKey: const ValueKey<String>(
                'match-board-quaternary-stat-decrease',
              ),
              onChanged: (value) =>
                  _updateAndScheduleAutoSave(() => _ballsWon = value),
            ),
            _TouchCounter(
              label: l10n.matchYellowCardsLabel,
              icon: Icons.style_outlined,
              value: _yellowCards,
              accent: const Color(0xFFEAB308),
              increaseKey: const ValueKey<String>(
                'match-board-yellow-cards-increase',
              ),
              decreaseKey: const ValueKey<String>(
                'match-board-yellow-cards-decrease',
              ),
              onChanged: (value) =>
                  _updateAndScheduleAutoSave(() => _yellowCards = value),
            ),
            _TouchCounter(
              label: l10n.matchRedCardsLabel,
              icon: Icons.style_outlined,
              value: _redCards,
              accent: const Color(0xFFDC2626),
              increaseKey: const ValueKey<String>(
                'match-board-red-cards-increase',
              ),
              decreaseKey: const ValueKey<String>(
                'match-board-red-cards-decrease',
              ),
              onChanged: (value) =>
                  _updateAndScheduleAutoSave(() => _redCards = value),
            ),
            _TouchCounter(
              label: l10n.matchMinutesPlayedLabel,
              icon: Icons.timer_outlined,
              value: _minutesPlayed,
              step: 5,
              increaseKey: const ValueKey<String>(
                'match-board-minutes-increase',
              ),
              decreaseKey: const ValueKey<String>(
                'match-board-minutes-decrease',
              ),
              onChanged: (value) =>
                  _updateAndScheduleAutoSave(() => _minutesPlayed = value),
            ),
          ],
        ),
        if (_matchKind == MatchCompetitionRecord.kindTournament &&
            !_isFixtureBound) ...[
          const SizedBox(height: AppSpacing.sm),
          _buildTournamentOutcomeControl(context),
        ],
      ],
    );
  }

  ManagedTeam? _managedTeam(String sportId) {
    final teams = TeamManagementService(
      widget.optionRepository,
      sportId: sportId,
    ).allTeams();
    return teams.isEmpty ? null : teams.first;
  }

  String _matchKindLabel(AppLocalizations l10n) {
    return switch (_matchKind) {
      MatchCompetitionRecord.kindLeague => l10n.matchKindLeague,
      MatchCompetitionRecord.kindTournament => l10n.matchKindTournament,
      _ => l10n.matchKindFriendly,
    };
  }

  Widget _buildMatchSetupControls(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_isFixtureBound) {
      return _ScheduledFixtureContext(
        date: _matchDay,
        matchKindLabel: _matchKindLabel(l10n),
        label: l10n.matchCompetitionFixtureRecordContext,
      );
    }
    final dateButton = OutlinedButton.icon(
      onPressed: _saving ? null : _pickMatchDate,
      icon: const Icon(Icons.calendar_today_outlined),
      label: Text(DateFormat('yyyy-MM-dd').format(_matchDay)),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 44),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
    final kindSelector = SegmentedButton<String>(
      key: const ValueKey<String>('match-record-kind-selector'),
      segments: [
        ButtonSegment<String>(
          value: 'friendly',
          icon: const Icon(Icons.handshake_outlined),
          label: Text(l10n.matchKindFriendly),
        ),
        ButtonSegment<String>(
          value: MatchCompetitionRecord.kindLeague,
          icon: const Icon(Icons.leaderboard_outlined),
          label: Text(l10n.matchKindLeague),
        ),
        ButtonSegment<String>(
          value: MatchCompetitionRecord.kindTournament,
          icon: const Icon(Icons.account_tree_outlined),
          label: Text(l10n.matchKindTournament),
        ),
      ],
      selected: {_matchKind},
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        ),
      ),
      onSelectionChanged: _saving || widget.editingEntry != null
          ? null
          : (selection) {
              _updateAndScheduleAutoSave(() {
                _matchKind = selection.first;
                _selectedCompetitionId = '';
                _teams = const <String>[];
                _opponent = '';
                _penaltyShootoutGoalsFor = null;
                _penaltyShootoutGoalsAgainst = null;
                _opponentController.clear();
              });
            },
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 620) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              dateButton,
              const SizedBox(height: AppSpacing.xs),
              kindSelector,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 168, child: dateButton),
            const SizedBox(width: AppSpacing.xs),
            Expanded(child: kindSelector),
          ],
        );
      },
    );
  }

  Widget _buildOpponentControl(
    BuildContext context,
    List<String> opponentOptions,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final textField = TextField(
      key: const ValueKey<String>('match-opponent-field'),
      controller: _opponentController,
      enabled: !_saving,
      maxLength: 40,
      textInputAction: TextInputAction.next,
      onChanged: (value) {
        _updateAndScheduleAutoSave(() => _opponent = value);
      },
      decoration: InputDecoration(
        labelText: l10n.requiredFieldLabel(l10n.matchOpponentTeamLabel),
        hintText: l10n.matchOpponentTeamHint,
        border: const OutlineInputBorder(),
        counterText: '',
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
      ),
    );

    if (_isCompetitionMatch && opponentOptions.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.requiredFieldLabel(l10n.matchFlowOpponentSectionTitle),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final team in opponentOptions)
                ChoiceChip(
                  label: Text(team),
                  selected: _opponent == team,
                  onSelected: _saving
                      ? null
                      : (_) {
                          _updateAndScheduleAutoSave(() {
                            _opponent = team;
                            _opponentController.text = team;
                          });
                        },
                ),
            ],
          ),
        ],
      );
    }

    if (opponentOptions.isEmpty) return textField;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        textField,
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final team in opponentOptions.take(6))
              ChoiceChip(
                label: Text(team),
                selected: _opponent == team,
                onSelected: _saving
                    ? null
                    : (_) {
                        _updateAndScheduleAutoSave(() {
                          _opponent = team;
                          _opponentController.text = team;
                        });
                      },
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildTournamentOutcomeControl(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DropdownButtonFormField<String>(
      initialValue: _tournamentOutcome,
      items: [
        for (final value in matchTournamentOutcomeValues)
          DropdownMenuItem<String>(
            value: value,
            child: Text(matchTournamentOutcomeLabel(l10n, value)),
          ),
      ],
      onChanged: _saving
          ? null
          : (value) {
              if (value == null) return;
              _updateAndScheduleAutoSave(
                () => _tournamentOutcome = value,
              );
            },
      decoration: InputDecoration(
        labelText: l10n.matchTournamentOutcomeLabel,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
      ),
    );
  }

  Widget _buildMatchDetailsSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locationField = TextField(
      controller: _locationController,
      enabled: !_saving,
      maxLength: 40,
      textInputAction: TextInputAction.next,
      onChanged: (value) {
        _location = value;
        _scheduleAutoSave();
      },
      decoration: InputDecoration(
        labelText: l10n.location,
        hintText: l10n.matchLocationHint,
        border: const OutlineInputBorder(),
        counterText: '',
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
      ),
    );
    final memoField = TextField(
      controller: _memoController,
      enabled: !_saving,
      maxLength: 60,
      textInputAction: TextInputAction.done,
      onChanged: (value) {
        _memo = value;
        _scheduleAutoSave();
      },
      decoration: InputDecoration(
        labelText: l10n.matchNoteOptionalLabel,
        border: const OutlineInputBorder(),
        counterText: '',
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
      ),
    );
    return _MatchRecordSection(
      step: _isCompetitionMatch ? 3 : 2,
      icon: Icons.edit_note_outlined,
      title: l10n.matchDetailsSectionTitle,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 620) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  locationField,
                  const SizedBox(height: AppSpacing.xs),
                  memoField,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: locationField),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: memoField),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildCompetitionSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selectedCompetition = _selectedManagedCompetition();
    return _MatchRecordSection(
      step: 2,
      icon: _matchKind == MatchCompetitionRecord.kindTournament
          ? Icons.account_tree_outlined
          : Icons.leaderboard_outlined,
      title: l10n.requiredFieldLabel(
        l10n.matchFlowCompetitionSectionTitle,
      ),
      helper: l10n.matchFlowCompetitionSectionHelper,
      children: [
        if (selectedCompetition == null)
          _InlineHint(
            text: l10n.matchCompetitionSelectionRequired,
            isError: _showValidationErrors,
          )
        else ...[
          _SelectedCompetitionSummary(competition: selectedCompetition),
          const SizedBox(height: AppSpacing.sm),
          if (_matchKind == MatchCompetitionRecord.kindLeague)
            TextField(
              controller: _roundController,
              enabled: !_saving,
              maxLength: 24,
              textInputAction: TextInputAction.next,
              onChanged: (value) {
                _leagueRound = value;
                _scheduleAutoSave();
              },
              decoration: InputDecoration(
                labelText: l10n.matchLeagueRoundLabel,
                hintText: l10n.matchLeagueRoundHint,
                border: const OutlineInputBorder(),
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
              ),
            )
          else
            DropdownButtonFormField<String>(
              initialValue: _tournamentStage,
              items: [
                for (final value in matchTournamentStageValues)
                  DropdownMenuItem<String>(
                    value: value,
                    child: Text(matchTournamentStageLabel(l10n, value)),
                  ),
              ],
              onChanged: _saving
                  ? null
                  : (value) {
                      if (value == null) return;
                      _updateAndScheduleAutoSave(
                        () => _tournamentStage = value,
                      );
                    },
              decoration: InputDecoration(
                labelText: l10n.matchTournamentStageLabel,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
              ),
            ),
        ],
      ],
    );
  }

  Future<void> _pickMatchDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _matchDay,
      firstDate: DateTime(2022),
      lastDate: DateTime(2032),
    );
    if (picked == null || !mounted) return;
    _updateAndScheduleAutoSave(() {
      _matchDay = DateTime(picked.year, picked.month, picked.day);
    });
  }

  void _applyCompetition(MatchCompetitionRecord record) {
    final sportId = widget.editingEntry?.sportId ??
        SportService(widget.optionRepository).currentSportId();
    final managedTeamName = _managedTeam(sportId)?.name.trim() ?? '';
    final fallbackTeamName = AppLocalizations.of(
      context,
    )!
        .matchCompetitionMyTeamFallback;
    _matchKind = record.kind;
    _selectedCompetitionId = record.id;
    _teams = MatchCompetitionService.teamsWithManagedTeam(
      kind: record.kind,
      teams: record.teams,
      managedTeamName: managedTeamName,
      fallbackTeamName: fallbackTeamName,
      replaceLeagueFirstTeam: true,
    );
    if (_location.trim().isEmpty && record.venue.trim().isNotEmpty) {
      _location = record.venue.trim();
      _locationController.text = _location;
    }
    if (!_teams.contains(_opponent.trim())) {
      _opponent = '';
      _opponentController.clear();
    }
  }

  void _applyFixture(
    MatchCompetitionRecord competition,
    CompetitionFixture fixture,
  ) {
    final sportId = widget.editingEntry?.sportId ??
        SportService(widget.optionRepository).currentSportId();
    final l10n = AppLocalizations.of(context)!;
    final managedTeam = _managedTeam(sportId);
    final managedTeamName = managedTeam?.name.trim().isNotEmpty == true
        ? managedTeam!.name.trim()
        : l10n.matchCompetitionMyTeamFallback;
    final states = MatchCompetitionService.resolveFixtureStates(
      competition: competition,
      entries: _contextEntries,
    );
    final state = states.firstWhere(
      (item) => item.fixture.id == fixture.id,
      orElse: () => CompetitionFixtureState(
        competition: competition,
        fixture: fixture,
        homeTeam: fixture.homeTeam,
        awayTeam: fixture.awayTeam,
      ),
    );
    final fixtureTeamName = state.involvesTeam(managedTeamName)
        ? managedTeamName
        : state.involvesTeam(l10n.matchCompetitionMyTeamFallback)
            ? l10n.matchCompetitionMyTeamFallback
            : managedTeamName;
    final opponent = state.opponentFor(fixtureTeamName);
    _matchKind = competition.kind;
    _selectedCompetitionId = competition.id;
    _teams = MatchCompetitionService.normalizeTeams([
      ...competition.teams,
      state.homeTeam,
      state.awayTeam,
    ]);
    _opponent = opponent;
    _opponentController.text = opponent;
    if (state.fixture.scheduledAt != null) {
      final date = state.fixture.scheduledAt!;
      _matchDay = DateTime(date.year, date.month, date.day);
    }
    if (state.fixture.venue.trim().isNotEmpty) {
      _location = state.fixture.venue.trim();
      _locationController.text = _location;
    }
    if (competition.kind == MatchCompetitionRecord.kindLeague) {
      _leagueRound = state.fixture.stage;
      _roundController.text = _leagueRound;
    } else {
      _tournamentStage = normalizeMatchTournamentStage(state.fixture.stage);
      _tournamentOutcome = 'ongoing';
    }
  }

  MatchCompetitionRecord? _selectedManagedCompetition() {
    if (!_isCompetitionMatch || _selectedCompetitionId.trim().isEmpty) {
      return null;
    }
    final sportId = widget.editingEntry?.sportId ??
        SportService(widget.optionRepository).currentSportId();
    final competition = MatchCompetitionService(
      widget.optionRepository,
      sportId: sportId,
    ).findCompetitionById(_selectedCompetitionId);
    if (competition?.kind != _matchKind) return null;
    return competition;
  }

  List<String> _opponentOptions() {
    if (_isCompetitionMatch && _teams.isNotEmpty) {
      final sportId = widget.editingEntry?.sportId ??
          SportService(widget.optionRepository).currentSportId();
      final managedTeamName = _managedTeam(sportId)?.name.trim() ?? '';
      if (managedTeamName.isNotEmpty) {
        return _teams
            .where((team) => team.trim() != managedTeamName)
            .toList(growable: false);
      }
      return _teams.skip(1).toList(growable: false);
    }
    return MatchCompetitionService.normalizeTeams([
      for (final entry in _contextEntries) entry.opponentTeam,
      for (final entry in _contextEntries) entry.club,
    ]);
  }

  String _matchResultValue() {
    final scored = _ourScore;
    final conceded = _opponentScore;
    if (scored == null || conceded == null) return _resultUnset;
    if (scored > conceded) return _resultWin;
    if (scored < conceded) return _resultLoss;
    if (_hasDecisiveTournamentShootout) {
      return _penaltyShootoutGoalsFor! > _penaltyShootoutGoalsAgainst!
          ? _resultWin
          : _resultLoss;
    }
    return _resultDraw;
  }

  void _applyMatchResult(String result) {
    switch (result) {
      case _resultWin:
        _ourScore = 1;
        _opponentScore = 0;
      case _resultDraw:
        _ourScore = 1;
        _opponentScore = 1;
      case _resultLoss:
        _ourScore = 0;
        _opponentScore = 1;
      default:
        _ourScore = null;
        _opponentScore = null;
    }
    _clearTournamentShootoutIfNotRequired();
  }

  int? _calculatedLeaguePoints() {
    return switch (_matchResultValue()) {
      _resultWin => 3,
      _resultDraw => 1,
      _resultLoss => 0,
      _ => null,
    };
  }

  int? _calculatedTournamentWins() {
    final result = _matchResultValue();
    if (result != _resultUnset) {
      return result == _resultWin ? 1 : 0;
    }
    return switch (normalizeMatchTournamentOutcome(_tournamentOutcome)) {
      'advanced' || 'champion' => 1,
      'eliminated' => 0,
      _ => null,
    };
  }

  bool get _requiresTournamentShootout =>
      _matchKind == MatchCompetitionRecord.kindTournament &&
      _ourScore != null &&
      _opponentScore != null &&
      _ourScore == _opponentScore;

  bool get _hasDecisiveTournamentShootout =>
      _requiresTournamentShootout &&
      _penaltyShootoutGoalsFor != null &&
      _penaltyShootoutGoalsAgainst != null &&
      _penaltyShootoutGoalsFor != _penaltyShootoutGoalsAgainst;

  void _clearTournamentShootoutIfNotRequired() {
    if (_requiresTournamentShootout) return;
    _penaltyShootoutGoalsFor = null;
    _penaltyShootoutGoalsAgainst = null;
  }

  String? _tournamentShootoutValidationMessage(AppLocalizations l10n) {
    if (!_requiresTournamentShootout) return null;
    if (_penaltyShootoutGoalsFor == null ||
        _penaltyShootoutGoalsAgainst == null) {
      return l10n.matchTournamentShootoutRequired;
    }
    if (_penaltyShootoutGoalsFor == _penaltyShootoutGoalsAgainst) {
      return l10n.matchTournamentShootoutTie;
    }
    return null;
  }

  Future<void> _saveMatch({bool closeAfterSave = true}) async {
    if (_saving) return;
    final l10n = AppLocalizations.of(context)!;
    final previousEntry = widget.editingEntry;
    final sportId = previousEntry?.sportId ??
        SportService(widget.optionRepository).currentSportId();
    final selectedCompetition = _isCompetitionMatch
        ? MatchCompetitionService(
            widget.optionRepository,
            sportId: sportId,
          ).findCompetitionById(_selectedCompetitionId)
        : null;
    final opponent = _opponent.trim();
    final hasValidCompetition = !_isCompetitionMatch ||
        (selectedCompetition != null &&
            selectedCompetition.kind == _matchKind &&
            selectedCompetition.name.trim().isNotEmpty);
    final hasCompleteScore = _ourScore != null && _opponentScore != null;
    final shootoutValidationMessage =
        hasCompleteScore ? _tournamentShootoutValidationMessage(l10n) : null;
    if (!hasValidCompetition ||
        opponent.isEmpty ||
        !hasCompleteScore ||
        shootoutValidationMessage != null) {
      if (closeAfterSave) {
        setState(() => _showValidationErrors = true);
        AppFeedback.showMessage(
          context,
          text: !hasValidCompetition
              ? l10n.matchCompetitionSelectionRequired
              : opponent.isEmpty
                  ? l10n.matchOpponentRequired
                  : !hasCompleteScore
                      ? l10n.matchScoreRequired
                      : shootoutValidationMessage!,
        );
      }
      return;
    }
    final competitionName =
        _isCompetitionMatch ? selectedCompetition!.name.trim() : '';
    final managedTeamName =
        _isCompetitionMatch ? _managedTeam(sportId)?.name.trim() ?? '' : '';
    final teams = _isCompetitionMatch
        ? MatchCompetitionService.teamsWithManagedTeam(
            kind: selectedCompetition!.kind,
            teams: selectedCompetition.teams,
            managedTeamName: managedTeamName,
            fallbackTeamName: l10n.matchCompetitionMyTeamFallback,
            replaceLeagueFirstTeam: true,
          )
        : MatchCompetitionService.normalizeTeams(_teams);
    final savedOpponent = opponent;
    final calculatedLeaguePoints = _calculatedLeaguePoints();
    final calculatedTournamentWins = _calculatedTournamentWins();
    final saved = TrainingEntry(
      date: _matchDay,
      durationMinutes: previousEntry?.durationMinutes ?? 90,
      intensity: previousEntry?.intensity ?? 3,
      type: l10n.typeMatch,
      mood: previousEntry?.mood ?? 3,
      injury: previousEntry?.injury ?? false,
      notes: _memo.trim(),
      location: _location.trim(),
      program: l10n.typeMatch,
      club: savedOpponent,
      opponentTeam: savedOpponent,
      status: previousEntry?.status ?? 'normal',
      goodPoints: previousEntry?.goodPoints ?? '',
      improvements: previousEntry?.improvements ?? '',
      nextGoal: previousEntry?.nextGoal ?? '',
      goalFocuses: previousEntry?.goalFocuses ?? const <String>[],
      createdAt: previousEntry?.createdAt,
      scoredGoals: _ourScore,
      concededGoals: _opponentScore,
      penaltyShootoutGoalsFor:
          _requiresTournamentShootout ? _penaltyShootoutGoalsFor : null,
      penaltyShootoutGoalsAgainst:
          _requiresTournamentShootout ? _penaltyShootoutGoalsAgainst : null,
      playerGoals: _playerGoals,
      playerAssists: _playerAssists,
      shotsOnTarget: _shotsOnTarget,
      ballsWon: _ballsWon,
      yellowCards: _yellowCards,
      redCards: _redCards,
      minutesPlayed: _minutesPlayed,
      matchLocation: _location.trim(),
      matchKind: _matchKind,
      leagueTeamNames: teams,
      leagueResultMode: _matchKind == MatchCompetitionRecord.kindTournament
          ? 'tournamentWins'
          : 'points',
      leaguePoints: _matchKind == MatchCompetitionRecord.kindLeague
          ? calculatedLeaguePoints
          : null,
      tournamentWins: _matchKind == MatchCompetitionRecord.kindTournament
          ? calculatedTournamentWins
          : null,
      matchCompetitionName: _isCompetitionMatch ? competitionName : '',
      matchCompetitionId: _isCompetitionMatch
          ? selectedCompetition?.id ?? previousEntry?.matchCompetitionId ?? ''
          : '',
      matchFixtureId: _isFixtureBound
          ? widget.initialFixture!.id
          : previousEntry?.matchFixtureId ?? '',
      matchStage: _matchKind == MatchCompetitionRecord.kindTournament
          ? _tournamentStage
          : _matchKind == MatchCompetitionRecord.kindLeague
              ? _leagueRound.trim()
              : '',
      tournamentOutcome: _matchKind == MatchCompetitionRecord.kindTournament
          ? _tournamentOutcome
          : '',
      sportId: sportId,
    );

    if (!closeAfterSave && previousEntry?.key is! int) {
      return;
    }
    if (closeAfterSave) {
      _autoSaveTimer?.cancel();
      setState(() => _saving = true);
    }
    try {
      if (previousEntry?.key is int) {
        await widget.trainingService.update(previousEntry!.key as int, saved);
      } else {
        if (!closeAfterSave) return;
        await widget.trainingService.add(saved);
      }
      await MatchCompetitionService(
        widget.optionRepository,
        sportId: saved.sportId,
      ).upsertFromEntry(saved);
      if (!closeAfterSave) return;
      final award = await PlayerLevelService(
        widget.optionRepository,
        sportId: saved.sportId,
      ).awardForMatchLog(previousEntry: previousEntry, updatedEntry: saved);
      if (!mounted) return;
      AppSoundEffects.playRewardClaimed();
      AppFeedback.showSuccess(
        context,
        text: award.gainedXp > 0
            ? l10n.matchSavedWithXpFeedback(award.gainedXp)
            : previousEntry == null
                ? l10n.matchSavedFeedback
                : l10n.matchUpdatedFeedback,
      );
      if (award.gainedXp > 0) {
        final isKo =
            (widget.localeService.locale ?? Localizations.localeOf(context))
                .languageCode
                .startsWith('ko');
        final reminderService = TrainingPlanReminderService(
          widget.optionRepository,
          widget.settingsService,
          sportId: saved.sportId,
        );
        await reminderService.showXpGainAlert(
          gainedXp: award.gainedXp,
          totalXp: award.after.totalXp,
          isKo: isKo,
          sourceLabel: l10n.calendarMatchXpSourceLabel,
        );
        if (award.didLevelUp) {
          await reminderService.showLevelUpAlert(
            level: award.after.level,
            isKo: isKo,
          );
        }
      }
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (closeAfterSave && mounted) setState(() => _saving = false);
    }
  }
}

class _MatchRecordSection extends StatelessWidget {
  final int step;
  final IconData icon;
  final String title;
  final String? helper;
  final List<Widget> children;

  const _MatchRecordSection({
    required this.step,
    required this.icon,
    required this.title,
    required this.children,
    this.helper,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.22)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: AppRadius.small,
        border: Border.all(
          color: AppSurfaces.borderColor(
            scheme,
            theme.brightness,
          ).withValues(alpha: 0.58),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                step.toString().padLeft(2, '0'),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(icon, size: 20, color: scheme.primary),
              const SizedBox(width: AppSpacing.xs),
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
          ),
          if (helper != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              helper!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          ...children,
        ],
      ),
    );
  }
}

class _ScheduledFixtureContext extends StatelessWidget {
  final DateTime date;
  final String matchKindLabel;
  final String label;

  const _ScheduledFixtureContext({
    required this.date,
    required this.matchKindLabel,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.42),
        borderRadius: AppRadius.small,
      ),
      child: Row(
        children: [
          Icon(Icons.event_available_outlined,
              color: scheme.onSecondaryContainer),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              '$matchKindLabel · ${DateFormat('yyyy-MM-dd').format(date)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.onSecondaryContainer,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchFlowContextStrip extends StatelessWidget {
  final String teamName;
  final int playerCount;
  final String matchKindLabel;
  final String competitionName;
  final String opponentName;

  const _MatchFlowContextStrip({
    required this.teamName,
    required this.playerCount,
    required this.matchKindLabel,
    required this.competitionName,
    required this.opponentName,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final competitionLabel = competitionName.trim().isEmpty
        ? l10n.matchFlowCompetitionSectionTitle
        : competitionName.trim();
    final opponentLabel = opponentName.trim().isEmpty
        ? l10n.matchOpponentTeamLabel
        : opponentName.trim();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.06),
        borderRadius: AppRadius.small,
        border: Border.all(color: scheme.primary.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _MatchFlowNode(
              icon: Icons.groups_2_outlined,
              label:
                  '$teamName · ${l10n.teamManagementPlayerCount(playerCount)}',
            ),
          ),
          _MatchFlowArrow(color: scheme.onSurfaceVariant),
          Expanded(
            child: _MatchFlowNode(
              icon: Icons.sports_soccer_outlined,
              label: matchKindLabel,
            ),
          ),
          _MatchFlowArrow(color: scheme.onSurfaceVariant),
          Expanded(
            child: _MatchFlowNode(
              icon: Icons.emoji_events_outlined,
              label: competitionLabel,
            ),
          ),
          _MatchFlowArrow(color: scheme.onSurfaceVariant),
          Expanded(
            child: _MatchFlowNode(
              icon: Icons.shield_outlined,
              label: opponentLabel,
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchFlowNode extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MatchFlowNode({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: scheme.primary),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
      ],
    );
  }
}

class _MatchFlowArrow extends StatelessWidget {
  final Color color;

  const _MatchFlowArrow({required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
      child: Icon(
        Icons.chevron_right_rounded,
        size: 15,
        color: color.withValues(alpha: 0.56),
      ),
    );
  }
}

class _ManagedCompetitionRequiredNotice extends StatelessWidget {
  final VoidCallback onOpenCompetitionManagement;

  const _ManagedCompetitionRequiredNotice({
    required this.onOpenCompetitionManagement,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.emoji_events_outlined, color: scheme.primary),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.matchCompetitionManagedOnlyTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  l10n.matchCompetitionManagedOnlyBody,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: OutlinedButton.icon(
                    onPressed: onOpenCompetitionManagement,
                    icon: const Icon(Icons.open_in_new_outlined),
                    label: Text(l10n.matchCompetitionOpenButton),
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

class _SelectedCompetitionSummary extends StatelessWidget {
  final MatchCompetitionRecord competition;

  const _SelectedCompetitionSummary({required this.competition});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final statusLabel = competition.isFinished
        ? l10n.matchCompetitionStatusFinished
        : l10n.matchCompetitionStatusActive;
    final teams = MatchCompetitionService.normalizeTeams(competition.teams);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.verified_outlined, color: scheme.primary, size: 20),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.matchCompetitionSelectedTitle,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      competition.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              _SmallInfoPill(
                label: statusLabel,
                color: competition.isFinished
                    ? scheme.onSurfaceVariant
                    : scheme.primary,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              _SmallInfoPill(
                label: l10n.matchCompetitionTeamCount(teams.length),
                color: scheme.secondary,
              ),
              if (competition.venue.trim().isNotEmpty)
                _SmallInfoPill(
                  label: competition.venue.trim(),
                  color: scheme.tertiary,
                ),
            ],
          ),
          if (teams.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final team in teams.take(8))
                  Chip(
                    label: Text(team),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.xs),
            _InlineHint(text: l10n.matchCompetitionNoTeams),
          ],
        ],
      ),
    );
  }
}

class _SmallInfoPill extends StatelessWidget {
  final String label;
  final Color color;

  const _SmallInfoPill({
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

class _SavedCompetitionLoader extends StatelessWidget {
  final List<MatchCompetitionRecord> competitions;
  final String selectedCompetitionId;
  final bool enabled;
  final ValueChanged<MatchCompetitionRecord> onSelected;

  const _SavedCompetitionLoader({
    required this.competitions,
    required this.selectedCompetitionId,
    required this.enabled,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selectedValue =
        competitions.any((record) => record.id == selectedCompetitionId)
            ? selectedCompetitionId
            : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: DropdownButtonFormField<String>(
        key: const ValueKey<String>('match-saved-competition-loader'),
        initialValue: selectedValue,
        items: [
          for (final competition in competitions)
            DropdownMenuItem<String>(
              value: competition.id,
              child: Text(
                competition.isFinished
                    ? l10n.matchCompetitionOptionFinished(
                        competition.name,
                      )
                    : l10n.matchCompetitionOptionActive(competition.name),
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: enabled
            ? (value) {
                if (value == null) return;
                for (final competition in competitions) {
                  if (competition.id == value) {
                    onSelected(competition);
                    return;
                  }
                }
              }
            : null,
        decoration: InputDecoration(
          labelText: l10n.matchCompetitionQuickLoadTitle,
          prefixIcon: const Icon(Icons.cloud_download_outlined),
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
        ),
      ),
    );
  }
}

class _LiveScoreboard extends StatelessWidget {
  final String homeLabel;
  final String awayLabel;
  final int? homeScore;
  final int? awayScore;
  final ValueChanged<int?> onHomeScoreChanged;
  final ValueChanged<int?> onAwayScoreChanged;

  const _LiveScoreboard({
    required this.homeLabel,
    required this.awayLabel,
    required this.homeScore,
    required this.awayScore,
    required this.onHomeScoreChanged,
    required this.onAwayScoreChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        final separator = _ScoreSeparator(
          vertical: !compact,
          homeScore: homeScore,
          awayScore: awayScore,
        );
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ScorePanel(
                label: homeLabel,
                value: homeScore,
                accent: Theme.of(context).colorScheme.primary,
                increaseKey: const ValueKey<String>(
                  'match-board-our-score-increase',
                ),
                decreaseKey: const ValueKey<String>(
                  'match-board-our-score-decrease',
                ),
                onChanged: onHomeScoreChanged,
              ),
              separator,
              _ScorePanel(
                label: awayLabel,
                value: awayScore,
                accent: Theme.of(context).colorScheme.tertiary,
                increaseKey: const ValueKey<String>(
                  'match-board-opponent-score-increase',
                ),
                decreaseKey: const ValueKey<String>(
                  'match-board-opponent-score-decrease',
                ),
                onChanged: onAwayScoreChanged,
              ),
            ],
          );
        }
        return Row(
          children: [
            Expanded(
              child: _ScorePanel(
                label: homeLabel,
                value: homeScore,
                accent: Theme.of(context).colorScheme.primary,
                increaseKey: const ValueKey<String>(
                  'match-board-our-score-increase',
                ),
                decreaseKey: const ValueKey<String>(
                  'match-board-our-score-decrease',
                ),
                onChanged: onHomeScoreChanged,
              ),
            ),
            separator,
            Expanded(
              child: _ScorePanel(
                label: awayLabel,
                value: awayScore,
                accent: Theme.of(context).colorScheme.tertiary,
                increaseKey: const ValueKey<String>(
                  'match-board-opponent-score-increase',
                ),
                decreaseKey: const ValueKey<String>(
                  'match-board-opponent-score-decrease',
                ),
                onChanged: onAwayScoreChanged,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TournamentShootoutScoreboard extends StatelessWidget {
  final String title;
  final String helper;
  final String homeLabel;
  final String awayLabel;
  final int? homeScore;
  final int? awayScore;
  final ValueChanged<int?> onHomeScoreChanged;
  final ValueChanged<int?> onAwayScoreChanged;

  const _TournamentShootoutScoreboard({
    required this.title,
    required this.helper,
    required this.homeLabel,
    required this.awayLabel,
    required this.homeScore,
    required this.awayScore,
    required this.onHomeScoreChanged,
    required this.onAwayScoreChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.sports_soccer_rounded, size: 18, color: scheme.primary),
            const SizedBox(width: AppSpacing.xs),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          helper,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: _ScorePanel(
                label: homeLabel,
                value: homeScore,
                accent: scheme.primary,
                increaseKey: const ValueKey<String>(
                  'match-board-penalty-home-increase',
                ),
                decreaseKey: const ValueKey<String>(
                  'match-board-penalty-home-decrease',
                ),
                onChanged: onHomeScoreChanged,
              ),
            ),
            _ScoreSeparator(
              vertical: true,
              homeScore: homeScore,
              awayScore: awayScore,
            ),
            Expanded(
              child: _ScorePanel(
                label: awayLabel,
                value: awayScore,
                accent: scheme.tertiary,
                increaseKey: const ValueKey<String>(
                  'match-board-penalty-away-increase',
                ),
                decreaseKey: const ValueKey<String>(
                  'match-board-penalty-away-decrease',
                ),
                onChanged: onAwayScoreChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ScorePanel extends StatelessWidget {
  final String label;
  final int? value;
  final Color accent;
  final Key increaseKey;
  final Key decreaseKey;
  final ValueChanged<int?> onChanged;

  const _ScorePanel({
    required this.label,
    required this.value,
    required this.accent,
    required this.increaseKey,
    required this.decreaseKey,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final current = value ?? 0;
    return Container(
      constraints: const BoxConstraints(minHeight: 118),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: AppRadius.small,
        border: Border.all(color: accent.withValues(alpha: 0.26)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              _CounterButton(
                buttonKey: decreaseKey,
                tooltip: l10n.matchCountDecreaseTooltip(label),
                icon: Icons.remove_rounded,
                accent: accent,
                enabled: current > 0,
                onPressed: () {
                  final next = current - 1;
                  onChanged(next <= 0 ? null : next);
                },
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    current.toString(),
                    style: theme.textTheme.displayMedium?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w900,
                      height: 0.92,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              _CounterButton(
                buttonKey: increaseKey,
                tooltip: l10n.matchCountIncreaseTooltip(label),
                icon: Icons.add_rounded,
                accent: accent,
                enabled: true,
                onPressed: () => onChanged(current + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreSeparator extends StatelessWidget {
  final bool vertical;
  final int? homeScore;
  final int? awayScore;

  const _ScoreSeparator({
    required this.vertical,
    required this.homeScore,
    required this.awayScore,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final resolved = homeScore != null && awayScore != null;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: vertical ? AppSpacing.sm : 0,
        vertical: vertical ? 0 : AppSpacing.xs,
      ),
      child: Icon(
        resolved ? Icons.sports_score_outlined : Icons.more_horiz_rounded,
        color: resolved ? scheme.primary : scheme.onSurfaceVariant,
        size: 24,
      ),
    );
  }
}

class _ResultChoiceStrip extends StatelessWidget {
  final String selected;
  final ValueChanged<String>? onSelected;

  const _ResultChoiceStrip({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final options = [
      (
        value: _MatchRecordScreenState._resultUnset,
        label: l10n.matchResultUnset
      ),
      (value: _MatchRecordScreenState._resultWin, label: l10n.matchResultWin),
      (value: _MatchRecordScreenState._resultDraw, label: l10n.matchResultDraw),
      (value: _MatchRecordScreenState._resultLoss, label: l10n.matchResultLoss),
    ];
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      alignment: WrapAlignment.center,
      children: [
        for (final option in options)
          ChoiceChip(
            label: Text(option.label),
            selected: selected == option.value,
            onSelected:
                onSelected == null ? null : (_) => onSelected!(option.value),
          ),
      ],
    );
  }
}

class _DynamicCounterGrid extends StatelessWidget {
  final List<Widget> children;

  const _DynamicCounterGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760
            ? 5
            : constraints.maxWidth >= 560
                ? 3
                : constraints.maxWidth >= 330
                    ? 3
                    : 2;
        const gap = AppSpacing.xs;
        final itemWidth =
            (constraints.maxWidth - (gap * (columns - 1))) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}

class _TouchCounter extends StatelessWidget {
  final String label;
  final IconData icon;
  final int? value;
  final int step;
  final Key? increaseKey;
  final Key? decreaseKey;
  final Color? accent;
  final ValueChanged<int?> onChanged;

  const _TouchCounter({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
    this.step = 1,
    this.increaseKey,
    this.decreaseKey,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accentColor = accent ?? scheme.primary;
    final current = value ?? 0;
    return Container(
      constraints: const BoxConstraints(minHeight: 94),
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: value == null
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.42)
            : accentColor.withValues(alpha: 0.08),
        borderRadius: AppRadius.small,
        border: Border.all(
          color: value == null
              ? AppSurfaces.borderColor(scheme, theme.brightness)
              : accentColor.withValues(alpha: 0.24),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(icon, size: 16, color: accentColor),
          const SizedBox(height: AppSpacing.xxs),
          SizedBox(
            height: 28,
            child: Center(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: value == null ? scheme.onSurfaceVariant : accentColor,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Row(
            children: [
              _CounterButton(
                buttonKey: decreaseKey,
                tooltip: l10n.matchCountDecreaseTooltip(label),
                icon: Icons.remove_rounded,
                accent: accentColor,
                enabled: current > 0,
                onPressed: () {
                  final next = current - step;
                  onChanged(next <= 0 ? null : next);
                },
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Container(
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: value == null
                        ? scheme.surface
                        : accentColor.withValues(alpha: 0.11),
                    borderRadius: AppRadius.small,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      current.toString(),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: value == null
                            ? scheme.onSurfaceVariant
                            : accentColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              _CounterButton(
                buttonKey: increaseKey,
                tooltip: l10n.matchCountIncreaseTooltip(label),
                icon: Icons.add_rounded,
                accent: accentColor,
                enabled: true,
                onPressed: () => onChanged(current + step),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CounterButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;
  final Key? buttonKey;
  final Color? accent;

  const _CounterButton({
    required this.tooltip,
    required this.icon,
    required this.enabled,
    required this.onPressed,
    this.buttonKey,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accentColor = accent ?? scheme.primary;
    return SizedBox.square(
      key: buttonKey,
      dimension: 34,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: enabled
              ? accentColor.withValues(alpha: 0.10)
              : scheme.surfaceContainerHighest,
          borderRadius: AppRadius.small,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: AppRadius.small,
            child: Icon(
              icon,
              size: 19,
              color: enabled
                  ? accentColor
                  : scheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineHint extends StatelessWidget {
  final String text;
  final bool isError;

  const _InlineHint({required this.text, this.isError = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isError
            ? theme.colorScheme.errorContainer.withValues(alpha: 0.6)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: AppRadius.small,
      ),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: isError
              ? theme.colorScheme.onErrorContainer
              : theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RequiredFieldError extends StatelessWidget {
  final String text;

  const _RequiredFieldError({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.error_outline, size: 18, color: theme.colorScheme.error),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _InfoPanel({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: AppSurfaces.cardDecoration(
        theme.colorScheme,
        theme.brightness,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Icon(icon, size: 32, color: theme.colorScheme.primary),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
