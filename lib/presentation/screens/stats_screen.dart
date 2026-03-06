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
  late DateTimeRange _selectedRange;

  @override
  void initState() {
    super.initState();
    _benchmarkService = BenchmarkService(widget.optionRepository);
    final today = DateTime.now();
    final end = DateTime(today.year, today.month, today.day);
    final start = end.subtract(const Duration(days: 6));
    _selectedRange = DateTimeRange(start: start, end: end);
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
                return _buildStatsContent(
                  context,
                  entries: entries,
                  isKo: isKo,
                );
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
    final rangeStart = DateTime(
      _selectedRange.start.year,
      _selectedRange.start.month,
      _selectedRange.start.day,
    );
    final rangeEndExclusive = DateTime(
      _selectedRange.end.year,
      _selectedRange.end.month,
      _selectedRange.end.day,
    ).add(const Duration(days: 1));
    final filteredEntries = entries
        .where(
          (entry) =>
              !entry.date.isBefore(rangeStart) &&
              entry.date.isBefore(rangeEndExclusive),
        )
        .toList(growable: false);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Builder(
            builder: (context) => WatchCartAppBar(
              onMenuTap: () => Scaffold.of(context).openDrawer(),
              profilePhotoSource:
                  widget.optionRepository.getValue<String>(
                    'profile_photo_url',
                  ) ??
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
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _pickRange(context),
                icon: const Icon(Icons.date_range_outlined, size: 18),
                label: Text(_rangeLabel(isKo)),
                style: OutlinedButton.styleFrom(
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
          ] else if (filteredEntries.isEmpty) ...[
            _InlineNotice(
              text: isKo
                  ? '선택한 기간에 훈련 기록이 없습니다.'
                  : 'No training entries in the selected period.',
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
                _TargetGrowthChart(
                  entries: filteredEntries,
                  ageYears: ageYears,
                  soccerYears: soccerYears,
                  isKo: isKo,
                  showAverage: canShowAverage,
                  range: _selectedRange,
                ),
                const SizedBox(height: 18),
                Divider(
                  height: 1,
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.25),
                ),
                const SizedBox(height: 18),
                _BodyAndLiftingBenchmarkCard(
                  entries: filteredEntries,
                  profile: profile,
                  ageYears: ageYears,
                  isKo: isKo,
                  benchmarkService: _benchmarkService,
                  showAverage: canShowAverage,
                  onReferenceTap: canShowAverage
                      ? () => _openAverageBenchmark(
                          context,
                          filteredEntries,
                          ageYears,
                          soccerYears,
                        )
                      : null,
                ),
                const SizedBox(height: 18),
                Divider(
                  height: 1,
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.25),
                ),
                const SizedBox(height: 18),
                _LiftingSummaryCard(entries: filteredEntries),
                const SizedBox(height: 18),
                Divider(
                  height: 1,
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.25),
                ),
                const SizedBox(height: 18),
                _JumpRopeSummaryCard(entries: filteredEntries),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickRange(BuildContext context) async {
    final picked = await showModalBottomSheet<DateTimeRange>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _StatsRangePickerSheet(initialRange: _selectedRange),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selectedRange = DateTimeRange(
        start: DateTime(
          picked.start.year,
          picked.start.month,
          picked.start.day,
        ),
        end: DateTime(picked.end.year, picked.end.month, picked.end.day),
      );
    });
  }

  String _rangeLabel(bool isKo) {
    final start = _selectedRange.start;
    final end = _selectedRange.end;
    final startText = isKo
        ? '${start.month}/${start.day}'
        : '${start.month}/${start.day}';
    final endText = isKo
        ? '${end.month}/${end.day}'
        : '${end.month}/${end.day}';
    return isKo ? '$startText~$endText' : '$startText-$endText';
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
        builder: (_) =>
            ProfileScreen(optionRepository: widget.optionRepository),
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

enum _CoachPeriod { daily, weekly, monthly }

_CoachPeriod _periodFromDays(int days) {
  if (days <= 1) return _CoachPeriod.daily;
  if (days <= 14) return _CoachPeriod.weekly;
  return _CoachPeriod.monthly;
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
  final gapMinutes = showAverage
      ? math.max(0.0, targetMinutes - minutes).round()
      : 0;
  final gapSessions = showAverage
      ? math.max(0.0, targetSessions - sessions).ceil()
      : 0;
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

class _StatsRangePickerSheet extends StatefulWidget {
  final DateTimeRange initialRange;

  const _StatsRangePickerSheet({required this.initialRange});

  @override
  State<_StatsRangePickerSheet> createState() => _StatsRangePickerSheetState();
}

class _StatsRangePickerSheetState extends State<_StatsRangePickerSheet> {
  late DateTime _start;
  late DateTime _end;
  bool _selectingEnd = false;

  @override
  void initState() {
    super.initState();
    _start = _normalize(widget.initialRange.start);
    _end = _normalize(widget.initialRange.end);
  }

  @override
  Widget build(BuildContext context) {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isKo ? '통계 기간 선택' : 'Select period',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              isKo
                  ? '저장 버튼 없이 바로 적용됩니다. ${_selectingEnd ? '종료일을 선택해 주세요.' : '시작일을 선택해 주세요.'}'
                  : 'Applied immediately. ${_selectingEnd ? 'Select end date.' : 'Select start date.'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _DateChip(
                  label: isKo ? '시작' : 'Start',
                  value: _start,
                  selected: !_selectingEnd,
                  onTap: () => setState(() => _selectingEnd = false),
                ),
                _DateChip(
                  label: isKo ? '종료' : 'End',
                  value: _end,
                  selected: _selectingEnd,
                  onTap: () => setState(() => _selectingEnd = true),
                ),
              ],
            ),
            const SizedBox(height: 10),
            CalendarDatePicker(
              initialDate: _selectingEnd ? _end : _start,
              firstDate: DateTime(2022, 1, 1),
              lastDate: DateTime(2032, 12, 31),
              onDateChanged: (picked) {
                final day = _normalize(picked);
                if (_selectingEnd) {
                  var start = _start;
                  var end = day;
                  if (end.isBefore(start)) {
                    final tmp = start;
                    start = end;
                    end = tmp;
                  }
                  Navigator.of(
                    context,
                  ).pop(DateTimeRange(start: start, end: end));
                  return;
                }
                setState(() {
                  _start = day;
                  if (_end.isBefore(_start)) {
                    _end = _start;
                  }
                  _selectingEnd = true;
                });
              },
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(isKo ? '취소' : 'Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  DateTime _normalize(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}

class _DateChip extends StatelessWidget {
  final String label;
  final DateTime value;
  final bool selected;
  final VoidCallback onTap;

  const _DateChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primary.withValues(alpha: 0.12)
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.35),
          ),
        ),
        child: Text(
          '$label ${value.month}/${value.day}',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: selected ? colorScheme.primary : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _TargetGrowthChart extends StatelessWidget {
  final List<TrainingEntry> entries;
  final int? ageYears;
  final int? soccerYears;
  final bool isKo;
  final bool showAverage;
  final DateTimeRange range;

  const _TargetGrowthChart({
    required this.entries,
    required this.ageYears,
    required this.soccerYears,
    required this.isKo,
    required this.showAverage,
    required this.range,
  });

  @override
  Widget build(BuildContext context) {
    final target = benchmarkTarget(ageYears, soccerYears);
    final periodStart = DateTime(
      range.start.year,
      range.start.month,
      range.start.day,
    );
    final periodEnd = DateTime(range.end.year, range.end.month, range.end.day);
    final dayPoints = <DateTime>[];
    var cursor = periodStart;
    while (!cursor.isAfter(periodEnd)) {
      dayPoints.add(cursor);
      cursor = cursor.add(const Duration(days: 1));
    }

    final actualSpots = <FlSpot>[];
    final targetSpots = <FlSpot>[];
    final labels = <int, String>{};
    final workedDays = <DateTime>{};
    final dailyTarget = (target.weeklyMinutesTarget / 7).round();
    final labelStep = dayPoints.length <= 10
        ? 1
        : (dayPoints.length <= 20 ? 2 : 3);

    for (var i = 0; i < dayPoints.length; i++) {
      final start = dayPoints[i];
      final end = start.add(const Duration(days: 1));
      final minutes = entries
          .where((e) => !e.date.isBefore(start) && e.date.isBefore(end))
          .fold<int>(0, (sum, entry) => sum + entry.durationMinutes);
      if (minutes > 0) workedDays.add(start);
      actualSpots.add(FlSpot(i.toDouble(), minutes.toDouble()));
      if (showAverage) {
        targetSpots.add(FlSpot(i.toDouble(), dailyTarget.toDouble()));
      }
      if (i == 0 || i == dayPoints.length - 1 || i % labelStep == 0) {
        labels[i] = '${start.month}/${start.day}';
      }
    }
    final workedDateText = workedDays.toList()..sort((a, b) => a.compareTo(b));
    final workedLabel = workedDateText.isEmpty
        ? (isKo ? '운동한 날: 없음' : 'Workout days: none')
        : (isKo
              ? '운동한 날: ${workedDateText.map((d) => '${d.month}/${d.day}').join(', ')}'
              : 'Workout days: ${workedDateText.map((d) => '${d.month}/${d.day}').join(', ')}');
    final periodDays = periodEnd.difference(periodStart).inDays + 1;
    final totalMinutes = entries.fold<int>(
      0,
      (sum, entry) => sum + entry.durationMinutes,
    );
    final sessions = entries.length;
    final scaledTargetMinutes = ((target.weeklyMinutesTarget * periodDays) / 7)
        .round();
    final scaledTargetSessions =
        ((target.weeklySessionsTarget * periodDays) / 7).clamp(1, 99).round();
    final period = _periodFromDays(periodDays);
    final periodAdvice = _buildPeriodAdvice(
      period: period,
      minutes: totalMinutes.toDouble(),
      sessions: sessions.toDouble(),
      targetMinutes: scaledTargetMinutes.toDouble(),
      targetSessions: scaledTargetSessions.toDouble(),
      showAverage: showAverage,
      isKo: isKo,
      variantSeed: periodStart.day + (entries.length % 7) + 1,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.show_chart,
          title: isKo ? '성장 그래프(선택 기간)' : 'Growth Chart (Selected Period)',
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 190,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              lineTouchData: LineTouchData(
                handleBuiltInTouches: true,
                touchTooltipData: LineTouchTooltipData(
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final label = spot.barIndex == 0
                          ? (isKo ? '실제' : 'Actual')
                          : (isKo ? '목표' : 'Target');
                      final timeText = _formatMinutesAsTime(
                        spot.y.round(),
                        isKo: isKo,
                      );
                      return LineTooltipItem(
                        '$label: $timeText',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
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
              label: isKo ? '실제 훈련 시간(일)' : 'Actual time (daily)',
            ),
            if (showAverage)
              _LegendDot(
                color: const Color(0xFFFFC857),
                label: isKo ? '평균 목표 시간(일)' : 'Average target time (daily)',
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(workedLabel, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 10),
        _CoachMessage(
          icon: Icons.date_range_outlined,
          title: isKo ? '기간 코칭' : 'Period Coaching',
          message: periodAdvice,
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
  final VoidCallback? onReferenceTap;

  const _BodyAndLiftingBenchmarkCard({
    required this.entries,
    required this.profile,
    required this.ageYears,
    required this.isKo,
    required this.benchmarkService,
    required this.showAverage,
    required this.onReferenceTap,
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
    final avgLiftPerSession = entries.isEmpty
        ? 0
        : (totalLifts / entries.length).round();
    final benchmark = benchmarkService.physicalBenchmarkForAge(ageYears);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.balance,
          title: isKo ? '평균 비교' : 'Average Comparison',
          trailing: onReferenceTap == null
              ? null
              : OutlinedButton.icon(
                  onPressed: onReferenceTap,
                  icon: const Icon(Icons.analytics_outlined, size: 16),
                  label: Text(isKo ? '기준 출처' : 'References'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    minimumSize: const Size(1, 34),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                ),
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
          isPositive:
              showAverage &&
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
          isPositive:
              showAverage &&
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
          isPositive:
              showAverage &&
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

  const _LiftingSummaryCard({required this.entries});

  @override
  Widget build(BuildContext context) {
    final bestByPart = <String, _PartBest>{};
    final recordsByPart = <String, List<_PartRecord>>{};
    for (final entry in entries) {
      entry.liftingByPart.forEach((part, count) {
        if (count <= 0) return;
        recordsByPart
            .putIfAbsent(part, () => <_PartRecord>[])
            .add(_PartRecord(count: count, date: entry.date));
        final current = bestByPart[part];
        if (current == null || count > current.count) {
          bestByPart[part] = _PartBest(
            count: count,
            date: entry.date,
            increase: 0,
          );
        }
      });
    }
    recordsByPart.forEach((part, records) {
      records.sort((a, b) => b.count.compareTo(a.count));
      final best = records.first.count;
      final prev = records.length > 1 ? records[1].count : 0;
      final current = bestByPart[part];
      if (current != null) {
        bestByPart[part] = _PartBest(
          count: current.count,
          date: current.date,
          increase: (best - prev).clamp(0, 999999),
        );
      }
    });
    final sorted = bestByPart.entries.toList()
      ..sort((a, b) => b.value.count.compareTo(a.value.count));
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.sports_soccer_outlined,
          title: l10n.liftingByBodyPartTitle,
        ),
        const SizedBox(height: 12),
        if (sorted.isEmpty)
          Text(l10n.liftingNoRecords)
        else
          ...sorted.map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _partLabel(entry.key, l10n),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    isKo ? '${entry.value.count}회' : '${entry.value.count}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (entry.value.increase > 0) ...[
                    const SizedBox(width: 6),
                    Text(
                      isKo
                          ? '(+${entry.value.increase})'
                          : '(+${entry.value.increase})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
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

  String _partLabel(String key, AppLocalizations l10n) {
    switch (key) {
      case 'infront':
        return l10n.liftingPartInfront;
      case 'inside':
        return l10n.liftingPartInside;
      case 'outside':
        return l10n.liftingPartOutside;
      case 'muple':
        return l10n.liftingPartMuple;
      case 'head':
        return l10n.liftingPartHead;
      case 'chest':
        return l10n.liftingPartChest;
      // Legacy keys from earlier lifting implementations.
      case 'left_foot':
        return '${l10n.liftingPartInfront} (${l10n.legacyLabel})';
      case 'right_foot':
        return '${l10n.liftingPartInside} (${l10n.legacyLabel})';
      case 'left_thigh':
        return '${l10n.liftingPartOutside} (${l10n.legacyLabel})';
      case 'right_thigh':
        return '${l10n.liftingPartMuple} (${l10n.legacyLabel})';
      case 'back':
        return '${l10n.liftingPartInside} (${l10n.oldLabel})';
      case 'legs':
        return '${l10n.liftingPartOutside} (${l10n.oldLabel})';
      case 'shoulders':
        return '${l10n.liftingPartMuple} (${l10n.oldLabel})';
      case 'arms':
        return '${l10n.liftingPartHead} (${l10n.legacyLabel})';
      case 'core':
        return '${l10n.liftingPartChest} (${l10n.legacyLabel})';
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

class _JumpRopeSummaryCard extends StatelessWidget {
  final List<TrainingEntry> entries;

  const _JumpRopeSummaryCard({required this.entries});

  @override
  Widget build(BuildContext context) {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final valid = entries
        .where((e) => e.jumpRopeCount > 0 || e.jumpRopeMinutes > 0)
        .toList(growable: false);
    final totalCount = valid.fold<int>(0, (sum, e) => sum + e.jumpRopeCount);
    final totalMinutes = valid.fold<int>(
      0,
      (sum, e) => sum + e.jumpRopeMinutes,
    );
    final bestCount = valid.isEmpty
        ? 0
        : valid.map((e) => e.jumpRopeCount).reduce(math.max);
    final avgCount = valid.isEmpty ? 0 : (totalCount / valid.length).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.fitness_center_outlined,
          title: isKo ? '줄넘기 통계' : 'Jump Rope Stats',
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _KpiTile(
                label: isKo ? '총 횟수' : 'Total',
                value: '$totalCount',
                icon: Icons.tag_outlined,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _KpiTile(
                label: isKo ? '총 시간(분)' : 'Total min',
                value: '$totalMinutes',
                icon: Icons.timer_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _KpiTile(
                label: isKo ? '최고 횟수' : 'Best count',
                value: '$bestCount',
                icon: Icons.emoji_events_outlined,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _KpiTile(
                label: isKo ? '평균 횟수' : 'Avg count',
                value: '$avgCount',
                icon: Icons.analytics_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InlineNotice extends StatelessWidget {
  final String text;
  final String? title;
  final Widget? trailing;

  const _InlineNotice({required this.text, this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(
      context,
    ).colorScheme.outline.withValues(alpha: 0.3);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            width: 3,
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.75),
          ),
        ),
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
          ],
          Text(text),
          if (trailing != null) ...[const SizedBox(height: 8), trailing!],
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
  final int increase;

  const _PartBest({
    required this.count,
    required this.date,
    required this.increase,
  });
}

class _PartRecord {
  final int count;
  final DateTime date;

  const _PartRecord({required this.count, required this.date});
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;

  const _SectionTitle({required this.icon, required this.title, this.trailing});

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
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
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
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _CoachMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _CoachMessage({
    required this.icon,
    required this.title,
    required this.message,
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
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.45,
                    fontWeight: FontWeight.w500,
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
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              Text(
                gap,
                style: TextStyle(fontWeight: FontWeight.w700, color: gapColor),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${isKo ? '현재' : 'Now'}: $current'),
              Text('${isKo ? '평균' : 'Avg'}: $average'),
            ],
          ),
        ],
      ),
    );
  }
}
