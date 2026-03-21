import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';

import '../domain/repositories/option_repository.dart';

class TrainingPlanBadgeService {
  static const String plansStorageKey = 'training_plans_v1';

  final OptionRepository _options;

  TrainingPlanBadgeService(this._options);

  Future<void> syncFromStorage() async {
    if (!_supportsAppIconBadge) return;

    final raw = _options.getValue<String>(plansStorageKey);
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

  bool get _supportsAppIconBadge {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS;
  }
}
