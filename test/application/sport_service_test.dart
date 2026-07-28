import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/sport_service.dart';
import 'package:football_note/application/sport_state_controller.dart';
import 'package:football_note/domain/entities/sport_definition.dart';
import 'package:football_note/domain/repositories/option_repository.dart';

void main() {
  tearDown(
    () => SportService.setFixedSportForCurrentSession(null),
  );

  test('current sport defaults to football', () {
    final repository = _MemoryOptionRepository();
    final service = SportService(repository);

    expect(service.currentSportId(), SportCatalog.footballId);
    expect(service.currentSport().isFootball, isTrue);
  });

  test('unknown sport ids normalize back to football', () async {
    final repository = _MemoryOptionRepository();
    final service = SportService(repository);

    await service.setCurrentSportId('unknown_sport');

    expect(
      repository.getValue<String>(SportCatalog.currentSportOptionKey),
      SportCatalog.footballId,
    );
    expect(service.currentSportId(), SportCatalog.footballId);
  });

  test('current sport can be set to supported sports', () async {
    final repository = _MemoryOptionRepository();
    final service = SportService(repository);

    await service.setCurrentSportId(SportCatalog.baseballId);

    expect(service.currentSportId(), SportCatalog.baseballId);
    expect(
      repository.getValue<String>(SportCatalog.currentSportOptionKey),
      SportCatalog.baseballId,
    );
  });

  test('football keeps legacy option keys while other sports are scoped', () {
    expect(
      SportCatalog.optionKey('programs', sportId: SportCatalog.footballId),
      'programs',
    );
    expect(
      SportCatalog.optionKey('programs', sportId: SportCatalog.basketballId),
      'programs_basketball',
    );
    expect(
      SportCatalog.optionKey(
        'default_program',
        sportId: SportCatalog.tennisId,
      ),
      'default_program_tennis',
    );
  });

  test('sport controller writes normalized sport and notifies listeners',
      () async {
    final repository = _MemoryOptionRepository();
    final controller = SportStateController(repository);
    var notificationCount = 0;
    controller.addListener(() => notificationCount++);

    final changed = await controller.setCurrentSportId(
      SportCatalog.basketballId,
    );
    final unchanged = await controller.setCurrentSportId(
      SportCatalog.basketballId,
    );

    expect(changed, isTrue);
    expect(unchanged, isFalse);
    expect(controller.currentSportId, SportCatalog.basketballId);
    expect(
      repository.getValue<String>(SportCatalog.currentSportOptionKey),
      SportCatalog.basketballId,
    );
    expect(notificationCount, 1);
  });

  test('sport controller reloads storage changes from backup restore',
      () async {
    final repository = _MemoryOptionRepository();
    final controller = SportStateController(repository);
    var notificationCount = 0;
    controller.addListener(() => notificationCount++);

    await repository.setValue(
      SportCatalog.currentSportOptionKey,
      SportCatalog.tennisId,
    );
    final reloaded = controller.reloadFromStorage();
    final unchanged = controller.reloadFromStorage();

    expect(reloaded, isTrue);
    expect(unchanged, isFalse);
    expect(controller.currentSportId, SportCatalog.tennisId);
    expect(notificationCount, 1);
  });

  test('fixed sport controller keeps football active without changing storage',
      () async {
    final repository = _MemoryOptionRepository();
    await repository.setValue(
      SportCatalog.currentSportOptionKey,
      SportCatalog.basketballId,
    );
    final controller = SportStateController(
      repository,
      fixedSportId: SportCatalog.footballId,
    );

    final changed = await controller.setCurrentSportId(SportCatalog.tennisId);
    await repository.setValue(
      SportCatalog.currentSportOptionKey,
      SportCatalog.baseballId,
    );

    expect(controller.currentSportId, SportCatalog.footballId);
    expect(changed, isFalse);
    expect(controller.reloadFromStorage(), isFalse);
    expect(
      repository.getValue<String>(SportCatalog.currentSportOptionKey),
      SportCatalog.baseballId,
    );
  });

  test('session-fixed sport preserves the stored selection', () async {
    final repository = _MemoryOptionRepository();
    await repository.setValue(
      SportCatalog.currentSportOptionKey,
      SportCatalog.basketballId,
    );
    SportService.setFixedSportForCurrentSession(SportCatalog.footballId);
    final service = SportService(repository);

    await service.setCurrentSportId(SportCatalog.tennisId);

    expect(service.currentSportId(), SportCatalog.footballId);
    expect(
      repository.getValue<String>(SportCatalog.currentSportOptionKey),
      SportCatalog.basketballId,
    );
  });
}

class _MemoryOptionRepository implements OptionRepository {
  final Map<String, dynamic> _values = <String, dynamic>{};

  @override
  List<String> getOptions(String key, List<String> defaults) {
    final value = _values[key];
    if (value is List<String>) {
      return List<String>.of(value);
    }
    return List<String>.of(defaults);
  }

  @override
  List<int> getIntOptions(String key, List<int> defaults) {
    final value = _values[key];
    if (value is List<int>) {
      return List<int>.of(value);
    }
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
