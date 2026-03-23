import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';

import '../domain/repositories/option_repository.dart';
import 'training_plan_reminder_service.dart';

class TrainingPlanBadgeService {
  final OptionRepository _options;

  TrainingPlanBadgeService(this._options);

  Future<void> syncFromStorage() async {
    if (!_supportsAppIconBadge) return;

    try {
      final xpLogs = _options
              .getValue<List>(TrainingPlanReminderService.xpMessageLogKey) ??
          const [];
      final xpReadRaw = _options.getValue<List>(
            TrainingPlanReminderService.xpMessageReadIdsKey,
          ) ??
          const [];
      final xpReadIds = xpReadRaw.map((e) => e.toString()).toSet();
      final xpUnread = xpLogs.whereType<Map>().where((item) {
        final id = item['id']?.toString() ?? '';
        if (id.isEmpty) return false;
        return !xpReadIds.contains(id);
      }).length;

      final count = xpUnread;

      if (count <= 0) {
        await FlutterAppBadger.removeBadge();
      } else {
        await FlutterAppBadger.updateBadgeCount(count);
      }
    } catch (_) {
      // Fallback to legacy stored plans if unread data is unavailable.
      final raw = _options
          .getValue<String>(TrainingPlanReminderService.plansStorageKey);
      if (raw == null || raw.trim().isEmpty) {
        await FlutterAppBadger.removeBadge();
        return;
      }
      try {
        final decoded = jsonDecode(raw);
        if (decoded is! List) {
          await FlutterAppBadger.removeBadge();
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
          await FlutterAppBadger.removeBadge();
        } else {
          await FlutterAppBadger.updateBadgeCount(count);
        }
      } catch (_) {
        await FlutterAppBadger.removeBadge();
      }
    }
  }

  Future<void> clearBadge() async {
    if (!_supportsAppIconBadge) return;
    try {
      await FlutterAppBadger.removeBadge();
    } catch (_) {
      // Ignore badge clearing failures.
    }
  }

  bool get _supportsAppIconBadge {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS;
  }
}
