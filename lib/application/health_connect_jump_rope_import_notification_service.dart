import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Locale;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:football_note/gen/app_localizations.dart';

import '../domain/repositories/option_repository.dart';
import 'notification_app_link.dart';
import 'settings_service.dart';

class HealthConnectJumpRopeImportNotification {
  final int count;
  final DateTime importedAt;
  final DateTime? firstSessionStart;

  const HealthConnectJumpRopeImportNotification({
    required this.count,
    required this.importedAt,
    this.firstSessionStart,
  });
}

abstract class HealthConnectJumpRopeImportNotifier {
  Future<bool> requestPermission();
  Future<String?> launchPayload();
  Future<void> showImported(
    HealthConnectJumpRopeImportNotification notification,
  );
}

class NoopHealthConnectJumpRopeImportNotifier
    implements HealthConnectJumpRopeImportNotifier {
  const NoopHealthConnectJumpRopeImportNotifier();

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<String?> launchPayload() async => null;

  @override
  Future<void> showImported(
    HealthConnectJumpRopeImportNotification notification,
  ) async {}
}

class HealthConnectJumpRopeImportNotificationService
    implements HealthConnectJumpRopeImportNotifier {
  static void Function(String? payload)? onNotificationPayloadTap;

  static const String _localeOptionKey = 'locale';
  static const String _androidChannelId = 'health_connect_jump_rope_imports';
  static final Int64List _vibrationPattern = Int64List.fromList(<int>[
    0,
    180,
    90,
    180,
  ]);

  final OptionRepository _options;
  final SettingsService _settings;
  final FlutterLocalNotificationsPlugin _plugin;

  bool _initialized = false;

  HealthConnectJumpRopeImportNotificationService({
    required OptionRepository optionRepository,
    required SettingsService settingsService,
    FlutterLocalNotificationsPlugin? plugin,
  })  : _options = optionRepository,
        _settings = settingsService,
        _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    if (_initialized) return;
    if (kIsWeb) {
      _initialized = true;
      return;
    }

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        onNotificationPayloadTap?.call(response.payload);
      },
    );

    final l10n = _localizations();
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(
      AndroidNotificationChannel(
        _androidChannelId,
        l10n.healthConnectImportNotificationChannelName,
        description: l10n.healthConnectImportNotificationChannelDescription,
        importance: Importance.high,
        enableVibration: _settings.reminderVibrationEnabled,
        vibrationPattern:
            _settings.reminderVibrationEnabled ? _vibrationPattern : null,
      ),
    );
    _initialized = true;
  }

  @override
  Future<bool> requestPermission() async {
    await initialize();
    if (kIsWeb) return true;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final androidImpl = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        await androidImpl?.requestNotificationsPermission();
        return await androidImpl?.areNotificationsEnabled() ?? true;
      case TargetPlatform.iOS:
        final iosImpl = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        await iosImpl?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        final permissions = await iosImpl?.checkPermissions();
        return permissions?.isEnabled ?? false;
      default:
        return true;
    }
  }

  Future<bool> _hasPermission() async {
    await initialize();
    if (kIsWeb) return true;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final androidImpl = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        return await androidImpl?.areNotificationsEnabled() ?? true;
      case TargetPlatform.iOS:
        final iosImpl = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        final permissions = await iosImpl?.checkPermissions();
        return permissions?.isEnabled ?? false;
      default:
        return true;
    }
  }

  @override
  Future<String?> launchPayload() async {
    await initialize();
    if (kIsWeb) return null;
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp != true) return null;
    return details?.notificationResponse?.payload;
  }

  @override
  Future<void> showImported(
    HealthConnectJumpRopeImportNotification notification,
  ) async {
    if (notification.count <= 0) return;
    await initialize();
    if (kIsWeb) return;
    if (!await _hasPermission()) return;

    final l10n = _localizations();
    final targetDay = notification.firstSessionStart ?? notification.importedAt;
    final id = _notificationIdForScope(
      'health_connect_jump_rope_import',
      '${notification.importedAt.microsecondsSinceEpoch}:${notification.count}',
    );
    try {
      await _plugin.show(
        id,
        l10n.healthConnectImportNotificationTitle,
        l10n.healthConnectImportNotificationBody(notification.count),
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannelId,
            l10n.healthConnectImportNotificationChannelName,
            channelDescription:
                l10n.healthConnectImportNotificationChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
            enableVibration: _settings.reminderVibrationEnabled,
            vibrationPattern:
                _settings.reminderVibrationEnabled ? _vibrationPattern : null,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: NotificationAppLink.calendarDay(date: targetDay),
      );
    } catch (_) {
      // Ignore immediate notification failures; the import itself already saved.
    }
  }

  AppLocalizations _localizations() {
    final languageCode = _options
        .getOptions(_localeOptionKey, const <String>[])
        .firstOrNull
        ?.trim()
        .toLowerCase();
    final locale = switch (languageCode) {
      'en' => const Locale('en'),
      'ja' => const Locale('ja'),
      _ => const Locale('ko'),
    };
    return lookupAppLocalizations(locale);
  }

  int _notificationIdForScope(String scope, String value) {
    var hash = 23;
    for (final code in '$scope:$value'.codeUnits) {
      hash = 41 * hash + code;
    }
    return hash.abs() % 2147483647;
  }
}
