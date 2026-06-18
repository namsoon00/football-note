import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

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
  }) : assert(
          onBoardList == null || boardListTitle != null,
          'boardListTitle is required when onBoardList is provided.',
        );

  @override
  Widget build(BuildContext context) {
    final hasBoardButton = onBoardList != null;
    final hasSummaryButton =
        (actionLabel ?? '').trim().isNotEmpty && badgeCount != null;
    return Row(
      children: [
        _OptionButton(icon: Icons.search, onTap: onSearch),
        const SizedBox(width: AppSpacing.sm),
        _OptionButton(
          icon: Icons.tune,
          onTap: onFilter,
          isActive: filterActive,
        ),
        if (hasSummaryButton) ...[
          const SizedBox(width: AppSpacing.sm),
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
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _LabeledCountButton(
              onTap: onBoardList!,
              semanticLabel: boardListLabel,
              label: boardListTitle!,
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
    final scheme = theme.colorScheme;
    final brightness = theme.brightness;
    final borderColor =
        isActive ? scheme.primary : AppSurfaces.borderColor(scheme, brightness);
    final backgroundColor = isActive
        ? scheme.primary.withValues(alpha: 0.08)
        : AppSurfaces.cardColor(scheme, brightness);
    return Material(
      color: backgroundColor,
      borderRadius: AppRadius.control,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.control,
        splashColor: scheme.primary.withAlpha(30),
        highlightColor: scheme.primary.withAlpha(15),
        child: Container(
          width: AppSizes.iconControl,
          height: AppSizes.iconControl,
          decoration: BoxDecoration(
            borderRadius: AppRadius.control,
            border: Border.all(color: borderColor),
            boxShadow: isActive ? null : AppShadows.surface(brightness),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: Icon(
                  icon,
                  color: isActive ? scheme.primary : scheme.onSurface,
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
                      color: scheme.primary,
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
    final scheme = theme.colorScheme;
    final brightness = theme.brightness;
    final emphasize = icon != null && onTap != null;
    final highlightColor = emphasize ? scheme.onPrimary : scheme.onSurface;
    final borderColor = emphasize
        ? scheme.primary
        : AppSurfaces.borderColor(scheme, brightness);
    final backgroundColor =
        emphasize ? scheme.primary : AppSurfaces.cardColor(scheme, brightness);
    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      child: Material(
        color: backgroundColor,
        borderRadius: AppRadius.control,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.control,
          splashColor: emphasize
              ? scheme.onPrimary.withAlpha(40)
              : scheme.primary.withAlpha(30),
          highlightColor: emphasize
              ? scheme.onPrimary.withAlpha(24)
              : scheme.primary.withAlpha(15),
          child: Container(
            width: double.infinity,
            height: AppSizes.iconControl,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            decoration: BoxDecoration(
              borderRadius: AppRadius.control,
              border: Border.all(color: borderColor),
              boxShadow: emphasize ? null : AppShadows.surface(brightness),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 24, color: highlightColor),
                        const SizedBox(width: AppSpacing.xs),
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
