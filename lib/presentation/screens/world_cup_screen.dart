import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../application/league_fixture_reminder_service.dart';
import '../../application/notification_app_link.dart';
import '../../application/settings_service.dart';
import '../../application/world_cup_live_data_service.dart';
import '../../application/world_cup_roster_data.dart';
import '../../application/world_cup_schedule.dart';
import '../../domain/entities/fifa_world_overview.dart';
import '../../domain/repositories/option_repository.dart';
import '../../gen/app_localizations.dart';
import '../utils/kickoff_time_format.dart';
import '../utils/pdf_export.dart';
import '../utils/share_utils.dart';
import '../widgets/app_bar_action_button.dart';
import '../widgets/app_background.dart';
import '../widgets/app_page_route.dart';
import '../widgets/watch_cart/watch_cart_card.dart';
import 'fifa_ranking_screen.dart';

final Uri _worldCupWebShareUri = Uri.https(
  'namsoon00.github.io',
  '/football-note/',
).replace(fragment: '/world-cup');

@visibleForTesting
Uri worldCupShareUriForPlatform({bool? isWeb}) {
  return (isWeb ?? kIsWeb)
      ? _worldCupWebShareUri
      : Uri.parse(NotificationAppLink.worldCup());
}

class WorldCupScreen extends StatefulWidget {
  final OptionRepository? optionRepository;
  final SettingsService? settingsService;
  final WorldCupLiveDataService? liveDataService;
  final bool refreshOfficialDataOnOpen;
  final DateTime? initialSelectedDay;
  final int? initialMatchNumber;
  final DateTime? currentTime;

  const WorldCupScreen({
    super.key,
    this.optionRepository,
    this.settingsService,
    this.liveDataService,
    this.refreshOfficialDataOnOpen = true,
    this.initialSelectedDay,
    this.initialMatchNumber,
    this.currentTime,
  });

  @override
  State<WorldCupScreen> createState() => _WorldCupScreenState();
}

