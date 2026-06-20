import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/benchmark_service.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/average_benchmark_screen.dart';

import '../helpers/test_asset_bundle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Average benchmark screen shows age benchmark table', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: TestAssetBundle(),
        child: MaterialApp(
          locale: const Locale('ko', 'KR'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('ko', 'KR')],
          home: AverageBenchmarkScreen(
            entries: const [],
            ageYears: 13,
            soccerYears: 2,
            benchmarkService: BenchmarkService(_MemoryOptionRepository()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('나이별 평균'), findsOneWidget);
    expect(find.text('키 평균'), findsOneWidget);
    expect(find.text('체중 평균'), findsOneWidget);
    expect(find.text('리프팅/세션'), findsOneWidget);
    expect(find.text('13세'), findsOneWidget);
    expect(find.text('현재'), findsOneWidget);
    expect(find.text('158.3cm'), findsOneWidget);
    expect(find.text('47.1kg'), findsOneWidget);
    expect(find.text('100회'), findsWidgets);
    expect(find.text('378분 · 5회'), findsWidgets);
  });
}

class _MemoryOptionRepository implements OptionRepository {
  final Map<String, dynamic> _values = <String, dynamic>{};

  @override
  T? getValue<T>(String key) => _values[key] as T?;

  @override
  List<int> getIntOptions(String key, List<int> defaults) {
    final value = _values[key];
    if (value is List<int>) return List<int>.from(value);
    if (value is List) return value.whereType<int>().toList(growable: false);
    return List<int>.from(defaults);
  }

  @override
  List<String> getOptions(String key, List<String> defaults) {
    final value = _values[key];
    if (value is List<String>) return List<String>.from(value);
    if (value is List) {
      return value.whereType<String>().toList(growable: false);
    }
    return List<String>.from(defaults);
  }

  @override
  Future<void> saveOptions(String key, List<dynamic> options) async {
    _values[key] = List<dynamic>.from(options);
  }

  @override
  Future<void> setValue(String key, dynamic value) async {
    _values[key] = value;
  }
}
