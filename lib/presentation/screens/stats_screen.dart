import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../application/benchmark_service.dart';
import '../../application/news_badge_service.dart';
import '../../application/training_service.dart';
import '../../application/settings_service.dart';
import '../../application/backup_service.dart';
import '../../application/player_profile_service.dart';
import '../../application/training_plan_reminder_service.dart';
import '../../domain/entities/training_entry.dart';
import '../../domain/entities/player_profile.dart';
import '../widgets/app_background.dart';
import 'package:football_note/gen/app_localizations.dart';
import '../../application/locale_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/shared_tab_header.dart';
import '../../domain/repositories/option_repository.dart';
import 'average_benchmark_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'news_screen.dart';
import 'skill_quiz_screen.dart';
import 'notification_center_screen.dart';

class StatsScreen extends StatefulWidget {
  final TrainingService trainingService;
  final LocaleService localeService;
  final VoidCallback onCreate;
  final OptionRepository optionRepository;
  final SettingsService settingsService;
  final BackupService? driveBackupService;
  final DateTimeRange? initialRange;
  final int initialRangeRequestKey;

  const StatsScreen({
    super.key,
    required this.trainingService,
    required this.localeService,
    required this.onCreate,
    required this.optionRepository,
    required this.settingsService,
    this.driveBackupService,
    this.initialRange,
    this.initialRangeRequestKey = 0,
  });

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  static const String _plansStorageKey = 'training_plans_v1';
  late final BenchmarkService _benchmarkService;
  late DateTimeRange _selectedRange;
  int _statsTabIndex = 0;
  bool _routePushInFlight = false;

  @override
  void initState() {
    super.initState();
    _benchmarkService = BenchmarkService(widget.optionRepository);
    _selectedRange = widget.initialRange ?? _recentWeekRange();
    NewsBadgeService.refresh(widget.optionRepository);
    _refreshBenchmarks();
  }

  @override
  void didUpdateWidget(covariant StatsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextRange = widget.initialRange;
    final previousRange = oldWidget.initialRange;
    final forceApplyRange =
        widget.initialRangeRequestKey != oldWidget.initialRangeRequestKey;
    if (nextRange != null &&
        (forceApplyRange || !_sameRange(previousRange, nextRange))) {
      _selectedRange = nextRange;
    }
  }

