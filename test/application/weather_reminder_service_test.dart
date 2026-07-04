import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/settings_service.dart';
import 'package:football_note/application/weather_reminder_service.dart';
import 'package:football_note/domain/repositories/option_repository.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const timezoneChannel = MethodChannel('flutter_timezone');
  const notificationsChannel = MethodChannel(
    'dexterous.com/flutter/local_notifications',
  );

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
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
          case 'zonedSchedule':
            return true;
          default:
            return null;
        }
      },
    );
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      timezoneChannel,
      null,
    );
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      notificationsChannel,
      null,
    );
  });

  test('daily weather reminder opens weather detail app link', () async {
    final repository = _MemoryOptionRepository()
      ..seed('reminder_enabled', true)
      ..seed('weather_alert_enabled', true)
      ..seed('weather_alert_time', '07:30');
    final settings = SettingsService(repository)..load();
    final service = WeatherReminderService(repository, settings);

    final count = await service.syncSettingsDrivenReminders();

    expect(count, 1);
    final logs =
        repository.getValue<List>(WeatherReminderService.messageLogKey);
    expect(logs, hasLength(1));
    final row = (logs!.single as Map).cast<String, dynamic>();
    expect(row['payload'], 'taeonote://weather/detail?action=today');
  });
}

class _MemoryOptionRepository implements OptionRepository {
  final Map<String, dynamic> _values = <String, dynamic>{};

  _MemoryOptionRepository seed(String key, dynamic value) {
    _values[key] = value;
    return this;
  }

  @override
  List<String> getOptions(String key, List<String> defaults) {
    final value = _values[key];
    if (value is List<String>) return List<String>.of(value);
    return List<String>.of(defaults);
  }

  @override
  List<int> getIntOptions(String key, List<int> defaults) {
    final value = _values[key];
    if (value is List<int>) return List<int>.of(value);
    return List<int>.of(defaults);
  }

  @override
  T? getValue<T>(String key) => _values[key] as T?;

  @override
  Future<void> saveOptions(String key, List<dynamic> options) async {
    _values[key] = options;
  }

  @override
  Future<void> setValue(String key, dynamic value) async {
    _values[key] = value;
  }
}
