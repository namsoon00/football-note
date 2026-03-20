import 'package:flutter/material.dart';

import 'tab_screen_title.dart';
import 'watch_cart/main_app_bar.dart';

class SharedTabHeader extends StatelessWidget {
  final VoidCallback? onLeadingTap;
  final IconData leadingIcon;
  final String? leadingTooltip;
  final VoidCallback? onNewsTap;
  final VoidCallback? onQuizTap;
  final VoidCallback? onCoachTap;
  final VoidCallback onProfileTap;
  final VoidCallback onSettingsTap;
  final String profilePhotoSource;
  final String? title;
  final Widget? titleTrailing;
  final EdgeInsetsGeometry padding;

  const SharedTabHeader({
    super.key,
    this.onLeadingTap,
    this.leadingIcon = Icons.menu,
    this.leadingTooltip,
    this.onNewsTap,
    this.onQuizTap,
    this.onCoachTap,
    required this.onProfileTap,
    required this.onSettingsTap,
    this.profilePhotoSource = '',
    this.title,
    this.titleTrailing,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WatchCartAppBar(
            onLeadingTap: onLeadingTap,
            leadingIcon: leadingIcon,
            leadingTooltip: leadingTooltip,
            onNewsTap: onNewsTap,
            onQuizTap: onQuizTap,
            onCoachTap: onCoachTap,
            onProfileTap: onProfileTap,
            onSettingsTap: onSettingsTap,
            profilePhotoSource: profilePhotoSource,
          ),
          if (title != null) ...[
            const SizedBox(height: 12),
            TabScreenTitle(title: title!, trailing: titleTrailing),
          ],
        ],
      ),
    );
  }
}
