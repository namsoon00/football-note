import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../application/league_fixture_reminder_service.dart';
import '../../application/settings_service.dart';
import '../../application/world_cup_live_data_service.dart';
import '../../application/world_cup_roster_data.dart';
import '../../application/world_cup_schedule.dart';
import '../../domain/entities/fifa_world_overview.dart';
import '../../domain/repositories/option_repository.dart';
import '../../gen/app_localizations.dart';
import '../utils/kickoff_time_format.dart';
import '../widgets/app_background.dart';
import '../widgets/watch_cart/watch_cart_card.dart';

class WorldCupScreen extends StatefulWidget {
  final OptionRepository? optionRepository;
  final SettingsService? settingsService;
  final WorldCupLiveDataService? liveDataService;
  final bool refreshOfficialDataOnOpen;
  final DateTime? initialSelectedDay;
  final DateTime? currentTime;

  const WorldCupScreen({
    super.key,
    this.optionRepository,
    this.settingsService,
    this.liveDataService,
    this.refreshOfficialDataOnOpen = true,
    this.initialSelectedDay,
    this.currentTime,
  });

  @override
  State<WorldCupScreen> createState() => _WorldCupScreenState();
}

class _WorldCupScreenState extends State<WorldCupScreen> {
  static const String _supportCountryKey = 'world_cup_support_country_v1';
  static const String _interestCountriesKey = 'world_cup_interest_countries_v1';
  static const double _calendarDayNumberFontSize = 17;
  static const double _selectedDayPageViewportFraction = 0.94;
  static final Uri _sourceUri = Uri.parse(
    'https://www.fifa.com/en/tournaments/mens/worldcup/canadamexicousa2026/articles/match-schedule-fixtures-results-teams-stadiums',
  );
  static final DateTime _openingDate = DateTime(2026, 6, 11);
  static final DateTime _finalDate = DateTime(2026, 7, 19);