  Future<void> _refreshBenchmarks() async {
    await _benchmarkService.refreshFromExternalIfNeeded();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _pushPageSafely(Route<void> route) async {
    if (!mounted || _routePushInFlight) return;
    _routePushInFlight = true;
    try {
      await Future<void>.delayed(Duration.zero);
      if (!mounted) return;
      await Navigator.of(context).push(route);
    } finally {
      _routePushInFlight = false;
      if (mounted) setState(() {});
    }
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
        currentIndex: 3,
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
    final reminderUnreadCount = TrainingPlanReminderService(
      widget.optionRepository,
      widget.settingsService,
    ).unreadReminderCountSync();
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
    final trainingEntries = filteredEntries
        .where((entry) => !entry.isMatch)
        .toList(growable: false);
    final matchEntries =
        filteredEntries.where((entry) => entry.isMatch).toList(growable: false);
    final plansInRange = _loadPlansInRange(
      rangeStart: rangeStart,
      rangeEndExclusive: rangeEndExclusive,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ValueListenableBuilder<int>(
            valueListenable: NewsBadgeService.listenable(
              widget.optionRepository,
            ),
            builder: (context, newsCount, _) => Builder(
              builder: (context) => SharedTabHeader(
                padding: EdgeInsets.zero,
                onLeadingTap: () => Scaffold.of(context).openDrawer(),
                onNewsTap: () => _openNews(context),
                newsBadgeCount: newsCount,
                onQuizTap: () => _openQuiz(context),
                onNotificationTap: () => _openNotifications(context),
                notificationBadgeCount: reminderUnreadCount,
                profilePhotoSource: widget.optionRepository.getValue<String>(
                      'profile_photo_url',
                    ) ??
                    '',
                onProfileTap: () => _openProfile(context),
                onSettingsTap: () => _openSettings(context),
                title: '${l10n.statsHeadline1} ${l10n.statsHeadline2}',
                titleTrailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton(
                      onPressed: _setRecentWeekRange,
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        minimumSize: const Size(1, 38),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                      child: Text(isKo ? '최근 1주일' : 'Last 7 days'),
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
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (topMessage != null) ...[
            _InlineNotice(text: topMessage),
            const SizedBox(height: 12),
          ],
          _buildStatsTabBar(context, isKo),
          const SizedBox(height: 16),
          if (_statsTabIndex == 0)
            _buildTrainingStatsTab(
              context,
              isKo: isKo,
              profile: profile,
              ageYears: ageYears,
              soccerYears: soccerYears,
              canShowAverage: canShowAverage,
              trainingEntries: trainingEntries,
              plansInRange: plansInRange,
            )
          else
            _buildMatchStatsTab(
              context,
              isKo: isKo,
              entries: entries,
              filteredEntries: filteredEntries,
              matchEntries: matchEntries,
            ),
        ],
      ),
    );
  }

  Widget _buildStatsTabBar(BuildContext context, bool isKo) {
    return SegmentedButton<int>(
      segments: [
        ButtonSegment<int>(
          value: 0,
          icon: const Icon(Icons.fitness_center_outlined),
          label: Text(isKo ? '훈련' : 'Training'),
        ),
        ButtonSegment<int>(
          value: 1,
          icon: const Icon(Icons.sports_soccer_outlined),
          label: Text(isKo ? '시합' : 'Matches'),
        ),
      ],
      selected: {_statsTabIndex},
      onSelectionChanged: (selection) {
        setState(() {
          _statsTabIndex = selection.first;
        });
      },
      showSelectedIcon: false,
    );
  }

  Widget _buildTrainingStatsTab(
    BuildContext context, {
    required bool isKo,
    required PlayerProfile profile,
    required int? ageYears,
    required int? soccerYears,
    required bool canShowAverage,
    required List<TrainingEntry> trainingEntries,
    required List<_StatsPlanLite> plansInRange,
  }) {
    if (trainingEntries.isEmpty) {
      return _InlineNotice(
        text: isKo
            ? '선택한 기간에 훈련 기록이 없습니다.'
            : 'No training entries in the selected period.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatsPanel(
          child: _TrainingOverviewSection(
            entries: trainingEntries,
            plans: plansInRange,
            isKo: isKo,
            range: _selectedRange,
          ),
        ),
        const SizedBox(height: 18),
        if (!canShowAverage) ...[
          _InlineNotice(
            text: isKo
                ? '현재는 판단 기준(나이/구력)이 없어 평균 비교 통계를 보여드릴 수 없어요. 프로필에서 생년월일과 축구 시작일을 입력해 주세요.'
                : 'Average comparison is hidden because age and soccer experience are missing. Add birth date and soccer start date in profile.',
            title:
                isKo ? '나이/구력 정보를 입력해 주세요' : 'Enter age and soccer experience',
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
        _StatsPanel(
          child: _TargetGrowthChart(
            entries: trainingEntries,
            ageYears: ageYears,
            soccerYears: soccerYears,
            isKo: isKo,
            showAverage: canShowAverage,
            range: _selectedRange,
          ),
        ),
        const SizedBox(height: 18),
        _StatsPanel(
          child: _BodyAndLiftingBenchmarkCard(
            entries: trainingEntries,
            profile: profile,
            ageYears: ageYears,
            isKo: isKo,
            benchmarkService: _benchmarkService,
            showAverage: canShowAverage,
            onReferenceTap: canShowAverage
                ? () => _openAverageBenchmark(
                      context,
                      trainingEntries,
                      ageYears,
                      soccerYears,
                    )
                : null,
          ),
        ),
        const SizedBox(height: 18),
        _StatsPanel(child: _LiftingSummaryCard(entries: trainingEntries)),
        const SizedBox(height: 18),
        _StatsPanel(
          child: _JumpRopeSummaryCard(
            entries: trainingEntries,
            range: _selectedRange,
          ),
        ),
      ],
    );
  }

  Widget _buildMatchStatsTab(
    BuildContext context, {
    required bool isKo,
    required List<TrainingEntry> entries,
    required List<TrainingEntry> filteredEntries,
    required List<TrainingEntry> matchEntries,
  }) {
    if (entries.isEmpty) {
      return _InlineNotice(
        text: isKo ? '아직 시합 기록이 없습니다.' : 'No match records yet.',
      );
    }
    if (filteredEntries.isEmpty || matchEntries.isEmpty) {
      return _InlineNotice(
        text: isKo
            ? '선택한 기간에 시합 기록이 없습니다.'
            : 'No matches in the selected period.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatsPanel(
          child: _MatchOverviewSection(entries: matchEntries, isKo: isKo),
        ),
        const SizedBox(height: 18),
        _StatsPanel(child: _MatchSummaryCard(entries: matchEntries)),
        const SizedBox(height: 18),
        _StatsPanel(child: _MatchHistorySection(entries: matchEntries)),
      ],
    );
  }

  Future<void> _pickRange(BuildContext context) async {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final theme = Theme.of(context);
    final rangeColor = theme.colorScheme.primary.withValues(alpha: 0.22);
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedRange,
      firstDate: DateTime(2022, 1, 1),
      lastDate: DateTime(2032, 12, 31),
      helpText: isKo ? '통계 기간 선택' : 'Select period',
      confirmText: isKo ? '적용' : 'Apply',
      cancelText: isKo ? '취소' : 'Cancel',
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            datePickerTheme: DatePickerThemeData(
              rangeSelectionBackgroundColor: rangeColor,
              rangeSelectionOverlayColor: WidgetStateProperty.resolveWith(
                (states) => theme.colorScheme.primary.withValues(alpha: 0.12),
              ),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
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
    final startText =
        isKo ? '${start.month}/${start.day}' : '${start.month}/${start.day}';
    final endText =
        isKo ? '${end.month}/${end.day}' : '${end.month}/${end.day}';
    return isKo ? '$startText~$endText' : '$startText-$endText';
  }

  void _setRecentWeekRange() {
    setState(() {
      _selectedRange = _recentWeekRange();
    });
  }

  DateTimeRange _recentWeekRange() {
    final today = DateTime.now();
    final end = DateTime(today.year, today.month, today.day);
    final start = end.subtract(const Duration(days: 6));
    return DateTimeRange(start: start, end: end);
  }

  bool _sameRange(DateTimeRange? left, DateTimeRange? right) {
    if (left == null || right == null) return left == right;
    return left.start == right.start && left.end == right.end;
  }

  List<_StatsPlanLite> _loadPlansInRange({
    required DateTime rangeStart,
    required DateTime rangeEndExclusive,
  }) {
    final raw = widget.optionRepository.getValue<String>(_plansStorageKey);
    if (raw == null || raw.trim().isEmpty) return const <_StatsPlanLite>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <_StatsPlanLite>[];
      return decoded
          .whereType<Map>()
          .map((item) => _StatsPlanLite.fromMap(item.cast<String, dynamic>()))
          .where(
            (plan) =>
                !plan.scheduledAt.isBefore(rangeStart) &&
                plan.scheduledAt.isBefore(rangeEndExclusive),
          )
          .toList(growable: false);
    } catch (_) {
      return const <_StatsPlanLite>[];
    }
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

  Future<void> _openProfile(BuildContext context) async {
    await _pushPageSafely(
      MaterialPageRoute(
        builder: (_) =>
            ProfileScreen(optionRepository: widget.optionRepository),
      ),
    );
  }

  Future<void> _openNews(BuildContext context) async {
    await _pushPageSafely(
      MaterialPageRoute(
        builder: (_) => NewsScreen(
          trainingService: widget.trainingService,
          localeService: widget.localeService,
          optionRepository: widget.optionRepository,
          settingsService: widget.settingsService,
          driveBackupService: widget.driveBackupService,
          isActive: true,
        ),
      ),
    );
    if (mounted) {
      await NewsBadgeService.refresh(widget.optionRepository);
    }
  }

  Future<void> _openQuiz(BuildContext context) async {
    await _pushPageSafely(
      MaterialPageRoute(
        builder: (_) =>
            SkillQuizScreen(optionRepository: widget.optionRepository),
      ),
    );
  }

  Future<void> _openNotifications(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotificationCenterScreen(
          optionRepository: widget.optionRepository,
          settingsService: widget.settingsService,
        ),
      ),
    );
    if (mounted) setState(() {});
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
    final labelStep =
        dayPoints.length <= 10 ? 1 : (dayPoints.length <= 20 ? 2 : 3);

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
    final scaledTargetMinutes =
        ((target.weeklyMinutesTarget * periodDays) / 7).round();
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
    final avgLiftPerSession =
        entries.isEmpty ? 0 : (totalLifts / entries.length).round();
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

  const _LiftingSummaryCard({required this.entries});

  @override
  Widget build(BuildContext context) {
    final bestByPart = <String, _PartBest>{};
    final recordsByPart = <String, List<_PartRecord>>{};
    final totalsByDay = <DateTime, int>{};
    for (final entry in entries) {
      final dayKey = DateTime(
        entry.date.year,
        entry.date.month,
        entry.date.day,
      );
      final totalForEntry = entry.liftingByPart.values.fold<int>(
        0,
        (sum, count) => sum + count,
      );
      if (totalForEntry > 0) {
        totalsByDay.update(
          dayKey,
          (value) => value + totalForEntry,
          ifAbsent: () => totalForEntry,
        );
      }
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
    final trendEntries = totalsByDay.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final maxTotal = trendEntries.isEmpty
        ? 0
        : trendEntries.map((entry) => entry.value).reduce(math.max);
    final yInterval = _niceLiftingAxisInterval(maxTotal);
    final yMax = trendEntries.isEmpty
        ? yInterval.toDouble()
        : ((maxTotal / yInterval).ceil() * yInterval).toDouble();
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
        else ...[
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: yMax,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: yInterval.toDouble(),
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.16),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: yInterval.toDouble(),
                      getTitlesWidget: (value, _) => Text(
                        value.toInt().toString(),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        final index = value.toInt();
                        if (index < 0 || index >= trendEntries.length) {
                          return const SizedBox.shrink();
                        }
                        final date = trendEntries[index].key;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            DateFormat('M/d').format(date),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: trendEntries.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.value.toDouble(),
                        width: 16,
                        borderRadius: BorderRadius.circular(6),
                        gradient: const LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Color(0xFF2F80ED), Color(0xFF6FCF97)],
                        ),
                      ),
                    ],
                  );
                }).toList(growable: false),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isKo ? '일자별 리프팅 총 횟수' : 'Daily lifting totals',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
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

  int _niceLiftingAxisInterval(int maxValue) {
    if (maxValue <= 20) return 10;
    if (maxValue <= 40) return 20;
    if (maxValue <= 80) return 25;
    if (maxValue <= 160) return 50;
    if (maxValue <= 320) return 100;
    final scaled = maxValue / 4;
    var magnitude = 1;
    while (magnitude * 10 <= scaled) {
      magnitude *= 10;
    }
    return ((scaled / magnitude).ceil() * magnitude).toInt();
  }
}

