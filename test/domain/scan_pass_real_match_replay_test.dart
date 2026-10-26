import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/scan_pass/real_match_replay.dart';

void main() {
  late RealMatchReplayData replay;

  setUpAll(() {
    replay = RealMatchReplayData.fromJsonString(
      File('assets/scan_pass_replay/replay-data.json').readAsStringSync(),
    );
  });

  test('asset identity retains the pinned active match roster and source', () {
    expect(replay.match.id, 1925299);
    expect(replay.match.home, 'Brisbane Roar');
    expect(replay.match.away, 'Perth Glory');
    expect(replay.match.date, '2024-12-21');
    expect(replay.players, hasLength(22));
    expect(replay.players.where((player) => player.home), hasLength(11));
    expect(replay.players.where((player) => !player.home), hasLength(11));
    expect(replay.frames, hasLength(309));
    expect(replay.poses, hasLength(155));
    expect(replay.fps, 25);
    expect(replay.poseStep, 2);
    expect(replay.duration, 12.32);
    expect(replay.startClock, 4654.48);
    expect(
      replay.sourceCommit,
      '4340d274572876239c154c90bc507a9b3250a656',
    );
    expect(replay.player(287934).number, 8);
    expect(replay.player(965698).number, 18);
    expect(replay.player(11897).number, 19);
    expect(replay.player(795533).number, 17);
    expect(replay.player(560985).keeper, isTrue);
  });

  test('centimetres convert once and interpolation preserves both endpoints',
      () {
    final first = replay.sample(0);
    final halfway = replay.sample(.02);
    final last = replay.sample(replay.duration);

    expect(first.players.first!.x, -33.95);
    expect(first.players.first!.y, .02);
    expect(first.players[replay.playerIndex(287934)]!.x, 4.95);
    expect(first.ball.x, 5.36);
    expect(first.ball.y, .38);
    expect(first.ball.z, .42);
    expect(halfway.ball.x, 5.36);
    expect(halfway.ball.y, closeTo(.535, 1e-10));
    expect(halfway.ball.z, .43);
    expect(last.sourceFrame, 308);
    expect(last.players.first!.x, -25.30);
    expect(last.ball.x, 50.93);
    expect(last.ball.y, 6.37);
    expect(last.ball.z, .30);
  });

  test('poses require recorded interpolation endpoints', () {
    final missing = replay.poseAt(0, replay.playerIndex(50999));
    final recorded = replay.poseAt(0, replay.playerIndex(965698));

    expect(missing, isNull);
    expect(recorded, isNotNull);
    expect(recorded!.joints, hasLength(18));
    expect(recorded.joints.first.z, 1.66);
  });

  test('source events and stable explanation boundaries remain authoritative',
      () {
    expect(replay.events.map((event) => event.id), <String>['8_870', '8_871']);
    expect(replay.events.first.playerId, 287934);
    expect(replay.events.first.targetedPlayerId, 965698);
    expect(replay.events.first.passOutcome, 'successful');
    expect(replay.events.first.end, 2.42);
    expect(replay.events.last.start, 4.22);
    expect(replay.events.last.end, 11.22);
    expect(replay.events.last.endType, 'shot');

    expect(replay.phaseAt(2.419), RealMatchReplayPhase.prepare);
    expect(replay.phaseAt(2.42), RealMatchReplayPhase.spacePass);
    expect(replay.phaseAt(4.22), RealMatchReplayPhase.advance);
    expect(replay.phaseAt(8), RealMatchReplayPhase.recovery);
    expect(replay.phaseAt(11.22), RealMatchReplayPhase.outcome);
    expect(replay.phaseAt(12.32), RealMatchReplayPhase.outcome);
  });
}
