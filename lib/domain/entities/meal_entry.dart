import 'training_entry.dart';

class MealEntry {
  final DateTime date;
  final double breakfastRiceBowls;
  final double lunchRiceBowls;
  final double dinnerRiceBowls;
  final DateTime createdAt;

  MealEntry({
    required this.date,
    this.breakfastRiceBowls = 0,
    this.lunchRiceBowls = 0,
    this.dinnerRiceBowls = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get totalRiceBowls =>
      breakfastRiceBowls + lunchRiceBowls + dinnerRiceBowls;

  int get completedMeals => <double>[
        breakfastRiceBowls,
        lunchRiceBowls,
        dinnerRiceBowls,
      ].where((value) => value > 0).length;

  bool get hasRecords => totalRiceBowls > 0;

  MealEntry copyWith({
    DateTime? date,
    double? breakfastRiceBowls,
    double? lunchRiceBowls,
    double? dinnerRiceBowls,
    DateTime? createdAt,
  }) {
    return MealEntry(
      date: date ?? this.date,
      breakfastRiceBowls: breakfastRiceBowls ?? this.breakfastRiceBowls,
      lunchRiceBowls: lunchRiceBowls ?? this.lunchRiceBowls,
      dinnerRiceBowls: dinnerRiceBowls ?? this.dinnerRiceBowls,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'date': date.toIso8601String(),
      'breakfastRiceBowls': breakfastRiceBowls,
      'lunchRiceBowls': lunchRiceBowls,
      'dinnerRiceBowls': dinnerRiceBowls,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory MealEntry.fromMap(Map<String, dynamic> map) {
    return MealEntry(
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      breakfastRiceBowls: (map['breakfastRiceBowls'] as num?)?.toDouble() ?? 0,
      lunchRiceBowls: (map['lunchRiceBowls'] as num?)?.toDouble() ?? 0,
      dinnerRiceBowls: (map['dinnerRiceBowls'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  factory MealEntry.fromTrainingEntry(TrainingEntry entry) {
    return MealEntry(
      date: entry.date,
      breakfastRiceBowls:
          entry.breakfastDone ? entry.breakfastRiceBowls.toDouble() : 0,
      lunchRiceBowls: entry.lunchDone ? entry.lunchRiceBowls.toDouble() : 0,
      dinnerRiceBowls: entry.dinnerDone ? entry.dinnerRiceBowls.toDouble() : 0,
      createdAt: entry.createdAt,
    );
  }

  static int compareByRecentCreated(MealEntry a, MealEntry b) {
    final createdCompare = b.createdAt.compareTo(a.createdAt);
    if (createdCompare != 0) return createdCompare;
    return b.date.compareTo(a.date);
  }
}
