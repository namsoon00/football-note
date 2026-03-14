import 'package:flutter/material.dart';
import 'constants.dart';

class WatchCartHomeOptions extends StatelessWidget {
  final VoidCallback? onBoardList;
  final VoidCallback? onFilter;
  final VoidCallback? onSearch;
  final String? actionLabel;
  final String? boardListLabel;
  final String? boardListTitle;
  final int? boardBadgeCount;
  final int? badgeCount;
  final IconData? boardListIcon;

  const WatchCartHomeOptions({
    super.key,
    this.actionLabel,
    this.badgeCount,
    this.onBoardList,
    this.boardListLabel,
    this.boardListTitle,
    this.boardBadgeCount,
    this.boardListIcon,
    this.onFilter,
    this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final hasBoardButton = onBoardList != null;
    final hasSummaryButton =
        (actionLabel ?? '').trim().isNotEmpty && badgeCount != null;
    return Row(
      children: [
        _OptionButton(icon: Icons.search, onTap: onSearch),
        const SizedBox(width: 12),
        _OptionButton(icon: Icons.tune, onTap: onFilter),
        if (hasSummaryButton) ...[
          const SizedBox(width: 12),
          Expanded(
            child: _LabeledCountButton(
              onTap: null,
              semanticLabel: actionLabel,
              label: actionLabel!,
              count: badgeCount!,
            ),
          ),
        ],
        if (hasBoardButton) ...[
          const SizedBox(width: 12),
          Expanded(
            child: _LabeledCountButton(
              onTap: onBoardList!,
              semanticLabel: boardListLabel,
              label: boardListTitle ?? 'Boards',
              count: boardBadgeCount ?? 0,
              icon: boardListIcon,
            ),
          ),
        ],
      ],
    );
  }
}

class _OptionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _OptionButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.0),
        splashColor: WatchCartConstants.primaryColor.withAlpha(30),
        highlightColor: WatchCartConstants.primaryColor.withAlpha(15),
        child: Container(
          width: 60.0,
          height: 60.0,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: const Color.fromRGBO(230, 230, 230, 1)),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.onSurface),
        ),
      ),
    );
  }
}

class _LabeledCountButton extends StatelessWidget {
  final VoidCallback? onTap;
  final String? semanticLabel;
  final String label;
  final int count;
  final IconData? icon;

  const _LabeledCountButton({
    required this.onTap,
    required this.label,
    required this.count,
    this.semanticLabel,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final highlightColor = icon != null
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface;
    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8.0),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8.0),
          splashColor: WatchCartConstants.primaryColor.withAlpha(30),
          highlightColor: WatchCartConstants.primaryColor.withAlpha(15),
          child: Container(
            width: double.infinity,
            height: 60.0,
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: const Color.fromRGBO(230, 230, 230, 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 24, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: highlightColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 26.0,
                  height: 26.0,
                  decoration: BoxDecoration(
                    color: highlightColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      count.toString(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: highlightColor,
                        fontWeight: FontWeight.w700,
                      ),
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
