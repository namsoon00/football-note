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
import '../../application/training_plan_reminder_service.dart';
import '../../application/training_service.dart';
import '../../domain/entities/training_entry.dart';
import '../../domain/repositories/option_repository.dart';
import '../theme/app_theme.dart';
import '../utils/match_entry_format.dart';
import '../widgets/app_bar_action_button.dart';
import '../widgets/app_feedback.dart';

class MatchRecordScreen extends StatefulWidget {
  final TrainingService trainingService;
  final LocaleService localeService;
  final OptionRepository optionRepository;
  final SettingsService settingsService;
  final DateTime? initialDate;
  final TrainingEntry? editingEntry;

  const MatchRecordScreen({
    super.key,
    required this.trainingService,
    required this.localeService,
    required this.optionRepository,
    required this.settingsService,
    this.initialDate,
    this.editingEntry,
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
  late String _competitionName;
  late String _competitionStatus;
  late String _selectedCompetitionId;
  late String _leagueRound;
  late String _tournamentStage;
  late String _tournamentOutcome;
  late List<String> _teams;
  late int? _ourScore;
  late int? _opponentScore;
  late int? _playerGoals;
  late int? _playerAssists;
  late int? _shotsOnTarget;
  late int? _ballsWon;
  late int? _minutesPlayed;
  late int? _leaguePoints;
  late int? _tournamentWins;
  late String _memo;

  final TextEditingController _competitionNameController =
      TextEditingController();
  final TextEditingController _teamController = TextEditingController();
  final TextEditingController _opponentController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _roundController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();

  List<TrainingEntry> _contextEntries = const <TrainingEntry>[];
  bool _saving = false;
  Timer? _autoSaveTimer;
  bool _autoSaveInFlight = false;
  bool _autoSaveQueued = false;

  bool get _isCompetitionMatch =>
      _matchKind == MatchCompetitionRecord.kindLeague ||
      _matchKind == MatchCompetitionRecord.kindTournament;

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
  void dispose() {
    _autoSaveTimer?.cancel();
    _competitionNameController.dispose();
    _teamController.dispose();
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
    _competitionName = entry?.matchCompetitionName ?? '';
    _competitionStatus = MatchCompetitionRecord.statusActive;
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
    _playerGoals = entry?.playerGoals;
    _playerAssists = entry?.playerAssists;
    _shotsOnTarget = entry?.shotsOnTarget;
    _ballsWon = entry?.ballsWon;
    _minutesPlayed = entry?.minutesPlayed;
    _leaguePoints = entry?.leaguePoints;
    _tournamentWins = entry?.tournamentWins;
    _memo = entry?.notes ?? '';

    _competitionNameController.text = _competitionName;
    _opponentController.text = _opponent;
    _locationController.text = _location;
    _roundController.text = _leagueRound;
    _memoController.text = _memo;

    final sportId = entry?.sportId ??
        SportService(widget.optionRepository).currentSportId();
    final competition = MatchCompetitionService(
      widget.optionRepository,
      sportId: sportId,
    ).findCompetition(kind: _matchKind, name: _competitionName);
    if (competition != null) {
      _applyCompetition(competition);
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
    setState(() => _contextEntries = entries);
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
                  child: AppBarActionButton.icon(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: Icons.arrow_back,
                    tooltip:
                        MaterialLocalizations.of(context).backButtonTooltip,
                    margin: EdgeInsets.zero,
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
                _buildBasicsSection(context),
                if (_isCompetitionMatch) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _buildCompetitionSection(context),
                ],
                const SizedBox(height: AppSpacing.sm),
                _buildOpponentSection(context),
                const SizedBox(height: AppSpacing.sm),
                _buildResultSection(context),
                const SizedBox(height: AppSpacing.sm),
                _buildPersonalSection(context),
                const SizedBox(height: AppSpacing.lg),
                _buildActions(context),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppBarActionButton.icon(
          onPressed: _saving ? null : () => Navigator.of(context).maybePop(),
          icon: Icons.arrow_back,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          margin: EdgeInsets.zero,
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.editingEntry == null
                    ? l10n.matchAddTitle
                    : l10n.matchEditTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                l10n.matchHubSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBasicsSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _MatchRecordSection(
      step: 1,
      icon: Icons.event_available_outlined,
      title: l10n.matchFlowBasicSectionTitle,
      children: [
        OutlinedButton.icon(
          onPressed: _saving ? null : _pickMatchDate,
          icon: const Icon(Icons.calendar_today_outlined),
          label: Text(DateFormat('yyyy-MM-dd').format(_matchDay)),
        ),
        const SizedBox(height: AppSpacing.xs),
        SegmentedButton<String>(
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
          onSelectionChanged: _saving
              ? null
              : (selection) {
                  _updateAndScheduleAutoSave(() {
                    _matchKind = selection.first;
                    _selectedCompetitionId = '';
                    _competitionName = '';
                    _competitionStatus = MatchCompetitionRecord.statusActive;
                    _competitionNameController.clear();
                    _teams = const <String>[];
                    _opponent = '';
                    _opponentController.clear();
                  });
                },
        ),
        const SizedBox(height: AppSpacing.xs),
        TextField(
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
          ),
        ),
      ],
    );
  }

  Widget _buildCompetitionSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sportId = widget.editingEntry?.sportId ??
        SportService(widget.optionRepository).currentSportId();
    final competitions = MatchCompetitionService(
      widget.optionRepository,
      sportId: sportId,
    ).competitionsForKind(_matchKind);
    final selectedValue = competitions.any(
      (competition) => competition.id == _selectedCompetitionId,
    )
        ? _selectedCompetitionId
        : null;
    return _MatchRecordSection(
      step: 2,
      icon: _matchKind == MatchCompetitionRecord.kindTournament
          ? Icons.account_tree_outlined
          : Icons.leaderboard_outlined,
      title: l10n.matchFlowCompetitionSectionTitle,
      helper: l10n.matchFlowCompetitionSectionHelper,
      children: [
        if (competitions.isNotEmpty) ...[
          DropdownButtonFormField<String>(
            initialValue: selectedValue,
            items: [
              for (final competition in competitions)
                DropdownMenuItem<String>(
                  value: competition.id,
                  child: Text(
                    competition.isFinished
                        ? l10n.matchCompetitionOptionFinished(competition.name)
                        : l10n.matchCompetitionOptionActive(competition.name),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: _saving
                ? null
                : (value) {
                    final record = value == null
                        ? null
                        : MatchCompetitionService(
                            widget.optionRepository,
                            sportId: sportId,
                          ).findCompetitionById(value);
                    if (record == null) return;
                    _updateAndScheduleAutoSave(() => _applyCompetition(record));
                  },
            decoration: InputDecoration(
              labelText: l10n.matchCompetitionSelectLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        TextField(
          controller: _competitionNameController,
          enabled: !_saving,
          maxLength: 40,
          textInputAction: TextInputAction.next,
          onChanged: (value) {
            _competitionName = value;
            _selectedCompetitionId = '';
            _scheduleAutoSave();
          },
          decoration: InputDecoration(
            labelText: l10n.matchCompetitionNameLabel,
            hintText: _matchKind == MatchCompetitionRecord.kindTournament
                ? l10n.matchTournamentNameHint
                : l10n.matchLeagueNameHint,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        SegmentedButton<String>(
          segments: [
            ButtonSegment<String>(
              value: MatchCompetitionRecord.statusActive,
              label: Text(l10n.matchCompetitionStatusActive),
            ),
            ButtonSegment<String>(
              value: MatchCompetitionRecord.statusFinished,
              label: Text(l10n.matchCompetitionStatusFinished),
            ),
          ],
          selected: {_competitionStatus},
          showSelectedIcon: false,
          onSelectionChanged: _saving
              ? null
              : (selection) {
                  _updateAndScheduleAutoSave(
                    () => _competitionStatus = selection.first,
                  );
                },
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildTeamEditor(context),
        const SizedBox(height: AppSpacing.xs),
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
            ),
          ),
      ],
    );
  }

  Widget _buildTeamEditor(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.matchCompetitionTeamsListTitle,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        if (_teams.isEmpty)
          _InlineHint(text: l10n.matchCompetitionNoTeams)
        else
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final team in _teams)
                InputChip(
                  label: Text(team),
                  onDeleted: _saving
                      ? null
                      : () {
                          _updateAndScheduleAutoSave(() {
                            _teams = _teams
                                .where((candidate) => candidate != team)
                                .toList(growable: false);
                            if (_opponent == team) {
                              _opponent = '';
                              _opponentController.clear();
                            }
                          });
                        },
                ),
            ],
          ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _teamController,
                enabled: !_saving,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _addTeamFromField(),
                decoration: InputDecoration(
                  labelText: l10n.matchCompetitionTeamNameLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            SizedBox(
              height: 56,
              child: FilledButton.icon(
                onPressed: _saving ? null : _addTeamFromField,
                icon: const Icon(Icons.add),
                label: Text(l10n.matchCompetitionAddTeamButton),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOpponentSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final options = _opponentOptions();
    return _MatchRecordSection(
      step: _isCompetitionMatch ? 3 : 2,
      icon: Icons.groups_outlined,
      title: l10n.matchFlowOpponentSectionTitle,
      helper: _isCompetitionMatch ? l10n.matchFlowOpponentSectionHelper : null,
      children: [
        if (_isCompetitionMatch && options.isNotEmpty)
          DropdownButtonFormField<String>(
            initialValue: options.contains(_opponent) ? _opponent : null,
            items: [
              for (final team in options)
                DropdownMenuItem<String>(
                  value: team,
                  child: Text(team, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: _saving
                ? null
                : (value) {
                    if (value == null) return;
                    _updateAndScheduleAutoSave(() {
                      _opponent = value;
                      _opponentController.text = value;
                    });
                  },
            decoration: InputDecoration(
              labelText: l10n.matchOpponentTeamLabel,
              border: const OutlineInputBorder(),
            ),
          )
        else
          TextField(
            controller: _opponentController,
            enabled: !_saving,
            maxLength: 40,
            textInputAction: TextInputAction.next,
            onChanged: (value) {
              _opponent = value;
              _scheduleAutoSave();
            },
            decoration: InputDecoration(
              labelText: l10n.matchOpponentTeamLabel,
              hintText: l10n.matchOpponentTeamHint,
              border: const OutlineInputBorder(),
            ),
          ),
      ],
    );
  }

  Widget _buildResultSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final step = _isCompetitionMatch ? 4 : 3;
    return _MatchRecordSection(
      step: step,
      icon: Icons.scoreboard_outlined,
      title: l10n.matchFlowResultSectionTitle,
      helper: l10n.matchFlowResultSectionHelper,
      children: [
        SegmentedButton<String>(
          segments: [
            ButtonSegment<String>(
              value: _resultUnset,
              label: Text(l10n.matchResultUnset),
            ),
            ButtonSegment<String>(
              value: _resultWin,
              label: Text(l10n.matchResultWin),
            ),
            ButtonSegment<String>(
              value: _resultDraw,
              label: Text(l10n.matchResultDraw),
            ),
            ButtonSegment<String>(
              value: _resultLoss,
              label: Text(l10n.matchResultLoss),
            ),
          ],
          selected: {_matchResultValue()},
          showSelectedIcon: false,
          onSelectionChanged: _saving
              ? null
              : (selection) => _updateAndScheduleAutoSave(
                    () => _applyMatchResult(selection.first),
                  ),
        ),
        const SizedBox(height: AppSpacing.xs),
        _TwoColumn(
          children: [
            _TouchCounter(
              label: l10n.matchOurScoreLabel,
              value: _ourScore,
              onChanged: (value) =>
                  _updateAndScheduleAutoSave(() => _ourScore = value),
            ),
            _TouchCounter(
              label: l10n.matchOpponentScoreLabel,
              value: _opponentScore,
              onChanged: (value) =>
                  _updateAndScheduleAutoSave(() => _opponentScore = value),
            ),
          ],
        ),
        if (_matchKind == MatchCompetitionRecord.kindTournament) ...[
          const SizedBox(height: AppSpacing.xs),
          DropdownButtonFormField<String>(
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
            ),
          ),
        ],
        if (_isCompetitionMatch) ...[
          const SizedBox(height: AppSpacing.xs),
          _TouchCounter(
            label: _matchKind == MatchCompetitionRecord.kindLeague
                ? l10n.matchLeaguePointsLabel
                : l10n.matchTournamentWinsLabel,
            value: _matchKind == MatchCompetitionRecord.kindLeague
                ? _leaguePoints
                : _tournamentWins,
            onChanged: (value) {
              _updateAndScheduleAutoSave(() {
                if (_matchKind == MatchCompetitionRecord.kindLeague) {
                  _leaguePoints = value;
                } else {
                  _tournamentWins = value;
                }
              });
            },
          ),
        ],
      ],
    );
  }

  Widget _buildPersonalSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sportId = widget.editingEntry?.sportId ??
        SportService(widget.optionRepository).currentSportId();
    final labels = SportMatchLabels.forSport(l10n: l10n, sportId: sportId);
    return _MatchRecordSection(
      step: _isCompetitionMatch ? 5 : 4,
      icon: Icons.person_outline,
      title: l10n.matchFlowPersonalSectionTitle,
      helper: l10n.matchFlowPersonalSectionHelper,
      children: [
        _TwoColumn(
          children: [
            _TouchCounter(
              label: labels.primary.label,
              value: _playerGoals,
              onChanged: (value) =>
                  _updateAndScheduleAutoSave(() => _playerGoals = value),
            ),
            _TouchCounter(
              label: labels.secondary.label,
              value: _playerAssists,
              onChanged: (value) =>
                  _updateAndScheduleAutoSave(() => _playerAssists = value),
            ),
            _TouchCounter(
              label: labels.tertiary.label,
              value: _shotsOnTarget,
              onChanged: (value) =>
                  _updateAndScheduleAutoSave(() => _shotsOnTarget = value),
            ),
            _TouchCounter(
              label: labels.quaternary.label,
              value: _ballsWon,
              onChanged: (value) =>
                  _updateAndScheduleAutoSave(() => _ballsWon = value),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        _TouchCounter(
          label: l10n.matchMinutesPlayedLabel,
          value: _minutesPlayed,
          onChanged: (value) =>
              _updateAndScheduleAutoSave(() => _minutesPlayed = value),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextField(
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
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _saving ? null : () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back),
            label: Text(l10n.matchCompetitionBackButton),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: FilledButton.icon(
            onPressed: _saving ? null : _saveMatch,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(l10n.save),
          ),
        ),
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
    _selectedCompetitionId = record.id;
    _competitionName = record.name;
    _competitionNameController.text = record.name;
    _competitionStatus = record.status;
    _teams = MatchCompetitionService.normalizeTeams(record.teams);
    if (!_teams.contains(_opponent.trim())) {
      _opponent = '';
      _opponentController.clear();
    }
  }

  void _addTeamFromField() {
    final l10n = AppLocalizations.of(context)!;
    final value = _teamController.text.trim();
    if (value.isEmpty) {
      AppFeedback.showMessage(
        context,
        text: l10n.matchCompetitionTeamNameRequired,
      );
      return;
    }
    final nextTeams =
        MatchCompetitionService.normalizeTeams([..._teams, value]);
    if (nextTeams.length == _teams.length) {
      AppFeedback.showMessage(
        context,
        text: l10n.matchCompetitionTeamAlreadyAdded,
      );
      return;
    }
    setState(() {
      _teams = nextTeams;
      _teamController.clear();
    });
    _scheduleAutoSave();
  }

  List<String> _opponentOptions() {
    if (_isCompetitionMatch && _teams.isNotEmpty) return _teams;
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
  }

  Future<void> _saveMatch({bool closeAfterSave = true}) async {
    if (_saving) return;
    final l10n = AppLocalizations.of(context)!;
    final opponent = _opponent.trim();
    final competitionName = _competitionName.trim();
    final teams = MatchCompetitionService.normalizeTeams(_teams);
    if (_isCompetitionMatch && competitionName.isEmpty) {
      if (closeAfterSave) {
        AppFeedback.showMessage(
          context,
          text: l10n.matchCompetitionNameRequired,
        );
      }
      return;
    }
    if (opponent.isEmpty && teams.isEmpty) {
      if (closeAfterSave) {
        AppFeedback.showMessage(
          context,
          text: l10n.matchOpponentTeamHint,
        );
      }
      return;
    }
    final savedOpponent = opponent.isNotEmpty ? opponent : teams.first;
    final previousEntry = widget.editingEntry;
    final sportId = previousEntry?.sportId ??
        SportService(widget.optionRepository).currentSportId();
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
      playerGoals: _playerGoals,
      playerAssists: _playerAssists,
      shotsOnTarget: _shotsOnTarget,
      ballsWon: _ballsWon,
      minutesPlayed: _minutesPlayed,
      matchLocation: _location.trim(),
      matchKind: _matchKind,
      leagueTeamNames: teams,
      leagueResultMode: _matchKind == MatchCompetitionRecord.kindTournament
          ? 'tournamentWins'
          : 'points',
      leaguePoints: _matchKind == MatchCompetitionRecord.kindLeague
          ? _leaguePoints
          : null,
      tournamentWins: _matchKind == MatchCompetitionRecord.kindTournament
          ? _tournamentWins
          : null,
      matchCompetitionName: _isCompetitionMatch ? competitionName : '',
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
      if (_isCompetitionMatch) {
        final competitionService = MatchCompetitionService(
          widget.optionRepository,
          sportId: sportId,
        );
        final existingCompetition = _selectedCompetitionId.trim().isNotEmpty
            ? competitionService.findCompetitionById(_selectedCompetitionId)
            : competitionService.findCompetition(
                kind: _matchKind,
                name: competitionName,
              );
        await competitionService.upsertCompetition(
          MatchCompetitionRecord.create(
            kind: _matchKind,
            name: competitionName,
            teams: MatchCompetitionService.normalizeTeams([
              ...teams,
              savedOpponent,
            ]),
            status: _competitionStatus,
            season: existingCompetition?.season ?? '',
            venue: existingCompetition?.venue ?? '',
            organizer: existingCompetition?.organizer ?? '',
            note: existingCompetition?.note ?? '',
          ),
        );
      }
      await MatchCompetitionService(
        widget.optionRepository,
        sportId: saved.sportId,
      ).upsertFromEntry(saved);
      if (previousEntry?.key is int) {
        await widget.trainingService.update(previousEntry!.key as int, saved);
      } else {
        if (!closeAfterSave) return;
        await widget.trainingService.add(saved);
      }
      if (!closeAfterSave) return;
      final award = await PlayerLevelService(
        widget.optionRepository,
        sportId: saved.sportId,
      ).awardForMatchLog(previousEntry: previousEntry, updatedEntry: saved);
      if (!mounted) return;
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
      decoration: AppSurfaces.cardDecoration(scheme, theme.brightness),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: AppRadius.small,
                ),
                child: Text(
                  step.toString(),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w900,
                  ),
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
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }
}

class _TwoColumn extends StatelessWidget {
  final List<Widget> children;

  const _TwoColumn({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - AppSpacing.xs) / 2;
        return Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
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
  final int? value;
  final ValueChanged<int?> onChanged;

  const _TouchCounter({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final current = value ?? 0;
    return Container(
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.46),
        borderRadius: AppRadius.small,
        border: Border.all(
            color: AppSurfaces.borderColor(scheme, theme.brightness)),
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
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              _CounterButton(
                tooltip: l10n.matchCountDecreaseTooltip(label),
                icon: Icons.remove_rounded,
                enabled: current > 0,
                onPressed: () {
                  final next = current - 1;
                  onChanged(next <= 0 ? null : next);
                },
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Container(
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: value == null
                        ? scheme.surface
                        : scheme.primary.withValues(alpha: 0.10),
                    borderRadius: AppRadius.small,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      current.toString(),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: value == null
                            ? scheme.onSurfaceVariant
                            : scheme.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              _CounterButton(
                tooltip: l10n.matchCountIncreaseTooltip(label),
                icon: Icons.add_rounded,
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

class _CounterButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  const _CounterButton({
    required this.tooltip,
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox.square(
      dimension: 40,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: enabled
              ? scheme.primary.withValues(alpha: 0.10)
              : scheme.surfaceContainerHighest,
          borderRadius: AppRadius.small,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: AppRadius.small,
            child: Icon(
              icon,
              size: 20,
              color: enabled
                  ? scheme.primary
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

  const _InlineHint({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: AppRadius.small,
      ),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
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