const Size _worldCupTournamentShareImageSize = Size(2000, 1120);
const double _worldCupTournamentShareImagePixelRatio = 1;

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
  bool _pageShareInProgress = false;
  late final PageController _selectedDayPageController;
  final Map<String, double> _selectedDayMatchPageHeights = <String, double>{};
  double? _selectedDayPagePosition;
  Timer? _clockTimer;
  bool _initialMatchDetailHandled = false;

  @override
  void initState() {
    super.initState();
    _liveDataService = widget.liveDataService ?? WorldCupLiveDataService();
    _ownsLiveDataService = widget.liveDataService == null;
    _countries = worldCupCountries();
    _focusedDay = _initialCalendarDay();
    _selectedDay = _focusedDay;
    final initialMatchNumber = widget.initialMatchNumber;
    final initialMatch = initialMatchNumber == null
        ? null
        : _fixtureByMatchNumber(initialMatchNumber);
    final initialSelectedDay =
        widget.initialSelectedDay ?? initialMatch?.localDay;
    if (initialSelectedDay != null) {
      _focusedDay = _clampCalendarDay(initialSelectedDay);
      _selectedDay = _focusedDay;
    }
    final initialPageIndex = _dayPageIndexForDay(_selectedDay);
    _selectedDayPagePosition = initialPageIndex.toDouble();
    _selectedDayPageController = PageController(
      initialPage: initialPageIndex,
      viewportFraction: _selectedDayPageViewportFraction,
    );
    _selectedDayPageController.addListener(_handleSelectedDayPageScroll);
    _loadCountryPreferences();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.refreshOfficialDataOnOpen) {
        unawaited(_refreshOfficialWorldCupData());
      } else {
        unawaited(_syncWorldCupReminders());
      }
      unawaited(_openInitialMatchDetail());
    });
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _selectedDayPageController.removeListener(_handleSelectedDayPageScroll);
    _selectedDayPageController.dispose();
    if (_ownsLiveDataService) {
      _liveDataService.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selectedView = _effectiveSelectedView;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.worldCupTitle),
        actions: [
          AppBarActionButton.label(
            tooltip: l10n.worldCupOverviewTitle,
            onPressed: _showTournamentInfo,
            icon: const Icon(Icons.info_outline_rounded),
            label: l10n.worldCupInfoAction,
            maxLabelWidth: 84,
          ),
          AppBarActionButton.icon(
            key: const ValueKey('world-cup-page-share-button'),
            tooltip: l10n.worldCupShareTooltip,
            onPressed: _pageShareInProgress
                ? null
                : () => unawaited(_shareWorldCupPage()),
            icon: Icons.ios_share_rounded,
          ),
          AppBarActionButton.label(
            tooltip: l10n.worldCupSourceAction,
            onPressed: () => unawaited(
              launchUrl(_sourceUri, mode: LaunchMode.inAppBrowserView),
            ),
            icon: const Icon(Icons.open_in_new_rounded),
            label: l10n.worldCupSourceShortAction,
            maxLabelWidth: 84,
          ),
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
              switch (selectedView) {
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
    final visibleViews = _visibleWorldCupViews;
    return SegmentedButton<_WorldCupView>(
      showSelectedIcon: false,
      segments: [
        for (final view in visibleViews)
          ButtonSegment<_WorldCupView>(
            value: view,
            icon: Icon(_worldCupViewIcon(view)),
            label: Text(_worldCupViewLabel(l10n, view)),
          ),
      ],
      selected: {_effectiveSelectedView},
      onSelectionChanged: (selection) {
        final nextView = selection.single;
        if (nextView == _WorldCupView.tournament) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            unawaited(_openTournamentFullScreen());
          });
          return;
        }
        setState(() => _selectedView = nextView);
      },
    );
  }

  List<_WorldCupView> get _visibleWorldCupViews {
    return <_WorldCupView>[
      _WorldCupView.schedule,
      _roundOf32Started ? _WorldCupView.tournament : _WorldCupView.standings,
    ];
  }

  _WorldCupView get _effectiveSelectedView {
    final visibleViews = _visibleWorldCupViews;
    return visibleViews.contains(_selectedView)
        ? _selectedView
        : visibleViews.last;
  }

  bool get _roundOf32Started => _roundOf32HasStarted(
        fixtures: _fixtures,
        officialMatchesByFixtureNumber: _officialMatchesByFixtureNumber,
        currentTime: widget.currentTime,
      );

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
              const SizedBox(height: 8),
              Text(
                l10n.worldCupStandingsTieGuide,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
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
    final qualifiedSlotResolver = _WorldCupRoundOf32QualifiedSlotResolver(
      _fixtures,
    );
    return _WorldCupTournamentBracket(
      rounds: _tournamentRounds(context, l10n),
      slotBuilder: (fixture, slot, side) =>
          _bracketSlotData(l10n, fixture, slot, side, qualifiedSlotResolver),
      scoreBuilder: _bracketMatchScoreData,
      onOpenFullScreen: _openTournamentFullScreen,
    );
  }

  List<_TournamentBracketRound> _tournamentRounds(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return [
      _tournamentRound(context, l10n, WorldCupStage.finalMatch),
      _tournamentRound(context, l10n, WorldCupStage.thirdPlace),
      _tournamentRound(context, l10n, WorldCupStage.semiFinal),
      _tournamentRound(context, l10n, WorldCupStage.quarterFinal),
      _tournamentRound(context, l10n, WorldCupStage.roundOf16),
      _tournamentRound(context, l10n, WorldCupStage.roundOf32),
    ];
  }

  _TournamentBracketRound _tournamentRound(
    BuildContext context,
    AppLocalizations l10n,
    WorldCupStage stage,
  ) {
    final fixtures = _fixturesForStage(stage);
    return _TournamentBracketRound(
      title: _stageLabelForStage(l10n, stage),
      subtitle: l10n.worldCupBracketRoundSummary(
        _dateRangeForFixtures(context, fixtures),
        fixtures.length,
      ),
      fixtures: fixtures,
    );
  }

  Future<void> _openTournamentFullScreen() async {
    final l10n = AppLocalizations.of(context)!;
    final qualifiedSlotResolver = _WorldCupRoundOf32QualifiedSlotResolver(
      _fixtures,
    );
    await Navigator.of(context).push<void>(
      AppPageRoute(
        builder: (_) => _WorldCupTournamentBracketFullScreen(
          rounds: _tournamentRounds(context, l10n),
          slotBuilder: (fixture, slot, side) => _bracketSlotData(
              l10n, fixture, slot, side, qualifiedSlotResolver),
          scoreBuilder: _bracketMatchScoreData,
        ),
      ),
    );
  }

  Future<void> _shareWorldCupPage() async {
    if (_pageShareInProgress) return;
    setState(() => _pageShareInProgress = true);
    try {
      final l10n = AppLocalizations.of(context)!;
      final shareUri = worldCupShareUriForPlatform();
      await shareTextContent(
        subject: l10n.worldCupHeroTitle,
        text: l10n.worldCupShareMessage(shareUri.toString()),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.worldCupShareOpenedSnack)),
      );
    } catch (error, stackTrace) {
      debugPrint('World Cup page share failed: $error\n$stackTrace');
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.worldCupShareFailedSnack)),
      );
    } finally {
      if (mounted) {
        setState(() => _pageShareInProgress = false);
      } else {
        _pageShareInProgress = false;
      }
    }
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
                                setState(() {
                                  _showSelectedCountriesOnly = selected;
                                  _selectedDayMatchPageHeights.clear();
                                });
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
        final activePage = _selectedDayPagePosition ?? initialIndex.toDouble();
        final height = _selectedDayMatchesPagerHeight(
          measuredPageWidth,
          selectedIndex: initialIndex,
          activePage: activePage,
        );
        final measurementIndices = _selectedDayPageMeasurementIndices(
          selectedIndex: initialIndex,
          activePage: activePage,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final pageIndex in measurementIndices)
              Offstage(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: SizedBox(
                    width: measuredPageWidth,
                    child: _WorldCupSizeReporter(
                      onChange: (size) => _recordSelectedDayMatchPageHeight(
                        pageIndex,
                        measuredPageWidth,
                        size.height,
                      ),
                      child: _buildSelectedDayMatchPage(
                        context,
                        _dayForPageIndex(pageIndex),
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
                  physics: _WorldCupLightSwipePageScrollPhysics(
                    currentPage: initialIndex,
                    parent: const BouncingScrollPhysics(),
                  ),
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
                      _selectedDayPagePosition = index.toDouble();
                    });
                  },
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsetsDirectional.only(
                        end: pageEndPadding,
                      ),
                      child: ClipRect(
                        child: OverflowBox(
                          alignment: Alignment.topCenter,
                          minHeight: 0,
                          maxHeight: double.infinity,
                          child: _buildSelectedDayMatchPage(
                            context,
                            _dayForPageIndex(index),
                          ),
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
                participants: _displayParticipantsForFixture(fixture),
                supportCountry: _supportCountry,
                interestCountries: _interestCountries,
                officialMatch:
                    _officialMatchesByFixtureNumber[fixture.matchNumber],
                rankingsByTeam: _rankingsByTeam,
                currentTime: widget.currentTime,
                onTeamTap: _openTeamRoster,
                onRankingTap: _openFifaRankingHub,
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
        ? 190.0
        : availableWidth < 430
            ? 178.0
            : 164.0;
    final matchCount =
        _visibleFixturesForDay(_dayForPageIndex(pageIndex)).length;
    final matchListHeight = matchCount == 0
        ? 48.0
        : matchCount * fixtureRowHeight + math.max(0, matchCount - 1) * 8.0;
    return 32 + 42 + matchListHeight + 32;
  }

  double _selectedDayMatchesPagerHeight(
    double availableWidth, {
    required int selectedIndex,
    required double activePage,
  }) {
    final roundedPage = activePage.round();
    final isSettled = (activePage - roundedPage).abs() < 0.02;
    if (isSettled) {
      final settledIndex = roundedPage.clamp(0, _dayPageCount - 1).toInt();
      return _selectedDayMatchPageHeight(
        settledIndex,
        availableWidth,
      );
    }

    final lowerIndex = activePage.floor().clamp(0, _dayPageCount - 1).toInt();
    final upperIndex = activePage.ceil().clamp(0, _dayPageCount - 1).toInt();
    final lowerHeight = _selectedDayMatchPageHeight(lowerIndex, availableWidth);
    final upperHeight = _selectedDayMatchPageHeight(upperIndex, availableWidth);
    if (lowerIndex == upperIndex) return lowerHeight;
    return math.max(lowerHeight, upperHeight);
  }

  double _selectedDayMatchPageHeight(int pageIndex, double availableWidth) {
    return _selectedDayMatchPageHeights[
            _selectedDayMatchPageHeightKey(pageIndex, availableWidth)] ??
        _selectedDayMatchesPagerEstimate(availableWidth, pageIndex);
  }

  List<int> _selectedDayPageMeasurementIndices({
    required int selectedIndex,
    required double activePage,
  }) {
    final indices = <int>{
      selectedIndex,
      activePage.floor().clamp(0, _dayPageCount - 1).toInt(),
      activePage.ceil().clamp(0, _dayPageCount - 1).toInt(),
      (selectedIndex - 1).clamp(0, _dayPageCount - 1).toInt(),
      (selectedIndex + 1).clamp(0, _dayPageCount - 1).toInt(),
    }.toList()
      ..sort();
    return indices;
  }

  String _selectedDayMatchPageHeightKey(int pageIndex, double availableWidth) {
    final selectedCountries = _selectedCountrySet.toList()..sort();
    final filterKey = _showSelectedCountriesOnly
        ? selectedCountries.join('|')
        : 'all-countries';
    return '$pageIndex:${availableWidth.round()}:$filterKey';
  }

  void _recordSelectedDayMatchPageHeight(
    int pageIndex,
    double availableWidth,
    double height,
  ) {
    if (!mounted || height <= 0) return;
    final key = _selectedDayMatchPageHeightKey(pageIndex, availableWidth);
    final previousHeight = _selectedDayMatchPageHeights[key];
    if (previousHeight != null && (previousHeight - height).abs() < 0.5) {
      return;
    }
    setState(() {
      _selectedDayMatchPageHeights[key] = height;
    });
  }

  void _handleSelectedDayPageScroll() {
    if (!_selectedDayPageController.hasClients) return;
    final page = _selectedDayPageController.page;
    if (page == null) return;
    final clampedPage =
        page.clamp(0.0, (_dayPageCount - 1).toDouble()).toDouble();
    final previousPage = _selectedDayPagePosition;
    if (previousPage != null && (previousPage - clampedPage).abs() < 0.01) {
      return;
    }
    setState(() => _selectedDayPagePosition = clampedPage);
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
        initialTeam: team,
        rankingsByTeam: _rankingsByTeam,
        fixtures: _fixtures,
        officialMatchesByFixtureNumber: _officialMatchesByFixtureNumber,
        currentTime: widget.currentTime,
        onRankingTap: _openFifaRankingHub,
      ),
    );
  }

  Future<void> _openFifaRankingHub() async {
    await Navigator.of(
      context,
    ).push<void>(AppPageRoute(builder: (_) => const FifaRankingScreen()));
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

  Future<void> _openInitialMatchDetail() async {
    if (_initialMatchDetailHandled) return;
    final matchNumber = widget.initialMatchNumber;
    if (matchNumber == null) return;
    _initialMatchDetailHandled = true;
    final fixture = _fixtureByMatchNumber(matchNumber);
    if (fixture == null || !mounted) return;
    await _openFixtureDetail(fixture);
  }

  Future<void> _setSupportCountry(String country) async {
    setState(() {
      _supportCountry = country;
      _supportCountryRegistered = country.trim().isNotEmpty;
      _showCountrySettings = !_hasRegisteredCountrySettings;
      if (_selectedCountrySet.isEmpty) {
        _showSelectedCountriesOnly = false;
      }
      _selectedDayMatchPageHeights.clear();
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
      _selectedDayMatchPageHeights.clear();
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
        _selectedDayMatchPageHeights.clear();
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
    return fixtures
        .where(_fixtureInvolvesAnySelectedCountry)
        .toList(growable: false);
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
        .where(_fixtureInvolvesAnySelectedCountry)
        .toList(growable: false);
  }

  List<String> _selectedCountryFlagsForFixtures(
    List<WorldCupFixture> fixtures,
  ) {
    if (fixtures.isEmpty) return const <String>[];
    final selectedCountries = _selectedCountrySet.toList()..sort();
    final flags = <String>[];
    for (final country in selectedCountries) {
      if (!fixtures
          .any((fixture) => _fixtureInvolvesCountry(fixture, country))) {
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
      final participants = _displayParticipantsForFixture(fixture);
      for (final country in [participants.homeTeam, participants.awayTeam]) {
        if (!countries.contains(country)) countries.add(country);
      }
    }
    return countries
        .map(worldCupCountryFlag)
        .where((flag) => flag.isNotEmpty)
        .toList(growable: false);
  }

  bool _fixtureInvolvesAnySelectedCountry(WorldCupFixture fixture) {
    return _selectedCountrySet.any(
      (country) => _fixtureInvolvesCountry(fixture, country),
    );
  }

  bool _fixtureInvolvesCountry(WorldCupFixture fixture, String country) {
    return _displayParticipantsForFixture(fixture).involvesCountry(country);
  }

  _WorldCupFixtureParticipants _displayParticipantsForFixture(
    WorldCupFixture fixture,
  ) {
    return _worldCupDisplayParticipantsForFixture(
      fixture,
      _officialMatchesByFixtureNumber[fixture.matchNumber],
      qualifiedSlotResolver: fixture.isGroupStage
          ? null
          : _WorldCupRoundOf32QualifiedSlotResolver(_fixtures),
    );
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

  _BracketSlotData _bracketSlotData(
    AppLocalizations l10n,
    WorldCupFixture fixture,
    String slot,
    _BracketSlotSide side,
    _WorldCupRoundOf32QualifiedSlotResolver qualifiedSlotResolver,
  ) {
    final slotLabel = _bracketSlotLabel(l10n, slot);
    final detail = _bracketSlotDetail(l10n, slot);
    final officialTeam = _officialBracketTeamForSlot(fixture, side);
    if (officialTeam != null) {
      return _BracketSlotData(
        label: _worldCupCountryLabelText(l10n, officialTeam),
        detail: l10n.worldCupBracketQualifiedSlotDetail(slotLabel),
      );
    }
    final outcomeSlotData = _bracketOutcomeSlotData(
      l10n,
      slot,
      qualifiedSlotResolver,
    );
    if (outcomeSlotData != null) return outcomeSlotData;
    final qualifiedTeams = qualifiedSlotResolver.teamsForSlot(slot);
    if (qualifiedTeams.isNotEmpty) {
      return _BracketSlotData(
        label: qualifiedTeams
            .map((team) => _worldCupCountryLabelText(l10n, team))
            .join(l10n.worldCupBracketQualifiedTeamSeparator),
        detail: l10n.worldCupBracketQualifiedSlotDetail(
          slotLabel,
        ),
      );
    }
    return _BracketSlotData(
      label: slotLabel,
      detail: detail,
    );
  }

  _BracketSlotData? _bracketOutcomeSlotData(
    AppLocalizations l10n,
    String slot,
    _WorldCupRoundOf32QualifiedSlotResolver qualifiedSlotResolver,
  ) {
    final matchReference = RegExp(r'^([WL])([0-9]+)$').firstMatch(slot);
    if (matchReference == null) return null;
    final wantsWinner = matchReference.group(1) == 'W';
    final sourceMatchNumber = int.parse(matchReference.group(2)!);
    final sourceFixture = _fixtureByMatchNumber(sourceMatchNumber);
    if (sourceFixture == null) return null;
    final sourceOfficialMatch =
        _officialMatchesByFixtureNumber[sourceFixture.matchNumber];
    final participants = _worldCupDisplayParticipantsForFixture(
      sourceFixture,
      sourceOfficialMatch,
      qualifiedSlotResolver:
          sourceFixture.isGroupStage ? null : qualifiedSlotResolver,
    );
    final displayScore = _displayScoreForFixture(
      sourceFixture,
      sourceOfficialMatch,
    );
    final resultSign = _homeResultSign(
      homeScore: displayScore.homeScore,
      awayScore: displayScore.awayScore,
      homePenaltyScore: displayScore.homePenaltyScore,
      awayPenaltyScore: displayScore.awayPenaltyScore,
    );
    if (resultSign != null && resultSign != 0) {
      final team = wantsWinner
          ? (resultSign > 0
              ? participants.homeOpenTeam
              : participants.awayOpenTeam)
          : (resultSign > 0
              ? participants.awayOpenTeam
              : participants.homeOpenTeam);
      if (team != null) {
        return _BracketSlotData(
          label: _worldCupCountryLabelText(l10n, team),
          detail: wantsWinner
              ? l10n.worldCupBracketWinnerResolvedDetail
              : l10n.worldCupBracketLoserResolvedDetail,
          showDetail: true,
        );
      }
    }

    final candidateTeams = <String>[];
    for (final team in [
      ...participants.homeDisplayTeams,
      ...participants.awayDisplayTeams,
    ]) {
      if (candidateTeams
          .any((seen) => _worldCupTeamKey(seen) == _worldCupTeamKey(team))) {
        continue;
      }
      candidateTeams.add(team);
    }
    if (candidateTeams.isEmpty) return null;
    return _BracketSlotData(
      label: candidateTeams
          .map((team) => _worldCupCountryLabelText(l10n, team))
          .join(l10n.worldCupBracketQualifiedTeamSeparator),
      detail: wantsWinner
          ? l10n.worldCupBracketWinnerCandidateDetail
          : l10n.worldCupBracketLoserCandidateDetail,
      showDetail: true,
    );
  }

  _BracketMatchScoreData _bracketMatchScoreData(WorldCupFixture fixture) {
    final officialMatch = _officialMatchesByFixtureNumber[fixture.matchNumber];
    final displayScore = _displayScoreForFixture(fixture, officialMatch);
    final resultSign = _homeResultSign(
      homeScore: displayScore.homeScore,
      awayScore: displayScore.awayScore,
      homePenaltyScore: displayScore.homePenaltyScore,
      awayPenaltyScore: displayScore.awayPenaltyScore,
    );
    final hasDisplayScore =
        displayScore.homeScore != null && displayScore.awayScore != null;
    final isLive = _runtimeStatusForFixture(
          fixture,
          officialMatch: officialMatch,
          now: widget.currentTime,
        ) ==
        _WorldCupFixtureRuntimeStatus.live;
    return _BracketMatchScoreData(
      homeScore: displayScore.homeScore,
      awayScore: displayScore.awayScore,
      homePenaltyScore: displayScore.homePenaltyScore,
      awayPenaltyScore: displayScore.awayPenaltyScore,
      applyResultColors: hasDisplayScore && !isLive,
      homeResult: _bracketTeamResult(resultSign, isHome: true),
      awayResult: _bracketTeamResult(resultSign, isHome: false),
    );
  }

  String? _officialBracketTeamForSlot(
    WorldCupFixture fixture,
    _BracketSlotSide side,
  ) {
    final officialMatch = _officialMatchesByFixtureNumber[fixture.matchNumber];
    if (officialMatch == null) return null;
    final team = (switch (side) {
      _BracketSlotSide.home => officialMatch.homeTeamName,
      _BracketSlotSide.away => officialMatch.awayTeamName,
    })
        .trim();
    return team.isEmpty ? null : _worldCupCanonicalCountry(team);
  }

  String _bracketSlotLabel(AppLocalizations l10n, String slot) {
    return _worldCupTournamentSlotLabel(l10n, slot);
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

IconData _worldCupViewIcon(_WorldCupView view) {
  return switch (view) {
    _WorldCupView.schedule => Icons.event_note_rounded,
    _WorldCupView.standings => Icons.leaderboard_rounded,
    _WorldCupView.tournament => Icons.account_tree_rounded,
  };
}

String _worldCupViewLabel(AppLocalizations l10n, _WorldCupView view) {
  return switch (view) {
    _WorldCupView.schedule => l10n.worldCupScheduleTab,
    _WorldCupView.standings => l10n.worldCupStandingsTab,
    _WorldCupView.tournament => l10n.worldCupTournamentTab,
  };
}

class _WorldCupLightSwipePageScrollPhysics extends PageScrollPhysics {
  final int currentPage;
  final double pageTurnThreshold;

  const _WorldCupLightSwipePageScrollPhysics({
    required this.currentPage,
    this.pageTurnThreshold = 0.12,
    super.parent,
  });

  @override
  _WorldCupLightSwipePageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _WorldCupLightSwipePageScrollPhysics(
      currentPage: currentPage,
      pageTurnThreshold: pageTurnThreshold,
      parent: buildParent(ancestor),
    );
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    if (position is! PageMetrics ||
        position.viewportDimension <= 0 ||
        position.viewportFraction <= 0) {
      return super.createBallisticSimulation(position, velocity);
    }

    final tolerance = toleranceFor(position);
    final targetPage = _targetPage(position, tolerance, velocity);
    final targetPixels = _pixelsForPage(position, targetPage);
    if ((targetPixels - position.pixels).abs() < tolerance.distance) {
      return null;
    }
    return ScrollSpringSimulation(
      spring,
      position.pixels,
      targetPixels,
      velocity,
      tolerance: tolerance,
    );
  }

  double _targetPage(
    PageMetrics position,
    Tolerance tolerance,
    double velocity,
  ) {
    final maxPage = _maxPage(position);
    final basePage = currentPage.clamp(0, maxPage).toDouble();
    final page = position.page ?? basePage;
    if (velocity > tolerance.velocity) {
      return (basePage + 1).clamp(0.0, maxPage).toDouble();
    }
    if (velocity < -tolerance.velocity) {
      return (basePage - 1).clamp(0.0, maxPage).toDouble();
    }

    final delta = page - basePage;
    if (delta >= pageTurnThreshold) {
      return (basePage + 1).clamp(0.0, maxPage).toDouble();
    }
    if (delta <= -pageTurnThreshold) {
      return (basePage - 1).clamp(0.0, maxPage).toDouble();
    }
    return basePage;
  }

  double _maxPage(PageMetrics position) {
    final pageExtent = position.viewportDimension * position.viewportFraction;
    if (pageExtent <= 0) return 0;
    return position.maxScrollExtent / pageExtent;
  }

  double _pixelsForPage(PageMetrics position, double page) {
    return page * position.viewportDimension * position.viewportFraction;
  }
}

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

bool _roundOf32HasStarted({
  required List<WorldCupFixture> fixtures,
  required Map<int, FifaAMatchEntry> officialMatchesByFixtureNumber,
  DateTime? currentTime,
}) {
  final roundOf32Fixtures = fixtures
      .where((fixture) => fixture.stage == WorldCupStage.roundOf32)
      .toList(growable: false);
  if (roundOf32Fixtures.isEmpty) return false;
  for (final fixture in roundOf32Fixtures) {
    final officialMatch = officialMatchesByFixtureNumber[fixture.matchNumber];
    if (officialMatch?.status == FifaAMatchStatus.live ||
        officialMatch?.status == FifaAMatchStatus.finished ||
        fixture.hasScore) {
      return true;
    }
  }
  final firstKickoff = roundOf32Fixtures
      .map((fixture) => fixture.kickoffUtc.toUtc())
      .reduce((a, b) => a.isBefore(b) ? a : b);
  return !(currentTime ?? DateTime.now()).toUtc().isBefore(firstKickoff);
}

class _WorldCupFixtureParticipants {
  final String homeTeam;
  final String awayTeam;
  final List<String> homeCandidateTeams;
  final List<String> awayCandidateTeams;

  const _WorldCupFixtureParticipants({
    required this.homeTeam,
    required this.awayTeam,
    this.homeCandidateTeams = const <String>[],
    this.awayCandidateTeams = const <String>[],
  });

  List<String> get homeDisplayTeams => homeCandidateTeams.isNotEmpty
      ? homeCandidateTeams
      : _worldCupSingleCountryCandidate(homeTeam);

  List<String> get awayDisplayTeams => awayCandidateTeams.isNotEmpty
      ? awayCandidateTeams
      : _worldCupSingleCountryCandidate(awayTeam);

  String? get homeOpenTeam =>
      homeDisplayTeams.length == 1 ? homeDisplayTeams.single : null;

  String? get awayOpenTeam =>
      awayDisplayTeams.length == 1 ? awayDisplayTeams.single : null;

  bool involvesCountry(String country) {
    final target = _worldCupTeamKey(country);
    final homeTeams = homeDisplayTeams;
    final awayTeams = awayDisplayTeams;
    return (homeTeams.isEmpty
            ? _worldCupTeamKey(homeTeam) == target
            : homeTeams.any((team) => _worldCupTeamKey(team) == target)) ||
        (awayTeams.isEmpty
            ? _worldCupTeamKey(awayTeam) == target
            : awayTeams.any((team) => _worldCupTeamKey(team) == target));
  }
}

_WorldCupFixtureParticipants _worldCupDisplayParticipantsForFixture(
  WorldCupFixture fixture,
  FifaAMatchEntry? officialMatch, {
  _WorldCupRoundOf32QualifiedSlotResolver? qualifiedSlotResolver,
}) {
  _WorldCupFixtureParticipants bracketParticipants() {
    final homeTeams = qualifiedSlotResolver?.teamsForSlot(fixture.homeTeam) ??
        const <String>[];
    final awayTeams = qualifiedSlotResolver?.teamsForSlot(fixture.awayTeam) ??
        const <String>[];
    return _WorldCupFixtureParticipants(
      homeTeam: fixture.homeTeam,
      awayTeam: fixture.awayTeam,
      homeCandidateTeams: homeTeams,
      awayCandidateTeams: awayTeams,
    );
  }

  if (officialMatch == null) {
    return bracketParticipants();
  }
  final officialHome = officialMatch.homeTeamName.trim();
  final officialAway = officialMatch.awayTeamName.trim();
  if (officialHome.isEmpty || officialAway.isEmpty) {
    return bracketParticipants();
  }
  final sameDirection =
      _worldCupTeamKey(fixture.homeTeam) == _worldCupTeamKey(officialHome) &&
          _worldCupTeamKey(fixture.awayTeam) == _worldCupTeamKey(officialAway);
  if (sameDirection || !fixture.isGroupStage) {
    final homeTeam = _worldCupCanonicalCountry(officialHome);
    final awayTeam = _worldCupCanonicalCountry(officialAway);
    return _WorldCupFixtureParticipants(
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      homeCandidateTeams: <String>[homeTeam],
      awayCandidateTeams: <String>[awayTeam],
    );
  }
  final reverseDirection =
      _worldCupTeamKey(fixture.homeTeam) == _worldCupTeamKey(officialAway) &&
          _worldCupTeamKey(fixture.awayTeam) == _worldCupTeamKey(officialHome);
  if (reverseDirection) {
    final homeTeam = _worldCupCanonicalCountry(officialAway);
    final awayTeam = _worldCupCanonicalCountry(officialHome);
    return _WorldCupFixtureParticipants(
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      homeCandidateTeams: <String>[homeTeam],
      awayCandidateTeams: <String>[awayTeam],
    );
  }
  return bracketParticipants();
}

List<String> _worldCupSingleCountryCandidate(String team) {
  final canonicalTeam = _worldCupCanonicalCountry(team);
  return worldCupCountryFlag(canonicalTeam).isEmpty
      ? const <String>[]
      : <String>[canonicalTeam];
}

({
  int? homeScore,
  int? awayScore,
  int? homePenaltyScore,
  int? awayPenaltyScore,
}) _displayScoreForFixture(
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
    if (sameDirection || !fixture.isGroupStage) {
      return (
        homeScore: officialMatch.homeScore,
        awayScore: officialMatch.awayScore,
        homePenaltyScore: officialMatch.homePenaltyScore,
        awayPenaltyScore: officialMatch.awayPenaltyScore,
      );
    }
    final reverseDirection = _worldCupTeamKey(fixture.homeTeam) ==
            _worldCupTeamKey(officialMatch.awayTeamName) &&
        _worldCupTeamKey(fixture.awayTeam) ==
            _worldCupTeamKey(officialMatch.homeTeamName);
    if (reverseDirection) {
      return (
        homeScore: officialMatch.awayScore,
        awayScore: officialMatch.homeScore,
        homePenaltyScore: officialMatch.awayPenaltyScore,
        awayPenaltyScore: officialMatch.homePenaltyScore,
      );
    }
  }
  return (
    homeScore: fixture.homeScore,
    awayScore: fixture.awayScore,
    homePenaltyScore: fixture.homePenaltyScore,
    awayPenaltyScore: fixture.awayPenaltyScore,
  );
}

WorldCupFixture _fixtureWithDisplayScore(
  WorldCupFixture fixture,
  FifaAMatchEntry? officialMatch,
) {
  final displayScore = _displayScoreForFixture(fixture, officialMatch);
  if (displayScore.homeScore == null || displayScore.awayScore == null) {
    return fixture;
  }
  return fixture.copyWithScore(
    homeScore: displayScore.homeScore,
    awayScore: displayScore.awayScore,
    homePenaltyScore: displayScore.homePenaltyScore,
    awayPenaltyScore: displayScore.awayPenaltyScore,
  );
}

int? _homeResultSign({
  required int? homeScore,
  required int? awayScore,
  int? homePenaltyScore,
  int? awayPenaltyScore,
}) {
  if (homeScore == null || awayScore == null) return null;
  if (homeScore > awayScore) return 1;
  if (homeScore < awayScore) return -1;
  if (homePenaltyScore != null && awayPenaltyScore != null) {
    if (homePenaltyScore > awayPenaltyScore) return 1;
    if (homePenaltyScore < awayPenaltyScore) return -1;
  }
  return 0;
}

WorldCupFixtureTeamResult _bracketTeamResult(
  int? homeResultSign, {
  required bool isHome,
}) {
  if (homeResultSign == null) return WorldCupFixtureTeamResult.scheduled;
  if (homeResultSign == 0) return WorldCupFixtureTeamResult.draw;
  final homeWon = homeResultSign > 0;
  return homeWon == isHome
      ? WorldCupFixtureTeamResult.win
      : WorldCupFixtureTeamResult.loss;
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
  final _WorldCupFixtureParticipants participants;
  final String supportCountry;
  final Set<String> interestCountries;
  final FifaAMatchEntry? officialMatch;
  final Map<String, FifaRankingEntry> rankingsByTeam;
  final DateTime? currentTime;
  final ValueChanged<String> onTeamTap;
  final VoidCallback onRankingTap;
  final ValueChanged<WorldCupFixture> onScoreTap;

  const _FixtureRow({
    required this.fixture,
    required this.participants,
    required this.supportCountry,
    required this.interestCountries,
    required this.officialMatch,
    required this.rankingsByTeam,
    this.currentTime,
    required this.onTeamTap,
    required this.onRankingTap,
    required this.onScoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final supportMatch = participants.involvesCountry(supportCountry);
    final interestMatch = interestCountries.any(participants.involvesCountry);
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
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 380;
              final homeOpenTeam = participants.homeOpenTeam;
              final awayOpenTeam = participants.awayOpenTeam;
              final homeBlock = _FixtureTeamBlock(
                team: homeOpenTeam ?? participants.homeTeam,
                displayLabel: _fixtureParticipantLabel(
                  l10n,
                  participants.homeTeam,
                  participants.homeDisplayTeams,
                ),
                ranking:
                    homeOpenTeam == null ? null : rankingsByTeam[homeOpenTeam],
                compact: compact,
                onTap:
                    homeOpenTeam == null ? null : () => onTeamTap(homeOpenTeam),
                onRankingTap: onRankingTap,
              );
              final scoreBoard = _FixtureScoreBoard(
                fixture: fixture,
                status: runtimeStatus,
                officialMatch: officialMatch,
                compact: compact,
                onTap: () => onScoreTap(fixture),
              );
              final awayBlock = _FixtureTeamBlock(
                team: awayOpenTeam ?? participants.awayTeam,
                displayLabel: _fixtureParticipantLabel(
                  l10n,
                  participants.awayTeam,
                  participants.awayDisplayTeams,
                ),
                ranking:
                    awayOpenTeam == null ? null : rankingsByTeam[awayOpenTeam],
                compact: compact,
                onTap:
                    awayOpenTeam == null ? null : () => onTeamTap(awayOpenTeam),
                onRankingTap: onRankingTap,
              );
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: homeBlock),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 6 : 10,
                    ),
                    child: scoreBoard,
                  ),
                  Expanded(child: awayBlock),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  kickoffText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.stadium_outlined,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  _worldCupVenueLabel(l10n, fixture.venue),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
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

class _FixtureTeamBlock extends StatelessWidget {
  final String team;
  final String displayLabel;
  final FifaRankingEntry? ranking;
  final bool compact;
  final VoidCallback? onTap;
  final VoidCallback onRankingTap;

  const _FixtureTeamBlock({
    required this.team,
    required this.displayLabel,
    required this.ranking,
    required this.compact,
    required this.onTap,
    required this.onRankingTap,
  });

  @override
  Widget build(BuildContext context) {
    final metaPills = <Widget>[
      if (ranking != null)
        _FifaRankingPill(ranking: ranking!, onTap: onRankingTap),
    ];
    final theme = Theme.of(context);
    final labelStyle =
        (compact ? theme.textTheme.labelMedium : theme.textTheme.labelLarge)
            ?.copyWith(
      fontWeight: FontWeight.w900,
      height: 1.08,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: double.infinity,
          child: onTap == null
              ? Text(
                  displayLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: labelStyle,
                )
              : _TappableCountryLabel(
                  country: team,
                  textAlign: TextAlign.center,
                  compact: compact,
                  onTap: onTap!,
                ),
        ),
        if (metaPills.isNotEmpty) ...[
          SizedBox(height: compact ? 4 : 6),
          SizedBox(
            width: double.infinity,
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: metaPills,
            ),
          ),
        ],
      ],
    );
  }
}

String _fixtureParticipantLabel(
  AppLocalizations l10n,
  String fallbackTeam,
  List<String> displayTeams,
) {
  if (displayTeams.isEmpty) {
    return _worldCupTournamentSlotLabel(l10n, fallbackTeam);
  }
  return displayTeams
      .map((team) => _worldCupCountryLabelText(l10n, team))
      .join(l10n.worldCupBracketQualifiedTeamSeparator);
}

class _FixtureScoreBoard extends StatelessWidget {
  final WorldCupFixture fixture;
  final _WorldCupFixtureRuntimeStatus status;
  final FifaAMatchEntry? officialMatch;
  final bool compact;
  final VoidCallback onTap;

  const _FixtureScoreBoard({
    required this.fixture,
    required this.status,
    required this.officialMatch,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final displayScore = _displayScoreForFixture(fixture, officialMatch);
    final hasDisplayScore =
        displayScore.homeScore != null && displayScore.awayScore != null;
    final scoreStyle =
        (compact ? theme.textTheme.titleSmall : theme.textTheme.titleMedium)
            ?.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w900,
    );
    return Tooltip(
      message: l10n.worldCupMatchDetailTitle,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: compact ? 60 : 74,
              minHeight: compact ? 42 : 46,
            ),
            child: Ink(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 7 : 9,
                vertical: compact ? 7 : 8,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.34),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: _WorldCupScoreLine(
                      homeScore: displayScore.homeScore,
                      awayScore: displayScore.awayScore,
                      homePenaltyScore: displayScore.homePenaltyScore,
                      awayPenaltyScore: displayScore.awayPenaltyScore,
                      pendingLabel: l10n.worldCupScorePending,
                      applyResultColors: hasDisplayScore &&
                          status != _WorldCupFixtureRuntimeStatus.live,
                      style: scoreStyle,
                      maxLines: 1,
                    ),
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

class _WorldCupScoreLine extends StatelessWidget {
  final int? homeScore;
  final int? awayScore;
  final int? homePenaltyScore;
  final int? awayPenaltyScore;
  final String pendingLabel;
  final bool applyResultColors;
  final TextStyle? style;
  final int maxLines;

  const _WorldCupScoreLine({
    required this.homeScore,
    required this.awayScore,
    this.homePenaltyScore,
    this.awayPenaltyScore,
    required this.pendingLabel,
    required this.applyResultColors,
    required this.style,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final home = homeScore;
    final away = awayScore;
    if (home == null || away == null) {
      return Text(
        pendingLabel,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: style,
      );
    }

    final label = '$home : $away';
    final hasPenaltyScore =
        homePenaltyScore != null && awayPenaltyScore != null;
    final penaltyLabel = hasPenaltyScore
        ? l10n.worldCupScorePenaltyLine(
            homePenaltyScore!,
            awayPenaltyScore!,
          )
        : null;
    if (!applyResultColors) {
      return _WorldCupScoreTextStack(
        score: Text(
          label,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: style?.copyWith(color: theme.colorScheme.primary),
        ),
        penaltyLabel: penaltyLabel,
        penaltyStyle: style?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontSize: (style?.fontSize ?? 14) * 0.72,
          fontWeight: FontWeight.w800,
        ),
      );
    }

    final resultSign = _homeResultSign(
      homeScore: home,
      awayScore: away,
      homePenaltyScore: homePenaltyScore,
      awayPenaltyScore: awayPenaltyScore,
    );
    if (resultSign == 0) {
      return _WorldCupScoreTextStack(
        score: Text(
          label,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: style?.copyWith(color: theme.colorScheme.tertiary),
        ),
        penaltyLabel: penaltyLabel,
        penaltyStyle: style?.copyWith(
          color: theme.colorScheme.tertiary,
          fontSize: (style?.fontSize ?? 14) * 0.72,
          fontWeight: FontWeight.w800,
        ),
      );
    }

    final homeWon = resultSign == 1;
    final winColor = theme.colorScheme.primary;
    final lossColor = theme.colorScheme.error;
    final baseStyle = style ?? DefaultTextStyle.of(context).style;
    return Semantics(
      label: penaltyLabel == null ? label : '$label, $penaltyLabel',
      child: ExcludeSemantics(
        child: _WorldCupScoreTextStack(
          score: Text.rich(
            TextSpan(
              style: baseStyle,
              children: [
                TextSpan(
                  text: '$home',
                  style: baseStyle.copyWith(
                    color: homeWon ? winColor : lossColor,
                  ),
                ),
                TextSpan(
                  text: ' : ',
                  style: baseStyle.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                TextSpan(
                  text: '$away',
                  style: baseStyle.copyWith(
                    color: homeWon ? lossColor : winColor,
                  ),
                ),
              ],
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          penaltyLabel: penaltyLabel,
          penaltyStyle: baseStyle.copyWith(
            color: homeWon ? winColor : lossColor,
            fontSize: (baseStyle.fontSize ?? 14) * 0.72,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _WorldCupScoreTextStack extends StatelessWidget {
  final Widget score;
  final String? penaltyLabel;
  final TextStyle? penaltyStyle;

  const _WorldCupScoreTextStack({
    required this.score,
    required this.penaltyLabel,
    required this.penaltyStyle,
  });

  @override
  Widget build(BuildContext context) {
    final penalty = penaltyLabel;
    if (penalty == null) return score;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        score,
        const SizedBox(height: 2),
        Text(
          penalty,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: penaltyStyle,
        ),
      ],
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
    final participants = _worldCupDisplayParticipantsForFixture(
      fixture,
      widget.officialMatch,
    );
    final status = _runtimeStatusForFixture(
      fixture,
      officialMatch: widget.officialMatch,
      now: widget.currentTime,
    );
    final displayScore = _displayScoreForFixture(fixture, widget.officialMatch);
    final hasDisplayScore =
        displayScore.homeScore != null && displayScore.awayScore != null;
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
                      _WorldCupScoreLine(
                        homeScore: displayScore.homeScore,
                        awayScore: displayScore.awayScore,
                        homePenaltyScore: displayScore.homePenaltyScore,
                        awayPenaltyScore: displayScore.awayPenaltyScore,
                        pendingLabel: l10n.worldCupScorePending,
                        applyResultColors: hasDisplayScore &&
                            status != _WorldCupFixtureRuntimeStatus.live,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w900,
                        ),
                        maxLines: 1,
                      ),
                    ],
                  );
                  return Row(
                    children: [
                      Expanded(
                        child: _CountryLabel(
                          country: participants.homeTeam,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: scoreColumn,
                      ),
                      Expanded(
                        child: _CountryLabel(
                          country: participants.awayTeam,
                          textAlign: TextAlign.center,
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
          participants: _worldCupDisplayParticipantsForFixture(
            widget.fixture,
            widget.officialMatch,
          ),
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
  final _WorldCupFixtureParticipants participants;
  final FifaAMatchDetail detail;

  const _WorldCupOfficialMatchRecords({
    required this.participants,
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
                _SmallPill(
                  label: _scorerLabel(l10n, participants.homeTeam, scorer),
                ),
              for (final scorer in detail.awayScorers)
                _SmallPill(
                  label: _scorerLabel(l10n, participants.awayTeam, scorer),
                ),
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
                      team: participants.homeTeam,
                      tactics: detail.homeTactics,
                      players: detail.homePlayers,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _WorldCupOfficialLineupCard(
                      team: participants.awayTeam,
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
                  _WorldCupClubLink(
                    club: club,
                    onMissingWebsiteTap: () => unawaited(
                      _openWorldCupClubInfo(
                        context,
                        team: team,
                        playerName: playerName,
                        club: club,
                        positionLabel: positionLabel,
                      ),
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

class _WorldCupClubLink extends StatelessWidget {
  final String club;
  final VoidCallback onMissingWebsiteTap;

  const _WorldCupClubLink({
    required this.club,
    required this.onMissingWebsiteTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final website = worldCupRosterClubWebsite(club);
    return Tooltip(
      message: website == null
          ? l10n.worldCupClubInfoOpenTooltip(club)
          : l10n.worldCupClubHomepageOpenTooltip(club),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (website == null) {
              onMissingWebsiteTap();
              return;
            }
            unawaited(launchUrl(website, mode: LaunchMode.inAppBrowserView));
          },
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            padding: const EdgeInsetsDirectional.fromSTEB(6, 3, 5, 3),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.22),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    club,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 3),
                Icon(
                  website == null
                      ? Icons.chevron_right_rounded
                      : Icons.open_in_new_rounded,
                  size: 13,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _openWorldCupClubInfo(
  BuildContext context, {
  required String team,
  required String playerName,
  required String club,
  required String positionLabel,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => _WorldCupClubInfoSheet(
      team: team,
      playerName: playerName,
      club: club,
      positionLabel: positionLabel,
    ),
  );
}

class _WorldCupClubInfoSheet extends StatelessWidget {
  final String team;
  final String playerName;
  final String club;
  final String positionLabel;

  const _WorldCupClubInfoSheet({
    required this.team,
    required this.playerName,
    required this.club,
    required this.positionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.48,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            Text(
              l10n.worldCupClubInfoTitle(club),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            _InfoGrid(
              items: [
                _InfoItem(l10n.worldCupPlayerProfileClubLabel, club),
                _InfoItem(l10n.worldCupPlayerProfilePlayerLabel, playerName),
                _InfoItem(
                  l10n.worldCupPlayerProfileTeamLabel,
                  _worldCupCountryLabelText(l10n, team),
                ),
                _InfoItem(
                  l10n.worldCupPlayerProfilePositionLabel,
                  positionLabel,
                ),
              ],
            ),
          ],
        ),
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
  final canonicalCountry = _worldCupCanonicalCountry(country);
  final flag = worldCupCountryFlag(canonicalCountry);
  final label = _worldCupCountryName(l10n, canonicalCountry);
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

String _worldCupCanonicalCountry(String country) {
  final key = _worldCupTeamKey(country);
  for (final fixture in worldCupFixtures) {
    if (_worldCupTeamKey(fixture.homeTeam) == key) return fixture.homeTeam;
    if (_worldCupTeamKey(fixture.awayTeam) == key) return fixture.awayTeam;
  }
  return country.trim();
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
  final bool compact;
  final VoidCallback onTap;

  const _TappableCountryLabel({
    required this.country,
    required this.onTap,
    required this.compact,
    this.textAlign = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final flag = worldCupCountryFlag(country);
    final countryName = _worldCupCountryName(l10n, country);
    final labelStyle =
        (compact ? theme.textTheme.labelMedium : theme.textTheme.labelLarge)
            ?.copyWith(
      fontWeight: FontWeight.w900,
      height: 1.08,
    );
    final flagText = flag.isEmpty
        ? null
        : Text(
            flag,
            maxLines: 1,
            style: theme.textTheme.bodyMedium,
          );
    final nameText = Flexible(
      child: Text(
        countryName,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: textAlign,
        style: labelStyle,
      ),
    );
    final labelChildren = <Widget>[
      if (flagText != null) ...[
        flagText,
        SizedBox(width: compact ? 3 : 4),
      ],
      nameText,
    ];
    return Tooltip(
      message: l10n.worldCupTeamRosterOpenTooltip(country),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: compact ? 38 : 42),
            child: Ink(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 6 : 8,
                vertical: compact ? 5 : 7,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      theme.colorScheme.outlineVariant.withValues(alpha: 0.8),
                ),
              ),
              child: Row(
                mainAxisAlignment: textAlign == TextAlign.center
                    ? MainAxisAlignment.center
                    : textAlign == TextAlign.right
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                children: labelChildren,
              ),
            ),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: headerStyle,
                ),
              ),
              SizedBox(
                width: 58,
                child: Text(
                  l10n.worldCupStandingsRecordColumn,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: headerStyle,
                ),
              ),
              SizedBox(
                width: 38,
                child: Text(
                  l10n.worldCupStandingsGoalDifferenceColumn,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: headerStyle,
                ),
              ),
              SizedBox(
                width: 38,
                child: Text(
                  l10n.worldCupStandingsGoalsForColumn,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
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
                  Expanded(
                    child: Text(
                      _worldCupCountryLabelText(l10n, standing.team),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 58,
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
                    width: 38,
                    child: Text(
                      _formatStandingGoalDifference(standing.goalDifference),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 38,
                    child: Text(
                      '${standing.goalsFor}',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
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
            ],
          ),
        ),
      ),
    );
  }
}

String _formatStandingGoalDifference(int value) {
  if (value > 0) return '+$value';
  return '$value';
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
  final String id;
  final String name;
  final String displayName;
  final String club;
  final _WorldCupRosterPosition position;

  const _WorldCupRosterPlayer({
    required this.id,
    required this.name,
    required this.displayName,
    required this.club,
    required this.position,
  });
}

class _WorldCupTeamRosterSheet extends StatefulWidget {
  final String initialTeam;
  final Map<String, FifaRankingEntry> rankingsByTeam;
  final List<WorldCupFixture> fixtures;
  final Map<int, FifaAMatchEntry> officialMatchesByFixtureNumber;
  final DateTime? currentTime;
  final VoidCallback onRankingTap;

  const _WorldCupTeamRosterSheet({
    required this.initialTeam,
    required this.rankingsByTeam,
    required this.fixtures,
    required this.officialMatchesByFixtureNumber,
    this.currentTime,
    required this.onRankingTap,
  });

  @override
  State<_WorldCupTeamRosterSheet> createState() =>
      _WorldCupTeamRosterSheetState();
}

class _WorldCupTeamRosterSheetState extends State<_WorldCupTeamRosterSheet> {
  final ScrollController _scrollController = ScrollController();
  late String _team;

  @override
  void initState() {
    super.initState();
    _team = widget.initialTeam;
  }

  void _openTeam(String team) {
    if (_worldCupTeamKey(team) == _worldCupTeamKey(_team)) return;
    setState(() {
      _team = team;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      unawaited(
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        ),
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final team = _team;
    final pool = worldCupRosterPoolForTeam(team);
    final players = _worldCupRosterPlayers(team, l10n);
    final ranking = widget.rankingsByTeam[team];
    final hasKnownPool = pool != null;
    final flag = worldCupCountryFlag(team);
    final officialSquadUri = worldCupOfficialSquadUri(team);
    final showRoundOf32Scenarios = !_roundOf32HasStarted(
      fixtures: widget.fixtures,
      officialMatchesByFixtureNumber: widget.officialMatchesByFixtureNumber,
      currentTime: widget.currentTime,
    );
    final knockoutPath = _worldCupTeamKnockoutPathForTeam(
      team: team,
      fixtures: widget.fixtures,
      officialMatchesByFixtureNumber: widget.officialMatchesByFixtureNumber,
    );
    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.9,
        child: ListView(
          controller: _scrollController,
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
              Row(
                children: [
                  Text(
                    l10n.newsFifaRankingTitle,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _FifaRankingPill(
                    ranking: ranking,
                    onTap: widget.onRankingTap,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            _WorldCupTeamMatchOverviewPanel(
              team: team,
              fixtures: widget.fixtures,
              officialMatchesByFixtureNumber:
                  widget.officialMatchesByFixtureNumber,
              currentTime: widget.currentTime,
              onTeamTap: _openTeam,
            ),
            if (knockoutPath != null) ...[
              const SizedBox(height: 14),
              _WorldCupTeamKnockoutPathPanel(
                path: knockoutPath,
                onTeamTap: _openTeam,
              ),
            ],
            if (showRoundOf32Scenarios) ...[
              const SizedBox(height: 14),
              _WorldCupRoundOf32ScenarioPanel(
                team: team,
                fixtures: widget.fixtures,
              ),
            ],
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
          _WorldCupPlayerProfileSheet(team: _team, player: player),
    );
  }
}

class _WorldCupTeamMatchOverviewPanel extends StatelessWidget {
  final String team;
  final List<WorldCupFixture> fixtures;
  final Map<int, FifaAMatchEntry> officialMatchesByFixtureNumber;
  final DateTime? currentTime;
  final ValueChanged<String> onTeamTap;

  const _WorldCupTeamMatchOverviewPanel({
    required this.team,
    required this.fixtures,
    required this.officialMatchesByFixtureNumber,
    this.currentTime,
    required this.onTeamTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final displayFixtures = [
      for (final fixture in fixtures)
        _fixtureWithDisplayScore(
          fixture,
          officialMatchesByFixtureNumber[fixture.matchNumber],
        ),
    ];
    final standing = _standingForTeam(team, displayFixtures);
    final teamFixtures = displayFixtures
        .where((fixture) => fixture.involvesCountry(team))
        .toList()
      ..sort((a, b) => a.kickoffLocal.compareTo(b.kickoffLocal));
    final points = standing?.points ?? 0;
    final record = standing == null
        ? l10n.worldCupStandingsRecordValue(0, 0, 0)
        : l10n.worldCupStandingsRecordValue(
            standing.wins,
            standing.draws,
            standing.losses,
          );

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
              Icon(
                Icons.query_stats_rounded,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.worldCupTeamMatchOverviewTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (standing != null) ...[
                const SizedBox(width: 8),
                _SmallPill(label: l10n.worldCupGroupStageLabel(standing.group)),
              ],
            ],
          ),
          const SizedBox(height: 10),
          _InfoGrid(
            items: [
              _InfoItem(l10n.worldCupTeamCurrentPointsLabel, '$points'),
              _InfoItem(l10n.worldCupStandingsRecordColumn, record),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l10n.worldCupTeamMatchHistoryTitle,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          for (final fixture in teamFixtures) ...[
            _WorldCupTeamMatchSummaryRow(
              team: team,
              fixture: fixture,
              officialMatch:
                  officialMatchesByFixtureNumber[fixture.matchNumber],
              currentTime: currentTime,
              onOpponentTap: onTeamTap,
            ),
            if (fixture != teamFixtures.last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  WorldCupGroupStanding? _standingForTeam(
    String team,
    List<WorldCupFixture> displayFixtures,
  ) {
    for (final standings in worldCupGroupStandings(
      fixtures: displayFixtures,
    ).values) {
      for (final standing in standings) {
        if (standing.team == team) return standing;
      }
    }
    return null;
  }
}

class _WorldCupTeamKnockoutPathPanel extends StatelessWidget {
  final _WorldCupTeamKnockoutPath path;
  final ValueChanged<String> onTeamTap;

  const _WorldCupTeamKnockoutPathPanel({
    required this.path,
    required this.onTeamTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
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
              Icon(
                Icons.emoji_events_outlined,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.worldCupKnockoutPathTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _SmallPill(label: _worldCupCountryName(l10n, path.team)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.worldCupKnockoutPathSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          for (final step in path.steps) ...[
            _WorldCupTeamKnockoutPathStepRow(
              step: step,
              onTeamTap: onTeamTap,
            ),
            if (step != path.steps.last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _WorldCupTeamKnockoutPathStepRow extends StatelessWidget {
  final _WorldCupTeamKnockoutPathStep step;
  final ValueChanged<String> onTeamTap;

  const _WorldCupTeamKnockoutPathStepRow({
    required this.step,
    required this.onTeamTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final accentColor =
        step.isEliminated ? theme.colorScheme.error : theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _fixtureStageLabel(l10n, step.fixture),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (step.isEliminated)
                _SmallPill(label: l10n.worldCupKnockoutPathEliminated)
              else if (step.opponentTeams.isEmpty)
                _SmallPill(label: l10n.worldCupKnockoutPathOpponentPending)
              else
                _SmallPill(
                  label: l10n.worldCupKnockoutPathCandidateCount(
                    step.opponentTeams.length,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (step.opponentTeams.isEmpty)
            Text(
              l10n.worldCupKnockoutPathOpponentPending,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final opponent in step.opponentTeams)
                  _WorldCupKnockoutOpponentChip(
                    team: opponent,
                    onTap: () => onTeamTap(opponent),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _WorldCupKnockoutOpponentChip extends StatelessWidget {
  final String team;
  final VoidCallback onTap;

  const _WorldCupKnockoutOpponentChip({
    required this.team,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final flag = worldCupCountryFlag(team);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (flag.isNotEmpty) ...[
                Text(flag, style: theme.textTheme.labelMedium),
                const SizedBox(width: 5),
              ],
              Text(
                _worldCupCountryName(l10n, team),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
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

class _WorldCupTeamKnockoutPath {
  final String team;
  final List<_WorldCupTeamKnockoutPathStep> steps;

  const _WorldCupTeamKnockoutPath({
    required this.team,
    required this.steps,
  });
}

class _WorldCupTeamKnockoutPathStep {
  final WorldCupFixture fixture;
  final List<String> opponentTeams;
  final bool isEliminated;

  const _WorldCupTeamKnockoutPathStep({
    required this.fixture,
    required this.opponentTeams,
    required this.isEliminated,
  });
}

_WorldCupTeamKnockoutPath? _worldCupTeamKnockoutPathForTeam({
  required String team,
  required List<WorldCupFixture> fixtures,
  required Map<int, FifaAMatchEntry> officialMatchesByFixtureNumber,
}) {
  final resolver = _WorldCupRoundOf32QualifiedSlotResolver(fixtures);
  final canonicalTeam = _worldCupCanonicalCountry(team);
  final sortedFixtures = fixtures.toList()
    ..sort((a, b) => a.kickoffUtc.compareTo(b.kickoffUtc));
  WorldCupFixture? currentFixture;
  for (final fixture in sortedFixtures) {
    if (fixture.stage != WorldCupStage.roundOf32) continue;
    final participants = _worldCupDisplayParticipantsForFixture(
      fixture,
      officialMatchesByFixtureNumber[fixture.matchNumber],
      qualifiedSlotResolver: resolver,
    );
    if (participants.involvesCountry(canonicalTeam)) {
      currentFixture = fixture;
      break;
    }
  }
  if (currentFixture == null) return null;

  final steps = <_WorldCupTeamKnockoutPathStep>[];
  String? pathSlot;
  while (currentFixture != null) {
    final officialMatch =
        officialMatchesByFixtureNumber[currentFixture.matchNumber];
    final participants = _worldCupDisplayParticipantsForFixture(
      currentFixture,
      officialMatch,
      qualifiedSlotResolver: resolver,
    );
    final teamSide = _worldCupTeamSideForPathFixture(
      team: canonicalTeam,
      pathSlot: pathSlot,
      fixture: currentFixture,
      participants: participants,
    );
    if (teamSide == null) break;
    final opponentSide = teamSide == _BracketSlotSide.home
        ? _BracketSlotSide.away
        : _BracketSlotSide.home;
    final opponentTeams = _worldCupCandidateTeamsForFixtureSide(
      fixture: currentFixture,
      side: opponentSide,
      fixtures: sortedFixtures,
      officialMatchesByFixtureNumber: officialMatchesByFixtureNumber,
      qualifiedSlotResolver: resolver,
    );
    final displayScore = _displayScoreForFixture(currentFixture, officialMatch);
    final resultSign = _homeResultSign(
      homeScore: displayScore.homeScore,
      awayScore: displayScore.awayScore,
      homePenaltyScore: displayScore.homePenaltyScore,
      awayPenaltyScore: displayScore.awayPenaltyScore,
    );
    var isEliminated = false;
    if (resultSign != null && resultSign != 0) {
      final homeWon = resultSign > 0;
      final teamWon = teamSide == _BracketSlotSide.home ? homeWon : !homeWon;
      isEliminated = !teamWon;
    }

    steps.add(
      _WorldCupTeamKnockoutPathStep(
        fixture: currentFixture,
        opponentTeams: opponentTeams,
        isEliminated: isEliminated,
      ),
    );
    if (isEliminated || currentFixture.stage == WorldCupStage.finalMatch) {
      break;
    }

    final winnerSlot = 'W${currentFixture.matchNumber}';
    currentFixture = _worldCupFixtureForBracketSlot(sortedFixtures, winnerSlot);
    pathSlot = winnerSlot;
  }

  if (steps.isEmpty) return null;
  return _WorldCupTeamKnockoutPath(
    team: canonicalTeam,
    steps: List.unmodifiable(steps),
  );
}

_BracketSlotSide? _worldCupTeamSideForPathFixture({
  required String team,
  required String? pathSlot,
  required WorldCupFixture fixture,
  required _WorldCupFixtureParticipants participants,
}) {
  final targetKey = _worldCupTeamKey(team);
  if (participants.homeDisplayTeams
      .any((candidate) => _worldCupTeamKey(candidate) == targetKey)) {
    return _BracketSlotSide.home;
  }
  if (participants.awayDisplayTeams
      .any((candidate) => _worldCupTeamKey(candidate) == targetKey)) {
    return _BracketSlotSide.away;
  }
  if (_worldCupTeamKey(fixture.homeTeam) == targetKey) {
    return _BracketSlotSide.home;
  }
  if (_worldCupTeamKey(fixture.awayTeam) == targetKey) {
    return _BracketSlotSide.away;
  }
  if (pathSlot != null) {
    final normalizedPathSlot = pathSlot.trim().toUpperCase();
    if (fixture.homeTeam.trim().toUpperCase() == normalizedPathSlot) {
      return _BracketSlotSide.home;
    }
    if (fixture.awayTeam.trim().toUpperCase() == normalizedPathSlot) {
      return _BracketSlotSide.away;
    }
  }
  return null;
}

List<String> _worldCupCandidateTeamsForFixtureSide({
  required WorldCupFixture fixture,
  required _BracketSlotSide side,
  required List<WorldCupFixture> fixtures,
  required Map<int, FifaAMatchEntry> officialMatchesByFixtureNumber,
  required _WorldCupRoundOf32QualifiedSlotResolver qualifiedSlotResolver,
  Set<String>? visitedSlots,
}) {
  final officialMatch = officialMatchesByFixtureNumber[fixture.matchNumber];
  final participants = _worldCupDisplayParticipantsForFixture(
    fixture,
    officialMatch,
    qualifiedSlotResolver: qualifiedSlotResolver,
  );
  final displayTeams = side == _BracketSlotSide.home
      ? participants.homeDisplayTeams
      : participants.awayDisplayTeams;
  if (displayTeams.isNotEmpty) {
    return _uniqueWorldCupTeams(displayTeams);
  }
  final slot =
      side == _BracketSlotSide.home ? fixture.homeTeam : fixture.awayTeam;
  return _worldCupCandidateTeamsForBracketSlot(
    slot: slot,
    fixtures: fixtures,
    officialMatchesByFixtureNumber: officialMatchesByFixtureNumber,
    qualifiedSlotResolver: qualifiedSlotResolver,
    visitedSlots: visitedSlots,
  );
}

List<String> _worldCupCandidateTeamsForBracketSlot({
  required String slot,
  required List<WorldCupFixture> fixtures,
  required Map<int, FifaAMatchEntry> officialMatchesByFixtureNumber,
  required _WorldCupRoundOf32QualifiedSlotResolver qualifiedSlotResolver,
  Set<String>? visitedSlots,
}) {
  final normalizedSlot = slot.trim();
  if (normalizedSlot.isEmpty) return const <String>[];
  final visited = visitedSlots ?? <String>{};
  final visitKey = normalizedSlot.toUpperCase();
  if (!visited.add(visitKey)) return const <String>[];

  final qualifiedTeams = qualifiedSlotResolver.teamsForSlot(normalizedSlot);
  if (qualifiedTeams.isNotEmpty) return _uniqueWorldCupTeams(qualifiedTeams);

  final directTeams = _worldCupSingleCountryCandidate(normalizedSlot);
  if (directTeams.isNotEmpty) return directTeams;

  final matchReference = RegExp(
    r'^([WL])([0-9]+)$',
  ).firstMatch(visitKey);
  if (matchReference == null) return const <String>[];

  final wantsWinner = matchReference.group(1) == 'W';
  final sourceMatchNumber = int.parse(matchReference.group(2)!);
  WorldCupFixture? sourceFixture;
  for (final fixture in fixtures) {
    if (fixture.matchNumber == sourceMatchNumber) {
      sourceFixture = fixture;
      break;
    }
  }
  if (sourceFixture == null) return const <String>[];

  final officialMatch =
      officialMatchesByFixtureNumber[sourceFixture.matchNumber];
  final displayScore = _displayScoreForFixture(sourceFixture, officialMatch);
  final resultSign = _homeResultSign(
    homeScore: displayScore.homeScore,
    awayScore: displayScore.awayScore,
    homePenaltyScore: displayScore.homePenaltyScore,
    awayPenaltyScore: displayScore.awayPenaltyScore,
  );
  if (resultSign != null && resultSign != 0) {
    final homeSideMatches = wantsWinner ? resultSign > 0 : resultSign < 0;
    return _worldCupCandidateTeamsForFixtureSide(
      fixture: sourceFixture,
      side: homeSideMatches ? _BracketSlotSide.home : _BracketSlotSide.away,
      fixtures: fixtures,
      officialMatchesByFixtureNumber: officialMatchesByFixtureNumber,
      qualifiedSlotResolver: qualifiedSlotResolver,
      visitedSlots: {...visited},
    );
  }

  return _uniqueWorldCupTeams([
    ..._worldCupCandidateTeamsForFixtureSide(
      fixture: sourceFixture,
      side: _BracketSlotSide.home,
      fixtures: fixtures,
      officialMatchesByFixtureNumber: officialMatchesByFixtureNumber,
      qualifiedSlotResolver: qualifiedSlotResolver,
      visitedSlots: {...visited},
    ),
    ..._worldCupCandidateTeamsForFixtureSide(
      fixture: sourceFixture,
      side: _BracketSlotSide.away,
      fixtures: fixtures,
      officialMatchesByFixtureNumber: officialMatchesByFixtureNumber,
      qualifiedSlotResolver: qualifiedSlotResolver,
      visitedSlots: {...visited},
    ),
  ]);
}

WorldCupFixture? _worldCupFixtureForBracketSlot(
  List<WorldCupFixture> fixtures,
  String slot,
) {
  final normalizedSlot = slot.trim().toUpperCase();
  for (final fixture in fixtures) {
    if (fixture.homeTeam.trim().toUpperCase() == normalizedSlot ||
        fixture.awayTeam.trim().toUpperCase() == normalizedSlot) {
      return fixture;
    }
  }
  return null;
}

List<String> _uniqueWorldCupTeams(Iterable<String> teams) {
  final seen = <String>{};
  final result = <String>[];
  for (final team in teams) {
    final canonicalTeam = _worldCupCanonicalCountry(team);
    final key = _worldCupTeamKey(canonicalTeam);
    if (key.isEmpty || !seen.add(key)) continue;
    result.add(canonicalTeam);
  }
  result.sort((a, b) => a.compareTo(b));
  return List.unmodifiable(result);
}

class _WorldCupRoundOf32ScenarioPanel extends StatelessWidget {
  final String team;
  final List<WorldCupFixture> fixtures;

  const _WorldCupRoundOf32ScenarioPanel({
    required this.team,
    required this.fixtures,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scenarios = worldCupRoundOf32PathScenariosForTeam(
      team,
      fixtures: fixtures,
    );
    if (scenarios.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Text(
          l10n.worldCupQualificationScenariosEmpty,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    final first = scenarios.first;
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
              Icon(
                Icons.account_tree_rounded,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.worldCupQualificationScenariosTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _SmallPill(label: l10n.worldCupGroupStageLabel(first.group)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _qualificationScenariosSubtitle(l10n, first),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.3,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _qualificationScenariosGuide(l10n, first),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          for (final scenario in scenarios) ...[
            _WorldCupQualificationScenarioRow(scenario: scenario),
            if (scenario != scenarios.last) const SizedBox(height: 8),
          ],
          const SizedBox(height: 10),
          Text(
            l10n.worldCupQualificationThirdPlaceNote,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorldCupQualificationScenarioRow extends StatelessWidget {
  final WorldCupQualificationPathScenario scenario;

  const _WorldCupQualificationScenarioRow({required this.scenario});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final accentColor = _qualificationScenarioAccentColor(theme, scenario);
    final opponentText = _qualificationOpponentText(l10n, scenario);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (scenario.picks.isEmpty)
                      _WorldCupQualificationStatusChip(scenario: scenario)
                    else
                      for (final pick in scenario.picks)
                        _WorldCupQualificationPickChip(pick: pick),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _WorldCupQualificationOutcomePill(
                scenario: scenario,
                color: accentColor,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${l10n.worldCupQualificationScenarioPoints(
              scenario.remainingPoints,
              scenario.finalPoints,
            )} · ${l10n.worldCupQualificationScenarioRankRange(
              scenario.bestRank,
              scenario.worstRank,
            )}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.3,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.worldCupQualificationScenarioCases(
              scenario.automaticAdvanceCases,
              scenario.thirdPlaceCases,
              scenario.eliminatedCases,
              scenario.totalCases,
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.3,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (scenario.remainingOtherMatches > 0 &&
              scenario.otherMatchPaths.isNotEmpty) ...[
            const SizedBox(height: 6),
            _WorldCupQualificationOtherMatches(scenario: scenario),
          ],
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                scenario.canAdvance
                    ? Icons.account_tree_rounded
                    : Icons.block_rounded,
                size: 16,
                color: accentColor,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  scenario.canAdvance
                      ? l10n.worldCupQualificationOpponentCandidates(
                          opponentText,
                        )
                      : l10n.worldCupQualificationNoOpponent,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scenario.canAdvance
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                    height: 1.3,
                    fontWeight: FontWeight.w800,
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

class _WorldCupQualificationOtherMatches extends StatelessWidget {
  final WorldCupQualificationPathScenario scenario;

  const _WorldCupQualificationOtherMatches({required this.scenario});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final waitingForOtherMatches =
        scenario.remainingMatches == 0 && scenario.remainingOtherMatches > 0;
    final directPaths = scenario.otherMatchPaths
        .where((path) => path.isAutomaticAdvance)
        .toList(growable: false);
    final thirdPlacePaths = scenario.otherMatchPaths
        .where((path) => path.isThirdPlaceRace)
        .toList(growable: false);
    final eliminatedPaths = scenario.otherMatchPaths
        .where((path) => path.isEliminated)
        .toList(growable: false);
    final sections =
        <({String label, List<WorldCupQualificationOtherMatchPath> paths})>[
      (
        label: l10n.worldCupQualificationOtherPathDirectSection,
        paths: directPaths,
      ),
      (
        label: l10n.worldCupQualificationOtherPathThirdSection,
        paths: thirdPlacePaths,
      ),
      (
        label: l10n.worldCupQualificationOtherPathOutSection,
        paths: eliminatedPaths,
      ),
    ].where((section) => section.paths.isNotEmpty).toList(growable: false);
    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 10),
          childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          dense: true,
          visualDensity: VisualDensity.compact,
          initiallyExpanded: scenario.remainingMatches == 0,
          leading: Icon(
            Icons.tune_rounded,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          title: Text(
            waitingForOtherMatches
                ? l10n.worldCupQualificationWaitingOtherMatchesTitle
                : l10n.worldCupQualificationOtherMatchesTitle(
                    scenario.otherMatchPaths.length,
                  ),
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          subtitle: Text(
            waitingForOtherMatches
                ? l10n.worldCupQualificationWaitingOtherMatchesSubtitle
                : l10n.worldCupQualificationOtherMatchesSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.25,
            ),
          ),
          children: [
            for (final section in sections) ...[
              _WorldCupQualificationOtherPathSection(
                label: section.label,
                paths: section.paths,
              ),
              if (section != sections.last) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _WorldCupQualificationOtherPathSection extends StatelessWidget {
  final String label;
  final List<WorldCupQualificationOtherMatchPath> paths;

  const _WorldCupQualificationOtherPathSection({
    required this.label,
    required this.paths,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.worldCupQualificationOtherPathSectionTitle(
            label,
            paths.length,
          ),
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        for (final path in paths) ...[
          _WorldCupQualificationOtherPathRow(path: path),
          if (path != paths.last) const SizedBox(height: 6),
        ],
      ],
    );
  }
}

class _WorldCupQualificationOtherPathRow extends StatelessWidget {
  final WorldCupQualificationOtherMatchPath path;

  const _WorldCupQualificationOtherPathRow({required this.path});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final color = _qualificationOtherPathColor(theme, path);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.worldCupQualificationOtherPathOutcome(
              path.rank,
              _qualificationOtherPathOutcomeLabel(l10n, path),
            ),
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (path.picks.isNotEmpty) ...[
            const SizedBox(height: 5),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: [
                for (final pick in path.picks)
                  _WorldCupQualificationOtherPickChip(pick: pick),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _WorldCupQualificationOtherPickChip extends StatelessWidget {
  final WorldCupQualificationOtherMatchPick pick;

  const _WorldCupQualificationOtherPickChip({required this.pick});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final result = _qualificationOtherMatchResultLabel(l10n, pick);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Text(
        l10n.worldCupQualificationOtherMatchPick(
          _worldCupCountryName(l10n, pick.homeTeam),
          _worldCupCountryName(l10n, pick.awayTeam),
          result,
        ),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _WorldCupQualificationStatusChip extends StatelessWidget {
  final WorldCupQualificationPathScenario scenario;

  const _WorldCupQualificationStatusChip({required this.scenario});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final color = _qualificationScenarioAccentColor(theme, scenario);
    final label = scenario.remainingGroupMatches == 0
        ? l10n.worldCupQualificationCompletePick
        : l10n.worldCupQualificationNoTeamMatchesPick;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _WorldCupQualificationPickChip extends StatelessWidget {
  final WorldCupQualificationMatchPick pick;

  const _WorldCupQualificationPickChip({required this.pick});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final color = _qualificationResultColor(theme, pick.result);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Text(
        l10n.worldCupQualificationMatchPick(
          _worldCupCountryName(l10n, pick.opponentTeam),
          _qualificationResultLabel(l10n, pick.result),
        ),
        style: theme.textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _WorldCupQualificationOutcomePill extends StatelessWidget {
  final WorldCupQualificationPathScenario scenario;
  final Color color;

  const _WorldCupQualificationOutcomePill({
    required this.scenario,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.36)),
      ),
      child: Text(
        _qualificationOutcomeLabel(l10n, scenario),
        style: theme.textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

Color _qualificationScenarioAccentColor(
  ThemeData theme,
  WorldCupQualificationPathScenario scenario,
) {
  if (scenario.guaranteesAutomaticAdvance) return theme.colorScheme.primary;
  if (scenario.automaticAdvanceCases > 0) return theme.colorScheme.tertiary;
  if (scenario.thirdPlaceCases > 0) return const Color(0xFF9A6A00);
  return theme.colorScheme.error;
}

Color _qualificationResultColor(
  ThemeData theme,
  WorldCupFixtureTeamResult result,
) {
  return switch (result) {
    WorldCupFixtureTeamResult.win => theme.colorScheme.primary,
    WorldCupFixtureTeamResult.draw => theme.colorScheme.tertiary,
    WorldCupFixtureTeamResult.loss => theme.colorScheme.error,
    WorldCupFixtureTeamResult.scheduled => theme.colorScheme.onSurfaceVariant,
  };
}

String _qualificationResultLabel(
  AppLocalizations l10n,
  WorldCupFixtureTeamResult result,
) {
  return switch (result) {
    WorldCupFixtureTeamResult.win => l10n.worldCupResultWin,
    WorldCupFixtureTeamResult.draw => l10n.worldCupResultDraw,
    WorldCupFixtureTeamResult.loss => l10n.worldCupResultLoss,
    WorldCupFixtureTeamResult.scheduled => l10n.worldCupResultPendingTeam,
  };
}

Color _qualificationOtherPathColor(
  ThemeData theme,
  WorldCupQualificationOtherMatchPath path,
) {
  if (path.isAutomaticAdvance) return theme.colorScheme.primary;
  if (path.isThirdPlaceRace) return const Color(0xFF9A6A00);
  return theme.colorScheme.error;
}

String _qualificationScenariosSubtitle(
  AppLocalizations l10n,
  WorldCupQualificationPathScenario scenario,
) {
  if (scenario.remainingMatches == 0) {
    final otherMatches = scenario.remainingOtherMatches;
    if (otherMatches > 0) {
      return l10n.worldCupQualificationScenariosNoTeamMatchesSubtitle(
        scenario.currentPoints,
        otherMatches,
      );
    }
    return l10n.worldCupQualificationScenariosCompleteSubtitle(
      scenario.currentPoints,
    );
  }
  if (scenario.remainingMatches == 1) {
    return l10n.worldCupQualificationScenariosOneMatchSubtitle(
      scenario.currentPoints,
    );
  }
  return l10n.worldCupQualificationScenariosSubtitle(
    scenario.currentPoints,
    scenario.remainingMatches,
  );
}

String _qualificationScenariosGuide(
  AppLocalizations l10n,
  WorldCupQualificationPathScenario scenario,
) {
  if (scenario.remainingMatches == 0) {
    return l10n.worldCupQualificationScenariosNoTeamMatchesGuide;
  }
  return l10n.worldCupQualificationScenariosGuide;
}

String _qualificationOtherPathOutcomeLabel(
  AppLocalizations l10n,
  WorldCupQualificationOtherMatchPath path,
) {
  if (path.isAutomaticAdvance) return l10n.worldCupQualificationOutcomeAuto;
  if (path.isThirdPlaceRace) return l10n.worldCupQualificationOutcomeThird;
  return l10n.worldCupQualificationOutcomeOut;
}

String _qualificationOtherMatchResultLabel(
  AppLocalizations l10n,
  WorldCupQualificationOtherMatchPick pick,
) {
  return switch (pick.resultForHomeTeam) {
    WorldCupFixtureTeamResult.win =>
      l10n.worldCupQualificationOtherMatchWinResult(
        _worldCupCountryName(l10n, pick.homeTeam),
      ),
    WorldCupFixtureTeamResult.draw =>
      l10n.worldCupQualificationOtherMatchDrawResult,
    WorldCupFixtureTeamResult.loss =>
      l10n.worldCupQualificationOtherMatchWinResult(
        _worldCupCountryName(l10n, pick.awayTeam),
      ),
    WorldCupFixtureTeamResult.scheduled => l10n.worldCupResultPendingTeam,
  };
}

String _qualificationOutcomeLabel(
  AppLocalizations l10n,
  WorldCupQualificationPathScenario scenario,
) {
  if (scenario.guaranteesAutomaticAdvance) {
    return l10n.worldCupQualificationOutcomeAuto;
  }
  if (scenario.automaticAdvanceCases > 0) {
    return l10n.worldCupQualificationOutcomePossible;
  }
  if (scenario.thirdPlaceCases > 0) {
    return l10n.worldCupQualificationOutcomeThird;
  }
  return l10n.worldCupQualificationOutcomeOut;
}

String _qualificationOpponentText(
  AppLocalizations l10n,
  WorldCupQualificationPathScenario scenario,
) {
  final seen = <String>{};
  final labels = <String>[];
  for (final path in scenario.opponentPaths) {
    final slot = _worldCupBracketSlotLabel(l10n, path.opponentSlot);
    final countries = path.opponentTeams
        .map((team) => _worldCupCountryName(l10n, team))
        .join(l10n.worldCupQualificationOpponentTeamSeparator);
    final label = countries.isEmpty
        ? l10n.worldCupQualificationOpponentCandidate(slot)
        : l10n.worldCupQualificationOpponentCandidateWithCountries(
            slot,
            countries,
          );
    if (seen.add(label)) labels.add(label);
  }
  return labels.join(l10n.worldCupQualificationOpponentSeparator);
}

class _WorldCupTeamMatchSummaryRow extends StatelessWidget {
  final String team;
  final WorldCupFixture fixture;
  final FifaAMatchEntry? officialMatch;
  final DateTime? currentTime;
  final ValueChanged<String> onOpponentTap;

  const _WorldCupTeamMatchSummaryRow({
    required this.team,
    required this.fixture,
    required this.officialMatch,
    this.currentTime,
    required this.onOpponentTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final opponent =
        fixture.homeTeam == team ? fixture.awayTeam : fixture.homeTeam;
    final status = _runtimeStatusForFixture(
      fixture,
      officialMatch: officialMatch,
      now: currentTime,
    );
    final displayScore = _displayScoreForFixture(fixture, officialMatch);
    final hasDisplayScore =
        displayScore.homeScore != null && displayScore.awayScore != null;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.45,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onOpponentTap(opponent),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(6, 5, 4, 5),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _CountryLabel(country: opponent),
                            const SizedBox(height: 4),
                            Text(
                              '${l10n.worldCupMatchNumber(fixture.matchNumber)} · '
                              '${_fixtureStageLabel(l10n, fixture)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _WorldCupScoreLine(
            homeScore: displayScore.homeScore,
            awayScore: displayScore.awayScore,
            homePenaltyScore: displayScore.homePenaltyScore,
            awayPenaltyScore: displayScore.awayPenaltyScore,
            pendingLabel: l10n.worldCupScorePending,
            applyResultColors:
                hasDisplayScore && status != _WorldCupFixtureRuntimeStatus.live,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
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
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _SmallPill(label: '${players.length}'),
            ],
          ),
          const SizedBox(height: 8),
          Column(
            children: [
              for (var index = 0; index < players.length; index += 1) ...[
                Builder(
                  builder: (context) {
                    final player = players[index];
                    return _RosterPlayerRow(
                      team: team,
                      player: player,
                      onPlayerTap: () => onPlayerTap(player),
                    );
                  },
                ),
                if (index != players.length - 1)
                  Divider(
                    height: 14,
                    color: theme.colorScheme.outlineVariant,
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _RosterPlayerRow extends StatelessWidget {
  final String team;
  final _WorldCupRosterPlayer player;
  final VoidCallback onPlayerTap;

  const _RosterPlayerRow({
    required this.team,
    required this.player,
    required this.onPlayerTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final color = _positionColor(theme, player.position);
    final club = _worldCupPlayerClubLabel(l10n, player);
    final positionLabel = _worldCupRosterPositionLabel(l10n, player.position);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(6, 7, 4, 7),
      child: Row(
        children: [
          Container(
            width: 34,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: color.withValues(alpha: 0.30)),
            ),
            child: Text(
              positionLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
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
                if (club.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: _WorldCupClubLink(
                        club: club,
                        onMissingWebsiteTap: () => unawaited(
                          _openWorldCupClubInfo(
                            context,
                            team: team,
                            playerName: player.displayName,
                            club: club,
                            positionLabel: positionLabel,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: l10n.worldCupPlayerProfileTitle(player.displayName),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPlayerTap,
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ],
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
    final club = _worldCupPlayerClubLabel(l10n, player);
    final positionLabel = _worldCupRosterPositionLabel(l10n, player.position);
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
                if (club.isNotEmpty)
                  _InfoItem(l10n.worldCupPlayerProfileClubLabel, club),
              ],
            ),
            if (club.isNotEmpty) ...[
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: _WorldCupClubLink(
                  club: club,
                  onMissingWebsiteTap: () => unawaited(
                    _openWorldCupClubInfo(
                      context,
                      team: team,
                      playerName: player.displayName,
                      club: club,
                      positionLabel: positionLabel,
                    ),
                  ),
                ),
              ),
            ],
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
        l10n,
      ),
      ..._playersFromNames(
        team,
        pool.defenders,
        _WorldCupRosterPosition.defender,
        l10n,
      ),
      ..._playersFromNames(
        team,
        pool.midfielders,
        _WorldCupRosterPosition.midfielder,
        l10n,
      ),
      ..._playersFromNames(
        team,
        pool.forwards,
        _WorldCupRosterPosition.forward,
        l10n,
      ),
    ];
  }
  return <_WorldCupRosterPlayer>[
    _WorldCupRosterPlayer(
      id: _worldCupRosterFallbackPlayerId(
        team,
        _WorldCupRosterPosition.goalkeeper,
        1,
      ),
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
    ),
    for (var index = 0; index < 4; index++)
      _WorldCupRosterPlayer(
        id: _worldCupRosterFallbackPlayerId(
          team,
          _WorldCupRosterPosition.defender,
          index + 1,
        ),
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
      ),
    for (var index = 0; index < 3; index++)
      _WorldCupRosterPlayer(
        id: _worldCupRosterFallbackPlayerId(
          team,
          _WorldCupRosterPosition.midfielder,
          index + 1,
        ),
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
      ),
    for (var index = 0; index < 3; index++)
      _WorldCupRosterPlayer(
        id: _worldCupRosterFallbackPlayerId(
          team,
          _WorldCupRosterPosition.forward,
          index + 1,
        ),
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
      ),
  ];
}

List<_WorldCupRosterPlayer> _playersFromNames(
  String team,
  List<String> names,
  _WorldCupRosterPosition position,
  AppLocalizations l10n,
) {
  return [
    for (var index = 0; index < names.length; index += 1)
      _WorldCupRosterPlayer(
        id: _worldCupRosterPlayerId(team, position, names[index]),
        name: names[index],
        displayName: worldCupRosterDisplayNameForPlayer(
          team,
          names[index],
          l10n.localeName,
        ),
        club: worldCupRosterClubForPlayer(team, names[index]),
        position: position,
      ),
  ];
}

String _worldCupRosterPlayerId(
  String team,
  _WorldCupRosterPosition position,
  String name,
) {
  return [
    team.trim().toLowerCase(),
    position.name,
    name.trim().toLowerCase(),
  ].join('|');
}

String _worldCupRosterFallbackPlayerId(
  String team,
  _WorldCupRosterPosition position,
  int number,
) {
  return [
    team.trim().toLowerCase(),
    position.name,
    number.toString(),
  ].join('|');
}

Color _positionColor(ThemeData theme, _WorldCupRosterPosition position) {
  return switch (position) {
    _WorldCupRosterPosition.goalkeeper => theme.colorScheme.tertiary,
    _WorldCupRosterPosition.defender => const Color(0xFF2A9D8F),
    _WorldCupRosterPosition.midfielder => theme.colorScheme.primary,
    _WorldCupRosterPosition.forward => theme.colorScheme.error,
  };
}

typedef _BracketSlotBuilder = _BracketSlotData Function(
  WorldCupFixture fixture,
  String slot,
  _BracketSlotSide side,
);

typedef _BracketMatchScoreBuilder = _BracketMatchScoreData Function(
  WorldCupFixture fixture,
);

enum _BracketSlotSide { home, away }

Future<bool> _shareWorldCupTournamentBracketImage({
  required BuildContext context,
  required List<_TournamentBracketRound> rounds,
  required _BracketSlotBuilder slotBuilder,
  required _BracketMatchScoreBuilder scoreBuilder,
}) async {
  if (!context.mounted) return false;
  final l10n = AppLocalizations.of(context)!;
  final pngBytes = await captureWidgetPng(
    context,
    size: _worldCupTournamentShareImageSize,
    pixelRatio: _worldCupTournamentShareImagePixelRatio,
    child: _WorldCupTournamentBracketShareImage(
      rounds: rounds,
      slotBuilder: slotBuilder,
      scoreBuilder: scoreBuilder,
    ),
  );
  await sharePngImage(
    pngImage: pngBytes,
    filename: timestampedImageFilename('world-cup-bracket'),
    title: l10n.worldCupTournamentTitle,
  );
  return true;
}

class _WorldCupTournamentBracketFullScreen extends StatefulWidget {
  final List<_TournamentBracketRound> rounds;
  final _BracketSlotBuilder slotBuilder;
  final _BracketMatchScoreBuilder scoreBuilder;

  const _WorldCupTournamentBracketFullScreen({
    required this.rounds,
    required this.slotBuilder,
    required this.scoreBuilder,
  });

  @override
  State<_WorldCupTournamentBracketFullScreen> createState() =>
      _WorldCupTournamentBracketFullScreenState();
}

class _WorldCupTournamentBracketFullScreenState
    extends State<_WorldCupTournamentBracketFullScreen> {
  bool _imageShareInProgress = false;

  Future<void> _shareTournamentImage() async {
    if (_imageShareInProgress) return;
    setState(() => _imageShareInProgress = true);
    try {
      final shared = await _shareWorldCupTournamentBracketImage(
        context: context,
        rounds: widget.rounds,
        slotBuilder: widget.slotBuilder,
        scoreBuilder: widget.scoreBuilder,
      );
      if (!mounted || !shared) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.worldCupTournamentImageExportedSnack)),
      );
    } catch (error, stackTrace) {
      debugPrint('World Cup bracket image share failed: $error\n$stackTrace');
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.worldCupTournamentImageExportFailedSnack)),
      );
    } finally {
      if (mounted) {
        setState(() => _imageShareInProgress = false);
      } else {
        _imageShareInProgress = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.worldCupTournamentTitle),
        actions: [
          AppBarActionButton.label(
            key: const ValueKey('world-cup-tournament-image-button'),
            tooltip: l10n.worldCupTournamentImageTooltip,
            onPressed: _imageShareInProgress
                ? null
                : () => unawaited(_shareTournamentImage()),
            icon: const Icon(Icons.ios_share_rounded),
            label: l10n.worldCupImageAction,
            maxLabelWidth: 68,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: _WorldCupTournamentBracket(
            rounds: widget.rounds,
            slotBuilder: widget.slotBuilder,
            scoreBuilder: widget.scoreBuilder,
            fullScreen: true,
          ),
        ),
      ),
    );
  }
}

class _WorldCupTournamentBracket extends StatefulWidget {
  final List<_TournamentBracketRound> rounds;
  final _BracketSlotBuilder slotBuilder;
  final _BracketMatchScoreBuilder scoreBuilder;
  final bool fullScreen;
  final VoidCallback? onOpenFullScreen;

  const _WorldCupTournamentBracket({
    required this.rounds,
    required this.slotBuilder,
    required this.scoreBuilder,
    this.fullScreen = false,
    this.onOpenFullScreen,
  });

  @override
  State<_WorldCupTournamentBracket> createState() =>
      _WorldCupTournamentBracketState();
}

class _WorldCupTournamentBracketState
    extends State<_WorldCupTournamentBracket> {
  static const _minScale = 0.32;
  static const _maxScale = 2.4;
  static const _zoomStep = 1.22;

  final TransformationController _transformationController =
      TransformationController();

  String? _layoutSignature;
  Matrix4? _initialMatrix;
  Size _lastViewportSize = const Size(360, 420);

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(_handleTransformChanged);
  }

  @override
  void dispose() {
    _transformationController.removeListener(_handleTransformChanged);
    _transformationController.dispose();
    super.dispose();
  }

  double get _currentScale => _transformationController.value
      .getMaxScaleOnAxis()
      .clamp(
        _minScale,
        _maxScale,
      )
      .toDouble();

  void _handleTransformChanged() {
    if (mounted) setState(() {});
  }

  void _scheduleInitialTransform({
    required double contentWidth,
    required double viewportWidth,
    required bool compact,
  }) {
    final signature =
        '${contentWidth.toStringAsFixed(1)}:${viewportWidth.toStringAsFixed(1)}'
        ':$compact';
    if (_layoutSignature == signature) return;
    _layoutSignature = signature;
    final initialScale = (compact ? 0.52 : 0.72)
        .clamp(
          _minScale,
          _maxScale,
        )
        .toDouble();
    final initialOffsetX = math.min(
      0.0,
      (viewportWidth - contentWidth * initialScale) / 2,
    );
    final initialMatrix = _matrixForTransform(
      scale: initialScale,
      offset: Offset(initialOffsetX, 0),
    );
    _initialMatrix = Matrix4.copy(initialMatrix);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _layoutSignature != signature) return;
      _transformationController.value = Matrix4.copy(initialMatrix);
    });
  }

  void _zoomBy(double factor) {
    final currentScale = _currentScale;
    final nextScale = (currentScale * factor)
        .clamp(
          _minScale,
          _maxScale,
        )
        .toDouble();
    if ((nextScale - currentScale).abs() < 0.001) return;

    final translation = _transformationController.value.getTranslation();
    final focalPoint = Offset(
      _lastViewportSize.width / 2,
      _lastViewportSize.height / 2,
    );
    final worldFocalPoint = Offset(
      (focalPoint.dx - translation.x) / currentScale,
      (focalPoint.dy - translation.y) / currentScale,
    );
    final nextOffset = Offset(
      focalPoint.dx - worldFocalPoint.dx * nextScale,
      focalPoint.dy - worldFocalPoint.dy * nextScale,
    );
    _transformationController.value = _matrixForTransform(
      scale: nextScale,
      offset: nextOffset,
    );
  }

  void _resetZoom() {
    final matrix = _initialMatrix;
    _transformationController.value =
        matrix == null ? Matrix4.identity() : Matrix4.copy(matrix);
  }

  Matrix4 _matrixForTransform({
    required double scale,
    required Offset offset,
  }) {
    final matrix = Matrix4.identity();
    matrix.setEntry(0, 0, scale);
    matrix.setEntry(1, 1, scale);
    matrix.setEntry(2, 2, scale);
    matrix.setEntry(0, 3, offset.dx);
    matrix.setEntry(1, 3, offset.dy);
    return matrix;
  }

  Widget _zoomButton({
    required String tooltip,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    final theme = Theme.of(context);
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon),
      constraints: const BoxConstraints.tightFor(width: 38, height: 38),
      padding: EdgeInsets.zero,
      style: IconButton.styleFrom(
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        foregroundColor: theme.colorScheme.primary,
        disabledForegroundColor: theme.colorScheme.onSurfaceVariant.withValues(
          alpha: 0.38,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final currentScale = _currentScale;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: _SectionTitle(
                icon: Icons.account_tree_rounded,
                title: l10n.worldCupTournamentTitle,
              ),
            ),
            const SizedBox(width: 8),
            Wrap(
              spacing: 4,
              children: [
                _zoomButton(
                  tooltip: l10n.worldCupTournamentZoomOut,
                  icon: Icons.zoom_out_rounded,
                  onPressed: currentScale > _minScale + 0.01
                      ? () => _zoomBy(1 / _zoomStep)
                      : null,
                ),
                _zoomButton(
                  tooltip: l10n.worldCupTournamentZoomReset,
                  icon: Icons.restart_alt_rounded,
                  onPressed: _resetZoom,
                ),
                _zoomButton(
                  tooltip: l10n.worldCupTournamentZoomIn,
                  icon: Icons.zoom_in_rounded,
                  onPressed: currentScale < _maxScale - 0.01
                      ? () => _zoomBy(_zoomStep)
                      : null,
                ),
                if (widget.onOpenFullScreen != null)
                  _zoomButton(
                    tooltip: l10n.worldCupTournamentOpenFullScreen,
                    icon: Icons.open_in_full_rounded,
                    onPressed: widget.onOpenFullScreen,
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          l10n.worldCupTournamentPlanBody,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 14),
        if (widget.fullScreen)
          Expanded(child: _buildBracketViewport(context))
        else
          _buildBracketViewport(context),
      ],
    );
    return widget.fullScreen ? content : WatchCartCard(child: content);
  }

  Widget _buildBracketViewport(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        final slotWidth = compact ? 148.0 : 166.0;
        const spacing = 10.0;
        final viewportHeight =
            widget.fullScreen && constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : compact
                    ? 390.0
                    : 470.0;
        final widestRoundCount = widget.rounds
            .map((round) => round.fixtures.length)
            .fold<int>(1, (max, count) => count > max ? count : max);
        final bracketWidth = math.max(
          constraints.maxWidth,
          widestRoundCount * slotWidth + (widestRoundCount - 1) * spacing,
        );
        final contentWidth = bracketWidth + 24;
        _lastViewportSize = Size(constraints.maxWidth, viewportHeight);
        _scheduleInitialTransform(
          contentWidth: contentWidth,
          viewportWidth: constraints.maxWidth,
          compact: compact,
        );
        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: viewportHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.28,
              ),
              border: Border.all(
                color: theme.colorScheme.outlineVariant,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: _minScale,
              maxScale: _maxScale,
              boundaryMargin: const EdgeInsets.all(220),
              constrained: false,
              child: SizedBox(
                width: contentWidth,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: bracketWidth,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var index = 0;
                            index < widget.rounds.length;
                            index += 1)
                          _TournamentBracketRoundRow(
                            round: widget.rounds[index],
                            slotBuilder: widget.slotBuilder,
                            scoreBuilder: widget.scoreBuilder,
                            slotWidth: slotWidth,
                            spacing: spacing,
                            compact: compact,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WorldCupTournamentBracketShareImage extends StatelessWidget {
  final List<_TournamentBracketRound> rounds;
  final _BracketSlotBuilder slotBuilder;
  final _BracketMatchScoreBuilder scoreBuilder;

  const _WorldCupTournamentBracketShareImage({
    required this.rounds,
    required this.slotBuilder,
    required this.scoreBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    const slotWidth = 166.0;
    const spacing = 10.0;
    final widestRoundCount = rounds
        .map((round) => round.fixtures.length)
        .fold<int>(1, (max, count) => count > max ? count : max);
    final bracketWidth =
        widestRoundCount * slotWidth + (widestRoundCount - 1) * spacing;
    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.all(42),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.account_tree_rounded,
            title: l10n.worldCupTournamentTitle,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.28,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: FittedBox(
                alignment: Alignment.topCenter,
                fit: BoxFit.contain,
                child: SizedBox(
                  width: bracketWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var index = 0; index < rounds.length; index += 1)
                        _TournamentBracketRoundRow(
                          round: rounds[index],
                          slotBuilder: slotBuilder,
                          scoreBuilder: scoreBuilder,
                          slotWidth: slotWidth,
                          spacing: spacing,
                          compact: true,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TournamentBracketRoundRow extends StatelessWidget {
  final _TournamentBracketRound round;
  final _BracketSlotBuilder slotBuilder;
  final _BracketMatchScoreBuilder scoreBuilder;
  final double slotWidth;
  final double spacing;
  final bool compact;

  const _TournamentBracketRoundRow({
    required this.round,
    required this.slotBuilder,
    required this.scoreBuilder,
    required this.slotWidth,
    required this.spacing,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Text(
            round.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            round.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var index = 0;
                  index < round.fixtures.length;
                  index += 1) ...[
                SizedBox(
                  width: slotWidth,
                  child: _BracketMatchCard(
                    fixture: round.fixtures[index],
                    homeSlot: slotBuilder(
                      round.fixtures[index],
                      round.fixtures[index].homeTeam,
                      _BracketSlotSide.home,
                    ),
                    awaySlot: slotBuilder(
                      round.fixtures[index],
                      round.fixtures[index].awayTeam,
                      _BracketSlotSide.away,
                    ),
                    scoreData: scoreBuilder(round.fixtures[index]),
                    compact: compact,
                  ),
                ),
                if (index != round.fixtures.length - 1)
                  SizedBox(width: spacing),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _TournamentBracketRound {
  final String title;
  final String subtitle;
  final List<WorldCupFixture> fixtures;

  const _TournamentBracketRound({
    required this.title,
    required this.subtitle,
    required this.fixtures,
  });
}

class _BracketMatchCard extends StatelessWidget {
  final WorldCupFixture fixture;
  final _BracketSlotData homeSlot;
  final _BracketSlotData awaySlot;
  final _BracketMatchScoreData scoreData;
  final bool compact;

  const _BracketMatchCard({
    required this.fixture,
    required this.homeSlot,
    required this.awaySlot,
    required this.scoreData,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final kickoffText = formatKickoffWithKoreaTime(context, fixture.kickoffUtc);
    return Container(
      padding: EdgeInsets.all(compact ? 9 : 12),
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
              Expanded(
                child: Text(
                  kickoffText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.left,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 8 : 10),
          _BracketTeamSlot(
            slot: homeSlot,
            result: scoreData.homeResult,
            compact: compact,
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: compact ? 5 : 7),
            child: _BracketScoreDivider(
              scoreData: scoreData,
              pendingLabel: l10n.worldCupVersusShort,
              compact: compact,
            ),
          ),
          _BracketTeamSlot(
            slot: awaySlot,
            result: scoreData.awayResult,
            compact: compact,
          ),
          if (!compact) ...[
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
        ],
      ),
    );
  }
}

class _BracketTeamSlot extends StatelessWidget {
  final _BracketSlotData slot;
  final WorldCupFixtureTeamResult result;
  final bool compact;

  const _BracketTeamSlot({
    required this.slot,
    this.result = WorldCupFixtureTeamResult.scheduled,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: compact ? 6 : 8,
          height: compact ? 6 : 8,
          margin: EdgeInsets.only(top: compact ? 6 : 7),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: compact ? 6 : 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      slot.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: (compact
                              ? theme.textTheme.labelSmall
                              : theme.textTheme.titleSmall)
                          ?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (result != WorldCupFixtureTeamResult.scheduled) ...[
                    SizedBox(width: compact ? 4 : 6),
                    _BracketResultBadge(
                      result: result,
                      compact: compact,
                    ),
                  ],
                ],
              ),
              if (slot.showDetail && slot.detail != null) ...[
                const SizedBox(height: 2),
                Text(
                  slot.detail!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
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

class _BracketScoreDivider extends StatelessWidget {
  final _BracketMatchScoreData scoreData;
  final String pendingLabel;
  final bool compact;

  const _BracketScoreDivider({
    required this.scoreData,
    required this.pendingLabel,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scoreStyle =
        (compact ? theme.textTheme.labelMedium : theme.textTheme.titleSmall)
            ?.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w900,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Divider(color: theme.colorScheme.outlineVariant),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: compact ? 40 : 48,
            maxWidth: compact ? 72 : 84,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: _WorldCupScoreLine(
              homeScore: scoreData.homeScore,
              awayScore: scoreData.awayScore,
              homePenaltyScore: scoreData.homePenaltyScore,
              awayPenaltyScore: scoreData.awayPenaltyScore,
              pendingLabel: pendingLabel,
              applyResultColors: scoreData.applyResultColors,
              style: scoreStyle,
              maxLines: 1,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: theme.colorScheme.outlineVariant),
        ),
      ],
    );
  }
}

class _BracketResultBadge extends StatelessWidget {
  final WorldCupFixtureTeamResult result;
  final bool compact;

  const _BracketResultBadge({
    required this.result,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final color = _qualificationResultColor(theme, result);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 4 : 5,
        vertical: compact ? 1 : 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(
        _qualificationResultLabel(l10n, result),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontSize: compact ? 9 : 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _BracketSlotData {
  final String label;
  final String? detail;
  final bool showDetail;

  const _BracketSlotData({
    required this.label,
    this.detail,
    this.showDetail = false,
  });
}

class _BracketMatchScoreData {
  final int? homeScore;
  final int? awayScore;
  final int? homePenaltyScore;
  final int? awayPenaltyScore;
  final bool applyResultColors;
  final WorldCupFixtureTeamResult homeResult;
  final WorldCupFixtureTeamResult awayResult;

  const _BracketMatchScoreData({
    required this.homeScore,
    required this.awayScore,
    required this.homePenaltyScore,
    required this.awayPenaltyScore,
    required this.applyResultColors,
    required this.homeResult,
    required this.awayResult,
  });
}

class _WorldCupRoundOf32QualifiedSlotResolver {
  final Map<String, List<WorldCupGroupStanding>> standingsByGroup;
  final Set<String> completedGroups;
  final Map<String, String> qualifiedThirdPlaceTeamsByGroup;

  _WorldCupRoundOf32QualifiedSlotResolver(List<WorldCupFixture> fixtures)
      : standingsByGroup = worldCupGroupStandings(fixtures: fixtures),
        completedGroups = _completedWorldCupGroups(fixtures),
        qualifiedThirdPlaceTeamsByGroup = {
          for (final standing
              in worldCupBestThirdPlaceStandings(fixtures: fixtures))
            standing.group: standing.team,
        };

  List<String> teamsForSlot(String slot) {
    final normalizedSlot = slot.trim().toUpperCase();
    final groupRankMatch = RegExp(
      r'^([12])([A-L])$',
    ).firstMatch(normalizedSlot);
    if (groupRankMatch != null) {
      final rank = int.parse(groupRankMatch.group(1)!);
      final group = groupRankMatch.group(2)!;
      if (!completedGroups.contains(group)) return const <String>[];
      final standings = standingsByGroup[group];
      if (standings == null || standings.length < rank) {
        return const <String>[];
      }
      return <String>[standings[rank - 1].team];
    }

    final thirdPlaceMatch = RegExp(
      r'^3([A-L](?:/[A-L])*)$',
    ).firstMatch(normalizedSlot);
    if (thirdPlaceMatch != null) {
      final groups = thirdPlaceMatch.group(1)!.split('/');
      final teams = <String>[];
      for (final group in groups) {
        final team = qualifiedThirdPlaceTeamsByGroup[group];
        if (team != null) teams.add(team);
      }
      return List<String>.unmodifiable(teams);
    }

    return const <String>[];
  }
}

Set<String> _completedWorldCupGroups(List<WorldCupFixture> fixtures) {
  final groups = <String>{
    for (final fixture in fixtures)
      if (fixture.isGroupStage && fixture.group != null) fixture.group!,
  };
  return {
    for (final group in groups)
      if (worldCupGroupComplete(group, fixtures: fixtures)) group,
  };
}

String _worldCupBracketSlotLabel(AppLocalizations l10n, String slot) {
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

String _worldCupTournamentSlotLabel(AppLocalizations l10n, String slot) {
  final normalizedSlot = slot.trim();
  if (RegExp(r'^[123][A-L](?:/[A-L])*$').hasMatch(normalizedSlot)) {
    return l10n.worldCupBracketPendingTeam;
  }
  final matchReference = RegExp(r'^([WL])([0-9]+)$').firstMatch(
    normalizedSlot,
  );
  if (matchReference != null) {
    return matchReference.group(1) == 'W'
        ? l10n.worldCupBracketPendingWinner
        : l10n.worldCupBracketPendingLoser;
  }
  return _worldCupCountryName(l10n, slot);
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

class _FifaRankingPill extends StatelessWidget {
  final FifaRankingEntry ranking;
  final VoidCallback onTap;

  const _FifaRankingPill({
    required this.ranking,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Tooltip(
      message: l10n.fifaHubAppBarTitle,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _fifaRankingCompactLabel(l10n, ranking),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 3),
                Icon(
                  Icons.open_in_new_rounded,
                  size: 13,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
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
