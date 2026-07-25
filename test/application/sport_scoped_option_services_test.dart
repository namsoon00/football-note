import 'dart:convert';

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

    test('migrates a single tactic board into the tactic book', () {
      final repository = _MemoryOptionRepository();
      final player = ManagedTeamPlayer.create(
        name: 'Kim',
        now: DateTime(2026, 7, 1),
      );
      final placement = ManagedPlayerPlacement.create(
        playerId: player.id,
        x: 0.42,
        y: 0.58,
      );
      final line = ManagedTacticLine.create(
        type: ManagedTacticLine.typePress,
        startX: 0.2,
        startY: 0.3,
        endX: 0.7,
        endY: 0.4,
        now: DateTime(2026, 7, 1, 9),
      );
      repository.seed(
        TeamManagementService.storageKey,
        jsonEncode([
          <String, Object?>{
            'id': 'team:legacy',
            'name': 'Legacy Team',
            'formation': ManagedTeam.defaultFormation,
            'strategy': '',
            'players': [player.toMap()],
            'lineup': <String, String>{},
            'playerPlacements': <String, Object?>{
              player.id: placement.toMap(),
            },
            'tacticLines': [line.toMap()],
            'createdAt': DateTime(2026, 7, 1).toIso8601String(),
            'updatedAt': DateTime(2026, 7, 1).toIso8601String(),
          },
        ]),
      );

      final team = TeamManagementService(repository).allTeams().single;

      expect(team.tacticBoards, hasLength(1));
      expect(team.tacticBoards.single.playerPlacements[player.id], isNotNull);
      expect(team.tacticBoards.single.tacticLines.single.type,
          ManagedTacticLine.typePress);
      expect(team.playerPlacements[player.id], isNotNull);
      expect(team.tacticLines, hasLength(1));
    });

    test('normalizes detailed player positions and preserves them in storage',
        () async {
      final repository = _MemoryOptionRepository();
      final legacyMidfielder = ManagedTeamPlayer.fromMap({
        'id': 'player:legacy-midfielder',
        'name': 'Legacy midfielder',
        'role': ManagedTeamPlayer.roleMidfielder,
      });
      final rightWinger = ManagedTeamPlayer.create(
        name: 'Right winger',
        role: ManagedTeamPlayer.roleForward,
        position: ManagedTeamPlayer.positionRightWinger,
        now: DateTime(2026, 7, 25),
      );

      expect(
        legacyMidfielder.effectivePosition,
        ManagedTeamPlayer.positionCentralMidfielder,
      );
      expect(
        rightWinger.effectivePosition,
        ManagedTeamPlayer.positionRightWinger,
      );
      expect(
        rightWinger.copyWith(role: ManagedTeamPlayer.roleDefender).position,
        ManagedTeamPlayer.positionCenterBack,
      );

      await TeamManagementService(repository).upsertTeam(
        ManagedTeam.create(
          name: 'Position Team',
          players: [legacyMidfielder, rightWinger],
        ),
      );

      final restored = TeamManagementService(repository).allTeams().single;
      expect(
        restored.players.first.effectivePosition,
        ManagedTeamPlayer.positionCentralMidfielder,
      );
      expect(
        restored.players.last.effectivePosition,
        ManagedTeamPlayer.positionRightWinger,
      );
    });

    test('preserves tactic board descriptions in storage', () async {
      final repository = _MemoryOptionRepository();
      final board = ManagedTacticBoard.create(
        title: 'Right switch press',
        description: 'Win the half space, then press the next pass.',
        now: DateTime(2026, 7, 25),
      );

      await TeamManagementService(repository).upsertTeam(
        ManagedTeam.create(
          name: 'Tactics Team',
          tacticBoards: [board],
          activeTacticBoardId: board.id,
        ),
      );

      final restored = TeamManagementService(repository).allTeams().single;
      expect(restored.tacticBoards.single.title, 'Right switch press');
      expect(
        restored.tacticBoards.single.description,
        'Win the half space, then press the next pass.',
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
