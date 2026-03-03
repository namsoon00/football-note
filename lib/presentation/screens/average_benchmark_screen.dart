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
    final bodyAvg = benchmarkService.physicalBenchmarkForAge(ageYears);
    final trainingAvg = benchmarkTarget(ageYears, soccerYears);
    final sources = benchmarkSources();
    final syncedAt = benchmarkService.lastSyncedAt();

    final sorted = entries.toList()..sort((a, b) => b.date.compareTo(a.date));
    TrainingEntry? latestWithBody;
    for (final entry in sorted) {
      if (entry.heightCm != null || entry.weightKg != null) {
        latestWithBody = entry;
        break;
      }
    }
    latestWithBody ??= sorted.isNotEmpty ? sorted.first : null;
    final latestHeight = latestWithBody?.heightCm;
    final latestWeight = latestWithBody?.weightKg;

    final totalLifts = entries.fold<int>(
      0,
      (sum, e) =>
          sum +
          e.liftingByPart.values.fold<int>(0, (acc, count) => acc + count),
    );
    final avgLiftPerSession =
        entries.isEmpty ? 0.0 : totalLifts.toDouble() / entries.length;

    final now = DateTime.now();
    final recent = entries
        .where((e) => e.date.isAfter(now.subtract(const Duration(days: 28))))
        .toList();
    final recentMinutes = recent.fold<int>(
      0,
      (sum, entry) => sum + entry.durationMinutes,
    );
    final avgWeeklyMinutes = recentMinutes / 4;

    return Scaffold(
      appBar: AppBar(title: Text(isKo ? '평균 비교' : 'Average Benchmarks')),
      body: AppBackground(
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
                children: [
                  _ComparisonSection(
                    isKo: isKo,
                    items: [
                      _ComparisonItem(
                        label: isKo ? '키' : 'Height',
                        current: latestHeight == null
                            ? (isKo ? '미입력' : 'Not set')
                            : '${latestHeight.toStringAsFixed(1)}cm',
                        average: '${bodyAvg.heightCmAvg.toStringAsFixed(1)}cm',
                        gap: latestHeight == null
                            ? (isKo ? '비교 불가' : 'N/A')
                            : _gapText(
                                latestHeight - bodyAvg.heightCmAvg,
                                isKo,
                              ),
                        isPositive: latestHeight != null &&
                            latestHeight - bodyAvg.heightCmAvg >= 0,
                      ),
                      _ComparisonItem(
                        label: isKo ? '몸무게' : 'Weight',
                        current: latestWeight == null
                            ? (isKo ? '미입력' : 'Not set')
                            : '${latestWeight.toStringAsFixed(1)}kg',
                        average: '${bodyAvg.weightKgAvg.toStringAsFixed(1)}kg',
                        gap: latestWeight == null
                            ? (isKo ? '비교 불가' : 'N/A')
                            : _gapText(
                                latestWeight - bodyAvg.weightKgAvg,
                                isKo,
                              ),
                        isPositive: latestWeight != null &&
                            latestWeight - bodyAvg.weightKgAvg >= 0,
                      ),
                      _ComparisonItem(
                        label: isKo ? '리프팅/세션' : 'Lifting/Session',
                        current: isKo
                            ? '${avgLiftPerSession.toStringAsFixed(1)}회'
                            : '${avgLiftPerSession.toStringAsFixed(1)} reps',
                        average: isKo
                            ? '${bodyAvg.liftsPerSessionAvg}회'
                            : '${bodyAvg.liftsPerSessionAvg} reps',
                        gap: _gapText(
                          avgLiftPerSession - bodyAvg.liftsPerSessionAvg,
                          isKo,
                        ),
                        isPositive:
                            avgLiftPerSession - bodyAvg.liftsPerSessionAvg >= 0,
                      ),
                      _ComparisonItem(
                        label: isKo ? '훈련량(최근 4주 평균)' : 'Training (4-week avg)',
                        current: isKo
                            ? '${avgWeeklyMinutes.toStringAsFixed(0)}분/주'
                            : '${avgWeeklyMinutes.toStringAsFixed(0)} min/week',
                        average: isKo
                            ? '${trainingAvg.weeklyMinutesTarget}분/주'
                            : '${trainingAvg.weeklyMinutesTarget} min/week',
                        gap: _gapText(
                          avgWeeklyMinutes - trainingAvg.weeklyMinutesTarget,
                          isKo,
                        ),
                        isPositive: avgWeeklyMinutes -
                                trainingAvg.weeklyMinutesTarget >=
                            0,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
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

class _ComparisonSection extends StatelessWidget {
  final bool isKo;
  final List<_ComparisonItem> items;

  const _ComparisonSection({required this.isKo, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.balance,
          title: isKo ? '평균 비교' : 'Average Comparison',
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < items.length; i++) ...[
          _ComparisonRow(isKo: isKo, item: items[i]),
          if (i < items.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _ComparisonItem {
  final String label;
  final String current;
  final String average;
  final String gap;
  final bool isPositive;

  const _ComparisonItem({
    required this.label,
    required this.current,
    required this.average,
    required this.gap,
    required this.isPositive,
  });
}

class _ComparisonRow extends StatelessWidget {
  final bool isKo;
  final _ComparisonItem item;

  const _ComparisonRow({required this.isKo, required this.item});

  @override
  Widget build(BuildContext context) {
    final gapColor = item.isPositive
        ? const Color(0xFF3DDC84)
        : Theme.of(context).colorScheme.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.label,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            Text(
              item.gap,
              style: TextStyle(fontWeight: FontWeight.w700, color: gapColor),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: Text('${isKo ? '현재' : 'Now'}: ${item.current}')),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '${isKo ? '평균' : 'Avg'}: ${item.average}',
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ],
    );
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

String _gapText(num gap, bool isKo) {
  final sign = gap >= 0 ? '+' : '';
  return isKo
      ? '$sign${gap.toStringAsFixed(1)} 평균대비'
      : '$sign${gap.toStringAsFixed(1)} vs avg';
}
