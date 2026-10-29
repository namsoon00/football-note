import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/scan_pass/scan_pass_video_learning.dart';

void main() {
  test('catalogue validates three contiguous authored phases and clip bounds',
      () {
    final catalog =
        VideoLearningCatalog.fromJson(testVideoLearningCatalogJson());
    final scene = catalog.scenes.single;

    expect(scene.clip.duration, 20);
    expect(scene.phases, hasLength(3));
    expect(scene.phaseAt(113).id, 'finish');
    expect(scene.phaseAt(999).id, 'finish');
    expect(scene.officialVideoUrl.host, 'www.youtube.com');
    expect(scene.officialVideoUrl.queryParameters['v'], 'abcdefghijk');
    expect(scene.officialVideoUrl.queryParameters['t'], '100s');
    expect(scene.officialVideoUrlAt(117.9).queryParameters['t'], '117s');
  });

  test('catalogue rejects a phase gap and a goal outside the reviewed clip',
      () {
    final gap = testVideoLearningCatalogJson();
    ((gap['scenes'] as List).single as Map<String, dynamic>)['phases']![1]
        ['start'] = 107;
    expect(
      () => VideoLearningCatalog.fromJson(gap),
      throwsFormatException,
    );

    final outside = testVideoLearningCatalogJson();
    ((outside['scenes'] as List).single as Map<String, dynamic>)['goalTime'] =
        140;
    expect(
      () => VideoLearningCatalog.fromJson(outside),
      throwsFormatException,
    );
  });

  test('team and watched filters keep deterministic non-wrapping navigation',
      () {
    final first = _sceneJson(id: 'scene-one', homeId: 'home');
    final second = _sceneJson(id: 'scene-two', homeId: 'other');
    final third = _sceneJson(id: 'scene-three', homeId: 'home');
    final catalog = VideoLearningCatalog.fromJson(<String, dynamic>{
      'version': 1,
      'scenes': <Object>[first, second, third],
    });
    final filtered = catalog.filtered(
      teamId: 'home',
      watchFilter: VideoLearningWatchFilter.unwatched,
      isWatched: (id) => id == 'scene-one',
    );

    expect(filtered.map((scene) => scene.id), <String>['scene-three']);
    expect(
      catalog.adjacentIndex(
        currentSceneId: 'scene-three',
        filteredScenes: filtered,
        delta: 1,
      ),
      isNull,
    );
    expect(
      catalog
          .nextUnseen(
            currentSceneId: 'scene-one',
            filteredScenes: catalog.scenes,
            isWatched: (id) => id == 'scene-one',
          )
          ?.id,
      'scene-two',
    );
  });

  test('malformed JSON is not silently accepted', () {
    final value = testVideoLearningCatalogJson();
    final encoded = jsonEncode(value).replaceFirst('#112233', 'blue');
    expect(
      () => VideoLearningCatalog.fromJsonString(encoded),
      throwsFormatException,
    );
  });

  test('committed reviewed catalogue has six real goal passages', () {
    final catalog = VideoLearningCatalog.fromJsonString(
      File('assets/video_learning/catalog.json').readAsStringSync(),
    );

    expect(catalog.scenes, hasLength(6));
    expect(catalog.teams, hasLength(5));
    expect(
      catalog.scenes.where((scene) => scene.attackDirection == -1),
      hasLength(3),
    );
    final arrowKinds = <VideoLearningArrowKind>{};
    for (final scene in catalog.scenes) {
      expect(scene.videoId, hasLength(11));
      expect(scene.phases, hasLength(3));
      expect(
          scene.goalTime, inInclusiveRange(scene.clip.start, scene.clip.end));
      expect(scene.phases.expand((phase) => phase.diagram.players), isNotEmpty);
      for (final phase in scene.phases) {
        expect(phase.diagram.focusIds, isNotEmpty);
        arrowKinds.addAll(phase.diagram.arrows.map((arrow) => arrow.kind));
      }
    }
    expect(arrowKinds, VideoLearningArrowKind.values.toSet());
  });

  test('a two-player combination keeps only identified actors', () {
    final value = testVideoLearningCatalogJson();
    final scene = (value['scenes'] as List).single as Map<String, dynamic>;
    for (final phase in scene['phases'] as List) {
      final diagram = phase['diagram'] as Map<String, dynamic>;
      diagram['players'] = (diagram['players'] as List).take(2).toList();
    }
    final catalog = VideoLearningCatalog.fromJson(value);
    expect(catalog.scenes.single.phases.first.diagram.players, hasLength(2));

    final firstDiagram = scene['phases'][0]['diagram'];
    firstDiagram['players'] =
        (firstDiagram['players'] as List).take(1).toList();
    expect(() => VideoLearningCatalog.fromJson(value), throwsFormatException);
  });
}

Map<String, dynamic> testVideoLearningCatalogJson() => <String, dynamic>{
      'version': 1,
      'scenes': <Object>[_sceneJson()],
    };

Map<String, dynamic> _sceneJson({
  String id = 'scene-one',
  String homeId = 'home',
}) =>
    <String, dynamic>{
      'id': id,
      'titleKey': 'videoSampleTitle',
      'focusKey': 'videoSampleFocus',
      'date': '2020-01-01',
      'homeTeam': _team(homeId, 'Home', '#112233'),
      'awayTeam': _team('away-$id', 'Away', '#CC2233'),
      'videoId': 'abcdefghijk',
      'channel': 'Official channel',
      'channelUrl': 'https://www.youtube.com/@official',
      'sourceDuration': 180,
      'start': 100,
      'end': 120,
      'goalTime': 117,
      'goalMinute': 80,
      'reportUrl': 'https://example.com/report',
      'reviewedOn': '2026-10-30',
      'reviewMethod': 'Reviewed official storyboard frames.',
      'timestampTolerance': 1,
      'attackDirection': 1,
      'phases': <Object>[
        _phase('prepare', 100, 106),
        _phase('break', 106, 112),
        _phase('finish', 112, 120),
      ],
    };

Map<String, dynamic> _team(String id, String name, String color) =>
    <String, dynamic>{
      'id': id,
      'name': name,
      'kit': <String, dynamic>{
        'primary': color,
        'secondary': '#FFFFFF',
        'accent': '#000000',
        'number': '#FFFFFF',
        'pattern': 'solid',
      },
    };

Map<String, dynamic> _phase(String id, double start, double end) =>
    <String, dynamic>{
      'id': id,
      'titleKey': 'videoSamplePhaseTitle',
      'watchKey': 'videoSamplePhaseWatch',
      'start': start,
      'end': end,
      'diagram': <String, dynamic>{
        'players': <Object>[
          _player('p1', 9, true, .2, .2),
          _player('p2', 10, true, .4, .4),
          _player('p3', 4, false, .6, .3),
          _player('p4', 5, false, .75, .6),
        ],
        'ball': <String, dynamic>{'x': .21, 'y': .2},
        'arrows': <Object>[
          <String, dynamic>{
            'from': <double>[.21, .2],
            'to': <double>[.4, .4],
            'kind': 'pass',
          },
          <String, dynamic>{
            'from': <double>[.2, .2],
            'to': <double>[.7, .2],
            'kind': 'run',
          },
        ],
        'space': <String, dynamic>{
          'x': .65,
          'y': .1,
          'width': .2,
          'height': .25,
        },
        'focusIds': <String>['p1'],
      },
    };

Map<String, dynamic> _player(
  String id,
  int number,
  bool home,
  double x,
  double y,
) =>
    <String, dynamic>{
      'id': id,
      'name': 'Player $id',
      'number': number,
      'home': home,
      'x': x,
      'y': y,
    };
