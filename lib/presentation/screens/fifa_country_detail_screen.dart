import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../application/fifa_world_overview_service.dart';
import '../../domain/entities/fifa_world_overview.dart';
import '../../gen/app_localizations.dart';
import '../widgets/app_background.dart';
import '../widgets/watch_cart/watch_cart_card.dart';

class FifaCountryDetailScreen extends StatefulWidget {
  final FifaRankingEntry rankingEntry;
  final List<FifaAMatchEntry> recentMatches;
  final List<FifaAMatchEntry> upcomingMatches;

  const FifaCountryDetailScreen({
    super.key,
    required this.rankingEntry,
    required this.recentMatches,
    required this.upcomingMatches,
  });

  @override
  State<FifaCountryDetailScreen> createState() =>
      _FifaCountryDetailScreenState();
}

class _FifaCountryDetailScreenState extends State<FifaCountryDetailScreen> {
  late final FifaWorldOverviewService _service;
  FifaTeamDetail? _teamDetail;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _service = FifaWorldOverviewService();
    _loadTeamDetail();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.rankingEntry;
    return Scaffold(
      appBar: AppBar(title: Text(entry.teamName)),
      body: AppBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadTeamDetail,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _buildHeroCard(context),
                const SizedBox(height: 12),
                _buildRankingSummaryCard(context),
                const SizedBox(height: 12),
                _buildProfileCard(context),
                const SizedBox(height: 12),
                _buildMatchCard(
                  context,
                  title: AppLocalizations.of(
                    context,
                  )!
                      .fifaCountryDetailUpcomingMatchesTitle,
                  matches: widget.upcomingMatches,
                ),
                const SizedBox(height: 12),
                _buildMatchCard(
                  context,
                  title: AppLocalizations.of(
                    context,
                  )!
                      .fifaCountryDetailRecentMatchesTitle,
                  matches: widget.recentMatches,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    final entry = widget.rankingEntry;
    final theme = Theme.of(context);
    return WatchCartCard(
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Color(0xFF0E2E4E), Color(0xFF246A85), Color(0xFFEAF3EF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.teamName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '#${entry.rank} · ${entry.points.toStringAsFixed(2)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white.withAlpha(230),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _DetailChip(label: entry.confederation),
                        _DetailChip(label: entry.countryCode),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _DetailCountryFlag(
                countryCode: entry.countryCode,
                size: 74,
                radius: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRankingSummaryCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final entry = widget.rankingEntry;
    return WatchCartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.fifaCountryDetailRankingSummaryTitle,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _InfoGrid(
            items: [
              _InfoItem(
                  l10n.fifaCountryDetailCurrentRankLabel, '#${entry.rank}'),
              _InfoItem(
                l10n.fifaCountryDetailPreviousRankLabel,
                '#${entry.previousRank}',
              ),
              _InfoItem(
                l10n.fifaCountryDetailPointsLabel,
                entry.points.toStringAsFixed(2),
              ),
              _InfoItem(
                l10n.fifaCountryDetailPointChangeLabel,
                _formatSigned(entry.pointsMovement),
              ),
              _InfoItem(l10n.fifaCountryDetailConfederationLabel,
                  entry.confederation),
              _InfoItem(l10n.fifaCountryDetailTeamIdLabel, entry.teamId),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final detail = _teamDetail;
    return WatchCartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.fifaCountryDetailTeamProfileTitle,
                  style: Theme.of(
                    context,
                  )
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              if (_isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (!_isLoading && (detail == null || !detail.hasTeamProfile))
            Text(
              l10n.fifaCountryDetailProfileUnavailable,
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else if (detail != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoGrid(
                  items: [
                    _InfoItem(
                      l10n.fifaCountryDetailAbbreviationLabel,
                      detail.abbreviation,
                    ),
                    _InfoItem(
                      l10n.fifaCountryDetailCountryCodeLabel,
                      detail.countryCode,
                    ),
                    _InfoItem(
                      l10n.fifaCountryDetailConfederationLabel,
                      detail.confederationCode,
                    ),
                    _InfoItem(
                      l10n.fifaCountryDetailFoundationYearLabel,
                      detail.foundationYear?.toString() ?? '',
                    ),
                    _InfoItem(l10n.fifaCountryDetailCityLabel, detail.city),
                    _InfoItem(
                      l10n.fifaCountryDetailStadiumLabel,
                      detail.stadiumName,
                    ),
                    _InfoItem(
                      l10n.fifaCountryDetailAddressLabel,
                      detail.street,
                      wide: true,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.fifaCountryDetailProfileSource,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (detail.officialSite.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    onPressed: () => _openUrl(detail.officialSite),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: Text(l10n.newsOpenOfficialSource),
                  ),
                ],
              ],
            )
          else
            const LinearProgressIndicator(minHeight: 2),
        ],
      ),
    );
  }

  Widget _buildMatchCard(
    BuildContext context, {
    required String title,
    required List<FifaAMatchEntry> matches,
  }) {
    final l10n = AppLocalizations.of(context)!;
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
          const SizedBox(height: 12),
          if (matches.isEmpty)
            Text(
              l10n.fifaCountryDetailMatchesUnavailable,
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            ...matches.asMap().entries.map((entry) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: entry.key == matches.length - 1 ? 0 : 10,
                ),
                child: _CountryDetailMatchRow(match: entry.value),
              );
            }),
        ],
      ),
    );
  }

  Future<void> _loadTeamDetail() async {
    setState(() {
      _isLoading = true;
    });
    final detail = await _service.fetchTeamDetail(
      teamId: widget.rankingEntry.teamId,
    );
    if (!mounted) return;
    setState(() {
      _teamDetail = detail;
      _isLoading = false;
    });
  }

  Future<void> _openUrl(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) return;
    await launchUrl(
      uri,
      mode: LaunchMode.inAppBrowserView,
      browserConfiguration: const BrowserConfiguration(showTitle: true),
    );
  }

