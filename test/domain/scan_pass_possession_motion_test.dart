import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/scan_pass/scan_pass_attack.dart';
import 'package:football_note/domain/scan_pass/scan_pass_possession_lesson.dart';

void main() {
  const engine = ScanPassPossessionLessonEngine();
  test(
      'coordinated defenders accelerate and turn without role-change speed jumps',
      () {
    var curved = 0, changingSpeeds = 0;
    for (final item in ScanPassPossessionLessonEngine.catalog) {
      final branch = engine.recommendedBranch(
          engine.scene(situation: item.situation, variant: item.variant));
      for (final t in branch.transitions) {
        for (var i = 1; i < t.motionSamples.length; i++) {
          final a = t.motionSamples[i - 1], b = t.motionSamples[i];
          final dt = b.elapsed - a.elapsed;
          if (dt < 1e-8) continue;
          for (final p in [...a.attackers, ...a.defenders]) {
            final q = (p.opponent ? b.defenders : b.attackers)
                .firstWhere((q) => q.number == p.number);
            final speed = ScanPassPossessionLessonEngine.distanceMetres(
                    p.position, q.position) /
                dt;
            expect(speed, lessThanOrEqualTo(7.05),
                reason: '${item.id} ${t.action.kind} #${p.number}');
            if (p.opponent) {
              final acceleration =
                  ScanPassPossessionLessonEngine.distanceMetres(
                          p.velocity, q.velocity) /
                      dt;
              expect(acceleration, lessThanOrEqualTo(5.51));
              if (acceleration > 1) changingSpeeds++;
            }
          }
        }
        if (t.duration > .5) {
          final halfway = t.frame(.5);
          for (final p in t.before.defenders.where((p) => !p.goalkeeper)) {
            final end =
                t.after.defenders.firstWhere((q) => q.number == p.number);
            final actual =
                halfway.defenders.firstWhere((q) => q.number == p.number);
            if (ScanPassPossessionLessonEngine.distanceMetres(
                    actual.position, p.position.lerp(end.position, .5)) >
                .15) {
              curved++;
            }
          }
        }
      }
    }
    expect(curved, greaterThan(25));
    expect(changingSpeeds, greaterThan(100));
  });

  test('rendered frames follow the same sampled paths used for interceptions',
      () {
    final branch = engine.recommendedBranch(engine.scene());
    for (final t in branch.transitions) {
      expect(t.motionSamples, isNotEmpty);
      for (final sample in t.motionSamples.skip(1)) {
        final progress = (sample.elapsed - t.before.elapsed) / t.duration;
        final rendered = t.frame(progress);
        expect(
            ScanPassPossessionLessonEngine.distanceMetres(
                rendered.ball, sample.ball),
            lessThan(1e-6));
        for (final p in sample.defenders) {
          expect(
              ScanPassPossessionLessonEngine.distanceMetres(
                  p.position,
                  rendered.defenders
                      .firstWhere((q) => q.number == p.number)
                      .position),
              lessThan(1e-6));
        }
      }
    }
  });

  test(
      'normal pass flights are faster than runners and first touches stay close',
      () {
    for (final item in ScanPassPossessionLessonEngine.catalog) {
      final scene =
          engine.scene(situation: item.situation, variant: item.variant);
      final point = engine.firstPhase(scene);
      for (final choice in [
        ScanPassPossessionChoice.touchAway,
        ScanPassPossessionChoice.turnForward
      ]) {
        final target = engine.targetFor(point, choice);
        expect(
            ScanPassPossessionLessonEngine.distanceMetres(
                point.state.ball, target),
            inInclusiveRange(2.7, 3.3));
      }
      final branch = engine.recommendedBranch(scene);
      for (final t in branch.transitions.where(
          (t) => t.action.kind == AttackActionKind.pass && t.duration > .2)) {
        expect(
            ScanPassPossessionLessonEngine.distanceMetres(
                    t.before.ball, t.after.ball) /
                t.duration,
            closeTo(19, .15));
      }
    }
  });

  test('changing scene names cannot change the physical answer', () {
    final original =
        engine.scene(situation: ScanPassPossessionSituation.touchline);
    final renamed = ScanPassPossessionScene(
        variant: ScanPassPossessionVariant.cover,
        situation: ScanPassPossessionSituation.transition,
        initial: original.initial,
        reception: original.reception,
        spotlights: original.spotlights);
    final a = engine.recommendedBranch(original),
        b = engine.recommendedBranch(renamed);
    expect(a.decisions, b.decisions);
    expect(
        a.transitions
            .map((t) => '${t.after.ball.x}/${t.after.ball.y}/${t.after.end}'),
        b.transitions
            .map((t) => '${t.after.ball.x}/${t.after.ball.y}/${t.after.end}'));
  });
}
