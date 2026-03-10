import 'package:flutter/material.dart';
import 'constants.dart';

class WatchCartHomeOptions extends StatelessWidget {
  final VoidCallback onAdd;
  final VoidCallback? onBoardList;
  final VoidCallback? onFilter;
  final VoidCallback? onSearch;
  final String actionLabel;
  final String? boardListLabel;
  final String? boardListTitle;
  final int? boardBadgeCount;
  final int badgeCount;

  const WatchCartHomeOptions({
    super.key,
    required this.onAdd,
    required this.actionLabel,
    required this.badgeCount,
    this.onBoardList,
    this.boardListLabel,
    this.boardListTitle,
    this.boardBadgeCount,
    this.onFilter,
    this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasBoardButton = onBoardList != null;
    final actionColor = theme.colorScheme.primary;
    final actionBorder = isDark
        ? theme.colorScheme.primary.withValues(alpha: 0.58)
        : const Color.fromRGBO(230, 230, 230, 1);
    return Row(
      children: [
        _OptionButton(icon: Icons.search, onTap: onSearch),
        const SizedBox(width: 12),
        _OptionButton(icon: Icons.tune, onTap: onFilter),
        const SizedBox(width: 12),
        if (hasBoardButton) ...[
          Expanded(
            child: _LabeledCountButton(
              onTap: onBoardList!,
              semanticLabel: boardListLabel,
              label: boardListTitle ?? 'Boards',
              count: boardBadgeCount ?? 0,
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Material(
            color: actionColor,
            borderRadius: BorderRadius.circular(8.0),
            child: InkWell(
              onTap: onAdd,
              borderRadius: BorderRadius.circular(8.0),
              splashColor: Colors.white.withAlpha(40),
              highlightColor: Colors.white.withAlpha(20),
              child: Container(
                height: 60.0,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: actionBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      actionLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14.0,
                      ),
                    ),
                    Container(
                      width: 30.0,
                      height: 30.0,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          badgeCount.toString(),
                          style: TextStyle(
                            color: actionColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
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
  final VoidCallback onTap;
  final String? semanticLabel;
  final String label;
  final int count;

  const _LabeledCountButton({
    required this.onTap,
    required this.label,
    required this.count,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: semanticLabel,
      button: true,
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
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  width: 26.0,
                  height: 26.0,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      count.toString(),
                      style: theme.textTheme.labelSmall?.copyWith(
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
