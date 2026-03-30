import '../domain/entities/meal_entry.dart';
import '../domain/entities/training_entry.dart';

class MealCoachingService {
  const MealCoachingService();

  static const List<double> riceBowlOptions = <double>[
    0,
    0.5,
    1,
    1.5,
    2,
    2.5,
    3,
  ];

  MealStatus statusForEntry(TrainingEntry entry) => MealStatus.fromEntry(entry);

  MealStatus statusForMealEntry(MealEntry entry) =>
      MealStatus.fromMealEntry(entry);

  int xpValueForEntry(TrainingEntry entry) {
    final status = MealStatus.fromEntry(entry);
    return xpValueForStatus(status);
  }

  int xpValueForMealEntry(MealEntry entry) {
    return xpValueForStatus(MealStatus.fromMealEntry(entry));
  }

  int xpValueForStatus(MealStatus status) {
    if (status.completedMeals >= 3) return 15;
    if (status.completedMeals >= 2) return 5;
    return 0;
  }

  String xpReasonForEntry(TrainingEntry entry) {
    final status = MealStatus.fromEntry(entry);
    return xpReasonForStatus(status);
  }

  String xpReasonForMealEntry(MealEntry entry) {
    return xpReasonForStatus(MealStatus.fromMealEntry(entry));
  }

  String xpReasonForStatus(MealStatus status) {
    if (status.completedMeals >= 3) return 'meal_full_day';
    if (status.completedMeals >= 2) return 'meal_two_plus';
    return '';
  }
}

class MealStatus {
  final bool breakfastDone;
  final double breakfastRiceBowls;
  final bool lunchDone;
  final double lunchRiceBowls;
  final bool dinnerDone;
  final double dinnerRiceBowls;

  const MealStatus({
    required this.breakfastDone,
    required this.breakfastRiceBowls,
    required this.lunchDone,
    required this.lunchRiceBowls,
    required this.dinnerDone,
    required this.dinnerRiceBowls,
  });

  factory MealStatus.fromEntry(TrainingEntry entry) {
    return MealStatus(
      breakfastDone: entry.breakfastDone,
      breakfastRiceBowls: entry.breakfastRiceBowls.toDouble(),
      lunchDone: entry.lunchDone,
      lunchRiceBowls: entry.lunchRiceBowls.toDouble(),
      dinnerDone: entry.dinnerDone,
      dinnerRiceBowls: entry.dinnerRiceBowls.toDouble(),
    );
  }

  factory MealStatus.fromMealEntry(MealEntry entry) {
    return MealStatus(
      breakfastDone: entry.breakfastRiceBowls > 0,
      breakfastRiceBowls: entry.breakfastRiceBowls,
      lunchDone: entry.lunchRiceBowls > 0,
      lunchRiceBowls: entry.lunchRiceBowls,
      dinnerDone: entry.dinnerRiceBowls > 0,
      dinnerRiceBowls: entry.dinnerRiceBowls,
    );
  }

  int get completedMeals =>
      <bool>[breakfastDone, lunchDone, dinnerDone].where((done) => done).length;

  double get totalRiceBowls =>
      _effectiveBowls(breakfastDone, breakfastRiceBowls) +
      _effectiveBowls(lunchDone, lunchRiceBowls) +
      _effectiveBowls(dinnerDone, dinnerRiceBowls);

  double get maxRiceBowls => <double>[
        _effectiveBowls(breakfastDone, breakfastRiceBowls),
        _effectiveBowls(lunchDone, lunchRiceBowls),
        _effectiveBowls(dinnerDone, dinnerRiceBowls),
      ].reduce((a, b) => a > b ? a : b);

  static double _effectiveBowls(bool done, double bowls) => done ? bowls : 0;
}
