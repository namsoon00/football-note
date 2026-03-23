import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../application/player_level_service.dart';
import '../../domain/repositories/option_repository.dart';
import '../widgets/app_background.dart';
import '../widgets/app_feedback.dart';

class PlayerXpHistoryScreen extends StatefulWidget {
  final OptionRepository optionRepository;

  const PlayerXpHistoryScreen({super.key, required this.optionRepository});

  @override
  State<PlayerXpHistoryScreen> createState() => _PlayerXpHistoryScreenState();
}

class _PlayerXpHistoryScreenState extends State<PlayerXpHistoryScreen> {
  late final PlayerLevelService _levelService;

  @override
  void initState() {
    super.initState();
    _levelService = PlayerLevelService(widget.optionRepository);
  }

  @override
  Widget build(BuildContext context) {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final history = _levelService.loadXpHistory()
      ..sort((a, b) => b.awardedAt.compareTo(a.awardedAt));
    final groupedHistory = _groupByDay(history);

    return Scaffold(
      appBar: AppBar(
        title: Text(isKo ? '경험치 히스토리' : 'XP history'),
        actions: [
          if (history.isNotEmpty)
            TextButton(
              onPressed: () => _confirmClearHistory(isKo),
              child: Text(isKo ? '전체 삭제' : 'Clear all'),
            ),
        ],
      ),
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
                  itemCount: groupedHistory.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Column(
                        children: [
                          _XpHistorySummaryCard(
                            isKo: isKo,
                            count: history.length,
                            latest: history.first,
                          ),
                        ],
                      );
                    }
                    final section = groupedHistory[index - 1];
                    return _XpHistoryDaySection(
                      isKo: isKo,
                      day: section.day,
                      items: section.items,
                      onDelete: (item) => _deleteHistoryItem(item, isKo),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Future<void> _deleteHistoryItem(PlayerXpHistoryEntry item, bool isKo) async {
    await _levelService.deleteXpHistoryEntry(item);
    if (!mounted) return;
    setState(() {});
    AppFeedback.showSuccess(
      context,
      text: isKo ? '경험치 메세지를 삭제했어요.' : 'XP message deleted.',
    );
  }

  Future<void> _confirmClearHistory(bool isKo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isKo ? '경험치 메세지 삭제' : 'Delete XP messages'),
        content: Text(
          isKo ? '쌓인 경험치 메세지를 모두 삭제할까요?' : 'Delete all saved XP messages?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(isKo ? '취소' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(isKo ? '전체 삭제' : 'Clear all'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _levelService.clearXpHistory();
    if (!mounted) return;
    setState(() {});
    AppFeedback.showSuccess(
      context,
      text: isKo ? '경험치 메세지를 모두 삭제했어요.' : 'All XP messages deleted.',
    );
  }

  List<_XpHistoryDaySectionData> _groupByDay(
    List<PlayerXpHistoryEntry> history,
  ) {
    final sections = <_XpHistoryDaySectionData>[];
    for (final item in history) {
      final day = DateTime(
        item.awardedAt.year,
        item.awardedAt.month,
        item.awardedAt.day,
      );
      if (sections.isNotEmpty && sections.last.day == day) {
        sections.last.items.add(item);
        continue;
      }
      sections.add(_XpHistoryDaySectionData(day: day, items: [item]));
    }
    return sections;
  }
}

class _XpHistorySummaryCard extends StatelessWidget {
  final bool isKo;
  final int count;
  final PlayerXpHistoryEntry latest;

  const _XpHistorySummaryCard({
    required this.isKo,
    required this.count,
    required this.latest,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isKo ? '최근 경험치 흐름' : 'Recent XP flow',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isKo
                ? '총 $count개의 기록이 저장되어 있습니다.'
                : '$count history items are saved.',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            isKo
                ? '아래에서 날짜와 시간 순서대로 바로 내려가며 확인할 수 있어요. 최근 기록은 ${_XpHistoryCard._title(latest, isKo)} 입니다.'
                : 'Below, entries are arranged in date and time order. Latest entry: ${_XpHistoryCard._title(latest, isKo)}.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _XpHistoryDaySection extends StatelessWidget {
  final bool isKo;
  final DateTime day;
  final List<PlayerXpHistoryEntry> items;
  final ValueChanged<PlayerXpHistoryEntry> onDelete;

  const _XpHistoryDaySection({
    required this.isKo,
    required this.day,
    required this.items,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _dayLabel(day, isKo),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isKo ? '${items.length}개의 경험치 변동' : '${items.length} XP events',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          for (var index = 0; index < items.length; index++) ...[
            _XpHistoryTimelineRow(
              item: items[index],
              isKo: isKo,
              showConnector: index != items.length - 1,
              onDelete: () => onDelete(items[index]),
            ),
            if (index != items.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  static String _dayLabel(DateTime value, bool isKo) {
    return isKo
        ? DateFormat('M월 d일 EEEE', 'ko').format(value)
        : DateFormat('EEE, MMM d').format(value);
  }
}

class _XpHistoryTimelineRow extends StatelessWidget {
  final PlayerXpHistoryEntry item;
  final bool isKo;
  final bool showConnector;
  final VoidCallback onDelete;

  const _XpHistoryTimelineRow({
    required this.item,
    required this.isKo,
    required this.showConnector,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final positive = item.deltaXp >= 0;
    final accent = positive
        ? theme.colorScheme.primary
        : theme.colorScheme.error;
    final deltaText = positive ? '+${item.deltaXp} XP' : '${item.deltaXp} XP';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 54,
          child: Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              if (showConnector)
                Container(
                  width: 2,
                  height: 88,
                  margin: const EdgeInsets.only(top: 4),
                  color: theme.colorScheme.outlineVariant,
                ),
            ],
          ),
        ),
        Expanded(
          child: Container(
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
                            _XpHistoryCard._title(item, isKo),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _XpHistoryCard._timestamp(item.awardedAt, isKo),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      deltaText,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    IconButton(
                      tooltip: isKo ? '메세지 삭제' : 'Delete message',
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
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
                          ? 'Lv.${item.beforeLevel} -> Lv.${item.afterLevel}'
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
                        _HistoryReasonChip(
                          label: _XpHistoryCard._reasonLabel(reason, isKo),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _XpHistoryCard extends StatelessWidget {
  final PlayerXpHistoryEntry item;
  final bool isKo;
  final VoidCallback onDelete;

  const _XpHistoryCard({
    required this.item,
    required this.isKo,
    required this.onDelete,
  });

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
              IconButton(
                tooltip: isKo ? '메세지 삭제' : 'Delete message',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
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
      case 'lifting_added':
        return isKo ? '리프팅 추가 기록' : 'lifting added';
      case 'jump_rope_added':
        return isKo ? '줄넘기 추가 기록' : 'jump rope added';
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

class _XpHistoryDaySectionData {
  final DateTime day;
  final List<PlayerXpHistoryEntry> items;

  const _XpHistoryDaySectionData({required this.day, required this.items});
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
