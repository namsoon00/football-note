import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/scan_pass/real_match_replay.dart';

void main() {
  late RealMatchReplayCatalog catalog;
  late Map<String, RealMatchReplayData> scenes;

  setUpAll(() {
    catalog = RealMatchReplayCatalog.fromJsonString(
      File('assets/scan_pass_replay/catalog.json').readAsStringSync(),
    );
    scenes = <String, RealMatchReplayData>{
      for (final entry in catalog.scenes)
        entry.id: RealMatchReplayData.fromJsonString(
          File(entry.asset).readAsStringSync(),
        ),
    };
  });

  test('catalog exposes 25 distinct scenes across every category', () {
    expect(catalog.version, 1);
    expect(catalog.scenes, hasLength(25));
    expect(
      catalog.scenes.map((scene) => scene.id).toSet(),
      hasLength(25),
    );
    expect(
      catalog.scenes.map((scene) => scene.category).toSet(),
      RealMatchReplayCategory.values.toSet(),
    );
    expect(
      scenes.values.map((scene) => scene.scene.attackDirection).toSet(),
      containsAll(<int>{-1, 1}),
    );
    expect(
      scenes.values.map((scene) => scene.duration).toSet().length,
      greaterThan(5),
    );
    expect(
      scenes.values.map((scene) => scene.scene.homeColor).toSet().length,
      greaterThan(1),
    );
    expect(
      catalog.scenes.take(5).map((scene) => scene.id),
      orderedEquals(<String>[
        'de-bruyne-pressure-receive',
        'salah-right-recycle',
        'messi-right-connection',
        'kroos-central-recycle',
        'vinicius-carry-inside',
      ]),
    );
    expect(
      catalog.scenes.skip(5).map((scene) => scene.id),
      containsAll(<String>[
        'transition-wing',
        'keeper-build',
        'central-build',
        'carry-turnover',
      ]),
    );
  });

  test('mixed revisions and source URLs match every scene payload', () {
    const historicalCommit = '1ed50b775f93075c2a6d00d0d795f13b7b89709e';
    const currentCommit = '4340d274572876239c154c90bc507a9b3250a656';
    expect(catalog.sourceCommit, currentCommit);
    expect(catalog.scenes.take(5).map((scene) => scene.sourceCommit).toSet(),
        <String>{historicalCommit});
    expect(catalog.scenes.skip(5).map((scene) => scene.sourceCommit).toSet(),
        <String>{currentCommit});
    for (final entry in catalog.scenes) {
      final data = scenes[entry.id]!;
      expect(data.sourceCommit, entry.sourceCommit, reason: entry.id);
      expect(data.sourceUrl, entry.sourceUrl, reason: entry.id);
      expect(Uri.parse(data.sourceUrl).isScheme('https'), isTrue,
          reason: entry.id);
      if (entry.sourceCommit == historicalCommit) {
        expect(Uri.parse(data.sourceUrl).host, 'github.com');
        expect(data.sourceUrl, endsWith('/data/matches/${entry.matchId}'));
      }
    }
  });

  test(
      'historical roster uses trackable ids, real numbers, names and kit colors',
      () {
    final deBruyne = scenes['de-bruyne-pressure-receive']!;
    final salah = scenes['salah-right-recycle']!;
    final messi = scenes['messi-right-connection']!;
    final kroos = scenes['kroos-central-recycle']!;
    final vinicius = scenes['vinicius-carry-inside']!;

    expect(deBruyne.player(5821).name, 'Kevin de Bruyne');
    expect(deBruyne.player(5821).number, 17);
    expect(salah.player(7745).name, 'Mohamed Salah');
    expect(salah.player(7745).number, 11);
    expect(messi.player(6260).name, 'Lionel Messi');
    expect(messi.player(6260).number, 10);
    expect(kroos.player(10530).name, 'Toni Kroos');
    expect(kroos.player(10530).number, 8);
    expect(vinicius.player(12397).name, 'Junior Vinicius');
    expect(vinicius.player(12397).number, 25);
    expect(deBruyne.scene.homeColor, '#00fff5');
    expect(deBruyne.scene.awayColor, '#c10021');
    expect(messi.scene.homeColor, '#ffffff');
    expect(messi.scene.awayColor, '#0500cf');
    for (final data
        in catalog.scenes.take(5).map((entry) => scenes[entry.id]!)) {
      expect(data.players, hasLength(22), reason: data.scene.id);
      expect(data.players.where((player) => player.home), hasLength(11),
          reason: data.scene.id);
      expect(data.players.where((player) => !player.home), hasLength(11),
          reason: data.scene.id);
      expect(data.players.every((player) => player.identified), isTrue,
          reason: data.scene.id);
      expect(data.players.where((player) => player.keeper), hasLength(2),
          reason: data.scene.id);
    }
  });

  test('historical proof pins hashes, coordinates, coverage and rationale', () {
    final manifest = jsonDecode(
      File('assets/scan_pass_replay/historical-source-manifest.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    final proof = jsonDecode(
      File('assets/scan_pass_replay/historical-catalog-proof.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    expect(manifest['commit'], '1ed50b775f93075c2a6d00d0d795f13b7b89709e');
    expect((manifest['files'] as List<dynamic>), hasLength(6));
    expect((proof['scenes'] as List<dynamic>), hasLength(5));
    for (final value in manifest['derivedAssets'] as List<dynamic>) {
      final entry = value as Map<String, dynamic>;
      final path = File(entry['path'] as String);
      expect(path.lengthSync(), entry['bytes'],
          reason: entry['path'] as String);
      expect(sha256.convert(path.readAsBytesSync()).toString(), entry['sha256'],
          reason: entry['path'] as String);
    }
    for (final value in proof['scenes'] as List<dynamic>) {
      final entry = value as Map<String, dynamic>;
      expect(entry['ballXYObservations'], entry['frames'],
          reason: entry['id'] as String);
      expect(entry['maxPositionQuantizationErrorMeters'],
          lessThanOrEqualTo(.005001));
      expect(entry['maxPlayerSpeedMetersPerSecond'], lessThan(15));
      expect(entry['maxDisplaySpeedMetersPerSecond'], lessThan(15));
      expect(entry['annotationRationale'], isNotEmpty);
      expect(entry['rosterMapping'], isNotEmpty);
      expect(entry['coverageDecision'], isNotEmpty);
      final reconstruction =
          entry['displayReconstruction'] as Map<String, dynamic>;
      expect(reconstruction['contextRadiusFrames'], 600);
      expect(reconstruction['players'], hasLength(22));
      expect(
        (reconstruction['players'] as List<dynamic>).every((value) {
          final player = value as Map<String, dynamic>;
          return (player['observedFrames'] as int) +
                  (player['inferredFrames'] as int) ==
              entry['frames'];
        }),
        isTrue,
      );
    }
    final currentProof = jsonDecode(
      File('assets/scan_pass_replay/catalog-proof.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    for (final value in currentProof['scenes'] as List<dynamic>) {
      final scene = value as Map<String, dynamic>;
      final path = File(scene['asset'] as String);
      expect(sha256.convert(path.readAsBytesSync()).toString(), scene['sha256'],
          reason: 'Original current payload changed: ${scene['id']}');
    }
    expect(
      sha256
          .convert(File('assets/scan_pass_replay/replay-data.json')
              .readAsBytesSync())
          .toString(),
      'cf73a11f566d974f3dada609e0d16111e6896dc522d88c08c257eb7332efaa71',
    );
  });

  test('source gaps stay null while the marked display trajectory is dense',
      () {
    final payload = jsonDecode(
      File('assets/scan_pass_replay/scenes/de-bruyne-pressure-receive.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    final playerIndex = (payload['players'] as List<dynamic>).indexWhere(
      (value) => (value as Map<String, dynamic>)['id'] == 5821,
    );
    final flags = payload['visibility'] as List<dynamic>;
    final frames = payload['frames'] as List<dynamic>;
    for (final frame in <int>[53, 54, 55]) {
      expect((flags[frame] as List<dynamic>)[playerIndex], 1);
    }
    // Introduce a missing observation away from any authored actor step. The
    // gap behavior must not depend on a particular source clip's incidental gap.
    (flags[54] as List<dynamic>)[playerIndex] = 0;
    (frames[54] as List<dynamic>)[playerIndex * 2] = 0;
    (frames[54] as List<dynamic>)[playerIndex * 2 + 1] = 0;
    ((payload['displayProvenance'] as List<dynamic>)[54]
        as List<dynamic>)[playerIndex] = 1;
    final data = RealMatchReplayData.fromJson(payload);
    final deBruyne = data.playerIndex(5821);
    expect(data.sample(5.3).players[deBruyne], isNotNull);
    expect(data.sample(5.35).players[deBruyne], isNull);
    expect(data.sample(5.4).players[deBruyne], isNull);
    expect(data.sample(5.45).players[deBruyne], isNull);
    expect(data.sample(5.5).players[deBruyne], isNotNull);
    expect(data.renderSample(5.4).players[deBruyne], isNull);
    expect(data.displaySample(5.4).players[deBruyne], isNotNull);
    expect(data.displaySample(5.4).reconstructed[deBruyne], isTrue);
    expect(() => data.motion.stateAt(5.4, deBruyne), returnsNormally);
    final camera =
        RealMatchReplayCoachingPlan.forData(data).cameraAt(data, 5.4);
    expect(camera.width, greaterThan(0));
    expect(camera.height, greaterThan(0));
    expect(camera.minX, greaterThanOrEqualTo(-data.pitchLength));
    expect(camera.maxX, lessThanOrEqualTo(data.pitchLength));
  });

  test('opening play does not invent an off-camera famous player', () {
    final data = scenes['de-bruyne-pressure-receive']!;
    expect(data.scene.steps.first.actorId, 1152);
    expect(data.playerPointAt(0, 5821), isNull);
    expect(data.displayPointAt(0, 5821), isNotNull);
    expect(data.displaySample(0).reconstructed[data.playerIndex(5821)], isTrue);
    expect(data.playerPointAt(1.2, 5821), isNotNull);
    expect(
        data.scene.steps
            .where((step) => step.kind == RealMatchReplayStepKind.pass),
        hasLength(3));
  });

  test(
      'historical display is 22-player dense while source evidence stays exact',
      () {
    for (final entry in catalog.scenes.take(5)) {
      final data = scenes[entry.id]!;
      expect(data.hasDisplayReconstruction, isTrue, reason: entry.id);
      for (var frame = 0; frame < data.frames.length; frame++) {
        for (final offset in <double>[
          0,
          if (frame + 1 < data.frames.length) .5
        ]) {
          final time = (frame + offset) / data.fps;
          final display = data.displaySample(time);
          expect(
              display.players.whereType<RealMatchReplayPoint>(), hasLength(22),
              reason: '${entry.id} frame=$frame offset=$offset');
          expect(display.ball.x, data.sample(time).ball.x,
              reason: '${entry.id} ball x at $time');
          expect(display.ball.y, data.sample(time).ball.y,
              reason: '${entry.id} ball y at $time');
          expect(display.ball.z, data.sample(time).ball.z,
              reason: '${entry.id} ball z at $time');
        }
        final source = data.sample(frame / data.fps);
        final display = data.displaySample(frame / data.fps);
        for (var player = 0; player < data.players.length; player++) {
          final shown = display.players[player]!;
          expect(shown.x.isFinite && shown.y.isFinite, isTrue,
              reason: '${entry.id} player=$player frame=$frame');
          expect(shown.x.abs(), lessThanOrEqualTo(data.pitchLength / 2));
          expect(shown.y.abs(), lessThanOrEqualTo(data.pitchWidth / 2));
          if (data.visibility[frame][player] == 1) {
            expect(source.players[player], isNotNull);
            expect(display.reconstructed[player], isFalse);
            expect(data.displayFrames[frame][player * 2],
                data.frames[frame][player * 2]);
            expect(data.displayFrames[frame][player * 2 + 1],
                data.frames[frame][player * 2 + 1]);
          } else {
            expect(source.players[player], isNull);
            expect(display.reconstructed[player], isTrue);
          }
        }
      }
      for (var frame = 1; frame < data.displayFrames.length; frame++) {
        for (var player = 0; player < data.players.length; player++) {
          final dx = (data.displayFrames[frame][player * 2] -
                  data.displayFrames[frame - 1][player * 2]) /
              100;
          final dy = (data.displayFrames[frame][player * 2 + 1] -
                  data.displayFrames[frame - 1][player * 2 + 1]) /
              100;
          expect(math.sqrt(dx * dx + dy * dy) * data.fps, lessThan(15),
              reason: '${entry.id} player=$player frame=$frame');
        }
      }
    }
  });

  test('display estimates cannot change coaching classifications or cameras',
      () {
    final payload = jsonDecode(
      File('assets/scan_pass_replay/scenes/de-bruyne-pressure-receive.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    final baseline = RealMatchReplayData.fromJson(payload);
    final baselinePlan = RealMatchReplayCoachingPlan.forData(baseline);
    final provenance = payload['displayProvenance'] as List<dynamic>;
    final display = payload['displayFrames'] as List<dynamic>;
    for (var frame = 0; frame < provenance.length; frame++) {
      final flags = provenance[frame] as List<dynamic>;
      final row = display[frame] as List<dynamic>;
      for (var player = 0; player < flags.length; player++) {
        if (flags[player] != 1) continue;
        row[player * 2] = player.isEven ? 5200 : -5200;
        row[player * 2 + 1] = player.isEven ? 3300 : -3300;
      }
    }
    final changed = RealMatchReplayData.fromJson(payload);
    final changedPlan = RealMatchReplayCoachingPlan.forData(changed);
    expect(changedPlan.moments.map((moment) => moment.cue),
        orderedEquals(baselinePlan.moments.map((moment) => moment.cue)));
    for (var time = 0.0; time <= baseline.duration; time += .1) {
      final a = baselinePlan.cameraAt(baseline, time);
      final b = changedPlan.cameraAt(changed, time);
      expect(<double>[b.minX, b.maxX, b.minY, b.maxY],
          <double>[a.minX, a.maxX, a.minY, a.maxY]);
    }
  });

  test('passes remain visible before a receiver enters broadcast coverage', () {
    for (final example in <(String, double, int, double)>[
      ('salah-right-recycle', 3.2, 11537, 4.4),
      ('kroos-central-recycle', 7.5, 8886, 8.4),
    ]) {
      final (id, passTime, receiver, receiveTime) = example;
      final data = scenes[id]!;
      final plan = RealMatchReplayCoachingPlan.forData(data);
      final step = data.stepAt(passTime);
      expect(step.kind, RealMatchReplayStepKind.pass, reason: id);
      expect(step.targetId, isNull, reason: id);
      expect(data.playerPointAt(passTime, receiver), isNull, reason: id);
      expect(
          plan.moments.any((moment) =>
              moment.time == passTime &&
              moment.step.kind == RealMatchReplayStepKind.pass),
          isTrue,
          reason: id);
      expect(data.stepAt(receiveTime).actorId, receiver, reason: id);
      expect(data.playerPointAt(receiveTime, receiver), isNotNull, reason: id);
    }
  });

  test('parser rejects malformed visibility and absent authored actors', () {
    Map<String, dynamic> payload() => jsonDecode(
          File(
            'assets/scan_pass_replay/scenes/de-bruyne-pressure-receive.json',
          ).readAsStringSync(),
        ) as Map<String, dynamic>;

    final wrongWidth = payload();
    (wrongWidth['visibility'] as List<dynamic>).first = <int>[1];
    expect(
        () => RealMatchReplayData.fromJson(wrongWidth), throwsFormatException);

    final hiddenCoordinate = payload();
    final visible = hiddenCoordinate['visibility'] as List<dynamic>;
    final frames = hiddenCoordinate['frames'] as List<dynamic>;
    final hiddenPlayer = (visible.first as List<dynamic>).indexOf(0);
    expect(hiddenPlayer, greaterThanOrEqualTo(0));
    (frames.first as List<dynamic>)[hiddenPlayer * 2] = 1;
    expect(() => RealMatchReplayData.fromJson(hiddenCoordinate),
        throwsFormatException);

    final alteredObservation = payload();
    final firstObserved = ((alteredObservation['visibility'] as List<dynamic>)
            .first as List<dynamic>)
        .indexOf(1);
    ((alteredObservation['displayFrames'] as List<dynamic>).first
        as List<dynamic>)[firstObserved * 2] += 1;
    expect(() => RealMatchReplayData.fromJson(alteredObservation),
        throwsFormatException);

    final falseProvenance = payload();
    final firstMissing = ((falseProvenance['visibility'] as List<dynamic>).first
            as List<dynamic>)
        .indexOf(0);
    ((falseProvenance['displayProvenance'] as List<dynamic>).first
        as List<dynamic>)[firstMissing] = 0;
    expect(() => RealMatchReplayData.fromJson(falseProvenance),
        throwsFormatException);

    final hiddenActor = payload();
    final players = hiddenActor['players'] as List<dynamic>;
    final firstVisibility =
        (hiddenActor['visibility'] as List<dynamic>).first as List<dynamic>;
    final firstHidden = firstVisibility.indexOf(0);
    final hiddenId =
        (players[firstHidden] as Map<String, dynamic>)['id'] as int;
    ((hiddenActor['scene'] as Map<String, dynamic>)['steps'] as List<dynamic>)
        .first['actorId'] = hiddenId;
    expect(
        () => RealMatchReplayData.fromJson(hiddenActor), throwsFormatException);

    final absentFocus = payload();
    final scene = absentFocus['scene'] as Map<String, dynamic>;
    final focus = scene['focusPlayerId'] as int;
    final focusIndex = (absentFocus['players'] as List<dynamic>).indexWhere(
      (value) => (value as Map<String, dynamic>)['id'] == focus,
    );
    final absentFrames = absentFocus['frames'] as List<dynamic>;
    final absentVisibility = absentFocus['visibility'] as List<dynamic>;
    for (var index = 0; index < absentFrames.length; index++) {
      (absentVisibility[index] as List<dynamic>)[focusIndex] = 0;
      (absentFrames[index] as List<dynamic>)[focusIndex * 2] = 0;
      (absentFrames[index] as List<dynamic>)[focusIndex * 2 + 1] = 0;
    }
    expect(
        () => RealMatchReplayData.fromJson(absentFocus), throwsFormatException);
  });

  test('XY-only scenes never expose inferred height', () {
    final deBruyne = scenes['de-bruyne-pressure-receive']!;
    final messi = scenes['messi-right-connection']!;
    expect(deBruyne.ballHeightAvailable, isTrue);
    expect(deBruyne.frames.any((frame) => frame.last != 0), isTrue);
    expect(messi.ballHeightAvailable, isFalse);
    expect(messi.frames.every((frame) => frame.last == 0), isTrue);
    expect(messi.sample(4.25).ball.z, 0);
  });

  test('visible anonymous team tracks stay drawable without invented identity',
      () {
    final payload = jsonDecode(
      File(
        'assets/scan_pass_replay/scenes/de-bruyne-pressure-receive.json',
      ).readAsStringSync(),
    ) as Map<String, dynamic>;
    final usedIds = <int>{
      ((payload['scene'] as Map<String, dynamic>)['focusPlayerId'] as int),
    };
    for (final value in (payload['scene'] as Map<String, dynamic>)['steps']
        as List<dynamic>) {
      final step = value as Map<String, dynamic>;
      for (final key in <String>['actorId', 'targetId', 'secondaryId']) {
        if (step[key] case final int id) usedIds.add(id);
      }
    }
    final players = payload['players'] as List<dynamic>;
    final anonymousIndex = players.indexWhere(
      (value) => !usedIds.contains((value as Map<String, dynamic>)['id']),
    );
    expect(anonymousIndex, greaterThanOrEqualTo(0));
    final anonymous = players[anonymousIndex] as Map<String, dynamic>;
    anonymous
      ..['number'] = null
      ..['name'] = null
      ..['trackId'] = 99001;

    final data = RealMatchReplayData.fromJson(payload);
    expect(data.players[anonymousIndex].identified, isFalse);
    expect(data.players[anonymousIndex].trackId, 99001);
    final visibleFrame = data.visibility.indexWhere(
      (row) => row[anonymousIndex] == 1,
    );
    expect(visibleFrame, greaterThanOrEqualTo(0));
    expect(
      data.sample(visibleFrame / data.fps).players[anonymousIndex],
      isNotNull,
    );
  });

  test('every catalog title and focus prompt is localized in all locales', () {
    for (final locale in <String>['en', 'ko', 'ja']) {
      final messages = jsonDecode(
        File('lib/l10n/app_$locale.arb').readAsStringSync(),
      ) as Map<String, dynamic>;
      for (final scene in catalog.scenes) {
        expect(messages[scene.titleKey], isNotEmpty,
            reason: '$locale ${scene.titleKey}');
        expect(messages[scene.focusKey], isNotEmpty,
            reason: '$locale ${scene.focusKey}');
      }
    }
  });

  test('every payload matches its catalog entry and has valid variable steps',
      () {
    for (final entry in catalog.scenes) {
      final data = scenes[entry.id]!;
      expect(data.scene.id, entry.id, reason: entry.id);
      expect(data.scene.category, entry.category, reason: entry.id);
      expect(data.match.id, entry.matchId, reason: entry.id);
      expect(data.duration, closeTo(entry.duration, 1 / data.fps));
      expect(data.scene.steps.first.time, 0, reason: entry.id);
      expect(data.scene.steps.last.time, lessThan(data.duration));
      expect(
        data.scene.steps.map((step) => step.time),
        orderedEquals(
          data.scene.steps.map((step) => step.time).toList()..sort(),
        ),
      );
      expect(
        () => data.player(data.scene.focusPlayerId),
        returnsNormally,
        reason: entry.id,
      );
    }
  });

  test('tracking-only scenes return null poses while original keeps poses', () {
    final tracked = scenes['central-build']!;
    final original = scenes['transition-wing']!;

    expect(tracked.poses, isEmpty);
    expect(tracked.hasRecordedPose, isFalse);
    expect(tracked.poseAt(0, 0), isNull);
    expect(original.hasRecordedPose, isTrue);
    expect(
      original.hasRecordedPoseFor(original.scene.focusPlayerId),
      isTrue,
    );
  });

  test('coaching plans deduplicate short steps and retain every clip endpoint',
      () {
    final catalogCues = <RealMatchReplayCoachingCue>{};
    for (final entry in catalog.scenes) {
      final data = scenes[entry.id]!;
      final plan = RealMatchReplayCoachingPlan.forData(data);
      catalogCues.addAll(plan.moments.map((moment) => moment.cue));
      expect(plan.moments.first.time, 0, reason: entry.id);
      expect(plan.moments.last.time, data.duration, reason: entry.id);
      expect(
        plan.moments.last.cue,
        RealMatchReplayCoachingCue.outcome,
        reason: entry.id,
      );
      for (var index = 1; index < plan.moments.length - 1; index++) {
        expect(
          plan.moments[index].time - plan.moments[index - 1].time,
          greaterThan(RealMatchReplayCoachingPlan.minimumMomentGap),
          reason: '${entry.id} moment $index',
        );
      }
      expect(
        plan.moments.length,
        lessThanOrEqualTo(data.scene.steps.length + 1),
        reason: entry.id,
      );
    }

    final overlap = RealMatchReplayCoachingPlan.forData(
      scenes['overlap-wing']!,
    );
    expect(
      overlap.moments.where(
        (moment) => moment.time >= 3.5 && moment.time <= 3.7,
      ),
      hasLength(1),
    );
    expect(
      overlap.moments.firstWhere((moment) => moment.time >= 3.5).cue,
      RealMatchReplayCoachingCue.overlap,
    );
    expect(
      catalogCues,
      containsAll(<RealMatchReplayCoachingCue>[
        RealMatchReplayCoachingCue.carryTurn,
        RealMatchReplayCoachingCue.passIntoRun,
        RealMatchReplayCoachingCue.overlap,
        RealMatchReplayCoachingCue.underlap,
        RealMatchReplayCoachingCue.crossArrival,
        RealMatchReplayCoachingCue.pressure,
      ]),
    );
  });

  test('outcome cue starts at its source event without an extra playback stop',
      () {
    for (final data in scenes.values) {
      final plan = RealMatchReplayCoachingPlan.forData(data);
      final outcome = data.scene.steps.last;
      expect(outcome.kind, RealMatchReplayStepKind.outcome);
      expect(plan.activeMomentAt(data, outcome.time).cue,
          RealMatchReplayCoachingCue.outcome,
          reason: data.scene.id);
      expect(plan.activeMomentAt(data, outcome.time).time, outcome.time);
      expect(plan.activeMomentAt(data, data.duration).time, outcome.time);
      expect(plan.nextMomentIndex(outcome.time), plan.moments.length - 1);
    }
  });

  test('generic validation rejects duplicate ids and non-finite durations', () {
    final catalogJson = jsonDecode(
      File('assets/scan_pass_replay/catalog.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final catalogScenes = catalogJson['scenes'] as List<dynamic>;
    (catalogScenes[1] as Map<String, dynamic>)['id'] =
        (catalogScenes[0] as Map<String, dynamic>)['id'];
    expect(
      () => RealMatchReplayCatalog.fromJson(catalogJson),
      throwsFormatException,
    );

    final payload = jsonDecode(
      File('assets/scan_pass_replay/scenes/central-build.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    payload['duration'] = double.nan;
    expect(
      () => RealMatchReplayData.fromJson(payload),
      throwsFormatException,
    );
  });

  test('motion is distance-phased, deterministic and turns continuously', () {
    final data = scenes['carry-turnover']!;
    final player = data.playerIndex(data.scene.focusPlayerId);
    var prior = data.motion.stateAt(0, player);
    var fastest = prior;
    var slowest = prior;
    var fastestTime = 0.0;
    var slowestTime = 0.0;
    for (var frame = 1; frame < data.frames.length; frame++) {
      final time = frame / data.fps;
      final current = data.motion.stateAt(time, player);
      final turn = _angleDifference(current.heading, prior.heading).abs();
      expect(turn * data.fps, lessThanOrEqualTo(4.1),
          reason: 'Turn rate must be bounded in real seconds, frame $frame');
      expect(current.gaitPhase, greaterThanOrEqualTo(prior.gaitPhase));
      if (current.speed <= .18) {
        expect(current.gaitPhase, prior.gaitPhase, reason: 'stationary $frame');
      }
      if (current.speed > fastest.speed) {
        fastest = current;
        fastestTime = time;
      }
      if (current.speed < slowest.speed) {
        slowest = current;
        slowestTime = time;
      }
      prior = current;
    }
    expect(fastest.speed, greaterThan(slowest.speed));
    final stepBefore = data.motion.stateAt(fastestTime - .05, player);
    final stepAfter = data.motion.stateAt(fastestTime + .05, player);
    final cyclesPerSecond =
        (stepAfter.gaitPhase - stepBefore.gaitPhase) / (.1 * 2 * math.pi);
    expect(cyclesPerSecond, inInclusiveRange(.8, 2.6),
        reason:
            'Full left/right stride cycles must not look like rapid shuffling');
    final fastPose = data.motion.simplifiedPoseAt(fastestTime, player);
    final slowPose = data.motion.simplifiedPoseAt(slowestTime, player);
    final leftAnkle = data.joints.indexOf('lAnkle');
    final rightAnkle = data.joints.indexOf('rAnkle');
    expect(
      math.max(
        fastPose.joints[leftAnkle].z,
        fastPose.joints[rightAnkle].z,
      ),
      greaterThan(math.max(
        slowPose.joints[leftAnkle].z,
        slowPose.joints[rightAnkle].z,
      )),
    );
    final atTime = data.motion.stateAt(3.47, player);
    final repeated = data.motion.stateAt(3.47, player);
    expect(repeated.heading, atTime.heading);
    expect(repeated.gaitPhase, atTime.gaitPhase);
    expect(repeated.position.x, atTime.position.x);
  });

  test('player smoothing is bounded and never changes the linear ball path',
      () {
    final data = scenes['pressure-switch']!;
    const frame = 17;
    const time = (frame + .5) / 10;
    final before = data.sample(frame / 10);
    final after = data.sample((frame + 1) / 10);
    final linear = data.sample(time);
    final rendered = data.renderSample(time);

    for (var index = 0; index < data.players.length; index++) {
      expect(
        rendered.players[index]!.x,
        inInclusiveRange(
          math.min(before.players[index]!.x, after.players[index]!.x),
          math.max(before.players[index]!.x, after.players[index]!.x),
        ),
      );
      expect(
        rendered.players[index]!.y,
        inInclusiveRange(
          math.min(before.players[index]!.y, after.players[index]!.y),
          math.max(before.players[index]!.y, after.players[index]!.y),
        ),
      );
    }
    expect(rendered.ball.x, linear.ball.x);
    expect(rendered.ball.y, linear.ball.y);
    expect(rendered.ball.z, linear.ball.z);
  });
}

double _angleDifference(double a, double b) {
  var value = a - b;
  while (value > math.pi) {
    value -= math.pi * 2;
  }
  while (value < -math.pi) {
    value += math.pi * 2;
  }
  return value;
}
