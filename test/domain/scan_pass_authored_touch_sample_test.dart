import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/scan_pass/authored_touch_sample.dart';

void main() {
  late AuthoredTouchSample sample;

  setUpAll(() {
    sample = AuthoredTouchSample.fromJsonString(
      File('assets/scan_pass_authored/first-touch-open-side.json')
          .readAsStringSync(),
    );
  });

  test('asset is an explicit fictional authored reconstruction', () {
    expect(sample.schemaVersion, 1);
    expect(sample.id, 'fictional-first-touch-open-side-v1');
    expect(sample.kind, 'manually-authored-educational-reconstruction');
    expect(sample.provenance.capturedTracking, isFalse);
    expect(sample.provenance.aiMeasurement, isFalse);
    expect(sample.provenance.coachCertified, isFalse);
    expect(sample.provenance.fictionalPlayers, isTrue);
    expect(sample.validationErrors(), isEmpty);
    expect(
      sample.players.where((player) => player.team == AuthoredTouchTeam.attack),
      hasLength(3),
    );
    expect(
      sample.players
          .where((player) => player.team == AuthoredTouchTeam.defense),
      hasLength(2),
    );
  });

  test('motion remains finite, bounded and physically limited', () {
    const dt = .025;
    for (final continuation in AuthoredTouchContinuation.values) {
      AuthoredTouchFrame? previous;
      final previousVelocity = <String, AuthoredTouchPoint>{};
      var previousBallVelocity = const AuthoredTouchPoint(0, 0, 0);
      for (double time = 0; time <= sample.duration + 1e-9; time += dt) {
        final frame = sample.sampleAt(time, continuation);
        expect(frame.ball.point.isFinite, isTrue);
        expect(sample.contextBounds.contains(frame.ball.point, margin: .01),
            isTrue);
        for (final player in sample.players) {
          final pose = frame.players[player.id]!;
          expect(pose.root.isFinite, isTrue);
          expect(pose.leftFoot.isFinite, isTrue);
          expect(pose.rightFoot.isFinite, isTrue);
          expect(sample.contextBounds.contains(pose.root), isTrue);
          expect(pose.root.distanceTo(pose.leftFoot), lessThan(1.16));
          expect(pose.root.distanceTo(pose.rightFoot), lessThan(1.16));
          if (previous != null) {
            final old = previous.players[player.id]!.root;
            final velocity = _velocity(old, pose.root, dt);
            expect(_magnitude(velocity), lessThan(8.0),
                reason: '${continuation.name}/${player.id} at $time');
            final oldVelocity = previousVelocity[player.id];
            if (oldVelocity != null) {
              final acceleration = _velocity(oldVelocity, velocity, dt);
              expect(_magnitude(acceleration), lessThan(95),
                  reason: '${continuation.name}/${player.id} at $time');
            }
            previousVelocity[player.id] = velocity;
          }
        }
        if (previous != null) {
          final ballVelocity =
              _velocity(previous.ball.point, frame.ball.point, dt);
          expect(_magnitude(ballVelocity), lessThan(13.0),
              reason: '${continuation.name} ball at $time');
          if (time > dt * 1.5) {
            final acceleration =
                _velocity(previousBallVelocity, ballVelocity, dt);
            final contactImpulse = sample.eventsFor(continuation).any(
                  (event) =>
                      event.foot != null &&
                      (time - event.time).abs() < dt * 2.1,
                );
            if (!contactImpulse) {
              expect(_magnitude(acceleration), lessThan(180),
                  reason: '${continuation.name} ball at $time');
            }
          }
          previousBallVelocity = ballVelocity;
        }
        previous = frame;
      }
    }
  });

  test('body rig keeps finite fixed-length legs and reachable contact shoes',
      () {
    const rig = AuthoredTouchBodyRig();
    for (final continuation in AuthoredTouchContinuation.values) {
      for (double time = 0; time <= sample.duration; time += .04) {
        final frame = sample.sampleAt(time, continuation);
        for (final player in sample.players) {
          final body = rig.solve(frame.players[player.id]!);
          expect(body.isFinite, isTrue,
              reason: '${continuation.name}/${player.id} at $time');
          expect(body.leftLegReach,
              lessThanOrEqualTo(AuthoredTouchBodyRig.maximumLegReach));
          expect(body.rightLegReach,
              lessThanOrEqualTo(AuthoredTouchBodyRig.maximumLegReach));
          expect(body.pelvisCenter.z, greaterThan(.39),
              reason: '${continuation.name}/${player.id} stance at $time');
          expect(
            body.leftHip.distanceTo(body.leftKnee),
            closeTo(AuthoredTouchBodyRig.upperLegLength, 1e-8),
          );
          expect(
            body.leftKnee.distanceTo(body.leftAnkle),
            closeTo(AuthoredTouchBodyRig.lowerLegLength, 1e-8),
          );
          expect(
            body.rightHip.distanceTo(body.rightKnee),
            closeTo(AuthoredTouchBodyRig.upperLegLength, 1e-8),
          );
          expect(
            body.rightKnee.distanceTo(body.rightAnkle),
            closeTo(AuthoredTouchBodyRig.lowerLegLength, 1e-8),
          );
        }
      }
    }

    final steal = sample.eventFor(
      AuthoredTouchContinuation.pressureSide,
      AuthoredTouchEventType.steal,
    )!;
    final presser = rig.solve(sample
        .sampleAt(steal.time, AuthoredTouchContinuation.pressureSide)
        .players['presser']!);
    expect(presser.rightLegReach, lessThan(1.1),
        reason: 'The stealing defender support leg must remain a human lunge.');
  });

  test('torso volume remains visible at every cardinal facing', () {
    const rig = AuthoredTouchBodyRig();
    for (final facing in <double>[0, math.pi / 2, math.pi, -math.pi / 2]) {
      final body = rig.solve(AuthoredTouchPose(
        root: const AuthoredTouchPoint(0, 0),
        bodyFacing: facing,
        leftFoot: const AuthoredTouchPoint(-.2, -.35),
        rightFoot: const AuthoredTouchPoint(.2, .35),
      ));
      final projectedX = body.torsoVertices.map((point) => point.x);
      final projectedY = body.torsoVertices.map((point) => -point.y - point.z);
      final width = projectedX.reduce(math.max) - projectedX.reduce(math.min);
      final height = projectedY.reduce(math.max) - projectedY.reduce(math.min);
      expect(width, greaterThanOrEqualTo(.31), reason: 'facing=$facing');
      expect(height, greaterThan(.45), reason: 'facing=$facing');
    }
  });

  test('the receiving player turns without crossing both legs', () {
    for (final continuation in AuthoredTouchContinuation.values) {
      for (double time = 0; time <= sample.duration; time += .025) {
        final pose = sample.sampleAt(time, continuation).players['receiver']!;
        final side = AuthoredTouchPoint(
          -math.sin(pose.bodyFacing),
          math.cos(pose.bodyFacing),
        );
        expect((pose.leftFoot - pose.rightFoot).dot(side), greaterThan(.04),
            reason: '${continuation.name} stance at $time');
      }
    }
  });

  test('passes and the first-touch roll keep moving between contacts', () {
    const continuation = AuthoredTouchContinuation.openSide;
    for (final interval in <List<double>>[
      [.7, 3.15, 4],
      [3.25, 4.15, 3],
      [5.6, 7.65, 5.5],
    ]) {
      for (double time = interval[0]; time <= interval[1]; time += .05) {
        final before = sample.sampleAt(time - .002, continuation).ball.point;
        final after = sample.sampleAt(time + .002, continuation).ball.point;
        expect(before.distanceTo(after) / .004, greaterThan(interval[2]),
            reason: 'A rolling ball must not stop at a plotting key at $time');
      }
    }
    expect(
        sample
            .eventsFor(continuation)
            .where((event) => event.type == AuthoredTouchEventType.carryTouch),
        hasLength(2));
  });

  test('event-derived traces follow the editable ball keyframes', () {
    for (final continuation in AuthoredTouchContinuation.values) {
      final pass = sample.eventFor(
        continuation,
        AuthoredTouchEventType.initialPass,
      )!;
      final touch = sample.eventFor(
        continuation,
        AuthoredTouchEventType.firstTouch,
      )!;
      final incoming = sample.ballPathBetween(
        continuation,
        start: pass.time,
        end: touch.time,
      );
      expect(
        incoming.first
            .distanceTo(sample.sampleAt(pass.time, continuation).ball.point),
        lessThan(1e-12),
      );
      expect(
        incoming.last
            .distanceTo(sample.sampleAt(touch.time, continuation).ball.point),
        lessThan(1e-12),
      );
      expect(incoming.length, greaterThanOrEqualTo(2));
    }
  });

  test('both choices have an identical lead-in and split continuously', () {
    for (double time = 0; time <= sample.sharedUntil; time += .04) {
      final open = sample.sampleAt(time, AuthoredTouchContinuation.openSide);
      final pressure =
          sample.sampleAt(time, AuthoredTouchContinuation.pressureSide);
      expect(open.ball.point.distanceTo(pressure.ball.point), lessThan(1e-12));
      expect(open.ball.rotation, pressure.ball.rotation);
      for (final player in sample.players) {
        expect(
          open.players[player.id]!.root
              .distanceTo(pressure.players[player.id]!.root),
          lessThan(1e-12),
        );
        expect(
          open.players[player.id]!.leftFoot
              .distanceTo(pressure.players[player.id]!.leftFoot),
          lessThan(1e-12),
        );
        expect(
          open.players[player.id]!.rightFoot
              .distanceTo(pressure.players[player.id]!.rightFoot),
          lessThan(1e-12),
        );
      }
    }
    for (final continuation in AuthoredTouchContinuation.values) {
      final before = sample.sampleAt(
        sample.sharedUntil - .001,
        continuation,
      );
      final after = sample.sampleAt(
        sample.sharedUntil + .001,
        continuation,
      );
      expect(before.ball.point.distanceTo(after.ball.point), lessThan(.015));
      for (final player in sample.players) {
        expect(
          before.players[player.id]!.root
              .distanceTo(after.players[player.id]!.root),
          lessThan(.015),
        );
      }
    }
  });

  test('authored contact feet meet the same continuous ball', () {
    for (final continuation in AuthoredTouchContinuation.values) {
      for (final event in sample.eventsFor(continuation)) {
        if (event.foot == null) continue;
        final frame = sample.sampleAt(event.time, continuation);
        final foot = frame.players[event.actorId]!.foot(event.foot!);
        expect(foot.distanceTo(frame.ball.point), lessThan(1e-9),
            reason: '${continuation.name}/${event.id}');
        final before = sample.sampleAt(event.time - .001, continuation).ball;
        final after = sample.sampleAt(event.time + .001, continuation).ball;
        expect(before.point.distanceTo(after.point), lessThan(.04),
            reason: '${event.id} must not teleport');
        expect(after.rotation, greaterThanOrEqualTo(before.rotation));
      }
    }
  });

  test('asserted support feet do not slide through touch and kick', () {
    for (final continuation in AuthoredTouchContinuation.values) {
      final plants = <AuthoredTouchPlantWindow>[
        ...sample.sharedPlantWindows,
        ...sample.branches[continuation]!.plantWindows,
      ];
      for (final plant in plants) {
        for (var step = 0; step <= 20; step++) {
          final time = plant.start + (plant.end - plant.start) * step / 20;
          final actual = sample
              .sampleAt(time, continuation)
              .players[plant.playerId]!
              .foot(plant.foot);
          expect(actual.distanceTo(plant.point), lessThan(1e-9),
              reason:
                  '${continuation.name}/${plant.playerId}/${plant.foot.name}');
        }
      }
    }
  });

  test('open-side pass reaches the moving forward teammate', () {
    const continuation = AuthoredTouchContinuation.openSide;
    final pass = sample.eventsFor(continuation).singleWhere(
        (event) => event.type == AuthoredTouchEventType.forwardPass);
    final receive = sample
        .eventsFor(continuation)
        .singleWhere((event) => event.type == AuthoredTouchEventType.receive);
    expect(sample.possessionAt(pass.time, continuation), isNull);
    final arrival = sample.sampleAt(receive.time, continuation);
    expect(
      arrival.ball.point.distanceTo(arrival.players['forward']!.leftFoot),
      lessThan(1e-9),
    );
    expect(sample.possessionAt(receive.time, continuation), 'forward');
    expect(
      arrival.players['forward']!.root.distanceTo(
        sample
            .sampleAt(sample.sharedUntil, continuation)
            .players['forward']!
            .root,
      ),
      greaterThan(3),
    );
  });

  test('pressure-side touch produces a visible steal and defender carry', () {
    const continuation = AuthoredTouchContinuation.pressureSide;
    final events = sample.eventsFor(continuation);
    final touch = events.singleWhere(
      (event) => event.type == AuthoredTouchEventType.firstTouch,
    );
    final steal = events.singleWhere(
      (event) => event.type == AuthoredTouchEventType.steal,
    );
    final carry = events.singleWhere(
      (event) => event.type == AuthoredTouchEventType.defenderCarry,
    );
    expect(sample.possessionAt(touch.time, continuation), 'receiver');
    expect(sample.possessionAt(steal.time - .001, continuation), 'receiver');
    expect(sample.possessionAt(steal.time, continuation), 'presser');
    expect(sample.possessionAt(carry.time, continuation), 'presser');
    final stealFrame = sample.sampleAt(steal.time, continuation);
    expect(
      stealFrame.ball.point.distanceTo(stealFrame.players['presser']!.leftFoot),
      lessThan(1e-9),
    );
    final end = sample.sampleAt(sample.duration, continuation);
    expect(
      end.ball.point.distanceTo(stealFrame.ball.point),
      greaterThan(7),
    );
    expect(
      end.ball.point.distanceTo(end.players['presser']!.rightFoot),
      lessThan(.02),
    );
  });

  test('reset and exact end sampling are clamped and deterministic', () {
    for (final continuation in AuthoredTouchContinuation.values) {
      final reset = sample.sampleAt(0, continuation);
      final negative = sample.sampleAt(-20, continuation);
      final resetAgain = sample.sampleAt(0, continuation);
      expect(negative.time, 0);
      expect(negative.ball.point.distanceTo(reset.ball.point), 0);
      expect(resetAgain.ball.point.distanceTo(reset.ball.point), 0);
      final end = sample.sampleAt(sample.duration, continuation);
      final beyond = sample.sampleAt(sample.duration + 20, continuation);
      expect(end.time, sample.duration);
      expect(beyond.time, sample.duration);
      expect(end.ball.point.distanceTo(beyond.ball.point), 0);
      expect(end.phase, AuthoredTouchPhase.complete);
    }
  });
}

AuthoredTouchPoint _velocity(
  AuthoredTouchPoint from,
  AuthoredTouchPoint to,
  double seconds,
) =>
    AuthoredTouchPoint(
      (to.x - from.x) / seconds,
      (to.y - from.y) / seconds,
      (to.z - from.z) / seconds,
    );

double _magnitude(AuthoredTouchPoint point) =>
    math.sqrt(point.x * point.x + point.y * point.y + point.z * point.z);
