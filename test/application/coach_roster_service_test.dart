import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/coach_roster_service.dart';
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
