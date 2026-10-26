import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/scan_pass/real_match_replay.dart';
import 'package:football_note/domain/scan_pass/real_match_replay_detail.dart';

void main() {
  late RealMatchReplayData original;

  setUpAll(() {
    original = _scene('transition-wing');
  });

  test('receive includes observed before and after without the next action',
      () {
    final step = _step(original, RealMatchReplayStepKind.receive);
    final detail = RealMatchReplayActionDetail.forStep(original, step)!;

    expect(detail.start, closeTo(step.time - .5, 1e-9));
    expect(detail.end, closeTo(5, 1e-9));
    expect(detail.start, lessThan(step.time));
    expect(detail.end, greaterThan(step.time));
    expect(
        detail.end,
        lessThanOrEqualTo(
          original.scene.steps[original.scene.steps.indexOf(step) + 1].time,
        ));
    expect(detail.hasRecordedPose, isTrue);
  });

  test('observe, run, pressure, and outcome remain plain moments', () {
    const unsupported = <RealMatchReplayStepKind>{
      RealMatchReplayStepKind.observe,
      RealMatchReplayStepKind.run,
      RealMatchReplayStepKind.pressure,
      RealMatchReplayStepKind.outcome,
    };
    for (final step in original.scene.steps
        .where((item) => unsupported.contains(item.kind))) {
      expect(RealMatchReplayActionDetail.forStep(original, step), isNull,
          reason: '${step.kind} at ${step.time}');
    }
  });

  test('pass without an observed recipient still follows its recorded route',
      () {
    final salah = _scene('salah-right-recycle');
    final step = salah.scene.steps.firstWhere(
      (item) =>
          item.kind == RealMatchReplayStepKind.pass && item.targetId == null,
    );
    final detail = RealMatchReplayActionDetail.forStep(salah, step)!;

    expect(step.targetId, isNull);
    expect(detail.step.actorId, step.actorId);
    expect(detail.end, greaterThan(step.time));
    expect(
      _distance(salah.sample(step.time).ball, salah.sample(detail.end).ball),
      greaterThan(.1),
    );
  });

  test('carry window is capped and retains a recorded direction change', () {
    final vinicius = _scene('vinicius-carry-inside');
    final step = _step(vinicius, RealMatchReplayStepKind.carry);
    final detail = RealMatchReplayActionDetail.forStep(vinicius, step)!;
    final a = vinicius.sample(step.time).players[detail.actorIndex]!;
    final b = vinicius
        .sample((step.time + detail.end) / 2)
        .players[detail.actorIndex]!;
    final c = vinicius.sample(detail.end).players[detail.actorIndex]!;

    expect(detail.duration,
        lessThanOrEqualTo(RealMatchReplayActionDetail.maximumDuration));
    expect(detail.end, lessThanOrEqualTo(step.end!));
    expect(_angleDelta(_heading(a, b), _heading(b, c)).abs(), greaterThan(.08));
  });

  test('camera is fixed, tight, and contains observed actor and recorded ball',
      () {
    final step = _step(original, RealMatchReplayStepKind.pass);
    final detail = RealMatchReplayActionDetail.forStep(original, step)!;

    expect(detail.camera.width, lessThan(original.displayOverviewCamera.width));
    expect(
        detail.camera.height, lessThan(original.displayOverviewCamera.height));
    for (var time = detail.start; time < detail.end; time += 1 / original.fps) {
      final sample = original.sample(time);
      expect(detail.contains(sample.players[detail.actorIndex]!), isTrue,
          reason: 'actor at $time');
      expect(detail.contains(sample.ball, includeHeight: true), isTrue,
          reason: 'ball at $time');
    }
    final end = original.sample(detail.end);
    expect(detail.contains(end.players[detail.actorIndex]!), isTrue);
    expect(detail.contains(end.ball, includeHeight: true), isTrue);
  });

  test('visibility gaps trim the source window and an anchor gap declines it',
      () {
    final source = jsonDecode(
      File(_asset('transition-wing')).readAsStringSync(),
    ) as Map<String, dynamic>;
    final base = RealMatchReplayData.fromJson(source);
    final receive = _step(base, RealMatchReplayStepKind.receive);
    final actor = base.playerIndex(receive.actorId);
    final visibility = List<List<int>>.generate(
      base.frames.length,
      (_) => List<int>.filled(base.players.length, 1),
    );
    final frames = (source['frames'] as List<dynamic>)
        .map((row) => List<int>.from(row as List<dynamic>))
        .toList();
    for (var frame = 94; frame < 100; frame++) {
      visibility[frame][actor] = 0;
      frames[frame][actor * 2] = 0;
      frames[frame][actor * 2 + 1] = 0;
    }
    source['visibility'] = visibility;
    source['frames'] = frames;
    final trimmedData = RealMatchReplayData.fromJson(source);
    final trimmedStep = _step(trimmedData, RealMatchReplayStepKind.receive);
    final trimmed = RealMatchReplayActionDetail.forStep(
      trimmedData,
      trimmedStep,
    )!;
    expect(trimmed.start, closeTo(4, 1e-9));

    final declinedSource = jsonDecode(
      File(_asset('transition-wing')).readAsStringSync(),
    ) as Map<String, dynamic>;
    final declinedBase = RealMatchReplayData.fromJson(declinedSource);
    final usedIds = declinedBase.scene.steps
        .expand<int>((step) => <int>[
              step.actorId,
              if (step.targetId != null) step.targetId!,
              if (step.secondaryId != null) step.secondaryId!,
            ])
        .toSet();
    final spare = declinedBase.players.firstWhere(
      (player) =>
          !usedIds.contains(player.id) &&
          player.id != declinedBase.scene.focusPlayerId,
    );
    final spareIndex = declinedBase.playerIndex(spare.id);
    final declinedSteps = (declinedSource['scene']
        as Map<String, dynamic>)['steps'] as List<dynamic>;
    (declinedSteps.last as Map<String, dynamic>)
      ..['kind'] = 'receive'
      ..['actorId'] = spare.id;
    final anchorFrame = declinedBase.scene.steps.last.time * declinedBase.fps;
    final anchorLower = anchorFrame.floor();
    final anchorUpper = anchorFrame.ceil();
    final declinedVisibility = List<List<int>>.generate(
      declinedBase.frames.length,
      (_) => List<int>.filled(declinedBase.players.length, 1),
    );
    final declinedFrames = (declinedSource['frames'] as List<dynamic>)
        .map((row) => List<int>.from(row as List<dynamic>))
        .toList();
    for (var frame = 0; frame < declinedFrames.length; frame++) {
      if (frame == anchorLower || frame == anchorUpper) continue;
      declinedVisibility[frame][spareIndex] = 0;
      declinedFrames[frame][spareIndex * 2] = 0;
      declinedFrames[frame][spareIndex * 2 + 1] = 0;
    }
    declinedSource['visibility'] = declinedVisibility;
    declinedSource['frames'] = declinedFrames;
    final declinedData = RealMatchReplayData.fromJson(declinedSource);
    expect(
      RealMatchReplayActionDetail.forStep(
        declinedData,
        declinedData.scene.steps.last,
      ),
      isNull,
    );
  });

  test('source endpoints clip safely and replay time is deterministic', () {
    final source = jsonDecode(
      File(_asset('transition-wing')).readAsStringSync(),
    ) as Map<String, dynamic>;
    final scene = source['scene'] as Map<String, dynamic>;
    final steps = scene['steps'] as List<dynamic>;
    final first = steps.first as Map<String, dynamic>;
    first
      ..['kind'] = 'receive'
      ..['time'] = 0.0;
    final data = RealMatchReplayData.fromJson(source);
    final detail = RealMatchReplayActionDetail.forStep(
      data,
      data.scene.steps.first,
    )!;

    expect(detail.start, 0);
    expect(detail.sourceTimeAt(-1), detail.start);
    expect(detail.sourceTimeAt(1), detail.end);
    expect(detail.sourceTimeAt(2), detail.end);
    final playbackDuration = Duration(
      microseconds: (detail.duration /
              RealMatchReplayActionDetail.playbackRate *
              Duration.microsecondsPerSecond)
          .round(),
    );
    expect(detail.sourceTimeAfter(Duration.zero), detail.start);
    expect(detail.sourceTimeAfter(playbackDuration), closeTo(detail.end, 1e-6));
    expect(detail.sourceTimeAfter(playbackDuration),
        detail.sourceTimeAfter(playbackDuration));
  });

  test('historical windows disclose trajectory-only and missing height', () {
    final messi = _scene('messi-right-connection');
    final detail = RealMatchReplayActionDetail.forStep(
      messi,
      _step(messi, RealMatchReplayStepKind.receive),
    )!;

    expect(detail.hasRecordedPose, isFalse);
    expect(detail.poseFidelity, RealMatchReplayDetailPoseFidelity.simplified);
    expect(detail.ballHeightAvailable, isFalse);
    for (var time = detail.start; time <= detail.end; time += 1 / messi.fps) {
      expect(messi.sample(time).ball.z, 0);
    }
  });

  test('all five famous-player scenes expose useful source-only actions', () {
    for (final id in <String>[
      'de-bruyne-pressure-receive',
      'salah-right-recycle',
      'messi-right-connection',
      'kroos-central-recycle',
      'vinicius-carry-inside',
    ]) {
      final data = _scene(id);
      final supported = data.scene.steps
          .map((step) => RealMatchReplayActionDetail.forStep(data, step))
          .whereType<RealMatchReplayActionDetail>()
          .toList();
      expect(supported, isNotEmpty, reason: id);
      expect(supported.every((detail) => !detail.hasRecordedPose), isTrue,
          reason: id);
      expect(supported.every((detail) => detail.duration > 0), isTrue,
          reason: id);
      expect(
        supported.every(
          (detail) =>
              detail.camera.width < data.displayOverviewCamera.width &&
              detail.camera.height < data.displayOverviewCamera.height,
        ),
        isTrue,
        reason: id,
      );
    }
  });

  test('detail derivation does not alter source or display sampling', () {
    final step = _step(original, RealMatchReplayStepKind.receive);
    final beforeSource = original.sample(4.43);
    final beforeDisplay = original.displaySample(4.43);
    RealMatchReplayActionDetail.forStep(original, step);
    final afterSource = original.sample(4.43);
    final afterDisplay = original.displaySample(4.43);

    expect(afterSource.sourceFrame, beforeSource.sourceFrame);
    expect(afterSource.ball.x, beforeSource.ball.x);
    expect(afterSource.ball.y, beforeSource.ball.y);
    expect(afterSource.ball.z, beforeSource.ball.z);
    expect(afterSource.players[0]!.x, beforeSource.players[0]!.x);
    expect(afterDisplay.players[0]!.x, beforeDisplay.players[0]!.x);
    expect(afterDisplay.reconstructed, beforeDisplay.reconstructed);
  });
}

RealMatchReplayData _scene(String id) => RealMatchReplayData.fromJsonString(
      File(_asset(id)).readAsStringSync(),
    );

String _asset(String id) => 'assets/scan_pass_replay/scenes/$id.json';

RealMatchReplayStep _step(
  RealMatchReplayData data,
  RealMatchReplayStepKind kind,
) =>
    data.scene.steps.firstWhere((step) => step.kind == kind);

double _distance(RealMatchReplayPoint a, RealMatchReplayPoint b) {
  final dx = b.x - a.x;
  final dy = b.y - a.y;
  return math.sqrt(dx * dx + dy * dy);
}

double _heading(RealMatchReplayPoint a, RealMatchReplayPoint b) =>
    math.atan2(b.y - a.y, b.x - a.x);

double _angleDelta(double a, double b) {
  var value = b - a;
  while (value > math.pi) {
    value -= math.pi * 2;
  }
  while (value < -math.pi) {
    value += math.pi * 2;
  }
  return value;
}
