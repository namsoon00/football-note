import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../application/backup_service.dart';
import '../../application/locale_service.dart';
import '../../application/news_badge_service.dart';
import '../../application/player_level_service.dart';
import '../../application/settings_service.dart';
import '../../application/training_board_service.dart';
import '../../application/training_plan_reminder_service.dart';
import '../../application/training_service.dart';
import '../../domain/entities/training_board.dart';
import '../../domain/entities/training_entry.dart';
import '../../domain/repositories/option_repository.dart';
import '../widgets/app_background.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_page_route.dart';
import '../widgets/player_level_visuals.dart';
import '../widgets/shared_tab_header.dart';
import '../widgets/watch_cart/watch_cart_card.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'skill_quiz_screen.dart';
import 'news_screen.dart';
import 'notification_center_screen.dart';
import 'coach_lesson_screen.dart';
import 'player_level_guide_screen.dart';
import 'training_method_board_screen.dart';

class HomeHubScreen extends StatefulWidget {
  final TrainingService trainingService;
  final LocaleService localeService;
  final OptionRepository optionRepository;
  final SettingsService settingsService;
  final BackupService? driveBackupService;
  final VoidCallback onCreate;
  final VoidCallback? onQuickPlan;
  final VoidCallback? onQuickMatch;
  final VoidCallback? onQuickQuiz;
  final VoidCallback? onQuickBoard;
  final VoidCallback onOpenPlans;
  final VoidCallback onOpenLogs;
  final VoidCallback onOpenDiary;
  final VoidCallback onOpenWeeklyStats;
  final ValueChanged<TrainingEntry> onEdit;
  final ValueChanged<TrainingEntry> onEditTrainingBoard;
  final Future<void> Function({DateTime? initialDate}) onCreateTrainingBoard;

  const HomeHubScreen({
    super.key,
    required this.trainingService,
    required this.localeService,
    required this.optionRepository,
    required this.settingsService,
    this.driveBackupService,
    required this.onCreate,
    this.onQuickPlan,
    this.onQuickMatch,
    this.onQuickQuiz,
    this.onQuickBoard,
    required this.onOpenPlans,
    required this.onOpenLogs,
    required this.onOpenDiary,
    required this.onOpenWeeklyStats,
    required this.onEdit,
    required this.onEditTrainingBoard,
    required this.onCreateTrainingBoard,
  });

  @override
  State<HomeHubScreen> createState() => _HomeHubScreenState();
}

