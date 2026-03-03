import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../application/benchmark_service.dart';
import '../../domain/entities/training_entry.dart';
import '../widgets/app_background.dart';

class AverageBenchmarkScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final sources = benchmarkSources();
    final syncedAt = benchmarkService.lastSyncedAt();

    return Scaffold(
      appBar: AppBar(title: Text(isKo ? '기준 출처' : 'References')),
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
                    title: isKo ? '기준 출처' : 'References',
                    sources: sources,
                    syncedAt: syncedAt,
                    isKo: isKo,
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

class _SourceSection extends StatelessWidget {
  final String title;
  final List<BenchmarkSource> sources;
  final DateTime? syncedAt;
  final bool isKo;

  const _SourceSection({
    required this.title,
    required this.sources,
    required this.syncedAt,
    required this.isKo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(icon: Icons.link, title: title),
        if (syncedAt != null) ...[
          const SizedBox(height: 4),
          Text(
            isKo
                ? '최근 동기화: ${syncedAt!.toLocal().toString().substring(0, 16)}'
                : 'Last sync: ${syncedAt!.toLocal().toString().substring(0, 16)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 6),
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
