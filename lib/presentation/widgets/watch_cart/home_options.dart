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
  final int badgeCount;

  const WatchCartHomeOptions({
    super.key,
    required this.onAdd,
    required this.actionLabel,
    required this.badgeCount,
    this.onBoardList,
    this.boardListLabel,
    this.boardListTitle,
    this.onFilter,
    this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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
        if (onBoardList != null) ...[
          _OptionButton(
            icon: Icons.developer_board_outlined,
            onTap: onBoardList,
            semanticLabel: boardListLabel,
            title: boardListTitle,
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
  final String? semanticLabel;
  final String? title;

  const _OptionButton({
    required this.icon,
    this.onTap,
    this.semanticLabel,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
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
            width: title == null ? 60.0 : 84.0,
            height: 60.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: const Color.fromRGBO(230, 230, 230, 1)),
            ),
            child: title == null
                ? Icon(icon, color: Theme.of(context).colorScheme.onSurface)
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size: 19,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        title!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
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
