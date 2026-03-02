import 'package:hive/hive.dart';
import '../domain/repositories/option_repository.dart';

class HiveOptionRepository implements OptionRepository {
  final Box _box;

  HiveOptionRepository(this._box);

  @override
  List<String> getOptions(String key, List<String> defaults) {
    final stored = _box.get(key);
    if (stored is List) {
      return stored.map((item) => item.toString()).toList();
    }
    _box.put(key, defaults);
    return List<String>.from(defaults);
  }

  @override
  List<int> getIntOptions(String key, List<int> defaults) {
    final stored = _box.get(key);
    if (stored is List) {
      return stored.map((item) => int.tryParse(item.toString()) ?? 0).toList();
    }
    _box.put(key, defaults);
    return List<int>.from(defaults);
  }

  @override
  T? getValue<T>(String key) {
    final value = _box.get(key);
    if (value is T) {
      return value;
    }
    return null;
  }

  @override
  Future<void> setValue(String key, dynamic value) async {
    await _box.put(key, value);
  }

  @override
  Future<void> saveOptions(String key, List<dynamic> options) async {
    await _box.put(key, options);
  }
}
