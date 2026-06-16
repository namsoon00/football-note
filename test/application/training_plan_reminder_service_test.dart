import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/challenge_service.dart';
import 'package:football_note/application/settings_service.dart';
import 'package:football_note/application/training_plan_reminder_service.dart';
import 'package:football_note/domain/entities/challenge.dart';
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
            return true;
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

  test(
    'settings-driven reminder sync does not reload settings recursively',
    () async {
      final repository = _MemoryOptionRepository()
        ..seed('reminder_enabled', false);
      final settings = SettingsService(repository)..load();
      final reminderService = TrainingPlanReminderService(repository, settings);
      final syncs = <Future<void>>[];
      var notifications = 0;

      settings.addListener(() {
        notifications += 1;
        syncs.add(reminderService.syncSettingsDrivenReminders());
      });

      settings.load();
      await Future.wait(syncs);

      expect(notifications, 1);
    },
  );

  test('challenge reminders do not schedule per-round notifications', () async {
    final repository = _MemoryOptionRepository()
      ..seed('reminder_enabled', true)
      ..seed('reminder_time', '07:30')
      ..seed(TrainingPlanReminderService.challengeReminderIdsKey, <int>[1, 2]);
    final settings = SettingsService(repository)..load();
    final reminderService = TrainingPlanReminderService(repository, settings);
    final startDay = DateTime.now().add(const Duration(days: 2));
    final template = defaultChallengeTemplates.first;
    final run = ChallengeRun(
      id: 'challenge-run-1',
      templateId: template.id,
      startedAt: DateTime(startDay.year, startDay.month, startDay.day, 9),
    );
    final progress = ChallengeProgress(
      run: run,
      template: template,
      rounds: template.rounds
          .map(
            (round) => ChallengeRoundProgress(
              round: round,
              date: run.dayForRound(round.number),
              trainingMinutes: 0,
              jumpRopeMinutes: 0,
              liftingMinutes: 0,
              riceBowls: 0,
            ),
          )
          .toList(growable: false),
    );

    await reminderService.syncChallengeReminders(progress);

    final ids = repository.getValue<List>(
      TrainingPlanReminderService.challengeReminderIdsKey,
    );
    expect(ids, isEmpty);
  });

  test(
    'challenge reminder sync clears stored ids when there is no active run',
    () async {
      final repository = _MemoryOptionRepository()
        ..seed('reminder_enabled', true)
        ..seed(TrainingPlanReminderService.challengeReminderIdsKey, <int>[
          1,
          2,
        ]);
      final settings = SettingsService(repository)..load();
      final reminderService = TrainingPlanReminderService(repository, settings);

      await reminderService.syncChallengeReminders(null);

      expect(
        repository.getValue<List>(
          TrainingPlanReminderService.challengeReminderIdsKey,
        ),
        isEmpty,
      );
    },
  );
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
          .map((item) => int.tryParse(item.toString()) ?? 0)
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
