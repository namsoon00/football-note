import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:football_note/gen/app_localizations.dart';

import '../../application/league_fixture_reminder_service.dart';
import '../../application/league_standings_service.dart';
import '../../application/settings_service.dart';
import '../../domain/entities/league_standings.dart';
import '../../domain/repositories/option_repository.dart';
import '../widgets/app_background.dart';
import '../widgets/app_page_route.dart';

class LeagueStandingsScreen extends StatefulWidget {
  final LeagueStandingsType initialType;
  final LeagueStandingsService? service;
  final LeagueFixtureReminderService? reminderService;
  final OptionRepository? optionRepository;
  final SettingsService? settingsService;

  const LeagueStandingsScreen({
    super.key,
    this.initialType = LeagueStandingsType.kLeague1,
    this.service,
    this.reminderService,
    this.optionRepository,
    this.settingsService,
  });

  @override
  State<LeagueStandingsScreen> createState() => _LeagueStandingsScreenState();
}

class _LeagueStandingsScreenState extends State<LeagueStandingsScreen> {
  static const String _lastSelectedLeagueKey =
      'league_standings_last_selected_type_v1';
  static const String _favoriteFixtureFilterKey =
      'league_standings_favorite_fixture_filter_types_v1';
  late final LeagueStandingsService _service;
  late final bool _ownsService;
  late final LeagueFixtureReminderService? _reminderService;
  late final PageController _pageController;
  late LeagueStandingsType _selectedType;
  late String _languageCode;
  final Map<LeagueStandingsType, _LeagueOverviewSnapshot> _cache = {};
  final Map<LeagueStandingsType, Future<_LeagueOverviewSnapshot>> _futures = {};
  final Map<LeagueStandingsType, ScrollController> _scrollControllers = {};
  final Map<LeagueStandingsType, GlobalKey<State<StatefulWidget>>>
  _leagueTabKeys = {
    for (final type in LeagueStandingsType.values)
      type: GlobalKey<State<StatefulWidget>>(),
  };
  final Set<LeagueStandingsType> _favoriteFixtureFilterTypes =
      <LeagueStandingsType>{};
  Set<String> _favoriteTeamKeys = <String>{};
  Future<_LeagueOverviewSnapshot>? _future;