class _JumpRopeSummaryCard extends StatelessWidget {
  final List<TrainingEntry> entries;
  final DateTimeRange range;

  const _JumpRopeSummaryCard({required this.entries, required this.range});

  @override
  Widget build(BuildContext context) {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final start = DateTime(
      range.start.year,
      range.start.month,
      range.start.day,
    );
    final end = DateTime(range.end.year, range.end.month, range.end.day);
    final days = <DateTime>[];
    for (var current = start;
        !current.isAfter(end);
        current = current.add(const Duration(days: 1))) {
      days.add(current);
    }
    final countByDay = <DateTime, int>{for (final day in days) day: 0};
    for (final entry in entries) {
      final key = DateTime(entry.date.year, entry.date.month, entry.date.day);
      countByDay.update(
        key,
        (value) => value + entry.jumpRopeCount,
        ifAbsent: () => entry.jumpRopeCount,
      );
    }
    final points = days
        .map((day) => MapEntry(day, countByDay[day] ?? 0))
        .toList(growable: false);
    final totalCount = points.fold<int>(0, (sum, item) => sum + item.value);
    final bestCount =
        points.isEmpty ? 0 : points.map((item) => item.value).reduce(math.max);
    final bestDay = points.firstWhere(
      (item) => item.value == bestCount,
      orElse: () => MapEntry(start, 0),
    );
    final maxY =
        bestCount <= 0 ? 5.0 : (bestCount * 1.25).clamp(5, 1000000).toDouble();
    final labelStride = math.max(1, (days.length / 6).ceil());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.fitness_center_outlined,
          title: isKo ? '줄넘기 통계' : 'Jump Rope Stats',
        ),
        const SizedBox(height: 10),
        if (totalCount == 0)
          _InlineNotice(
            text: isKo
                ? '선택한 기간에 기록된 줄넘기 횟수가 없습니다.'
                : 'No jump rope counts recorded in the selected period.',
          )
        else ...[
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY <= 10 ? 2 : null,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.18),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Colors.black87,
                    getTooltipItem: (group, _, rod, __) {
                      final day = days[group.x.toInt()];
                      final dateLabel = isKo
                          ? '${day.month}/${day.day}'
                          : '${day.month}/${day.day}';
                      final count = rod.toY.round();
                      return BarTooltipItem(
                        '$dateLabel\n${isKo ? '줄넘기' : 'Count'} $count',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 10),
                      ),
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
                        final index = value.toInt();
                        if (index < 0 || index >= days.length) {
                          return const SizedBox.shrink();
                        }
                        if (index % labelStride != 0 &&
                            index != days.length - 1) {
                          return const SizedBox.shrink();
                        }
                        final day = days[index];
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '${day.month}/${day.day}',
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < points.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: points[i].value.toDouble(),
                          width: days.length <= 10 ? 18 : 10,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                          color: const Color(0xFF3DDC84),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _LegendDot(
                color: const Color(0xFF3DDC84),
                label: isKo ? '일자별 줄넘기 횟수' : 'Daily jump rope count',
              ),
              Text(
                isKo ? '총합 $totalCount회' : 'Total $totalCount',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                isKo
                    ? '최고 ${bestDay.key.month}/${bestDay.key.day} · $bestCount회'
                    : 'Best ${bestDay.key.month}/${bestDay.key.day} · $bestCount',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _TrainingOverviewSection extends StatelessWidget {
  final List<TrainingEntry> entries;
  final List<_StatsPlanLite> plans;
  final bool isKo;
  final DateTimeRange range;

  const _TrainingOverviewSection({
    required this.entries,
    required this.plans,
    required this.isKo,
    required this.range,
  });

  @override
  Widget build(BuildContext context) {
    final totalMinutes = entries.fold<int>(
      0,
      (sum, entry) => sum + entry.durationMinutes,
    );
    final activeDays = entries
        .map((entry) =>
            DateTime(entry.date.year, entry.date.month, entry.date.day))
        .toSet();
    final plannedDays = plans
        .map((plan) => DateTime(plan.scheduledAt.year, plan.scheduledAt.month,
            plan.scheduledAt.day))
        .toSet();
    final completedPlanDays = plannedDays.where(activeDays.contains).length;
    final executionRate = plannedDays.isEmpty
        ? null
        : ((completedPlanDays / plannedDays.length) * 100).round();
    final focus = _topFocusLabel(entries, isKo);
    final strongest = _topPhrase(
      entries.map((entry) => entry.goodPoints).toList(growable: false),
      isKo: isKo,
      fallback: isKo ? '강점 기록 필요' : 'Need strength notes',
    );
    final weakest = _topPhrase(
      entries.map((entry) => entry.improvements).toList(growable: false),
      isKo: isKo,
      fallback: isKo ? '보완점 기록 필요' : 'Need improvement notes',
    );
    final nextAction = _topPhrase(
      entries.map((entry) => entry.nextGoal).toList(growable: false),
      isKo: isKo,
      fallback: executionRate != null && executionRate < 70
          ? (isKo ? '계획한 날 훈련 완료부터 회복' : 'Recover plan completion first')
          : (isKo
              ? '다음 목표를 훈련노트에 적어주세요'
              : 'Add the next goal in training logs'),
    );
    final streak = _currentTrainingStreak(entries);
    final overviewMessage = _buildOverviewMessage(
      isKo: isKo,
      totalMinutes: totalMinutes,
      sessions: entries.length,
      executionRate: executionRate,
      weakest: weakest,
      nextAction: nextAction,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(
          icon: Icons.insights_outlined,
          title: isKo ? '이번 기간 성장 요약' : 'Growth Summary',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _MetricCard(
              label: isKo ? '훈련 횟수' : 'Sessions',
              value: isKo ? '${entries.length}회' : '${entries.length}',
            ),
            _MetricCard(
              label: isKo ? '총 훈련 시간' : 'Total time',
              value: _formatMinutesAsTime(totalMinutes, isKo: isKo),
            ),
            _MetricCard(
              label: isKo ? '계획 실행률' : 'Plan execution',
              value: executionRate == null
                  ? (isKo ? '계획 없음' : 'No plan')
                  : '$executionRate%',
            ),
            _MetricCard(
              label: isKo ? '집중 분야' : 'Focus',
              value: focus,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _CoachMessage(
          icon: Icons.auto_awesome_outlined,
          title: isKo ? '코치 해석' : 'Coach Insight',
          message: overviewMessage,
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 700;
            final cards = [
              _InsightMiniCard(
                title: isKo ? '가장 좋아진 점' : 'Best gain',
                value: strongest,
                icon: Icons.trending_up_outlined,
              ),
              _InsightMiniCard(
                title: isKo ? '가장 약한 점' : 'Weak spot',
                value: weakest,
                icon: Icons.report_problem_outlined,
              ),
              _InsightMiniCard(
                title: isKo ? '다음 액션' : 'Next action',
                value: nextAction,
                icon: Icons.flag_outlined,
              ),
              _InsightMiniCard(
                title: isKo ? '꾸준함' : 'Consistency',
                value: isKo ? '$streak일 연속 기록' : '$streak-day streak',
                icon: Icons.local_fire_department_outlined,
              ),
            ];
            if (!wide) {
              return Column(
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    cards[i],
                    if (i != cards.length - 1) const SizedBox(height: 10),
                  ],
                ],
              );
            }
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: cards
                  .map(
                    (card) => SizedBox(
                      width: (constraints.maxWidth - 10) / 2,
                      child: card,
                    ),
                  )
                  .toList(growable: false),
            );
          },
        ),
      ],
    );
  }
}

