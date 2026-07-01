import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/club_schedule_service.dart';
import 'package:football_note/domain/entities/sport_definition.dart';
import 'package:football_note/domain/repositories/option_repository.dart';

void main() {
  group('ClubScheduleService', () {
    test('saves and loads club training schedule', () async {
      final repository = _MemoryOptionRepository();
      final service = ClubScheduleService(repository);

      await service.saveProfile(
        ClubScheduleProfile.empty().copyWith(
          clubName: '성남 U15',
          weekdaySchedules: const [
            ClubTrainingSchedule(
              weekday: DateTime.wednesday,
              enabled: true,
              startMinutes: 19 * 60,
              endMinutes: 21 * 60,
            ),
          ],
          homeUniformColorValue: 0xFFDC2626,
        ),
      );

      final profile = service.loadProfile();
      expect(profile.clubName, '성남 U15');
      expect(profile.weekdaySchedules, hasLength(7));
      expect(profile.scheduleForDate(DateTime(2026, 7, 1))?.enabled, isTrue);
      expect(
        profile.scheduleForDate(DateTime(2026, 7, 1))?.startMinutes,
        19 * 60,
      );
      expect(profile.homeUniformColorValue, 0xFFDC2626);
    });

    test('separates schedules by sport while preserving football key',
        () async {
      final repository = _MemoryOptionRepository();
      final football = ClubScheduleService(repository);
      final basketball = ClubScheduleService(
        repository,
        sportId: SportCatalog.basketballId,
      );

      await football.saveProfile(
        ClubScheduleProfile.empty().copyWith(clubName: 'Football Club'),
      );
      await basketball.saveProfile(
        ClubScheduleProfile.empty().copyWith(clubName: 'Basketball Club'),
      );

      expect(football.loadProfile().clubName, 'Football Club');
      expect(basketball.loadProfile().clubName, 'Basketball Club');
      expect(repository.values.containsKey(ClubScheduleService.storageKey),
          isTrue);
      expect(
        repository.values.containsKey(
          SportCatalog.optionKey(
            ClubScheduleService.storageKey,
            sportId: SportCatalog.basketballId,
          ),
        ),
        isTrue,
      );
    });

    test('normalizes incomplete stored data', () {
      final repository = _MemoryOptionRepository()
        ..seed(
          ClubScheduleService.storageKey,
          jsonEncode(
            <String, dynamic>{
              'clubName': '  Local FC  ',
              'homeUniformColorValue': 0x2563EB,
              'weekdaySchedules': [
                <String, dynamic>{
                  'weekday': 9,
                  'enabled': true,
                  'startMinutes': 24 * 60,
                  'endMinutes': 5,
                },
              ],
            },
          ),
        );

      final profile = ClubScheduleService(repository).loadProfile();

      expect(profile.clubName, 'Local FC');
      expect(profile.weekdaySchedules, hasLength(7));
      expect(profile.weekdaySchedules.first.weekday, DateTime.monday);
      expect(profile.weekdaySchedules.first.startMinutes, 23 * 60 + 59);
      expect(profile.weekdaySchedules.first.endMinutes, 23 * 60 + 59);
      expect(profile.homeUniformColorValue, 0xFF2563EB);
    });
  });
}

class _MemoryOptionRepository implements OptionRepository {
  final Map<String, dynamic> values = <String, dynamic>{};

  void seed(String key, dynamic value) {
    values[key] = value;
  }

  @override
  T? getValue<T>(String key) => values[key] as T?;

  @override
  List<int> getIntOptions(String key, List<int> defaults) {
    final value = values[key];
    if (value is List<int>) return List<int>.from(value);
    if (value is List) return value.whereType<int>().toList(growable: false);
    return List<int>.from(defaults);
  }

  @override
  List<String> getOptions(String key, List<String> defaults) {
    final value = values[key];
    if (value is List<String>) return List<String>.from(value);
    if (value is List) {
      return value.whereType<String>().toList(growable: false);
    }
    return List<String>.from(defaults);
  }

  @override
  Future<void> saveOptions(String key, List<dynamic> options) async {
    values[key] = List<dynamic>.from(options);
  }

  @override
  Future<void> setValue(String key, dynamic value) async {
    values[key] = value;
  }
}
