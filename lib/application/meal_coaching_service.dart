import '../domain/entities/training_entry.dart';

class MealCoachingService {
  const MealCoachingService();

  static const List<int> riceBowlOptions = <int>[0, 1, 2, 3];

  MealStatus statusForEntry(TrainingEntry entry) => MealStatus.fromEntry(entry);

  int xpValueForEntry(TrainingEntry entry) {
    final status = MealStatus.fromEntry(entry);
    if (status.completedMeals >= 3) return 15;
    if (status.completedMeals >= 2) return 5;
    return 0;
  }

  String xpReasonForEntry(TrainingEntry entry) {
    final status = MealStatus.fromEntry(entry);
    if (status.completedMeals >= 3) return 'meal_full_day';
    if (status.completedMeals >= 2) return 'meal_two_plus';
    return '';
  }
}

class MealStatus {
  final bool breakfastDone;
  final int breakfastRiceBowls;
  final bool lunchDone;
  final int lunchRiceBowls;
  final bool dinnerDone;
  final int dinnerRiceBowls;

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
      breakfastRiceBowls: entry.breakfastRiceBowls,
      lunchDone: entry.lunchDone,
      lunchRiceBowls: entry.lunchRiceBowls,
      dinnerDone: entry.dinnerDone,
      dinnerRiceBowls: entry.dinnerRiceBowls,
    );
  }

  int get completedMeals =>
      <bool>[breakfastDone, lunchDone, dinnerDone].where((done) => done).length;

  int get totalRiceBowls =>
      _effectiveBowls(breakfastDone, breakfastRiceBowls) +
      _effectiveBowls(lunchDone, lunchRiceBowls) +
      _effectiveBowls(dinnerDone, dinnerRiceBowls);

  int get maxRiceBowls => <int>[
    _effectiveBowls(breakfastDone, breakfastRiceBowls),
    _effectiveBowls(lunchDone, lunchRiceBowls),
    _effectiveBowls(dinnerDone, dinnerRiceBowls),
  ].reduce((a, b) => a > b ? a : b);

  static int _effectiveBowls(bool done, int bowls) => done ? bowls : 0;
}
