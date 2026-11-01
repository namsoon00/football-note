import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/scan_pass/real_match_replay.dart';
import 'package:football_note/domain/scan_pass/scan_pass_spatial_library.dart';

void main() {
  late Map<String, dynamic> source;
  late SpatialLibraryCatalog catalog;

  setUpAll(() {
    source = _json('assets/scan_pass_spatial/education-catalog.json');
    catalog = SpatialLibraryCatalog.fromJson(_copy(source));
  });

  test('education catalogue is mixed-source, evidence-led, and complete', () {
    final proof = _json('assets/scan_pass_spatial/education-proof.json');
    expect(catalog.version, 2);
    expect(catalog.matchCount, catalog.matchIds.length);
    expect(catalog.sourcePins, hasLength(2));
    expect(
      catalog.scenes.map((scene) => scene.education!.objective).toSet(),
      SpatialLearningObjective.values.toSet(),
    );
    expect(catalog.scenes.map((scene) => scene.season).toSet(),
        {'2019/20', '2024/25'});
    expect(catalog.matchIds, containsAll(<int>{1925299, 1996435}));
    for (final scene in catalog.scenes.where(
      (scene) =>
          scene.education!.objective == SpatialLearningObjective.receivingLane,
    )) {
      final lesson = scene.education!;
      expect(lesson.beforeValue, lessThanOrEqualTo(25.001), reason: scene.id);
      expect(
        lesson.baselinePassLineGapMeters,
        lessThanOrEqualTo(3.001),
        reason: scene.id,
      );
      expect(
        lesson.afterPassLineGapMeters! - lesson.baselinePassLineGapMeters!,
        greaterThanOrEqualTo(.49),
        reason: scene.id,
      );
      expect(
        lesson.receiverLineGapContributionMeters,
        greaterThanOrEqualTo(.24),
        reason: scene.id,
      );
    }
    expect(proof['archiveAudit'], hasLength(72));
    expect(
      (proof['archiveAudit'] as List<dynamic>)
          .where((value) => !(value as Map<String, dynamic>)['accepted'])
          .isNotEmpty,
      isTrue,
      reason: 'the archive cannot silently remain a 72-scene menu',
    );
  });

  test('every shipped lesson recomputes from its loaded observed replay', () {
    for (final scene in catalog.scenes) {
      final data = _replay(scene);
      expect(() => scene.validateReplay(data), returnsNormally,
          reason: scene.id);
      expect(data.hasDisplayReconstruction, isFalse, reason: scene.id);
      expect(data.ballHeightAvailable, isFalse, reason: scene.id);
      if (scene.season == '2024/25') {
        expect(data.ballVisibility.every((value) => value == 1), isTrue,
            reason: scene.id);
        expect(
          scene.asset,
          startsWith('assets/scan_pass_spatial/education_scenes/'),
        );
      } else {
        expect(scene.asset, startsWith('assets/scan_pass_spatial/scenes/'));
      }
    }
  });

  test('mixed-source pins reject an unallowlisted commit or stale match count',
      () {
    final badCommit = _copy(source);
    (badCommit['sourcePins'] as List<dynamic>)[1]['commit'] =
        List<String>.filled(40, '0').join();
    expect(
      () => SpatialLibraryCatalog.fromJson(badCommit),
      throwsFormatException,
    );

    final staleCount = _copy(source)..['matchCount'] = 999;
    expect(
      () => SpatialLibraryCatalog.fromJson(staleCount),
      throwsFormatException,
    );
  });

  test('tampered measurements and late movement fail replay validation', () {
    final target = catalog.scenes.firstWhere(
      (scene) =>
          scene.education!.objective == SpatialLearningObjective.receivingLane,
    );
    final data = _replay(target);

    final tampered = _catalogWithSceneMutation(source, target.id, (learning) {
      final measurements = learning['measurements'] as Map<String, dynamic>;
      measurements['after'] = measurements['before'];
      measurements['improvement'] = 0.0;
    });
    final tamperedScene = tampered.scenes.firstWhere((s) => s.id == target.id);
    expect(() => tamperedScene.validateReplay(data), throwsFormatException);

    final late = _catalogWithSceneMutation(source, target.id, (learning) {
      final trigger = (learning['trigger'] as num).toDouble();
      learning['movementStart'] = trigger - .1;
      final frames = learning['sourceFrames'] as Map<String, dynamic>;
      frames['movementStart'] =
          target.startFrame + ((trigger - .1) * data.fps).round();
    });
    final lateScene = late.scenes.firstWhere((s) => s.id == target.id);
    expect(() => lateScene.validateReplay(data), throwsFormatException);
  });

  test('missing support, hidden evidence, and ABA third-player labels fail',
      () {
    final receiving = catalog.scenes.firstWhere(
      (scene) =>
          scene.education!.objective == SpatialLearningObjective.receivingLane,
    );
    final missingSupport =
        _catalogWithSceneMutation(source, receiving.id, (learning) {
      learning['supportActors'] = <dynamic>[];
    });
    expect(
      () => missingSupport.scenes
          .firstWhere((scene) => scene.id == receiving.id)
          .validateReplay(_replay(receiving)),
      throwsFormatException,
    );

    final hiddenJson = _json(receiving.asset);
    final focusId = receiving.education!.focusActor.playerId;
    final playerIndex = (hiddenJson['players'] as List<dynamic>)
        .indexWhere((value) => value['id'] == focusId);
    final frame =
        (receiving.education!.movementStart * hiddenJson['fps']).round();
    hiddenJson['visibility'][frame][playerIndex] = 0;
    hiddenJson['frames'][frame][playerIndex * 2] =
        hiddenJson['missingPlayerCoordinate'];
    hiddenJson['frames'][frame][playerIndex * 2 + 1] =
        hiddenJson['missingPlayerCoordinate'];
    final hidden = RealMatchReplayData.fromJson(hiddenJson);
    expect(() => receiving.validateReplay(hidden), throwsFormatException);

    final third = catalog.scenes.firstWhere(
      (scene) =>
          scene.education!.objective == SpatialLearningObjective.thirdPlayer,
    );
    final aba = _catalogWithSceneMutation(source, third.id, (learning) {
      final focus = _copyMap(learning['focusActor']);
      (learning['supportActors'] as List<dynamic>)[0] = focus;
    });
    expect(
      () => aba.scenes
          .firstWhere((scene) => scene.id == third.id)
          .validateReplay(_replay(third)),
      throwsFormatException,
    );
  });

  test('lane proof rejects an off-segment defender and stationary receiver',
      () {
    final receiving = catalog.scenes.firstWhere(
      (scene) =>
          scene.education!.objective == SpatialLearningObjective.receivingLane,
    );
    final lesson = receiving.education!;

    final beyondJson = _json(receiving.asset);
    final focusIndex = _playerIndex(beyondJson, lesson.focusActor.playerId);
    final passerIndex =
        _playerIndex(beyondJson, lesson.supportActors.first.playerId);
    final defenderIndex =
        _playerIndex(beyondJson, lesson.opponentActors.single.playerId);
    for (final time in <double>[lesson.movementStart, lesson.trigger]) {
      final frame = (time * (beyondJson['fps'] as num)).round();
      final row =
          (beyondJson['frames'] as List<dynamic>)[frame] as List<dynamic>;
      final receiverX = (row[focusIndex * 2] as num).toInt();
      final receiverY = (row[focusIndex * 2 + 1] as num).toInt();
      final passerX = (row[passerIndex * 2] as num).toInt();
      final passerY = (row[passerIndex * 2 + 1] as num).toInt();
      row[defenderIndex * 2] = receiverX + (receiverX - passerX);
      row[defenderIndex * 2 + 1] = receiverY + (receiverY - passerY);
    }
    expect(
      () => receiving.validateReplay(RealMatchReplayData.fromJson(beyondJson)),
      throwsFormatException,
    );

    final farLateralJson = _json(receiving.asset);
    for (final time in <double>[lesson.movementStart, lesson.trigger]) {
      final frame = (time * (farLateralJson['fps'] as num)).round();
      final row =
          (farLateralJson['frames'] as List<dynamic>)[frame] as List<dynamic>;
      final receiverX = (row[focusIndex * 2] as num).toDouble();
      final receiverY = (row[focusIndex * 2 + 1] as num).toDouble();
      final passerX = (row[passerIndex * 2] as num).toDouble();
      final passerY = (row[passerIndex * 2 + 1] as num).toDouble();
      final dx = receiverX - passerX;
      final dy = receiverY - passerY;
      final length = math.sqrt(dx * dx + dy * dy);
      row[defenderIndex * 2] =
          ((passerX + receiverX) / 2 - dy / length * 1000).round();
      row[defenderIndex * 2 + 1] =
          ((passerY + receiverY) / 2 + dx / length * 1000).round();
    }
    expect(
      () => receiving
          .validateReplay(RealMatchReplayData.fromJson(farLateralJson)),
      throwsFormatException,
      reason: 'projection 0.5 is insufficient when the defender is 10m wide',
    );

    final stationaryJson = _json(receiving.asset);
    final startFrame =
        (lesson.movementStart * (stationaryJson['fps'] as num)).round();
    final triggerFrame =
        (lesson.trigger * (stationaryJson['fps'] as num)).round();
    final frames = stationaryJson['frames'] as List<dynamic>;
    final startRow = frames[startFrame] as List<dynamic>;
    final triggerRow = frames[triggerFrame] as List<dynamic>;
    triggerRow[focusIndex * 2] = startRow[focusIndex * 2];
    triggerRow[focusIndex * 2 + 1] = startRow[focusIndex * 2 + 1];
    expect(
      () => receiving
          .validateReplay(RealMatchReplayData.fromJson(stationaryJson)),
      throwsFormatException,
    );
  });

  test('interception, hidden ball, and wrong-team roles fail validation', () {
    for (final objective in <SpatialLearningObjective>[
      SpatialLearningObjective.pressureOutlet,
      SpatialLearningObjective.thirdPlayer,
    ]) {
      final scene = catalog.scenes.firstWhere(
        (value) => value.education!.objective == objective,
      );
      final lesson = scene.education!;
      final replayJson = _json(scene.asset);
      final fps = (replayJson['fps'] as num).toInt();
      final start = (lesson.trigger * fps).round() + 1;
      final end = ((lesson.nextConnection ?? lesson.outcome) * fps).round();
      final visibility = replayJson['visibility'] as List<dynamic>;
      final players = replayJson['players'] as List<dynamic>;
      final focusHome = (players[_playerIndex(
        replayJson,
        lesson.focusActor.playerId,
      )] as Map<String, dynamic>)['home'];
      final frame = List<int>.generate(end - start, (index) => start + index)
          .firstWhere((value) {
        final flags = visibility[value] as List<dynamic>;
        return players.indexed.any((entry) =>
            (entry.$2 as Map<String, dynamic>)['home'] != focusHome &&
            (flags[entry.$1] as num) == 1);
      });
      final flags = visibility[frame] as List<dynamic>;
      final opponentIndex = players.indexed
          .firstWhere((entry) =>
              (entry.$2 as Map<String, dynamic>)['home'] != focusHome &&
              (flags[entry.$1] as num) == 1)
          .$1;
      final opponentId =
          (players[opponentIndex] as Map<String, dynamic>)['id'] as int;
      (replayJson['sourcePossessionOwners'] as List<dynamic>)[frame] =
          opponentId;
      expect(
        () => scene.validateReplay(RealMatchReplayData.fromJson(replayJson)),
        throwsFormatException,
        reason: '$objective cannot skip an opposing possession',
      );
    }

    final target = catalog.scenes.first;
    final hiddenBallJson = _json(target.asset);
    final hiddenFrame =
        (target.education!.trigger * (hiddenBallJson['fps'] as num)).round();
    (hiddenBallJson['ballVisibility'] as List<dynamic>)[hiddenFrame] = 0;
    expect(
      () => target.validateReplay(RealMatchReplayData.fromJson(hiddenBallJson)),
      throwsFormatException,
    );

    final wrongTeam = _catalogWithSceneMutation(source, target.id, (learning) {
      learning['opponentActors'] = <dynamic>[
        _copyMap((learning['supportActors'] as List<dynamic>).first),
      ];
    });
    expect(
      () => wrongTeam.scenes
          .firstWhere((scene) => scene.id == target.id)
          .validateReplay(_replay(target)),
      throwsFormatException,
    );
  });
}

int _playerIndex(Map<String, dynamic> replay, int playerId) =>
    (replay['players'] as List<dynamic>).indexWhere(
      (value) => (value as Map<String, dynamic>)['id'] == playerId,
    );

SpatialLibraryCatalog _catalogWithSceneMutation(
  Map<String, dynamic> source,
  String id,
  void Function(Map<String, dynamic> learning) mutate,
) {
  final changed = _copy(source);
  final scene = (changed['scenes'] as List<dynamic>)
      .cast<Map<String, dynamic>>()
      .firstWhere((value) => value['id'] == id);
  mutate(scene['learning'] as Map<String, dynamic>);
  return SpatialLibraryCatalog.fromJson(changed);
}

RealMatchReplayData _replay(SpatialLibraryScene scene) =>
    RealMatchReplayData.fromJsonString(File(scene.asset).readAsStringSync());

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

Map<String, dynamic> _copy(Map<String, dynamic> value) =>
    jsonDecode(jsonEncode(value)) as Map<String, dynamic>;

Map<String, dynamic> _copyMap(Object? value) =>
    jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
