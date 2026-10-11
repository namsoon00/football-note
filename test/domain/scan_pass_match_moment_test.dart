import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/scan_pass/scan_pass_match_moment.dart';
import 'package:football_note/domain/scan_pass/scan_pass_game.dart'
    show ScanPassPoint;

void main() {
  const episode = MatchMomentEpisode();

  test('roster uses match-specific numbers and team-qualified ids', () {
    final roster = episode.roster;
    expect(roster.map((p) => p.id).toSet(), hasLength(roster.length));
    expect(
      roster.where((p) => p.number == 2).map((p) => p.id).toSet(),
      {MatchMomentEpisode.spain2, MatchMomentEpisode.england2},
    );
    expect(
      roster.where((p) => p.team == MatchMomentTeam.spain).map((p) => p.number),
      containsAll(<int>[2, 7, 10, 17, 18, 19, 24]),
    );
    expect(
      roster.where((p) => p.team == MatchMomentTeam.spain).map((p) => p.number),
      isNot(anyOf(contains(16), contains(21))),
      reason: 'Rodri was replaced by Zubimendi; Oyarzabal was not on yet.',
    );
    expect(
      roster
          .where((p) => p.team == MatchMomentTeam.england)
          .map((p) => p.number),
      containsAll(<int>[1, 2, 3, 4, 5, 6, 7, 9, 10, 11, 26]),
    );
  });

  test(
      'historical line receives, touches shortly, carries, assists, and scores',
      () {
    final attempt = episode.historicalAttempt;
    expect(attempt.followsHistoricalLine, isTrue);
    expect(attempt.outcome, MatchMomentOutcome.goal);
    expect(attempt.finalFrame.ball.x, greaterThan(1.0));
    expect(attempt.finalFrame.ball.y, inInclusiveRange(.446, .554));

    final receive = attempt.segments.first;
    expect(receive.kind, MatchMomentActionKind.receivePass);
    expect(receive.actorId, MatchMomentEpisode.spain2);
    expect(receive.receiverId, MatchMomentEpisode.spain19);
    expect(receive.frame(.5).carrierId, isNull);
    expect(receive.after.carrierId, MatchMomentEpisode.spain19);

    final touch = attempt.segments
        .firstWhere((s) => s.kind == MatchMomentActionKind.firstTouch);
    expect(_metres(touch.before.ball, touch.after.ball), lessThan(2.5));

    final carry = attempt.segments.firstWhere(
      (s) =>
          s.kind == MatchMomentActionKind.carry &&
          s.choiceId == MatchMomentChoiceId.passWilliams,
    );
    expect(_metres(carry.before.ball, carry.after.ball), greaterThan(8));
    expect(carry.duration, greaterThan(1.0));

    final assist = attempt.segments.firstWhere(
      (s) =>
          s.kind == MatchMomentActionKind.pass &&
          s.receiverId == MatchMomentEpisode.spain17,
    );
    expect(assist.actorId, MatchMomentEpisode.spain19);
    expect(assist.frame(.4).carrierId, isNull);

    final shot = attempt.segments.last;
    expect(shot.kind, MatchMomentActionKind.shot);
    expect(shot.actorId, MatchMomentEpisode.spain17);
  });

  test('authored branches produce different coherent conclusions', () {
    final goal = episode.historicalAttempt;
    final saved = episode.buildAttempt(const [
      MatchMomentChoiceId.receiveWide,
      MatchMomentChoiceId.touchLine,
      MatchMomentChoiceId.passWilliams,
    ]);
    final turnover = episode.buildAttempt(const [
      MatchMomentChoiceId.receiveCheck,
      MatchMomentChoiceId.touchSet,
      MatchMomentChoiceId.passWilliams,
    ]);
    final retained = episode.buildAttempt(const [
      MatchMomentChoiceId.receiveInside,
      MatchMomentChoiceId.touchInside,
      MatchMomentChoiceId.passMorata,
    ]);
    final riskyCarry = episode.buildAttempt(const [
      MatchMomentChoiceId.receiveWide,
      MatchMomentChoiceId.touchLine,
      MatchMomentChoiceId.carryInside,
    ]);

    expect(goal.outcome, MatchMomentOutcome.goal);
    expect(saved.outcome, MatchMomentOutcome.saved);
    expect(turnover.outcome, MatchMomentOutcome.turnover);
    expect(retained.outcome, MatchMomentOutcome.retained);
    expect(riskyCarry.outcome, MatchMomentOutcome.turnover);

    for (final attempt in [goal, saved, turnover, retained, riskyCarry]) {
      _expectContinuous(attempt.segments);
    }
  });

  test('retry frame for the last decision preserves the prior choices state',
      () {
    final attempt = episode.buildAttempt(const [
      MatchMomentChoiceId.receiveInside,
      MatchMomentChoiceId.touchInside,
      MatchMomentChoiceId.carryInside,
    ]);
    final beforeNext = attempt.frameBefore(MatchMomentBeat.nextAction);
    final rebuilt = episode.buildAttempt(const [
      MatchMomentChoiceId.receiveInside,
      MatchMomentChoiceId.touchInside,
      MatchMomentChoiceId.passMorata,
    ]);
    final otherBeforeNext = rebuilt.frameBefore(MatchMomentBeat.nextAction);

    expect(beforeNext.ball.distanceTo(otherBeforeNext.ball), closeTo(0, 1e-9));
    expect(beforeNext.carrierId, MatchMomentEpisode.spain19);
    expect(
      beforeNext.actor(MatchMomentEpisode.spain19).position.distanceTo(
            otherBeforeNext.actor(MatchMomentEpisode.spain19).position,
          ),
      closeTo(0, 1e-9),
    );
  });

  test('backward touch points toward Carvajal from every receiving position',
      () {
    for (final receive in [
      MatchMomentChoiceId.receiveInside,
      MatchMomentChoiceId.receiveWide,
      MatchMomentChoiceId.receiveCheck
    ]) {
      final frame =
          episode.applyChoice(episode.decisionStart, [], receive).after;
      final option = episode
          .choicesFor(MatchMomentBeat.firstTouch, frame)
          .firstWhere((c) => c.id == MatchMomentChoiceId.touchSet);
      final touch = option.target - frame.ball;
      final support =
          frame.actor(MatchMomentEpisode.spain2).position - frame.ball;
      expect(touch.x * support.y - touch.y * support.x, closeTo(0, 1e-9));
      expect(touch.x * support.x + touch.y * support.y, greaterThan(0));
      expect(_metres(frame.ball, option.target), closeTo(1.5, 1e-8));
      final executed =
          episode.applyChoice(frame, [receive], MatchMomentChoiceId.touchSet);
      expect(executed.after.ball.distanceTo(option.target), closeTo(0, 1e-9));
    }
  });

  test('authored actor movement stays within short-burst pace', () {
    for (final attempt in _allAttempts(episode)) {
      for (final segment in attempt.segments) {
        expect(segment.after.elapsed - segment.before.elapsed,
            closeTo(segment.duration, 1e-8));
        expect(segment.frame(0).carrierId, segment.before.carrierId);
        expect(segment.frame(1).carrierId, segment.after.carrierId);
        for (final entry in segment.before.actors.entries) {
          final after = segment.after.actor(entry.key);
          final speed =
              _metres(entry.value.position, after.position) / segment.duration;
          expect(
            speed,
            lessThanOrEqualTo(8.501),
            reason:
                '${attempt.choices} ${segment.kind} moved ${entry.key} too fast',
          );
        }
      }
    }
  });
  test('reference assist has an open lane around moving defenders', () {
    final assist = episode.historicalAttempt.segments.firstWhere((segment) =>
        segment.kind == MatchMomentActionKind.pass &&
        segment.receiverId == MatchMomentEpisode.spain17);
    for (final player
        in episode.roster.where((p) => p.team == MatchMomentTeam.england)) {
      for (var sample = 0; sample <= 100; sample++) {
        final frame = assist.frame(sample / 100);
        expect(_metres(frame.ball, frame.actor(player.id).position),
            greaterThan(1.2),
            reason: '${player.id} at sample $sample');
      }
    }
  });

  test('a defender owns the ball only after contact when stealing a carry', () {
    final attempt = episode.buildAttempt(const [
      MatchMomentChoiceId.receiveWide,
      MatchMomentChoiceId.touchLine,
      MatchMomentChoiceId.carryInside,
    ]);
    final contact = attempt.segments.last;
    expect(contact.frame(.5).carrierId, MatchMomentEpisode.spain19);
    expect(contact.after.carrierId, MatchMomentEpisode.england3);
    expect(
        contact.after.ball.distanceTo(
            contact.after.actor(MatchMomentEpisode.england3).position),
        closeTo(0, 1e-9));
    expect(
        contact.before.ball.distanceTo(contact.after.ball), closeTo(0, 1e-9));
  });
}