  late final List<String> _countries;
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  String _supportCountry = '';
  bool _supportCountryRegistered = false;
  Set<String> _interestCountries = <String>{};
  bool _showSelectedCountriesOnly = false;
  bool _showCountrySettings = true;
  _WorldCupView _selectedView = _WorldCupView.schedule;
  late final WorldCupLiveDataService _liveDataService;
  late final bool _ownsLiveDataService;
  List<WorldCupFixture> _fixtures = worldCupFixtures;
  Map<int, FifaAMatchEntry> _officialMatchesByFixtureNumber =
      const <int, FifaAMatchEntry>{};
  Map<String, FifaRankingEntry> _rankingsByTeam =
      const <String, FifaRankingEntry>{};
  DateTime? _officialDataRefreshedAt;
  bool _officialDataRefreshing = false;
  bool _officialDataRefreshFailed = false;
  late final PageController _selectedDayPageController;
  final Map<int, double> _selectedDayMatchPageHeights = <int, double>{};
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _liveDataService = widget.liveDataService ?? WorldCupLiveDataService();
    _ownsLiveDataService = widget.liveDataService == null;
    _countries = worldCupCountries();
    _focusedDay = _initialCalendarDay();
    _selectedDay = _focusedDay;
    final initialSelectedDay = widget.initialSelectedDay;
    if (initialSelectedDay != null) {
      _focusedDay = _clampCalendarDay(initialSelectedDay);
      _selectedDay = _focusedDay;
    }
    _selectedDayPageController = PageController(
      initialPage: _dayPageIndexForDay(_selectedDay),
      viewportFraction: _selectedDayPageViewportFraction,
    );
    _loadCountryPreferences();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.refreshOfficialDataOnOpen) {
        unawaited(_refreshOfficialWorldCupData());
      } else {
        unawaited(_syncWorldCupReminders());
      }
    });
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _selectedDayPageController.dispose();
    if (_ownsLiveDataService) {
      _liveDataService.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.worldCupTitle),
        actions: [
          Tooltip(
            message: l10n.worldCupOverviewTitle,
            child: TextButton.icon(
              onPressed: _showTournamentInfo,
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              icon: const Icon(Icons.info_outline_rounded, size: 18),
              label: Text(l10n.worldCupInfoAction),
            ),
          ),
          Tooltip(
            message: l10n.worldCupSourceAction,
            child: TextButton.icon(
              onPressed: () => unawaited(
                launchUrl(_sourceUri, mode: LaunchMode.inAppBrowserView),
              ),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: Text(l10n.worldCupSourceShortAction),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _buildCountrySettings(context),
              const SizedBox(height: 12),
              _buildCalendar(context),
              const SizedBox(height: 12),
              _buildViewSwitcher(context),
              const SizedBox(height: 12),
              switch (_selectedView) {
                _WorldCupView.schedule => _buildScheduleView(context),
                _WorldCupView.standings => _buildStandingsPlan(context),
                _WorldCupView.tournament => _buildTournamentPlan(context),
              },
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showTournamentInfo() async {
    final l10n = AppLocalizations.of(context)!;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16,
            4,
            16,
            16 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).backButtonTooltip,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.worldCupOverviewTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildOverview(context),
              const SizedBox(height: 12),
              _buildGuideCard(
                context,
                icon: Icons.account_tree_rounded,
                title: l10n.worldCupGuideFormatTitle,
                bullets: l10n.worldCupGuideFormatBullets,
              ),
              const SizedBox(height: 12),
              _buildGuideCard(
                context,
                icon: Icons.sports_soccer_rounded,
                title: l10n.worldCupGuideMatchRulesTitle,
                bullets: l10n.worldCupGuideMatchRulesBullets,
              ),
              const SizedBox(height: 12),
              _buildGuideCard(
                context,
                icon: Icons.rule_rounded,
                title: l10n.worldCupGuideTiebreakTitle,
                bullets: l10n.worldCupGuideTiebreakBullets,
              ),
              const SizedBox(height: 12),
              _buildGuideCard(
                context,
                icon: Icons.sports_rounded,
                title: l10n.worldCupGuideRefereeTitle,
                bullets: l10n.worldCupGuideRefereeBullets,
              ),
              const SizedBox(height: 12),
              _buildGuideCard(
                context,
                icon: Icons.live_tv_rounded,
                title: l10n.worldCupGuideVarTitle,
                bullets: l10n.worldCupGuideVarBullets,
              ),
              const SizedBox(height: 12),
              _buildMilestones(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewSwitcher(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SegmentedButton<_WorldCupView>(
      showSelectedIcon: false,
      segments: [
        ButtonSegment<_WorldCupView>(
          value: _WorldCupView.schedule,
          icon: const Icon(Icons.event_note_rounded),
          label: Text(l10n.worldCupScheduleTab),
        ),
        ButtonSegment<_WorldCupView>(
          value: _WorldCupView.standings,
          icon: const Icon(Icons.leaderboard_rounded),
          label: Text(l10n.worldCupStandingsTab),
        ),
        ButtonSegment<_WorldCupView>(
          value: _WorldCupView.tournament,
          icon: const Icon(Icons.account_tree_rounded),
          label: Text(l10n.worldCupTournamentTab),
        ),
      ],
      selected: {_selectedView},
      onSelectionChanged: (selection) {
        setState(() => _selectedView = selection.single);
      },
    );
  }

  Widget _buildScheduleView(BuildContext context) {
    return _buildSelectedDayMatches(context);
  }

  Widget _buildStandingsPlan(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final groups = _groupTeams;
    final groupStandings = worldCupGroupStandings(fixtures: _fixtures);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WatchCartCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle(
                icon: Icons.leaderboard_rounded,
                title: l10n.worldCupStandingsTitle,
              ),
              const SizedBox(height: 10),
              Text(
                l10n.worldCupStandingsPlanBody,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              _InfoGrid(
                items: [
                  _InfoItem(
                    l10n.worldCupStandingsRuleLabel,
                    l10n.worldCupStandingsRuleValue,
                  ),
                  _InfoItem(
                    l10n.worldCupMatchesLabel,
                    l10n.worldCupMatchesCountValue(_fixtures.length),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        WatchCartCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle(
                icon: Icons.format_list_numbered_rounded,
                title: l10n.worldCupStandingsTableTitle,
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 620 ? 2 : 1;
                  const spacing = 8.0;
                  final width =
                      (constraints.maxWidth - spacing * (columns - 1)) /
                          columns;
                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [
                      for (final entry in groupStandings.entries)
                        SizedBox(
                          width: width,
                          child: _GroupStandingsCard(
                            group: entry.key,
                            standings: entry.value,
                            onTeamTap: _openTeamRoster,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        WatchCartCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle(
                icon: Icons.groups_rounded,
                title: l10n.worldCupGroupTeamsTitle,
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 620 ? 3 : 2;
                  const spacing = 8.0;
                  final width =
                      (constraints.maxWidth - spacing * (columns - 1)) /
                          columns;
                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [
                      for (final entry in groups.entries)
                        SizedBox(
                          width: width,
                          child: _GroupTeamsCard(
                            group: entry.key,
                            teams: entry.value,
                            onTeamTap: _openTeamRoster,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTournamentPlan(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    const stages = [
      WorldCupStage.roundOf32,
      WorldCupStage.roundOf16,
      WorldCupStage.quarterFinal,
      WorldCupStage.semiFinal,
      WorldCupStage.thirdPlace,
      WorldCupStage.finalMatch,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WatchCartCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle(
                icon: Icons.account_tree_rounded,
                title: l10n.worldCupTournamentTitle,
              ),
              const SizedBox(height: 10),
              Text(
                l10n.worldCupTournamentPlanBody,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final stage in stages) ...[
          _TournamentRoundSection(
            title: _stageLabelForStage(l10n, stage),
            subtitle: l10n.worldCupBracketRoundSummary(
              _dateRangeForFixtures(context, _fixturesForStage(stage)),
              _fixturesForStage(stage).length,
            ),
            fixtures: _fixturesForStage(stage),
            slotBuilder: (slot) => _bracketSlotData(l10n, slot),
          ),
          if (stage != stages.last) const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildOverview(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return WatchCartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.public_rounded,
            title: l10n.worldCupOverviewTitle,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.worldCupOverviewIntro,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _InfoGrid(
            items: [
              _InfoItem(l10n.worldCupHostsLabel, l10n.worldCupHostsValue),
              _InfoItem(l10n.worldCupDatesLabel, _dateRange(context)),
              _InfoItem(l10n.worldCupFormatLabel, l10n.worldCupFormatValue),
              _InfoItem(
                l10n.worldCupMatchesLabel,
                l10n.worldCupMatchesCountValue(_fixtures.length),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGuideCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String bullets,
  }) {
    final bulletLines = bullets
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
    return WatchCartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(icon: icon, title: title),
          const SizedBox(height: 12),
          for (var index = 0; index < bulletLines.length; index += 1) ...[
            _GuideBullet(text: bulletLines[index]),
            if (index != bulletLines.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildCountrySettings(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final interestCountries = _interestCountries.toList()..sort();
    final selectedSummary = _hasRegisteredCountrySettings
        ? (_selectedCountrySet.toList()..sort())
        : const <String>[];
    return WatchCartCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: _toggleCountrySettings,
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  _showCountrySettings ? 16 : 14,
                  14,
                  _showCountrySettings ? 14 : 14,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.flag_rounded,
                        color: theme.colorScheme.onPrimaryContainer,
                        size: 23,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.worldCupTeamSettingsTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            selectedSummary.isEmpty
                                ? l10n.worldCupInterestCountriesEmpty
                                : selectedSummary
                                    .map(
                                      (country) => _worldCupCountryLabelText(
                                        l10n,
                                        country,
                                      ),
                                    )
                                    .join(' · '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _showCountrySettings
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 620 ? 2 : 1;
                        const spacing = 10.0;
                        final panelWidth =
                            (constraints.maxWidth - spacing * (columns - 1)) /
                                columns;
                        return Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: [
                            SizedBox(
                              width: panelWidth,
                              child: _WorldCupCountrySettingPanel(
                                title: l10n.worldCupSupportCountryLabel,
                                child: DropdownButtonFormField<String>(
                                  initialValue: _supportCountryRegistered
                                      ? _supportCountry
                                      : '',
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                  ),
                                  items: [
                                    DropdownMenuItem<String>(
                                      value: '',
                                      child: Text(
                                        l10n.notSet,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    for (final country in _countries)
                                      DropdownMenuItem<String>(
                                        value: country,
                                        child: _CountryLabel(country: country),
                                      ),
                                  ],
                                  onChanged: (value) {
                                    if (value == null) return;
                                    unawaited(_setSupportCountry(value));
                                  },
                                ),
                              ),
                            ),
                            SizedBox(
                              width: panelWidth,
                              child: _WorldCupCountrySettingPanel(
                                title: l10n.worldCupInterestCountriesLabel,
                                trailing: TextButton.icon(
                                  onPressed: _editInterestCountries,
                                  icon: const Icon(Icons.edit_outlined),
                                  label: Text(
                                    l10n.worldCupEditInterestCountriesAction,
                                  ),
                                ),
                                child: interestCountries.isEmpty
                                    ? Text(
                                        l10n.worldCupInterestCountriesEmpty,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                      )
                                    : Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          for (final country
                                              in interestCountries)
                                            InputChip(
                                              label: _CountryLabel(
                                                country: country,
                                              ),
                                              onDeleted: () =>
                                                  _removeInterestCountry(
                                                country,
                                              ),
                                            ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: FilterChip(
                        avatar: const Icon(Icons.filter_alt_outlined, size: 18),
                        label: Text(l10n.worldCupSelectedCountriesOnly),
                        selected: _showSelectedCountriesOnly,
                        onSelected: _selectedCountrySet.isEmpty
                            ? null
                            : (selected) {
                                setState(
                                  () => _showSelectedCountriesOnly = selected,
                                );
                              },
                      ),
                    ),
                  ],
                ),
              ),
              crossFadeState: _showCountrySettings
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 180),
              firstCurve: Curves.easeOutCubic,
              secondCurve: Curves.easeOutCubic,
              sizeCurve: Curves.easeOutCubic,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final firstDay = worldCupFixtures.first.localDay;
    final lastDay = worldCupFixtures.last.localDay;
    return WatchCartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final actions = Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 4,
                runSpacing: 4,
                children: [
                  _SmallPill(label: _countdownLabel(context)),
                  if (_showsOfficialDataStatus)
                    _SmallPill(label: _officialDataStatusLabel(context)),
                  IconButton.outlined(
                    tooltip: l10n.worldCupOfficialRefreshAction,
                    visualDensity: VisualDensity.compact,
                    onPressed: _officialDataRefreshing
                        ? null
                        : () => unawaited(_refreshOfficialWorldCupData()),
                    icon: _officialDataRefreshing
                        ? SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.primary,
                            ),
                          )
                        : const Icon(Icons.sync_rounded, size: 18),
                  ),
                  IconButton.outlined(
                    tooltip: l10n.guideActionToday,
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      final today = _clampCalendarDay(DateTime.now());
                      setState(() {
                        _selectedDay = today;
                        _focusedDay = today;
                      });
                    },
                    icon: const Icon(Icons.today_outlined, size: 18),
                  ),
                ],
              );
              final title = _SectionTitle(
                icon: Icons.calendar_month_rounded,
                title: l10n.worldCupCalendarTitle,
              );
              if (constraints.maxWidth < 460) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    const SizedBox(height: 8),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: actions,
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: title),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: actions,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          TableCalendar<WorldCupFixture>(
            key: const ValueKey('world-cup-calendar-month'),
            firstDay: firstDay,
            lastDay: lastDay,
            focusedDay: _focusedDay,
            locale: localeName,
            sixWeekMonthsEnforced: false,
            rowHeight: 44,
            daysOfWeekHeight: 20,
            selectedDayPredicate: (day) =>
                normalizeWorldCupDay(day) == normalizeWorldCupDay(_selectedDay),
            calendarFormat: CalendarFormat.month,
            availableCalendarFormats: const {CalendarFormat.month: ''},
            availableGestures: AvailableGestures.horizontalSwipe,
            startingDayOfWeek: StartingDayOfWeek.sunday,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
              headerPadding: EdgeInsets.fromLTRB(0, 0, 0, 6),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              dowTextFormatter: (date, _) =>
                  DateFormat.E(localeName).format(date),
              weekdayStyle: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ) ??
                  const TextStyle(fontWeight: FontWeight.w800),
              weekendStyle: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ) ??
                  const TextStyle(fontWeight: FontWeight.w800),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              markersMaxCount: 0,
              defaultTextStyle: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ) ??
                  const TextStyle(fontWeight: FontWeight.w800),
              weekendTextStyle: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ) ??
                  const TextStyle(fontWeight: FontWeight.w800),
              selectedDecoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                shape: BoxShape.circle,
              ),
              todayTextStyle: TextStyle(
                color: theme.colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
              selectedTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
            calendarBuilders: CalendarBuilders<WorldCupFixture>(
              defaultBuilder: (context, day, focusedDay) =>
                  _buildCalendarDayCell(day),
              todayBuilder: (context, day, focusedDay) =>
                  _buildCalendarDayCell(day, isToday: true),
              selectedBuilder: (context, day, focusedDay) =>
                  _buildCalendarDayCell(day, isSelected: true),
              markerBuilder: (context, day, events) => const SizedBox.shrink(),
            ),
            onDaySelected: (selectedDay, focusedDay) {
              final nextDay = _clampCalendarDay(selectedDay);
              setState(() {
                _selectedDay = nextDay;
                _focusedDay = focusedDay;
              });
              _animateSelectedDayPageTo(nextDay);
            },
            onPageChanged: (focusedDay) {
              setState(() => _focusedDay = focusedDay);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDayMatches(BuildContext context) {
    final initialIndex = _dayPageIndexForDay(_selectedDay);
    return LayoutBuilder(
      builder: (context, constraints) {
        const pageEndPadding = 10.0;
        final pageWidth =
            constraints.maxWidth * _selectedDayPageViewportFraction;
        final measuredPageWidth = math.max(0.0, pageWidth - pageEndPadding);
        final measuredHeight = _selectedDayMatchPageHeights[initialIndex];
        final height = measuredHeight ??
            _selectedDayMatchesPagerEstimate(
              measuredPageWidth,
              initialIndex,
            );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Offstage(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: SizedBox(
                  width: measuredPageWidth,
                  child: _WorldCupSizeReporter(
                    onChange: (size) => _recordSelectedDayMatchPageHeight(
                      initialIndex,
                      size.height,
                    ),
                    child: _buildSelectedDayMatchPage(
                      context,
                      _dayForPageIndex(initialIndex),
                    ),
                  ),
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: SizedBox(
                key: const ValueKey<String>('world-cup-day-match-pager'),
                height: height,
                child: PageView.builder(
                  controller: _selectedDayPageController,
                  clipBehavior: Clip.none,
                  allowImplicitScrolling: true,
                  padEnds: false,
                  physics:
                      const PageScrollPhysics(parent: BouncingScrollPhysics()),
                  itemCount: _dayPageCount,
                  onPageChanged: (index) {
                    final nextDay = _dayForPageIndex(index);
                    if (normalizeWorldCupDay(nextDay) ==
                        normalizeWorldCupDay(_selectedDay)) {
                      return;
                    }
                    setState(() {
                      _selectedDay = nextDay;
                      _focusedDay = nextDay;
                    });
                  },
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsetsDirectional.only(
                        end: pageEndPadding,
                      ),
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: _buildSelectedDayMatchPage(
                          context,
                          _dayForPageIndex(index),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSelectedDayMatchPage(BuildContext context, DateTime day) {
    final l10n = AppLocalizations.of(context)!;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final formattedDay = DateFormat.yMMMd(localeName).format(day);
    final matches = _visibleFixturesForDay(day);
    final theme = Theme.of(context);
    return WatchCartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.event_note_rounded,
            title: l10n.worldCupDayMatchesTitle(formattedDay, matches.length),
          ),
          const SizedBox(height: 10),
          if (matches.isEmpty)
            Text(
              l10n.worldCupNoMatchesOnDay,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            for (final fixture in matches) ...[
              _FixtureRow(
                fixture: fixture,
                supportCountry: _supportCountry,
                interestCountries: _interestCountries,
                officialMatch:
                    _officialMatchesByFixtureNumber[fixture.matchNumber],
                rankingsByTeam: _rankingsByTeam,
                currentTime: widget.currentTime,
                onTeamTap: _openTeamRoster,
                onScoreTap: _openFixtureDetail,
              ),
              if (fixture != matches.last) const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }

  double _selectedDayMatchesPagerEstimate(
    double availableWidth,
    int pageIndex,
  ) {
    final fixtureRowHeight = availableWidth < 380
        ? 440.0
        : availableWidth < 430
            ? 400.0
            : 340.0;
    final matchCount =
        _visibleFixturesForDay(_dayForPageIndex(pageIndex)).length;
    final matchListHeight = matchCount == 0
        ? 48.0
        : matchCount * fixtureRowHeight + math.max(0, matchCount - 1) * 8.0;
    return 16 + 56 + matchListHeight + 16;
  }

  void _recordSelectedDayMatchPageHeight(int pageIndex, double height) {
    if (!mounted || height <= 0) return;
    final previousHeight = _selectedDayMatchPageHeights[pageIndex];
    if (previousHeight != null && (previousHeight - height).abs() < 0.5) {
      return;
    }
    setState(() {
      _selectedDayMatchPageHeights[pageIndex] = height;
    });
  }

  int get _dayPageCount {
    return _lastWorldCupDay.difference(_firstWorldCupDay).inDays + 1;
  }

  DateTime get _firstWorldCupDay => worldCupFixtures.first.localDay;

  DateTime get _lastWorldCupDay => worldCupFixtures.last.localDay;

  int _dayPageIndexForDay(DateTime day) {
    final clampedDay = _clampCalendarDay(day);
    return normalizeWorldCupDay(clampedDay)
        .difference(normalizeWorldCupDay(_firstWorldCupDay))
        .inDays
        .clamp(0, _dayPageCount - 1);
  }

  DateTime _dayForPageIndex(int index) {
    final clampedIndex = index.clamp(0, _dayPageCount - 1);
    return normalizeWorldCupDay(
      _firstWorldCupDay.add(Duration(days: clampedIndex)),
    );
  }

  void _animateSelectedDayPageTo(DateTime day) {
    if (!_selectedDayPageController.hasClients) return;
    unawaited(
      _selectedDayPageController.animateToPage(
        _dayPageIndexForDay(day),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  Widget _buildMilestones(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final milestones = <_InfoItem>[
      _InfoItem(l10n.worldCupMilestoneOpeningLabel, l10n.worldCupOpeningMatch),
      _InfoItem(l10n.worldCupMilestoneGroupLabel, l10n.worldCupGroupStage),
      _InfoItem(l10n.worldCupMilestoneKnockoutLabel, l10n.worldCupKnockouts),
      _InfoItem(l10n.worldCupMilestoneFinalLabel, l10n.worldCupFinalMatch),
    ];
    return WatchCartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.route_rounded,
            title: l10n.worldCupMilestonesTitle,
          ),
          const SizedBox(height: 12),
          for (final item in milestones) ...[
            _MilestoneRow(item: item),
            if (item != milestones.last) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Future<void> _editInterestCountries() async {
    final l10n = AppLocalizations.of(context)!;
    final working = Set<String>.from(_interestCountries);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, sheetSetState) {
            void updateWorking(VoidCallback update) {
              sheetSetState(update);
              unawaited(_setInterestCountries(working));
            }

            Widget buildActionRow(Key key) {
              return Wrap(
                key: key,
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton(
                    onPressed: () {
                      updateWorking(working.clear);
                    },
                    child: Text(l10n.worldCupClearInterestCountriesAction),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.cancel),
                  ),
                  FilledButton(
                    onPressed: () {
                      unawaited(_setInterestCountries(working));
                      Navigator.of(context).pop();
                    },
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(84, 44),
                    ),
                    child: Text(l10n.save),
                  ),
                ],
              );
            }

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.82,
              minChildSize: 0.2,
              maxChildSize: 0.92,
              shouldCloseOnMinExtent: true,
              builder: (context, scrollController) {
                return SafeArea(
                  child: CustomScrollView(
                    controller: scrollController,
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                l10n.worldCupInterestCountriesLabel,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 10),
                              buildActionRow(
                                const ValueKey(
                                  'world-cup-country-editor-top-actions',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final country = _countries[index];
                          return CheckboxListTile(
                            value: working.contains(country),
                            title: _CountryLabel(country: country),
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (checked) {
                              updateWorking(() {
                                if (checked ?? false) {
                                  working.add(country);
                                } else {
                                  working.remove(country);
                                }
                              });
                            },
                          );
                        }, childCount: _countries.length),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          child: buildActionRow(
                            const ValueKey(
                              'world-cup-country-editor-bottom-actions',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _openTeamRoster(String team) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _WorldCupTeamRosterSheet(
        team: team,
        ranking: _rankingsByTeam[team],
      ),
    );
  }

  Future<void> _openFixtureDetail(WorldCupFixture fixture) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _WorldCupFixtureDetailSheet(
        fixture: fixture,
        officialMatch: _officialMatchesByFixtureNumber[fixture.matchNumber],
        fetchOfficialDetail: _liveDataService.fetchMatchDetail,
        currentTime: widget.currentTime,
      ),
    );
  }

  Future<void> _setSupportCountry(String country) async {
    setState(() {
      _supportCountry = country;
      _supportCountryRegistered = country.trim().isNotEmpty;
      _showCountrySettings = !_hasRegisteredCountrySettings;
      if (_selectedCountrySet.isEmpty) {
        _showSelectedCountriesOnly = false;
      }
    });
    await widget.optionRepository?.setValue(_supportCountryKey, country);
    await _syncWorldCupReminders();
  }

  Future<void> _removeInterestCountry(String country) async {
    final next = Set<String>.from(_interestCountries)..remove(country);
    await _setInterestCountries(next);
  }

  Future<void> _setInterestCountries(Set<String> countries) async {
    if (!mounted) return;
    final normalized =
        countries.where((country) => _countries.contains(country)).toSet();
    setState(() {
      _interestCountries = normalized;
      _showCountrySettings = !_hasRegisteredCountrySettings;
      if (_selectedCountrySet.isEmpty) {
        _showSelectedCountriesOnly = false;
      }
    });
    await widget.optionRepository?.saveOptions(
      _interestCountriesKey,
      _interestCountries.toList()..sort(),
    );
    await _syncWorldCupReminders();
  }

  Future<void> _refreshOfficialWorldCupData() async {
    if (_officialDataRefreshing) return;
    setState(() {
      _officialDataRefreshing = true;
      _officialDataRefreshFailed = false;
    });
    try {
      final liveData = await _liveDataService.fetchLatest(
        now: widget.currentTime,
      );
      if (!mounted) return;
      setState(() {
        _fixtures = liveData.fixtures;
        _officialMatchesByFixtureNumber =
            liveData.officialMatchesByFixtureNumber;
        _rankingsByTeam = liveData.rankingsByTeam;
        _officialDataRefreshedAt = liveData.refreshedAt;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _officialDataRefreshFailed = true);
    } finally {
      if (mounted) {
        setState(() => _officialDataRefreshing = false);
        await _syncWorldCupReminders();
      }
    }
  }

  Future<void> _syncWorldCupReminders() async {
    final repository = widget.optionRepository;
    final settingsService = widget.settingsService;
    if (repository == null || settingsService == null || !mounted) return;
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;
    final locale = Localizations.localeOf(context).toString();
    final formatter = DateFormat.MMMd(locale).add_Hm();
    await LeagueFixtureReminderService(
      repository,
      settingsService,
    ).syncWorldCupReminders(
      fixtures: _fixtures,
      selectedCountries: _selectedCountrySet,
      androidChannelName: l10n.worldCupFixtureNotificationChannelName,
      androidChannelDescription:
          l10n.worldCupFixtureNotificationChannelDescription,
      bodyBuilder: (fixture, teamName, opponentName) =>
          l10n.worldCupFixtureNotificationBody(
        teamName,
        opponentName,
        formatter.format(fixture.kickoffLocal),
      ),
    );
  }

  void _loadCountryPreferences() {
    final repository = widget.optionRepository;
    if (repository == null) return;
    final storedSupport = repository.getValue<String>(_supportCountryKey);
    final storedInterest = repository.getOptions(
      _interestCountriesKey,
      const <String>[],
    );
    if (storedSupport != null && _countries.contains(storedSupport)) {
      _supportCountry = storedSupport;
      _supportCountryRegistered = true;
    }
    _interestCountries =
        storedInterest.where((country) => _countries.contains(country)).toSet();
    _showCountrySettings = !_hasRegisteredCountrySettings;
  }

  List<WorldCupFixture> _fixturesForDay(DateTime day) {
    return worldCupFixturesForDay(day, fixtures: _fixtures);
  }

  List<WorldCupFixture> _fixturesForStage(WorldCupStage stage) {
    return _fixtures
        .where((fixture) => fixture.stage == stage)
        .toList(growable: false);
  }

  List<WorldCupFixture> _visibleFixturesForDay(DateTime day) {
    final fixtures = _fixturesForDay(day);
    if (!_showSelectedCountriesOnly) return fixtures;
    return worldCupFixturesForDayAndCountries(
      day,
      _selectedCountrySet,
      fixtures: _fixtures,
    );
  }

  Widget _buildCalendarDayCell(
    DateTime day, {
    bool isSelected = false,
    bool isToday = false,
  }) {
    final fixtures = _visibleFixturesForDay(day);
    final selectedCountryFixtures = _selectedCountryFixturesForDay(day);
    final showsSelectedCountryFlags = selectedCountryFixtures.isNotEmpty;
    final flags = showsSelectedCountryFlags
        ? _selectedCountryFlagsForFixtures(selectedCountryFixtures)
        : _fixtureFlagsForFixtures(fixtures);
    return _WorldCupCalendarDayCell(
      day: normalizeWorldCupDay(day),
      dayNumber: day.day,
      fixtureCount: fixtures.length,
      badgeCount: showsSelectedCountryFlags
          ? selectedCountryFixtures.length
          : fixtures.length,
      flags: flags.take(2).toList(growable: false),
      isSelected: isSelected ||
          normalizeWorldCupDay(day) == normalizeWorldCupDay(_selectedDay),
      isToday: isToday ||
          normalizeWorldCupDay(day) == normalizeWorldCupDay(DateTime.now()),
    );
  }

  List<WorldCupFixture> _selectedCountryFixturesForDay(DateTime day) {
    final selectedCountries = _selectedCountrySet.toList()..sort();
    if (selectedCountries.isEmpty) return const <WorldCupFixture>[];
    final fixtures = _fixturesForDay(day);
    if (fixtures.isEmpty) return const <WorldCupFixture>[];
    return fixtures
        .where((fixture) => selectedCountries.any(fixture.involvesCountry))
        .toList(growable: false);
  }

  List<String> _selectedCountryFlagsForFixtures(
    List<WorldCupFixture> fixtures,
  ) {
    if (fixtures.isEmpty) return const <String>[];
    final selectedCountries = _selectedCountrySet.toList()..sort();
    final flags = <String>[];
    for (final country in selectedCountries) {
      if (!fixtures.any((fixture) => fixture.involvesCountry(country))) {
        continue;
      }
      final flag = worldCupCountryFlag(country);
      if (flag.isNotEmpty) flags.add(flag);
    }
    return flags;
  }

  List<String> _fixtureFlagsForFixtures(List<WorldCupFixture> fixtures) {
    if (fixtures.isEmpty) return const <String>[];
    final countries = <String>[];
    for (final fixture in fixtures) {
      for (final country in [fixture.homeTeam, fixture.awayTeam]) {
        if (!countries.contains(country)) countries.add(country);
      }
    }
    return countries
        .map(worldCupCountryFlag)
        .where((flag) => flag.isNotEmpty)
        .toList(growable: false);
  }

  Set<String> get _selectedCountrySet {
    return <String>{
      if (_supportCountryRegistered) _supportCountry,
      ..._interestCountries,
    }..removeWhere((country) => country.trim().isEmpty);
  }

  bool get _hasRegisteredCountrySettings {
    return _supportCountryRegistered || _interestCountries.isNotEmpty;
  }

  void _toggleCountrySettings() {
    setState(() => _showCountrySettings = !_showCountrySettings);
  }

  Map<String, List<String>> get _groupTeams {
    final groups = <String, Set<String>>{};
    for (final fixture in _fixtures) {
      final group = fixture.group;
      if (!fixture.isGroupStage || group == null) continue;
      groups.putIfAbsent(group, () => <String>{})
        ..add(fixture.homeTeam)
        ..add(fixture.awayTeam);
    }
    final entries = groups.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return {
      for (final entry in entries)
        entry.key: (entry.value.toList()..sort()).toList(growable: false),
    };
  }

  DateTime _initialCalendarDay() {
    final today = normalizeWorldCupDay(DateTime.now());
    return _clampCalendarDay(today);
  }

  DateTime _clampCalendarDay(DateTime value) {
    final day = normalizeWorldCupDay(value);
    final firstDay = worldCupFixtures.first.localDay;
    final lastDay = worldCupFixtures.last.localDay;
    if (day.isBefore(firstDay)) return firstDay;
    if (day.isAfter(lastDay)) return lastDay;
    return day;
  }

  String _countdownLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final today = normalizeWorldCupDay(DateTime.now());
    if (today.isAfter(_finalDate)) {
      return l10n.worldCupCountdownComplete;
    }
    if (today.isAtSameMomentAs(_openingDate)) {
      return l10n.worldCupCountdownToday;
    }
    if (today.isAfter(_openingDate)) {
      return l10n.worldCupCountdownStarted;
    }
    return l10n.worldCupCountdownDays(_openingDate.difference(today).inDays);
  }

  bool get _showsOfficialDataStatus =>
      _officialDataRefreshing ||
      _officialDataRefreshFailed ||
      _officialDataRefreshedAt != null;

  String _officialDataStatusLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_officialDataRefreshing) {
      return l10n.worldCupOfficialRefreshing;
    }
    if (_officialDataRefreshFailed) {
      return l10n.worldCupOfficialUnavailable;
    }
    final refreshedAt = _officialDataRefreshedAt;
    if (refreshedAt != null) {
      return l10n.worldCupOfficialUpdatedAt(
        _formatOfficialRefreshTime(context, refreshedAt),
      );
    }
    return l10n.worldCupOfficialUnavailable;
  }

  String _formatOfficialRefreshTime(
    BuildContext context,
    DateTime refreshedAt,
  ) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.Hm(locale).format(refreshedAt.toLocal());
  }

  String _dateRange(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final formatter = DateFormat.yMMMd(locale);
    return AppLocalizations.of(context)!.worldCupDateRange(
      formatter.format(_openingDate),
      formatter.format(_finalDate),
    );
  }

  String _dateRangeForFixtures(
    BuildContext context,
    List<WorldCupFixture> fixtures,
  ) {
    if (fixtures.isEmpty) return '';
    final locale = Localizations.localeOf(context).toString();
    final formatter = DateFormat.MMMd(locale);
    final sorted = fixtures.toList()
      ..sort((a, b) => a.kickoffLocal.compareTo(b.kickoffLocal));
    final start = formatter.format(sorted.first.kickoffLocal);
    final end = formatter.format(sorted.last.kickoffLocal);
    if (start == end) return start;
    return AppLocalizations.of(context)!.worldCupDateRange(start, end);
  }

  String _stageLabelForStage(AppLocalizations l10n, WorldCupStage stage) {
    return switch (stage) {
      WorldCupStage.group => l10n.worldCupMilestoneGroupLabel,
      WorldCupStage.roundOf32 => l10n.worldCupRoundOf32Label,
      WorldCupStage.roundOf16 => l10n.worldCupRoundOf16Label,
      WorldCupStage.quarterFinal => l10n.worldCupQuarterFinalLabel,
      WorldCupStage.semiFinal => l10n.worldCupSemiFinalLabel,
      WorldCupStage.thirdPlace => l10n.worldCupThirdPlaceLabel,
      WorldCupStage.finalMatch => l10n.worldCupFinalLabel,
    };
  }

  _BracketSlotData _bracketSlotData(AppLocalizations l10n, String slot) {
    final detail = _bracketSlotDetail(l10n, slot);
    return _BracketSlotData(
      label: _bracketSlotLabel(l10n, slot),
      detail: detail,
    );
  }

  String _bracketSlotLabel(AppLocalizations l10n, String slot) {
    final groupRankMatch = RegExp(r'^([12])([A-L])$').firstMatch(slot);
    if (groupRankMatch != null) {
      final rank = groupRankMatch.group(1)!;
      final group = groupRankMatch.group(2)!;
      return rank == '1'
          ? l10n.worldCupBracketFirstSeed(group)
          : l10n.worldCupBracketSecondSeed(group);
    }

    final thirdPlaceMatch = RegExp(r'^3([A-L](?:/[A-L])*)$').firstMatch(slot);
    if (thirdPlaceMatch != null) {
      return l10n.worldCupBracketThirdSeed(thirdPlaceMatch.group(1)!);
    }

    final matchReference = RegExp(r'^([WL])([0-9]+)$').firstMatch(slot);
    if (matchReference != null) {
      final matchNumber = int.parse(matchReference.group(2)!);
      return matchReference.group(1) == 'W'
          ? l10n.worldCupBracketWinnerSlot(matchNumber)
          : l10n.worldCupBracketLoserSlot(matchNumber);
    }

    return _worldCupCountryName(l10n, slot);
  }

  String? _bracketSlotDetail(AppLocalizations l10n, String slot) {
    final matchReference = RegExp(r'^[WL]([0-9]+)$').firstMatch(slot);
    if (matchReference == null) return null;
    final matchNumber = int.parse(matchReference.group(1)!);
    final fixture = _fixtureByMatchNumber(matchNumber);
    if (fixture == null) return null;
    return l10n.worldCupBracketSourceMatch(
      fixture.matchNumber,
      _bracketSlotLabel(l10n, fixture.homeTeam),
      _bracketSlotLabel(l10n, fixture.awayTeam),
    );
  }

  WorldCupFixture? _fixtureByMatchNumber(int matchNumber) {
    for (final fixture in _fixtures) {
      if (fixture.matchNumber == matchNumber) return fixture;
    }
    return null;
  }
}

enum _WorldCupView { schedule, standings, tournament }

enum _WorldCupFixtureRuntimeStatus { scheduled, live, awaitingUpdate, finished }

_WorldCupFixtureRuntimeStatus _runtimeStatusForFixture(
  WorldCupFixture fixture, {
  FifaAMatchEntry? officialMatch,
  DateTime? now,
}) {
  if (officialMatch?.status == FifaAMatchStatus.live) {
    return _WorldCupFixtureRuntimeStatus.live;
  }
  if (officialMatch?.status == FifaAMatchStatus.finished) {
    return _WorldCupFixtureRuntimeStatus.finished;
  }
  if (fixture.hasScore) return _WorldCupFixtureRuntimeStatus.finished;
  final current = (now ?? DateTime.now()).toUtc();
  final kickoff = fixture.kickoffUtc.toUtc();
  final estimatedFinalWhistle = kickoff.add(
    const Duration(hours: 2, minutes: 20),
  );
  if (!current.isBefore(kickoff) && current.isBefore(estimatedFinalWhistle)) {
    return _WorldCupFixtureRuntimeStatus.live;
  }
  if (!current.isBefore(estimatedFinalWhistle)) {
    return _WorldCupFixtureRuntimeStatus.awaitingUpdate;
  }
  return _WorldCupFixtureRuntimeStatus.scheduled;
}

({int? homeScore, int? awayScore}) _displayScoreForFixture(
  WorldCupFixture fixture,
  FifaAMatchEntry? officialMatch,
) {
  if (officialMatch != null &&
      officialMatch.hasScore &&
      (officialMatch.status == FifaAMatchStatus.live ||
          officialMatch.status == FifaAMatchStatus.finished)) {
    final sameDirection = _worldCupTeamKey(fixture.homeTeam) ==
            _worldCupTeamKey(officialMatch.homeTeamName) &&
        _worldCupTeamKey(fixture.awayTeam) ==
            _worldCupTeamKey(officialMatch.awayTeamName);
    return sameDirection
        ? (
            homeScore: officialMatch.homeScore,
            awayScore: officialMatch.awayScore,
          )
        : (
            homeScore: officialMatch.awayScore,
            awayScore: officialMatch.homeScore,
          );
  }
  return (homeScore: fixture.homeScore, awayScore: fixture.awayScore);
}

String _runtimeStatusLabel(
  AppLocalizations l10n,
  _WorldCupFixtureRuntimeStatus status,
) {
  return switch (status) {
    _WorldCupFixtureRuntimeStatus.finished => l10n.worldCupMatchResultFinal,
    _WorldCupFixtureRuntimeStatus.live => l10n.worldCupMatchLive,
    _WorldCupFixtureRuntimeStatus.awaitingUpdate =>
      l10n.worldCupMatchAwaitingUpdate,
    _WorldCupFixtureRuntimeStatus.scheduled => l10n.worldCupMatchScheduled,
  };
}

String? _visibleRuntimeStatusLabel(
  AppLocalizations l10n,
  _WorldCupFixtureRuntimeStatus status,
) {
  if (status == _WorldCupFixtureRuntimeStatus.scheduled) {
    return null;
  }
  return _runtimeStatusLabel(l10n, status);
}

String _fixtureStageLabel(AppLocalizations l10n, WorldCupFixture fixture) {
  return switch (fixture.stage) {
    WorldCupStage.group => l10n.worldCupGroupStageLabel(fixture.group ?? ''),
    WorldCupStage.roundOf32 => l10n.worldCupRoundOf32Label,
    WorldCupStage.roundOf16 => l10n.worldCupRoundOf16Label,
    WorldCupStage.quarterFinal => l10n.worldCupQuarterFinalLabel,
    WorldCupStage.semiFinal => l10n.worldCupSemiFinalLabel,
    WorldCupStage.thirdPlace => l10n.worldCupThirdPlaceLabel,
    WorldCupStage.finalMatch => l10n.worldCupFinalLabel,
  };
}

class _FixtureRow extends StatelessWidget {
  final WorldCupFixture fixture;
  final String supportCountry;
  final Set<String> interestCountries;
  final FifaAMatchEntry? officialMatch;
  final Map<String, FifaRankingEntry> rankingsByTeam;
  final DateTime? currentTime;
  final ValueChanged<String> onTeamTap;
  final ValueChanged<WorldCupFixture> onScoreTap;

  const _FixtureRow({
    required this.fixture,
    required this.supportCountry,
    required this.interestCountries,
    required this.officialMatch,
    required this.rankingsByTeam,
    this.currentTime,
    required this.onTeamTap,
    required this.onScoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final supportMatch = fixture.involvesCountry(supportCountry);
    final interestMatch = interestCountries.any(fixture.involvesCountry);
    final selected = supportMatch || interestMatch;
    final borderColor = supportMatch
        ? theme.colorScheme.primary
        : interestMatch
            ? theme.colorScheme.tertiary
            : theme.colorScheme.outlineVariant;
    final backgroundColor = selected
        ? borderColor.withValues(alpha: 0.08)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.42);
    final kickoffText = formatKickoffWithKoreaTime(context, fixture.kickoffUtc);
    final runtimeStatus = _runtimeStatusForFixture(
      fixture,
      officialMatch: officialMatch,
      now: currentTime,
    );
    final statusLabel = _visibleRuntimeStatusLabel(l10n, runtimeStatus);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor.withValues(alpha: 0.58)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _SmallPill(label: l10n.worldCupMatchNumber(fixture.matchNumber)),
              _SmallPill(label: _stageLabel(l10n, fixture)),
              if (supportMatch || interestMatch) ...[
                _SmallPill(
                  label: supportMatch
                      ? l10n.worldCupSupportBadge
                      : l10n.worldCupInterestBadge,
                ),
              ],
              if (statusLabel != null) _SmallPill(label: statusLabel),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, _) {
              final homeBlock = _FixtureTeamBlock(
                team: fixture.homeTeam,
                status: runtimeStatus,
                ranking: rankingsByTeam[fixture.homeTeam],
                onTap: () => onTeamTap(fixture.homeTeam),
              );
              final scoreBoard = _FixtureScoreBoard(
                fixture: fixture,
                status: runtimeStatus,
                officialMatch: officialMatch,
                onTap: () => onScoreTap(fixture),
              );
              final awayBlock = _FixtureTeamBlock(
                team: fixture.awayTeam,
                status: runtimeStatus,
                ranking: rankingsByTeam[fixture.awayTeam],
                alignEnd: true,
                onTap: () => onTeamTap(fixture.awayTeam),
              );
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: homeBlock),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: scoreBoard,
                  ),
                  Expanded(child: awayBlock),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Text(
            kickoffText,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _worldCupVenueLabel(l10n, fixture.venue),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (runtimeStatus ==
              _WorldCupFixtureRuntimeStatus.awaitingUpdate) ...[
            const SizedBox(height: 6),
            Text(
              l10n.worldCupMatchAwaitingUpdateReason,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _stageLabel(AppLocalizations l10n, WorldCupFixture fixture) {
    return switch (fixture.stage) {
      WorldCupStage.group => l10n.worldCupGroupStageLabel(fixture.group ?? ''),
      WorldCupStage.roundOf32 => l10n.worldCupRoundOf32Label,
      WorldCupStage.roundOf16 => l10n.worldCupRoundOf16Label,
      WorldCupStage.quarterFinal => l10n.worldCupQuarterFinalLabel,
      WorldCupStage.semiFinal => l10n.worldCupSemiFinalLabel,
      WorldCupStage.thirdPlace => l10n.worldCupThirdPlaceLabel,
      WorldCupStage.finalMatch => l10n.worldCupFinalLabel,
    };
  }
}

class _FixtureTeamBlock extends StatelessWidget {
  final String team;
  final _WorldCupFixtureRuntimeStatus status;
  final FifaRankingEntry? ranking;
  final bool alignEnd;
  final VoidCallback onTap;

  const _FixtureTeamBlock({
    required this.team,
    required this.status,
    required this.ranking,
    required this.onTap,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final teamStatusSummary = _teamStatusSummary(l10n);
    final metaPills = <Widget>[
      if (ranking != null)
        _SmallPill(label: _fifaRankingCompactLabel(l10n, ranking!)),
    ];
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: _TappableCountryLabel(
            country: team,
            textAlign: alignEnd ? TextAlign.right : TextAlign.left,
            onTap: onTap,
          ),
        ),
        if (teamStatusSummary.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            teamStatusSummary,
            textAlign: alignEnd ? TextAlign.right : TextAlign.left,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        if (metaPills.isNotEmpty) ...[
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              alignment: alignEnd ? WrapAlignment.end : WrapAlignment.start,
              children: metaPills,
            ),
          ),
        ],
      ],
    );
  }

  String _teamStatusSummary(AppLocalizations l10n) {
    return switch (status) {
      _WorldCupFixtureRuntimeStatus.live => l10n.worldCupMatchLive,
      _ => '',
    };
  }
}

class _FixtureScoreBoard extends StatelessWidget {
  final WorldCupFixture fixture;
  final _WorldCupFixtureRuntimeStatus status;
  final FifaAMatchEntry? officialMatch;
  final VoidCallback onTap;

  const _FixtureScoreBoard({
    required this.fixture,
    required this.status,
    required this.officialMatch,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final displayScore = _displayScoreForFixture(fixture, officialMatch);
    final hasDisplayScore =
        displayScore.homeScore != null && displayScore.awayScore != null;
    final scoreText = hasDisplayScore
        ? l10n.worldCupScoreLine(
            displayScore.homeScore!,
            displayScore.awayScore!,
          )
        : status == _WorldCupFixtureRuntimeStatus.live
            ? l10n.worldCupMatchLive
            : l10n.worldCupScorePending;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 70),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Text(
              scoreText,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: status == _WorldCupFixtureRuntimeStatus.live
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WorldCupFixtureDetailSheet extends StatefulWidget {
  final WorldCupFixture fixture;
  final FifaAMatchEntry? officialMatch;
  final Future<FifaAMatchDetail?> Function(
    FifaAMatchEntry match, {
    String language,
  })? fetchOfficialDetail;
  final DateTime? currentTime;

  const _WorldCupFixtureDetailSheet({
    required this.fixture,
    required this.officialMatch,
    required this.fetchOfficialDetail,
    this.currentTime,
  });

  @override
  State<_WorldCupFixtureDetailSheet> createState() =>
      _WorldCupFixtureDetailSheetState();
}

class _WorldCupFixtureDetailSheetState
    extends State<_WorldCupFixtureDetailSheet> {
  Future<FifaAMatchDetail?>? _officialDetailFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_officialDetailFuture != null) return;
    final officialMatch = widget.officialMatch;
    final fetchOfficialDetail = widget.fetchOfficialDetail;
    _officialDetailFuture = officialMatch == null || fetchOfficialDetail == null
        ? null
        : fetchOfficialDetail(
            officialMatch,
            language: _fifaApiLanguageForLocale(
              Localizations.localeOf(context),
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final fixture = widget.fixture;
    final status = _runtimeStatusForFixture(
      fixture,
      officialMatch: widget.officialMatch,
      now: widget.currentTime,
    );
    final displayScore = _displayScoreForFixture(fixture, widget.officialMatch);
    final hasDisplayScore =
        displayScore.homeScore != null && displayScore.awayScore != null;
    final scoreText = hasDisplayScore
        ? l10n.worldCupScoreLine(
            displayScore.homeScore!,
            displayScore.awayScore!,
          )
        : status == _WorldCupFixtureRuntimeStatus.live
            ? l10n.worldCupMatchLive
            : l10n.worldCupScorePending;
    final statusLabel = _visibleRuntimeStatusLabel(l10n, status);
    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.82,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
          children: [
            _SectionTitle(
              icon: Icons.scoreboard_rounded,
              title: l10n.worldCupMatchDetailTitle,
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.52,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: LayoutBuilder(
                builder: (context, _) {
                  final scoreColumn = Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        scoreText,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: status == _WorldCupFixtureRuntimeStatus.live
                              ? theme.colorScheme.error
                              : theme.colorScheme.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (statusLabel != null) ...[
                        const SizedBox(height: 4),
                        _SmallPill(label: statusLabel),
                      ],
                    ],
                  );
                  return Row(
                    children: [
                      Expanded(child: _CountryLabel(country: fixture.homeTeam)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: scoreColumn,
                      ),
                      Expanded(
                        child: _CountryLabel(
                          country: fixture.awayTeam,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            _SectionTitle(
              icon: Icons.fact_check_rounded,
              title: l10n.worldCupMatchRecordsTitle,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SmallPill(
                  label: l10n.worldCupMatchNumber(fixture.matchNumber),
                ),
                _SmallPill(label: _fixtureStageLabel(l10n, fixture)),
                _SmallPill(
                  label: formatKickoffWithKoreaTime(
                    context,
                    fixture.kickoffUtc,
                  ),
                ),
                _SmallPill(label: _worldCupVenueLabel(l10n, fixture.venue)),
              ],
            ),
            const SizedBox(height: 10),
            _buildOfficialRecords(context),
            if (status == _WorldCupFixtureRuntimeStatus.awaitingUpdate) ...[
              const SizedBox(height: 10),
              _WorldCupOfficialRecordMessage(
                message: l10n.worldCupMatchAwaitingUpdateReason,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOfficialRecords(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final detailFuture = _officialDetailFuture;
    if (detailFuture == null) {
      return _WorldCupOfficialRecordMessage(
        message: l10n.worldCupMatchRecordUnavailable,
      );
    }
    return FutureBuilder<FifaAMatchDetail?>(
      future: detailFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Row(
            children: [
              SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.worldCupMatchDetailLoading,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          );
        }
        final detail = snapshot.data;
        if (detail == null || !detail.hasOfficialRecords) {
          return _WorldCupOfficialRecordMessage(
            message: l10n.worldCupMatchRecordUnavailable,
          );
        }
        return _WorldCupOfficialMatchRecords(
          fixture: widget.fixture,
          detail: detail,
        );
      },
    );
  }
}

class _WorldCupOfficialRecordMessage extends StatelessWidget {
  final String message;

  const _WorldCupOfficialRecordMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      message,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _WorldCupOfficialMatchRecords extends StatelessWidget {
  final WorldCupFixture fixture;
  final FifaAMatchDetail detail;

  const _WorldCupOfficialMatchRecords({
    required this.fixture,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final stats = _matchStats(l10n, Localizations.localeOf(context).toString());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (stats.isNotEmpty) ...[
          _InfoGrid(items: stats),
          const SizedBox(height: 12),
        ],
        if (detail.hasScorers) ...[
          Text(
            l10n.worldCupMatchScorersTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final scorer in detail.homeScorers)
                _SmallPill(label: _scorerLabel(l10n, fixture.homeTeam, scorer)),
              for (final scorer in detail.awayScorers)
                _SmallPill(label: _scorerLabel(l10n, fixture.awayTeam, scorer)),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (detail.hasPlayers) ...[
          Text(
            l10n.worldCupMatchLineupsTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 620 ? 2 : 1;
              const spacing = 10.0;
              final width =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  SizedBox(
                    width: width,
                    child: _WorldCupOfficialLineupCard(
                      team: fixture.homeTeam,
                      tactics: detail.homeTactics,
                      players: detail.homePlayers,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _WorldCupOfficialLineupCard(
                      team: fixture.awayTeam,
                      tactics: detail.awayTactics,
                      players: detail.awayPlayers,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
        ],
        Text(
          l10n.worldCupOfficialSourceNote,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  List<_InfoItem> _matchStats(AppLocalizations l10n, String locale) {
    final items = <_InfoItem>[];
    if (detail.hasPossession) {
      items.add(
        _InfoItem(
          l10n.worldCupMatchPossessionLabel,
          l10n.worldCupMatchPossessionValue(
            detail.homePossession!.round(),
            detail.awayPossession!.round(),
          ),
        ),
      );
    }
    if (detail.attendance != null) {
      items.add(
        _InfoItem(
          l10n.worldCupMatchAttendanceLabel,
          NumberFormat.decimalPattern(locale).format(detail.attendance),
        ),
      );
    }
    if (detail.hasTactics) {
      items.add(
        _InfoItem(
          l10n.worldCupMatchTacticsLabel,
          '${detail.homeTactics.isEmpty ? l10n.notSet : detail.homeTactics} · '
          '${detail.awayTactics.isEmpty ? l10n.notSet : detail.awayTactics}',
        ),
      );
    }
    return items;
  }

  String _scorerLabel(
    AppLocalizations l10n,
    String team,
    FifaMatchScorer scorer,
  ) {
    final minute = scorer.minute.trim();
    final prefix = _worldCupCountryName(l10n, team);
    final playerName = worldCupRosterDisplayNameForPlayer(
      team,
      scorer.playerName,
      l10n.localeName,
    );
    return minute.isEmpty
        ? '$prefix · $playerName'
        : '$prefix · $playerName $minute';
  }
}

class _WorldCupOfficialLineupCard extends StatelessWidget {
  final String team;
  final String tactics;
  final List<FifaMatchPlayer> players;

  const _WorldCupOfficialLineupCard({
    required this.team,
    required this.tactics,
    required this.players,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final starters =
        players.where((player) => player.isStarting).toList(growable: false);
    final bench =
        players.where((player) => !player.isStarting).toList(growable: false);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _CountryLabel(country: team)),
              if (tactics.isNotEmpty) ...[
                const SizedBox(width: 8),
                _SmallPill(label: tactics),
              ],
            ],
          ),
          const SizedBox(height: 10),
          _WorldCupPlayerGroup(
            title: l10n.worldCupStartingPlayersLabel,
            team: team,
            players: starters,
          ),
          if (bench.isNotEmpty) ...[
            const SizedBox(height: 10),
            _WorldCupPlayerGroup(
              title: l10n.worldCupBenchPlayersLabel,
              team: team,
              players: bench,
            ),
          ],
        ],
      ),
    );
  }
}

class _WorldCupPlayerGroup extends StatelessWidget {
  final String title;
  final String team;
  final List<FifaMatchPlayer> players;

  const _WorldCupPlayerGroup({
    required this.title,
    required this.team,
    required this.players,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final player in players)
              _FifaMatchPlayerPill(team: team, player: player),
          ],
        ),
      ],
    );
  }
}

class _FifaMatchPlayerPill extends StatelessWidget {
  final String team;
  final FifaMatchPlayer player;

  const _FifaMatchPlayerPill({required this.team, required this.player});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final positionLabel = _fifaMatchPlayerPositionLabel(l10n, player.position);
    final shirt = player.shirtNumber == null ? '' : '${player.shirtNumber} · ';
    final captain =
        player.isCaptain ? ' ${l10n.worldCupCaptainAbbreviation}' : '';
    final sourceName =
        player.fullName.trim().isNotEmpty ? player.fullName : player.playerName;
    final playerName = worldCupRosterDisplayNameForPlayer(
      team,
      sourceName,
      l10n.localeName,
    );
    final club = _worldCupFifaMatchPlayerClub(team, player);
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(10, 6, 10, 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 190),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$shirt$playerName$captain · $positionLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (club.isNotEmpty)
                  Text(
                    club,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
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

String _worldCupFifaMatchPlayerClub(String team, FifaMatchPlayer player) {
  for (final candidate in <String>[
    player.fullName,
    player.playerName,
  ]) {
    final club = worldCupRosterClubForPlayer(
      team,
      candidate,
      playerId: player.playerId,
    );
    if (club.isNotEmpty) return club;
  }
  return '';
}

String _worldCupCountryLabelText(AppLocalizations l10n, String country) {
  final flag = worldCupCountryFlag(country);
  final label = _worldCupCountryName(l10n, country);
  return flag.isEmpty ? label : '$flag $label';
}

String _fifaRankingCompactLabel(
  AppLocalizations l10n,
  FifaRankingEntry ranking,
) {
  return l10n.worldCupFifaRankingCompactLabel(ranking.rank);
}

String _fifaApiLanguageForLocale(Locale locale) {
  return switch (locale.languageCode.toLowerCase()) {
    'ko' => 'ko',
    'ja' => 'ja',
    _ => 'en',
  };
}

String _worldCupTeamKey(String value) {
  final normalized = value
      .trim()
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('à', 'a')
      .replaceAll('â', 'a')
      .replaceAll('ã', 'a')
      .replaceAll('å', 'a')
      .replaceAll('é', 'e')
      .replaceAll('è', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ï', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ò', 'o')
      .replaceAll('ô', 'o')
      .replaceAll('ö', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ù', 'u')
      .replaceAll('ü', 'u')
      .replaceAll('ı', 'i')
      .replaceAll('ç', 'c')
      .replaceAll('’', "'")
      .replaceAll(RegExp(r'\s+'), ' ');
  return switch (normalized) {
    "cote d'ivoire" => 'ivory coast',
    'cote divoire' => 'ivory coast',
    'cabo verde' => 'cape verde',
    'cape verde' => 'cape verde',
    'czech republic' => 'czechia',
    'czechia' => 'czechia',
    'dr congo' => 'congo dr',
    'congo dr' => 'congo dr',
    'democratic republic of congo' => 'congo dr',
    'ir iran' => 'iran',
    'iran' => 'iran',
    'turkey' => 'turkiye',
    'turkiye' => 'turkiye',
    'united states' => 'usa',
    'united states of america' => 'usa',
    'usa' => 'usa',
    _ => normalized,
  };
}

String _worldCupCountryName(AppLocalizations l10n, String country) {
  return switch (country) {
    'Algeria' => l10n.worldCupCountryAlgeria,
    'Argentina' => l10n.worldCupCountryArgentina,
    'Australia' => l10n.worldCupCountryAustralia,
    'Austria' => l10n.worldCupCountryAustria,
    'Belgium' => l10n.worldCupCountryBelgium,
    'Bosnia and Herzegovina' => l10n.worldCupCountryBosniaAndHerzegovina,
    'Brazil' => l10n.worldCupCountryBrazil,
    'Canada' => l10n.worldCupCountryCanada,
    'Cape Verde' => l10n.worldCupCountryCapeVerde,
    'Colombia' => l10n.worldCupCountryColombia,
    'Congo DR' => l10n.worldCupCountryCongoDr,
    'Croatia' => l10n.worldCupCountryCroatia,
    'Curacao' => l10n.worldCupCountryCuracao,
    'Czechia' => l10n.worldCupCountryCzechia,
    'Ecuador' => l10n.worldCupCountryEcuador,
    'Egypt' => l10n.worldCupCountryEgypt,
    'England' => l10n.worldCupCountryEngland,
    'France' => l10n.worldCupCountryFrance,
    'Germany' => l10n.worldCupCountryGermany,
    'Ghana' => l10n.worldCupCountryGhana,
    'Haiti' => l10n.worldCupCountryHaiti,
    'Iran' => l10n.worldCupCountryIran,
    'Iraq' => l10n.worldCupCountryIraq,
    'Ivory Coast' => l10n.worldCupCountryIvoryCoast,
    'Japan' => l10n.worldCupCountryJapan,
    'Jordan' => l10n.worldCupCountryJordan,
    'Korea Republic' => l10n.worldCupCountryKoreaRepublic,
    'Mexico' => l10n.worldCupCountryMexico,
    'Morocco' => l10n.worldCupCountryMorocco,
    'Netherlands' => l10n.worldCupCountryNetherlands,
    'New Zealand' => l10n.worldCupCountryNewZealand,
    'Norway' => l10n.worldCupCountryNorway,
    'Panama' => l10n.worldCupCountryPanama,
    'Paraguay' => l10n.worldCupCountryParaguay,
    'Portugal' => l10n.worldCupCountryPortugal,
    'Qatar' => l10n.worldCupCountryQatar,
    'Saudi Arabia' => l10n.worldCupCountrySaudiArabia,
    'Scotland' => l10n.worldCupCountryScotland,
    'Senegal' => l10n.worldCupCountrySenegal,
    'South Africa' => l10n.worldCupCountrySouthAfrica,
    'Spain' => l10n.worldCupCountrySpain,
    'Sweden' => l10n.worldCupCountrySweden,
    'Switzerland' => l10n.worldCupCountrySwitzerland,
    'Tunisia' => l10n.worldCupCountryTunisia,
    'Turkiye' => l10n.worldCupCountryTurkiye,
    'USA' => l10n.worldCupCountryUsa,
    'Uruguay' => l10n.worldCupCountryUruguay,
    'Uzbekistan' => l10n.worldCupCountryUzbekistan,
    _ => country,
  };
}

String _worldCupVenueLabel(AppLocalizations l10n, String venue) {
  return switch (venue) {
    'AT&T Stadium, Dallas' => l10n.worldCupVenueAttDallas,
    'BC Place, Vancouver' => l10n.worldCupVenueBcPlaceVancouver,
    'BMO Field, Toronto' => l10n.worldCupVenueBmoFieldToronto,
    'Estadio Akron, Guadalajara' => l10n.worldCupVenueEstadioAkronGuadalajara,
    'Estadio Azteca, Mexico City' => l10n.worldCupVenueEstadioAztecaMexicoCity,
    'Estadio BBVA, Monterrey' => l10n.worldCupVenueEstadioBbvaMonterrey,
    'GEHA Field at Arrowhead Stadium, Kansas City' =>
      l10n.worldCupVenueGehaArrowheadKansasCity,
    'Gillette Stadium, Boston' => l10n.worldCupVenueGilletteBoston,
    'Hard Rock Stadium, Miami' => l10n.worldCupVenueHardRockMiami,
    'Levi\'s Stadium, San Francisco Bay Area' =>
      l10n.worldCupVenueLevisSanFranciscoBayArea,
    'Lincoln Financial Field, Philadelphia' =>
      l10n.worldCupVenueLincolnFinancialPhiladelphia,
    'Lumen Field, Seattle' => l10n.worldCupVenueLumenSeattle,
    'Mercedes-Benz Stadium, Atlanta' => l10n.worldCupVenueMercedesBenzAtlanta,
    'MetLife Stadium, New York/New Jersey' =>
      l10n.worldCupVenueMetLifeNewYorkNewJersey,
    'NRG Stadium, Houston' => l10n.worldCupVenueNrgHouston,
    'SoFi Stadium, Los Angeles' => l10n.worldCupVenueSofiLosAngeles,
    _ => venue,
  };
}

class _CountryLabel extends StatelessWidget {
  final String country;
  final TextAlign textAlign;

  const _CountryLabel({required this.country, this.textAlign = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Text(
      _worldCupCountryLabelText(l10n, country),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: textAlign,
      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}

class _WorldCupCountrySettingPanel extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _WorldCupCountrySettingPanel({
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.46,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
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
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _TappableCountryLabel extends StatelessWidget {
  final String country;
  final TextAlign textAlign;
  final VoidCallback onTap;

  const _TappableCountryLabel({
    required this.country,
    required this.onTap,
    this.textAlign = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Tooltip(
      message: l10n.worldCupTeamRosterOpenTooltip(country),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
            child: _CountryLabel(country: country, textAlign: textAlign),
          ),
        ),
      ),
    );
  }
}

class _GuideBullet extends StatelessWidget {
  final String text;

  const _GuideBullet({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 7,
          height: 7,
          margin: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _WorldCupCalendarDayCell extends StatelessWidget {
  final DateTime day;
  final int dayNumber;
  final int fixtureCount;
  final int badgeCount;
  final List<String> flags;
  final bool isSelected;
  final bool isToday;

  const _WorldCupCalendarDayCell({
    required this.day,
    required this.dayNumber,
    required this.fixtureCount,
    required this.badgeCount,
    required this.flags,
    required this.isSelected,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final todayColor = colorScheme.tertiary;
    final dayTextColor = isSelected
        ? colorScheme.primary
        : (isToday ? todayColor : colorScheme.onSurface);
    final borderColor = isSelected
        ? colorScheme.primary
        : (isToday ? todayColor.withAlpha(210) : Colors.transparent);
    final backgroundColor = isSelected
        ? colorScheme.primary.withAlpha(28)
        : (isToday ? todayColor.withAlpha(24) : Colors.transparent);

    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        width: 40,
        height: 44,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$dayNumber',
              style: TextStyle(
                fontSize: _WorldCupScreenState._calendarDayNumberFontSize,
                fontWeight: FontWeight.w800,
                color: dayTextColor,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            if (flags.isNotEmpty)
              _WorldCupCalendarFlagStrip(
                countKey: _calendarMatchCountKey(day),
                flags: flags,
                fixtureCount: badgeCount,
              )
            else if (fixtureCount > 0)
              _WorldCupCalendarCountBadge(
                key: _calendarMatchCountKey(day),
                count: fixtureCount,
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              )
            else
              const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  ValueKey<String> _calendarMatchCountKey(DateTime day) {
    return ValueKey<String>(
      'world-cup-calendar-day-count-${day.year}-${day.month}-${day.day}',
    );
  }
}

class _WorldCupCalendarFlagStrip extends StatelessWidget {
  final Key countKey;
  final List<String> flags;
  final int fixtureCount;

  const _WorldCupCalendarFlagStrip({
    required this.countKey,
    required this.flags,
    required this.fixtureCount,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 12,
      width: 36,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final flag in flags)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Text(flag, style: const TextStyle(fontSize: 10)),
              ),
            if (fixtureCount > 0) ...[
              const SizedBox(width: 2),
              _WorldCupCalendarCountBadge(
                key: countKey,
                count: fixtureCount,
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WorldCupCalendarCountBadge extends StatelessWidget {
  final int count;
  final Color backgroundColor;
  final Color foregroundColor;

  const _WorldCupCalendarCountBadge({
    super.key,
    required this.count,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 13),
      height: 12,
      padding: const EdgeInsets.symmetric(horizontal: 3),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foregroundColor,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
      ),
    );
  }
}

class _GroupStandingsCard extends StatelessWidget {
  final String group;
  final List<WorldCupGroupStanding> standings;
  final ValueChanged<String> onTeamTap;

  const _GroupStandingsCard({
    required this.group,
    required this.standings,
    required this.onTeamTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final headerStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w900,
    );
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.worldCupGroupStageLabel(group),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(
                width: 30,
                child: Text(
                  l10n.worldCupStandingsRankColumn,
                  style: headerStyle,
                ),
              ),
              Expanded(
                child: Text(
                  l10n.worldCupStandingsTeamColumn,
                  style: headerStyle,
                ),
              ),
              SizedBox(
                width: 60,
                child: Text(
                  l10n.worldCupStandingsRecordColumn,
                  textAlign: TextAlign.center,
                  style: headerStyle,
                ),
              ),
              SizedBox(
                width: 34,
                child: Text(
                  l10n.worldCupStandingsPointsColumn,
                  textAlign: TextAlign.end,
                  style: headerStyle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (var index = 0; index < standings.length; index += 1) ...[
            _GroupStandingRow(
              rank: index + 1,
              standing: standings[index],
              onTeamTap: onTeamTap,
            ),
            if (index != standings.length - 1)
              Divider(
                height: 10,
                thickness: 0.7,
                color: theme.colorScheme.outlineVariant,
              ),
          ],
        ],
      ),
    );
  }
}

class _GroupStandingRow extends StatelessWidget {
  final int rank;
  final WorldCupGroupStanding standing;
  final ValueChanged<String> onTeamTap;

  const _GroupStandingRow({
    required this.rank,
    required this.standing,
    required this.onTeamTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTeamTap(standing.team),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 30,
                child: Text(
                  '$rank',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: rank <= 2
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Expanded(child: _CountryLabel(country: standing.team)),
              SizedBox(
                width: 60,
                child: Text(
                  l10n.worldCupStandingsRecordValue(
                    standing.wins,
                    standing.draws,
                    standing.losses,
                  ),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              SizedBox(
                width: 34,
                child: Text(
                  '${standing.points}',
                  textAlign: TextAlign.end,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w900,
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

class _GroupTeamsCard extends StatelessWidget {
  final String group;
  final List<String> teams;
  final ValueChanged<String> onTeamTap;

  const _GroupTeamsCard({
    required this.group,
    required this.teams,
    required this.onTeamTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.worldCupGroupStageLabel(group),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          for (final team in teams) ...[
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onTeamTap(team),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(child: _CountryLabel(country: team)),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (team != teams.last) const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}

enum _WorldCupRosterPosition { goalkeeper, defender, midfielder, forward }

class _WorldCupRosterPlayer {
  final String name;
  final String displayName;
  final String club;
  final _WorldCupRosterPosition position;
  final Offset spot;

  const _WorldCupRosterPlayer({
    required this.name,
    required this.displayName,
    required this.club,
    required this.position,
    required this.spot,
  });
}

class _WorldCupTeamRosterSheet extends StatelessWidget {
  final String team;
  final FifaRankingEntry? ranking;

  const _WorldCupTeamRosterSheet({required this.team, this.ranking});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final pool = worldCupRosterPoolForTeam(team);
    final players = _worldCupRosterPlayers(team, l10n);
    final formation = pool?.formation ?? '4-3-3';
    final hasKnownPool = pool != null;
    final flag = worldCupCountryFlag(team);
    final officialSquadUri = worldCupOfficialSquadUri(team);
    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.9,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (flag.isNotEmpty) ...[
                  Text(flag, style: theme.textTheme.headlineMedium),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.worldCupTeamRosterTitle(
                          _worldCupCountryName(l10n, team),
                        ),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.worldCupTeamRosterSubtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (officialSquadUri != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: OutlinedButton.icon(
                  onPressed: () => unawaited(
                    launchUrl(
                      officialSquadUri,
                      mode: LaunchMode.inAppBrowserView,
                    ),
                  ),
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: Text(l10n.newsOpenOfficialSource),
                ),
              ),
            ],
            if (ranking != null) ...[
              const SizedBox(height: 12),
              _InfoGrid(
                items: [
                  _InfoItem(
                    l10n.newsFifaRankingTitle,
                    _fifaRankingCompactLabel(l10n, ranking!),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            _WorldCupFormationPitch(
              title: l10n.worldCupTeamRosterFormationLabel(formation),
              players: _worldCupFormationPlayers(players, formation),
              onPlayerTap: (player) => _openPlayerProfile(context, player),
            ),
            const SizedBox(height: 14),
            _WorldCupRosterPositionSection(
              title: l10n.worldCupTeamRosterGoalkeepers,
              team: team,
              players: _playersForPosition(
                players,
                _WorldCupRosterPosition.goalkeeper,
              ),
              onPlayerTap: (player) => _openPlayerProfile(context, player),
            ),
            const SizedBox(height: 10),
            _WorldCupRosterPositionSection(
              title: l10n.worldCupTeamRosterDefenders,
              team: team,
              players: _playersForPosition(
                players,
                _WorldCupRosterPosition.defender,
              ),
              onPlayerTap: (player) => _openPlayerProfile(context, player),
            ),
            const SizedBox(height: 10),
            _WorldCupRosterPositionSection(
              title: l10n.worldCupTeamRosterMidfielders,
              team: team,
              players: _playersForPosition(
                players,
                _WorldCupRosterPosition.midfielder,
              ),
              onPlayerTap: (player) => _openPlayerProfile(context, player),
            ),
            const SizedBox(height: 10),
            _WorldCupRosterPositionSection(
              title: l10n.worldCupTeamRosterForwards,
              team: team,
              players: _playersForPosition(
                players,
                _WorldCupRosterPosition.forward,
              ),
              onPlayerTap: (player) => _openPlayerProfile(context, player),
            ),
            const SizedBox(height: 12),
            Text(
              hasKnownPool
                  ? l10n.worldCupTeamRosterCandidateSourceNote
                  : l10n.worldCupTeamRosterSourceNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPlayerProfile(
    BuildContext context,
    _WorldCupRosterPlayer player,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) =>
          _WorldCupPlayerProfileSheet(team: team, player: player),
    );
  }
}

class _WorldCupFormationPitch extends StatelessWidget {
  final String title;
  final List<_WorldCupRosterPlayer> players;
  final ValueChanged<_WorldCupRosterPlayer> onPlayerTap;

  const _WorldCupFormationPitch({
    required this.title,
    required this.players,
    required this.onPlayerTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sports_soccer, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AspectRatio(
            aspectRatio: 0.68,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return CustomPaint(
                  painter: _WorldCupPitchPainter(theme.colorScheme),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (final player in players)
                        Positioned(
                          left: constraints.maxWidth * player.spot.dx,
                          top: constraints.maxHeight * player.spot.dy,
                          child: FractionalTranslation(
                            translation: const Offset(-0.5, -0.5),
                            child: _PitchPlayerChip(
                              player: player,
                              onTap: () => onPlayerTap(player),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WorldCupPitchPainter extends CustomPainter {
  final ColorScheme scheme;

  const _WorldCupPitchPainter(this.scheme);

  @override
  void paint(Canvas canvas, Size size) {
    final grass = Paint()..color = const Color(0xFF2F7D50);
    final stripe = Paint()..color = const Color(0xFF398A5B);
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final rect = Offset.zero & size;
    final radius = Radius.circular(size.width * 0.055);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), grass);
    for (var index = 0; index < 6; index++) {
      if (index.isOdd) {
        final top = size.height / 6 * index;
        canvas.drawRect(
          Rect.fromLTWH(0, top, size.width, size.height / 6),
          stripe,
        );
      }
    }
    final inset = size.width * 0.06;
    final fieldRect = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(fieldRect, radius), line);
    canvas.drawLine(
      Offset(inset, size.height / 2),
      Offset(size.width - inset, size.height / 2),
      line,
    );
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 34, line);
    final boxWidth = size.width * 0.5;
    final boxHeight = size.height * 0.15;
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.width / 2, inset),
        width: boxWidth,
        height: boxHeight,
      ).translate(0, boxHeight / 2),
      line,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height - inset),
        width: boxWidth,
        height: boxHeight,
      ).translate(0, -boxHeight / 2),
      line,
    );
  }

  @override
  bool shouldRepaint(covariant _WorldCupPitchPainter oldDelegate) {
    return oldDelegate.scheme != scheme;
  }
}

class _PitchPlayerChip extends StatelessWidget {
  final _WorldCupRosterPlayer player;
  final VoidCallback onTap;

  const _PitchPlayerChip({required this.player, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: player.displayName,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 86),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: _positionColor(
                    theme,
                    player.position,
                  ).withValues(alpha: 0.52),
                ),
              ),
              child: Text(
                player.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: _positionColor(theme, player.position),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WorldCupRosterPositionSection extends StatelessWidget {
  final String title;
  final String team;
  final List<_WorldCupRosterPlayer> players;
  final ValueChanged<_WorldCupRosterPlayer> onPlayerTap;

  const _WorldCupRosterPositionSection({
    required this.title,
    required this.team,
    required this.players,
    required this.onPlayerTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.48,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final player in players)
                _RosterPlayerPill(
                  player: player,
                  onTap: () => onPlayerTap(player),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RosterPlayerPill extends StatelessWidget {
  final _WorldCupRosterPlayer player;
  final VoidCallback onTap;

  const _RosterPlayerPill({
    required this.player,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final color = _positionColor(theme, player.position);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsetsDirectional.fromSTEB(10, 6, 10, 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withValues(alpha: 0.32)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 190),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      player.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (_worldCupPlayerClubLabel(l10n, player).isNotEmpty)
                      Text(
                        _worldCupPlayerClubLabel(l10n, player),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
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

class _WorldCupPlayerProfileSheet extends StatelessWidget {
  final String team;
  final _WorldCupRosterPlayer player;

  const _WorldCupPlayerProfileSheet({required this.team, required this.player});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.62,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            Text(
              l10n.worldCupPlayerProfileTitle(player.displayName),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            _CountryLabel(country: team),
            const SizedBox(height: 18),
            _InfoGrid(
              items: [
                _InfoItem(
                  l10n.worldCupPlayerProfileTeamLabel,
                  _worldCupCountryLabelText(l10n, team),
                ),
                _InfoItem(
                  l10n.worldCupPlayerProfilePositionLabel,
                  _worldCupRosterPositionLabel(l10n, player.position),
                ),
                if (_worldCupPlayerClubLabel(l10n, player).isNotEmpty)
                  _InfoItem(
                    l10n.worldCupPlayerProfileClubLabel,
                    _worldCupPlayerClubLabel(l10n, player),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

List<_WorldCupRosterPlayer> _playersForPosition(
  List<_WorldCupRosterPlayer> players,
  _WorldCupRosterPosition position,
) {
  return players
      .where((player) => player.position == position)
      .toList(growable: false);
}

String _worldCupRosterPositionLabel(
  AppLocalizations l10n,
  _WorldCupRosterPosition position,
) {
  return switch (position) {
    _WorldCupRosterPosition.goalkeeper =>
      l10n.worldCupTeamRosterPositionGoalkeeper,
    _WorldCupRosterPosition.defender => l10n.worldCupTeamRosterPositionDefender,
    _WorldCupRosterPosition.midfielder =>
      l10n.worldCupTeamRosterPositionMidfielder,
    _WorldCupRosterPosition.forward => l10n.worldCupTeamRosterPositionForward,
  };
}

String _fifaMatchPlayerPositionLabel(
  AppLocalizations l10n,
  FifaMatchPlayerPosition position,
) {
  return switch (position) {
    FifaMatchPlayerPosition.goalkeeper =>
      l10n.worldCupTeamRosterPositionGoalkeeper,
    FifaMatchPlayerPosition.defender => l10n.worldCupTeamRosterPositionDefender,
    FifaMatchPlayerPosition.midfielder =>
      l10n.worldCupTeamRosterPositionMidfielder,
    FifaMatchPlayerPosition.forward => l10n.worldCupTeamRosterPositionForward,
    FifaMatchPlayerPosition.unknown => l10n.notSet,
  };
}

String _worldCupPlayerClubLabel(
  AppLocalizations l10n,
  _WorldCupRosterPlayer player,
) {
  final club = player.club.trim();
  return club;
}

List<_WorldCupRosterPlayer> _worldCupRosterPlayers(
  String team,
  AppLocalizations l10n,
) {
  final pool = worldCupRosterPoolForTeam(team);
  if (pool != null) {
    return <_WorldCupRosterPlayer>[
      ..._playersFromNames(
        team,
        pool.goalkeepers,
        _WorldCupRosterPosition.goalkeeper,
        const [Offset(0.50, 0.88)],
        l10n,
      ),
      ..._playersFromNames(
        team,
        pool.defenders,
        _WorldCupRosterPosition.defender,
        const [
          Offset(0.18, 0.70),
          Offset(0.40, 0.72),
          Offset(0.60, 0.72),
          Offset(0.82, 0.70),
        ],
        l10n,
      ),
      ..._playersFromNames(
        team,
        pool.midfielders,
        _WorldCupRosterPosition.midfielder,
        const [Offset(0.25, 0.48), Offset(0.50, 0.42), Offset(0.75, 0.48)],
        l10n,
      ),
      ..._playersFromNames(
        team,
        pool.forwards,
        _WorldCupRosterPosition.forward,
        const [Offset(0.24, 0.24), Offset(0.50, 0.17), Offset(0.76, 0.24)],
        l10n,
      ),
    ];
  }
  return <_WorldCupRosterPlayer>[
    _WorldCupRosterPlayer(
      name: l10n.worldCupTeamRosterPlayerSlot(
        l10n.worldCupTeamRosterPositionGoalkeeper,
        1,
      ),
      displayName: l10n.worldCupTeamRosterPlayerSlot(
        l10n.worldCupTeamRosterPositionGoalkeeper,
        1,
      ),
      club: '',
      position: _WorldCupRosterPosition.goalkeeper,
      spot: const Offset(0.50, 0.88),
    ),
    for (var index = 0; index < 4; index++)
      _WorldCupRosterPlayer(
        name: l10n.worldCupTeamRosterPlayerSlot(
          l10n.worldCupTeamRosterPositionDefender,
          index + 1,
        ),
        displayName: l10n.worldCupTeamRosterPlayerSlot(
          l10n.worldCupTeamRosterPositionDefender,
          index + 1,
        ),
        club: '',
        position: _WorldCupRosterPosition.defender,
        spot: [
          const Offset(0.18, 0.70),
          const Offset(0.40, 0.72),
          const Offset(0.60, 0.72),
          const Offset(0.82, 0.70),
        ][index],
      ),
    for (var index = 0; index < 3; index++)
      _WorldCupRosterPlayer(
        name: l10n.worldCupTeamRosterPlayerSlot(
          l10n.worldCupTeamRosterPositionMidfielder,
          index + 1,
        ),
        displayName: l10n.worldCupTeamRosterPlayerSlot(
          l10n.worldCupTeamRosterPositionMidfielder,
          index + 1,
        ),
        club: '',
        position: _WorldCupRosterPosition.midfielder,
        spot: [
          const Offset(0.25, 0.48),
          const Offset(0.50, 0.42),
          const Offset(0.75, 0.48),
        ][index],
      ),
    for (var index = 0; index < 3; index++)
      _WorldCupRosterPlayer(
        name: l10n.worldCupTeamRosterPlayerSlot(
          l10n.worldCupTeamRosterPositionForward,
          index + 1,
        ),
        displayName: l10n.worldCupTeamRosterPlayerSlot(
          l10n.worldCupTeamRosterPositionForward,
          index + 1,
        ),
        club: '',
        position: _WorldCupRosterPosition.forward,
        spot: [
          const Offset(0.24, 0.24),
          const Offset(0.50, 0.17),
          const Offset(0.76, 0.24),
        ][index],
      ),
  ];
}

List<_WorldCupRosterPlayer> _playersFromNames(
  String team,
  List<String> names,
  _WorldCupRosterPosition position,
  List<Offset> formationSpots,
  AppLocalizations l10n,
) {
  return [
    for (var index = 0; index < names.length; index += 1)
      _WorldCupRosterPlayer(
        name: names[index],
        displayName: worldCupRosterDisplayNameForPlayer(
          team,
          names[index],
          l10n.localeName,
        ),
        club: worldCupRosterClubForPlayer(team, names[index]),
        position: position,
        spot: index < formationSpots.length
            ? formationSpots[index]
            : Offset(0.18 + (index % 4) * 0.21, 0.96),
      ),
  ];
}

List<_WorldCupRosterPlayer> _worldCupFormationPlayers(
  List<_WorldCupRosterPlayer> players,
  String formation,
) {
  final shape = _formationShape(formation);
  final formationPlayers = <_WorldCupRosterPlayer>[];
  final goalkeepers = _playersForPosition(
    players,
    _WorldCupRosterPosition.goalkeeper,
  );
  if (goalkeepers.isNotEmpty) {
    formationPlayers.add(
      _playerWithSpot(goalkeepers.first, const Offset(0.50, 0.88)),
    );
  }

  final lineYs = _formationLineYs(shape.length);
  for (var lineIndex = 0; lineIndex < shape.length; lineIndex += 1) {
    final count = shape[lineIndex];
    final position = _formationLinePosition(lineIndex, shape.length);
    final linePlayers = _playersForPosition(players, position);
    final spots = _formationLineSpots(count, lineYs[lineIndex]);
    for (var index = 0;
        index < count && index < linePlayers.length;
        index += 1) {
      formationPlayers.add(_playerWithSpot(linePlayers[index], spots[index]));
    }
  }
  return formationPlayers;
}

List<int> _formationShape(String formation) {
  final parts = formation
      .split('-')
      .map((part) => int.tryParse(part.trim()))
      .whereType<int>()
      .where((count) => count > 0)
      .toList(growable: false);
  return parts.length >= 2 ? parts : const <int>[4, 3, 3];
}

List<double> _formationLineYs(int lineCount) {
  if (lineCount <= 1) return const <double>[0.48];
  const deepest = 0.72;
  const highest = 0.17;
  return <double>[
    for (var index = 0; index < lineCount; index += 1)
      deepest - (deepest - highest) * index / (lineCount - 1),
  ];
}

List<Offset> _formationLineSpots(int count, double y) {
  if (count <= 1) return <Offset>[Offset(0.50, y)];
  final edge = switch (count) {
    >= 5 => 0.12,
    4 => 0.17,
    3 => 0.24,
    2 => 0.34,
    _ => 0.50,
  };
  final width = 1 - edge * 2;
  return <Offset>[
    for (var index = 0; index < count; index += 1)
      Offset(edge + width * index / (count - 1), y),
  ];
}

_WorldCupRosterPosition _formationLinePosition(int lineIndex, int lineCount) {
  if (lineIndex == 0) return _WorldCupRosterPosition.defender;
  if (lineIndex == lineCount - 1) return _WorldCupRosterPosition.forward;
  return _WorldCupRosterPosition.midfielder;
}

_WorldCupRosterPlayer _playerWithSpot(
  _WorldCupRosterPlayer player,
  Offset spot,
) {
  return _WorldCupRosterPlayer(
    name: player.name,
    displayName: player.displayName,
    club: player.club,
    position: player.position,
    spot: spot,
  );
}

Color _positionColor(ThemeData theme, _WorldCupRosterPosition position) {
  return switch (position) {
    _WorldCupRosterPosition.goalkeeper => theme.colorScheme.tertiary,
    _WorldCupRosterPosition.defender => const Color(0xFF2A9D8F),
    _WorldCupRosterPosition.midfielder => theme.colorScheme.primary,
    _WorldCupRosterPosition.forward => theme.colorScheme.error,
  };
}

class _TournamentRoundSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<WorldCupFixture> fixtures;
  final _BracketSlotData Function(String slot) slotBuilder;

  const _TournamentRoundSection({
    required this.title,
    required this.subtitle,
    required this.fixtures,
    required this.slotBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return WatchCartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _SmallPill(label: subtitle),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 760 ? 2 : 1;
              const spacing = 10.0;
              final width =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final fixture in fixtures)
                    SizedBox(
                      width: width,
                      child: _BracketMatchCard(
                        fixture: fixture,
                        homeSlot: slotBuilder(fixture.homeTeam),
                        awaySlot: slotBuilder(fixture.awayTeam),
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

class _BracketMatchCard extends StatelessWidget {
  final WorldCupFixture fixture;
  final _BracketSlotData homeSlot;
  final _BracketSlotData awaySlot;

  const _BracketMatchCard({
    required this.fixture,
    required this.homeSlot,
    required this.awaySlot,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final kickoffText = formatKickoffWithKoreaTime(context, fixture.kickoffUtc);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.48,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SmallPill(label: l10n.worldCupMatchNumber(fixture.matchNumber)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  kickoffText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _BracketTeamSlot(slot: homeSlot),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Divider(color: theme.colorScheme.outlineVariant),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    l10n.worldCupVersusShort,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(color: theme.colorScheme.outlineVariant),
                ),
              ],
            ),
          ),
          _BracketTeamSlot(slot: awaySlot),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.stadium_outlined,
                size: 15,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  _worldCupVenueLabel(l10n, fixture.venue),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BracketTeamSlot extends StatelessWidget {
  final _BracketSlotData slot;

  const _BracketTeamSlot({required this.slot});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 7),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                slot.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (slot.detail != null) ...[
                const SizedBox(height: 2),
                Text(
                  slot.detail!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.25,
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

class _BracketSlotData {
  final String label;
  final String? detail;

  const _BracketSlotData({required this.label, this.detail});
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final List<_InfoItem> items;

  const _InfoGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 520 ? 2 : 1;
        const spacing = 8.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: _InfoTile(item: item),
              ),
          ],
        );
      },
    );
  }
}

class _InfoTile extends StatelessWidget {
  final _InfoItem item;

  const _InfoTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  final _InfoItem item;

  const _MilestoneRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.value,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
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

class _SmallPill extends StatelessWidget {
  final String label;

  const _SmallPill({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _WorldCupSizeReporter extends StatefulWidget {
  final Widget child;
  final ValueChanged<Size> onChange;

  const _WorldCupSizeReporter({
    required this.child,
    required this.onChange,
  });

  @override
  State<_WorldCupSizeReporter> createState() => _WorldCupSizeReporterState();
}

class _WorldCupSizeReporterState extends State<_WorldCupSizeReporter> {
  final GlobalKey _childKey = GlobalKey();
  Size? _lastSize;

  @override
  void initState() {
    super.initState();
    _scheduleReport();
  }

  @override
  void didUpdateWidget(covariant _WorldCupSizeReporter oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleReport();
  }

  @override
  Widget build(BuildContext context) {
    _scheduleReport();
    return SizedBox(key: _childKey, child: widget.child);
  }

  void _scheduleReport() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final size = _childKey.currentContext?.size;
      if (size == null || size == _lastSize) return;
      _lastSize = size;
      widget.onChange(size);
    });
  }
}

class _InfoItem {
  final String label;
  final String value;

  const _InfoItem(this.label, this.value);
}
