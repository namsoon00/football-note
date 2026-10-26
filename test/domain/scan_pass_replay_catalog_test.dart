import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

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

  test('catalog exposes twenty distinct scenes across every category', () {
    expect(catalog.version, 1);
    expect(catalog.scenes, hasLength(20));
    expect(
      catalog.scenes.map((scene) => scene.id).toSet(),
      hasLength(20),
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
        rendered.players[index].x,
        inInclusiveRange(
          math.min(before.players[index].x, after.players[index].x),
          math.max(before.players[index].x, after.players[index].x),
        ),
      );
      expect(
        rendered.players[index].y,
        inInclusiveRange(
          math.min(before.players[index].y, after.players[index].y),
          math.max(before.players[index].y, after.players[index].y),
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
