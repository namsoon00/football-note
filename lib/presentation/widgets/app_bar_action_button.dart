import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppBarActionButton extends StatelessWidget {
  final Widget icon;
  final String? tooltip;
  final VoidCallback? onPressed;
  final String? label;
  final int? badgeCount;
  final bool selected;
  final EdgeInsetsGeometry margin;
  final double maxLabelWidth;

  const AppBarActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.label,
    this.badgeCount,
    this.selected = false,
    this.margin = const EdgeInsetsDirectional.only(end: AppSpacing.xs),
    this.maxLabelWidth = 88,
  });

  AppBarActionButton.icon({
    super.key,
    required IconData icon,
    required this.onPressed,
    this.tooltip,
    this.badgeCount,
    this.selected = false,
    this.margin = const EdgeInsetsDirectional.only(end: AppSpacing.xs),
  })  : icon = Icon(icon),
        label = null,
        maxLabelWidth = 88;

  const AppBarActionButton.label({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.tooltip,
    this.badgeCount,
    this.selected = false,
    this.margin = const EdgeInsetsDirectional.only(end: AppSpacing.xs),
    this.maxLabelWidth = 88,
  });

  @override
  Widget build(BuildContext context) {
    final child = label == null
        ? IconButton(
            tooltip: tooltip,
            onPressed: onPressed,
            icon: _ActionIcon(icon: icon, badgeCount: badgeCount),
            style: AppBarActionStyle.iconButtonStyle(context, selected),
          )
        : TextButton.icon(
            onPressed: onPressed,
            icon: IconTheme.merge(
              data: const IconThemeData(size: 18),
              child: icon,
            ),
            label: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxLabelWidth),
              child: Text(
                label!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            style: AppBarActionStyle.textButtonStyle(context, selected),
          );
    final wrappedChild =
        tooltip == null ? child : Tooltip(message: tooltip!, child: child);
    return Padding(padding: margin, child: wrappedChild);
  }
}

class AppBarActionMenuButton<T> extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool enabled;
  final T? initialValue;
  final PopupMenuItemBuilder<T> itemBuilder;
  final PopupMenuItemSelected<T>? onSelected;
  final EdgeInsetsGeometry margin;

  const AppBarActionMenuButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.itemBuilder,
    this.enabled = true,
    this.initialValue,
    this.onSelected,
    this.margin = const EdgeInsetsDirectional.only(end: AppSpacing.xs),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: PopupMenuButton<T>(
        tooltip: tooltip,
        enabled: enabled,
        initialValue: initialValue,
        onSelected: onSelected,
        itemBuilder: itemBuilder,
        padding: EdgeInsets.zero,
        position: PopupMenuPosition.under,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.control),
        icon: _ActionShell(
          enabled: enabled,
          selected: false,
          child: Icon(icon),
        ),
      ),
    );
  }
}

class AppBarActionStyle {
  static ButtonStyle iconButtonStyle(BuildContext context, bool selected) {
    final colors = _colors(context, selected: selected);
    return IconButton.styleFrom(
      foregroundColor: colors.foreground,
      disabledForegroundColor: colors.disabledForeground,
      backgroundColor: colors.background,
      disabledBackgroundColor: colors.disabledBackground,
      fixedSize: const Size.square(AppSizes.appBarAction),
      minimumSize: const Size.square(AppSizes.appBarAction),
      maximumSize: const Size.square(AppSizes.appBarAction),
      padding: EdgeInsets.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: colors.border),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.small),
    ).copyWith(
      overlayColor: WidgetStateProperty.all(colors.overlay),
      splashFactory: InkRipple.splashFactory,
    );
  }

  static ButtonStyle textButtonStyle(BuildContext context, bool selected) {
    final colors = _colors(context, selected: selected);
    return TextButton.styleFrom(
      foregroundColor: colors.foreground,
      disabledForegroundColor: colors.disabledForeground,
      backgroundColor: colors.background,
      disabledBackgroundColor: colors.disabledBackground,
      minimumSize: const Size(0, AppSizes.appBarAction),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: colors.border),
      textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.0,
          ),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.small),
    ).copyWith(
      overlayColor: WidgetStateProperty.all(colors.overlay),
      splashFactory: InkRipple.splashFactory,
    );
  }

  static BoxDecoration shellDecoration(
    BuildContext context, {
    required bool selected,
    required bool enabled,
  }) {
    final colors = _colors(context, selected: selected);
    return BoxDecoration(
      color: enabled ? colors.background : colors.disabledBackground,
      borderRadius: AppRadius.small,
      border: Border.all(color: colors.border),
    );
  }

  static _ActionColors _colors(BuildContext context, {required bool selected}) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final background = selected
        ? scheme.primary.withValues(alpha: isDark ? 0.22 : 0.12)
        : AppSurfaces.subtleColor(scheme, theme.brightness);
    final border = selected
        ? scheme.primary.withValues(alpha: isDark ? 0.46 : 0.32)
        : AppSurfaces.borderColor(scheme, theme.brightness);
    final foreground = selected ? scheme.primary : scheme.onSurface;
    return _ActionColors(
      background: background,
      disabledBackground: background.withValues(alpha: isDark ? 0.22 : 0.46),
      border: border,
      foreground: foreground,
      disabledForeground: scheme.onSurface.withValues(alpha: 0.34),
      overlay: foreground.withValues(alpha: isDark ? 0.18 : 0.12),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final Widget icon;
  final int? badgeCount;

  const _ActionIcon({required this.icon, this.badgeCount});

  @override
  Widget build(BuildContext context) {
    final count = badgeCount ?? 0;
    if (count <= 0) {
      return IconTheme.merge(data: const IconThemeData(size: 20), child: icon);
    }
    final theme = Theme.of(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconTheme.merge(data: const IconThemeData(size: 20), child: icon),
        PositionedDirectional(
          end: -8,
          top: -9,
          child: Container(
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.error,
              borderRadius: AppRadius.full,
              border: Border.all(
                color: AppSurfaces.cardColor(
                  theme.colorScheme,
                  theme.brightness,
                ),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                count > 99 ? '99+' : '$count',
                style: TextStyle(
                  color: theme.colorScheme.onError,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionShell extends StatelessWidget {
  final Widget child;
  final bool enabled;
  final bool selected;

  const _ActionShell({
    required this.child,
    required this.enabled,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: AppSizes.appBarAction,
      height: AppSizes.appBarAction,
      decoration: AppBarActionStyle.shellDecoration(
        context,
        selected: selected,
        enabled: enabled,
      ),
      alignment: Alignment.center,
      child: IconTheme.merge(
        data: IconThemeData(
          size: 20,
          color: enabled
              ? scheme.onSurface
              : scheme.onSurface.withValues(alpha: 0.34),
        ),
        child: child,
      ),
    );
  }
}

class _ActionColors {
  final Color background;
  final Color disabledBackground;
  final Color border;
  final Color foreground;
  final Color disabledForeground;
  final Color overlay;

  const _ActionColors({
    required this.background,
    required this.disabledBackground,
    required this.border,
    required this.foreground,
    required this.disabledForeground,
    required this.overlay,
  });
}
