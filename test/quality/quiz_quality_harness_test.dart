import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/presentation/screens/skill_quiz_screen.dart';

void main() {
  test('quiz quality harness passes for every supported sport', () {
    final report = buildQuizQualityHarnessReport();

    expect(report.failures, isEmpty, reason: report.toConsoleString());
    expect(report.passed, isTrue);
    expect(report.questionCountBySport.keys,
        containsAll(['football', 'baseball', 'basketball', 'tennis']));
    for (final entry in report.styleCountBySport.entries) {
      for (final count in entry.value.values) {
        expect(
          count,
          greaterThanOrEqualTo(20),
          reason: '${entry.key} style counts: ${entry.value}',
        );
      }
    }
  });
}
