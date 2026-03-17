import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../application/backup_service.dart';
import '../../application/locale_service.dart';
import '../../application/news_service.dart';
import '../../application/player_level_service.dart';
import '../../application/settings_service.dart';
import '../../application/training_board_service.dart';
import '../../application/training_service.dart';
import '../../domain/entities/news_article.dart';
import '../../domain/entities/training_board.dart';
import '../../domain/entities/training_entry.dart';
import '../../domain/repositories/option_repository.dart';
import '../../infrastructure/rss_news_repository.dart';
import '../widgets/app_background.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_page_route.dart';
import '../widgets/player_level_visuals.dart';
import '../widgets/watch_cart/main_app_bar.dart';
import '../widgets/watch_cart/watch_cart_card.dart';
import 'coach_lesson_screen.dart';
import 'player_level_guide_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'skill_quiz_screen.dart';
import 'news_screen.dart';
import 'space_speed_game_screen.dart';
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
  final VoidCallback onOpenLogs;
  final VoidCallback onOpenWeeklyStats;
  final ValueChanged<TrainingEntry> onEdit;

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
    required this.onOpenLogs,
    required this.onOpenWeeklyStats,
    required this.onEdit,
  });

  @override
  State<HomeHubScreen> createState() => _HomeHubScreenState();
}

class _HomeHubScreenState extends State<HomeHubScreen> {
  late Future<int> _newsCountFuture;

  @override
  void initState() {
    super.initState();
    _newsCountFuture = _loadNewsCount();
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
              final rewardStatuses = PlayerLevelService(
                widget.optionRepository,
              ).loadRewardStatuses();
              final data = _HomeHubData.build(
                entries: allEntries,
                plans: _loadPlans(widget.optionRepository),
                boards: boards,
                quizCompletedAt: _loadQuizCompletedAt(widget.optionRepository),
                quizResumeSummary: SkillQuizScreen.loadResumeSummary(
                  widget.optionRepository,
                ),
                newsCountFuture: _newsCountFuture,
              );

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
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
                        onNewsTap: _openNews,
                        onGameTap: _openGame,
                        onProfileTap: () => _openProfile(context),
                        onSettingsTap: () => _openSettings(context),
                        onCoachTap: () => _openCoach(context),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _LevelHeroCard(
                      levelState: levelState,
                      rewardStatuses: rewardStatuses,
                      isKo: isKo,
                      onTap: () => _openLevelGuide(context, levelState.level),
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
                        const SizedBox(width: 8),
                        _WeeklyBadge(
                          label: isKo
                              ? '이번 주 ${data.weeklyTrainingCount}회'
                              : '${data.weeklyTrainingCount} this week',
                          onTap: widget.onOpenWeeklyStats,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _TodayOverviewCard(data: data, isKo: isKo),
                    const SizedBox(height: 12),
                    _QuickActionGrid(
                      isKo: isKo,
                      onCreate: widget.onCreate,
                      onQuickMatch: widget.onQuickMatch,
                      onQuickPlan: widget.onQuickPlan,
                      onQuickQuiz: widget.onQuickQuiz,
                      onQuickBoard: widget.onQuickBoard,
                      onOpenWeeklyStats: () => _openWeeklyStats(context),
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
                      onContinuePlan: widget.onQuickPlan,
                      onContinueBoard: data.latestBoard == null
                          ? widget.onQuickBoard
                          : () => _openBoard(context, data.latestBoard!),
                    ),
                    const SizedBox(height: 12),
                    _WeeklySummaryCard(data: data, isKo: isKo),
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

  Future<void> _openCoach(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CoachLessonScreen(
          optionRepository: widget.optionRepository,
          trainingService: widget.trainingService,
          localeService: widget.localeService,
          settingsService: widget.settingsService,
          driveBackupService: widget.driveBackupService,
        ),
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
    setState(() {
      _newsCountFuture = _loadNewsCount();
    });
  }

  Future<void> _openGame() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SpaceSpeedGameScreen(
          trainingService: widget.trainingService,
          localeService: widget.localeService,
          optionRepository: widget.optionRepository,
          settingsService: widget.settingsService,
          driveBackupService: widget.driveBackupService,
        ),
      ),
    );
  }

