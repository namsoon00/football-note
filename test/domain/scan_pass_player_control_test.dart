import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/scan_pass/scan_pass_game.dart'
    show ScanPassPoint;
import 'package:football_note/domain/scan_pass/scan_pass_possession_lesson.dart';

void main() {
  const engine = ScanPassPossessionLessonEngine();
  test(
      'an outgoing pass does not invent an off-ball destination for the learner',
      () {
    for (final item in ScanPassPossessionLessonEngine.catalog) {
      final scene =
          engine.scene(situation: item.situation, variant: item.variant);
      final before = scene.reception.copyWith(attackers: [
        for (final p in scene.reception.attackers)
          p.number == 6 ? p.copyWith(velocity: const ScanPassPoint(0, 0)) : p,
      ]);
      final point = ScanPassPossessionDecisionPoint(
        scene: scene,
        kind: ScanPassPossessionDecisionKind.nextAction,
        state: before,
        activeNumber: 6,
        choices: const [ScanPassPossessionChoice.passTo8],
        decisions: const [],
        history: const [],
      );
      final result = engine.choose(point, ScanPassPossessionChoice.passTo8);
      final from = before.attackers.firstWhere((p) => p.number == 6).position;
      for (final frame in result.transitions.first.motionSamples) {
        final to = frame.attackers.firstWhere((p) => p.number == 6).position;
        expect(ScanPassPossessionLessonEngine.distanceMetres(from, to),
            lessThan(1e-8),
            reason: '${item.id}: wait for an explicit movement choice');
      }
    }
  });
}
