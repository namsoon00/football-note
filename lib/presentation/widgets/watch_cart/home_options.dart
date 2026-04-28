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
  final bool filterActive;

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
    this.filterActive = false,
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
        _OptionButton(
          icon: Icons.tune,
          onTap: onFilter,
          isActive: filterActive,
        ),
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
  final bool isActive;

  const _OptionButton({required this.icon, this.onTap, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = isActive
        ? theme.colorScheme.primary
        : const Color.fromRGBO(230, 230, 230, 1);
    final backgroundColor = isActive
        ? theme.colorScheme.primary.withValues(alpha: 0.08)
        : Colors.transparent;
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
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: borderColor),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: Icon(
                  icon,
                  color: isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
              ),
              if (isActive)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    key: ValueKey('home-option-active-${icon.codePoint}'),
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
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
    final emphasize = icon != null && onTap != null;
    final highlightColor = emphasize
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;
    final borderColor = emphasize
        ? theme.colorScheme.primary
        : const Color.fromRGBO(230, 230, 230, 1);
    final backgroundColor = emphasize
        ? theme.colorScheme.primary
        : Colors.transparent;
    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8.0),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8.0),
          splashColor: emphasize
              ? theme.colorScheme.onPrimary.withAlpha(40)
              : WatchCartConstants.primaryColor.withAlpha(30),
          highlightColor: emphasize
              ? theme.colorScheme.onPrimary.withAlpha(24)
              : WatchCartConstants.primaryColor.withAlpha(15),
          child: Container(
            width: double.infinity,
            height: 60.0,
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 24, color: highlightColor),
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
                    color: emphasize
                        ? theme.colorScheme.onPrimary.withAlpha(36)
                        : highlightColor.withValues(alpha: 0.12),
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