  Future<void> _openLevelGuide(BuildContext context, int currentLevel) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayerLevelGuideScreen(
          currentLevel: currentLevel,
          optionRepository: widget.optionRepository,
        ),
      ),
    );
  }

  Future<void> _openWeeklyStats(BuildContext context) async {
    widget.onOpenWeeklyStats();
    await Future<void>.delayed(Duration.zero);
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

  Future<int> _loadNewsCount() async {
    final service = NewsService(RssNewsRepository(widget.optionRepository));
    final channels = service.channels();
    final seenKeys = <String>{};
    var count = 0;

    await Future.wait(
      channels.map((channel) async {
        try {
          final articles = await service.latest(channel.id);
          for (final article in articles) {
            final key = _newsArticleKey(article);
            if (!seenKeys.add(key)) continue;
            count += 1;
          }
        } catch (_) {
          // Ignore per-channel failures and show the count from successful feeds.
        }
      }),
    );

    return count;
  }

  String _newsArticleKey(NewsArticle article) {
    final link = article.link.trim();
    if (link.isNotEmpty) return link;
    return '${article.source.trim()}::${article.title.trim().toLowerCase()}';
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
  final String strongestSignal;
  final String focusSignal;
  final TrainingEntry? latestTrainingEntry;
  final bool loggedTrainingToday;
  final bool loggedLiftingToday;
  final bool loggedJumpRopeToday;
  final bool quizCompletedToday;
  final SkillQuizResumeSummary quizResumeSummary;
  final Future<int> newsCountFuture;

  const _HomeHubData({
    required this.weeklyTrainingCount,
    required this.weeklyMinutes,
    required this.streakDays,
    required this.boardCount,
    required this.latestBoardUpdatedAt,
    required this.latestBoard,
    required this.todayPlanCount,
    required this.strongestSignal,
    required this.focusSignal,
    required this.latestTrainingEntry,
    required this.loggedTrainingToday,
    required this.loggedLiftingToday,
    required this.loggedJumpRopeToday,
    required this.quizCompletedToday,
    required this.quizResumeSummary,
    required this.newsCountFuture,
  });

  factory _HomeHubData.build({
    required List<TrainingEntry> entries,
    required List<_DashboardPlan> plans,
    required List<TrainingBoard> boards,
    required DateTime? quizCompletedAt,
    required SkillQuizResumeSummary quizResumeSummary,
    required Future<int> newsCountFuture,
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
    final loggedJumpRopeToday = todayEntries.any(
      (entry) => entry.jumpRopeEnabled && entry.jumpRopeMinutes > 0,
    );

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

    return _HomeHubData(
      weeklyTrainingCount: weeklyEntries.length,
      weeklyMinutes: weeklyMinutes,
      streakDays: streakDays,
      boardCount: boards.length,
      latestBoardUpdatedAt: boards.isEmpty ? null : boards.first.updatedAt,
      latestBoard: boards.isEmpty ? null : boards.first,
      todayPlanCount: todayPlanCount,
      strongestSignal: strongest,
      focusSignal: focus,
      latestTrainingEntry: latestTrainingEntry,
      loggedTrainingToday: loggedTrainingToday,
      loggedLiftingToday: loggedLiftingToday,
      loggedJumpRopeToday: loggedJumpRopeToday,
      quizCompletedToday: quizCompletedToday,
      quizResumeSummary: quizResumeSummary,
      newsCountFuture: newsCountFuture,
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

class _WeeklyBadge extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _WeeklyBadge({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      ),
    );
  }
}

class _LevelHeroCard extends StatelessWidget {
  final PlayerLevelState levelState;
  final List<PlayerLevelRewardStatus> rewardStatuses;
  final bool isKo;
  final VoidCallback onTap;

  const _LevelHeroCard({
    required this.levelState,
    required this.rewardStatuses,
    required this.isKo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final spec = PlayerLevelVisualSpec.fromLevel(levelState.level);
    final claimableRewards = rewardStatuses.where(
      (item) =>
          item.isAvailable &&
          !item.isClaimed &&
          item.customRewardName.trim().isNotEmpty,
    );
    PlayerLevelRewardStatus? nextReward;
    for (final status in rewardStatuses) {
      if (status.customRewardName.trim().isEmpty || status.isClaimed) continue;
      nextReward = status;
      break;
    }
    final rewardSummary = claimableRewards.isNotEmpty
        ? (isKo
            ? '지금 받을 선물 ${claimableRewards.length}개'
            : '${claimableRewards.length} rewards ready')
        : nextReward == null
            ? (isKo ? '다음 선물이 아직 없어요' : 'No next reward yet')
            : nextReward.isAvailable
                ? (isKo
                    ? '지금 선물: ${nextReward.customRewardName}'
                    : 'Reward now: ${nextReward.customRewardName}')
                : (isKo
                    ? '다음 선물 Lv.${nextReward.reward.level} ${nextReward.customRewardName}'
                    : 'Next reward Lv.${nextReward.reward.level} ${nextReward.customRewardName}');
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('level-hero-card'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: spec.colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isKo ? '선수 레벨' : 'Player level',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.86),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Lv.${levelState.level} ${PlayerLevelService.levelName(levelState.level, isKo)}',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      PlayerLevelService.stageName(levelState.level, isKo),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: levelState.progress,
                        minHeight: 10,
                        backgroundColor: Colors.white.withValues(alpha: 0.22),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isKo
                          ? '다음 레벨까지 ${levelState.xpToNextLevel} XP'
                          : '${levelState.xpToNextLevel} XP to next level',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isKo
                          ? '총 ${levelState.totalXp} XP'
                          : 'Total ${levelState.totalXp} XP',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.86),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isKo ? '탭해서 전체 레벨 보기' : 'Tap to view all levels',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rewardSummary,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.94),
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _LevelIllustration(isKo: isKo, level: levelState.level),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelIllustration extends StatelessWidget {
  final bool isKo;
  final int level;

  const _LevelIllustration({required this.isKo, required this.level});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 118,
      height: 124,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 10,
            top: 8,
            child: PlayerLevelIllustration(level: level, size: 88),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    PlayerLevelService.illustrationLabel(level, isKo),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isKo ? '비주얼 성장 단계' : 'Visual growth tier',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayOverviewCard extends StatelessWidget {
  final _HomeHubData data;
  final bool isKo;

  const _TodayOverviewCard({required this.data, required this.isKo});

  @override
  Widget build(BuildContext context) {
    final latestLabel = data.latestTrainingEntry == null
        ? (isKo ? '최근 기록 없음' : 'No recent log')
        : (isKo
            ? '최근 기록 ${DateFormat('M/d').format(data.latestTrainingEntry!.date)}'
            : 'Last log ${DateFormat('M/d').format(data.latestTrainingEntry!.date)}');
    final todayStatus = data.loggedTrainingToday
        ? (isKo ? '오늘 기록 완료' : 'Today logged')
        : (isKo ? '오늘 기록 미완료' : 'Today not logged');
    final liftingStatus = data.loggedLiftingToday
        ? (isKo ? '리프팅 체크 완료' : 'Lifting checked')
        : (isKo ? '리프팅 미완료' : 'Lifting pending');
    final jumpRopeStatus = data.loggedJumpRopeToday
        ? (isKo ? '줄넘기 체크 완료' : 'Jump rope checked')
        : (isKo ? '줄넘기 미완료' : 'Jump rope pending');
    return WatchCartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FutureBuilder<int>(
            future: data.newsCountFuture,
            builder: (context, snapshot) {
              final newsCount = snapshot.data ?? 0;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatPill(
                    icon: Icons.newspaper_outlined,
                    label: isKo ? '소식 $newsCount개' : '$newsCount news',
                  ),
                  _StatPill(
                    icon: Icons.local_fire_department_outlined,
                    label: isKo
                        ? '${data.streakDays}일 연속'
                        : '${data.streakDays}-day streak',
                  ),
                  _StatPill(icon: Icons.history, label: latestLabel),
                  _StatPill(
                    icon: data.loggedTrainingToday
                        ? Icons.check_circle_outline
                        : Icons.radio_button_unchecked,
                    label: todayStatus,
                  ),
                  _StatPill(
                    icon: data.loggedLiftingToday
                        ? Icons.check_circle_outline
                        : Icons.radio_button_unchecked,
                    label: liftingStatus,
                  ),
                  _StatPill(
                    icon: data.loggedJumpRopeToday
                        ? Icons.check_circle_outline
                        : Icons.radio_button_unchecked,
                    label: jumpRopeStatus,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _QuickActionGrid extends StatelessWidget {
  final bool isKo;
  final VoidCallback onCreate;
  final VoidCallback? onQuickMatch;
  final VoidCallback? onQuickPlan;
  final VoidCallback? onQuickQuiz;
  final VoidCallback? onQuickBoard;
  final VoidCallback onOpenWeeklyStats;

  const _QuickActionGrid({
    required this.isKo,
    required this.onCreate,
    required this.onQuickMatch,
    required this.onQuickPlan,
    required this.onQuickQuiz,
    required this.onQuickBoard,
    required this.onOpenWeeklyStats,
  });

  @override
  Widget build(BuildContext context) {
    final items = <_QuickActionItem>[
      _QuickActionItem(
        icon: Icons.add_circle_outline,
        title: isKo ? '훈련 기록' : 'Add log',
        onTap: onCreate,
      ),
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
      _QuickActionItem(
        icon: Icons.quiz_outlined,
        title: isKo ? '퀴즈 시작' : 'Start quiz',
        onTap: onQuickQuiz,
      ),
      _QuickActionItem(
        icon: Icons.developer_board_outlined,
        title: isKo ? '훈련보드' : 'Boards',
        onTap: onQuickBoard,
      ),
      _QuickActionItem(
        icon: Icons.bar_chart_outlined,
        title: isKo ? '이번 주 통계' : 'This week stats',
        onTap: onOpenWeeklyStats,
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
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.38,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) =>
              _QuickActionButton(item: items[index]),
        ),
      ],
    );
  }
}

class _WeeklySummaryCard extends StatelessWidget {
  final _HomeHubData data;
  final bool isKo;

  const _WeeklySummaryCard({required this.data, required this.isKo});

  @override
  Widget build(BuildContext context) {
    return WatchCartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isKo ? '이번 주 성장 요약' : 'Weekly growth summary',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  label: isKo ? '훈련 횟수' : 'Sessions',
                  value: '${data.weeklyTrainingCount}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryMetric(
                  label: isKo ? '총 시간' : 'Minutes',
                  value: _formatWeeklyMinutes(data.weeklyMinutes, isKo),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isKo
                ? '강점: ${_strongestLabel(data.strongestSignal, true)}'
                : 'Strongest signal: ${_strongestLabel(data.strongestSignal, false)}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            isKo
                ? '다음 포커스: ${_focusLabel(data.focusSignal, true)}'
                : 'Next focus: ${_focusLabel(data.focusSignal, false)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            data.quizCompletedToday
                ? (isKo ? '오늘 퀴즈 완료' : 'Today quiz completed')
                : (isKo ? '오늘 퀴즈 미완료' : 'Today quiz not completed'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  String _strongestLabel(String key, bool isKo) {
    switch (key) {
      case 'consistency':
        return isKo ? '훈련 꾸준함' : 'consistency';
      case 'condition':
        return isKo ? '좋은 컨디션' : 'condition';
      case 'volume':
        return isKo ? '충분한 훈련량' : 'training volume';
      default:
        return isKo ? '다시 시작할 준비' : 'restart momentum';
    }
  }

  String _focusLabel(String key, bool isKo) {
    switch (key) {
      case 'add_session':
        return isKo ? '이번 주 1회 더 기록하기' : 'add one more session';
      case 'add_minutes':
        return isKo ? '훈련 시간을 조금 더 늘리기' : 'increase minutes';
      case 'recovery':
        return isKo ? '회복 중심으로 강도 조절하기' : 'balance recovery';
      case 'upgrade_quality':
        return isKo ? '기록의 질과 훈련 스케치 연결하기' : 'upgrade quality with sketches';
      default:
        return isKo ? '오늘 첫 기록 남기기' : 'log today';
    }
  }

  String _formatWeeklyMinutes(int minutes, bool isKo) {
    if (minutes < 60) return isKo ? '$minutes분' : '${minutes}m';
    final hours = minutes ~/ 60;
    final remainMinutes = minutes % 60;
    if (remainMinutes == 0) {
      return isKo ? '$hours시간' : '${hours}h';
    }
    return isKo ? '$hours시간 $remainMinutes분' : '${hours}h ${remainMinutes}m';
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
    final hasWrongReview = !hasQuizSession && quizSummary.pendingWrongCount > 0;
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
        : hasWrongReview
            ? (isKo ? '오답 복습 시작' : 'Start wrong-answer review')
            : (isKo ? '새 퀴즈 시작' : 'Start quiz');
    final quizSubtitle = hasQuizSession
        ? (isKo
            ? '${quizSummary.currentIndex + 1} / ${quizSummary.totalQuestions} 진행 중'
            : 'In progress ${quizSummary.currentIndex + 1} / ${quizSummary.totalQuestions}')
        : hasWrongReview
            ? (isKo
                ? '다시 풀 문제 ${quizSummary.pendingWrongCount}개'
                : '${quizSummary.pendingWrongCount} saved wrong answers')
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
      if (hasQuizSession || hasWrongReview)
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              item.icon,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                FilledButton.tonalIcon(
                  onPressed: item.onPressed,
                  icon: Icon(item.icon),
                  label: Text(item.buttonLabel),
                ),
              ],
            ),
          ),
        ],
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  item.icon,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const Spacer(),
                Text(
                  item.title,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