class _MatchOverviewSection extends StatelessWidget {
  final List<TrainingEntry> entries;
  final bool isKo;

  const _MatchOverviewSection({
    required this.entries,
    required this.isKo,
  });

  @override
  Widget build(BuildContext context) {
    final wins = entries.where((entry) => _matchOutcome(entry) == 1).length;
    final losses = entries.where((entry) => _matchOutcome(entry) == -1).length;
    final playerGoals = entries.fold<int>(
      0,
      (sum, entry) => sum + (entry.playerGoals ?? 0),
    );
    final playerAssists = entries.fold<int>(
      0,
      (sum, entry) => sum + (entry.playerAssists ?? 0),
    );
    final direction = wins >= losses
        ? (isKo ? '최근 흐름이 무너지지 않았습니다.' : 'Recent match trend is stable.')
        : (isKo ? '결과 흐름 관리가 필요합니다.' : 'Result trend needs attention.');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(
          icon: Icons.sports_soccer_outlined,
          title: isKo ? '시합 해석' : 'Match Insight',
        ),
        const SizedBox(height: 12),
        _CoachMessage(
          icon: Icons.tips_and_updates_outlined,
          title: isKo ? '기간 해석' : 'Period Insight',
          message: isKo
              ? '${entries.length}경기 동안 개인 기록은 $playerGoals골 $playerAssists도움입니다. $direction'
              : 'Across ${entries.length} matches you produced $playerGoals goals and $playerAssists assists. $direction',
        ),
      ],
    );
  }
}

