import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/repositories/option_repository.dart';
import 'league_fixture_reminder_service.dart';
import 'training_plan_reminder_service.dart';

class TrainingPlanBadgeService {
  static const MethodChannel _badgeChannel = MethodChannel(
    'football_note/app_badge',
  );

  final OptionRepository _options;

  TrainingPlanBadgeService(this._options);

  Future<void> syncFromStorage() async {
    if (!_supportsAppIconBadge) return;

    try {
      final xpLogs =
          _options.getValue<List>(
            TrainingPlanReminderService.xpMessageLogKey,
          ) ??
          const [];
      final xpReadRaw =
          _options.getValue<List>(
            TrainingPlanReminderService.xpMessageReadIdsKey,
          ) ??
          const [];
      final xpReadIds = xpReadRaw.map((e) => e.toString()).toSet();
      final xpUnread = xpLogs.whereType<Map>().where((item) {
        final id = item['id']?.toString() ?? '';
        if (id.isEmpty) return false;
        return !xpReadIds.contains(id);
      }).length;

      final fixtureLogs =
          _options.getValue<List>(
            LeagueFixtureReminderService.fixtureMessageLogKey,
          ) ??
          const [];
      final fixtureReadRaw =
          _options.getValue<List>(
            LeagueFixtureReminderService.fixtureMessageReadIdsKey,
          ) ??
          const [];
      final fixtureReadIds = fixtureReadRaw.map((e) => e.toString()).toSet();
      final fixtureUnread = fixtureLogs.whereType<Map>().where((item) {
        final id = item['id']?.toString() ?? '';
        if (id.isEmpty) return false;
        return !fixtureReadIds.contains(id);
      }).length;

      final count = xpUnread + fixtureUnread;

      if (count <= 0) {
        await _setBadgeCount(0);
      } else {
        await _setBadgeCount(count);
      }
    } catch (_) {
      // Fallback to legacy stored plans if unread data is unavailable.
      final raw = _options.getValue<String>(
        TrainingPlanReminderService.plansStorageKey,
      );
      if (raw == null || raw.trim().isEmpty) {
        await _setBadgeCount(0);
        return;
      }
      try {
        final decoded = jsonDecode(raw);
        if (decoded is! List) {
          await _setBadgeCount(0);
          return;
        }
        final today = DateTime.now();
        final todayOnly = DateTime(today.year, today.month, today.day);
        var count = 0;
        for (final item in decoded) {
          if (item is! Map) continue;
          final map = item.cast<String, dynamic>();
          final scheduled = DateTime.tryParse(
            map['scheduledAt']?.toString() ?? '',
          );
          if (scheduled == null) continue;
          final day = DateTime(scheduled.year, scheduled.month, scheduled.day);
          if (day.isBefore(todayOnly)) continue;
          count++;
        }
        if (count <= 0) {
          await _setBadgeCount(0);
        } else {
          await _setBadgeCount(count);
        }
      } catch (_) {
        await _setBadgeCount(0);
      }
    }
  }

  Future<void> clearBadge() async {
    if (!_supportsAppIconBadge) return;
    try {
      await _setBadgeCount(0);
    } catch (_) {
      // Ignore badge clearing failures.
    }
  }

  Future<void> _setBadgeCount(int count) async {
    if (!_supportsAppIconBadge) return;
    try {
      await _badgeChannel.invokeMethod<void>('setBadgeCount', {
        'count': count < 0 ? 0 : count,
      });
    } catch (_) {
      // Badge updates should never block the app flow.
    }
  }

  bool get _supportsAppIconBadge {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS;
  }
}