  @override
  void initState() {
    super.initState();
    _ownsService = widget.service == null;
    _service = widget.service ?? LeagueStandingsService();
    _reminderService =
        widget.reminderService ??
        (widget.optionRepository != null && widget.settingsService != null
            ? LeagueFixtureReminderService(
                widget.optionRepository!,
                widget.settingsService!,
              )
            : null);
    _languageCode =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    _favoriteTeamKeys = _reminderService?.favoriteTeamKeysSync() ?? <String>{};
    _restoreFavoriteFixtureFilters();
    _selectedType = _loadInitialType();
    _pageController = PageController(
      initialPage: _leagueIndexForType(_selectedType),
    );
    _future = _futureFor(_selectedType);
    _scrollLeagueTabIntoView(_selectedType);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextLanguageCode = Localizations.localeOf(context).languageCode;
    if (nextLanguageCode == _languageCode) return;
    _languageCode = nextLanguageCode;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients) return;
      _pageController.jumpToPage(_leagueIndexForType(_selectedType));
      _scrollLeagueTabIntoView(_selectedType);
    });
  }

  @override
  void dispose() {
    for (final controller in _scrollControllers.values) {
      controller.dispose();
    }
    _pageController.dispose();
    if (_ownsService) {
      _service.dispose();
    }
    super.dispose();
  }

  LeagueStandingsType _loadInitialType() {
    final stored = widget.optionRepository?.getValue<String>(
      _lastSelectedLeagueKey,
    );
    return LeagueStandingsType.values.firstWhere(
      (type) => type.name == stored,
      orElse: () => widget.initialType,
    );
  }

  void _restoreFavoriteFixtureFilters() {
    final stored =
        widget.optionRepository?.getValue<List>(_favoriteFixtureFilterKey) ??
        const <dynamic>[];
    _favoriteFixtureFilterTypes
      ..clear()
      ..addAll(
        stored
            .map((item) => item.toString())
            .map(_leagueTypeByName)
            .whereType<LeagueStandingsType>(),
      );
  }

  LeagueStandingsType? _leagueTypeByName(String name) {
    for (final type in LeagueStandingsType.values) {
      if (type.name == name) return type;
    }
    return null;
  }

  Future<_LeagueOverviewSnapshot> _load(
    LeagueStandingsType type, {
    bool refresh = false,
  }) async {
    if (!refresh) {
      final cached = _cache[type];
      if (cached != null) return cached;
    }
    final standingsFuture = _service.fetch(type);
    final fixturesFuture = _service.fetchFixtures(type);
    final values = await Future.wait<Object>([standingsFuture, fixturesFuture]);
    final snapshot = _LeagueOverviewSnapshot(
      standings: values[0] as LeagueStandingsSnapshot,
      fixtures: values[1] as LeagueFixtureSnapshot,
    );
    _cache[type] = snapshot;
    unawaited(_syncLeagueReminders());
    return snapshot;
  }

  Future<_LeagueOverviewSnapshot> _futureFor(LeagueStandingsType type) {
    return _futures.putIfAbsent(type, () => _load(type));
  }

  int _leagueIndexForType(LeagueStandingsType type) {
    final index = _leagueTypes.indexOf(type);
    return index < 0 ? 0 : index;
  }

  List<LeagueStandingsType> get _leagueTypes =>
      _leagueTypesForLanguage(_languageCode);

  void _selectType(LeagueStandingsType type) {
    if (type == _selectedType) {
      _scrollLeagueTabIntoView(type);
      _animateToLeaguePage(type);
      return;
    }
    _setSelectedType(type);
    _animateToLeaguePage(type);
  }

  void _setSelectedType(LeagueStandingsType type) {
    setState(() {
      _selectedType = type;
      _future = _futureFor(type);
    });
    final optionRepository = widget.optionRepository;
    if (optionRepository != null) {
      unawaited(optionRepository.setValue(_lastSelectedLeagueKey, type.name));
    }
    _scrollLeagueTabIntoView(type);
  }

  void _animateToLeaguePage(LeagueStandingsType type) {
    if (!_pageController.hasClients) return;
    unawaited(
      _pageController.animateToPage(
        _leagueIndexForType(type),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  void _handleLeaguePageChanged(int index) {
    if (index < 0 || index >= _leagueTypes.length) return;
    final type = _leagueTypes[index];
    if (type == _selectedType) {
      _scrollLeagueTabIntoView(type);
      return;
    }
    _setSelectedType(type);
  }

  void _scrollLeagueTabIntoView(LeagueStandingsType type) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final tabContext = _leagueTabKeys[type]?.currentContext;
      if (tabContext == null) return;
      Scrollable.ensureVisible(
        tabContext,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        alignment: 0.5,
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      );
    });
  }

  Future<void> _refresh() async {
    final future = _load(_selectedType, refresh: true);
    _futures[_selectedType] = future;
    setState(() => _future = future);
    await future;
  }

  ScrollController _scrollControllerFor(LeagueStandingsType type) {
    return _scrollControllers.putIfAbsent(type, ScrollController.new);
  }

  void _setFavoriteFixtureFilter(LeagueStandingsType type, bool enabled) {
    setState(() {
      if (enabled) {
        _favoriteFixtureFilterTypes.add(type);
      } else {
        _favoriteFixtureFilterTypes.remove(type);
      }
    });
    final optionRepository = widget.optionRepository;
    if (optionRepository != null) {
      final stored =
          _favoriteFixtureFilterTypes.map((type) => type.name).toList()..sort();
      unawaited(optionRepository.setValue(_favoriteFixtureFilterKey, stored));
    }
  }

  Widget? _buildReminderPanel(
    AppLocalizations l10n,
    _LeagueOverviewSnapshot data,
  ) {
    if (_reminderService == null) return null;
    final options = _favoriteTeamOptionsFor(data);
    final selectedTeams = options
        .where((option) => _favoriteTeamKeys.contains(option.key))
        .toList(growable: false);
    final leagueReminderCount = _scheduledReminderCountFor(data.fixtures);
    return _LeagueReminderPanel(
      title: l10n.newsLeagueFavoriteTeamTitle,
      emptyLabel: l10n.newsLeagueFavoriteTeamNone,
      selectLabel: l10n.newsLeagueFavoriteTeamManage,
      reminderCountLabel: leagueReminderCount > 0
          ? l10n.newsLeagueFavoriteTeamReminderCount(leagueReminderCount)
          : l10n.newsLeagueFavoriteTeamNoUpcoming,
      selectedTeams: selectedTeams,
      onSelect: options.isEmpty ? null : _openFavoriteTeamScreen,
    );
  }

  Future<int> _syncLeagueReminders() async {
    final reminderService = _reminderService;
    if (reminderService == null || !mounted) return 0;
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return 0;
    final locale = Localizations.localeOf(context).toString();
    final formatter = DateFormat.MMMd(locale).add_Hm();
    final count = await reminderService.syncReminders(
      snapshots: _cache.values.map((snapshot) => snapshot.fixtures),
      title: l10n.appTitle,
      androidChannelName: l10n.newsLeagueFixtureNotificationChannelName,
      androidChannelDescription:
          l10n.newsLeagueFixtureNotificationChannelDescription,
      bodyBuilder: (entry, teamName, opponentName) =>
          l10n.newsLeagueFavoriteTeamNotificationBody(
            teamName,
            opponentName,
            formatter.format(entry.kickoffAt.toLocal()),
          ),
    );
    return count;
  }

  int _scheduledReminderCountFor(LeagueFixtureSnapshot snapshot) {
    final now = DateTime.now();
    var count = 0;
    for (final entry in snapshot.entries) {
      if (entry.status != LeagueFixtureStatus.scheduled) continue;
      if (!entry.kickoffAt.toLocal().isAfter(now)) continue;
      if (_fixtureMatchesFavoriteTeam(
        snapshot.type,
        entry,
        _favoriteTeamKeys,
      )) {
        count++;
      }
    }
    return count;
  }

  Future<void> _openFavoriteTeamScreen() async {
    final reminderService = _reminderService;
    if (reminderService == null) return;
    final savedKeys = await Navigator.of(context).push<Set<String>>(
      AppPageRoute(
        builder: (_) => _LeagueFavoriteTeamScreen(
          initialType: _selectedType,
          service: _service,
          reminderService: reminderService,
          initialFavoriteTeamKeys: _favoriteTeamKeys,
        ),
      ),
    );
    if (!mounted || savedKeys == null) return;
    setState(() => _favoriteTeamKeys = savedKeys);
    await _syncLeagueReminders();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)!.newsLeagueFavoriteTeamSaved,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.newsLeagueStandingsTitle),
        actions: [
          if (_reminderService != null)
            IconButton(
              tooltip: l10n.newsLeagueFavoriteTeamManage,
              onPressed: _openFavoriteTeamScreen,
              icon: const Icon(Icons.favorite_border_rounded),
            ),
          FutureBuilder<_LeagueOverviewSnapshot>(
            future: _future,
            builder: (context, snapshot) {
              final sourceUrl = snapshot.data?.standings.sourceUrl.trim() ?? '';
              if (sourceUrl.isEmpty) return const SizedBox.shrink();
              return IconButton(
                tooltip: l10n.newsLeagueStandingsOpenSource,
                onPressed: () => _openSource(sourceUrl),
                icon: const Icon(Icons.open_in_new_rounded),
              );
            },
          ),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<LeagueStandingsType>(
                    segments: _leagueStandingsSegments(
                      l10n,
                      leagueTypes: _leagueTypes,
                      labelKeys: _leagueTabKeys,
                    ),
                    selected: {_selectedType},
                    showSelectedIcon: false,
                    onSelectionChanged: (selection) {
                      if (selection.isEmpty) return;
                      _selectType(selection.first);
                    },
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _leagueTypes.length,
                  onPageChanged: _handleLeaguePageChanged,
                  itemBuilder: (context, index) {
                    final type = _leagueTypes[index];
                    return FutureBuilder<_LeagueOverviewSnapshot>(
                      future: _futureFor(type),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                                ConnectionState.waiting &&
                            !snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return _MessageState(
                            icon: Icons.cloud_off_outlined,
                            title: l10n.newsLeagueStandingsError,
                            onRetry: _refresh,
                          );
                        }
                        final data = snapshot.data;
                        if (data == null ||
                            (data.standings.entries.isEmpty &&
                                data.fixtures.entries.isEmpty)) {
                          return _MessageState(
                            icon: Icons.table_chart_outlined,
                            title: l10n.newsLeagueStandingsEmpty,
                            onRetry: _refresh,
                          );
                        }
                        return RefreshIndicator(
                          onRefresh: _refresh,
                          child: _StandingsTable(
                            snapshot: data.standings,
                            fixtures: data.fixtures,
                            scrollController: _scrollControllerFor(
                              data.standings.type,
                            ),
                            favoriteTeamKeys: _favoriteTeamKeys,
                            filterFavoriteFixtures: _favoriteFixtureFilterTypes
                                .contains(data.standings.type),
                            onFilterFavoriteFixturesChanged: (enabled) =>
                                _setFavoriteFixtureFilter(
                                  data.standings.type,
                                  enabled,
                                ),
                            reminderPanel: _buildReminderPanel(l10n, data),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openSource(String sourceUrl) async {
    final uri = Uri.tryParse(sourceUrl);
    if (uri == null) return;
    await launchUrl(
      uri,
      mode: LaunchMode.inAppBrowserView,
      browserConfiguration: const BrowserConfiguration(showTitle: true),
    );
  }
}

class _LeagueFavoriteTeamScreen extends StatefulWidget {
  final LeagueStandingsType initialType;
  final LeagueStandingsService service;
  final LeagueFixtureReminderService reminderService;
  final Set<String> initialFavoriteTeamKeys;

  const _LeagueFavoriteTeamScreen({
    required this.initialType,
    required this.service,
    required this.reminderService,
    required this.initialFavoriteTeamKeys,
  });

  @override
  State<_LeagueFavoriteTeamScreen> createState() =>
      _LeagueFavoriteTeamScreenState();
}

class _LeagueFavoriteTeamScreenState extends State<_LeagueFavoriteTeamScreen> {
  late LeagueStandingsType _selectedType;
  late Set<String> _favoriteTeamKeys;
  final Map<LeagueStandingsType, _LeagueOverviewSnapshot> _cache = {};
  final Map<LeagueStandingsType, GlobalKey<State<StatefulWidget>>>
  _leagueTabKeys = {
    for (final type in LeagueStandingsType.values)
      type: GlobalKey<State<StatefulWidget>>(),
  };
  Future<_LeagueOverviewSnapshot>? _future;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    _favoriteTeamKeys = Set<String>.from(widget.initialFavoriteTeamKeys);
    _future = _load(_selectedType);
    _scrollLeagueTabIntoView(_selectedType);
  }

  Future<_LeagueOverviewSnapshot> _load(LeagueStandingsType type) async {
    final cached = _cache[type];
    if (cached != null) return cached;
    final values = await Future.wait<Object>([
      widget.service.fetch(type),
      widget.service.fetchFixtures(type),
    ]);
    final snapshot = _LeagueOverviewSnapshot(
      standings: values[0] as LeagueStandingsSnapshot,
      fixtures: values[1] as LeagueFixtureSnapshot,
    );
    _cache[type] = snapshot;
    return snapshot;
  }

  void _selectType(LeagueStandingsType type) {
    if (type == _selectedType) {
      _scrollLeagueTabIntoView(type);
      return;
    }
    setState(() {
      _selectedType = type;
      _future = _load(type);
    });
    _scrollLeagueTabIntoView(type);
  }

  void _scrollLeagueTabIntoView(LeagueStandingsType type) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final tabContext = _leagueTabKeys[type]?.currentContext;
      if (tabContext == null) return;
      Scrollable.ensureVisible(
        tabContext,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        alignment: 0.5,
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      );
    });
  }

  Future<void> _refresh() async {
    final future = _load(_selectedType);
    setState(() => _future = future);
    await future;
  }

  void _toggleTeam(String key, bool selected) {
    setState(() {
      if (selected) {
        _favoriteTeamKeys.add(key);
      } else {
        _favoriteTeamKeys.remove(key);
      }
    });
  }

  void _clearSelectedLeague() {
    final selectedPrefix = '${_selectedType.name}:';
    setState(() {
      _favoriteTeamKeys.removeWhere((key) => key.startsWith(selectedPrefix));
    });
  }

  Future<void> _save() async {
    await widget.reminderService.saveFavoriteTeamKeys(_favoriteTeamKeys);
    if (!mounted) return;
    Navigator.of(context).pop(Set<String>.from(_favoriteTeamKeys));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.newsLeagueFavoriteTeamManage)),
      body: AppBackground(
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<LeagueStandingsType>(
                    segments: _leagueStandingsSegments(
                      l10n,
                      leagueTypes: _leagueTypesForLanguage(
                        Localizations.localeOf(context).languageCode,
                      ),
                      labelKeys: _leagueTabKeys,
                    ),
                    selected: {_selectedType},
                    showSelectedIcon: false,
                    onSelectionChanged: (selection) {
                      if (selection.isEmpty) return;
                      _selectType(selection.first);
                    },
                  ),
                ),
              ),
              Expanded(
                child: FutureBuilder<_LeagueOverviewSnapshot>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return _MessageState(
                        icon: Icons.cloud_off_outlined,
                        title: l10n.newsLeagueFavoriteTeamLoadError,
                        onRetry: _refresh,
                      );
                    }
                    final data = snapshot.data;
                    if (data == null) {
                      return _MessageState(
                        icon: Icons.favorite_border_rounded,
                        title: l10n.newsLeagueFavoriteTeamEmpty,
                        onRetry: _refresh,
                      );
                    }
                    final options = _favoriteTeamOptionsFor(data);
                    if (options.isEmpty) {
                      return _MessageState(
                        icon: Icons.favorite_border_rounded,
                        title: l10n.newsLeagueFavoriteTeamEmpty,
                        onRetry: _refresh,
                      );
                    }
                    final selectedPrefix = '${_selectedType.name}:';
                    final selectedCount = _favoriteTeamKeys
                        .where((key) => key.startsWith(selectedPrefix))
                        .length;
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  selectedCount == 0
                                      ? l10n.newsLeagueFavoriteTeamNone
                                      : l10n.newsLeagueFavoriteTeamSelectedCount(
                                          selectedCount,
                                        ),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: selectedCount == 0
                                    ? null
                                    : _clearSelectedLeague,
                                icon: const Icon(Icons.clear_all_rounded),
                                label: Text(l10n.newsLeagueFavoriteTeamClear),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final option = options[index];
                              return CheckboxListTile(
                                value: _favoriteTeamKeys.contains(option.key),
                                title: Row(
                                  children: [
                                    _LogoCircle(
                                      name: option.label,
                                      shortName: option.shortName,
                                      logoUrl: option.logoUrl,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        option.label,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                onChanged: (checked) =>
                                    _toggleTeam(option.key, checked ?? false),
                              );
                            },
                          ),
                        ),
                        SafeArea(
                          top: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            child: SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _save,
                                icon: const Icon(Icons.save_outlined),
                                label: Text(
                                  l10n.newsLeagueFavoriteTeamSaveAction,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeagueOverviewSnapshot {
  final LeagueStandingsSnapshot standings;
  final LeagueFixtureSnapshot fixtures;

  const _LeagueOverviewSnapshot({
    required this.standings,
    required this.fixtures,
  });
}

class _LeagueFavoriteTeamOption {
  final String key;
  final String label;
  final String shortName;
  final String logoUrl;

  const _LeagueFavoriteTeamOption({
    required this.key,
    required this.label,
    required this.shortName,
    required this.logoUrl,
  });
}

List<_LeagueFavoriteTeamOption> _favoriteTeamOptionsFor(
  _LeagueOverviewSnapshot data,
) {
  final optionsByKey = <String, _LeagueFavoriteTeamOption>{};
  void addTeam(String name, {String shortName = '', String logoUrl = ''}) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final key = LeagueFixtureReminderService.teamKey(
      data.standings.type,
      trimmed,
    );
    optionsByKey.putIfAbsent(
      key,
      () => _LeagueFavoriteTeamOption(
        key: key,
        label: trimmed,
        shortName: shortName,
        logoUrl: logoUrl,
      ),
    );
  }

  for (final entry in data.standings.entries) {
    addTeam(
      entry.teamName,
      shortName: entry.teamShortName,
      logoUrl: entry.logoUrl,
    );
  }
  for (final entry in data.fixtures.entries) {
    addTeam(
      entry.homeTeamName,
      shortName: entry.homeTeamShortName,
      logoUrl: entry.homeLogoUrl,
    );
    addTeam(
      entry.awayTeamName,
      shortName: entry.awayTeamShortName,
      logoUrl: entry.awayLogoUrl,
    );
  }

  final options = optionsByKey.values.toList(growable: false)
    ..sort((a, b) => a.label.compareTo(b.label));
  return options;
}

bool _fixtureMatchesFavoriteTeam(
  LeagueStandingsType type,
  LeagueFixtureEntry entry,
  Set<String> favoriteTeamKeys,
) {
  return favoriteTeamKeys.contains(
        LeagueFixtureReminderService.teamKey(type, entry.homeTeamName),
      ) ||
      favoriteTeamKeys.contains(
        LeagueFixtureReminderService.teamKey(type, entry.awayTeamName),
      );
}

List<ButtonSegment<LeagueStandingsType>> _leagueStandingsSegments(
  AppLocalizations l10n, {
  required List<LeagueStandingsType> leagueTypes,
  Map<LeagueStandingsType, GlobalKey<State<StatefulWidget>>>? labelKeys,
}) {
  return leagueTypes
      .map((type) => _leagueStandingsSegment(l10n, type, labelKeys))
      .toList(growable: false);
}

List<LeagueStandingsType> _leagueTypesForLanguage(String languageCode) {
  if (languageCode == 'ko' || languageCode == 'ja') {
    return LeagueStandingsType.values;
  }
  return const <LeagueStandingsType>[
    LeagueStandingsType.premierLeague,
    LeagueStandingsType.championsLeague,
    LeagueStandingsType.laLiga,
    LeagueStandingsType.bundesliga,
    LeagueStandingsType.majorLeagueSoccer,
    LeagueStandingsType.saudiProLeague,
    LeagueStandingsType.kLeague1,
  ];
}

ButtonSegment<LeagueStandingsType> _leagueStandingsSegment(
  AppLocalizations l10n,
  LeagueStandingsType type,
  Map<LeagueStandingsType, GlobalKey<State<StatefulWidget>>>? labelKeys,
) {
  return switch (type) {
    LeagueStandingsType.kLeague1 => ButtonSegment<LeagueStandingsType>(
      value: type,
      icon: const Icon(Icons.flag_outlined, size: 18),
      label: _leagueSegmentLabel(
        labelKeys,
        type,
        l10n.newsKLeagueStandingsTitle,
      ),
    ),
    LeagueStandingsType.premierLeague => ButtonSegment<LeagueStandingsType>(
      value: type,
      icon: const Icon(Icons.shield_outlined, size: 18),
      label: _leagueSegmentLabel(
        labelKeys,
        type,
        l10n.newsPremierLeagueStandingsTitle,
      ),
    ),
    LeagueStandingsType.championsLeague => ButtonSegment<LeagueStandingsType>(
      value: type,
      icon: const Icon(Icons.emoji_events_outlined, size: 18),
      label: _leagueSegmentLabel(
        labelKeys,
        type,
        l10n.newsChampionsLeagueStandingsTitle,
      ),
    ),
    LeagueStandingsType.laLiga => ButtonSegment<LeagueStandingsType>(
      value: type,
      icon: const Icon(Icons.sports_soccer, size: 18),
      label: _leagueSegmentLabel(
        labelKeys,
        type,
        l10n.newsLaLigaStandingsTitle,
      ),
    ),
    LeagueStandingsType.bundesliga => ButtonSegment<LeagueStandingsType>(
      value: type,
      icon: const Icon(Icons.shield, size: 18),
      label: _leagueSegmentLabel(
        labelKeys,
        type,
        l10n.newsBundesligaStandingsTitle,
      ),
    ),
    LeagueStandingsType.majorLeagueSoccer => ButtonSegment<LeagueStandingsType>(
      value: type,
      icon: const Icon(Icons.public, size: 18),
      label: _leagueSegmentLabel(
        labelKeys,
        type,
        l10n.newsMajorLeagueSoccerStandingsTitle,
      ),
    ),
    LeagueStandingsType.saudiProLeague => ButtonSegment<LeagueStandingsType>(
      value: type,
      icon: const Icon(Icons.flag_outlined, size: 18),
      label: _leagueSegmentLabel(
        labelKeys,
        type,
        l10n.newsSaudiProLeagueStandingsTitle,
      ),
    ),
  };
}

Widget _leagueSegmentLabel(
  Map<LeagueStandingsType, GlobalKey<State<StatefulWidget>>>? labelKeys,
  LeagueStandingsType type,
  String label,
) {
  final key = labelKeys?[type];
  final text = Text(label);
  return key == null ? text : KeyedSubtree(key: key, child: text);
}

class _LeagueReminderPanel extends StatelessWidget {
  final String title;
  final String emptyLabel;
  final String selectLabel;
  final String reminderCountLabel;
  final List<_LeagueFavoriteTeamOption> selectedTeams;
  final VoidCallback? onSelect;

  const _LeagueReminderPanel({
    required this.title,
    required this.emptyLabel,
    required this.selectLabel,
    required this.reminderCountLabel,
    required this.selectedTeams,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: selectLabel,
      child: OutlinedButton(
        onPressed: onSelect,
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          backgroundColor: theme.colorScheme.surfaceContainerLow,
          foregroundColor: theme.colorScheme.onSurface,
          disabledForegroundColor: theme.colorScheme.onSurfaceVariant,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          minimumSize: const Size.fromHeight(64),
          side: BorderSide(
            color: onSelect == null
                ? theme.colorScheme.outlineVariant.withValues(alpha: 0.55)
                : theme.colorScheme.primary.withValues(alpha: 0.42),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                Icons.favorite_border_rounded,
                size: 21,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  if (selectedTeams.isNotEmpty) ...[
                    SizedBox(
                      height: 32,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: selectedTeams.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 6),
                        itemBuilder: (context, index) {
                          final team = selectedTeams[index];
                          return _FavoriteTeamPill(team: team);
                        },
                      ),
                    ),
                  ] else ...[
                    Text(
                      emptyLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                  ],
                  Text(
                    reminderCountLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              selectLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                color: onSelect == null
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.chevron_right_rounded,
              color: onSelect == null
                  ? theme.colorScheme.onSurfaceVariant
                  : theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteTeamPill extends StatelessWidget {
  final _LeagueFavoriteTeamOption team;

  const _FavoriteTeamPill({required this.team});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(maxWidth: 190),
      padding: const EdgeInsetsDirectional.fromSTEB(4, 3, 9, 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LogoCircle(
            name: team.label,
            shortName: team.shortName,
            logoUrl: team.logoUrl,
            size: 24,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              team.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StandingsTable extends StatelessWidget {
  final LeagueStandingsSnapshot snapshot;
  final LeagueFixtureSnapshot fixtures;
  final ScrollController scrollController;
  final Set<String> favoriteTeamKeys;
  final bool filterFavoriteFixtures;
  final ValueChanged<bool> onFilterFavoriteFixturesChanged;
  final Widget? reminderPanel;

  const _StandingsTable({
    required this.snapshot,
    required this.fixtures,
    required this.scrollController,
    required this.favoriteTeamKeys,
    required this.filterFavoriteFixtures,
    required this.onFilterFavoriteFixturesChanged,
    this.reminderPanel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final fetchedText = DateFormat.yMMMd(
      locale,
    ).add_Hm().format(snapshot.fetchedAt.toLocal());
    return ListView(
      key: PageStorageKey<String>(
        'league_overview_scroll_${snapshot.type.name}',
      ),
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
      children: [
        Text(
          [
            if (snapshot.seasonName.trim().isNotEmpty) snapshot.seasonName,
            l10n.newsLeagueStandingsUpdated(fetchedText),
          ].join(' · '),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        if (reminderPanel != null) ...[
          reminderPanel!,
          const SizedBox(height: 12),
        ],
        _FixtureSection(
          snapshot: fixtures,
          favoriteTeamKeys: favoriteTeamKeys,
          filterFavorites: filterFavoriteFixtures,
          onFilterFavoritesChanged: onFilterFavoriteFixturesChanged,
        ),
        if (snapshot.entries.isNotEmpty) ...[
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              children: [
                _StandingsHeaderRow(),
                ...snapshot.entries.map(
                  (entry) => _StandingTeamRow(entry: entry),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _FixtureSection extends StatelessWidget {
  final LeagueFixtureSnapshot snapshot;
  final Set<String> favoriteTeamKeys;
  final bool filterFavorites;
  final ValueChanged<bool> onFilterFavoritesChanged;

  const _FixtureSection({
    required this.snapshot,
    required this.favoriteTeamKeys,
    required this.filterFavorites,
    required this.onFilterFavoritesChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final hasFavoriteTeamsForLeague = favoriteTeamKeys.any(
      (key) => key.startsWith('${snapshot.type.name}:'),
    );
    final entries = filterFavorites && hasFavoriteTeamsForLeague
        ? snapshot.entries
              .where(
                (entry) => _fixtureMatchesFavoriteTeam(
                  snapshot.type,
                  entry,
                  favoriteTeamKeys,
                ),
              )
              .toList(growable: false)
        : snapshot.entries;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.newsLeagueFixturesTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(l10n.newsLeagueFixturesSubtitle, style: theme.textTheme.bodySmall),
        if (hasFavoriteTeamsForLeague) ...[
          const SizedBox(height: 10),
          FilterChip(
            avatar: Icon(
              filterFavorites
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              size: 18,
              color: filterFavorites
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.primary,
            ),
            label: Text(
              l10n.newsLeagueFixturesSelectedTeamsOnly,
              style: theme.textTheme.labelLarge?.copyWith(
                color: filterFavorites
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurface,
                fontWeight: FontWeight.w900,
              ),
            ),
            selected: filterFavorites,
            selectedColor: theme.colorScheme.primaryContainer,
            backgroundColor: theme.colorScheme.surfaceContainerLow,
            checkmarkColor: theme.colorScheme.onPrimaryContainer,
            side: BorderSide(
              color: filterFavorites
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
              width: filterFavorites ? 1.4 : 1,
            ),
            onSelected: onFilterFavoritesChanged,
          ),
        ],
        const SizedBox(height: 10),
        if (entries.isEmpty)
          Text(
            filterFavorites && hasFavoriteTeamsForLeague
                ? l10n.newsLeagueFixturesSelectedTeamsEmpty
                : l10n.newsLeagueFixturesEmpty,
            style: theme.textTheme.bodyMedium,
          )
        else
          _FixtureCalendarButton(
            snapshot: snapshot,
            entries: entries,
            favoriteTeamKeys: favoriteTeamKeys,
          ),
      ],
    );
  }
}

class _FixtureCalendarButton extends StatelessWidget {
  final LeagueFixtureSnapshot snapshot;
  final List<LeagueFixtureEntry> entries;
  final Set<String> favoriteTeamKeys;

  const _FixtureCalendarButton({
    required this.snapshot,
    required this.entries,
    required this.favoriteTeamKeys,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.of(context).push(
            AppPageRoute(
              builder: (_) => _LeagueFixtureCalendarScreen(
                snapshot: snapshot,
                entries: entries,
                favoriteTeamKeys: favoriteTeamKeys,
              ),
            ),
          );
        },
        icon: const Icon(Icons.calendar_month_outlined),
        label: Text(l10n.newsLeagueFixturesOpenCalendar),
      ),
    );
  }
}

class _LeagueFixtureCalendarScreen extends StatefulWidget {
  final LeagueFixtureSnapshot snapshot;
  final List<LeagueFixtureEntry> entries;
  final Set<String> favoriteTeamKeys;

  const _LeagueFixtureCalendarScreen({
    required this.snapshot,
    required this.entries,
    required this.favoriteTeamKeys,
  });

  @override
  State<_LeagueFixtureCalendarScreen> createState() =>
      _LeagueFixtureCalendarScreenState();
}

class _LeagueFixtureCalendarScreenState
    extends State<_LeagueFixtureCalendarScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  late Map<DateTime, List<LeagueFixtureEntry>> _entriesByDay;

  @override
  void initState() {
    super.initState();
    final entries = widget.entries.toList(growable: false)
      ..sort((a, b) => a.kickoffAt.compareTo(b.kickoffAt));
    _entriesByDay = _groupByDay(entries);
    final now = DateTime.now();
    final defaultEntry = entries.cast<LeagueFixtureEntry?>().firstWhere(
      (entry) => entry!.kickoffAt.toLocal().isAfter(now),
      orElse: () => entries.isEmpty ? null : entries.first,
    );
    final defaultDay = defaultEntry == null
        ? _normalizeDay(now)
        : _normalizeDay(defaultEntry.kickoffAt.toLocal());
    _focusedDay = defaultDay;
    _selectedDay = defaultDay;
  }

  Map<DateTime, List<LeagueFixtureEntry>> _groupByDay(
    List<LeagueFixtureEntry> entries,
  ) {
    final byDay = <DateTime, List<LeagueFixtureEntry>>{};
    for (final entry in entries) {
      final day = _normalizeDay(entry.kickoffAt.toLocal());
      byDay.putIfAbsent(day, () => <LeagueFixtureEntry>[]).add(entry);
    }
    return byDay;
  }

  DateTime _normalizeDay(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  List<LeagueFixtureEntry> _entriesFor(DateTime day) {
    return _entriesByDay[_normalizeDay(day)] ?? const <LeagueFixtureEntry>[];
  }

  DateTime get _firstDay {
    if (_entriesByDay.isEmpty) {
      final now = DateTime.now();
      return DateTime(now.year, now.month - 1, 1);
    }
    final first = _entriesByDay.keys.reduce((a, b) => a.isBefore(b) ? a : b);
    return DateTime(first.year, first.month - 1, 1);
  }

  DateTime get _lastDay {
    if (_entriesByDay.isEmpty) {
      final now = DateTime.now();
      return DateTime(now.year, now.month + 2, 0);
    }
    final last = _entriesByDay.keys.reduce((a, b) => a.isAfter(b) ? a : b);
    return DateTime(last.year, last.month + 2, 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final selectedEntries = _entriesFor(_selectedDay);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.newsLeagueFixturesCalendarTitle)),
      body: AppBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
            children: [
              Text(
                widget.snapshot.leagueName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (widget.snapshot.seasonName.trim().isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  widget.snapshot.seasonName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                  child: TableCalendar<LeagueFixtureEntry>(
                    locale: locale,
                    firstDay: _firstDay,
                    lastDay: _lastDay,
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
                    eventLoader: _entriesFor,
                    calendarFormat: CalendarFormat.month,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    availableCalendarFormats: {
                      CalendarFormat.month: l10n.calendarFormatMonth,
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = _normalizeDay(selectedDay);
                        _focusedDay = focusedDay;
                      });
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                    headerStyle: HeaderStyle(
                      titleCentered: true,
                      formatButtonVisible: false,
                      titleTextStyle:
                          theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ) ??
                          const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    calendarStyle: CalendarStyle(
                      markersMaxCount: 0,
                      todayDecoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.18,
                        ),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    calendarBuilders: CalendarBuilders<LeagueFixtureEntry>(
                      markerBuilder: (context, day, events) {
                        if (events.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return _FixtureCalendarMarkers(
                          entries: events,
                          type: widget.snapshot.type,
                          favoriteTeamKeys: widget.favoriteTeamKeys,
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                DateFormat.yMMMMEEEEd(locale).format(_selectedDay),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              if (selectedEntries.isEmpty)
                Text(
                  l10n.newsLeagueFixturesCalendarEmptyDay,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else
                for (
                  var index = 0;
                  index < selectedEntries.length;
                  index++
                ) ...[
                  _FixtureRow(entry: selectedEntries[index]),
                  if (index != selectedEntries.length - 1)
                    const SizedBox(height: 8),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FixtureCalendarMarkers extends StatelessWidget {
  final List<LeagueFixtureEntry> entries;
  final LeagueStandingsType type;
  final Set<String> favoriteTeamKeys;

  const _FixtureCalendarMarkers({
    required this.entries,
    required this.type,
    required this.favoriteTeamKeys,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final markerEntries = entries.take(2).toList(growable: false);
    final hasFavorite = entries.any(
      (entry) => _fixtureMatchesFavoriteTeam(type, entry, favoriteTeamKeys),
    );
    final color = hasFavorite
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    return PositionedDirectional(
      bottom: 4,
      start: 2,
      end: 2,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final entry in markerEntries) ...[
            _LogoCircle(
              name: entry.homeTeamName,
              shortName: entry.homeTeamShortName,
              logoUrl: entry.homeLogoUrl,
              size: 16,
            ),
            const SizedBox(width: 2),
          ],
          if (entries.length > markerEntries.length)
            Text(
              '+${entries.length - markerEntries.length}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
        ],
      ),
    );
  }
}

class _FixtureRow extends StatelessWidget {
  final LeagueFixtureEntry entry;

  const _FixtureRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final kickoffText = DateFormat.MMMd(
      locale,
    ).add_Hm().format(entry.kickoffAt.toLocal());
    final statusColor = _statusColor(theme);
    final detailParts = <String>[
      if (entry.stage.trim().isNotEmpty) entry.stage.trim(),
      if (entry.leg.trim().isNotEmpty) entry.leg.trim(),
      if (entry.note.trim().isNotEmpty) entry.note.trim(),
      if (entry.venue.trim().isNotEmpty) entry.venue.trim(),
      if (entry.city.trim().isNotEmpty) entry.city.trim(),
    ];
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: entry.sourceUrl.trim().isEmpty
            ? null
            : () => _openSource(entry.sourceUrl),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _StatusChip(label: _statusLabel(context), color: statusColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      kickoffText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _FixtureTeam(
                      name: entry.homeTeamName,
                      shortName: entry.homeTeamShortName,
                      logoUrl: entry.homeLogoUrl,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      entry.hasScore
                          ? '${entry.homeScore} - ${entry.awayScore}'
                          : kickoffText,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _FixtureTeam(
                      name: entry.awayTeamName,
                      shortName: entry.awayTeamShortName,
                      logoUrl: entry.awayLogoUrl,
                      alignEnd: true,
                    ),
                  ),
                ],
              ),
              if (detailParts.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  detailParts.join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openSource(String sourceUrl) async {
    final uri = Uri.tryParse(sourceUrl);
    if (uri == null) return;
    await launchUrl(
      uri,
      mode: LaunchMode.inAppBrowserView,
      browserConfiguration: const BrowserConfiguration(showTitle: true),
    );
  }

  String _statusLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return switch (entry.status) {
      LeagueFixtureStatus.scheduled => l10n.newsLeagueFixtureScheduled,
      LeagueFixtureStatus.live => l10n.newsLeagueFixtureLive,
      LeagueFixtureStatus.finished => l10n.newsLeagueFixtureFullTime,
    };
  }

  Color _statusColor(ThemeData theme) {
    return switch (entry.status) {
      LeagueFixtureStatus.scheduled => theme.colorScheme.primary,
      LeagueFixtureStatus.live => Colors.orange.shade700,
      LeagueFixtureStatus.finished => Colors.green.shade700,
    };
  }
}

class _FixtureTeam extends StatelessWidget {
  final String name;
  final String shortName;
  final String logoUrl;
  final bool alignEnd;

  const _FixtureTeam({
    required this.name,
    required this.shortName,
    required this.logoUrl,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    final logo = _LogoCircle(
      name: name,
      shortName: shortName,
      logoUrl: logoUrl,
    );
    final text = Expanded(
      child: Text(
        name,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: alignEnd ? TextAlign.right : TextAlign.left,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
    return Row(
      children: alignEnd
          ? [text, const SizedBox(width: 8), logo]
          : [logo, const SizedBox(width: 8), text],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StandingsHeaderRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _StandingRowShell(
      header: true,
      child: Row(
        children: [
          _cell('#', width: 42, context: context, header: true),
          _cell(
            l10n.newsLeagueStandingsTeamColumn,
            width: 184,
            context: context,
            header: true,
          ),
          _cell(
            l10n.newsLeagueStandingsPlayedColumn,
            context: context,
            header: true,
          ),
          _cell(
            l10n.newsLeagueStandingsWinsColumn,
            context: context,
            header: true,
          ),
          _cell(
            l10n.newsLeagueStandingsDrawsColumn,
            context: context,
            header: true,
          ),
          _cell(
            l10n.newsLeagueStandingsLossesColumn,
            context: context,
            header: true,
          ),
          _cell(
            l10n.newsLeagueStandingsGoalDifferenceColumn,
            context: context,
            header: true,
          ),
          _cell(
            l10n.newsLeagueStandingsPointsColumn,
            context: context,
            header: true,
          ),
        ],
      ),
    );
  }
}

class _StandingTeamRow extends StatelessWidget {
  final LeagueStandingEntry entry;

  const _StandingTeamRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return _StandingRowShell(
      child: Row(
        children: [
          _cell('${entry.rank}', width: 42, context: context),
          SizedBox(
            width: 184,
            child: Row(
              children: [
                _TeamLogo(entry: entry),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.teamName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _cell(entry.played, context: context),
          _cell(entry.wins, context: context),
          _cell(entry.draws, context: context),
          _cell(entry.losses, context: context),
          _cell(entry.goalDifference, context: context),
          _cell(entry.points, context: context, strong: true),
        ],
      ),
    );
  }
}

class _TeamLogo extends StatelessWidget {
  final LeagueStandingEntry entry;

  const _TeamLogo({required this.entry});

  @override
  Widget build(BuildContext context) {
    return _LogoCircle(
      name: entry.teamName,
      shortName: entry.teamShortName,
      logoUrl: entry.logoUrl,
    );
  }
}

class _LogoCircle extends StatelessWidget {
  final String name;
  final String shortName;
  final String logoUrl;
  final double size;

  const _LogoCircle({
    required this.name,
    required this.shortName,
    required this.logoUrl,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    final compactName = name.trim();
    final initials = _logoFallbackText(shortName, compactName);
    final trimmedLogoUrl = logoUrl.trim();
    final theme = Theme.of(context);
    Widget fallbackLogo() {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              initials,
              maxLines: 1,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      padding: trimmedLogoUrl.isEmpty
          ? EdgeInsets.zero
          : const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.72 : 1.0,
        ),
        borderRadius: BorderRadius.circular(size * 0.32),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: trimmedLogoUrl.isEmpty
          ? fallbackLogo()
          : Image.network(
              trimmedLogoUrl,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              gaplessPlayback: true,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => fallbackLogo(),
            ),
    );
  }
}

String _logoFallbackText(String shortName, String name) {
  final preferred = shortName.trim().isNotEmpty
      ? shortName.trim()
      : name.trim();
  if (preferred.isEmpty) return '?';
  final words = preferred
      .split(RegExp(r'\s+'))
      .where((word) => word.trim().isNotEmpty)
      .toList(growable: false);
  if (words.length >= 2) {
    return words
        .take(2)
        .map((word) => String.fromCharCode(word.runes.first))
        .join()
        .toUpperCase();
  }
  final runes = preferred.runes.toList(growable: false);
  final takeCount = runes.length <= 3 ? runes.length : 2;
  return String.fromCharCodes(runes.take(takeCount)).toUpperCase();
}

class _StandingRowShell extends StatelessWidget {
  final Widget child;
  final bool header;

  const _StandingRowShell({required this.child, this.header = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 562,
      margin: EdgeInsets.only(bottom: header ? 6 : 5),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: header
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: header ? 0.65 : 0.42),
        ),
      ),
      child: child,
    );
  }
}

Widget _cell(
  String text, {
  required BuildContext context,
  double width = 48,
  bool header = false,
  bool strong = false,
}) {
  return SizedBox(
    width: width,
    child: Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style:
          (header
                  ? Theme.of(context).textTheme.labelMedium
                  : Theme.of(context).textTheme.bodyMedium)
              ?.copyWith(
                fontWeight: header || strong
                    ? FontWeight.w900
                    : FontWeight.w600,
              ),
    ),
  );
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final Future<void> Function() onRetry;

  const _MessageState({
    required this.icon,
    required this.title,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.newsLeagueStandingsRetry),
            ),
          ],
        ),
      ),
    );
  }
}
