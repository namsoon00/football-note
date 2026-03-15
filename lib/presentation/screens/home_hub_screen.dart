import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../application/backup_service.dart';
import '../../application/locale_service.dart';
import '../../application/settings_service.dart';
import '../../application/training_board_service.dart';
import '../../application/training_service.dart';
import '../../domain/entities/training_entry.dart';
import '../../domain/repositories/option_repository.dart';
import '../widgets/app_background.dart';
import '../widgets/app_drawer.dart';
import '../widgets/watch_cart/main_app_bar.dart';
import '../widgets/watch_cart/watch_cart_card.dart';
import 'coach_lesson_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'news_screen.dart';
import 'space_speed_game_screen.dart';

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
  final VoidCallback onOpenLogs;
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
    required this.onOpenLogs,
    required this.onEdit,
  });

  @override
  State<HomeHubScreen> createState() => _HomeHubScreenState();
}

class _HomeHubScreenState extends State<HomeHubScreen> {
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
              final boardsById =
                  TrainingBoardService(widget.optionRepository).boardMap();
              final data = _HomeHubData.build(
                entries: allEntries,
                plans: _loadPlans(widget.optionRepository),
                boardCount: boardsById.length,
                quizCompletedAt: _loadQuizCompletedAt(widget.optionRepository),
              );

              return SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Builder(
                      builder: (context) => WatchCartAppBar(
                        onMenuTap: () => Scaffold.of(context).openDrawer(),
                        profilePhotoSource: widget.optionRepository
                                .getValue<String>('profile_photo_url') ??
                            '',
                        onNewsTap: _openNews,
                        onGameTap: _openGame,
                        onProfileTap: () => _openProfile(context),
                        onSettingsTap: () => _openSettings(context),
                        onCoachTap: () => _openCoach(context),
                      ),
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
                      onOpenLogs: widget.onOpenLogs,
                    ),
                    const SizedBox(height: 12),
                    _WeeklySummaryCard(data: data, isKo: isKo),
                    const SizedBox(height: 12),
                    _RecentLogPreview(
                      entries: allEntries.take(3).toList(growable: false),
                      isKo: isKo,
                      onOpenLogs: widget.onOpenLogs,
                      onEdit: widget.onEdit,
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
}

class _HomeHubData {
  final int weeklyTrainingCount;
  final int weeklyMinutes;
  final int streakDays;
  final int boardCount;
  final int todayPlanCount;
  final String strongestSignal;
  final String focusSignal;
  final TrainingEntry? latestEntry;
  final bool quizCompletedToday;

  const _HomeHubData({
    required this.weeklyTrainingCount,
    required this.weeklyMinutes,
    required this.streakDays,
    required this.boardCount,
    required this.todayPlanCount,
    required this.strongestSignal,
    required this.focusSignal,
    required this.latestEntry,
    required this.quizCompletedToday,
  });

  factory _HomeHubData.build({
    required List<TrainingEntry> entries,
    required List<_DashboardPlan> plans,
    required int boardCount,
    required DateTime? quizCompletedAt,
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
    final latestEntry = entries.isEmpty ? null : entries.first;

    final entryDays = entries
        .map((entry) =>
            DateTime(entry.date.year, entry.date.month, entry.date.day))
        .toSet();
    var streakDays = 0;
    DateTime? cursor = latestEntry == null
        ? null
        : DateTime(latestEntry.date.year, latestEntry.date.month,
            latestEntry.date.day);
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

    final totalMood =
        weeklyEntries.fold<int>(0, (sum, entry) => sum + entry.mood);
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
      boardCount: boardCount,
      todayPlanCount: todayPlanCount,
      strongestSignal: strongest,
      focusSignal: focus,
      latestEntry: latestEntry,
      quizCompletedToday: quizCompletedToday,
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

  const _WeeklyBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
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
    final latestLabel = data.latestEntry == null
        ? (isKo ? '최근 기록 없음' : 'No recent log')
        : (isKo
            ? '최근 기록 ${DateFormat('M/d').format(data.latestEntry!.date)}'
            : 'Last log ${DateFormat('M/d').format(data.latestEntry!.date)}');
    return WatchCartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isKo ? '오늘 해야 할 흐름을 바로 시작하세요.' : 'Start today with the right flow.',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatPill(
                icon: Icons.today_outlined,
                label: isKo
                    ? '오늘 계획 ${data.todayPlanCount}개'
                    : '${data.todayPlanCount} plans today',
              ),
              _StatPill(
                icon: Icons.local_fire_department_outlined,
                label: isKo
                    ? '${data.streakDays}일 연속'
                    : '${data.streakDays}-day streak',
              ),
              _StatPill(icon: Icons.history, label: latestLabel),
              _StatPill(
                icon: Icons.developer_board_outlined,
                label: isKo
                    ? '스케치 ${data.boardCount}개'
                    : '${data.boardCount} sketches',
              ),
            ],
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
  final VoidCallback onOpenLogs;

  const _QuickActionGrid({
    required this.isKo,
    required this.onCreate,
    required this.onQuickMatch,
    required this.onQuickPlan,
    required this.onQuickQuiz,
    required this.onOpenLogs,
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
        icon: Icons.list_alt_outlined,
        title: isKo ? '기록 보기' : 'View logs',
        onTap: onOpenLogs,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isKo ? '빠른 실행' : 'Quick actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
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
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
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

class _RecentLogPreview extends StatelessWidget {
  final List<TrainingEntry> entries;
  final bool isKo;
  final VoidCallback onOpenLogs;
  final ValueChanged<TrainingEntry> onEdit;

  const _RecentLogPreview({
    required this.entries,
    required this.isKo,
    required this.onOpenLogs,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return WatchCartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isKo ? '최근 훈련 미리보기' : 'Recent training preview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              TextButton(
                onPressed: onOpenLogs,
                child: Text(isKo ? '전체 보기' : 'View all'),
              ),
            ],
          ),
          if (entries.isEmpty)
            Text(isKo ? '아직 기록이 없습니다.' : 'No logs yet.')
          else
            ...entries.map(
              (entry) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.fitness_center_outlined),
                title: Text(
                  entry.program.trim().isEmpty
                      ? (isKo ? '훈련 기록' : 'Training log')
                      : entry.program.trim(),
                ),
                subtitle: Text(
                  '${DateFormat('M/d').format(entry.date)} · ${entry.durationMinutes}${isKo ? '분' : ' min'}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => onEdit(entry),
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
              color:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.18),
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
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}
