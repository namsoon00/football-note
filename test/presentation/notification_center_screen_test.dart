import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/settings_service.dart';
import 'package:football_note/application/weather_reminder_service.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/notification_center_screen.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const timezoneChannel = MethodChannel('flutter_timezone');
  const notificationsChannel = MethodChannel(
    'dexterous.com/flutter/local_notifications',
  );
  const badgeChannel = MethodChannel('football_note/app_badge');

  setUp(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(timezoneChannel, (
      call,
    ) async {
      if (call.method == 'getLocalTimezone') return 'Asia/Seoul';
      return <String>[];
    });
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      notificationsChannel,
      (call) async {
        switch (call.method) {
          case 'initialize':
          case 'requestNotificationsPermission':
          case 'requestExactAlarmsPermission':
          case 'areNotificationsEnabled':
          case 'cancel':
            return true;
          default:
            return null;
        }
      },
    );
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      badgeChannel,
      (call) async => null,
    );
  });

  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      timezoneChannel,
      null,
    );
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      notificationsChannel,
      null,
    );
    binding.defaultBinaryMessenger.setMockMethodCallHandler(badgeChannel, null);
  });

  testWidgets('new notification is visible from collapsed category header', (
    WidgetTester tester,
  ) async {
    final repository = _MemoryOptionRepository()
      ..seed(WeatherReminderService.messageLogKey, [
        {
          'id': 'weather-new',
          'payload': 'taeonote://notifications/weather?action=today',
          'createdAt': '2026-06-28T07:00:00.000',
          'scheduledAt': '2026-06-28T07:30:00.000',
          'title': '오늘 날씨',
          'body': '비 예보를 확인해 주세요.',
        },
        {
          'id': 'weather-read',
          'payload': 'taeonote://notifications/weather?action=today',
          'createdAt': '2026-06-27T07:00:00.000',
          'scheduledAt': '2026-06-27T07:30:00.000',
          'title': '어제 날씨',
          'body': '이미 확인한 알림입니다.',
        },
      ])
      ..seed(WeatherReminderService.messageReadIdsKey, ['weather-read']);
    final settings = SettingsService(repository)..load();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: NotificationCenterScreen(
          optionRepository: repository,
          settingsService: settings,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('NEW'), findsWidgets);
    final highlightedTitle = tester.widget<Text>(
      find.byKey(
        const ValueKey<String>('notification-section-highlight-weather'),
      ),
    );
    expect(highlightedTitle.data, '오늘 날씨');
    expect(find.text('비 예보를 확인해 주세요.'), findsWidgets);
    expect(
      repository.getValue<List>(WeatherReminderService.messageReadIdsKey),
      contains('weather-new'),
    );
  });
}

class _MemoryOptionRepository implements OptionRepository {
  final Map<String, dynamic> _values = {};

  void seed(String key, dynamic value) {
    _values[key] = value;
  }

  @override
  List<String> getOptions(String key, List<String> defaults) {
    final value = _values[key];
    if (value is List) {
      return value.map((item) => item.toString()).toList(growable: false);
    }
    return defaults;
  }

  @override
  List<int> getIntOptions(String key, List<int> defaults) {
    final value = _values[key];
    if (value is List) {
      return value
          .map((item) => item is num ? item.toInt() : int.tryParse('$item'))
          .whereType<int>()
          .toList(growable: false);
    }
    return defaults;
  }

  @override
  T? getValue<T>(String key) {
    final value = _values[key];
    if (value is T) return value;
    return null;
  }

  @override
  Future<void> saveOptions(String key, List<dynamic> options) async {
    _values[key] = options;
  }

  @override
  Future<void> setValue(String key, dynamic value) async {
    _values[key] = value;
  }
}