class _MatchSummaryCard extends StatelessWidget {
  final List<TrainingEntry> entries;

  const _MatchSummaryCard({required this.entries});

  @override
  Widget build(BuildContext context) {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final wins = entries.where((entry) => _matchOutcome(entry) == 1).length;
    final draws = entries.where((entry) => _matchOutcome(entry) == 0).length;
    final losses = entries.where((entry) => _matchOutcome(entry) == -1).length;
    final scored = entries.fold<int>(
      0,
      (sum, entry) => sum + (entry.scoredGoals ?? 0),
    );
    final conceded = entries.fold<int>(
      0,
      (sum, entry) => sum + (entry.concededGoals ?? 0),
    );
    final playerGoals = entries.fold<int>(
      0,
      (sum, entry) => sum + (entry.playerGoals ?? 0),
    );
    final playerAssists = entries.fold<int>(
      0,
      (sum, entry) => sum + (entry.playerAssists ?? 0),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.scoreboard_outlined,
          title: isKo ? '시합 요약' : 'Match Summary',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _MetricCard(
              label: isKo ? '총 시합' : 'Matches',
              value: isKo ? '${entries.length}경기' : '${entries.length}',
            ),
            _MetricCard(
              label: isKo ? '전적' : 'Record',
              value: isKo ? '$wins승 $draws무 $losses패' : '$wins-$draws-$losses',
            ),
            _MetricCard(
              label: isKo ? '득실점' : 'Goals',
              value: '$scored:$conceded',
            ),
            _MetricCard(
              label: isKo ? '개인 기록' : 'Personal',
              value: isKo
                  ? '$playerGoals골 $playerAssists도움'
                  : '$playerGoals G / $playerAssists A',
            ),
          ],
        ),
      ],
    );
  }
}

