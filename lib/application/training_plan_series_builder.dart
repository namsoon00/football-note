class TrainingPlanSeriesBuilder {
  const TrainingPlanSeriesBuilder._();

  static List<DateTime> buildOccurrenceDates({
    required DateTime startDate,
    required DateTime endDate,
    required List<int> weekdays,
    required int hour,
    required int minute,
  }) {
    final normalizedStart = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );
    final normalizedEnd = DateTime(endDate.year, endDate.month, endDate.day);
    if (normalizedEnd.isBefore(normalizedStart)) {
      return const <DateTime>[];
    }

    final weekdaySet = weekdays
        .where((value) => value >= DateTime.monday && value <= DateTime.sunday)
        .toSet();
    if (weekdaySet.isEmpty) {
      return const <DateTime>[];
    }

    final result = <DateTime>[];
    for (var day = normalizedStart;
        !day.isAfter(normalizedEnd);
        day = day.add(const Duration(days: 1))) {
      if (!weekdaySet.contains(day.weekday)) continue;
      result.add(DateTime(day.year, day.month, day.day, hour, minute));
    }
    return result;
  }

  static bool isRecurringSelection({
    required DateTime startDate,
    required DateTime endDate,
    required List<int> weekdays,
  }) {
    final normalizedStart = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );
    final normalizedEnd = DateTime(endDate.year, endDate.month, endDate.day);
    final uniqueWeekdays = weekdays.toSet();
    return normalizedStart != normalizedEnd ||
        uniqueWeekdays.length > 1 ||
        !uniqueWeekdays.contains(normalizedStart.weekday);
  }
}
