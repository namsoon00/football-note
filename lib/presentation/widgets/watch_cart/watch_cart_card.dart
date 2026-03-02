import 'package:flutter/material.dart';

class WatchCartCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const WatchCartCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? scheme.surfaceContainerHighest
            : scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: scheme.outline.withAlpha(150),
        ),
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x0F111827),
                  blurRadius: 14,
                  offset: Offset(0, 4),
                ),
              ],
      ),
      child: child,
    );
  }
}
