import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/scan_pass_spatial_library_service.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/domain/scan_pass/real_match_replay.dart';
import 'package:football_note/domain/scan_pass/scan_pass_spatial_library.dart';
import 'package:football_note/domain/scan_pass/scan_pass_spatial_personalization.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/scan_pass_game_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SpatialLibraryCatalog catalog;

  setUpAll(() {
    catalog = SpatialLibraryCatalog.fromJsonString(
      File('assets/scan_pass_spatial/education-catalog.json')
          .readAsStringSync(),
    );
  });

  for (final objective in SpatialLearningObjective.values) {
    testWidgets(
        '$objective shows question, observed action, and measured result',
        (tester) async {
      final scene = catalog.scenes.firstWhere(
        (value) => value.education!.objective == objective,
      );
      await tester.pumpWidget(_catalogApp(catalog, initialScene: scene));
      await _pumpLoaded(tester);

      final objectiveText = _text(tester, 'spatial-objective-line');
      final question = _text(tester, 'spatial-cue-line');
      expect(objectiveText, isNotEmpty);
      expect(
        question,
        contains(
          _cueLabel(
            _replay(scene),
            scene.education!.focusActor.playerId,
          ),
        ),
      );
      expect(_painter(tester).time, 0);

      _seek(tester, scene, scene.education!.trigger);
      await tester.pump();
      final action = _text(tester, 'spatial-cue-line');
      expect(action, isNot(question));
      expect(action, contains('#'));
      expect(_painter(tester).blueTeachingFocusPlayerIds,
          contains(scene.education!.focusActor.playerId));

      _seek(tester, scene, scene.education!.outcome + .2);
      await tester.pump();
      final result = _text(tester, 'spatial-cue-line');
      expect(result, isNot(action));
      expect(
        result,
        contains(scene.education!.afterValue.toStringAsFixed(1)),
      );
      expect(_painter(tester).showsEndpointRegion, isTrue);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('guided play resumes seeks in every rate segment without reset',
      (tester) async {
    final scene = catalog.scenes.first;
    final lesson = scene.education!;
    await tester.pumpWidget(_catalogApp(catalog, initialScene: scene));
    await _pumpLoaded(tester);

    final samples = <(double, double)>[
      (lesson.slowStart - 1.5, 1),
      ((lesson.slowStart + lesson.slowEnd) / 2, .5),
      (lesson.slowEnd + .6, 1),
    ];
    for (final (start, rate) in samples) {
      _seek(tester, scene, start);
      await tester.pump();
      expect(_painter(tester).time, closeTo(start, .02));

      await tester.tap(find.byKey(const ValueKey<String>('spatial-play')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      expect(
        _painter(tester).time,
        closeTo(start + .7 * rate, .12),
        reason: 'guided play must continue from $start at $rate×',
      );
      await tester.tap(find.byKey(const ValueKey<String>('spatial-play')));
      await tester.pump();
    }
  });

  testWidgets('guided pause and ordinary play resume the same source instant',
      (tester) async {
    final scene = catalog.scenes.first;
    final lesson = scene.education!;
    final start = (lesson.slowStart + lesson.slowEnd) / 2;
    await tester.pumpWidget(_catalogApp(catalog, initialScene: scene));
    await _pumpLoaded(tester);

    _seek(tester, scene, start);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('spatial-play')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.byKey(const ValueKey<String>('spatial-play')));
    await tester.pump();
    final paused = _painter(tester).time;
    expect(paused, closeTo(start + .3, .12));

    await tester.pump(const Duration(seconds: 1));
    expect(_painter(tester).time, closeTo(paused, .01));
    await tester.tap(find.byKey(const ValueKey<String>('spatial-play')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(_painter(tester).time, closeTo(paused + .3, .12));
  });

  testWidgets('source-speed choice survives pause, seek, and ordinary resume',
      (tester) async {
    final scene = catalog.scenes.first;
    final lesson = scene.education!;
    await tester.pumpWidget(_catalogApp(catalog, initialScene: scene));
    await _pumpLoaded(tester);

    await _selectPlaybackAction(tester, 'spatial-source-speed');
    await tester.pump(const Duration(milliseconds: 600));
    expect(_painter(tester).time, closeTo(.6, .12));
    await tester.tap(find.byKey(const ValueKey<String>('spatial-play')));
    await tester.pump();
    final paused = _painter(tester).time;
    await tester.pump(const Duration(milliseconds: 700));
    expect(_painter(tester).time, closeTo(paused, .01));

    final seekTime = (lesson.slowStart + lesson.slowEnd) / 2;
    _seek(tester, scene, seekTime);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('spatial-play')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(
      _painter(tester).time,
      closeTo(seekTime + .7, .12),
      reason: 'ordinary play must keep the selected 1× source mode',
    );

    final nextScene = catalog.scenes[1];
    await tester.tap(find.byKey(const ValueKey<String>('spatial-next')));
    await _pumpScene(tester, nextScene.id);
    final nextLesson = nextScene.education!;
    final nextSeekTime = (nextLesson.slowStart + nextLesson.slowEnd) / 2;
    _seek(tester, nextScene, nextSeekTime);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('spatial-play')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(
      _painter(tester).time,
      closeTo(nextSeekTime + .6, .12),
      reason: 'simple scene switching must preserve source-speed mode',
    );
  });

  testWidgets(
      'delayed source-mode save cannot start playback on a newly selected scene',
      (tester) async {
    final options = _DelayedWriteOptions();
    await tester.pumpWidget(_catalogApp(catalog, options: options));
    await _pumpLoaded(tester);

    await tester.tap(find.byKey(const ValueKey<String>('spatial-more')));
    await tester.pumpAndSettle();
    options.delayNextWrite = true;
    await tester.tap(
      find.byKey(const ValueKey<String>('spatial-source-speed')),
    );
    await tester.pump();
    expect(options.writeBlocked, isTrue);

    final nextScene = catalog.scenes[1];
    await tester.tap(find.byKey(const ValueKey<String>('spatial-next')));
    await _pumpScene(tester, nextScene.id);
    expect(_painter(tester).time, 0);

    options.releaseWrite.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(_painter(tester).scene.id, nextScene.id);
    expect(
      _painter(tester).time,
      0,
      reason: 'a stale menu continuation must leave the new scene paused',
    );
  });

  testWidgets('recreation restores source-speed preference paused',
      (tester) async {
    final options = _MemoryOptions();
    final scene = catalog.scenes.first;
    final resume = (scene.teachingStart + scene.teachingEnd) / 2;
    await tester.pumpWidget(_catalogApp(catalog, options: options));
    await _pumpLoaded(tester);
    await _selectPlaybackAction(tester, 'spatial-source-speed');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const ValueKey<String>('spatial-play')));
    await tester.pump();
    _seek(tester, scene, resume);
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    await tester.pumpWidget(_catalogApp(catalog, options: options));
    await _pumpLoaded(tester);
    expect(_painter(tester).time, closeTo(resume, .01));
    await tester.pump(const Duration(milliseconds: 500));
    expect(_painter(tester).time, closeTo(resume, .01));
    await tester.tap(find.byKey(const ValueKey<String>('spatial-play')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(_painter(tester).time, closeTo(resume + .6, .12));
  });

  testWidgets(
      'saved filtered resume and pause continue to genuine auto-next paused',
      (tester) async {
    final grouped = <(String, String), List<SpatialLibraryScene>>{};
    for (final scene in catalog.scenes) {
      for (final player in scene.participantNames) {
        grouped.putIfAbsent(
          (scene.attackingTeam, player),
          () => <SpatialLibraryScene>[],
        ).add(scene);
      }
    }
    final group =
        grouped.entries.firstWhere((entry) => entry.value.length >= 2);
    final first = group.value[0];
    final expectedNext = group.value[1];
    final resume = first.duration > 12 ? 12.0 : first.duration / 2;
    final options = _MemoryOptions();
    options.values[ScanPassSpatialLibraryService.storageKey] = jsonEncode(
      SpatialLibraryPreferences(
        lastSceneIdentity: first.spatialHistoryIdentity,
        records: <String, SpatialLibrarySceneRecord>{
          first.spatialHistoryIdentity: SpatialLibrarySceneRecord(
            resumeTime: resume,
            coverage: SpatialLibraryCoverage(
              intervals: <SpatialLibraryViewedInterval>[
                SpatialLibraryViewedInterval(0, resume),
              ],
            ),
          ),
        },
        filters: SpatialLibraryFilters(
          query: first.attackingTeam,
          attackingTeam: first.attackingTeam,
          player: group.key.$2,
        ),
        playbackMode: SpatialLibraryPlaybackMode.source,
      ).toJson(),
    );
    await tester.pumpWidget(_catalogApp(catalog, options: options));
    await _pumpLoaded(tester);
    expect(_painter(tester).scene.id, first.id);
    expect(_painter(tester).time, closeTo(resume, .01));

    await tester.tap(find.byKey(const ValueKey<String>('spatial-play')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byKey(const ValueKey<String>('spatial-play')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('spatial-play')));
    await tester.pump();
    for (var attempt = 0;
        attempt < 160 && _painter(tester).scene.id == first.id;
        attempt++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    await _pumpScene(tester, expectedNext.id);
    final paused = _painter(tester).time;
    await tester.pump(const Duration(seconds: 1));

    expect(_painter(tester).time, paused);
    expect(tester.takeException(), isNull);
  });

  testWidgets('guided menu and finished replay intentionally restart at zero',
      (tester) async {
    final scene = catalog.scenes.first;
    await tester.pumpWidget(_catalogApp(catalog, initialScene: scene));
    await _pumpLoaded(tester);

    await _selectPlaybackAction(tester, 'spatial-source-speed');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const ValueKey<String>('spatial-play')));
    await tester.pump();
    _seek(tester, scene, scene.education!.slowStart + .5);
    await tester.pump();
    await _selectPlaybackAction(tester, 'spatial-focus-replay');
    expect(_painter(tester).time, 0);
    await tester.pump(const Duration(milliseconds: 400));
    expect(_painter(tester).time, closeTo(.4, .12));

    await tester.tap(find.byKey(const ValueKey<String>('spatial-play')));
    await tester.pump();
    _seek(tester, scene, scene.duration);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('spatial-play')));
    await tester.pump();
    expect(_painter(tester).time, 0);
    await tester.pump(const Duration(milliseconds: 400));
    expect(_painter(tester).time, closeTo(.4, .12));
  });

  testWidgets('objective title rate follows guided phase and source mode',
      (tester) async {
    final scene = catalog.scenes.first;
    final lesson = scene.education!;
    await tester.pumpWidget(_catalogApp(catalog, initialScene: scene));
    await _pumpLoaded(tester);
    final l10n = AppLocalizations.of(
      tester.element(
        find.byKey(const ValueKey<String>('spatial-objective-line')),
      ),
    )!;
    final objective = _objectiveTitle(l10n, lesson.objective);

    expect(_text(tester, 'spatial-objective-line'), objective);
    expect(
      _text(tester, 'spatial-playback-rate'),
      l10n.spatialEducationPlaybackRateNormal,
    );
    _seek(tester, scene, (lesson.slowStart + lesson.slowEnd) / 2);
    await tester.pump();
    expect(
      _text(tester, 'spatial-playback-rate'),
      l10n.spatialEducationPlaybackRateHalf,
    );
    _seek(tester, scene, lesson.slowEnd + .5);
    await tester.pump();
    expect(
      _text(tester, 'spatial-playback-rate'),
      l10n.spatialEducationPlaybackRateNormal,
    );

    await _selectPlaybackAction(tester, 'spatial-source-speed');
    _seek(tester, scene, (lesson.slowStart + lesson.slowEnd) / 2);
    await tester.pump();
    expect(
      _text(tester, 'spatial-playback-rate'),
      l10n.spatialEducationPlaybackRateNormal,
    );
  });

  for (final locale in const <Locale>[
    Locale('en'),
    Locale('ko'),
    Locale('ja'),
  ]) {
    testWidgets(
        'compact rate stays painted at 320px and 1.4 text in ${locale.languageCode}',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 740));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final scene = catalog.scenes.firstWhere(
        (value) =>
            value.education!.objective ==
            SpatialLearningObjective.switchingSpace,
      );
      final lesson = scene.education!;
      await tester.pumpWidget(
        _catalogApp(
          catalog,
          initialScene: scene,
          textScale: 1.4,
          locale: locale,
        ),
      );
      await _pumpLoaded(tester);
      _seek(tester, scene, (lesson.slowStart + lesson.slowEnd) / 2);
      await tester.pump();

      final rateFinder =
          find.byKey(const ValueKey<String>('spatial-playback-rate'));
      final rate = tester.widget<Text>(rateFinder).data!;
      final l10n = AppLocalizations.of(tester.element(rateFinder))!;
      expect(rate, l10n.spatialEducationPlaybackRateHalf);
      final paragraph = tester.renderObject<RenderParagraph>(rateFinder);
      expect(paragraph.didExceedMaxLines, isFalse);
      expect(
        paragraph.getBoxesForSelection(
          TextSelection(
            baseOffset: rate.length - 1,
            extentOffset: rate.length,
          ),
        ),
        isNotEmpty,
        reason: 'the trailing multiplication sign must be painted',
      );
      final rateRect = tester.getRect(rateFinder);
      final cardRect = tester.getRect(
        find.byKey(const ValueKey<String>('spatial-context')),
      );
      expect(cardRect.contains(rateRect.topRight), isTrue);
      expect(cardRect.contains(rateRect.bottomRight), isTrue);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('objective filters and season search share the existing sheet',
      (tester) async {
    await tester.pumpWidget(_catalogApp(catalog));
    await _pumpLoaded(tester);
    await tester.tap(
      find.byKey(const ValueKey<String>('spatial-scene-selector')),
    );
    await tester.pumpAndSettle();

    for (final objective in SpatialLearningObjective.values) {
      expect(
        find.byKey(ValueKey<String>('spatial-objective-${objective.name}')),
        findsOneWidget,
      );
    }
    expect(find.byKey(const ValueKey<String>('spatial-theme-lateralSwitch')),
        findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey<String>('spatial-search')),
      '2024/25',
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('spatial-result-count')),
      findsOneWidget,
    );
    expect(find.textContaining('2024/25'), findsWidgets);

    final chip = find.byKey(
      const ValueKey<String>('spatial-objective-thirdPlayer'),
    );
    await tester.ensureVisible(chip);
    await tester.pump();
    await tester.tap(chip);
    await tester.pump();
    expect(tester.widget<ChoiceChip>(chip).selected, isTrue);

    Navigator.of(tester.element(chip)).pop();
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('spatial-scene-selector')),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ChoiceChip>(
            find.byKey(
              const ValueKey<String>('spatial-objective-thirdPlayer'),
            ),
          )
          .selected,
      isTrue,
    );
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey<String>('spatial-search')),
          )
          .controller!
          .text,
      '2024/25',
    );
  });

  testWidgets('320px and 1.4 text keep the teaching card cue-clear',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final scene = catalog.scenes.firstWhere(
      (value) =>
          value.education!.objective == SpatialLearningObjective.pressureOutlet,
    );
    await tester.pumpWidget(
      _catalogApp(catalog, initialScene: scene, textScale: 1.4),
    );
    await _pumpLoaded(tester);
    _seek(tester, scene, scene.education!.outcome + .2);
    await tester.pump();

    final painter = _painter(tester);
    expect(painter.viewport.view.contains(painter.cueRect.topLeft), isTrue);
    expect(painter.viewport.view.contains(painter.cueRect.bottomRight), isTrue);
    for (final actor in painter.keyPlayerSafetyRects) {
      expect(painter.cueRect.overlaps(actor), isFalse);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('blue teaching focus is independent from gold source ownership',
      (tester) async {
    final scene = catalog.scenes.firstWhere((value) {
      final lesson = value.education!;
      final data = _replay(value);
      final owner =
          data.sourcePossessionOwners[(lesson.trigger * data.fps).round()];
      return owner != null && owner != lesson.focusActor.playerId;
    });
    await tester.pumpWidget(_catalogApp(catalog, initialScene: scene));
    await _pumpLoaded(tester);
    _seek(tester, scene, scene.education!.trigger);
    await tester.pump();
    final painter = _painter(tester);
    expect(
      painter.blueTeachingFocusPlayerIds,
      contains(scene.education!.focusActor.playerId),
    );
    expect(
      painter.goldOwnershipPlayerIds,
      isNot(contains(scene.education!.focusActor.playerId)),
    );
  });

  testWidgets('next connection appears only after its observed source time',
      (tester) async {
    final scene = catalog.scenes.firstWhere((value) {
      final lesson = value.education!;
      return lesson.objective == SpatialLearningObjective.pressureOutlet &&
          lesson.nextConnection! - lesson.outcome > 1;
    });
    final lesson = scene.education!;
    final data = _replay(scene);
    final nextLabel = _cueLabel(data, lesson.nextActor!.playerId);
    await tester.pumpWidget(_catalogApp(catalog, initialScene: scene));
    await _pumpLoaded(tester);

    _seek(tester, scene, lesson.outcome + .2);
    await tester.pump();
    expect(_text(tester, 'spatial-cue-line'), isNot(contains(nextLabel)));

    _seek(tester, scene, lesson.nextConnection!);
    await tester.pump();
    expect(_text(tester, 'spatial-cue-line'), contains(nextLabel));
  });

  testWidgets(
      'education rings and labels keep one blue focus and named comparison',
      (tester) async {
    final scene = catalog.scenes.firstWhere(
      (value) => value.id == '3442-1123-varane-combination',
    );
    final lesson = scene.education!;
    await tester.pumpWidget(_catalogApp(catalog, initialScene: scene));
    await _pumpLoaded(tester);
    _seek(tester, scene, lesson.outcome);
    await tester.pump();

    final painter = _painter(tester);
    expect(
      painter.blueTeachingFocusPlayerIds,
      <int>{lesson.focusActor.playerId},
    );
    expect(painter.legacyRoleRingPlayerIds, isEmpty);
    expect(
      painter.neutralEducationEmphasisPlayerIds,
      contains(lesson.opponentActors.single.playerId),
    );
    expect(
      painter.playerNameLabels.map((label) => label.playerId),
      containsAll(<int>[
        lesson.focusActor.playerId,
        lesson.opponentActors.single.playerId,
      ]),
    );
  });

  for (final configuration in <({
    Locale locale,
    Size size,
    String sceneId,
    double time,
    SpatialOnPitchActionKind kind,
  })>[
    for (final actionCase in <({
      String sceneId,
      double time,
      SpatialOnPitchActionKind kind,
    })>[
      (
        sceneId: '1925299-185-560983-thirdPlayer',
        time: 11.3,
        kind: SpatialOnPitchActionKind.receive,
      ),
      (
        sceneId: '1925299-185-560983-thirdPlayer',
        time: 11.8,
        kind: SpatialOnPitchActionKind.carry,
      ),
      (
        sceneId: '1925299-185-560983-thirdPlayer',
        time: 17.4,
        kind: SpatialOnPitchActionKind.oneTouchPass,
      ),
      (
        sceneId: '1925299-185-560983-thirdPlayer',
        time: 19,
        kind: SpatialOnPitchActionKind.header,
      ),
      (
        sceneId: '1925299-35928-560882-receivingLane',
        time: 19.7,
        kind: SpatialOnPitchActionKind.directionChange,
      ),
    ])
      for (final locale in const <Locale>[
        Locale('en'),
        Locale('ko'),
        Locale('ja'),
      ])
        for (final size in const <Size>[
          Size(390, 844),
          Size(320, 740),
          Size(667, 320),
        ])
          (
            locale: locale,
            size: size,
            sceneId: actionCase.sceneId,
            time: actionCase.time,
            kind: actionCase.kind,
          ),
  ]) {
    testWidgets(
        '${configuration.kind.name} icon stays actor-bound and clear in '
        '${configuration.locale.languageCode} ${configuration.size.width}x${configuration.size.height}',
        (tester) async {
      await tester.binding.setSurfaceSize(configuration.size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final scene = catalog.scenes.firstWhere(
        (value) => value.id == configuration.sceneId,
      );
      await tester.pumpWidget(
        _catalogApp(
          catalog,
          initialScene: scene,
          locale: configuration.locale,
          textScale: 1.4,
        ),
      );
      await _pumpLoaded(tester);
      _seek(tester, scene, configuration.time);
      await tester.pump();

      final painter = _painter(tester);
      final action = painter.activeAction;
      expect(action?.kind, configuration.kind);
      final icon = painter.actionIcon;
      expect(icon, isNotNull);
      final resolvedIcon = icon!;
      expect(resolvedIcon.actorPlayerId, action!.playerId);
      expect(resolvedIcon.eventId, action.eventId);
      expect(resolvedIcon.kind, action.kind);
      expect(resolvedIcon.attachmentDistance, lessThanOrEqualTo(24));
      expect(
        resolvedIcon.visualSize,
        anyOf(closeTo(32, .001), closeTo(36, .001), closeTo(40, .001)),
      );
      expect(resolvedIcon.hitRect.size, const Size.square(44));
      expect(resolvedIcon.hitTargetContainsVisual, isTrue);
      expect(
        painter.viewport.view.contains(resolvedIcon.visualRect.topLeft),
        isTrue,
      );
      expect(
        painter.viewport.view.contains(resolvedIcon.visualRect.bottomRight),
        isTrue,
      );
      expect(
        painter.viewport.view.contains(resolvedIcon.hitRect.topLeft),
        isTrue,
      );
      expect(
        painter.viewport.view.contains(resolvedIcon.hitRect.bottomRight),
        isTrue,
      );
      expect(resolvedIcon.hitRect.overlaps(painter.ballSafetyRect), isFalse);
      expect(
        painter.reservedOverlayRects.any(resolvedIcon.hitRect.overlaps),
        isFalse,
      );
      expect(
        painter.playerBadgeSafetyRects.any(resolvedIcon.hitRect.overlaps),
        isFalse,
      );
      expect(
        painter.playerNameLabels
            .any((label) => resolvedIcon.visualRect.overlaps(label.rect)),
        isFalse,
      );

      final localizedAction = _actionLabel(
        lookupAppLocalizations(configuration.locale),
        action.kind,
      );
      for (final name in painter.playerNameLabels) {
        expect(name.displayName, isNot(contains(localizedAction)));
        expect(name.displayName, isNot(contains('·')));
        expect(name.attachmentDistance, lessThanOrEqualTo(18));
      }
      expect(
        find.byKey(
          ValueKey<String>(
            'spatial-action-control-${resolvedIcon.sourceIdentity}',
          ),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('time-gated, hidden, and historical actions have no icon target',
      (tester) async {
    final cases = <(SpatialLibraryScene, double)>[
      (
        catalog.scenes.firstWhere(
          (scene) => scene.id == '1925299-185-560983-thirdPlayer',
        ),
        11,
      ),
      (
        catalog.scenes.firstWhere(
          (scene) => scene.id == '1996435-24085-25534-thirdPlayer',
        ),
        1.4,
      ),
      (catalog.scenes.firstWhere((scene) => scene.sourceActions.isEmpty), 10),
    ];
    for (final (scene, time) in cases) {
      await tester.pumpWidget(_catalogApp(catalog, initialScene: scene));
      await _pumpLoaded(tester);
      _seek(tester, scene, time);
      await tester.pump();

      expect(_painter(tester).activeAction, isNull);
      expect(_painter(tester).actionIcon, isNull);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget.key is ValueKey<String> &&
              ((widget.key! as ValueKey<String>).value)
                  .startsWith('spatial-action-control-'),
        ),
        findsNothing,
      );
    }
  });

  testWidgets('action icon exposes tap hover focus and keyboard meaning',
      (tester) async {
    final scene = catalog.scenes.firstWhere(
      (value) => value.id == '1925299-185-560983-thirdPlayer',
    );
    await tester.pumpWidget(_catalogApp(catalog, initialScene: scene));
    await _pumpLoaded(tester);
    _seek(tester, scene, 19);
    await tester.pump();

    final painter = _painter(tester);
    final action = painter.activeAction!;
    final icon = painter.actionIcon!;
    final control = find.byKey(
      ValueKey<String>('spatial-action-control-${icon.sourceIdentity}'),
    );
    final l10n = lookupAppLocalizations(const Locale('en'));
    final message = l10n.spatialActionSemantics(
      action.playerName,
      _actionLabel(l10n, action.kind),
    );
    final semantics = tester.getSemantics(control).getSemanticsData();
    expect(semantics.label, message);
    expect(semantics.hasAction(SemanticsAction.tap), isTrue);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(1, 1));
    await mouse.moveTo(tester.getCenter(control));
    await tester.pump();
    expect(find.text(message), findsOneWidget);
    await mouse.moveTo(Offset.zero);
    await tester.pumpAndSettle();
    expect(find.text(message), findsNothing);

    final focusable = tester.widget<FocusableActionDetector>(
      find.descendant(
        of: control,
        matching: find.byType(FocusableActionDetector),
      ),
    );
    focusable.focusNode!.requestFocus();
    await tester.pumpAndSettle();
    expect(find.text(message), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(find.text(message), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text(message), findsNothing);

    await tester.tap(control);
    await tester.pumpAndSettle();
    expect(find.text(message), findsOneWidget);
    await tester.tapAt(const Offset(2, 2));
    await tester.pumpAndSettle();
    expect(find.text(message), findsNothing);
    await tester.tap(control);
    await tester.pumpAndSettle();
    expect(find.text(message), findsOneWidget);
    await mouse.removePointer();
  });

  testWidgets('tap pauses action inspection and seek dismisses it',
      (tester) async {
    final scene = catalog.scenes.firstWhere(
      (value) => value.id == '1925299-185-560983-thirdPlayer',
    );
    await tester.pumpWidget(_catalogApp(catalog, initialScene: scene));
    await _pumpLoaded(tester);
    _seek(tester, scene, 19);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('spatial-play')));
    await tester.pump(const Duration(milliseconds: 120));

    var painter = _painter(tester);
    final action = painter.activeAction!;
    final icon = painter.actionIcon!;
    final control = find.byKey(
      ValueKey<String>('spatial-action-control-${icon.sourceIdentity}'),
    );
    final l10n = lookupAppLocalizations(const Locale('en'));
    final message = l10n.spatialActionSemantics(
      action.playerName,
      _actionLabel(l10n, action.kind),
    );
    await tester.tap(control);
    await tester.pump();
    final pausedAt = _painter(tester).time;
    expect(find.text(message), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
    expect(_painter(tester).time, closeTo(pausedAt, .001));

    await tester.tap(find.byKey(const ValueKey<String>('spatial-play')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(_painter(tester).time, greaterThan(pausedAt));
    painter = _painter(tester);
    expect(painter.actionIcon, isNotNull);

    _seek(tester, scene, 18.9);
    await tester.pumpAndSettle();
    expect(find.text(message), findsNothing);
  });

  testWidgets('pause and backward seek reproduce the same header source label',
      (tester) async {
    final scene = catalog.scenes.firstWhere(
      (value) => value.id == '1925299-185-560983-thirdPlayer',
    );
    await tester.pumpWidget(_catalogApp(catalog, initialScene: scene));
    await _pumpLoaded(tester);

    _seek(tester, scene, 19);
    await tester.pump();
    final first = _painter(tester).activeAction;
    expect((first?.eventId, first?.kind),
        ('8_9', SpatialOnPitchActionKind.header));
    await tester.pump(const Duration(milliseconds: 500));
    expect(_painter(tester).time, closeTo(19, .001));
    expect(_painter(tester).activeAction?.eventId, '8_9');

    _seek(tester, scene, 18.9);
    await tester.pump();
    expect(_painter(tester).activeAction?.eventId, isNot('8_9'));
    _seek(tester, scene, 19);
    await tester.pump();
    expect(_painter(tester).activeAction?.eventId, '8_9');
  });
}

String _cueLabel(RealMatchReplayData data, int playerId) {
  final player = data.player(playerId);
  final name = player.name!.trim().split(' ').last;
  return player.number == null ? name : '#${player.number} $name';
}

String _objectiveTitle(
  AppLocalizations l10n,
  SpatialLearningObjective objective,
) =>
    switch (objective) {
      SpatialLearningObjective.receivingLane =>
        l10n.spatialEducationObjectiveReceivingLane,
      SpatialLearningObjective.pressureOutlet =>
        l10n.spatialEducationObjectivePressureOutlet,
      SpatialLearningObjective.thirdPlayer =>
        l10n.spatialEducationObjectiveThirdPlayer,
      SpatialLearningObjective.switchingSpace =>
        l10n.spatialEducationObjectiveSwitchingSpace,
    };

String _actionLabel(
  AppLocalizations l10n,
  SpatialOnPitchActionKind kind,
) =>
    switch (kind) {
      SpatialOnPitchActionKind.carry => l10n.spatialActionCarry,
      SpatialOnPitchActionKind.directionChange =>
        l10n.spatialActionDirectionChange,
      SpatialOnPitchActionKind.receive => l10n.spatialActionReceive,
      SpatialOnPitchActionKind.header => l10n.spatialActionHeader,
      SpatialOnPitchActionKind.oneTouchPass => l10n.spatialActionOneTouchPass,
    };

Future<void> _selectPlaybackAction(
  WidgetTester tester,
  String actionKey,
) async {
  await tester.tap(find.byKey(const ValueKey<String>('spatial-more')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ValueKey<String>(actionKey)));
  await tester.pump();
}

Widget _catalogApp(
  SpatialLibraryCatalog catalog, {
  SpatialLibraryScene? initialScene,
  double textScale = 1,
  Locale locale = const Locale('en'),
  OptionRepository? options,
}) {
  final ordered = initialScene == null
      ? catalog
      : SpatialLibraryCatalog(
          version: catalog.version,
          provider: catalog.provider,
          license: catalog.license,
          sourceCommit: catalog.sourceCommit,
          sourceUrl: catalog.sourceUrl,
          matchCount: catalog.matchCount,
          scenes: <SpatialLibraryScene>[
            initialScene,
            ...catalog.scenes.where((value) => value.id != initialScene.id),
          ],
          proofVersion: catalog.proofVersion,
          sourcePins: catalog.sourcePins,
        );
  return MaterialApp(
    locale: locale,
    theme: ThemeData.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
      ),
      child: child!,
    ),
    home: ScanPassSpatialLibraryScreen(
      optionRepository: options,
      catalogLoader: () async => ordered,
      sceneLoader: (scene) async => _replay(scene),
    ),
  );
}

Future<void> _pumpLoaded(WidgetTester tester) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    await tester.pump();
    if (find
        .byKey(const ValueKey<String>('spatial-pitch'))
        .evaluate()
        .isNotEmpty) {
      return;
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
  }
  fail('Spatial education library did not load.');
}

Future<void> _pumpScene(WidgetTester tester, String sceneId) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    await tester.pump();
    if (find
            .byKey(const ValueKey<String>('spatial-pitch'))
            .evaluate()
            .isNotEmpty &&
        _painter(tester).scene.id == sceneId) {
      return;
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
  }
  fail('Spatial education scene $sceneId did not load.');
}

void _seek(
  WidgetTester tester,
  SpatialLibraryScene scene,
  double time,
) {
  tester
      .widget<Slider>(
        find.byKey(const ValueKey<String>('spatial-progress')),
      )
      .onChanged!(time / scene.duration);
}

String _text(WidgetTester tester, String key) =>
    tester.widget<Text>(find.byKey(ValueKey<String>(key))).data!;

SpatialLibraryPitchPainter _painter(WidgetTester tester) => tester
    .widget<CustomPaint>(
      find.byKey(const ValueKey<String>('spatial-pitch')),
    )
    .painter! as SpatialLibraryPitchPainter;

RealMatchReplayData _replay(SpatialLibraryScene scene) =>
    RealMatchReplayData.fromJsonString(File(scene.asset).readAsStringSync());

class _MemoryOptions implements OptionRepository {
  final Map<String, dynamic> values = <String, dynamic>{};

  @override
  List<int> getIntOptions(String key, List<int> defaults) => defaults;

  @override
  List<String> getOptions(String key, List<String> defaults) => defaults;

  @override
  T? getValue<T>(String key) => values[key] is T ? values[key] as T : null;

  @override
  Future<void> saveOptions(String key, List<dynamic> options) async {
    values[key] = options;
  }

  @override
  Future<void> setValue(String key, dynamic value) async {
    values[key] = value;
  }
}

class _DelayedWriteOptions extends _MemoryOptions {
  bool delayNextWrite = false;
  bool writeBlocked = false;
  final Completer<void> releaseWrite = Completer<void>();

  @override
  Future<void> setValue(String key, dynamic value) async {
    if (delayNextWrite) {
      delayNextWrite = false;
      writeBlocked = true;
      await releaseWrite.future;
    }
    await super.setValue(key, value);
  }
}
