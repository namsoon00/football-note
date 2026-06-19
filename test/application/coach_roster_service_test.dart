import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/coach_roster_service.dart';
import 'package:football_note/application/drive_connection_info.dart';
import 'package:football_note/application/family_access_service.dart';
import 'package:football_note/domain/repositories/option_repository.dart';

void main() {
  test('creates a fallback active player for coach mode', () async {
    final repository = _MemoryOptionRepository()
      ..seed(FamilyAccessService.currentRoleLocalKey, FamilyRole.coach.name)
      ..seed(FamilyAccessService.childNameKey, 'Minjun');
    final service = CoachRosterService(repository);

    final player = await service.ensureActivePlayer();
    final state = service.loadState();

    expect(player.id, CoachRosterService.defaultPlayerId);
    expect(player.displayName, 'Minjun');
    expect(state.activePlayerId, CoachRosterService.defaultPlayerId);
    expect(state.players.single.displayName, 'Minjun');
    expect(
      CoachRosterService.resolveScopedPlayerIdForOptions(repository),
      CoachRosterService.defaultPlayerId,
    );
  });

  test('adds players and switches active player', () async {
    final repository = _MemoryOptionRepository()
      ..seed(FamilyAccessService.currentRoleLocalKey, FamilyRole.coach.name);
    final service = CoachRosterService(repository);

    final first = await service.addPlayer(displayName: 'Minjun');
    final second = await service.addPlayer(displayName: 'Jisoo');
    await service.setActivePlayer(first.id);

    var state = service.loadState();
    expect(state.players.map((player) => player.displayName), [
      'Minjun',
      'Jisoo',
    ]);
    expect(state.activePlayerId, first.id);

    await service.setActivePlayer(second.id);
    state = service.loadState();
    expect(state.activePlayerId, second.id);
    expect(state.activePlayer?.displayName, 'Jisoo');
  });

  test('renames players and keeps at least one roster player', () async {
    final repository = _MemoryOptionRepository()
      ..seed(FamilyAccessService.currentRoleLocalKey, FamilyRole.coach.name);
    final service = CoachRosterService(repository);

    final first = await service.addPlayer(displayName: 'Minjun');
    final second = await service.addPlayer(displayName: 'Jisoo');
    final renamed = await service.renamePlayer(
      playerId: first.id,
      displayName: 'Minjun Kim',
    );

    expect(renamed?.displayName, 'Minjun Kim');
    expect(service.loadState().players.first.displayName, 'Minjun Kim');
    expect(await service.removePlayer(second.id), isTrue);
    expect(service.loadState().players.single.id, first.id);
    expect(await service.removePlayer(first.id), isFalse);
    expect(service.loadState().players.single.id, first.id);
  });

  test('stores Drive metadata on the active player', () async {
    final repository = _MemoryOptionRepository()
      ..seed(FamilyAccessService.currentRoleLocalKey, FamilyRole.coach.name);
    final service = CoachRosterService(repository);
    final player = await service.addPlayer(displayName: 'Minjun');
    await service.setActivePlayer(player.id);

    final updated = await service.updateActivePlayerDriveConnection(
      const DriveConnectionInfo(
        email: 'minjun@example.com',
        displayName: 'Minjun Drive',
        subjectId: 'subject-minjun',
      ),
    );
    final connection = service.activePlayerDriveConnection();

    expect(updated?.driveEmail, 'minjun@example.com');
    expect(updated?.driveLabel, 'Minjun Drive · minjun@example.com');
    expect(updated?.driveSubjectId, 'subject-minjun');
    expect(connection?.email, 'minjun@example.com');
    expect(connection?.displayName, 'Minjun Drive');
    expect(connection?.subjectId, 'subject-minjun');
  });

  test('does not scope data outside coach mode unless explicitly requested',
      () {
    final repository = _MemoryOptionRepository()
      ..seed(FamilyAccessService.currentRoleLocalKey, FamilyRole.parent.name);

    expect(CoachRosterService.resolveScopedPlayerIdForOptions(repository), '');
    expect(
      CoachRosterService.resolveScopedPlayerIdForOptions(
        repository,
        explicitPlayerId: 'player-a',
      ),
      'player-a',
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
