import 'training_entry.dart';

class MealEntry {
  final DateTime date;
  final double breakfastRiceBowls;
  final double lunchRiceBowls;
  final double dinnerRiceBowls;
  final String breakfastMenu;
  final String lunchMenu;
  final String dinnerMenu;
  final DateTime createdAt;

  MealEntry({
    required this.date,
    this.breakfastRiceBowls = 0,
    this.lunchRiceBowls = 0,
    this.dinnerRiceBowls = 0,
    this.breakfastMenu = '',
    this.lunchMenu = '',
    this.dinnerMenu = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get totalRiceBowls =>
      breakfastRiceBowls + lunchRiceBowls + dinnerRiceBowls;

  bool get hasMealPlan =>
      breakfastMenu.trim().isNotEmpty ||
      lunchMenu.trim().isNotEmpty ||
      dinnerMenu.trim().isNotEmpty;

  int get completedMeals => <bool>[
        breakfastRiceBowls > 0 || breakfastMenu.trim().isNotEmpty,
        lunchRiceBowls > 0 || lunchMenu.trim().isNotEmpty,
        dinnerRiceBowls > 0 || dinnerMenu.trim().isNotEmpty,
      ].where((value) => value).length;

  bool get hasRecords => totalRiceBowls > 0 || hasMealPlan;

  MealEntry copyWith({
    DateTime? date,
    double? breakfastRiceBowls,
    double? lunchRiceBowls,
    double? dinnerRiceBowls,
    String? breakfastMenu,
    String? lunchMenu,
    String? dinnerMenu,
    DateTime? createdAt,
  }) {
    return MealEntry(
      date: date ?? this.date,
      breakfastRiceBowls: breakfastRiceBowls ?? this.breakfastRiceBowls,
      lunchRiceBowls: lunchRiceBowls ?? this.lunchRiceBowls,
      dinnerRiceBowls: dinnerRiceBowls ?? this.dinnerRiceBowls,
      breakfastMenu: breakfastMenu ?? this.breakfastMenu,
      lunchMenu: lunchMenu ?? this.lunchMenu,
      dinnerMenu: dinnerMenu ?? this.dinnerMenu,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'date': date.toIso8601String(),
      'breakfastRiceBowls': breakfastRiceBowls,
      'lunchRiceBowls': lunchRiceBowls,
      'dinnerRiceBowls': dinnerRiceBowls,
      'breakfastMenu': breakfastMenu,
      'lunchMenu': lunchMenu,
      'dinnerMenu': dinnerMenu,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory MealEntry.fromMap(Map<String, dynamic> map) {
    return MealEntry(
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      breakfastRiceBowls: (map['breakfastRiceBowls'] as num?)?.toDouble() ?? 0,
      lunchRiceBowls: (map['lunchRiceBowls'] as num?)?.toDouble() ?? 0,
      dinnerRiceBowls: (map['dinnerRiceBowls'] as num?)?.toDouble() ?? 0,
      breakfastMenu: _stringValue(map['breakfastMenu']),
      lunchMenu: _stringValue(map['lunchMenu']),
      dinnerMenu: _stringValue(map['dinnerMenu']),
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

  static String _stringValue(Object? value) => value?.toString() ?? '';

  static int compareByRecentCreated(MealEntry a, MealEntry b) {
    final createdCompare = b.createdAt.compareTo(a.createdAt);
    if (createdCompare != 0) return createdCompare;
    return b.date.compareTo(a.date);
  }
}
