import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../application/benchmark_service.dart';
import '../../domain/entities/training_entry.dart';
import '../../gen/app_localizations.dart';
import '../widgets/app_background.dart';

class AverageBenchmarkScreen extends StatefulWidget {
  final List<TrainingEntry> entries;
  final int? ageYears;
  final int? soccerYears;
  final BenchmarkService benchmarkService;

  const AverageBenchmarkScreen({
    super.key,
    required this.entries,
    required this.ageYears,
    required this.soccerYears,
    required this.benchmarkService,
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
    final sources = benchmarkSources();

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
