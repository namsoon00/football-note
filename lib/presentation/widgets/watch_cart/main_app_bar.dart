import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:football_note/gen/app_localizations.dart';

class WatchCartAppBar extends StatelessWidget {
  final VoidCallback? onLeadingTap;
  final IconData leadingIcon;
  final String? leadingTooltip;
  final VoidCallback? onNewsTap;
  final int newsBadgeCount;
  final VoidCallback? onQuizTap;
  final VoidCallback? onCoachTap;
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
    this.onCoachTap,
    required this.onProfileTap,
    this.onNotificationTap,
    this.notificationBadgeCount = 0,
    required this.onSettingsTap,
    this.profilePhotoSource = '',
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const actionConstraints = BoxConstraints(minWidth: 44, minHeight: 44);
    const actionPadding = EdgeInsets.all(6);
    final leadingButton = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(220),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outline.withAlpha(120)),
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
          borderRadius: BorderRadius.circular(10),
          child: leadingTooltip == null
              ? leadingButton
              : Tooltip(message: leadingTooltip!, child: leadingButton),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onNewsTap != null)
              IconButton(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.newspaper_outlined),
                    if (newsBadgeCount > 0)
                      Positioned(
                        right: -6,
                        top: -4,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53935),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Center(
                            child: Text(
                              newsBadgeCount > 99 ? '99+' : '$newsBadgeCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                tooltip: Localizations.localeOf(context).languageCode == 'ko'
                    ? '오늘의 소식'
                    : 'Today news',
                iconSize: 28,
                padding: actionPadding,
                constraints: actionConstraints,
                onPressed: onNewsTap,
              ),
            if (onQuizTap != null)
              IconButton(
                icon: const Icon(Icons.quiz_outlined),
                tooltip: Localizations.localeOf(context).languageCode == 'ko'
                    ? '퀴즈'
                    : 'Quiz',
                iconSize: 28,
                padding: actionPadding,
                constraints: actionConstraints,
                onPressed: onQuizTap,
              ),
            if (onCoachTap != null)
              IconButton(
                icon: const Icon(Icons.school_outlined),
                tooltip: AppLocalizations.of(context)!.headerEducationTooltip,
                iconSize: 28,
                padding: actionPadding,
                constraints: actionConstraints,
                onPressed: onCoachTap,
              ),
            IconButton(
              icon: _ProfileAppBarAvatar(photoSource: profilePhotoSource),
              iconSize: 30,
              padding: actionPadding,
              constraints: actionConstraints,
              onPressed: onProfileTap,
            ),
            if (onNotificationTap != null)
              IconButton(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_outlined),
                    if (notificationBadgeCount > 0)
                      Positioned(
                        right: -6,
                        top: -4,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53935),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Center(
                            child: Text(
                              notificationBadgeCount > 99
                                  ? '99+'
                                  : '$notificationBadgeCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                tooltip: Localizations.localeOf(context).languageCode == 'ko'
                    ? '알림'
                    : 'Notifications',
                iconSize: 30,
                padding: actionPadding,
                constraints: actionConstraints,
                onPressed: onNotificationTap,
              ),
            IconButton(
              icon: const Icon(Icons.settings),
              iconSize: 30,
              padding: actionPadding,
              constraints: actionConstraints,
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
      return const Icon(Icons.person_outline, size: 30);
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
