import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../application/benchmark_service.dart';
import '../../application/training_service.dart';
import '../../application/settings_service.dart';
import '../../application/backup_service.dart';
import '../../application/player_profile_service.dart';
import '../../domain/entities/training_entry.dart';
import '../../domain/entities/player_profile.dart';
import '../widgets/app_background.dart';
import 'package:football_note/gen/app_localizations.dart';
import '../../application/locale_service.dart';
import '../widgets/watch_cart/main_app_bar.dart';
import '../widgets/app_drawer.dart';
import '../../domain/repositories/option_repository.dart';
import 'average_benchmark_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class StatsScreen extends StatefulWidget {
  final TrainingService trainingService;
  final LocaleService localeService;
  final VoidCallback onCreate;
  final OptionRepository optionRepository;
  final SettingsService settingsService;
  final BackupService? driveBackupService;

  const StatsScreen({
    super.key,
    required this.trainingService,
    required this.localeService,
    required this.onCreate,
    required this.optionRepository,
    required this.settingsService,
    this.driveBackupService,
  });

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late final BenchmarkService _benchmarkService;

  @override
  void initState() {
    super.initState();
    _benchmarkService = BenchmarkService(widget.optionRepository);
    _refreshBenchmarks();
  }

  Future<void> _refreshBenchmarks() async {
    await _benchmarkService.refreshFromExternalIfNeeded();
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(
        trainingService: widget.trainingService,
        optionRepository: widget.optionRepository,
        localeService: widget.localeService,
        settingsService: widget.settingsService,
        driveBackupService: widget.driveBackupService,
        currentIndex: 2,
      ),
      body: AppBackground(
        child: SafeArea(
          child: StreamBuilder<List<TrainingEntry>>(
            stream: widget.trainingService.watchEntries(),
            builder: (context, snapshot) {
              final isKo = Localizations.localeOf(context).languageCode == 'ko';
              if (snapshot.hasError) {
                return _buildStatsContent(
                  context,
                  entries: const [],
                  isKo: isKo,
                  topMessage: isKo
                      ? '통계를 불러오는 중 문제가 발생했어요.'
                      : 'There was a problem loading statistics.',
                );
              }
              if (!snapshot.hasData &&
                  snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingState(context, isKo);
              }
              final entries = snapshot.data ?? const <TrainingEntry>[];
              try {
                return _buildStatsContent(context,
                    entries: entries, isKo: isKo);
              } catch (_) {
                return _buildStatsContent(
                  context,
                  entries: entries,
                  isKo: isKo,
                  topMessage: isKo
                      ? '일부 통계 계산에 실패해 기본 화면으로 표시합니다.'
                      : 'Some stats failed to compute, showing fallback view.',
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context, bool isKo) {
    return Center(
      child: Text(
        isKo ? '통계 데이터를 불러오는 중...' : 'Loading statistics...',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }

  Widget _buildStatsContent(
    BuildContext context, {
    required List<TrainingEntry> entries,
    required bool isKo,
    String? topMessage,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final profileService = PlayerProfileService(widget.optionRepository);
    final profile = profileService.load();
    final now = DateTime.now();
    final ageYears = profileService.ageInYears(profile, now);
    final soccerYears = profileService.soccerYears(profile, now);
    final canShowAverage = ageYears != null && soccerYears != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Builder(
            builder: (context) => WatchCartAppBar(
              onMenuTap: () => Scaffold.of(context).openDrawer(),
              profilePhotoSource: widget.optionRepository
                      .getValue<String>('profile_photo_url') ??
                  '',
              onProfileTap: () => _openProfile(context),
              onSettingsTap: () => _openSettings(context),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${l10n.statsHeadline1} ${l10n.statsHeadline2}',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              if (canShowAverage) ...[
                const SizedBox(width: 10),
                FilledButton.tonalIcon(
                  onPressed: () => _openAverageBenchmark(
                    context,
                    entries,
                    ageYears,
                    soccerYears,
                  ),
                  icon: const Icon(Icons.analytics_outlined, size: 18),
                  label: Text(isKo ? '평균 비교' : 'Averages'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    minimumSize: const Size(1, 38),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          if (topMessage != null) ...[
            _InlineNotice(text: topMessage),
            const SizedBox(height: 12),
          ],
          if (entries.isEmpty) ...[
            _InlineNotice(
              text: isKo
                  ? '아직 통계가 없어요. 훈련일지를 1개 이상 기록하면 자동으로 표시됩니다.'
                  : 'No stats yet. Add at least one training entry to see analytics.',
            ),
            const SizedBox(height: 12),
          ] else ...[
            if (!canShowAverage) ...[
              _InlineNotice(
                text: isKo
                    ? '현재는 판단 기준(나이/구력)이 없어 평균 비교 통계를 보여드릴 수 없어요. 프로필에서 생년월일과 축구 시작일을 입력해 주세요.'
                    : 'Average comparison is hidden because age and soccer experience are missing. Add birth date and soccer start date in profile.',
                title: isKo
                    ? '나이/구력 정보를 입력해 주세요'
                    : 'Enter age and soccer experience',
                trailing: Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () => _openProfile(context),
                    icon: const Icon(Icons.person_outline),
                    label: Text(isKo ? '프로필 입력하기' : 'Open Profile'),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DevelopmentCoachCard(
                  entries: entries,
                  ageYears: ageYears,
                  soccerYears: soccerYears,
                  isKo: isKo,
                  showAverage: canShowAverage,
                ),
                const SizedBox(height: 18),
                Divider(
                  height: 1,
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.25),
                ),
                const SizedBox(height: 18),
                _TargetGrowthChart(
                  entries: entries,
                  ageYears: ageYears,
                  soccerYears: soccerYears,
                  isKo: isKo,
                  showAverage: canShowAverage,
                ),
                const SizedBox(height: 18),
                Divider(
                  height: 1,
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.25),
                ),
                const SizedBox(height: 18),
                _BodyAndLiftingBenchmarkCard(
                  entries: entries,
                  profile: profile,
                  ageYears: ageYears,
                  isKo: isKo,
                  benchmarkService: _benchmarkService,
                  showAverage: canShowAverage,
                ),
                const SizedBox(height: 18),
                Divider(
                  height: 1,
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.25),
                ),
                const SizedBox(height: 18),
                _LiftingSummaryCard(
                  entries: entries,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          localeService: widget.localeService,
          settingsService: widget.settingsService,
          optionRepository: widget.optionRepository,
          driveBackupService: widget.driveBackupService,
        ),
      ),
    );
  }

  void _openProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          optionRepository: widget.optionRepository,
        ),
      ),
    );
  }

  void _openAverageBenchmark(
    BuildContext context,
    List<TrainingEntry> entries,
    int? ageYears,
    int? soccerYears,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AverageBenchmarkScreen(
          entries: entries,
          ageYears: ageYears,
          soccerYears: soccerYears,
          benchmarkService: _benchmarkService,
        ),
      ),
    );
  }
}

class _DevelopmentCoachCard extends StatelessWidget {
  final List<TrainingEntry> entries;
  final int? ageYears;
  final int? soccerYears;
  final bool isKo;
  final bool showAverage;

  const _DevelopmentCoachCard({
    required this.entries,
    required this.ageYears,
    required this.soccerYears,
    required this.isKo,
    required this.showAverage,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dayStart = DateTime(now.year, now.month, now.day);
    final weekStart = dayStart.subtract(Duration(days: dayStart.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    final weekEndInclusive = weekEnd.subtract(const Duration(days: 1));

    final recent = entries
        .where((e) => e.date.isAfter(now.subtract(const Duration(days: 28))))
        .toList();
    final weekEntries = entries
        .where((e) => !e.date.isBefore(weekStart) && e.date.isBefore(weekEnd))
        .toList();

    final weekMinutes =
        weekEntries.fold<int>(0, (sum, entry) => sum + entry.durationMinutes);
    final recentMinutes =
        recent.fold<int>(0, (sum, entry) => sum + entry.durationMinutes);
    final avgWeeklyMinutes = recentMinutes / 4;
    final avgWeeklySessions = recent.length / 4;
    final target = benchmarkTarget(ageYears, soccerYears);
    final minuteRatio = target.weeklyMinutesTarget <= 0
        ? 0.0
        : avgWeeklyMinutes / target.weeklyMinutesTarget;
    final sessionRatio = target.weeklySessionsTarget <= 0
        ? 0.0
        : avgWeeklySessions / target.weeklySessionsTarget;

    final variantSeed = now.day + (entries.length % 7);

    final weeklyAdvice = _buildPeriodAdvice(
      period: _CoachPeriod.weekly,
      minutes: weekMinutes.toDouble(),
      sessions: weekEntries.length.toDouble(),
      targetMinutes: target.weeklyMinutesTarget.toDouble(),
      targetSessions: target.weeklySessionsTarget.toDouble(),
      showAverage: showAverage,
      isKo: isKo,
      variantSeed: variantSeed + 1,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.trending_up,
          title: isKo ? '성장 코치' : 'Growth Coach',
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _KpiTile(
                label: isKo ? '내 훈련 시간' : 'My Time',
                value: _formatMinutesAsTime(
                  avgWeeklyMinutes.round(),
                  isKo: isKo,
                ),
                icon: Icons.timer_outlined,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _KpiTile(
                label: isKo ? '평균 기준' : 'Avg Target',
                value: showAverage
                    ? _formatMinutesAsTime(target.weeklyMinutesTarget,
                        isKo: isKo)
                    : (isKo ? '미입력' : 'N/A'),
                icon: Icons.flag_outlined,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _KpiTile(
                label: isKo ? '주 훈련 횟수' : 'Sessions',
                value: showAverage
                    ? '${avgWeeklySessions.toStringAsFixed(1)}/${target.weeklySessionsTarget}'
                    : avgWeeklySessions.toStringAsFixed(1),
                icon: Icons.event_repeat_outlined,
              ),
            ),
          ],
        ),
        if (showAverage) ...[
          const SizedBox(height: 8),
          _RatioBar(
            label: isKo ? '훈련량 달성률' : 'Minutes Progress',
            ratio: minuteRatio,
            tint: const Color(0xFF4DD0E1),
          ),
          const SizedBox(height: 8),
          _RatioBar(
            label: isKo ? '횟수 달성률' : 'Session Progress',
            ratio: sessionRatio,
            tint: const Color(0xFF3DDC84),
          ),
        ],
        const SizedBox(height: 10),
        _CoachMessage(
          icon: Icons.fact_check_outlined,
          title: isKo ? '평가 기준' : 'Evaluation Basis',
          message: isKo
              ? '주간(월~일) 기준으로 코칭합니다.\n기준 기간: ${_formatDateWithWeekday(weekStart, true)} ~ ${_formatDateWithWeekday(weekEndInclusive, true)}\n위 기간의 훈련 시간과 횟수로 평가합니다.'
              : 'Coaching is weekly (Mon-Sun).\nRange: ${_formatDateWithWeekday(weekStart, false)} ~ ${_formatDateWithWeekday(weekEndInclusive, false)}\nEvaluation is based on training time and sessions in this range.',
          strong: true,
        ),
        const SizedBox(height: 8),
        _CoachMessage(
          icon: Icons.date_range_outlined,
          title: isKo ? '주간 코칭' : 'Weekly Coaching',
          message: weeklyAdvice,
        ),
      ],
    );
  }

  String _formatDateWithWeekday(DateTime date, bool isKo) {
    const koWeekdays = <String>['월', '화', '수', '목', '금', '토', '일'];
    const enWeekdays = <String>[
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun'
    ];
    final weekday =
        isKo ? koWeekdays[date.weekday - 1] : enWeekdays[date.weekday - 1];
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return isKo ? '$y.$m.$d($weekday)' : '$y-$m-$d ($weekday)';
  }

  String _buildPeriodAdvice({
    required _CoachPeriod period,
    required double minutes,
    required double sessions,
    required double targetMinutes,
    required double targetSessions,
    required bool showAverage,
    required bool isKo,
    required int variantSeed,
  }) {
    final ratio = showAverage
        ? (targetMinutes <= 0 ? 0.0 : (minutes / targetMinutes))
        : _heuristicRatio(period, minutes);
    final sessionRatio = showAverage
        ? (targetSessions <= 0 ? 0.0 : (sessions / targetSessions))
        : _heuristicSessionRatio(period, sessions);
    final combined = ((ratio * 0.65) + (sessionRatio * 0.35)).clamp(0.0, 2.0);
    final gapMinutes =
        showAverage ? math.max(0.0, targetMinutes - minutes).round() : 0;
    final gapSessions =
        showAverage ? math.max(0.0, targetSessions - sessions).ceil() : 0;
    final variant = variantSeed % 3;

    if (combined >= 1.0) {
      final lines = isKo
          ? <String>[
              '${_periodName(period, true)} 목표 이상입니다. 지금 리듬을 유지하고 마지막 10분은 첫 터치/패스 정확도에 집중하세요.',
              '${_periodName(period, true)} 페이스가 매우 좋아요. 다음 훈련은 약한 발 컨트롤을 추가해 성장 폭을 키워보세요.',
              '${_periodName(period, true)} 기준으로 안정권입니다. 강도는 유지하고 회복 루틴(스트레칭/수면)도 챙기면 더 좋아요.',
            ]
          : <String>[
              '${_periodName(period, false)} target exceeded. Keep the rhythm and spend the final 10 minutes on first touch and passing accuracy.',
              '${_periodName(period, false)} pace is strong. Add weak-foot control in the next session for better growth.',
              '${_periodName(period, false)} level is stable. Keep intensity and reinforce recovery habits.',
            ];
      return lines[variant];
    }

    if (combined >= 0.7) {
      final lines = isKo
          ? <String>[
              '${_periodName(period, true)} 기준 거의 도달했습니다. ${showAverage ? '${_formatMinutesAsTime(gapMinutes, isKo: true)} + $gapSessions회' : '한 세션'}만 보완하면 목표권입니다.',
              '${_periodName(period, true)} 흐름이 좋습니다. 남은 훈련은 드리블-패스 연계 반복을 넣어 완성도를 올려보세요.',
              '${_periodName(period, true)} 상위 구간 직전입니다. 짧고 집중도 높은 세션을 1회 추가해 보세요.',
            ]
          : <String>[
              '${_periodName(period, false)} is close to target. ${showAverage ? '${_formatMinutesAsTime(gapMinutes, isKo: false)} + $gapSessions sessions' : 'one focused session'} can close the gap.',
              '${_periodName(period, false)} trend is positive. Add dribble-pass transition drills in the remaining sessions.',
              '${_periodName(period, false)} is near upper band. Add one short high-focus session to break through.',
            ];
      return lines[variant];
    }

    if (showAverage) {
      final lines = isKo
          ? <String>[
              '${_periodName(period, true)} 기준이 부족합니다. 최소 ${_formatMinutesAsTime(gapMinutes, isKo: true)}와 $gapSessions회 추가가 필요해요.',
              '${_periodName(period, true)} 대비 훈련량이 낮습니다. 우선 횟수를 먼저 채우고(짧게라도), 그다음 시간을 늘려보세요.',
              '${_periodName(period, true)} 목표와 차이가 큽니다. 이번에는 강도보다 규칙성(정해진 요일 고정)에 집중하세요.',
            ]
          : <String>[
              '${_periodName(period, false)} is below target. Add at least ${_formatMinutesAsTime(gapMinutes, isKo: false)} and $gapSessions sessions.',
              '${_periodName(period, false)} volume is low. Prioritize session count first, then increase total minutes.',
              '${_periodName(period, false)} gap is significant. Focus on consistency before intensity.',
            ];
      return lines[variant];
    }

    final lines = isKo
        ? <String>[
            '${_periodName(period, true)} 기준으로 볼 때 훈련이 적습니다. 이번 기간은 횟수를 먼저 늘려 리듬을 만들어요.',
            '${_periodName(period, true)} 데이터상 누적량이 부족해요. 짧아도 좋으니 끊기지 않게 이어가는 것이 우선입니다.',
            '${_periodName(period, true)} 기준 평가에서 개선이 필요합니다. 같은 시간대에 고정 훈련을 잡아보세요.',
          ]
        : <String>[
            '${_periodName(period, false)} suggests low activity. Increase frequency first to build rhythm.',
            '${_periodName(period, false)} data shows low accumulation. Keep sessions continuous even if short.',
            '${_periodName(period, false)} needs improvement. Try fixed-time training slots for consistency.',
          ];
    return lines[variant];
  }

  double _heuristicRatio(_CoachPeriod period, double minutes) {
    switch (period) {
      case _CoachPeriod.daily:
        return (minutes / 50).clamp(0.0, 2.0);
      case _CoachPeriod.weekly:
        return (minutes / 220).clamp(0.0, 2.0);
      case _CoachPeriod.monthly:
        return (minutes / 880).clamp(0.0, 2.0);
    }
  }

  double _heuristicSessionRatio(_CoachPeriod period, double sessions) {
    switch (period) {
      case _CoachPeriod.daily:
        return sessions >= 1 ? 1.0 : 0.0;
      case _CoachPeriod.weekly:
        return (sessions / 4).clamp(0.0, 2.0);
      case _CoachPeriod.monthly:
        return (sessions / 16).clamp(0.0, 2.0);
    }
  }

  String _periodName(_CoachPeriod period, bool isKo) {
    switch (period) {
      case _CoachPeriod.daily:
        return isKo ? '일간' : 'Daily';
      case _CoachPeriod.weekly:
        return isKo ? '주간' : 'Weekly';
      case _CoachPeriod.monthly:
        return isKo ? '월간' : 'Monthly';
    }
  }
}

enum _CoachPeriod {
  daily,
  weekly,
  monthly,
}

class _TargetGrowthChart extends StatelessWidget {
  final List<TrainingEntry> entries;
  final int? ageYears;
  final int? soccerYears;
  final bool isKo;
  final bool showAverage;

  const _TargetGrowthChart({
    required this.entries,
    required this.ageYears,
    required this.soccerYears,
    required this.isKo,
    required this.showAverage,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final target = benchmarkTarget(ageYears, soccerYears);
    final weekStarts = List.generate(
      8,
      (i) {
        final d = now.subtract(Duration(days: (7 * (7 - i))));
        return DateTime(d.year, d.month, d.day);
      },
    );

    final actualSpots = <FlSpot>[];
    final targetSpots = <FlSpot>[];
    final labels = <int, String>{};
    for (var i = 0; i < weekStarts.length; i++) {
      final start = weekStarts[i];
      final end = start.add(const Duration(days: 7));
      final minutes = entries
          .where((e) => !e.date.isBefore(start) && e.date.isBefore(end))
          .fold<int>(0, (sum, entry) => sum + entry.durationMinutes);
      actualSpots.add(FlSpot(i.toDouble(), minutes.toDouble()));
      if (showAverage) {
        targetSpots
            .add(FlSpot(i.toDouble(), target.weeklyMinutesTarget.toDouble()));
      }
      if (i % 2 == 0) {
        labels[i] = '${start.month}/${start.day}';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.show_chart,
          title:
              isKo ? '성장 그래프(실제 vs 평균 목표)' : 'Growth Chart (Actual vs Target)',
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 190,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    getTitlesWidget: (value, meta) {
                      if (value < 0) return const SizedBox.shrink();
                      return Text(
                        _compactHourTick(value, isKo: isKo),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final label = labels[value.toInt()];
                      if (label == null) return const SizedBox.shrink();
                      return Text(label, style: const TextStyle(fontSize: 10));
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: actualSpots,
                  isCurved: true,
                  color: const Color(0xFF3DDC84),
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                ),
                if (showAverage)
                  LineChartBarData(
                    spots: targetSpots,
                    isCurved: false,
                    color: const Color(0xFFFFC857),
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    dashArray: const [6, 4],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          children: [
            _LegendDot(
              color: const Color(0xFF3DDC84),
              label: isKo ? '실제 훈련 시간' : 'Actual time',
            ),
            if (showAverage)
              _LegendDot(
                color: const Color(0xFFFFC857),
                label: isKo ? '평균 목표 시간' : 'Average target time',
              ),
          ],
        ),
      ],
    );
  }
}

class _BodyAndLiftingBenchmarkCard extends StatelessWidget {
  final List<TrainingEntry> entries;
  final PlayerProfile profile;
  final int? ageYears;
  final bool isKo;
  final BenchmarkService benchmarkService;
  final bool showAverage;

  const _BodyAndLiftingBenchmarkCard({
    required this.entries,
    required this.profile,
    required this.ageYears,
    required this.isKo,
    required this.benchmarkService,
    required this.showAverage,
  });

  @override
  Widget build(BuildContext context) {
    final latestHeight = profile.heightCm;
    final latestWeight = profile.weightKg;

    final totalLifts = entries.fold<int>(
      0,
      (sum, e) =>
          sum +
          e.liftingByPart.values.fold<int>(0, (acc, count) => acc + count),
    );
    final avgLiftPerSession =
        entries.isEmpty ? 0 : (totalLifts / entries.length).round();
    final benchmark = benchmarkService.physicalBenchmarkForAge(ageYears);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.balance,
          title: isKo ? '평균 비교' : 'Average Comparison',
        ),
        const SizedBox(height: 12),
        if (!showAverage) ...[
          Text(
            isKo
                ? '나이/구력 미입력으로 평균 비교는 숨김 상태입니다.'
                : 'Average comparison is hidden because age/experience is not set.',
          ),
          const SizedBox(height: 10),
        ],
        _ComparisonRow(
          isKo: isKo,
          label: isKo ? '키' : 'Height',
          current: latestHeight == null
              ? (isKo ? '미입력' : 'Not set')
              : '${latestHeight.toStringAsFixed(1)}cm',
          average: showAverage
              ? '${benchmark.heightCmAvg.toStringAsFixed(1)}cm'
              : (isKo ? '숨김' : 'Hidden'),
          gap: latestHeight == null
              ? (isKo ? '비교 불가' : 'N/A')
              : showAverage
                  ? _gapText(latestHeight - benchmark.heightCmAvg, isKo)
                  : (isKo ? '비교 숨김' : 'Hidden'),
          isPositive: showAverage &&
              latestHeight != null &&
              latestHeight - benchmark.heightCmAvg >= 0,
        ),
        const SizedBox(height: 8),
        _ComparisonRow(
          isKo: isKo,
          label: isKo ? '몸무게' : 'Weight',
          current: latestWeight == null
              ? (isKo ? '미입력' : 'Not set')
              : '${latestWeight.toStringAsFixed(1)}kg',
          average: showAverage
              ? '${benchmark.weightKgAvg.toStringAsFixed(1)}kg'
              : (isKo ? '숨김' : 'Hidden'),
          gap: latestWeight == null
              ? (isKo ? '비교 불가' : 'N/A')
              : showAverage
                  ? _gapText(latestWeight - benchmark.weightKgAvg, isKo)
                  : (isKo ? '비교 숨김' : 'Hidden'),
          isPositive: showAverage &&
              latestWeight != null &&
              latestWeight - benchmark.weightKgAvg >= 0,
        ),
        const SizedBox(height: 8),
        _ComparisonRow(
          isKo: isKo,
          label: isKo ? '리프팅/세션' : 'Lifting/Session',
          current: '$avgLiftPerSession',
          average: showAverage
              ? '${benchmark.liftsPerSessionAvg}'
              : (isKo ? '숨김' : 'Hidden'),
          gap: showAverage
              ? _gapText(
                  (avgLiftPerSession - benchmark.liftsPerSessionAvg).toDouble(),
                  isKo,
                )
              : (isKo ? '비교 숨김' : 'Hidden'),
          isPositive: showAverage &&
              avgLiftPerSession - benchmark.liftsPerSessionAvg >= 0,
        ),
      ],
    );
  }
}

String _gapText(double gap, bool isKo) {
  final sign = gap >= 0 ? '+' : '';
  return isKo
      ? '$sign${gap.toStringAsFixed(1)} 평균대비'
      : '$sign${gap.toStringAsFixed(1)} vs avg';
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}

class _LiftingSummaryCard extends StatelessWidget {
  final List<TrainingEntry> entries;

  const _LiftingSummaryCard({
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    final bestByPart = <String, _PartBest>{};
    for (final entry in entries) {
      entry.liftingByPart.forEach(
        (part, count) {
          if (count <= 0) return;
          final current = bestByPart[part];
          if (current == null || count > current.count) {
            bestByPart[part] = _PartBest(count: count, date: entry.date);
          }
        },
      );
    }
    final sorted = bestByPart.entries.toList()
      ..sort((a, b) => b.value.count.compareTo(a.value.count));
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.sports_soccer_outlined,
          title: isKo ? '리프팅 부위 통계' : 'Lifting by Body Part',
        ),
        const SizedBox(height: 12),
        if (sorted.isEmpty)
          Text(isKo ? '리프팅 기록이 없습니다.' : 'No lifting records.')
        else
          ...sorted.map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _partLabel(entry.key, isKo),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    isKo ? '${entry.value.count}회' : '${entry.value.count}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _dateText(entry.value.date),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _partLabel(String key, bool isKo) {
    switch (key) {
      case 'infront':
        return isKo ? '인프론트' : 'Infront';
      case 'inside':
        return isKo ? '인사이드' : 'Inside';
      case 'outside':
        return isKo ? '아웃사이드' : 'Outside';
      case 'muple':
        return isKo ? '무릎' : 'Knee';
      case 'head':
        return isKo ? '머리' : 'Head';
      case 'chest':
        return isKo ? '가슴' : 'Chest';
      // Legacy keys from earlier lifting implementations.
      case 'left_foot':
        return isKo ? '인프론트(기존)' : 'Infront (Legacy)';
      case 'right_foot':
        return isKo ? '인사이드(기존)' : 'Inside (Legacy)';
      case 'left_thigh':
        return isKo ? '아웃사이드(기존)' : 'Outside (Legacy)';
      case 'right_thigh':
        return isKo ? '무릎(기존)' : 'Knee (Legacy)';
      case 'back':
        return isKo ? '인사이드(구버전)' : 'Inside (Old)';
      case 'legs':
        return isKo ? '아웃사이드(구버전)' : 'Outside (Old)';
      case 'shoulders':
        return isKo ? '무릎(구버전)' : 'Knee (Old)';
      case 'arms':
        return isKo ? '머리(기존)' : 'Head (Legacy)';
      case 'core':
        return isKo ? '가슴(기존)' : 'Chest (Legacy)';
      default:
        return key;
    }
  }

  String _dateText(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y.$m.$d';
  }
}

class _InlineNotice extends StatelessWidget {
  final String text;
  final String? title;
  final Widget? trailing;

  const _InlineNotice({
    required this.text,
    this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final outline =
        Theme.of(context).colorScheme.outline.withValues(alpha: 0.3);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            width: 3,
            color:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.75),
          ),
        ),
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
          ],
          Text(text),
          if (trailing != null) ...[
            const SizedBox(height: 8),
            trailing!,
          ],
          const SizedBox(height: 2),
          Divider(height: 1, color: outline),
        ],
      ),
    );
  }
}

