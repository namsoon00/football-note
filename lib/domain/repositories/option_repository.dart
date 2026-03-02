abstract class OptionRepository {
  List<String> getOptions(String key, List<String> defaults);
  List<int> getIntOptions(String key, List<int> defaults);
  T? getValue<T>(String key);
  Future<void> setValue(String key, dynamic value);
  Future<void> saveOptions(String key, List<dynamic> options);
}
