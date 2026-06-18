import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/presentation/screens/skill_quiz_screen.dart';

void main() {
  test('quiz quality harness passes for every supported sport', () {
    final report = buildQuizQualityHarnessReport();

    expect(report.failures, isEmpty, reason: report.toConsoleString());
    expect(report.passed, isTrue);
    expect(report.questionCountBySport.keys,
        containsAll(['football', 'baseball', 'basketball', 'tennis']));
  });
}
