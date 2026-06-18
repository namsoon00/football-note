import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/presentation/screens/skill_quiz_screen.dart';

void main() {
  test('quiz generation harness creates useful draft seeds', () {
    final report = buildQuizGenerationHarnessReport();
    final reportFile = File('build/reports/quiz_generation_harness.md');
    reportFile.parent.createSync(recursive: true);
    reportFile.writeAsStringSync(report.toMarkdownString());

    expect(report.failures, isEmpty, reason: report.toConsoleString());
    expect(report.passed, isTrue);
    expect(report.totalDraftSeeds, greaterThanOrEqualTo(32));
    expect(report.draftSeedsBySport.keys,
        containsAll(['football', 'baseball', 'basketball', 'tennis']));

    final seenIds = <String>{};
    final seenConcepts = <String>{};
    for (final entry in report.draftSeedsBySport.entries) {
      expect(entry.value, hasLength(greaterThanOrEqualTo(8)));
      final styles = entry.value.map((seed) => seed.style).toSet();
      final categories = entry.value.map((seed) => seed.category).toSet();
      expect(styles, containsAll(['ox', 'multipleChoice', 'shortAnswer']));
      expect(categories.length, greaterThanOrEqualTo(4));

      for (final seed in entry.value) {
        expect(seenIds.add('${seed.sportId}:${seed.idStem}'), isTrue);
        expect(seenConcepts.add('${seed.sportId}:${seed.conceptKey}'), isTrue);
        expect(seed.koPrompt.trim().length, greaterThan(18));
        expect(seed.enPrompt.trim().length, greaterThan(18));
        expect(seed.koAnswer.trim().length, greaterThan(0));
        expect(seed.enAnswer.trim().length, greaterThan(0));
        expect(seed.koExplanationAngle.trim().length, greaterThan(20));
        expect(seed.enExplanationAngle.trim().length, greaterThan(20));
        expect(seed.koNextPointAngle.trim().length, greaterThan(15));
        expect(seed.enNextPointAngle.trim().length, greaterThan(15));
      }
    }

    final markdown = report.toMarkdownString();
    expect(markdown, contains('Quiz Generation Harness Report'));
    expect(markdown, contains('curated deterministic draft seeds'));
  });
}
