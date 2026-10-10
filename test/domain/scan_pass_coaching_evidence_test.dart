import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/scan_pass/scan_pass_game.dart';
import 'package:football_note/domain/scan_pass/scan_pass_judgment.dart';

void main() {
  const engine = JudgmentEngine();

  test('cue pairs start from the same positions before movement changes', () {
    for (final spec in engine.catalog()) {
      final a = engine.scene(spec);
      final b = engine.scene(spec.pairedCue());
      for (final pair in [
        (a.initial.attackers, b.initial.attackers),
        (a.initial.defenders, b.initial.defenders)
      ]) {
        for (final player in pair.$1) {
          final other = pair.$2.firstWhere((p) => p.number == player.number);
          expect(player.position.distanceTo(other.position), lessThan(1e-8));
        }
      }
    }
  });

  test('first-touch coaching cites motion visible before the decision', () {
    for (final spec in engine.catalog()) {
      final scene = engine.scene(spec);
      final phase = engine.firstPhase(scene);
      for (final choice in phase.choices) {
        if (choice.action == JudgmentAction.oneTouchReturn) continue;
        final result = engine.choose(phase, choice);
        final cue = engine.coachingEvidence(result).observedCue;
        final observedStart = scene.initial.defenders
            .firstWhere((player) => player.number == cue.number);
        final observedEnd = scene.reception.defenders
            .firstWhere((player) => player.number == cue.number);
        expect(cue.opponent, isTrue);
        expect(cue.from.distanceTo(observedStart.position), lessThan(1e-8));
        expect(cue.to.distanceTo(observedEnd.position), lessThan(1e-8));
        final closing = cue.from.distanceTo(phase.state.ball) -
            cue.to.distanceTo(phase.state.ball);
        expect(
            cue.kind,
            closing > .01
                ? JudgmentCueKind.pressure
                : closing < -.01
                    ? JudgmentCueKind.pressureRetreating
                    : JudgmentCueKind.pressureHolding);
      }
    }
  });

  test('same positions with a different defensive run cannot justify advice',
      () {
    final scene = engine.scene(const JudgmentSceneSpec(
        family: JudgmentFamily.rearPressure, configuration: 0));
    final phase = engine.firstPhase(scene);
    final chosen = engine.choose(
        phase,
        phase.choices.firstWhere(
            (choice) => choice.action == JudgmentAction.touchForward));
    final changedState = phase.state.copyWith(defenders: [
      for (final player in phase.state.defenders)
        player.copyWith(
            velocity: player.velocity + const ScanPassPoint(.04, 0)),
    ]);
    final changedPhase = JudgmentPhase(
        scene: scene,
        kind: phase.kind,
        state: changedState,
        activeNumber: phase.activeNumber,
        step: phase.step,
        choices: phase.choices);
    final unrelatedAlternative = engine.choose(
        changedPhase,
        changedPhase.choices
            .firstWhere((choice) => choice.action == JudgmentAction.touchLeft));
    final evidence =
        engine.coachingEvidence(chosen, alternatives: [unrelatedAlternative]);
    expect(evidence.hasSupportedAlternative, isFalse);
    final sameMoment = engine.coachingEvidence(chosen,
        alternatives: engine.alternatives(phase));
    expect(sameMoment.hasSupportedAlternative, isTrue);
  });

  test('numbered connection evidence agrees with actual reachable outlets', () {
    var completed = 0;
    var lost = 0;
    for (final spec in engine.catalog()) {
      final phase = engine.firstPhase(engine.scene(spec));
      for (final choice in phase.choices) {
        final result = engine.choose(phase, choice);
        final numbers = engine.availableConnections(result.after);
        final positions = result.after.attackers
            .where((player) => numbers.contains(player.number))
            .map((player) => player.position)
            .toList();
        expect(positions, hasLength(result.outletPoints.length));
        for (final position in result.outletPoints) {
          expect(positions.any((point) => point.distanceTo(position) < 1e-8),
              isTrue);
        }
        if (result.after.finished) {
          lost++;
          expect(numbers, isEmpty);
        } else {
          completed++;
          expect(numbers, isNot(contains(result.after.carrierNumber)));
        }
      }
    }
    expect(completed, greaterThan(20));
    expect(lost, greaterThan(0));
  });
}
