import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/training_plan_series_builder.dart';

void main() {
  test('요일과 기간에 맞는 실제 일정 날짜를 생성한다', () {
    final dates = TrainingPlanSeriesBuilder.buildOccurrenceDates(
      startDate: DateTime(2026, 3, 23),
      endDate: DateTime(2026, 3, 31),
      weekdays: const [DateTime.monday, DateTime.wednesday],
      hour: 18,
      minute: 30,
    );

    expect(dates, <DateTime>[
      DateTime(2026, 3, 23, 18, 30),
      DateTime(2026, 3, 25, 18, 30),
      DateTime(2026, 3, 30, 18, 30),
    ]);
  });

  test('같은 날짜의 단일 요일 선택은 반복 등록으로 보지 않는다', () {
    final isRecurring = TrainingPlanSeriesBuilder.isRecurringSelection(
      startDate: DateTime(2026, 3, 23),
      endDate: DateTime(2026, 3, 23),
      weekdays: const [DateTime.monday],
    );

    expect(isRecurring, isFalse);
  });

  test('기간이 늘어나면 실제 반복 등록으로 본다', () {
    final isRecurring = TrainingPlanSeriesBuilder.isRecurringSelection(
      startDate: DateTime(2026, 3, 23),
      endDate: DateTime(2026, 3, 30),
      weekdays: const [DateTime.monday],
    );

    expect(isRecurring, isTrue);
  });
}
