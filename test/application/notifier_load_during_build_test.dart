import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/locale_service.dart';
import 'package:football_note/application/settings_service.dart';
import 'package:football_note/domain/repositories/option_repository.dart';

void main() {
  testWidgets('settings load defers root rebuild notifications during build', (
    tester,
  ) async {
    final repository = _MemoryOptionRepository();
    final settings = SettingsService(repository)..load();

    await tester.pumpWidget(
      AnimatedBuilder(
        animation: settings,
        builder: (context, _) => MaterialApp(
          home: _LoadSettingsOnMount(settings: settings),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('locale load defers root rebuild notifications during build', (
    tester,
  ) async {
    final repository = _MemoryOptionRepository();
    final locale = LocaleService(repository)..load();

    await tester.pumpWidget(
      AnimatedBuilder(
        animation: locale,
        builder: (context, _) => MaterialApp(
          home: _LoadLocaleOnMount(locale: locale),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}

class _LoadSettingsOnMount extends StatefulWidget {
  final SettingsService settings;

  const _LoadSettingsOnMount({required this.settings});

  @override
  State<_LoadSettingsOnMount> createState() => _LoadSettingsOnMountState();
}

class _LoadSettingsOnMountState extends State<_LoadSettingsOnMount> {
  @override
  void initState() {
    super.initState();
    widget.settings.load();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _LoadLocaleOnMount extends StatefulWidget {
  final LocaleService locale;

  const _LoadLocaleOnMount({required this.locale});

  @override
  State<_LoadLocaleOnMount> createState() => _LoadLocaleOnMountState();
}

class _LoadLocaleOnMountState extends State<_LoadLocaleOnMount> {
  @override
  void initState() {
    super.initState();
    widget.locale.load();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _MemoryOptionRepository implements OptionRepository {
  final Map<String, dynamic> _values = <String, dynamic>{};

  @override
  List<String> getOptions(String key, List<String> defaults) {
    final value = _values[key];
    if (value is List<String>) return value;
    return defaults;
  }

  @override
  List<int> getIntOptions(String key, List<int> defaults) {
    final value = _values[key];
    if (value is List<int>) return value;
    return defaults;
  }

  @override
  T? getValue<T>(String key) => _values[key] as T?;

  @override
  Future<void> saveOptions(String key, List<dynamic> options) async {
    _values[key] = List<dynamic>.from(options);
  }

  @override
  Future<void> setValue(String key, dynamic value) async {
    _values[key] = value;
  }
}
