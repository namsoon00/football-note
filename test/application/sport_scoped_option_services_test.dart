import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/match_competition_service.dart';
import 'package:football_note/application/running_growth_service.dart';
import 'package:football_note/application/settings_service.dart';
import 'package:football_note/application/team_management_service.dart';
import 'package:football_note/application/training_plan_reminder_service.dart';
import 'package:football_note/domain/entities/sport_definition.dart';
import 'package:football_note/domain/repositories/option_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('sport-scoped option services', () {
    test('separates managed teams by sport while preserving football key',
        () async {
      final repository = _MemoryOptionRepository();
      final football = TeamManagementService(repository);
      final basketball = TeamManagementService(
        repository,
        sportId: SportCatalog.basketballId,
      );

      await football.upsertTeam(
        ManagedTeam.create(name: 'Football Team'),
      );
      await basketball.upsertTeam(
        ManagedTeam.create(name: 'Basketball Team'),
      );

      expect(
        football.allTeams().map((team) => team.name),
        <String>['Football Team'],
      );
      expect(
        basketball.allTeams().map((team) => team.name),
        <String>['Basketball Team'],
      );
      expect(
        repository.values.containsKey(TeamManagementService.storageKey),
        isTrue,
      );
      expect(
        repository.values.containsKey(
          SportCatalog.optionKey(
            TeamManagementService.storageKey,
            sportId: SportCatalog.basketballId,
          ),
        ),
        isTrue,
      );
    });

    test('separates match competitions by sport', () async {
      final repository = _MemoryOptionRepository();
      final football = MatchCompetitionService(repository);
      final tennis = MatchCompetitionService(
        repository,
        sportId: SportCatalog.tennisId,
      );

      await football.upsertCompetition(
        MatchCompetitionRecord.create(
          kind: MatchCompetitionRecord.kindLeague,
          name: 'Weekend League',
          teams: const <String>['A'],
        ),
      );
      await tennis.upsertCompetition(
        MatchCompetitionRecord.create(
          kind: MatchCompetitionRecord.kindTournament,
          name: 'Club Ladder',
          teams: const <String>['Player A'],
        ),
      );

      expect(
        football.allCompetitions().map((record) => record.name),
        <String>['Weekend League'],
      );
      expect(
        tennis.allCompetitions().map((record) => record.name),
        <String>['Club Ladder'],
      );
    });

    test('separates running growth records by sport', () async {
      final repository = _MemoryOptionRepository();
      final football = RunningGrowthService(repository);
      final basketball = RunningGrowthService(
        repository,
        sportId: SportCatalog.basketballId,
      );

      await football.saveRecord(
        distance: RunningSprintDistance.twentyMeters,
        seconds: 4.2,
        recordedAt: DateTime(2026, 6, 1),
      );
      await basketball.saveRecord(
        distance: RunningSprintDistance.twentyMeters,
        seconds: 3.9,
        recordedAt: DateTime(2026, 6, 2),
      );

      expect(football.allRecords().single.seconds, 4.2);
      expect(basketball.allRecords().single.seconds, 3.9);
    });

    test('reads XP notification logs from the active sport key', () {
      final repository = _MemoryOptionRepository()
        ..seed(TrainingPlanReminderService.xpMessageLogKey, <Object?>[
          <String, Object?>{
            'id': 'football-xp',
            'createdAt': DateTime(2026, 6, 1).toIso8601String(),
          },
        ])
        ..seed(
          SportCatalog.optionKey(
            TrainingPlanReminderService.xpMessageLogKey,
            sportId: SportCatalog.basketballId,
          ),
          <Object?>[
            <String, Object?>{
              'id': 'basketball-xp',
              'createdAt': DateTime(2026, 6, 2).toIso8601String(),
            },
          ],
        );
      final settings = SettingsService(repository)..load();

      final basketball = TrainingPlanReminderService(
        repository,
        settings,
        sportId: SportCatalog.basketballId,
      );

      expect(
        basketball.loadXpMessageLogSync().map((item) => item['id']),
        <String>['basketball-xp'],
      );
    });
  });
}

class _MemoryOptionRepository implements OptionRepository {
  final Map<String, dynamic> values = <String, dynamic>{};

  void seed(String key, dynamic value) {
    values[key] = value;
  }

  @override
  List<String> getOptions(String key, List<String> defaults) {
    final value = values[key];
    if (value is List) {
      return value.map((item) => item.toString()).toList(growable: false);
    }
    values[key] = defaults;
    return List<String>.from(defaults);
  }

  @override
  List<int> getIntOptions(String key, List<int> defaults) {
    final value = values[key];
    if (value is List) {
      return value
          .map((item) => int.tryParse(item.toString()) ?? 0)
          .toList(growable: false);
    }
    values[key] = defaults;
    return List<int>.from(defaults);
  }

  @override
  T? getValue<T>(String key) {
    final value = values[key];
    return value is T ? value : null;
  }

  @override
  Future<void> saveOptions(String key, List<dynamic> options) async {
    values[key] = options;
  }

  @override
  Future<void> setValue(String key, dynamic value) async {
    values[key] = value;
  }
}
