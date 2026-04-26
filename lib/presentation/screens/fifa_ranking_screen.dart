import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../application/fifa_world_overview_service.dart';
import '../../domain/entities/fifa_world_overview.dart';
import '../../gen/app_localizations.dart';
import '../widgets/app_background.dart';
import '../widgets/app_page_route.dart';
import '../widgets/watch_cart/watch_cart_card.dart';
import 'fifa_country_detail_screen.dart';

class FifaRankingScreen extends StatefulWidget {
  const FifaRankingScreen({super.key});

  @override
  State<FifaRankingScreen> createState() => _FifaRankingScreenState();
}

class _FifaRankingScreenState extends State<FifaRankingScreen> {
  static const FifaRankingGender _rankingGender = FifaRankingGender.men;

  late final FifaWorldOverviewService _service;
  late final ScrollController _rankingScrollController;
  late final ScrollController _recentMatchScrollController;
  late final ScrollController _upcomingMatchScrollController;
  late final ScrollController _kfaRecentMatchScrollController;
  late final ScrollController _kfaUpcomingMatchScrollController;
  Locale? _lastLocale;
  FifaWorldOverview? _overview;
  List<KfaMatchEntry> _kfaRecentResults = const <KfaMatchEntry>[];
  List<KfaMatchEntry> _kfaUpcomingFixtures = const <KfaMatchEntry>[];
  bool _isRankingLoading = true;
  bool _isMatchLoading = false;
  bool _isKfaLoading = false;
  bool _hadError = false;
  int _loadToken = 0;

  @override
  void initState() {
    super.initState();
    _service = FifaWorldOverviewService();
    _rankingScrollController = ScrollController();
    _recentMatchScrollController = ScrollController();
    _upcomingMatchScrollController = ScrollController();
    _kfaRecentMatchScrollController = ScrollController();
    _kfaUpcomingMatchScrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadOverview();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    final previousLocale = _lastLocale;
    _lastLocale = locale;
    if (previousLocale != null &&
        previousLocale.languageCode != locale.languageCode) {
      _loadOverview(force: true);
    }
  }

