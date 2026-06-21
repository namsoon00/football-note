import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../application/benchmark_service.dart';
import '../../application/sport_defaults.dart';
import '../../domain/entities/training_entry.dart';
import '../../domain/entities/sport_definition.dart';
import '../../gen/app_localizations.dart';
import '../widgets/app_background.dart';

class AverageBenchmarkScreen extends StatefulWidget {
  final List<TrainingEntry> entries;
  final int? ageYears;
  final int? soccerYears;
  final BenchmarkService benchmarkService;
  final String sportId;

  const AverageBenchmarkScreen({
    super.key,
    required this.entries,
    required this.ageYears,
    required this.soccerYears,
    required this.benchmarkService,
    this.sportId = SportCatalog.defaultSportId,
  });

  @override
  State<AverageBenchmarkScreen> createState() => _AverageBenchmarkScreenState();
}

class _AverageBenchmarkScreenState extends State<AverageBenchmarkScreen> {
  bool _refreshing = false;
  DateTime? _syncedAt;

  @override
  void initState() {
    super.initState();
    _syncedAt = widget.benchmarkService.lastSyncedAt();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sources = benchmarkSources(sportId: widget.sportId);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.benchmarkReferencesTitle)),
      body: AppBackground(
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
                children: [
                  _AgeBenchmarkSection(
                    currentAgeYears: widget.ageYears,
                    soccerYears: widget.soccerYears,
                    sportId: widget.sportId,
                    benchmarkService: widget.benchmarkService,
                  ),
                  const SizedBox(height: 18),
                  _SourceSection(
                    title: l10n.benchmarkReferencesTitle,
                    sources: sources,
                    syncedAt: _syncedAt,
                    refreshing: _refreshing,
                    referenceNote: l10n.benchmarkReferenceNote,
                    onRefresh: _refreshBenchmarkData,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _refreshBenchmarkData() async {
    if (_refreshing) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _refreshing = true);
    try {
      await widget.benchmarkService.refreshFromExternalIfNeeded(force: true);
      if (!mounted) return;
      setState(() => _syncedAt = widget.benchmarkService.lastSyncedAt());
      final suffix = _syncedAt == null
          ? ''
          : ' ${l10n.benchmarkLastSynced(_formatSyncTime(context, _syncedAt!))}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.benchmarkRefreshSuccess}$suffix')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.benchmarkRefreshFailed)));
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }
}

class _AgeBenchmarkSection extends StatelessWidget {
  final int? currentAgeYears;
  final int? soccerYears;
  final String sportId;
  final BenchmarkService benchmarkService;

  const _AgeBenchmarkSection({
    required this.currentAgeYears,
    required this.soccerYears,
    required this.sportId,
    required this.benchmarkService,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final currentAge = currentAgeYears?.clamp(6, 18);
    final rowColor = theme.colorScheme.primary.withValues(alpha: 0.08);
    final conditioningLabel = SportDefaults.secondaryConditioningLabel(
      l10n: l10n,
      sportId: sportId,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.table_chart_outlined,
          title: l10n.benchmarkAgeTableTitle,
        ),
        const SizedBox(height: 6),
        Text(
          l10n.benchmarkAgeTableNote,
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingTextStyle: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            columns: [
              DataColumn(label: Text(l10n.benchmarkAgeColumnAge)),
              DataColumn(label: Text(l10n.benchmarkAgeColumnHeight)),
              DataColumn(label: Text(l10n.benchmarkAgeColumnWeight)),
              DataColumn(
                label: Text(
                  l10n.benchmarkAgeColumnConditioning(conditioningLabel),
                ),
              ),
              DataColumn(label: Text(l10n.benchmarkAgeColumnWeeklyTarget)),
            ],
            rows: [
              for (var age = 6; age <= 18; age++)
                _buildRow(
                  context: context,
                  age: age,
                  selected: currentAge == age,
                  rowColor: rowColor,
                ),
            ],
          ),
        ),
      ],
    );
  }

  DataRow _buildRow({
    required BuildContext context,
    required int age,
    required bool selected,
    required Color rowColor,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final benchmark = benchmarkService.physicalBenchmarkForAge(
      age,
      sportId: sportId,
    );
    final target = benchmarkTargetForSport(
      sportId: sportId,
      ageYears: age,
      sportYears: soccerYears,
    );
    return DataRow(
      color: selected ? WidgetStatePropertyAll<Color>(rowColor) : null,
      cells: [
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.benchmarkAgeValue(age)),
              if (selected) ...[
                const SizedBox(width: 8),
                _CurrentAgeBadge(label: l10n.benchmarkAgeCurrentBadge),
              ],
            ],
          ),
        ),
        DataCell(Text('${benchmark.heightCmAvg.toStringAsFixed(1)}cm')),
        DataCell(Text('${benchmark.weightKgAvg.toStringAsFixed(1)}kg')),
        DataCell(Text(l10n.benchmarkAgeLiftingValue(
          benchmark.liftsPerSessionAvg,
        ))),
        DataCell(Text(l10n.benchmarkAgeWeeklyTargetValue(
          target.weeklyMinutesTarget,
          target.weeklySessionsTarget,
        ))),
      ],
    );
  }
}

class _CurrentAgeBadge extends StatelessWidget {
  final String label;

  const _CurrentAgeBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SourceSection extends StatelessWidget {
  final String title;
  final List<BenchmarkSource> sources;
  final DateTime? syncedAt;
  final bool refreshing;
  final String referenceNote;
  final VoidCallback onRefresh;

  const _SourceSection({
    required this.title,
    required this.sources,
    required this.syncedAt,
    required this.refreshing,
    required this.referenceNote,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _SectionTitle(icon: Icons.link, title: title),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: refreshing ? null : onRefresh,
              icon: refreshing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync_outlined, size: 18),
              label: Text(
                refreshing
                    ? l10n.benchmarkRefreshInProgress
                    : l10n.benchmarkRefreshAction,
              ),
            ),
          ],
        ),
        if (syncedAt != null) ...[
          const SizedBox(height: 4),
          Text(
            l10n.benchmarkLastSynced(_formatSyncTime(context, syncedAt!)),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 6),
        Text(referenceNote, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        ...sources.map(
          (source) => Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _openLink(source.url),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: Text(source.title, textAlign: TextAlign.left),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
  }
}

String _formatSyncTime(BuildContext context, DateTime value) {
  final localeName = Localizations.localeOf(context).toLanguageTag();
  return DateFormat.yMMMd(localeName).add_Hm().format(value.toLocal());
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}
