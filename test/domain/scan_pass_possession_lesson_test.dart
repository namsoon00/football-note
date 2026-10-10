import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/scan_pass/scan_pass_attack.dart';
import 'package:football_note/domain/scan_pass/scan_pass_game.dart'
    show ScanPassPoint;
import 'package:football_note/domain/scan_pass/scan_pass_possession_lesson.dart';

void main() {
  const engine = ScanPassPossessionLessonEngine();

  test(
      'catalog has twelve playable situations with six distinct spatial problems',
      () {
    const catalog = ScanPassPossessionLessonEngine.catalog;
    expect(catalog.length, 12);
    expect(catalog.map((s) => s.id).toSet().length, 12);
    final origins = <String>{};
    for (final item in catalog) {
      final scene =
          engine.scene(situation: item.situation, variant: item.variant);
      origins.add('${scene.reception.ball.x}/${scene.reception.ball.y}');
      expect(scene.situation, item.situation);
      expect(scene.reception.carrierNumber, 6);
      expect(scene.observation.duration, inExclusiveRange(.4, 1.5));
      expect(scene.observation.after, same(scene.reception));
    }
    expect(origins.length, 6);
  });

  test(
      'recommended attacks connect from reception to a real shot or safe reset',
      () {
    var shots = 0;
    for (final item in ScanPassPossessionLessonEngine.catalog) {
      final scene =
          engine.scene(situation: item.situation, variant: item.variant);
      final branch = engine.recommendedBranch(scene);
      expect(branch.recommended, isTrue);
      expect(branch.outcome, isNot(ScanPassPossessionOutcomeKind.turnover),
          reason: item.id);
      if (branch.outcome == ScanPassPossessionOutcomeKind.chanceCreated) {
        shots++;
        expect(branch.transitions.last.action.kind, AttackActionKind.shoot);
        expect(branch.finalState.end,
            anyOf(AttackEnd.goal, AttackEnd.saved, AttackEnd.blocked));
        expect(branch.evidence,
            contains(ScanPassPossessionEvidence.supportConnected));
      } else {
        expect(branch.finalState.carrierNumber, 4);
        expect(branch.finalState.finished, isFalse);
      }
      final transitions = branch.fullTransitions;
      for (var i = 1; i < transitions.length; i++) {
        expect(transitions[i].before, same(transitions[i - 1].after));
      }
      expect(
          transitions.fold<double>(0, (s, t) => s + t.duration), lessThan(13));
    }
    expect(shots, greaterThanOrEqualTo(8));
  });

  test(
      'defensive variations change decisions without moving the opening attackers',
      () {
    var differentFirstTouches = 0;
    for (final situation in ScanPassPossessionSituation.values) {
      final press = engine.scene(situation: situation);
      final cover = engine.scene(
          situation: situation, variant: ScanPassPossessionVariant.cover);
      expect(press.initial.attackers.map((p) => p.position.x),
          cover.initial.attackers.map((p) => p.position.x));
      expect(press.initial.attackers.map((p) => p.position.y),
          cover.initial.attackers.map((p) => p.position.y));
      expect(press.reception.defenders.first.position.x,
          isNot(cover.reception.defenders.first.position.x));
      if (engine.recommendedBranch(press).decisions.first !=
          engine.recommendedBranch(cover).decisions.first) {
        differentFirstTouches++;
      }
    }
    expect(differentFirstTouches, greaterThanOrEqualTo(3));
  });

  test('support direction and metre distance match the learner actual run', () {
    var checked = 0;
    for (final item in ScanPassPossessionLessonEngine.catalog) {
      final scene =
          engine.scene(situation: item.situation, variant: item.variant);
      final branch = engine.recommendedBranch(scene);
      var point = engine.firstPhase(scene);
      for (final choice in branch.decisions) {
        if (point.kind == ScanPassPossessionDecisionKind.support) {
          expect(point.activeNumber, 6);
          expect(point.state.carrierNumber, isNot(6));
          final origins =
              point.state.attackers.firstWhere((p) => p.number == 6).position;
          final destinations = <String>{};
          for (final option in point.choices) {
            final target = engine.targetFor(point, option);
            destinations.add('${target.x}/${target.y}');
            final run = engine.choose(point, option).transitions.first;
            if (!run.after.finished) {
              final end =
                  run.after.attackers.firstWhere((p) => p.number == 6).position;
              expect(ScanPassPossessionLessonEngine.distanceMetres(end, target),
                  lessThan(1e-7));
              final expected = ScanPassPossessionLessonEngine.distanceMetres(
                  origins, target);
              var travelled = 0.0;
              for (var i = 1; i < run.motionSamples.length; i++) {
                final a = run.motionSamples[i - 1].attackers
                    .firstWhere((p) => p.number == 6)
                    .position;
                final b = run.motionSamples[i].attackers
                    .firstWhere((p) => p.number == 6)
                    .position;
                travelled +=
                    ScanPassPossessionLessonEngine.distanceMetres(a, b);
              }
              expect(travelled, closeTo(expected, 1e-7));
              expect(travelled, inInclusiveRange(3, 9));
              checked++;
            }
          }
          expect(destinations.length, 3);
        }
        final result = engine.choose(point, choice);
        if (result.nextPoint == null) break;
        point = result.nextPoint!;
      }
    }
    expect(checked, greaterThan(15));
  });

  test('distances use pitch dimensions rather than pixels or normalized length',
      () {
    expect(
        ScanPassPossessionLessonEngine.distanceMetres(
            const ScanPassPoint(0, 0), const ScanPassPoint(1, 0)),
        105);
    expect(
        ScanPassPossessionLessonEngine.distanceMetres(
            const ScanPassPoint(0, 0), const ScanPassPoint(0, 1)),
        68);
    expect(
        ScanPassPossessionLessonEngine.distanceMetres(
            const ScanPassPoint(.4, .4),
            const ScanPassPoint(.4 + 3 / 105, .4 + 4 / 68)),
        closeTo(5, 1e-8));
  });

  test(
      'replaying and comparing branches is deterministic and preserves choices',
      () {
    final scene =
        engine.scene(situation: ScanPassPossessionSituation.halfSpace);
    final coach = engine.recommendedBranch(scene);
    ScanPassPossessionBranch play() {
      var point = engine.firstPhase(scene);
      for (final choice in coach.decisions) {
        final result = engine.choose(point, choice);
        if (result.branch != null) return result.branch!;
        point = result.nextPoint!;
      }
      throw StateError('Unfinished route');
    }

    final first = play(), second = play();
    expect(first.recommended, isFalse);
    expect(first.decisions, coach.decisions);
    expect(
        first.transitions.map((t) =>
            '${t.after.ball.x}/${t.after.ball.y}/${t.after.end}/${t.duration}'),
        second.transitions.map((t) =>
            '${t.after.ball.x}/${t.after.ball.y}/${t.after.end}/${t.duration}'));
    expect(identical(first, coach), isFalse);
  });
}
