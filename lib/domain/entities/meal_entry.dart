import 'training_entry.dart';

class MealEntry {
  final DateTime date;
  final double breakfastRiceBowls;
  final double lunchRiceBowls;
  final double dinnerRiceBowls;
  final String breakfastMenu;
  final String lunchMenu;
  final String dinnerMenu;
  final String breakfastDishId;
  final String lunchDishId;
  final String dinnerDishId;
  final String breakfastDishPortion;
  final String lunchDishPortion;
  final String dinnerDishPortion;
  final DateTime createdAt;

  MealEntry({
    required this.date,
    this.breakfastRiceBowls = 0,
    this.lunchRiceBowls = 0,
    this.dinnerRiceBowls = 0,
    this.breakfastMenu = '',
    this.lunchMenu = '',
    this.dinnerMenu = '',
    this.breakfastDishId = '',
    this.lunchDishId = '',
    this.dinnerDishId = '',
    this.breakfastDishPortion = 'regular',
    this.lunchDishPortion = 'regular',
    this.dinnerDishPortion = 'regular',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get totalRiceBowls =>
      breakfastRiceBowls + lunchRiceBowls + dinnerRiceBowls;

  bool get hasMealPlan =>
      breakfastMenu.trim().isNotEmpty ||
      lunchMenu.trim().isNotEmpty ||
      dinnerMenu.trim().isNotEmpty ||
      breakfastDishId.trim().isNotEmpty ||
      lunchDishId.trim().isNotEmpty ||
      dinnerDishId.trim().isNotEmpty;

  int get completedMeals => <bool>[
        breakfastRiceBowls > 0 ||
            breakfastMenu.trim().isNotEmpty ||
            breakfastDishId.trim().isNotEmpty,
        lunchRiceBowls > 0 ||
            lunchMenu.trim().isNotEmpty ||
            lunchDishId.trim().isNotEmpty,
        dinnerRiceBowls > 0 ||
            dinnerMenu.trim().isNotEmpty ||
            dinnerDishId.trim().isNotEmpty,
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
    String? breakfastDishId,
    String? lunchDishId,
    String? dinnerDishId,
    String? breakfastDishPortion,
    String? lunchDishPortion,
    String? dinnerDishPortion,
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
      breakfastDishId: breakfastDishId ?? this.breakfastDishId,
      lunchDishId: lunchDishId ?? this.lunchDishId,
      dinnerDishId: dinnerDishId ?? this.dinnerDishId,
      breakfastDishPortion: breakfastDishPortion ?? this.breakfastDishPortion,
      lunchDishPortion: lunchDishPortion ?? this.lunchDishPortion,
      dinnerDishPortion: dinnerDishPortion ?? this.dinnerDishPortion,
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
      'breakfastDishId': breakfastDishId,
      'lunchDishId': lunchDishId,
      'dinnerDishId': dinnerDishId,
      'breakfastDishPortion': breakfastDishPortion,
      'lunchDishPortion': lunchDishPortion,
      'dinnerDishPortion': dinnerDishPortion,
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
      breakfastDishId: _stringValue(map['breakfastDishId']),
      lunchDishId: _stringValue(map['lunchDishId']),
      dinnerDishId: _stringValue(map['dinnerDishId']),
      breakfastDishPortion:
          _portionValue(_stringValue(map['breakfastDishPortion'])),
      lunchDishPortion: _portionValue(_stringValue(map['lunchDishPortion'])),
      dinnerDishPortion: _portionValue(_stringValue(map['dinnerDishPortion'])),
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

  static String _portionValue(String value) {
    return switch (value) {
      'small' || 'regular' || 'large' => value,
      _ => 'regular',
    };
  }

  static int compareByRecentCreated(MealEntry a, MealEntry b) {
    final createdCompare = b.createdAt.compareTo(a.createdAt);
    if (createdCompare != 0) return createdCompare;
    return b.date.compareTo(a.date);
  }
}
