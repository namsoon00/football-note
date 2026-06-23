import 'package:flutter/material.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:intl/intl.dart';

import '../../application/player_level_service.dart';
import '../../domain/repositories/option_repository.dart';
import '../localization/player_progression_localizations.dart';
import '../widgets/app_bar_action_button.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final history = _levelService.loadXpHistory()
      ..sort((a, b) => b.awardedAt.compareTo(a.awardedAt));
    final groupedHistory = _groupByDay(history);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.xpHistoryTitle),
        actions: [
          if (history.isNotEmpty)
            AppBarActionButton.label(
              onPressed: () => _confirmClearHistory(l10n),
              tooltip: l10n.xpHistoryClearAllAction,
              icon: const Icon(Icons.delete_sweep_outlined),
              label: l10n.xpHistoryClearAllAction,
              maxLabelWidth: 96,
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
                      l10n.xpHistoryEmpty,
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
                            l10n: l10n,
                            count: history.length,
                            latest: history.first,
                          ),
                        ],
                      );
                    }
                    final section = groupedHistory[index - 1];
                    return _XpHistoryDaySection(
                      isKo: isKo,
                      l10n: l10n,
                      day: section.day,
                      items: section.items,
                      onDelete: (item) => _deleteHistoryItem(item, l10n),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Future<void> _deleteHistoryItem(
    PlayerXpHistoryEntry item,
    AppLocalizations l10n,
  ) async {
    await _levelService.deleteXpHistoryEntry(item);
    if (!mounted) return;
    setState(() {});
    AppFeedback.showSuccess(context, text: l10n.xpHistoryMessageDeleted);
  }

  Future<void> _confirmClearHistory(AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.xpHistoryDeleteDialogTitle),
        content: Text(l10n.xpHistoryDeleteDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.xpHistoryClearAllAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _levelService.clearXpHistory();
    if (!mounted) return;
    setState(() {});
    AppFeedback.showSuccess(context, text: l10n.xpHistoryAllDeleted);
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
  final AppLocalizations l10n;
  final int count;
  final PlayerXpHistoryEntry latest;

  const _XpHistorySummaryCard({
    required this.l10n,
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
            l10n.xpHistoryRecentFlow,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.xpHistorySummaryCount(count),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.xpHistorySummaryLatest(l10n.xpHistoryTitleFor(latest)),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _XpHistoryDaySection extends StatelessWidget {
  final bool isKo;
  final AppLocalizations l10n;
  final DateTime day;
  final List<PlayerXpHistoryEntry> items;
  final ValueChanged<PlayerXpHistoryEntry> onDelete;

  const _XpHistoryDaySection({
    required this.isKo,
    required this.l10n,
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
            l10n.xpHistoryDayEventCount(items.length),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          for (var index = 0; index < items.length; index++) ...[
            _XpHistoryTimelineRow(
              item: items[index],
              isKo: isKo,
              l10n: l10n,
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
  final AppLocalizations l10n;
  final bool showConnector;
  final VoidCallback onDelete;

  const _XpHistoryTimelineRow({
    required this.item,
    required this.isKo,
    required this.l10n,
    required this.showConnector,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final positive = item.deltaXp >= 0;
    final accent =
        positive ? theme.colorScheme.primary : theme.colorScheme.error;
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
                            l10n.xpHistoryTitleFor(item),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatXpHistoryTimestamp(item.awardedAt, isKo),
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
                      tooltip: l10n.xpHistoryDeleteMessageTooltip,
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
                    _HistoryPill(label: l10n.xpHistoryTotalXp(item.totalXp)),
                    _HistoryPill(
                      label: item.leveledUp
                          ? 'Lv.${item.beforeLevel} -> Lv.${item.afterLevel}'
                          : l10n.xpHistoryStayedAtLevel(item.afterLevel),
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
                          label: l10n.xpHistoryReasonLabel(reason),
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

String _formatXpHistoryTimestamp(DateTime value, bool isKo) {
  return isKo
      ? DateFormat('M월 d일 a h:mm', 'ko').format(value)
      : DateFormat('MMM d, h:mm a', 'en').format(value);
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