  @override
  void dispose() {
    _rankingScrollController.dispose();
    _recentMatchScrollController.dispose();
    _upcomingMatchScrollController.dispose();
    _kfaRecentMatchScrollController.dispose();
    _kfaUpcomingMatchScrollController.dispose();
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.fifaHubAppBarTitle)),
      body: AppBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () => _loadOverview(force: true),
            child: _buildBody(context),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final overview = _overview;
    final showKfaMatches = _isKoreanLocale;
    if (_isRankingLoading && overview == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 140),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    final items = <Widget>[
      if (_hadError && (overview == null || overview.isEmpty))
        _buildMessageCard(l10n.fifaHubLoadError)
      else if (overview == null || overview.isEmpty)
        _buildMessageCard(l10n.fifaHubNoData)
      else ...[
        _buildHeroCard(context, overview),
        _buildRankingCard(context, overview),
        if (showKfaMatches &&
            (!_isKfaLoading || _kfaUpcomingFixtures.isNotEmpty))
          _buildKfaMatchSection(
            context,
            title: l10n.fifaHubKfaUpcomingFixturesTitle,
            subtitle: l10n.fifaHubKfaUpcomingFixturesSubtitle,
            emptyMessage: l10n.fifaHubKfaUpcomingFixturesEmpty,
            matches: _kfaUpcomingFixtures,
            scrollController: _kfaUpcomingMatchScrollController,
          ),
        if (showKfaMatches && (!_isKfaLoading || _kfaRecentResults.isNotEmpty))
          _buildKfaMatchSection(
            context,
            title: l10n.fifaHubKfaRecentResultsTitle,
            subtitle: l10n.fifaHubKfaRecentResultsSubtitle,
            emptyMessage: l10n.fifaHubKfaRecentResultsEmpty,
            matches: _kfaRecentResults,
            scrollController: _kfaRecentMatchScrollController,
          ),
        if (!_isMatchLoading || overview.recentResults.isNotEmpty)
          _buildMatchSection(
            context,
            title: l10n.fifaHubRecentResultsTitle,
            subtitle: l10n.fifaHubRecentResultsSubtitle,
            emptyMessage: l10n.fifaHubRecentResultsEmpty,
            matches: overview.recentResults,
            scrollController: _recentMatchScrollController,
          ),
        if (!_isMatchLoading || overview.upcomingFixtures.isNotEmpty)
          _buildMatchSection(
            context,
            title: l10n.fifaHubUpcomingFixturesTitle,
            subtitle: l10n.fifaHubUpcomingFixturesSubtitle,
            emptyMessage: l10n.fifaHubUpcomingFixturesEmpty,
            matches: overview.upcomingFixtures,
            scrollController: _upcomingMatchScrollController,
          ),
      ],
      const SizedBox(height: 12),
    ];

    return Stack(
      children: [
        ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) => items[index],
        ),
        if (_isRankingLoading || _isMatchLoading || _isKfaLoading)
          const Align(
            alignment: Alignment.topCenter,
            child: LinearProgressIndicator(minHeight: 2),
          ),
      ],
    );
  }

  Widget _buildHeroCard(BuildContext context, FifaWorldOverview overview) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final leader = overview.leader;
    final locale = Localizations.localeOf(context).toString();
    final updateLabel = overview.lastUpdatedAt == null
        ? ''
        : DateFormat('yyyy.MM.dd', locale).format(overview.lastUpdatedAt!);
    final nextUpdateLabel = overview.nextUpdatedAt == null
        ? ''
        : DateFormat('yyyy.MM.dd', locale).format(overview.nextUpdatedAt!);

    return WatchCartCard(
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Color(0xFF123B6E), Color(0xFF1D6FA3), Color(0xFFE6EEF5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.fifaHubHeroTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (leader != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            l10n.fifaHubLeaderLabel,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: Colors.white.withAlpha(230),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            leader.teamName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            '#${leader.rank} · ${leader.points.toStringAsFixed(2)}',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: Colors.white.withAlpha(230),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (leader != null) ...[
                    const SizedBox(width: 12),
                    _CountryFlag(
                      countryCode: leader.countryCode,
                      size: 46,
                      radius: 14,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _HeroChip(
                    icon: Icons.public_outlined,
                    label: l10n.fifaHubRankedTeamsCount(
                      overview.rankings.length,
                    ),
                  ),
                  _HeroChip(
                    icon: Icons.hub_outlined,
                    label: l10n.fifaHubConfederationCount(
                      overview.confederationCount,
                    ),
                  ),
                  if (updateLabel.isNotEmpty)
                    _SoftInfoChip(
                      label: '${l10n.newsRankingUpdatedLabel} · $updateLabel',
                    ),
                  if (nextUpdateLabel.isNotEmpty)
                    _SoftInfoChip(
                      label:
                          '${l10n.fifaHubNextUpdateLabel} · $nextUpdateLabel',
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  FilledButton.tonalIcon(
                    onPressed: _openOfficialRankingPage,
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: Text(l10n.newsOpenOfficialSource),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(1, 46),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.fifaHubDataSourceLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF0F2946),
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.right,
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

  Widget _buildRankingCard(BuildContext context, FifaWorldOverview overview) {
    final l10n = AppLocalizations.of(context)!;
    final rankingHeight = (MediaQuery.sizeOf(context).height * 0.42)
        .clamp(300.0, 430.0)
        .toDouble();

    return WatchCartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.fifaHubGlobalRankingTitle,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.fifaHubGlobalRankingSubtitle,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: rankingHeight,
            child: Scrollbar(
              controller: _rankingScrollController,
              thumbVisibility: true,
              child: ListView.separated(
                controller: _rankingScrollController,
                primary: false,
                itemCount: overview.rankings.length,
                padding: EdgeInsets.zero,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final entry = overview.rankings[index];
                  return _RankingRow(
                    entry: entry,
                    onTap: () => _openCountryDetail(entry),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchSection(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String emptyMessage,
    required List<FifaAMatchEntry> matches,
    required ScrollController scrollController,
  }) {
    final matchHeight = _matchListHeight(context);
    return WatchCartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          if (matches.isEmpty)
            Text(emptyMessage, style: Theme.of(context).textTheme.bodyMedium)
          else
            SizedBox(
              height: matchHeight,
              child: Scrollbar(
                controller: scrollController,
                thumbVisibility: true,
                child: ListView.separated(
                  controller: scrollController,
                  primary: false,
                  padding: EdgeInsets.zero,
                  itemCount: matches.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final match = matches[index];
                    return _MatchRow(
                      match: match,
                      onTap: () => _openFifaMatchDetail(match),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildKfaMatchSection(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String emptyMessage,
    required List<KfaMatchEntry> matches,
    required ScrollController scrollController,
  }) {
    final matchHeight = _matchListHeight(context);
    return WatchCartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          if (matches.isEmpty)
            Text(emptyMessage, style: Theme.of(context).textTheme.bodyMedium)
          else
            SizedBox(
              height: matchHeight,
              child: Scrollbar(
                controller: scrollController,
                thumbVisibility: true,
                child: ListView.separated(
                  controller: scrollController,
                  primary: false,
                  padding: EdgeInsets.zero,
                  itemCount: matches.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final match = matches[index];
                    return _KfaMatchRow(
                      match: match,
                      onTap: () => _openKfaMatchDetail(match),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  double _matchListHeight(BuildContext context) =>
      (MediaQuery.sizeOf(context).height * 0.32).clamp(220.0, 340.0).toDouble();

  Widget _buildMessageCard(String message) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Center(child: Text(message, textAlign: TextAlign.center)),
    );
  }

  Future<void> _loadOverview({bool force = false}) async {
    final token = ++_loadToken;
    final shouldLoadKfa = _isKoreanLocale;
    if (mounted) {
      setState(() {
        _isRankingLoading = true;
        _isMatchLoading = false;
        _isKfaLoading = false;
        if (!shouldLoadKfa) {
          _kfaRecentResults = const <KfaMatchEntry>[];
          _kfaUpcomingFixtures = const <KfaMatchEntry>[];
        }
        if (force) {
          _hadError = false;
        }
      });
    }
    try {
      final overview = await _service.fetchRankingOverview(
        gender: _rankingGender,
      );
      if (!mounted || token != _loadToken) return;
      setState(() {
        _overview = overview;
        _isRankingLoading = false;
        _isMatchLoading = true;
        _isKfaLoading = shouldLoadKfa;
        _hadError = false;
      });
      unawaited(_loadMatchOverview(token));
      if (shouldLoadKfa) {
        unawaited(_loadKfaMatchOverview(token));
      }
    } catch (_) {
      if (!mounted || token != _loadToken) return;
      setState(() {
        _isRankingLoading = false;
        _isMatchLoading = false;
        _isKfaLoading = false;
        _hadError = true;
      });
    }
  }

  Future<void> _loadMatchOverview(int token) async {
    try {
      final matchOverview = await _service.fetchMatchOverview(
        gender: _rankingGender,
      );
      if (!mounted || token != _loadToken) return;
      setState(() {
        final current = _overview;
        _overview = current == null
            ? matchOverview
            : current.copyWith(
                lastUpdatedAt:
                    current.lastUpdatedAt ?? matchOverview.lastUpdatedAt,
                nextUpdatedAt:
                    current.nextUpdatedAt ?? matchOverview.nextUpdatedAt,
                recentResults: matchOverview.recentResults,
                upcomingFixtures: matchOverview.upcomingFixtures,
              );
        _isMatchLoading = false;
      });
    } catch (_) {
      if (!mounted || token != _loadToken) return;
      setState(() {
        _isMatchLoading = false;
      });
    }
  }

  Future<void> _loadKfaMatchOverview(int token) async {
    final overview = await _service.fetchKfaMatchOverview();
    if (!mounted || token != _loadToken) return;
    setState(() {
      _kfaRecentResults = overview.recentResults;
      _kfaUpcomingFixtures = overview.upcomingFixtures;
      _isKfaLoading = false;
    });
  }

  bool get _isKoreanLocale =>
      Localizations.localeOf(context).languageCode == 'ko';

  Future<void> _openCountryDetail(FifaRankingEntry entry) async {
    final overview = _overview;
    final recentMatches = overview == null
        ? const <FifaAMatchEntry>[]
        : _matchesForCountry(overview.recentResults, entry.countryCode);
    final upcomingMatches = overview == null
        ? const <FifaAMatchEntry>[]
        : _matchesForCountry(overview.upcomingFixtures, entry.countryCode);
    await Navigator.of(context).push(
      AppPageRoute(
        builder: (_) => FifaCountryDetailScreen(
          rankingEntry: entry,
          recentMatches: recentMatches,
          upcomingMatches: upcomingMatches,
        ),
      ),
    );
  }

  List<FifaAMatchEntry> _matchesForCountry(
    List<FifaAMatchEntry> matches,
    String countryCode,
  ) {
    return matches
        .where(
          (match) =>
              match.homeCountryCode == countryCode ||
              match.awayCountryCode == countryCode,
        )
        .toList(growable: false);
  }

  Future<void> _openFifaMatchDetail(FifaAMatchEntry match) async {
    final detailFuture = _service.fetchMatchDetail(match: match);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) =>
          _FifaMatchDetailSheet(match: match, detailFuture: detailFuture),
    );
  }

  Future<void> _openKfaMatchDetail(KfaMatchEntry match) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => _KfaMatchDetailSheet(match: match),
    );
  }

  Future<void> _openOfficialRankingPage() async {
    final uri = Uri.parse(_rankingGender.officialRankingUrl);
    await launchUrl(
      uri,
      mode: LaunchMode.inAppBrowserView,
      browserConfiguration: const BrowserConfiguration(showTitle: true),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(44),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftInfoChip extends StatelessWidget {
  final String label;

  const _SoftInfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(188),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: const Color(0xFF123B6E),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RankingRow extends StatelessWidget {
  final FifaRankingEntry entry;
  final VoidCallback? onTap;

  const _RankingRow({required this.entry, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Color movementColor;
    IconData movementIcon;
    if (entry.rankMovement > 0) {
      movementColor = const Color(0xFF1E8E5A);
      movementIcon = Icons.arrow_upward_rounded;
    } else if (entry.rankMovement < 0) {
      movementColor = const Color(0xFFD24A43);
      movementIcon = Icons.arrow_downward_rounded;
    } else {
      movementColor = scheme.outline;
      movementIcon = Icons.remove_rounded;
    }

    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: 34,
                child: Text(
                  '${entry.rank}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _CountryFlag(
                countryCode: entry.countryCode,
                size: 28,
                radius: 10,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.teamName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.confederation,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: movementColor.withAlpha(18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(movementIcon, size: 15, color: movementColor),
                    const SizedBox(width: 4),
                    Text(
                      '${entry.rankMovement.abs()}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: movementColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 74,
                child: Text(
                  entry.points.toStringAsFixed(2),
                  textAlign: TextAlign.right,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: scheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchRow extends StatelessWidget {
  final FifaAMatchEntry match;
  final VoidCallback onTap;

  const _MatchRow({required this.match, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final l10n = AppLocalizations.of(context)!;
    final metaParts = <String>[
      DateFormat('M.d (EEE) HH:mm', locale).format(match.kickoffAt.toLocal()),
      if (match.stage.trim().isNotEmpty) match.stage.trim(),
      if (match.city.trim().isNotEmpty) match.city.trim(),
      if (match.venue.trim().isNotEmpty) match.venue.trim(),
    ];
    final statusLabel = switch (match.status) {
      FifaAMatchStatus.finished => l10n.fifaHubMatchStatusResult,
      FifaAMatchStatus.live => l10n.fifaHubMatchStatusLive,
      FifaAMatchStatus.scheduled => l10n.fifaHubMatchStatusFixture,
    };
    final statusColor = switch (match.status) {
      FifaAMatchStatus.finished => const Color(0xFF1B5E20),
      FifaAMatchStatus.live => const Color(0xFFC62828),
      FifaAMatchStatus.scheduled => const Color(0xFF355C7D),
    };

    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      statusLabel,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      match.competition,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                metaParts.join(' · '),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _TeamLine(
                      countryCode: match.homeCountryCode,
                      name: match.homeTeamName,
                      alignEnd: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 54,
                    child: Center(
                      child: match.hasScore
                          ? Text(
                              '${match.homeScore}-${match.awayScore}',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            )
                          : Icon(
                              match.status == FifaAMatchStatus.live
                                  ? Icons.bolt_rounded
                                  : Icons.schedule_outlined,
                              size: 20,
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TeamLine(
                      countryCode: match.awayCountryCode,
                      name: match.awayTeamName,
                      alignEnd: true,
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

class _KfaMatchRow extends StatelessWidget {
  final KfaMatchEntry match;
  final VoidCallback onTap;

  const _KfaMatchRow({required this.match, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final metaParts = <String>[
      [
        match.dateLabel,
        match.timeLabel,
      ].where((part) => part.isNotEmpty).join(' '),
      if (match.venue.trim().isNotEmpty) match.venue.trim(),
    ].where((part) => part.trim().isNotEmpty).toList(growable: false);
    final isResult = match.status == KfaMatchStatus.finished;
    final statusLabel = isResult
        ? l10n.fifaHubMatchStatusResult
        : l10n.fifaHubMatchStatusFixture;
    final statusColor = isResult
        ? const Color(0xFF1B5E20)
        : const Color(0xFF355C7D);

    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      statusLabel,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      match.competition,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ],
              ),
              if (metaParts.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  metaParts.join(' · '),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _KfaTeamLine(
                      name: match.homeTeamName,
                      alignEnd: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 54,
                    child: Center(
                      child: match.hasScore
                          ? Text(
                              '${match.homeScore}-${match.awayScore}',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            )
                          : const Icon(Icons.schedule_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _KfaTeamLine(
                      name: match.awayTeamName,
                      alignEnd: true,
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

class _FifaMatchDetailSheet extends StatelessWidget {
  final FifaAMatchEntry match;
  final Future<FifaAMatchDetail?> detailFuture;

  const _FifaMatchDetailSheet({
    required this.match,
    required this.detailFuture,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    return FutureBuilder<FifaAMatchDetail?>(
      future: detailFuture,
      builder: (context, snapshot) {
        final detail = snapshot.data;
        final effectiveMatch = detail?.match ?? match;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final kickoffLabel = DateFormat(
          'yyyy.MM.dd (EEE) HH:mm',
          locale,
        ).format(effectiveMatch.kickoffAt.toLocal());
        final summaryTitle = effectiveMatch.status == FifaAMatchStatus.scheduled
            ? l10n.fifaMatchDetailFixtureSummaryTitle
            : l10n.fifaMatchDetailResultSummaryTitle;

        return _MatchDetailShell(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MatchDetailTitle(
                title: l10n.fifaMatchDetailTitle,
                sourceNote: l10n.fifaMatchDetailFifaSourceNote,
              ),
              const SizedBox(height: 16),
              _FifaMatchScoreboard(match: effectiveMatch),
              const SizedBox(height: 14),
              _MatchDetailSection(
                title: summaryTitle,
                child: _MatchDetailInfoRows(
                  items: [
                    _MatchDetailInfoItem(
                      label: l10n.fifaMatchDetailCompetitionLabel,
                      value: effectiveMatch.competition,
                    ),
                    _MatchDetailInfoItem(
                      label: l10n.fifaMatchDetailKickoffLabel,
                      value: kickoffLabel,
                    ),
                    _MatchDetailInfoItem(
                      label: l10n.fifaMatchDetailStageLabel,
                      value: effectiveMatch.stage,
                    ),
                    _MatchDetailInfoItem(
                      label: l10n.fifaMatchDetailVenueLabel,
                      value: effectiveMatch.venue,
                    ),
                    _MatchDetailInfoItem(
                      label: l10n.fifaMatchDetailCityLabel,
                      value: effectiveMatch.city,
                    ),
                    _MatchDetailInfoItem(
                      label: l10n.fifaMatchDetailMatchIdLabel,
                      value: effectiveMatch.matchId,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _FifaAdvancedMatchDetail(
                match: effectiveMatch,
                detail: detail,
                isLoading: isLoading,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _KfaMatchDetailSheet extends StatelessWidget {
  final KfaMatchEntry match;

  const _KfaMatchDetailSheet({required this.match});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateLabel = [
      match.dateLabel,
      match.timeLabel,
    ].where((part) => part.trim().isNotEmpty).join(' ');
    final summaryTitle = match.status == KfaMatchStatus.scheduled
        ? l10n.fifaMatchDetailFixtureSummaryTitle
        : l10n.fifaMatchDetailResultSummaryTitle;

    return _MatchDetailShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MatchDetailTitle(
            title: l10n.fifaMatchDetailTitle,
            sourceNote: l10n.newsOfficialSourceKfa,
          ),
          const SizedBox(height: 16),
          _KfaMatchScoreboard(match: match),
          const SizedBox(height: 14),
          _MatchDetailSection(
            title: summaryTitle,
            child: _MatchDetailInfoRows(
              items: [
                _MatchDetailInfoItem(
                  label: l10n.fifaMatchDetailCompetitionLabel,
                  value: match.competition,
                ),
                _MatchDetailInfoItem(
                  label: l10n.fifaMatchDetailDateLabel,
                  value: dateLabel,
                ),
                _MatchDetailInfoItem(
                  label: l10n.fifaMatchDetailVenueLabel,
                  value: match.venue,
                ),
                _MatchDetailInfoItem(
                  label: l10n.fifaMatchDetailMatchIdLabel,
                  value: match.matchId,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _UnavailableNotice(message: l10n.fifaMatchDetailKfaSourceNote),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                unawaited(
                  launchUrl(
                    match.sourceUrl,
                    mode: LaunchMode.inAppBrowserView,
                    browserConfiguration: const BrowserConfiguration(
                      showTitle: true,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: Text(l10n.fifaMatchDetailOpenSource),
              style: TextButton.styleFrom(
                minimumSize: const Size(1, 40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchDetailShell extends StatelessWidget {
  final Widget child;

  const _MatchDetailShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.86;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _MatchDetailTitle extends StatelessWidget {
  final String title;
  final String sourceNote;

  const _MatchDetailTitle({required this.title, required this.sourceNote});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(
          sourceNote,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _FifaMatchScoreboard extends StatelessWidget {
  final FifaAMatchEntry match;

  const _FifaMatchScoreboard({required this.match});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _ScoreboardFrame(
      statusLabel: _fifaStatusLabel(l10n, match.status),
      statusColor: _fifaStatusColor(match.status),
      home: _ScoreTeam(
        label: l10n.fifaMatchDetailHomeTeamLabel,
        name: match.homeTeamName,
        countryCode: match.homeCountryCode,
        alignEnd: false,
      ),
      away: _ScoreTeam(
        label: l10n.fifaMatchDetailAwayTeamLabel,
        name: match.awayTeamName,
        countryCode: match.awayCountryCode,
        alignEnd: true,
      ),
      scoreText: match.hasScore
          ? '${match.homeScore}-${match.awayScore}'
          : l10n.fifaMatchDetailVersusLabel,
    );
  }
}

class _KfaMatchScoreboard extends StatelessWidget {
  final KfaMatchEntry match;

  const _KfaMatchScoreboard({required this.match});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isResult = match.status == KfaMatchStatus.finished;
    return _ScoreboardFrame(
      statusLabel: isResult
          ? l10n.fifaHubMatchStatusResult
          : l10n.fifaHubMatchStatusFixture,
      statusColor: isResult ? const Color(0xFF1B5E20) : const Color(0xFF355C7D),
      home: _ScoreTeam(
        label: l10n.fifaMatchDetailHomeTeamLabel,
        name: match.homeTeamName,
        alignEnd: false,
      ),
      away: _ScoreTeam(
        label: l10n.fifaMatchDetailAwayTeamLabel,
        name: match.awayTeamName,
        alignEnd: true,
      ),
      scoreText: match.hasScore
          ? '${match.homeScore}-${match.awayScore}'
          : l10n.fifaMatchDetailVersusLabel,
    );
  }
}

class _ScoreboardFrame extends StatelessWidget {
  final String statusLabel;
  final Color statusColor;
  final _ScoreTeam home;
  final _ScoreTeam away;
  final String scoreText;

  const _ScoreboardFrame({
    required this.statusLabel,
    required this.statusColor,
    required this.home,
    required this.away,
    required this.scoreText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(child: home),
          const SizedBox(width: 10),
          Column(
            children: [
              Text(
                scoreText,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(child: away),
        ],
      ),
    );
  }
}

class _ScoreTeam extends StatelessWidget {
  final String label;
  final String name;
  final String countryCode;
  final bool alignEnd;

  const _ScoreTeam({
    required this.label,
    required this.name,
    this.countryCode = '',
    required this.alignEnd,
  });

  @override
  Widget build(BuildContext context) {
    final flag = countryCode.trim().isEmpty
        ? null
        : _CountryFlag(countryCode: countryCode, size: 32, radius: 10);
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (flag != null) ...[const SizedBox(height: 8), flag],
        const SizedBox(height: 8),
        Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: alignEnd ? TextAlign.right : TextAlign.left,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _FifaAdvancedMatchDetail extends StatelessWidget {
  final FifaAMatchEntry match;
  final FifaAMatchDetail? detail;
  final bool isLoading;

  const _FifaAdvancedMatchDetail({
    required this.match,
    required this.detail,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (isLoading) {
      return _LoadingNotice(message: l10n.fifaMatchDetailAdvancedLoading);
    }
    final loaded = detail;
    if (loaded == null || (!loaded.hasScorers && !loaded.hasPossession)) {
      return _UnavailableNotice(
        message: l10n.fifaMatchDetailAdvancedUnavailable,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MatchDetailSection(
          title: l10n.fifaMatchDetailScorersTitle,
          child: loaded.hasScorers
              ? _ScorersSummary(
                  homeTeamName: match.homeTeamName,
                  awayTeamName: match.awayTeamName,
                  homeScorers: loaded.homeScorers,
                  awayScorers: loaded.awayScorers,
                )
              : _UnavailableNotice(
                  message: l10n.fifaMatchDetailScorersUnavailable,
                ),
        ),
        const SizedBox(height: 12),
        _MatchDetailSection(
          title: l10n.fifaMatchDetailPossessionTitle,
          child: loaded.hasPossession
              ? _PossessionSummary(
                  homeTeamName: match.homeTeamName,
                  awayTeamName: match.awayTeamName,
                  homePossession: loaded.homePossession!,
                  awayPossession: loaded.awayPossession!,
                )
              : _UnavailableNotice(
                  message: l10n.fifaMatchDetailPossessionUnavailable,
                ),
        ),
      ],
    );
  }
}

class _MatchDetailSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _MatchDetailSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _MatchDetailInfoRows extends StatelessWidget {
  final List<_MatchDetailInfoItem> items;

  const _MatchDetailInfoRows({required this.items});

  @override
  Widget build(BuildContext context) {
    final visibleItems = items
        .where((item) => item.value.trim().isNotEmpty)
        .toList(growable: false);
    return Column(
      children: [
        for (final entry in visibleItems.asMap().entries) ...[
          if (entry.key > 0) const Divider(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 88,
                child: Text(
                  entry.value.label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  entry.value.value,
                  textAlign: TextAlign.right,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _MatchDetailInfoItem {
  final String label;
  final String value;

  const _MatchDetailInfoItem({required this.label, required this.value});
}

class _ScorersSummary extends StatelessWidget {
  final String homeTeamName;
  final String awayTeamName;
  final List<FifaMatchScorer> homeScorers;
  final List<FifaMatchScorer> awayScorers;

  const _ScorersSummary({
    required this.homeTeamName,
    required this.awayTeamName,
    required this.homeScorers,
    required this.awayScorers,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ScorerLine(teamName: homeTeamName, scorers: homeScorers),
        const Divider(height: 16),
        _ScorerLine(teamName: awayTeamName, scorers: awayScorers),
      ],
    );
  }
}

class _ScorerLine extends StatelessWidget {
  final String teamName;
  final List<FifaMatchScorer> scorers;

  const _ScorerLine({required this.teamName, required this.scorers});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = scorers.isEmpty
        ? '-'
        : scorers
              .map((scorer) {
                final name = scorer.playerName.trim().isEmpty
                    ? l10n.fifaMatchDetailUnknownScorer
                    : scorer.playerName.trim();
                final minute = scorer.minute.trim();
                return minute.isEmpty ? name : '$minute $name';
              })
              .join(', ');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            teamName,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 5,
          child: Text(
            text,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _PossessionSummary extends StatelessWidget {
  final String homeTeamName;
  final String awayTeamName;
  final double homePossession;
  final double awayPossession;

  const _PossessionSummary({
    required this.homeTeamName,
    required this.awayTeamName,
    required this.homePossession,
    required this.awayPossession,
  });

  @override
  Widget build(BuildContext context) {
    final homeFlex = homePossession.round().clamp(1, 99).toInt();
    final awayFlex = awayPossession.round().clamp(1, 99).toInt();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 12,
            child: Row(
              children: [
                Expanded(
                  flex: homeFlex,
                  child: Container(color: const Color(0xFF1B5E20)),
                ),
                Expanded(
                  flex: awayFlex,
                  child: Container(color: const Color(0xFF355C7D)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                '$homeTeamName ${_formatPercent(homePossession)}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            Expanded(
              child: Text(
                '${_formatPercent(awayPossession)} $awayTeamName',
                textAlign: TextAlign.right,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LoadingNotice extends StatelessWidget {
  final String message;

  const _LoadingNotice({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _UnavailableNotice extends StatelessWidget {
  final String message;

  const _UnavailableNotice({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withAlpha(120),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(message, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

String _fifaStatusLabel(AppLocalizations l10n, FifaAMatchStatus status) {
  return switch (status) {
    FifaAMatchStatus.finished => l10n.fifaHubMatchStatusResult,
    FifaAMatchStatus.live => l10n.fifaHubMatchStatusLive,
    FifaAMatchStatus.scheduled => l10n.fifaHubMatchStatusFixture,
  };
}

Color _fifaStatusColor(FifaAMatchStatus status) {
  return switch (status) {
    FifaAMatchStatus.finished => const Color(0xFF1B5E20),
    FifaAMatchStatus.live => const Color(0xFFC62828),
    FifaAMatchStatus.scheduled => const Color(0xFF355C7D),
  };
}

String _formatPercent(double value) {
  final rounded = value.roundToDouble();
  if ((value - rounded).abs() < 0.05) {
    return '${rounded.toInt()}%';
  }
  return '${value.toStringAsFixed(1)}%';
}

class _KfaTeamLine extends StatelessWidget {
  final String name;
  final bool alignEnd;

  const _KfaTeamLine({required this.name, required this.alignEnd});

  @override
  Widget build(BuildContext context) {
    return Text(
      name,
      textAlign: alignEnd ? TextAlign.right : TextAlign.left,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _TeamLine extends StatelessWidget {
  final String countryCode;
  final String name;
  final bool alignEnd;

  const _TeamLine({
    required this.countryCode,
    required this.name,
    required this.alignEnd,
  });

  @override
  Widget build(BuildContext context) {
    final flag = _CountryFlag(countryCode: countryCode, size: 24, radius: 8);
    final nameText = Expanded(
      child: Text(
        name,
        textAlign: alignEnd ? TextAlign.right : TextAlign.left,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
    return Row(
      mainAxisAlignment: alignEnd
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: alignEnd
          ? [nameText, const SizedBox(width: 8), flag]
          : [flag, const SizedBox(width: 8), nameText],
    );
  }
}

class _CountryFlag extends StatelessWidget {
  final String countryCode;
  final double size;
  final double radius;

  const _CountryFlag({
    required this.countryCode,
    required this.size,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size * 0.7,
        child: Image.network(
          'https://api.fifa.com/api/v3/picture/flags-sq-2/$countryCode',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            alignment: Alignment.center,
            child: Text(
              countryCode,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
    );
  }
}
