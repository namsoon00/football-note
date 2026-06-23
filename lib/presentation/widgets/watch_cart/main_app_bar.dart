import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:football_note/gen/app_localizations.dart';

import '../../theme/app_theme.dart';
import '../app_bar_action_button.dart';

class WatchCartAppBar extends StatelessWidget {
  final VoidCallback? onLeadingTap;
  final IconData leadingIcon;
  final String? leadingTooltip;
  final VoidCallback? onNewsTap;
  final int newsBadgeCount;
  final VoidCallback? onQuizTap;
  final VoidCallback onProfileTap;
  final VoidCallback? onNotificationTap;
  final int notificationBadgeCount;
  final VoidCallback onSettingsTap;
  final String profilePhotoSource;

  const WatchCartAppBar({
    super.key,
    this.onLeadingTap,
    this.leadingIcon = Icons.menu,
    this.leadingTooltip,
    this.onNewsTap,
    this.newsBadgeCount = 0,
    this.onQuizTap,
    required this.onProfileTap,
    this.onNotificationTap,
    this.notificationBadgeCount = 0,
    required this.onSettingsTap,
    this.profilePhotoSource = '',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final leadingButton = Container(
      width: AppSizes.appBarAction,
      height: AppSizes.appBarAction,
      decoration: BoxDecoration(
        color: AppSurfaces.subtleColor(scheme, theme.brightness),
        borderRadius: AppRadius.small,
        border: Border.all(
          color: AppSurfaces.borderColor(scheme, theme.brightness),
        ),
      ),
      padding: const EdgeInsets.all(10),
      child: Center(
        child: leadingIcon == Icons.menu
            ? SvgPicture.asset(
                'assets/watch_cart/svg/menu.svg',
                width: 18,
                height: 18,
                colorFilter: ColorFilter.mode(
                  scheme.onSurface,
                  BlendMode.srcIn,
                ),
              )
            : Icon(leadingIcon, size: 22, color: scheme.onSurface),
      ),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          onTap: onLeadingTap,
          borderRadius: AppRadius.small,
          child: leadingTooltip == null
              ? leadingButton
              : Tooltip(message: leadingTooltip!, child: leadingButton),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onNewsTap != null)
              AppBarActionButton.icon(
                icon: Icons.newspaper_outlined,
                tooltip: l10n.tabNews,
                badgeCount: newsBadgeCount,
                onPressed: onNewsTap,
              ),
            if (onQuizTap != null)
              AppBarActionButton.icon(
                icon: Icons.quiz_outlined,
                tooltip: l10n.drawerQuiz,
                onPressed: onQuizTap,
              ),
            AppBarActionButton(
              icon: _ProfileAppBarAvatar(photoSource: profilePhotoSource),
              onPressed: onProfileTap,
            ),
            if (onNotificationTap != null)
              AppBarActionButton.icon(
                icon: Icons.notifications_outlined,
                tooltip: l10n.notifications,
                badgeCount: notificationBadgeCount,
                onPressed: onNotificationTap,
              ),
            AppBarActionButton.icon(
              icon: Icons.settings,
              tooltip: l10n.settings,
              onPressed: onSettingsTap,
            ),
          ],
        ),
      ],
    );
  }
}

class _ProfileAppBarAvatar extends StatelessWidget {
  final String photoSource;

  const _ProfileAppBarAvatar({required this.photoSource});

  @override
  Widget build(BuildContext context) {
    final source = photoSource.trim();
    final provider = _imageProvider(source);
    if (provider == null) {
      return const Icon(Icons.person_outline, size: 20);
    }
    return SizedBox(
      width: 30,
      height: 30,
      child: CircleAvatar(
        backgroundImage: provider,
        onBackgroundImageError: (_, __) {},
      ),
    );
  }

  ImageProvider? _imageProvider(String source) {
    if (source.isEmpty) return null;
    if (source.startsWith('data:image/')) {
      final comma = source.indexOf(',');
      if (comma > 0) {
        final b64 = source.substring(comma + 1);
        try {
          return MemoryImage(base64Decode(b64));
        } catch (_) {
          return null;
        }
      }
      return null;
    }
    if (source.startsWith('http://') ||
        source.startsWith('https://') ||
        source.startsWith('blob:')) {
      return NetworkImage(source);
    }
    if (kIsWeb) {
      return NetworkImage(source);
    }
    if (!kIsWeb) {
      final file = File(source);
      if (file.existsSync()) {
        return FileImage(file);
      }
    }
    return null;
  }
}
