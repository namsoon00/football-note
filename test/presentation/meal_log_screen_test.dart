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
    Locale locale = const Locale('ko', 'KR'),
  }) async {
    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: TestAssetBundle(),
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: MealLogScreen(
            key: UniqueKey(),
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

  Future<void> expandDietDetails(WidgetTester tester, String mealKey) async {
    final expansion =
        find.byKey(PageStorageKey<String>('meal-$mealKey-diet-expansion'));
    await tester.scrollUntilVisible(
      expansion,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(
      expansion,
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

  testWidgets('meal coach summary appears below date and diet form folds', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final day = DateTime(2026, 3, 31);
    await mealLogService.save(
      MealEntry(date: day, breakfastRiceBowls: 1),
    );

    await pumpMealLogScreen(tester, initialDate: day);

    expect(find.text('식사 루틴을 더 채워야 합니다.'), findsOneWidget);
    expect(find.byKey(const ValueKey('meal-breakfast-menu')), findsNothing);
    expect(find.byType(Card), findsNothing);
    expect(find.byKey(const ValueKey('meal-log-date-section')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('meal-coach-summary-section')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('meal-coach-body')), findsNothing);
    expect(
        find.byKey(const ValueKey('meal-breakfast-section')), findsOneWidget);
    expect(find.byKey(const ValueKey('meal-lunch-section')), findsOneWidget);
    expect(find.byKey(const ValueKey('meal-dinner-section')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('meal-coach-expected-row')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('meal-coach-actual-row')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('meal-coach-calorie-row')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('meal-coach-xp-row')), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('meal-coach-details-false')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('meal-coach-body')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('meal-coach-expected-row')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('meal-coach-actual-row')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('meal-coach-calorie-row')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('meal-coach-xp-row')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('meal-coach-summary-divider-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('meal-coach-summary-divider-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('meal-coach-summary-divider-2')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('meal-log-date-card')), findsNothing);
    expect(find.byKey(const ValueKey('meal-coach-summary-card')), findsNothing);
    expect(find.byKey(const ValueKey('meal-breakfast-card')), findsNothing);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('meal-log-date-section')))
          .height,
      greaterThanOrEqualTo(48),
    );

    final dateBottom = tester
        .getBottomLeft(find.byKey(const ValueKey('meal-log-date-section')))
        .dy;
    final dateDividerTop = tester
        .getTopLeft(find.byKey(const ValueKey('meal-log-date-divider')))
        .dy;
    final coachTop = tester
        .getTopLeft(find.byKey(const ValueKey('meal-coach-summary-section')))
        .dy;
    final coachBreakfastDividerTop = tester
        .getTopLeft(
          find.byKey(const ValueKey('meal-section-divider-coach-breakfast')),
        )
        .dy;
    final breakfastTop = tester
        .getTopLeft(find.byKey(const ValueKey('meal-breakfast-section')))
        .dy;
    final breakfastLunchDividerTop = tester
        .getTopLeft(
          find.byKey(const ValueKey('meal-section-divider-breakfast-lunch')),
        )
        .dy;
    final lunchTop =
        tester.getTopLeft(find.byKey(const ValueKey('meal-lunch-section'))).dy;
    final lunchDinnerDividerTop = tester
        .getTopLeft(
          find.byKey(const ValueKey('meal-section-divider-lunch-dinner')),
        )
        .dy;
    final dinnerTop =
        tester.getTopLeft(find.byKey(const ValueKey('meal-dinner-section'))).dy;
    expect(dateDividerTop, greaterThan(dateBottom));
    expect(coachTop, greaterThan(dateDividerTop));
    expect(coachBreakfastDividerTop, greaterThan(coachTop));
    expect(breakfastTop, greaterThan(coachBreakfastDividerTop));
    expect(coachTop, lessThan(breakfastTop));
    expect(breakfastLunchDividerTop, greaterThan(breakfastTop));
    expect(lunchTop, greaterThan(breakfastLunchDividerTop));
    expect(lunchDinnerDividerTop, greaterThan(lunchTop));
    expect(dinnerTop, greaterThan(lunchDinnerDividerTop));

    await expandDietDetails(tester, 'breakfast');

    expect(find.byKey(const ValueKey('meal-breakfast-menu')), findsOneWidget);
  });

  testWidgets('meal log screen auto saves meal menu text', (tester) async {
    final day = DateTime(2026, 3, 31);

    await pumpMealLogScreen(tester, initialDate: day);
    await expandDietDetails(tester, 'breakfast');

    await tester.enterText(
      find.byKey(const ValueKey('meal-breakfast-menu')),
      '오트밀, 바나나, 우유',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.scrollUntilVisible(
      find.text('약 455 kcal'),
      -500,
      scrollable: find.byType(Scrollable).first,
    );

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
    await expandDietDetails(tester, 'breakfast');

    final dishButton = find.byKey(const ValueKey('meal-breakfast-dish'));
    await tester.ensureVisible(dishButton);
    await tester.pumpAndSettle();
    await tester.tap(dishButton);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('meal-main-dish-search')),
      '닭가슴살',
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('meal-main-dish-option-chickenBreast')),
    );
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

  testWidgets('meal log screen auto saves selected companion foods', (
    tester,
  ) async {
    final day = DateTime(2026, 3, 31);

    await pumpMealLogScreen(tester, initialDate: day);
    await expandDietDetails(tester, 'breakfast');

    final foodsButton = find.byKey(const ValueKey('meal-breakfast-foods'));
    await tester.ensureVisible(foodsButton);
    await tester.pumpAndSettle();
    await tester.tap(foodsButton);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('meal-food-search')),
      '바나나',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('meal-food-option-banana')));
    await tester.pump(const Duration(milliseconds: 400));

    var saved = mealLogService.entryForDay(day);
    expect(saved, isNotNull);
    expect(saved!.breakfastFoodIds, contains('banana'));

    await tester.enterText(
      find.byKey(const ValueKey('meal-food-search')),
      '우유',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('meal-food-option-milk')));
    await tester.pump(const Duration(milliseconds: 400));

    saved = mealLogService.entryForDay(day);
    expect(saved, isNotNull);
    expect(saved!.breakfastFoodIds, containsAll(<String>['banana', 'milk']));

    await tester.tap(find.byKey(const ValueKey('meal-food-sheet-done')));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('추가 음식 약 235 kcal · 단백질 8g'), findsOneWidget);
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

  testWidgets('meal log flat sections render in narrow localized layouts', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final locale in const <Locale>[
      Locale('en'),
      Locale('ko'),
      Locale('ja'),
    ]) {
      final day = DateTime(2026, 3, 31);
      await mealLogService.save(
        MealEntry(
          date: day,
          breakfastRiceBowls: 1,
          lunchRiceBowls: 1,
          dinnerRiceBowls: 1,
          breakfastDishId: 'chickenBreast',
          lunchFoodIds: const <String>['banana', 'milk'],
        ),
      );

      await pumpMealLogScreen(
        tester,
        initialDate: day,
        locale: locale,
      );

      expect(find.byType(Card), findsNothing);
      expect(
        find.byKey(const ValueKey('meal-log-date-section')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('meal-coach-summary-section')),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('meal-breakfast-section')),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.byKey(const ValueKey('meal-breakfast-section')),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('meal-lunch-section')),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(const ValueKey('meal-lunch-section')), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('meal-dinner-section')),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(const ValueKey('meal-dinner-section')), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
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
