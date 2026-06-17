import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/running_growth_service.dart';
import 'package:football_note/domain/repositories/option_repository.dart';

void main() {
  group('RunningGrowthService', () {
    test('stores sprint records and exposes the best time by distance',
        () async {
      final repository = _MemoryOptionRepository();
      final service = RunningGrowthService(repository);

      await service.saveRecord(
        distance: RunningSprintDistance.twentyMeters,
        seconds: 4.26,
        recordedAt: DateTime(2026, 6, 10, 8),
      );
      final snapshot = await service.saveRecord(
        distance: RunningSprintDistance.twentyMeters,
        seconds: 4.11,
        recordedAt: DateTime(2026, 6, 11, 8),
      );

      expect(snapshot.totalAttempts, 2);
      expect(
        snapshot.bestFor(RunningSprintDistance.twentyMeters)!.seconds,
        4.11,
      );
      expect(
        snapshot
            .latestDeltaFor(RunningSprintDistance.twentyMeters)!
            .secondsImproved,
        closeTo(0.15, 0.001),
      );
      expect(
        snapshot.earnedBadges,
        containsAll([
          RunningGrowthBadge.firstRun,
          RunningGrowthBadge.recordBreaker,
        ]),
      );
    });

    test('calculates streaks and all-distance badge', () async {
      final repository = _MemoryOptionRepository();
      final service = RunningGrowthService(repository);

      await service.saveRecord(
        distance: RunningSprintDistance.tenMeters,
        seconds: 2.05,
        recordedAt: DateTime(2026, 6, 15, 7),
      );
      await service.saveRecord(
        distance: RunningSprintDistance.twentyMeters,
        seconds: 4.22,
        recordedAt: DateTime(2026, 6, 16, 7),
      );
      await service.saveRecord(
        distance: RunningSprintDistance.thirtyMeters,
        seconds: 6.45,
        recordedAt: DateTime(2026, 6, 17, 7),
      );

      final snapshot = service.snapshot(now: DateTime(2026, 6, 17, 20));

      expect(snapshot.currentStreakDays, 3);
      expect(snapshot.completedDistanceCount, 3);
      expect(
        snapshot.earnedBadges,
        containsAll([
          RunningGrowthBadge.firstRun,
          RunningGrowthBadge.threeDaySpark,
          RunningGrowthBadge.allRounder,
        ]),
      );
    });

    test('ignores malformed stored values', () async {
      final repository = _MemoryOptionRepository();
      await repository.setValue(RunningGrowthService.storageKey, '{bad json');

      final service = RunningGrowthService(repository);

      expect(service.allRecords(), isEmpty);
    });
  });
}

class _MemoryOptionRepository implements OptionRepository {
  final Map<String, dynamic> _values = {};

  @override
  List<String> getOptions(String key, List<String> defaults) {
    final value = _values[key];
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    _values[key] = defaults;
    return List<String>.from(defaults);
  }

  @override
  List<int> getIntOptions(String key, List<int> defaults) {
    final value = _values[key];
    if (value is List) {
      return value.map((item) => int.tryParse(item.toString()) ?? 0).toList();
    }
    _values[key] = defaults;
    return List<int>.from(defaults);
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
