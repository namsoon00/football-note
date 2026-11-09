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
    expect(catalog.version, 3);
    expect(catalog.scenes.first.id, '1925299-185-560983-thirdPlayer');
    expect(catalog.matchCount, catalog.matchIds.length);
    expect(catalog.sourcePins, hasLength(5));
    expect(
      catalog.scenes.map((scene) => scene.education!.objective).toSet(),
      SpatialLearningObjective.values.toSet(),
    );
    expect(catalog.scenes.map((scene) => scene.season).toSet(),
        {'2019/20', '2022', '2024/25'});
    expect(
      catalog.matchIds,
      containsAll(<int>{3857, 10507, 10517, 1925299, 1996435}),
    );
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

  test('PFF clips keep provider event links and missing observations', () {
    final proof = _json('assets/scan_pass_spatial/worldcup-proof.json');
    final worldCup = catalog.scenes.where((scene) => scene.season == '2022');
    expect(worldCup, hasLength(4));
    expect(proof['candidateCount'], 24);
    expect(proof['sceneCount'], 4);
    expect(proof['rejectedCandidates'], hasLength(20));
    expect(
      worldCup.map((scene) => scene.matchId).toSet(),
      <int>{3857, 10507, 10517},
    );
    expect(catalog.scenes.take(70).every((scene) => scene.season != '2022'),
        isTrue);
    var sawHiddenBall = false;
    for (final scene in worldCup) {
      final replay = _replay(scene);
      final lesson = scene.education!;
      expect(replay.fps, 29.97, reason: scene.id);
      expect(scene.duration, inInclusiveRange(15, 40), reason: scene.id);
      expect(lesson.movementStart, greaterThanOrEqualTo(4), reason: scene.id);
      expect(scene.duration - lesson.outcome, greaterThanOrEqualTo(4),
          reason: scene.id);
      expect(replay.visibility.every((row) => row.contains(1)), isTrue,
          reason: scene.id);
      expect(scene.education!.sourceConnectionEventIds, isNotEmpty,
          reason: scene.id);
      expect(
        replay.events.map((event) => event.id).toSet(),
        scene.education!.sourceConnectionEventIds.toSet(),
        reason: scene.id,
      );
      if (replay.ballVisibility.contains(0)) {
        sawHiddenBall = true;
        final hiddenFrame = replay.ballVisibility.indexOf(0);
        expect(replay.sample(hiddenFrame / replay.fps).ballVisible, isFalse,
            reason: scene.id);
      }
      expect(() => scene.validateReplay(replay), returnsNormally,
          reason: scene.id);
    }
    expect(sawHiddenBall, isTrue);
  });

  test('World Cup source association and localized aliases are searchable', () {
    final worldCup = catalog.scenes.where((scene) => scene.season == '2022');
    for (final query in <String>['World Cup', '월드컵', 'ワールドカップ']) {
      final matches = catalog.scenes
          .where((scene) => scene.matchesSearch(query))
          .toList(growable: false);
      expect(matches.map((scene) => scene.id).toSet(),
          worldCup.map((scene) => scene.id).toSet(),
          reason: query);
    }

    for (final entry in <(String, bool Function(SpatialLibraryScene))>[
      (
        '대한민국',
        (scene) => <String>{scene.home, scene.away}.contains('South Korea')
      ),
      (
        '한국',
        (scene) => <String>{scene.home, scene.away}.contains('South Korea')
      ),
      ('손흥민', (scene) => scene.involvesPlayer('Heung-min Son')),
      ('음바페', (scene) => scene.involvesPlayer('Kylian Mbappé')),
      ('호날두', (scene) => scene.involvesPlayer('Cristiano Ronaldo')),
      ('네이마르', (scene) => scene.involvesPlayer('Neymar')),
    ]) {
      final matches = worldCup
          .where((scene) => scene.matchesSearch(entry.$1))
          .toList(growable: false);
      expect(matches, isNotEmpty, reason: entry.$1);
      expect(matches.every(entry.$2), isTrue, reason: entry.$1);
    }
  });

  test('PFF connection identity and source hashes fail closed', () {
    final target = catalog.scenes.firstWhere((scene) => scene.season == '2022');
    final badConnection =
        _catalogWithSceneMutation(source, target.id, (learning) {
      (learning['sourceConnectionEventIds'] as List<dynamic>)[0] =
          'pff:tampered:event';
    });
    expect(
      () => badConnection.scenes
          .firstWhere((scene) => scene.id == target.id)
          .validateReplay(_replay(target)),
      throwsFormatException,
    );

    final badPin = _copy(source);
    final pffPin = (badPin['sourcePins'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .firstWhere((pin) => pin['provider'] == 'PFF FC');
    (pffPin['sourceFiles'] as List<dynamic>).first['sha256'] = 'not-a-hash';
    expect(() => SpatialLibraryCatalog.fromJson(badPin), throwsFormatException);
  });

  test('every shipped lesson recomputes from its loaded observed replay', () {
    for (final scene in catalog.scenes) {
      final data = _replay(scene);
      expect(() => scene.validateReplay(data), returnsNormally,
          reason: scene.id);
      expect(data.hasDisplayReconstruction, isFalse, reason: scene.id);
      expect(data.hasAuditedBallHeight, isTrue, reason: scene.id);
      expect(data.ballHeightValidity, hasLength(data.frames.length));
      expect(
        data.ballHeightValidity.contains(1),
        isTrue,
        reason: scene.id,
      );
      expect(
        scene.asset,
        startsWith('assets/scan_pass_spatial/education_scenes/'),
      );
      if (scene.season == '2024/25') {
        expect(data.ballVisibility.every((value) => value == 1), isTrue,
            reason: scene.id);
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

  test('source actions retain nullable provider evidence and safe coverage',
      () {
    final recent = catalog.scenes.where(
      (scene) =>
          scene.sourceCommit ==
          SpatialLibraryCatalog.expectedRecentSourceCommit,
    );
    final historical = catalog.scenes.where(
      (scene) =>
          scene.sourceCommit !=
          SpatialLibraryCatalog.expectedRecentSourceCommit,
    );
    final actions = recent.expand((scene) => scene.sourceActions).toList();

    expect(catalog.actionProofVersion,
        SpatialSourceActionEvidence.expectedProofVersion);
    expect(historical.every((scene) => scene.sourceActions.isEmpty), isTrue);
    expect(actions, hasLength(375));
    expect(
      actions.where((action) => action.geometry.carryOnsetFrame != null),
      hasLength(45),
    );
    expect(
      actions
          .where((action) => action.geometry.directionChangeOnsetFrame != null),
      hasLength(4),
    );
    final headers = actions.where(
      (action) => action.supports(SpatialOnPitchActionKind.header),
    );
    expect(headers, hasLength(8));
    expect(headers.every((action) => action.flags.isHeader == true), isTrue);
    expect(
      actions.where((action) => action.flags.oneTouch == false),
      isNotEmpty,
      reason: 'false provider flags must never become confident actions',
    );
  });

  test('every action kind starts at reached source time and seeking is stable',
      () {
    final cases = <(SpatialOnPitchActionKind, String, String, int)>[
      (
        SpatialOnPitchActionKind.receive,
        '1925299-185-560983-thirdPlayer',
        '8_5',
        202,
      ),
      (
        SpatialOnPitchActionKind.carry,
        '1925299-185-560983-thirdPlayer',
        '8_5',
        209,
      ),
      (
        SpatialOnPitchActionKind.oneTouchPass,
        '1925299-185-560983-thirdPlayer',
        '8_8',
        265,
      ),
      (
        SpatialOnPitchActionKind.header,
        '1925299-185-560983-thirdPlayer',
        '8_9',
        281,
      ),
      (
        SpatialOnPitchActionKind.directionChange,
        '1925299-35928-560882-receivingLane',
        '8_646',
        36040,
      ),
    ];
    for (final (kind, sceneId, eventId, sourceFrame) in cases) {
      final scene = catalog.scenes.firstWhere((value) => value.id == sceneId);
      final data = _replay(scene);
      final onset = (sourceFrame - scene.startFrame) / data.fps;
      final before = scene.sourceActionAt(data, onset - 1 / data.fps);
      final current = scene.sourceActionAt(data, onset);
      final repeated = scene.sourceActionAt(data, onset);

      expect(
        (before?.eventId, before?.kind),
        isNot((eventId, kind)),
        reason: '$kind must never appear one source frame early',
      );
      expect((current?.eventId, current?.kind), (eventId, kind));
      expect((repeated?.eventId, repeated?.kind), (eventId, kind));
    }
  });

  test('header wins over one touch and valid null-owner contact lingers', () {
    final scene = catalog.scenes.firstWhere(
      (value) => value.id == '1925299-185-560983-thirdPlayer',
    );
    final data = _replay(scene);
    final atHeader = scene.sourceActionAt(data, 19);
    final afterHeader = scene.sourceActionAt(data, 20);
    expect((atHeader?.eventId, atHeader?.kind),
        ('8_9', SpatialOnPitchActionKind.header));
    expect((afterHeader?.eventId, afterHeader?.kind),
        ('8_9', SpatialOnPitchActionKind.header));
    expect(
      scene.sourceActions
          .firstWhere((action) => action.eventId == '8_9')
          .flags
          .oneTouch,
      isTrue,
      reason: 'the same provider event is one-touch but header has priority',
    );
    expect(
      data.sourcePossessionOwners[190],
      isNull,
      reason: 'headers do not require tracking ownership at contact',
    );
  });

  test('instant actions require observed actor and ball at source contact', () {
    final hiddenScene = catalog.scenes.firstWhere(
      (value) => value.id == '1996435-24085-25534-thirdPlayer',
    );
    final hiddenData = _replay(hiddenScene);
    expect(
        hiddenScene.sourceActionAt(hiddenData, 1.4)?.eventId, isNot('8_489'));
    expect(
      hiddenScene.sourceActionAt(hiddenData, 1.6)?.eventId,
      isNot('8_489'),
      reason: 'later actor reappearance cannot repair hidden source contact',
    );

    final separatedScene = catalog.scenes.firstWhere(
      (value) => value.id == '1996435-7549-25534-thirdPlayer',
    );
    final separatedData = _replay(separatedScene);
    expect(
      separatedScene.sourceActionAt(separatedData, 5)?.eventId,
      isNot('8_172'),
      reason: 'the source contact is 3.574 m from the observed ball',
    );
    expect(
      separatedScene.sourceActionAt(separatedData, 5.5)?.eventId,
      isNot('8_172'),
      reason: 'the label must stay hidden if the actor later gets closer',
    );

    final validScene = catalog.scenes.firstWhere(
      (value) => value.id == '1925299-185-560983-thirdPlayer',
    );
    final hiddenBallJson = _json(validScene.asset);
    (hiddenBallJson['ballVisibility'] as List<dynamic>)[190] = 0;
    final hiddenBallData = RealMatchReplayData.fromJson(hiddenBallJson);
    expect(
      validScene.sourceActionAt(hiddenBallData, 19)?.eventId,
      isNot('8_9'),
      reason: 'missing ball at the original source contact fails closed',
    );

    expect(
      validScene.sourceActionAt(_replay(validScene), 19)?.eventId,
      '8_9',
      reason: 'the adjacent valid source frame remains index-safe',
    );
  });

  test('known one-touch receptions are not labelled as receives', () {
    for (final endType in <String>['shot', 'clearance']) {
      final changed = _copy(source);
      final sceneJson = (changed['scenes'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .firstWhere(
            (value) => value['id'] == '1925299-185-560983-thirdPlayer',
          );
      final actionJson = (sceneJson['sourceActions'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .firstWhere((value) => value['eventId'] == '8_5');
      (actionJson['flags'] as Map<String, dynamic>)['oneTouch'] = true;
      actionJson['endType'] = endType;
      final changedScene =
          SpatialLibraryCatalog.fromJson(changed).scenes.firstWhere(
                (value) => value.id == '1925299-185-560983-thirdPlayer',
              );
      final action = changedScene.sourceActions
          .firstWhere((value) => value.eventId == '8_5');

      expect(action.supports(SpatialOnPitchActionKind.receive), isFalse);
      expect(action.supports(SpatialOnPitchActionKind.oneTouchPass), isFalse);
      expect(
        changedScene.sourceActionAt(_replay(changedScene), 11.1)?.eventId,
        isNot('8_5'),
        reason: 'a known first-time $endType is not a trapping-like receive',
      );
    }

    final nullable = _copy(source);
    final nullableSceneJson = (nullable['scenes'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .firstWhere(
          (value) => value['id'] == '1925299-185-560983-thirdPlayer',
        );
    final nullableActionJson =
        (nullableSceneJson['sourceActions'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .firstWhere((value) => value['eventId'] == '8_5');
    (nullableActionJson['flags'] as Map<String, dynamic>)['oneTouch'] = null;
    nullableActionJson['endType'] = 'shot';
    final nullableAction = SpatialLibraryCatalog.fromJson(nullable)
        .scenes
        .firstWhere(
          (value) => value.id == '1925299-185-560983-thirdPlayer',
        )
        .sourceActions
        .firstWhere((value) => value.eventId == '8_5');
    expect(nullableAction.supports(SpatialOnPitchActionKind.receive), isTrue);
    expect(
      nullableAction.supports(SpatialOnPitchActionKind.oneTouchPass),
      isFalse,
      reason: 'a null provider flag stays unknown, never confident one-touch',
    );
  });

  test('receive uses incoming previous-pass match, not outgoing reception', () {
    final incomingScene = catalog.scenes.firstWhere(
      (value) => value.id == '1925299-21757-51043-thirdPlayer',
    );
    final incoming = incomingScene.sourceActions.firstWhere(
      (value) => value.eventId == '8_373',
    );
    expect(incoming.matched.previousPass, isTrue);
    expect(incoming.matched.passReception, isFalse);
    expect(incoming.supports(SpatialOnPitchActionKind.receive), isTrue);

    final changed = _copy(source);
    final outgoingSceneJson = (changed['scenes'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .firstWhere(
          (value) => value['id'] == '1925299-24011-287934-receivingLane',
        );
    final outgoingJson = (outgoingSceneJson['sourceActions'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .firstWhere((value) => value['eventId'] == '8_433');
    (outgoingJson['flags'] as Map<String, dynamic>)['oneTouch'] = false;
    final outgoing = SpatialLibraryCatalog.fromJson(changed)
        .scenes
        .firstWhere(
          (value) => value.id == '1925299-24011-287934-receivingLane',
        )
        .sourceActions
        .firstWhere((value) => value.eventId == '8_433');
    expect(outgoing.matched.previousPass, isFalse);
    expect(outgoing.matched.passReception, isTrue);
    expect(outgoing.supports(SpatialOnPitchActionKind.receive), isFalse);
  });

  test('stationary and off-ball carry evidence fail observed validation', () {
    final scene = catalog.scenes.firstWhere(
      (value) => value.id == '1925299-12334-11897-thirdPlayer',
    );
    final action = scene.sourceActions.firstWhere(
      (value) => value.eventId == '8_250',
    );
    final actorIndex = _playerIndex(_json(scene.asset), action.playerId);
    final first = action.sourceStartFrame - scene.startFrame;
    final last = action.sourceEndFrame - scene.startFrame;

    final stationaryJson = _json(scene.asset);
    final stationaryFrames = stationaryJson['frames'] as List<dynamic>;
    final startRow = stationaryFrames[first] as List<dynamic>;
    for (var frame = first + 1; frame <= last; frame++) {
      final row = stationaryFrames[frame] as List<dynamic>;
      row[actorIndex * 2] = startRow[actorIndex * 2];
      row[actorIndex * 2 + 1] = startRow[actorIndex * 2 + 1];
    }
    expect(
      () => scene.validateReplay(RealMatchReplayData.fromJson(stationaryJson)),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('source action geometry'),
        ),
      ),
    );

    final offBallJson = _json(scene.asset);
    (offBallJson['sourcePossessionOwners'] as List<dynamic>)[first] = null;
    expect(
      () => scene.validateReplay(RealMatchReplayData.fromJson(offBallJson)),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('source action geometry'),
        ),
      ),
    );
  });

  test(
      'malformed flags reject parsing and unsupported header combination hides',
      () {
    final malformed = _copy(source);
    final malformedScene = (malformed['scenes'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .firstWhere(
          (value) => value['id'] == '1925299-185-560983-thirdPlayer',
        );
    final malformedAction = (malformedScene['sourceActions'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .firstWhere((value) => value['eventId'] == '8_9');
    (malformedAction['flags'] as Map<String, dynamic>)['isHeader'] = 'True';
    expect(
      () => SpatialLibraryCatalog.fromJson(malformed),
      throwsFormatException,
    );

    final unsupported = _copy(source);
    final unsupportedSceneJson = (unsupported['scenes'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .firstWhere(
          (value) => value['id'] == '1925299-185-560983-thirdPlayer',
        );
    final unsupportedAction =
        (unsupportedSceneJson['sourceActions'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .firstWhere((value) => value['eventId'] == '8_9');
    (unsupportedAction['flags'] as Map<String, dynamic>)['handPass'] = true;
    final unsupportedCatalog = SpatialLibraryCatalog.fromJson(unsupported);
    final unsupportedScene = unsupportedCatalog.scenes.firstWhere(
      (value) => value.id == '1925299-185-560983-thirdPlayer',
    );
    expect(
      unsupportedScene.sourceActionAt(_replay(unsupportedScene), 19)?.eventId,
      isNot('8_9'),
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
