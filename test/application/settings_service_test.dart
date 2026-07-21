import 'package:football_note/application/settings_service.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('sound effects are enabled by default', () {
    final settings = SettingsService(_MemoryOptionRepository())..load();

    expect(settings.soundEffectsEnabled, isTrue);
  });

  test('sound effects preference persists across service instances', () async {
    final repository = _MemoryOptionRepository();
    final settings = SettingsService(repository)..load();

    await settings.setSoundEffectsEnabled(false);

    expect(repository.getValue<bool>('sound_effects_enabled'), isFalse);
    expect(
      (SettingsService(repository)..load()).soundEffectsEnabled,
      isFalse,
    );
  });
}

class _MemoryOptionRepository implements OptionRepository {
  final Map<String, dynamic> _values = <String, dynamic>{};

  @override
  List<String> getOptions(String key, List<String> defaults) {
    return _values[key] as List<String>? ?? defaults;
  }

  @override
  List<int> getIntOptions(String key, List<int> defaults) {
    return _values[key] as List<int>? ?? defaults;
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