class _HomeHubScreenState extends State<HomeHubScreen> {
  @override
  void initState() {
    super.initState();
    NewsBadgeService.refresh(widget.optionRepository);
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
        currentIndex: 0,
      ),
      body: AppBackground(
        child: SafeArea(
          child: StreamBuilder<List<TrainingEntry>>(
            stream: widget.trainingService.watchEntries(),
            builder: (context, snapshot) {
              final allEntries = (snapshot.data ?? const <TrainingEntry>[])
                  .where((entry) => !entry.isMatch)
                  .toList()
                ..sort(TrainingEntry.compareByRecentCreated);
              final isKo = Localizations.localeOf(context).languageCode == 'ko';
              final boardsById = TrainingBoardService(
                widget.optionRepository,
              ).boardMap();
              final boards = boardsById.values.toList(growable: false)
                ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
              final levelState = PlayerLevelService(
                widget.optionRepository,
              ).loadState();
              final data = _HomeHubData.build(
                entries: allEntries,
                plans: _loadPlans(widget.optionRepository),
                boards: boards,
                quizCompletedAt: _loadQuizCompletedAt(widget.optionRepository),
                viewedDiaryDayToken: widget.optionRepository.getValue<String>(
                  CoachLessonScreen.todayViewedDiaryDayKey,
                ),
                quizResumeSummary: SkillQuizScreen.loadResumeSummary(
                  widget.optionRepository,
                ),
              );
              final reminderUnreadCount = TrainingPlanReminderService(
                widget.optionRepository,
                widget.settingsService,
              ).unreadReminderCountSync();

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ValueListenableBuilder<int>(
                      valueListenable: NewsBadgeService.listenable(
                        widget.optionRepository,
                      ),
                      builder: (context, newsCount, _) {
                        return Builder(
                          builder: (context) => SharedTabHeader(
                            padding: EdgeInsets.zero,
                            onLeadingTap: () =>
                                Scaffold.of(context).openDrawer(),
                            profilePhotoSource:
                                widget.optionRepository.getValue<String>(
                                      'profile_photo_url',
                                    ) ??
                                    '',
                            onNewsTap: _openNews,
                            newsBadgeCount: newsCount,
                            onQuizTap: _openQuizShortcut,
                            onProfileTap: () => _openProfile(context),
                            onNotificationTap: _openNotifications,
                            notificationBadgeCount: reminderUnreadCount,
                            onSettingsTap: () => _openSettings(context),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _LevelHeroCard(
                      levelState: levelState,
                      isKo: isKo,
                      onTap: _openLevelGuide,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            isKo ? '오늘의 홈' : 'Today Home',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                    if (data.todayPlanCount > 0) ...[
                      const SizedBox(height: 8),
                      _TodayPlanHighlightCard(
                        isKo: isKo,
                        count: data.todayPlanCount,
                        onTap: widget.onOpenPlans,
                      ),
                    ] else if (data.upcomingPlanDays.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _PlanDaysCard(
                        isKo: isKo,
                        days: data.upcomingPlanDays,
                        onTap: widget.onOpenPlans,
                      ),
                    ],
                    const SizedBox(height: 12),
                    _PriorityActionCard(
                      data: data,
                      isKo: isKo,
                      onPrimaryTap: _trackedAction(
                        'priority_action',
                        data.focusSignal == 'log_today'
                            ? widget.onOpenPlans
                            : data.focusSignal == 'add_session'
                                ? widget.onOpenWeeklyStats
                                : data.focusSignal == 'add_minutes'
                                    ? widget.onQuickBoard
                                    : data.focusSignal == 'recovery'
                                        ? widget.onOpenWeeklyStats
                                        : _openLevelGuide,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DailyFlowCard(
                      data: data,
                      isKo: isKo,
                      onLog: _trackedAction('daily_flow_log', widget.onCreate),
                      onLifting: _trackedAction(
                        'daily_flow_lifting',
                        () => _openTodayEntryOrCreate(data),
                      ),
                      onJumpRope: _trackedAction(
                        'daily_flow_jump_rope',
                        () => _openTodayEntryOrCreate(data),
                      ),
                      onQuiz: _trackedAction(
                        'daily_flow_quiz',
                        widget.onQuickQuiz,
                      ),
                      onReview: _trackedAction(
                        'daily_flow_review',
                        widget.onOpenDiary,
                      ),
                      onBoard: _trackedAction(
                        'daily_flow_board',
                        () => _openTodayBoardSketch(data),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _QuickActionGrid(
                      isKo: isKo,
                      onQuickMatch: _trackedAction(
                        'quick_create_match',
                        widget.onQuickMatch,
                      ),
                      onQuickPlan: _trackedAction(
                        'quick_create_plan',
                        widget.onQuickPlan,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ContinueCard(
                      data: data,
                      isKo: isKo,
                      onContinueQuiz: widget.onQuickQuiz,
                      onContinueTraining: data.latestTrainingEntry == null
                          ? widget.onCreate
                          : () => widget.onEdit(data.latestTrainingEntry!),
                      onContinueMatch: widget.onQuickMatch,
                      onContinuePlan: widget.onOpenPlans,
                      onContinueBoard: data.latestBoard == null
                          ? widget.onQuickBoard
                          : () => _openBoard(context, data.latestBoard!),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  static List<_DashboardPlan> _loadPlans(OptionRepository optionRepository) {
    final raw = optionRepository.getValue<String>('training_plans_v1');
    if (raw == null || raw.trim().isEmpty) return const <_DashboardPlan>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <_DashboardPlan>[];
      return decoded
          .whereType<Map>()
          .map((item) => _DashboardPlan.fromMap(item.cast<String, dynamic>()))
          .toList(growable: false);
    } catch (_) {
      return const <_DashboardPlan>[];
    }
  }

  static DateTime? _loadQuizCompletedAt(OptionRepository optionRepository) {
    final raw = optionRepository.getValue<String>('skill_quiz_completed_at');
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> _openSettings(BuildContext context) async {
    await Navigator.of(context).push(
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
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ProfileScreen(optionRepository: widget.optionRepository),
      ),
    );
  }

  Future<void> _openNews() async {
    await Navigator.of(context).push(
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
    if (!mounted) return;
    await NewsBadgeService.refresh(widget.optionRepository);
  }

  Future<void> _openQuizShortcut() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            SkillQuizScreen(optionRepository: widget.optionRepository),
      ),
    );
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotificationCenterScreen(
          optionRepository: widget.optionRepository,
          settingsService: widget.settingsService,
        ),
      ),
    );
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _openBoard(BuildContext context, TrainingBoard board) async {
    await Navigator.of(context).push<void>(
      AppPageRoute(
        builder: (_) => TrainingMethodBoardScreen(
          boardTitle: board.title,
          initialLayoutJson: board.layoutJson,
          optionRepository: widget.optionRepository,
          initialSelectedBoardIds: [board.id],
          initialBoardId: board.id,
        ),
      ),
    );
  }

  VoidCallback? _trackedAction(String key, VoidCallback? action) {
    if (action == null) return null;
    return () {
      unawaited(_trackHomeActionTap(key));
      action();
    };
  }

  Future<void> _trackHomeActionTap(String key) async {
    final metricKey = 'home_action_count_v1_$key';
    final current = widget.optionRepository.getValue(metricKey) as int? ?? 0;
    await widget.optionRepository.setValue(metricKey, current + 1);
    await widget.optionRepository.setValue(
      'home_action_last_tap_at_v1',
      DateTime.now().toIso8601String(),
    );
  }

  void _openTodayEntryOrCreate(_HomeHubData data) {
    final entry = data.latestTrainingEntry;
    if (entry == null) {
      widget.onCreate();
      return;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entryDay = DateTime(
      entry.date.year,
      entry.date.month,
      entry.date.day,
    );
    if (entryDay == today) {
      widget.onEdit(entry);
      return;
    }
    widget.onCreate();
  }

  void _openTodayBoardSketch(_HomeHubData data) {
    final entry = data.latestCreatedTrainingEntry;
    if (entry != null) {
      final createdDay = DateTime(
        entry.createdAt.year,
        entry.createdAt.month,
        entry.createdAt.day,
      );
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      if (createdDay == today) {
        widget.onEditTrainingBoard(entry);
        return;
      }
    }
    unawaited(widget.onCreateTrainingBoard(initialDate: DateTime.now()));
  }

  Future<void> _openLevelGuide() async {
    final levelState = PlayerLevelService(widget.optionRepository).loadState();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayerLevelGuideScreen(
          currentLevel: levelState.level,
          optionRepository: widget.optionRepository,
        ),
      ),
    );
  }
}

class _HomeHubData {
  final int weeklyTrainingCount;
  final int weeklyMinutes;
  final int streakDays;
  final int boardCount;
  final DateTime? latestBoardUpdatedAt;
  final TrainingBoard? latestBoard;
  final int todayPlanCount;
  final List<_PlanDaySummary> upcomingPlanDays;
  final String strongestSignal;
  final String focusSignal;
  final TrainingEntry? latestTrainingEntry;
  final TrainingEntry? latestCreatedTrainingEntry;
  final bool loggedTrainingToday;
  final bool loggedLiftingToday;
  final bool loggedJumpRopeToday;
  final bool reviewedTodayDiary;
  final bool quizCompletedToday;
  final bool loggedBoardToday;
  final SkillQuizResumeSummary quizResumeSummary;

  const _HomeHubData({
    required this.weeklyTrainingCount,
    required this.weeklyMinutes,
    required this.streakDays,
    required this.boardCount,
    required this.latestBoardUpdatedAt,
    required this.latestBoard,
    required this.todayPlanCount,
    required this.upcomingPlanDays,
    required this.strongestSignal,
    required this.focusSignal,
    required this.latestTrainingEntry,
    required this.latestCreatedTrainingEntry,
    required this.loggedTrainingToday,
    required this.loggedLiftingToday,
    required this.loggedJumpRopeToday,
    required this.reviewedTodayDiary,
    required this.quizCompletedToday,
    required this.loggedBoardToday,
    required this.quizResumeSummary,
  });

  factory _HomeHubData.build({
    required List<TrainingEntry> entries,
    required List<_DashboardPlan> plans,
    required List<TrainingBoard> boards,
    required DateTime? quizCompletedAt,
    required String? viewedDiaryDayToken,
    required SkillQuizResumeSummary quizResumeSummary,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekEndExclusive = weekStart.add(const Duration(days: 7));
    final weeklyEntries = entries
        .where(
          (entry) =>
              !entry.date.isBefore(weekStart) &&
              entry.date.isBefore(weekEndExclusive),
        )
        .toList(growable: false);
    final weeklyMinutes = weeklyEntries.fold<int>(
      0,
      (sum, entry) => sum + entry.durationMinutes,
    );
    final latestTrainingEntry = entries.isEmpty ? null : entries.first;
    final latestCreatedTrainingEntry = entries.where((entry) {
      final createdDay = DateTime(
        entry.createdAt.year,
        entry.createdAt.month,
        entry.createdAt.day,
      );
      return createdDay == today;
    }).fold<TrainingEntry?>(
      null,
      (latest, entry) =>
          latest == null || entry.createdAt.isAfter(latest.createdAt)
              ? entry
              : latest,
    );
    final todayEntries = entries.where((entry) {
      final day = DateTime(
        entry.date.year,
        entry.date.month,
        entry.date.day,
      );
      return day == today;
    }).toList(growable: false);
    final loggedTrainingToday = todayEntries.isNotEmpty;
    final loggedLiftingToday = todayEntries.any(
      (entry) => entry.liftingByPart.values.any((value) => value > 0),
    );
    final loggedJumpRopeToday = todayEntries.any(_hasCompletedJumpRope);

    final entryDays = entries
        .map(
          (entry) =>
              DateTime(entry.date.year, entry.date.month, entry.date.day),
        )
        .toSet();
    var streakDays = 0;
    DateTime? cursor = latestTrainingEntry == null
        ? null
        : DateTime(
            latestTrainingEntry.date.year,
            latestTrainingEntry.date.month,
            latestTrainingEntry.date.day,
          );
    while (cursor != null && entryDays.contains(cursor)) {
      streakDays++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    final todayPlanCount = plans.where((plan) {
      final day = DateTime(
        plan.scheduledAt.year,
        plan.scheduledAt.month,
        plan.scheduledAt.day,
      );
      return day == today;
    }).length;
    final planDayCount = <DateTime, int>{};
    for (final plan in plans) {
      final day = DateTime(
        plan.scheduledAt.year,
        plan.scheduledAt.month,
        plan.scheduledAt.day,
      );
      if (day.isBefore(today)) continue;
      planDayCount[day] = (planDayCount[day] ?? 0) + 1;
    }
    final upcomingPlanDays = planDayCount.entries.toList(growable: false)
      ..sort((a, b) => a.key.compareTo(b.key));
    final upcomingPlanDaySummaries = upcomingPlanDays
        .take(7)
        .map((entry) => _PlanDaySummary(day: entry.key, count: entry.value))
        .toList(growable: false);
    final totalMood = weeklyEntries.fold<int>(
      0,
      (sum, entry) => sum + entry.mood,
    );
    final averageMood =
        weeklyEntries.isEmpty ? 0 : totalMood / weeklyEntries.length;

    String strongest;
    String focus;
    if (weeklyEntries.length >= 4) {
      strongest = 'consistency';
    } else if (averageMood >= 4) {
      strongest = 'condition';
    } else if (weeklyMinutes >= 180) {
      strongest = 'volume';
    } else {
      strongest = 'restart';
    }

    if (weeklyEntries.isEmpty) {
      focus = 'log_today';
    } else if (weeklyEntries.length < 3) {
      focus = 'add_session';
    } else if (weeklyMinutes < 150) {
      focus = 'add_minutes';
    } else if (averageMood < 3) {
      focus = 'recovery';
    } else {
      focus = 'upgrade_quality';
    }

    final quizCompletedToday = quizCompletedAt != null &&
        quizCompletedAt.year == now.year &&
        quizCompletedAt.month == now.month &&
        quizCompletedAt.day == now.day;
    final reviewedTodayDiary =
        viewedDiaryDayToken == CoachLessonScreen.todayViewedDayToken(now);
    final loggedBoardToday = boards.isNotEmpty &&
        boards.first.updatedAt.year == now.year &&
        boards.first.updatedAt.month == now.month &&
        boards.first.updatedAt.day == now.day;

    return _HomeHubData(
      weeklyTrainingCount: weeklyEntries.length,
      weeklyMinutes: weeklyMinutes,
      streakDays: streakDays,
      boardCount: boards.length,
      latestBoardUpdatedAt: boards.isEmpty ? null : boards.first.updatedAt,
      latestBoard: boards.isEmpty ? null : boards.first,
      todayPlanCount: todayPlanCount,
      upcomingPlanDays: upcomingPlanDaySummaries,
      strongestSignal: strongest,
      focusSignal: focus,
      latestTrainingEntry: latestTrainingEntry,
      latestCreatedTrainingEntry: latestCreatedTrainingEntry,
      loggedTrainingToday: loggedTrainingToday,
      loggedLiftingToday: loggedLiftingToday,
      loggedJumpRopeToday: loggedJumpRopeToday,
      reviewedTodayDiary: reviewedTodayDiary,
      quizCompletedToday: quizCompletedToday,
      loggedBoardToday: loggedBoardToday,
      quizResumeSummary: quizResumeSummary,
    );
  }
}

class _DashboardPlan {
  final DateTime scheduledAt;

  const _DashboardPlan({required this.scheduledAt});

  factory _DashboardPlan.fromMap(Map<String, dynamic> map) {
    return _DashboardPlan(
      scheduledAt: DateTime.tryParse(map['scheduledAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class _PlanDaySummary {
  final DateTime day;
  final int count;

  const _PlanDaySummary({required this.day, required this.count});
}

bool _hasCompletedJumpRope(TrainingEntry entry) {
  if (!entry.jumpRopeEnabled) return false;
  return entry.jumpRopeCount > 0 || entry.jumpRopeMinutes > 0;
}

class _TodayPlanHighlightCard extends StatelessWidget {
  final bool isKo;
  final int count;
  final VoidCallback onTap;

  const _TodayPlanHighlightCard({
    required this.isKo,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.18),
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.22),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.event_note_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isKo ? '오늘의 훈련 계획' : 'Today training plan',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isKo
                          ? '등록된 계획 $count개를 바로 확인하세요.'
                          : 'Open your $count saved plans for today.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isKo ? '계획 보기' : 'Open plans',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.primary,
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

class _LevelHeroCard extends StatelessWidget {
  final PlayerLevelState levelState;
  final bool isKo;
  final VoidCallback onTap;

  const _LevelHeroCard({
    required this.levelState,
    required this.isKo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final spec = PlayerLevelVisualSpec.fromLevel(levelState.level);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('level-hero-card'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                spec.colors.first.withValues(alpha: 0.92),
                spec.colors.last.withValues(alpha: 0.92),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
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
                                color: Colors.white.withValues(alpha: 0.20),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'Lv.${levelState.level}',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                PlayerLevelService.levelName(
                                  levelState.level,
                                  isKo,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.chevron_right,
                              color: Colors.white,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isKo
                              ? '다음까지 ${levelState.xpToNextLevel}XP'
                              : '${levelState.xpToNextLevel} XP left',
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.92),
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _HomeLevelIllustration(isKo: isKo, level: levelState.level),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: levelState.progress,
                minHeight: 5,
                borderRadius: BorderRadius.circular(999),
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyFlowCard extends StatelessWidget {
  final _HomeHubData data;
  final bool isKo;
  final VoidCallback? onLog;
  final VoidCallback? onLifting;
  final VoidCallback? onJumpRope;
  final VoidCallback? onQuiz;
  final VoidCallback? onReview;
  final VoidCallback? onBoard;

  const _DailyFlowCard({
    required this.data,
    required this.isKo,
    required this.onLog,
    required this.onLifting,
    required this.onJumpRope,
    required this.onQuiz,
    required this.onReview,
    required this.onBoard,
  });

  @override
  Widget build(BuildContext context) {
    final completedCount = <bool>[
      data.loggedTrainingToday,
      data.loggedLiftingToday,
      data.loggedJumpRopeToday,
      data.quizCompletedToday,
      data.reviewedTodayDiary,
      data.loggedBoardToday,
    ].where((done) => done).length;
    final progress = completedCount / 6;
    return WatchCartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isKo ? '오늘 할 일' : 'Today tasks',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              Text(
                isKo ? '$completedCount/6 완료' : '$completedCount/6 done',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            borderRadius: BorderRadius.circular(999),
          ),
          const SizedBox(height: 8),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.0,
            children: [
              _TodoChip(
                done: data.loggedTrainingToday,
                icon: Icons.menu_book_rounded,
                label: isKo ? '훈련기록' : 'Training',
                onTap: onLog,
              ),
              _TodoChip(
                done: data.loggedLiftingToday,
                icon: Icons.fitness_center_rounded,
                label: isKo ? '리프팅' : 'Lifting',
                onTap: onLifting,
              ),
              _TodoChip(
                done: data.loggedJumpRopeToday,
                icon: Icons.sports_gymnastics_rounded,
                label: isKo ? '줄넘기' : 'Jump',
                onTap: onJumpRope,
              ),
              _TodoChip(
                done: data.quizCompletedToday,
                icon: Icons.quiz_rounded,
                label: isKo ? '퀴즈' : 'Quiz',
                onTap: onQuiz,
              ),
              _TodoChip(
                done: data.reviewedTodayDiary,
                icon: Icons.auto_stories_rounded,
                label: isKo ? '다이어리' : 'Diary',
                onTap: onReview,
              ),
              _TodoChip(
                done: data.loggedBoardToday,
                icon: Icons.developer_board_outlined,
                label: isKo ? '훈련스케치' : 'Sketch',
                onTap: onBoard,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriorityActionCard extends StatelessWidget {
  final _HomeHubData data;
  final bool isKo;
  final VoidCallback? onPrimaryTap;

  const _PriorityActionCard({
    required this.data,
    required this.isKo,
    required this.onPrimaryTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (message, buttonLabel, icon) = _copy();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.secondaryContainer.withValues(alpha: 0.95),
            theme.colorScheme.primaryContainer.withValues(alpha: 0.70),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  maxLines: 2,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: onPrimaryTap,
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  minimumSize: const Size(1, 44),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                child: Text(
                  buttonLabel,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  (String, String, IconData) _copy() {
    int pick(List<(String, String, IconData)> options, int salt) {
      final now = DateTime.now();
      final seed = (now.year * 10000) +
          (now.month * 100) +
          now.day +
          (data.weeklyTrainingCount * 7) +
          (data.streakDays * 13) +
          (data.todayPlanCount * 17) +
          salt;
      return seed.abs() % options.length;
    }

    switch (data.focusSignal) {
      case 'log_today':
        final options = <(String, String, IconData)>[
          (
            isKo
                ? '오늘 기록 전, 남은 계획을 먼저 확인하세요.'
                : 'Check the remaining plans before logging today.',
            isKo ? '계획 보기' : 'Open plans',
            Icons.event_note_outlined,
          ),
          (
            isKo
                ? '기록부터 열기 전에 오늘 예정된 훈련을 짧게 점검해 보세요.'
                : 'Before logging, quickly review your planned sessions today.',
            isKo ? '오늘 계획' : 'Today plans',
            Icons.today_outlined,
          ),
          (
            isKo
                ? '지금 해야 할 훈련이 남아 있으면 먼저 체크하고 시작해요.'
                : 'If any session is still pending, check it first and start.',
            isKo ? '남은 계획' : 'Pending plans',
            Icons.checklist_rtl_outlined,
          ),
          (
            isKo
                ? '훈련 기록 품질은 계획 확인부터 시작됩니다. 먼저 훑어보세요.'
                : 'Higher quality logs start with checking the plan first.',
            isKo ? '일정 확인' : 'Review schedule',
            Icons.schedule_outlined,
          ),
          (
            isKo
                ? '오늘 할 일을 먼저 정리하면 기록이 더 간결해집니다.'
                : 'Clarifying today tasks first makes your logs cleaner.',
            isKo ? '할 일 확인' : 'Check tasks',
            Icons.fact_check_outlined,
          ),
        ];
        return options[pick(options, 11)];
      case 'add_session':
        final options = <(String, String, IconData)>[
          (
            isKo
                ? '주간 흐름을 보고 다음 세션을 추가하세요.'
                : 'Review the weekly flow before adding another session.',
            isKo ? '주간 통계 보기' : 'Open weekly stats',
            Icons.bar_chart_outlined,
          ),
          (
            isKo
                ? '이번 주 누락된 구간을 확인하고 다음 훈련을 채워보세요.'
                : 'Find this week gaps and fill them with your next session.',
            isKo ? '누락 확인' : 'Find gaps',
            Icons.insights_outlined,
          ),
          (
            isKo
                ? '연속 훈련 흐름을 이어가려면 지금 다음 세션을 잡는 게 좋아요.'
                : 'To keep momentum, set the next session now.',
            isKo ? '다음 세션' : 'Next session',
            Icons.trending_up_outlined,
          ),
          (
            isKo
                ? '주간 밸런스를 보고 부족한 유형 훈련을 추가해보세요.'
                : 'Check weekly balance and add the missing type of session.',
            isKo ? '밸런스 보기' : 'View balance',
            Icons.balance_outlined,
          ),
          (
            isKo
                ? '지금 한 번 더 세션을 잡아두면 주말 몰아치기를 줄일 수 있어요.'
                : 'Adding one session now prevents weekend overload.',
            isKo ? '세션 추가' : 'Add session',
            Icons.add_task_outlined,
          ),
        ];
        return options[pick(options, 23)];
      case 'add_minutes':
        final options = <(String, String, IconData)>[
          (
            isKo
                ? '다음 훈련 길이는 보드에서 먼저 잡아두세요.'
                : 'Shape the next longer session on the board first.',
            isKo ? '훈련판 열기' : 'Open board',
            Icons.developer_board_outlined,
          ),
          (
            isKo
                ? '시간을 늘리고 싶다면 보드에서 흐름 3단계만 먼저 설계해보세요.'
                : 'If you want longer minutes, sketch 3 phases on the board first.',
            isKo ? '보드 설계' : 'Sketch flow',
            Icons.route_outlined,
          ),
          (
            isKo
                ? '보드에 시작-전개-마무리만 잡아도 훈련 시간이 자연스럽게 늘어요.'
                : 'Defining start-build-finish on board naturally extends session time.',
            isKo ? '흐름 만들기' : 'Build sequence',
            Icons.schema_outlined,
          ),
          (
            isKo
                ? '오늘은 보드 한 장으로 훈련 길이 목표를 먼저 고정해보세요.'
                : 'Lock today time target with one board layout first.',
            isKo ? '목표 고정' : 'Lock target',
            Icons.push_pin_outlined,
          ),
          (
            isKo
                ? '긴 훈련은 즉흥보다 설계가 중요해요. 보드부터 열어보세요.'
                : 'Long sessions need structure. Open board before starting.',
            isKo ? '보드 먼저' : 'Board first',
            Icons.view_quilt_outlined,
          ),
        ];
        return options[pick(options, 37)];
      case 'recovery':
        final options = <(String, String, IconData)>[
          (
            isKo
                ? '최근 컨디션 흐름을 보고 강도를 조절하세요.'
                : 'Review the recent condition trend before adjusting load.',
            isKo ? '주간 통계 보기' : 'Open weekly stats',
            Icons.monitor_heart_outlined,
          ),
          (
            isKo
                ? '회복 지표를 보고 오늘 강도를 한 단계 조정해 보세요.'
                : 'Check recovery signals and tune today intensity by one level.',
            isKo ? '회복 확인' : 'Check recovery',
            Icons.health_and_safety_outlined,
          ),
          (
            isKo
                ? '컨디션이 흔들리면 양보다 품질로 전환하는 게 좋습니다.'
                : 'If condition dips, shift from volume to quality.',
            isKo ? '컨디션 보기' : 'View condition',
            Icons.favorite_outline,
          ),
          (
            isKo
                ? '회복 흐름 점검 후 세션 길이를 재조정해 보세요.'
                : 'After recovery review, rebalance session duration.',
            isKo ? '흐름 점검' : 'Review trend',
            Icons.query_stats_outlined,
          ),
          (
            isKo
                ? '강도 조절은 데이터 기반이 가장 안전해요. 통계를 확인하세요.'
                : 'Data-first load adjustment is safest. Open stats.',
            isKo ? '통계 열기' : 'Open stats',
            Icons.stacked_line_chart_outlined,
          ),
        ];
        return options[pick(options, 53)];
      default:
        final options = <(String, String, IconData)>[
          (
            isKo
                ? '보상 확인 후 다음 훈련 흐름을 바로 잡아보세요.'
                : 'Review rewards, then shape the next training flow.',
            isKo ? '레벨 가이드' : 'Level guide',
            Icons.military_tech_outlined,
          ),
          (
            isKo
                ? '지금 성장 포인트를 확인하고 오늘 목표를 짧게 정해보세요.'
                : 'Check growth points and set a short goal for today.',
            isKo ? '성장 보기' : 'View growth',
            Icons.auto_graph_outlined,
          ),
          (
            isKo
                ? '레벨 진행 상황을 보면 다음 훈련 우선순위가 선명해집니다.'
                : 'Level progress clarifies your next training priority.',
            isKo ? '진행 확인' : 'Check progress',
            Icons.flag_circle_outlined,
          ),
          (
            isKo
                ? '보상 화면에서 다음 동기 포인트를 잡아보세요.'
                : 'Use reward view to lock your next motivation point.',
            isKo ? '보상 보기' : 'Open rewards',
            Icons.emoji_events_outlined,
          ),
          (
            isKo
                ? '오늘은 레벨 가이드를 보고 훈련 방향을 1개만 정해보세요.'
                : 'Open level guide and choose one training direction today.',
            isKo ? '가이드 열기' : 'Open guide',
            Icons.explore_outlined,
          ),
        ];
        return options[pick(options, 71)];
    }
  }
}

class _PlanDaysCard extends StatelessWidget {
  final bool isKo;
  final List<_PlanDaySummary> days;
  final VoidCallback? onTap;

  const _PlanDaysCard({
    required this.isKo,
    required this.days,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final totalPlans = days.fold<int>(0, (sum, item) => sum + item.count);
    final next = days.first;
    final nextLabel = isKo
        ? '${next.day.month}월 ${next.day.day}일'
        : DateFormat('EEE M/d').format(next.day);
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final remainingDays = next.day.difference(today).inDays;
    final whenText = remainingDays <= 0
        ? (isKo ? '오늘' : 'Today')
        : remainingDays == 1
            ? (isKo ? '내일' : 'Tomorrow')
            : (isKo ? '$remainingDays일 뒤' : 'In $remainingDays days');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.22),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.event_note_outlined,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isKo ? '다음 훈련' : 'Next training',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isKo
                          ? '$nextLabel · ${next.count}개 예정'
                          : '$nextLabel · ${next.count} planned',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isKo
                          ? '$whenText · 앞으로 총 $totalPlans개'
                          : '$whenText · $totalPlans upcoming',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionGrid extends StatelessWidget {
  final bool isKo;
  final VoidCallback? onQuickMatch;
  final VoidCallback? onQuickPlan;

  const _QuickActionGrid({
    required this.isKo,
    required this.onQuickMatch,
    required this.onQuickPlan,
  });

  @override
  Widget build(BuildContext context) {
    final primaryItems = <_QuickActionItem>[
      _QuickActionItem(
        icon: Icons.sports_soccer_outlined,
        title: isKo ? '시합 기록' : 'Add match',
        onTap: onQuickMatch,
      ),
      _QuickActionItem(
        icon: Icons.event_note_outlined,
        title: isKo ? '훈련 계획' : 'Add plan',
        onTap: onQuickPlan,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isKo ? '빠른 실행' : 'Quick actions',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 3.1,
          ),
          itemCount: primaryItems.length,
          itemBuilder: (context, index) =>
              _QuickActionButton(item: primaryItems[index]),
        ),
      ],
    );
  }
}

class _ContinueCard extends StatelessWidget {
  final _HomeHubData data;
  final bool isKo;
  final VoidCallback? onContinueQuiz;
  final VoidCallback? onContinueTraining;
  final VoidCallback? onContinueMatch;
  final VoidCallback? onContinuePlan;
  final VoidCallback? onContinueBoard;

  const _ContinueCard({
    required this.data,
    required this.isKo,
    required this.onContinueQuiz,
    required this.onContinueTraining,
    required this.onContinueMatch,
    required this.onContinuePlan,
    required this.onContinueBoard,
  });

  @override
  Widget build(BuildContext context) {
    final quizSummary = data.quizResumeSummary;
    final hasQuizSession = quizSummary.hasActiveSession;
    final latestTrainingEntry = data.latestTrainingEntry;
    final latestTrainingIsToday = latestTrainingEntry != null &&
        DateTime(
              latestTrainingEntry.date.year,
              latestTrainingEntry.date.month,
              latestTrainingEntry.date.day,
            ) ==
            DateTime.now().copyWith(
              hour: 0,
              minute: 0,
              second: 0,
              millisecond: 0,
              microsecond: 0,
            );
    final quizTitle = hasQuizSession
        ? (quizSummary.reviewMode
            ? (isKo ? '오답 복습 이어하기' : 'Continue wrong-answer review')
            : (isKo ? '퀴즈 이어하기' : 'Continue quiz'))
        : (isKo ? '새 퀴즈 시작' : 'Start quiz');
    final quizSubtitle = hasQuizSession
        ? (isKo
            ? '${quizSummary.currentIndex + 1} / ${quizSummary.totalQuestions} 진행 중'
            : 'In progress ${quizSummary.currentIndex + 1} / ${quizSummary.totalQuestions}')
        : (isKo ? '오늘 퀴즈를 다시 시작해요.' : 'Jump back into today’s quiz.');
    final items = <_ContinueItemData>[
      if (latestTrainingIsToday)
        _ContinueItemData(
          icon: Icons.edit_note_outlined,
          title: isKo ? '오늘 훈련 기록' : 'Today training log',
          subtitle: latestTrainingEntry.program.trim().isEmpty
              ? '${DateFormat('M/d').format(latestTrainingEntry.date)} · ${latestTrainingEntry.durationMinutes}${isKo ? '분' : ' min'}'
              : '${latestTrainingEntry.program.trim()} · ${DateFormat('M/d').format(latestTrainingEntry.date)}',
          buttonLabel: isKo ? '이어서 쓰기' : 'Continue',
          onPressed: onContinueTraining,
        ),
      if (data.todayPlanCount > 0)
        _ContinueItemData(
          icon: Icons.event_note_outlined,
          title: isKo ? '오늘 훈련 계획' : 'Today training plan',
          subtitle: isKo
              ? '오늘 계획 ${data.todayPlanCount}개가 있어요.'
              : '${data.todayPlanCount} plans are waiting today.',
          buttonLabel: isKo ? '계획 보기' : 'Open plans',
          onPressed: onContinuePlan,
        ),
      if (hasQuizSession)
        _ContinueItemData(
          icon: Icons.quiz_outlined,
          title: quizTitle,
          subtitle: quizSubtitle,
          buttonLabel: isKo ? '퀴즈 열기' : 'Open quiz',
          onPressed: onContinueQuiz,
        ),
      if (data.boardCount > 0)
        _ContinueItemData(
          icon: Icons.developer_board_outlined,
          title: isKo ? '최근 훈련보드' : 'Recent training board',
          subtitle: data.latestBoard == null
              ? (isKo
                  ? '스케치 ${data.boardCount}개'
                  : '${data.boardCount} sketches')
              : data.latestBoardUpdatedAt == null
                  ? (isKo
                      ? '스케치 ${data.boardCount}개'
                      : '${data.boardCount} sketches')
                  : (isKo
                      ? '${data.latestBoard!.title} · 최근 저장 ${DateFormat('M/d').format(data.latestBoardUpdatedAt!)}'
                      : '${data.latestBoard!.title} · saved ${DateFormat('M/d').format(data.latestBoardUpdatedAt!)}'),
          buttonLabel: isKo ? '바로 수정' : 'Edit now',
          onPressed: onContinueBoard,
        ),
    ];
    return WatchCartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isKo ? '이어하기' : 'Continue',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            Text(
              isKo
                  ? '오늘은 이어서 할 액션이 없어요. 아래에서 새 도전을 골라보세요.'
                  : 'Nothing to continue today. Pick a fresh challenge below.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ContinueItem(item: item),
              ),
            ),
        ],
      ),
    );
  }
}

class _ContinueItemData {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback? onPressed;

  const _ContinueItemData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onPressed,
  });
}

class _ContinueItem extends StatelessWidget {
  final _ContinueItemData item;

  const _ContinueItem({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: item.onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  item.icon,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                item.buttonLabel,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionItem {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const _QuickActionItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}

class _QuickActionButton extends StatelessWidget {
  final _QuickActionItem item;

  const _QuickActionButton({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: item.onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.18),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    strutStyle: const StrutStyle(
                      fontSize: 14,
                      height: 1.05,
                      forceStrutHeight: true,
                    ),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontSize: 14,
                          height: 1.05,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeLevelIllustration extends StatelessWidget {
  final bool isKo;
  final int level;

  const _HomeLevelIllustration({required this.isKo, required this.level});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.topRight,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Positioned(
            right: 2,
            top: 0,
            child: PlayerLevelIllustration(level: level, size: 46),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
              ),
              child: Text(
                PlayerLevelService.illustrationLabel(level, isKo),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodoChip extends StatelessWidget {
  final bool done;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _TodoChip({
    required this.done,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: done
                  ? const Color(0xFF0FA968).withValues(alpha: 0.40)
                  : scheme.outlineVariant.withValues(alpha: 0.55),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                done ? Icons.check_circle : icon,
                size: 18,
                color: done ? const Color(0xFF0FA968) : scheme.primary,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  strutStyle: const StrutStyle(
                    fontSize: 14,
                    height: 1.05,
                    forceStrutHeight: true,
                  ),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontSize: 14,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