Iterable<MatchMomentAttempt> _allAttempts(MatchMomentEpisode episode) sync* {
  const receiveChoices = [
    MatchMomentChoiceId.receiveInside,
    MatchMomentChoiceId.receiveWide,
    MatchMomentChoiceId.receiveCheck,
  ];
  const touchChoices = [
    MatchMomentChoiceId.touchInside,
    MatchMomentChoiceId.touchLine,
    MatchMomentChoiceId.touchSet,
  ];
  const nextChoices = [
    MatchMomentChoiceId.passWilliams,
    MatchMomentChoiceId.passMorata,
    MatchMomentChoiceId.carryInside,
  ];
  for (final receive in receiveChoices) {
    for (final touch in touchChoices) {
      for (final next in nextChoices) {
        yield episode.buildAttempt([receive, touch, next]);
      }
    }
  }
}

double _metres(ScanPassPoint a, ScanPassPoint b) {
  final dx = (a.x - b.x) * 105;
  final dy = (a.y - b.y) * 68;
  return math.sqrt(dx * dx + dy * dy);
}

void _expectContinuous(List<MatchMomentSegment> segments) {
  for (var index = 1; index < segments.length; index += 1) {
    final previous = segments[index - 1].after;
    final next = segments[index].before;
    expect(next.ball.distanceTo(previous.ball), closeTo(0, 1e-9));
    expect(next.carrierId, previous.carrierId);
    for (final entry in previous.actors.entries) {
      expect(
        next.actor(entry.key).position.distanceTo(entry.value.position),
        closeTo(0, 1e-9),
      );
    }
  }
}
