import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../application/player_level_service.dart';
import '../../domain/repositories/option_repository.dart';
import '../widgets/app_background.dart';

class PlayerXpHistoryScreen extends StatelessWidget {
  final OptionRepository optionRepository;

  const PlayerXpHistoryScreen({super.key, required this.optionRepository});

  @override
  Widget build(BuildContext context) {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final history = PlayerLevelService(optionRepository).loadXpHistory();

    return Scaffold(
      appBar: AppBar(title: Text(isKo ? '경험치 히스토리' : 'XP history')),
      body: AppBackground(
        child: SafeArea(
          child: history.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      isKo ? '아직 쌓인 경험치 기록이 없습니다.' : 'No XP history yet.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: history.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = history[index];
                    return _XpHistoryCard(item: item, isKo: isKo);
                  },
                ),
        ),
      ),
    );
  }
}

class _XpHistoryCard extends StatelessWidget {
  final PlayerXpHistoryEntry item;
  final bool isKo;

  const _XpHistoryCard({required this.item, required this.isKo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final positive = item.deltaXp >= 0;
    final deltaText = positive ? '+${item.deltaXp} XP' : '${item.deltaXp} XP';
    final accent = positive
        ? theme.colorScheme.primary
        : theme.colorScheme.error;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title(item, isKo),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _timestamp(item.awardedAt, isKo),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                deltaText,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HistoryPill(
                label: isKo
                    ? '누적 ${item.totalXp} XP'
                    : '${item.totalXp} XP total',
              ),
              _HistoryPill(
                label: item.leveledUp
                    ? (isKo
                          ? 'Lv.${item.beforeLevel} -> Lv.${item.afterLevel}'
                          : 'Lv.${item.beforeLevel} -> Lv.${item.afterLevel}')
                    : (isKo
                          ? 'Lv.${item.afterLevel} 유지'
                          : 'Stayed at Lv.${item.afterLevel}'),
              ),
            ],
          ),
          if (item.reasons.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final reason in item.reasons)
                  _HistoryReasonChip(label: _reasonLabel(reason, isKo)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _title(PlayerXpHistoryEntry item, bool isKo) {
    switch (item.category) {
      case PlayerXpHistoryCategory.training:
        final label = item.label.trim();
        if (label.isEmpty) return isKo ? '훈련 기록 저장' : 'Training log';
        return isKo ? '훈련 기록 · $label' : 'Training log · $label';
      case PlayerXpHistoryCategory.quiz:
        return isKo ? '퀴즈 완료' : 'Quiz completion';
      case PlayerXpHistoryCategory.plan:
        return isKo ? '훈련 계획 생성' : 'Training plan created';
      case PlayerXpHistoryCategory.board:
        final label = item.label.trim();
        if (label.isEmpty) return isKo ? '훈련 스케치 저장' : 'Training sketch saved';
        return isKo ? '훈련 스케치 · $label' : 'Training sketch · $label';
      case PlayerXpHistoryCategory.diary:
        return isKo ? '오늘 다이어리 확인' : 'Today diary reviewed';
    }
  }

  static String _timestamp(DateTime value, bool isKo) {
    return isKo
        ? DateFormat('M월 d일 a h:mm', 'ko').format(value)
        : DateFormat('MMM d, h:mm a', 'en').format(value);
  }

  static String _reasonLabel(String reason, bool isKo) {
    switch (reason) {
      case 'log':
        return isKo ? '기본 기록' : 'base log';
      case 'first_daily_log':
        return isKo ? '하루 첫 기록' : 'first of day';
      case 'plan_completed':
        return isKo ? '계획 수행' : 'planned day';
      case 'lifting_missed':
        return isKo ? '리프팅 미기록' : 'no lifting';
      case 'jump_rope_missed':
        return isKo ? '줄넘기 미기록' : 'no jump rope';
      case 'streak_3':
        return isKo ? '3일 연속' : '3-day streak';
      case 'streak_7':
        return isKo ? '7일 연속' : '7-day streak';
      case 'weekly_3':
        return isKo ? '주간 3회' : '3 this week';
      case 'weekly_5':
        return isKo ? '주간 5회' : '5 this week';
      case 'quiz_complete':
        return isKo ? '퀴즈 완료' : 'quiz complete';
      case 'plan_created':
        return isKo ? '계획 생성' : 'plan created';
      case 'board_created':
        return isKo ? '보드 생성' : 'board created';
      case 'board_saved':
        return isKo ? '보드 저장' : 'board saved';
      case 'diary_reviewed':
        return isKo ? '다이어리 확인' : 'diary reviewed';
      default:
        return reason;
    }
  }
}

class _HistoryPill extends StatelessWidget {
  final String label;

  const _HistoryPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _HistoryReasonChip extends StatelessWidget {
  final String label;

  const _HistoryReasonChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
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