class _PartBest {
  final int count;
  final DateTime date;

  const _PartBest({
    required this.count,
    required this.date,
  });
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, size: 18, color: accent),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.1,
                ),
          ),
        ),
      ],
    );
  }
}

class _KpiTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _KpiTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17),
          const SizedBox(height: 7),
          Text(
            value,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _RatioBar extends StatelessWidget {
  final String label;
  final double ratio;
  final Color tint;

  const _RatioBar({
    required this.label,
    required this.ratio,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final p = ratio.clamp(0.0, 1.2);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            Text(
              '${(p * 100).toStringAsFixed(0)}%',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: p <= 1 ? p : 1,
            minHeight: 9,
            color: tint,
            backgroundColor:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.14),
          ),
        ),
      ],
    );
  }
}

class _CoachMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final bool strong;

  const _CoachMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.strong = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E2635) : const Color(0xFFF4F7FF);
    final border = isDark ? const Color(0xFF31405B) : const Color(0xFFD8E2FA);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.45,
                        fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
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

String _formatMinutesAsTime(int minutes, {required bool isKo}) {
  if (minutes <= 0) return isKo ? '0분' : '0m';
  final hours = minutes ~/ 60;
  final remain = minutes % 60;
  if (hours <= 0) {
    return isKo ? '$remain분' : '$remain min';
  }
  if (remain <= 0) {
    return isKo ? '$hours시간' : '$hours h';
  }
  return isKo ? '$hours시간 $remain분' : '$hours h $remain min';
}

String _compactHourTick(double minuteValue, {required bool isKo}) {
  final minutes = minuteValue.round();
  if (minutes <= 0) return isKo ? '0분' : '0h';
  final hours = minutes ~/ 60;
  final remain = minutes % 60;
  if (hours <= 0) return isKo ? '$remain분' : '$remain m';
  if (remain <= 0) return isKo ? '$hours시간' : '$hours h';
  return isKo ? '$hours시간 $remain분' : '$hours h $remain m';
}

class _ComparisonRow extends StatelessWidget {
  final bool isKo;
  final String label;
  final String current;
  final String average;
  final String gap;
  final bool isPositive;

  const _ComparisonRow({
    required this.isKo,
    required this.label,
    required this.current,
    required this.average,
    required this.gap,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    final gapColor = isPositive
        ? const Color(0xFF3DDC84)
        : Theme.of(context).colorScheme.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${isKo ? '현재' : 'Now'}: $current'),
              Text('${isKo ? '평균' : 'Avg'}: $average'),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: gapColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              gap,
              style: TextStyle(fontWeight: FontWeight.w700, color: gapColor),
            ),
          ),
        ],
      ),
    );
  }
}
