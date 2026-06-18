import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final brightness = theme.brightness;
    return Container(
      padding: padding,
      decoration: AppSurfaces.cardDecoration(scheme, brightness),
      child: child,
    );
  }
}
