import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/family_access_service.dart';
import 'package:football_note/application/meal_log_service.dart';
import 'package:football_note/application/settings_service.dart';
import 'package:football_note/domain/entities/meal_entry.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/meal_log_screen.dart';

import '../helpers/test_asset_bundle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MemoryOptionRepository optionRepository;
  late MealLogService mealLogService;
  late SettingsService settingsService;

  setUp(() {
    optionRepository = _MemoryOptionRepository();
    mealLogService = MealLogService(optionRepository);
    settingsService = SettingsService(optionRepository)..load();
  });

  tearDown(() async {
    await mealLogService.dispose();
  });

  Future<void> pumpMealLogScreen(
    WidgetTester tester, {
    required DateTime initialDate,
    MealEntry? initialEntry,
  }) async {
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
          home: MealLogScreen(
            mealLogService: mealLogService,
            optionRepository: optionRepository,
            settingsService: settingsService,
            initialDate: initialDate,
            initialEntry: initialEntry,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('meal log screen auto saves after rice bowl tap', (tester) async {
    final day = DateTime(2026, 3, 31);

    await pumpMealLogScreen(tester, initialDate: day);

    expect(find.text('저장'), findsNothing);

    final increment = find.byKey(const ValueKey('meal-breakfast-increment'));
    await tester.tap(increment);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(increment);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(increment);
    await tester.pump(const Duration(milliseconds: 400));

    final saved = mealLogService.entryForDay(day);
    expect(saved, isNotNull);
    expect(saved!.breakfastRiceBowls, 1.5);
    expect(saved.lunchRiceBowls, 0);
    expect(saved.dinnerRiceBowls, 0);
  });

  testWidgets('meal log screen auto saves meal menu text', (tester) async {
    final day = DateTime(2026, 3, 31);

    await pumpMealLogScreen(tester, initialDate: day);

    await tester.enterText(
      find.byKey(const ValueKey('meal-breakfast-menu')),
      '오트밀, 바나나, 우유',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(find.text('약 455 kcal'), findsOneWidget);

    final saved = mealLogService.entryForDay(day);
    expect(saved, isNotNull);
    expect(saved!.breakfastMenu, '오트밀, 바나나, 우유');
    expect(saved.breakfastRiceBowls, 0);
    expect(saved.completedMeals, 1);
    expect(saved.hasRecords, isTrue);
  });

  testWidgets('meal log screen auto saves selected main dish and portion', (
    tester,
  ) async {
    final day = DateTime(2026, 3, 31);

    await pumpMealLogScreen(tester, initialDate: day);

    await tester.tap(find.byKey(const ValueKey('meal-breakfast-dish')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('닭가슴살').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('많이'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('약 215 kcal · 단백질 40g'), findsOneWidget);

    final saved = mealLogService.entryForDay(day);
    expect(saved, isNotNull);
    expect(saved!.breakfastDishId, 'chickenBreast');
    expect(saved.breakfastDishPortion, 'large');
    expect(saved.completedMeals, 1);
    expect(saved.hasRecords, isTrue);
  });

  testWidgets('parent mode can view meal log without editing it', (
    tester,
  ) async {
    final day = DateTime(2026, 3, 31);
    await optionRepository.setValue(
      FamilyAccessService.currentRoleLocalKey,
      FamilyRole.parent.name,
    );
    await mealLogService.save(
      MealEntry(
        date: day,
        breakfastRiceBowls: 1.5,
        lunchRiceBowls: 1,
        dinnerRiceBowls: 0.5,
        breakfastMenu: '현미밥, 달걀, 사과',
      ),
    );

    await pumpMealLogScreen(tester, initialDate: day);

    expect(find.text('식사 기록은 읽기 전용이에요.'), findsNothing);
    expect(find.text('현미밥, 달걀, 사과'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('meal-breakfast-increment')),
      warnIfMissed: false,
    );
    await tester.pump();

    final saved = mealLogService.entryForDay(day);
    expect(saved, isNotNull);
    expect(saved!.breakfastRiceBowls, 1.5);
    expect(saved.breakfastMenu, '현미밥, 달걀, 사과');
  });
}

class _MemoryOptionRepository implements OptionRepository {
  final Map<String, dynamic> _values = <String, dynamic>{};

  @override
  List<String> getOptions(String key, List<String> defaults) {
    final value = _values[key];
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    final stored = List<String>.of(defaults);
    _values[key] = stored;
    return stored;
  }

  @override
  List<int> getIntOptions(String key, List<int> defaults) {
    final value = _values[key];
    if (value is List) {
      return value.map((item) => int.tryParse(item.toString()) ?? 0).toList();
    }
    final stored = List<int>.of(defaults);
    _values[key] = stored;
    return stored;
  }

  @override
  T? getValue<T>(String key) {
    final value = _values[key];
    return value is T ? value : null;
  }

  @override
  Future<void> saveOptions(String key, List<dynamic> options) async {
    _values[key] = List<dynamic>.of(options);
  }

  @override
  Future<void> setValue(String key, dynamic value) async {
    _values[key] = value;
  }
}