  String _formatSigned(double value) {
    if (value > 0) return '+${value.toStringAsFixed(2)}';
    return value.toStringAsFixed(2);
  }
}

class _InfoGrid extends StatelessWidget {
  final List<_InfoItem> items;

  const _InfoGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    final visibleItems = items
        .where((item) => item.value.trim().isNotEmpty)
        .toList(growable: false);
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        final itemWidth = (constraints.maxWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: visibleItems.map((item) {
            return SizedBox(
              width: item.wide ? constraints.maxWidth : itemWidth,
              child: _InfoTile(label: item.label, value: item.value),
            );
          }).toList(growable: false),
        );
      },
    );
  }
}

class _InfoItem {
  final String label;
  final String value;
  final bool wide;

  const _InfoItem(this.label, this.value, {this.wide = false});
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _CountryDetailMatchRow extends StatelessWidget {
  final FifaAMatchEntry match;

  const _CountryDetailMatchRow({required this.match});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final l10n = AppLocalizations.of(context)!;
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
    final metaParts = <String>[
      DateFormat('M.d (EEE) HH:mm', locale).format(match.kickoffAt.toLocal()),
      if (match.competition.trim().isNotEmpty) match.competition.trim(),
      if (match.city.trim().isNotEmpty) match.city.trim(),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
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
                  metaParts.join(' · '),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  match.homeTeamName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 56,
                child: Center(
                  child: match.hasScore
                      ? Text(
                          '${match.homeScore}-${match.awayScore}',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        )
                      : const Icon(Icons.schedule_outlined, size: 20),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  match.awayTeamName,
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final String label;

  const _DetailChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(44),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _DetailCountryFlag extends StatelessWidget {
  final String countryCode;
  final double size;
  final double radius;

  const _DetailCountryFlag({
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
