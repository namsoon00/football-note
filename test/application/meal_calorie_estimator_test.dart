import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/meal_calorie_estimator.dart';
import 'package:football_note/domain/entities/meal_entry.dart';

void main() {
  test('estimates calories from rice bowls and menu keywords', () {
    final estimate = MealCalorieEstimator.estimate(
      MealEntry(
        date: DateTime(2026, 7, 6),
        breakfastRiceBowls: 1,
        breakfastMenu: '계란 2개, 바나나',
        lunchMenu: '오트밀, 우유',
      ),
    );

    expect(estimate.breakfastKcal, 565);
    expect(estimate.lunchKcal, 350);
    expect(estimate.totalKcal, 915);
  });

  test('does not double count rice keywords when rice bowls are recorded', () {
    final estimate = MealCalorieEstimator.estimate(
      MealEntry(
        date: DateTime(2026, 7, 6),
        breakfastRiceBowls: 1,
        breakfastMenu: '현미밥, 달걀',
      ),
    );

    expect(estimate.breakfastKcal, 380);
  });

  test('uses menu rice keywords when rice bowls are not recorded', () {
    final estimate = MealCalorieEstimator.estimate(
      MealEntry(
        date: DateTime(2026, 7, 6),
        breakfastMenu: '현미밥, 달걀',
      ),
    );

    expect(estimate.breakfastKcal, 380);
  });

  test('adds selected main dish nutrition with portion multiplier', () {
    final estimate = MealCalorieEstimator.estimate(
      MealEntry(
        date: DateTime(2026, 7, 6),
        breakfastRiceBowls: 1,
        breakfastDishId: 'chickenBreast',
        breakfastDishPortion: 'large',
      ),
    );

    expect(estimate.breakfastKcal, 515);
    expect(estimate.totalCarbs, closeTo(65, 0.01));
    expect(estimate.totalProtein, closeTo(45.3, 0.01));
    expect(estimate.totalFat, closeTo(6.2, 0.01));
  });
}
