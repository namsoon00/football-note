import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/scan_pass/real_match_replay.dart';

void main() {
  late Map<String, dynamic> extract;

  setUpAll(() {
    extract = jsonDecode(
      File('assets/scan_pass_spatial/source-height-extract.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
  });

  test('recent and historical payloads retain exact pinned source z', () {
    for (final sample in <(String, String, double)>[
      (
        '1925299-30793-287934-pressureOutlet',
        '4340d274572876239c154c90bc507a9b3250a656',
        6.96,
      ),
      (
        '2269-32665-caleta-car-lateralSwitch',
        '1ed50b775f93075c2a6d00d0d795f13b7b89709e',
        9.74,
      ),
    ]) {
      final data = _replay(sample.$1);
      final source = _extractScene(extract, sample.$1);
      final raw = (source['rawZMeters'] as List<dynamic>)
          .map((value) => value as num?)
          .toList(growable: false);
      final valid = (source['valid'] as List<dynamic>).cast<bool>();
      final maximumIndex = <int>[
        for (var index = 0; index < raw.length; index++)
          if (valid[index]) index,
      ].reduce(
        (first, second) =>
            raw[first]!.toDouble() >= raw[second]!.toDouble() ? first : second,
      );

      expect(data.sourceCommit, sample.$2);
      expect(data.hasAuditedBallHeight, isTrue);
      expect(data.frames[maximumIndex].last / 100, sample.$3);
      expect(
        data.frames[maximumIndex].last / 100,
        closeTo(raw[maximumIndex]!.toDouble(), .0050001),
      );
      expect(data.heightAt(maximumIndex / data.fps), sample.$3);
    }
  });

  test('known zero remains ground while missing and negative z stay unknown',
      () {
    final zero = _findHeightSample(
      extract,
      (raw, valid) => valid && raw == 0,
    );
    final negative = _findHeightSample(
      extract,
      (raw, valid) => !valid && raw != null && raw < 0,
    );
    final missing = _findHeightSample(
      extract,
      (raw, valid) => !valid && raw == null,
    );

    final zeroData = _replay(zero.sceneId);
    expect(zeroData.frames[zero.index].last, 0);
    expect(zeroData.isBallHeightValidAtFrame(zero.index), isTrue);
    expect(zeroData.heightAt(zero.index / zeroData.fps), 0);

    for (final unknown in <_HeightSample>[negative, missing]) {
      final data = _replay(unknown.sceneId);
      expect(data.frames[unknown.index].last, 0);
      expect(data.isBallHeightValidAtFrame(unknown.index), isFalse);
      expect(data.heightAt(unknown.index / data.fps), isNull);
    }
  });

  test('height never interpolates across an adjacent invalid observation', () {
    final sample = _findValidityBoundary(extract);
    final data = _replay(sample.sceneId);
    final validIndex = sample.firstValid ? sample.index : sample.index + 1;
    final invalidIndex = sample.firstValid ? sample.index + 1 : sample.index;

    expect(data.heightAt(validIndex / data.fps), isNotNull);
    expect(data.heightAt(invalidIndex / data.fps), isNull);
    expect(data.heightAt((sample.index + .5) / data.fps), isNull);
    expect(
      data.heightAt(validIndex / data.fps),
      data.frames[validIndex].last / 100,
    );
  });

  test('malformed masks, global flags, and height ranges are rejected', () {
    final source = _sceneJson('1925299-185-560983-thirdPlayer');

    final shortMask = _copy(source);
    (shortMask['ballHeightValid'] as List<dynamic>).removeLast();
    expect(
        () => RealMatchReplayData.fromJson(shortMask), throwsFormatException);

    final numericMask = _copy(source);
    numericMask['ballHeightValid'][0] = 1;
    expect(
        () => RealMatchReplayData.fromJson(numericMask), throwsFormatException);

    final staleGlobal = _copy(source)..['ballHeightAvailable'] = false;
    expect(
        () => RealMatchReplayData.fromJson(staleGlobal), throwsFormatException);

    final outOfRange = _copy(source);
    outOfRange['frames'][0][(outOfRange['frames'][0] as List).length - 1] =
        1501;
    outOfRange['ballHeightValid'][0] = true;
    expect(
        () => RealMatchReplayData.fromJson(outOfRange), throwsFormatException);

    final inventedGround = _copy(source);
    inventedGround['frames'][0]
        [(inventedGround['frames'][0] as List).length - 1] = 7;
    inventedGround['ballHeightValid'][0] = false;
    expect(
      () => RealMatchReplayData.fromJson(inventedGround),
      throwsFormatException,
    );
  });

  test('legacy assets without masks derive safe per-frame fallback validity',
      () {
    final legacy = _copy(_sceneJson('1925299-185-560983-thirdPlayer'));
    legacy.remove('ballHeightValid');
    legacy.remove('ballHeightSource');
    legacy['ballHeightAvailable'] = true;
    legacy['frames'][0][(legacy['frames'][0] as List).length - 1] = -4;
    legacy['frames'][1][(legacy['frames'][1] as List).length - 1] = 0;

    final data = RealMatchReplayData.fromJson(legacy);
    expect(data.ballHeightMaskProvided, isFalse);
    expect(data.hasAuditedBallHeight, isFalse);
    expect(data.heightAt(0), isNull);
    expect(data.heightAt(1 / data.fps), 0);
    expect(data.heightAt(.5 / data.fps), isNull);
  });
}

Map<String, dynamic> _sceneJson(String sceneId) => jsonDecode(
      File('assets/scan_pass_spatial/education_scenes/$sceneId.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;

RealMatchReplayData _replay(String sceneId) =>
    RealMatchReplayData.fromJson(_sceneJson(sceneId));

Map<String, dynamic> _extractScene(
  Map<String, dynamic> extract,
  String sceneId,
) =>
    (extract['scenes'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .firstWhere((scene) => scene['id'] == sceneId);

Map<String, dynamic> _copy(Map<String, dynamic> source) =>
    jsonDecode(jsonEncode(source)) as Map<String, dynamic>;

typedef _HeightSample = ({String sceneId, int index});

_HeightSample _findHeightSample(
  Map<String, dynamic> extract,
  bool Function(double? raw, bool valid) predicate,
) {
  for (final scene
      in (extract['scenes'] as List<dynamic>).cast<Map<String, dynamic>>()) {
    final raw = scene['rawZMeters'] as List<dynamic>;
    final valid = (scene['valid'] as List<dynamic>).cast<bool>();
    for (var index = 0; index < raw.length; index++) {
      final value = (raw[index] as num?)?.toDouble();
      if (predicate(value, valid[index])) {
        return (sceneId: scene['id'] as String, index: index);
      }
    }
  }
  throw StateError('No matching height sample');
}

({String sceneId, int index, bool firstValid}) _findValidityBoundary(
  Map<String, dynamic> extract,
) {
  for (final scene
      in (extract['scenes'] as List<dynamic>).cast<Map<String, dynamic>>()) {
    final valid = (scene['valid'] as List<dynamic>).cast<bool>();
    for (var index = 0; index + 1 < valid.length; index++) {
      if (valid[index] != valid[index + 1]) {
        return (
          sceneId: scene['id'] as String,
          index: index,
          firstValid: valid[index],
        );
      }
    }
  }
  throw StateError('No adjacent validity boundary');
}
