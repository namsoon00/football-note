import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/locale_service.dart';
import 'package:football_note/domain/repositories/option_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('load follows system locale when no explicit locale is stored', () {
    final repository = _MemoryOptionRepository();
    final service = LocaleService(repository)..load();

    expect(service.locale, isNull);
  });

  test('load restores stored supported locale', () {
    final repository = _MemoryOptionRepository()
      ..values['locale'] = <String>['ja'];
    final service = LocaleService(repository)..load();

    expect(service.locale, const Locale('ja'));
  });

  test('setLocale null clears explicit locale selection', () async {
    final repository = _MemoryOptionRepository();
    final service = LocaleService(repository);

    await service.setLocale(const Locale('ko', 'KR'));
    expect(repository.values['locale'], <String>['ko']);

    await service.setLocale(null);
    expect(repository.values['locale'], isEmpty);
  });
}

class _MemoryOptionRepository implements OptionRepository {
  final Map<String, Object?> values = <String, Object?>{};

  @override
  List<int> getIntOptions(String key, List<int> defaults) =>
      switch (values[key]) {
        final List<dynamic> value => value.cast<int>(),
        _ => defaults,
      };

  @override
  List<String> getOptions(String key, List<String> defaults) =>
      switch (values[key]) {
        final List<dynamic> value => value.cast<String>(),
        _ => defaults,
      };

  @override
  T? getValue<T>(String key) => values[key] as T?;

  @override
  Future<void> saveOptions(String key, List<dynamic> options) async {
    values[key] = List<dynamic>.from(options);
  }

  @override
  Future<void> setValue(String key, dynamic value) async {
    values[key] = <dynamic>[value];
  }
}
