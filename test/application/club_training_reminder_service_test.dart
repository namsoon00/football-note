import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/club_schedule_service.dart';
import 'package:football_note/application/club_training_reminder_service.dart';
import 'package:football_note/application/settings_service.dart';
import 'package:football_note/domain/repositories/option_repository.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const timezoneChannel = MethodChannel('flutter_timezone');
  const notificationsChannel = MethodChannel(
    'dexterous.com/flutter/local_notifications',
  );

  late List<MethodCall> notificationCalls;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    notificationCalls = <MethodCall>[];
    binding.defaultBinaryMessenger.setMockMethodCallHandler(timezoneChannel, (
      call,
    ) async {
      if (call.method == 'getLocalTimezone') return 'Asia/Seoul';
      return <String>[];
    });
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      notificationsChannel,
      (call) async {
        notificationCalls.add(call);
        switch (call.method) {
          case 'initialize':
          case 'requestNotificationsPermission':
          case 'requestExactAlarmsPermission':
          case 'zonedSchedule':
          case 'cancel':
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

  test('schedules weekly club training reminders without color codes',
      () async {
    final repository = _MemoryOptionRepository()
      ..seed('reminder_enabled', true)
      ..seed('club_training_alert_enabled', true)
      ..seed('club_training_alert_minutes_before', 30);
    await ClubScheduleService(repository).saveProfile(
      ClubScheduleProfile.empty().copyWith(
        clubName: '성남 U15',
        weekdaySchedules: const [
          ClubTrainingSchedule(
            weekday: DateTime.wednesday,
            enabled: true,
            startMinutes: 19 * 60,
            endMinutes: 21 * 60,
            uniformColorValue: 0xFFDC2626,
          ),
        ],
      ),
    );
    final settings = SettingsService(repository)..load();
    final service = ClubTrainingReminderService(repository, settings);

    final count = await service.syncSettingsDrivenReminders();

    expect(count, 1);
    expect(
      notificationCalls.where((call) => call.method == 'zonedSchedule'),
      hasLength(1),
    );
    final ids = repository.getValue<List>(
      ClubTrainingReminderService.reminderIdsKey,
    );
    expect(ids, hasLength(1));
    final logs = repository.getValue<List>(
      ClubTrainingReminderService.messageLogKey,
    );
    expect(logs, hasLength(1));
    final row = (logs!.single as Map).cast<String, dynamic>();
    expect(row['title'], '성남 U15 훈련 준비');
    expect(row['body'], contains('30분 뒤 훈련'));
    expect(row['body'], contains('19:00-21:00'));
    expect(row['body'], isNot(contains('#DC2626')));
    expect(row['body'], isNot(contains('유니폼')));
    expect(row, isNot(contains('uniform')));
    expect(row['payload'], 'taeonote://club/training?weekday=3');
  });

  test('disabled club training alerts clear scheduled reminders and messages',
      () async {
    final repository = _MemoryOptionRepository()
      ..seed('reminder_enabled', true)
      ..seed('club_training_alert_enabled', false)
      ..seed(ClubTrainingReminderService.reminderIdsKey, <int>[123])
      ..seed(ClubTrainingReminderService.messageLogKey, [
        {'id': 'old', 'title': 'old'},
      ])
      ..seed(ClubTrainingReminderService.messageReadIdsKey, ['old']);
    final settings = SettingsService(repository)..load();
    final service = ClubTrainingReminderService(repository, settings);

    final count = await service.syncSettingsDrivenReminders();

    expect(count, 0);
    expect(
      notificationCalls.where((call) => call.method == 'cancel'),
      isNotEmpty,
    );
    expect(
      repository.getValue<List>(ClubTrainingReminderService.reminderIdsKey),
      isEmpty,
    );
    expect(
      repository.getValue<List>(ClubTrainingReminderService.messageLogKey),
      isEmpty,
    );
    expect(
      repository.getValue<List>(ClubTrainingReminderService.messageReadIdsKey),
      isEmpty,
    );
  });
}

class _MemoryOptionRepository implements OptionRepository {
  final Map<String, dynamic> _values = <String, dynamic>{};

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
