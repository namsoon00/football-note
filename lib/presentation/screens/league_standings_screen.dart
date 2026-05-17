import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:football_note/gen/app_localizations.dart';

import '../../application/league_standings_service.dart';
import '../../domain/entities/league_standings.dart';
import '../widgets/app_background.dart';

class LeagueStandingsScreen extends StatefulWidget {
  final LeagueStandingsType initialType;
  final LeagueStandingsService? service;

  const LeagueStandingsScreen({
    super.key,
    this.initialType = LeagueStandingsType.premierLeague,
    this.service,
  });

  @override
  State<LeagueStandingsScreen> createState() => _LeagueStandingsScreenState();
}

class _LeagueStandingsScreenState extends State<LeagueStandingsScreen> {
  late final LeagueStandingsService _service;
  late final bool _ownsService;
  late LeagueStandingsType _selectedType;
  final Map<LeagueStandingsType, LeagueStandingsSnapshot> _cache = {};
  Future<LeagueStandingsSnapshot>? _future;

  @override
  void initState() {
    super.initState();
    _ownsService = widget.service == null;
    _service = widget.service ?? LeagueStandingsService();
    _selectedType = widget.initialType;
    _future = _load(_selectedType);
  }

  @override
  void dispose() {
    if (_ownsService) {
      _service.dispose();
    }
    super.dispose();
  }

  Future<LeagueStandingsSnapshot> _load(
    LeagueStandingsType type, {
    bool refresh = false,
  }) async {
    if (!refresh) {
      final cached = _cache[type];
      if (cached != null) return cached;
    }
    final snapshot = await _service.fetch(type);
    _cache[type] = snapshot;
    return snapshot;
  }

  void _selectType(LeagueStandingsType type) {
    if (type == _selectedType) return;
    setState(() {
      _selectedType = type;
      _future = _load(type);
    });
  }

  Future<void> _refresh() async {
    final future = _load(_selectedType, refresh: true);
    setState(() => _future = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.newsLeagueStandingsTitle),
        actions: [
          FutureBuilder<LeagueStandingsSnapshot>(
            future: _future,
            builder: (context, snapshot) {
              final sourceUrl = snapshot.data?.sourceUrl.trim() ?? '';
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
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<LeagueStandingsType>(
                    segments: [
                      ButtonSegment<LeagueStandingsType>(
                        value: LeagueStandingsType.premierLeague,
                        icon: const Icon(Icons.shield_outlined, size: 18),
                        label: Text(l10n.newsPremierLeagueStandingsTitle),
                      ),
                      ButtonSegment<LeagueStandingsType>(
                        value: LeagueStandingsType.championsLeague,
                        icon: const Icon(Icons.emoji_events_outlined, size: 18),
                        label: Text(l10n.newsChampionsLeagueStandingsTitle),
                      ),
                    ],
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
                child: FutureBuilder<LeagueStandingsSnapshot>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return _MessageState(
                        icon: Icons.cloud_off_outlined,
                        title: l10n.newsLeagueStandingsError,
                        onRetry: _refresh,
                      );
                    }
                    final data = snapshot.data;
                    if (data == null || data.entries.isEmpty) {
                      return _MessageState(
                        icon: Icons.table_chart_outlined,
                        title: l10n.newsLeagueStandingsEmpty,
                        onRetry: _refresh,
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: _refresh,
                      child: _StandingsTable(snapshot: data),
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

class _StandingsTable extends StatelessWidget {
  final LeagueStandingsSnapshot snapshot;

  const _StandingsTable({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final fetchedText = DateFormat.yMMMd(
      locale,
    ).add_Hm().format(snapshot.fetchedAt.toLocal());
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
      children: [
        Text(
          snapshot.leagueName,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(
          [
            if (snapshot.seasonName.trim().isNotEmpty) snapshot.seasonName,
            l10n.newsLeagueStandingsUpdated(fetchedText),
          ].join(' · '),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
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
    final compactName = entry.teamName.trim();
    final initials = entry.teamShortName.trim().isNotEmpty
        ? entry.teamShortName.trim()
        : compactName.isEmpty
            ? '?'
            : compactName
                .substring(0, compactName.length < 2 ? compactName.length : 2)
                .toUpperCase();
    final logoUrl = entry.logoUrl.trim();
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      clipBehavior: Clip.antiAlias,
      child: logoUrl.isEmpty
          ? Center(
              child: Text(
                initials,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            )
          : Image.network(
              logoUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Center(
                child: Text(
                  initials,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ),
    );
  }
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
      style: (header
              ? Theme.of(context).textTheme.labelMedium
              : Theme.of(context).textTheme.bodyMedium)
          ?.copyWith(
        fontWeight: header || strong ? FontWeight.w900 : FontWeight.w600,
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
