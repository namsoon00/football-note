import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/presentation/screens/player_level_guide_screen.dart';

void main() {
  testWidgets('reward dialog keeps action buttons in one row in dark mode', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: ThemeMode.dark,
        locale: const Locale('ko', 'KR'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('ko', 'KR')],
        home: PlayerLevelGuideScreen(
          currentLevel: 2,
          optionRepository: _MemoryOptionRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('입력').first);
    await tester.pumpAndSettle();

    final cancelY = tester.getTopLeft(find.text('취소')).dy;
    final clearY = tester.getTopLeft(find.text('삭제')).dy;
    final saveY = tester.getTopLeft(find.text('저장')).dy;

    expect((cancelY - clearY).abs(), lessThan(1));
    expect((clearY - saveY).abs(), lessThan(1));
  });
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
    _values[key] = options;
  }

  @override
  Future<void> setValue(String key, dynamic value) async {
    _values[key] = value;
  }
}