class _MatchHistorySection extends StatelessWidget {
  final List<TrainingEntry> entries;

  const _MatchHistorySection({required this.entries});

  @override
  Widget build(BuildContext context) {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final sorted = [...entries]..sort(TrainingEntry.compareByRecentCreated);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.format_list_bulleted_outlined,
          title: isKo ? '전체 시합 기록' : 'All Match Records',
        ),
        const SizedBox(height: 12),
        ...sorted.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _MatchHistoryTile(entry: entry),
          ),
        ),
      ],
    );
  }
}

class _MatchHistoryTile extends StatelessWidget {
  final TrainingEntry entry;

  const _MatchHistoryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final opponent = entry.opponentTeam.trim().isEmpty
        ? (isKo ? '상대 미입력' : 'Opponent unset')
        : entry.opponentTeam.trim();
    final detailLine = [
      if (entry.playerGoals != null)
        isKo ? '득점 ${entry.playerGoals}' : 'Goals ${entry.playerGoals}',
      if (entry.playerAssists != null)
        isKo ? '도움 ${entry.playerAssists}' : 'Assists ${entry.playerAssists}',
      if (entry.minutesPlayed != null)
        isKo ? '${entry.minutesPlayed}분 출전' : '${entry.minutesPlayed} min',
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat.yMMMd(locale).add_E().format(entry.date),
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 4),
          Text(
            '${entry.type.trim().isEmpty ? (isKo ? '시합' : 'Match') : entry.type.trim()} · $opponent',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            _matchResultLabel(entry, isKo: isKo),
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (detailLine.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(detailLine),
          ],
          if (entry.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              entry.notes.trim(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;

  const _MetricCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.of(context).size.width - 42) / 2;
    return Container(
      width: width < 150 ? double.infinity : width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _InsightMiniCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _InsightMiniCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 10),
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
                const SizedBox(height: 6),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.45,
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

int _matchOutcome(TrainingEntry entry) {
  final scored = entry.scoredGoals;
  final conceded = entry.concededGoals;
  if (scored == null || conceded == null) return 0;
  if (scored > conceded) return 1;
  if (scored < conceded) return -1;
  return 0;
}

String _matchResultLabel(TrainingEntry entry, {required bool isKo}) {
  final scored = entry.scoredGoals;
  final conceded = entry.concededGoals;
  if (scored == null && conceded == null) {
    return isKo ? '결과 미입력' : 'Result unset';
  }
  final resultLabel = switch (_matchOutcome(entry)) {
    1 => isKo ? '승' : 'Win',
    -1 => isKo ? '패' : 'Loss',
    _ => isKo ? '무' : 'Draw',
  };
  return '$resultLabel ${scored ?? '-'}:${conceded ?? '-'}';
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

class _StatsPlanLite {
  final DateTime scheduledAt;

  const _StatsPlanLite({required this.scheduledAt});

  factory _StatsPlanLite.fromMap(Map<String, dynamic> map) {
    return _StatsPlanLite(
      scheduledAt: DateTime.tryParse(map['scheduledAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

String _topFocusLabel(List<TrainingEntry> entries, bool isKo) {
  final counts = <String, int>{};
  for (final entry in entries) {
    for (final value in <String>[
      ...entry.goalFocuses,
      entry.program,
      entry.type,
    ]) {
      final text = value.trim();
      if (text.isEmpty) continue;
      counts[text] = (counts[text] ?? 0) + 1;
    }
  }
  if (counts.isEmpty) {
    return isKo ? '기본기' : 'Fundamentals';
  }
  final sorted = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return sorted.first.key;
}

String _topPhrase(
  List<String> rawValues, {
  required bool isKo,
  required String fallback,
}) {
  final counts = <String, int>{};
  for (final raw in rawValues) {
    for (final chunk in raw.split(RegExp(r'[\n,/]'))) {
      final text = chunk.trim();
      if (text.isEmpty) continue;
      counts[text] = (counts[text] ?? 0) + 1;
    }
  }
  if (counts.isEmpty) return fallback;
  final sorted = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return sorted.first.key;
}

int _currentTrainingStreak(List<TrainingEntry> entries) {
  final workedDays = entries
      .map((entry) =>
          DateTime(entry.date.year, entry.date.month, entry.date.day))
      .toSet()
      .toList(growable: false)
    ..sort((a, b) => b.compareTo(a));
  if (workedDays.isEmpty) return 0;
  var streak = 1;
  for (var i = 1; i < workedDays.length; i++) {
    final gap = workedDays[i - 1].difference(workedDays[i]).inDays;
    if (gap == 1) {
      streak += 1;
      continue;
    }
    break;
  }
  return streak;
}

String _buildOverviewMessage({
  required bool isKo,
  required int totalMinutes,
  required int sessions,
  required int? executionRate,
  required String weakest,
  required String nextAction,
}) {
  final executionText = executionRate == null
      ? (isKo ? '계획 데이터는 아직 없습니다.' : 'No plan data yet.')
      : (isKo
          ? '계획 실행률은 $executionRate%입니다.'
          : 'Plan execution is $executionRate%.');
  return isKo
      ? '이번 기간 훈련은 총 ${_formatMinutesAsTime(totalMinutes, isKo: true)}, $sessions회입니다. $executionText 가장 약한 지점은 $weakest 쪽으로 보이고, 다음엔 $nextAction 를 먼저 가져가면 좋습니다.'
      : 'This period totals ${_formatMinutesAsTime(totalMinutes, isKo: false)} across $sessions sessions. $executionText The main weak area looks like $weakest, and the next priority is $nextAction.';
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

class _StatsPanel extends StatelessWidget {
  final Widget child;

  const _StatsPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.38)
            : colorScheme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.42),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
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
