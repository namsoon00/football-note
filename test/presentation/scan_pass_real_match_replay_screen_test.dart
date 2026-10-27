import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/domain/scan_pass/real_match_replay.dart';
import 'package:football_note/domain/scan_pass/real_match_replay_detail.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/scan_pass_game_screen.dart';
import 'package:football_note/presentation/theme/app_theme.dart';

late RealMatchReplayData _testReplay;
late RealMatchReplayCatalog _testCatalog;
late Map<String, RealMatchReplayData> _testScenes;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  setUpAll(() {
    _testReplay = RealMatchReplayData.fromJsonString(
      File('assets/scan_pass_replay/replay-data.json').readAsStringSync(),
    );
    _testCatalog = RealMatchReplayCatalog.fromJsonString(
      File('assets/scan_pass_replay/catalog.json').readAsStringSync(),
    );
    _testScenes = <String, RealMatchReplayData>{
      for (final scene in _testCatalog.scenes)
        scene.id: RealMatchReplayData.fromJsonString(
          File(scene.asset).readAsStringSync(),
        ),
    };
  });

  testWidgets('default viewer is paused, visual, and has one playback control',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_app());
    await _pumpLoaded(tester);
    final l10n = _l10n(tester);

    expect(find.byKey(const ValueKey<String>('replay-pitch')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('replay-play')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('replay-more')), findsOneWidget);
    expect(
        find.byKey(const ValueKey<String>('replay-moment-0')), findsOneWidget);
    expect(find.text(l10n.realMatchReplayNextAction), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
    for (final removed in <String>[
      'replay-scrub',
      'replay-time',
      'replay-explanation',
      'replay-speed',
      'replay-zoom',
      'replay-chapters',
      'replay-expand',
      'replay-previous-scene',
      'replay-next-scene',
    ]) {
      expect(find.byKey(ValueKey<String>(removed)), findsNothing,
          reason: removed);
    }
    final pitch = find.byKey(const ValueKey<String>('replay-pitch'));
    expect(tester.getSize(pitch).height, greaterThan(390));
    expect(
      tester.getSemantics(pitch).label,
      contains('actual tracked positions'),
    );
    final initialTime = _sourceTime(tester);
    await tester.pump(const Duration(seconds: 1));
    expect(_sourceTime(tester), initialTime);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('one control plays to a stop, pauses, and resumes mid-action',
      (tester) async {
    await tester.pumpWidget(_app());
    await _pumpLoaded(tester);
    final l10n = _l10n(tester);
    final plan = RealMatchReplayCoachingPlan.forData(_testReplay);

    await _tap(tester, 'replay-play');
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text(l10n.realMatchReplayPauseAction), findsOneWidget);
    final pausedAt = _sourceTime(tester);
    expect(pausedAt, inExclusiveRange(0, .6));

    await _tap(tester, 'replay-play');
    expect(find.text(l10n.realMatchReplayNextAction), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(_sourceTime(tester), closeTo(pausedAt, .001));

    await _tap(tester, 'replay-play');
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(
        find.byKey(const ValueKey<String>('replay-moment-1')), findsOneWidget);
    expect(find.text(l10n.realMatchReplayNextAction), findsOneWidget);
    expect(_sourceTime(tester), closeTo(plan.moments[1].time, .02));
    expect(tester.takeException(), isNull);
  });

  testWidgets('every coaching click reaches the true end and replay restarts',
      (tester) async {
    await tester.pumpWidget(_app());
    await _pumpLoaded(tester);
    final l10n = _l10n(tester);
    final plan = RealMatchReplayCoachingPlan.forData(_testReplay);

    for (var index = 1; index < plan.moments.length; index++) {
      final delta = plan.moments[index].time - plan.moments[index - 1].time;
      await _tap(tester, 'replay-play');
      await tester.pump(
        Duration(milliseconds: (delta * 1000).round() + 80),
      );
      expect(
        find.byKey(ValueKey<String>('replay-moment-$index')),
        findsOneWidget,
        reason: 'moment $index at ${plan.moments[index].time}',
      );
      if (index < plan.moments.length - 1) {
        expect(find.text(l10n.realMatchReplayNextAction), findsOneWidget);
      }
    }

    expect(_sourceTime(tester), closeTo(_testReplay.duration, .02));
    expect(find.text(l10n.realMatchReplayReplayAction), findsOneWidget);
    await _tap(tester, 'replay-play');
    await tester.pump(const Duration(milliseconds: 100));
    expect(
        find.byKey(const ValueKey<String>('replay-moment-0')), findsOneWidget);
    expect(find.text(l10n.realMatchReplayPauseAction), findsOneWidget);
    expect(_sourceTime(tester), lessThan(.2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('app lifecycle pauses at the same recorded source position',
      (tester) async {
    await tester.pumpWidget(_app());
    await _pumpLoaded(tester);
    final l10n = _l10n(tester);
    await _tap(tester, 'replay-play');
    await tester.pump(const Duration(milliseconds: 300));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    final pausedAt = _sourceTime(tester);
    expect(find.text(l10n.realMatchReplayNextAction), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(_sourceTime(tester), closeTo(pausedAt, .001));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(tester.takeException(), isNull);
  });

  testWidgets('public camera stays on the stable overview without controls',
      (tester) async {
    await tester.pumpWidget(_app());
    await _pumpLoaded(tester);
    final contextWidth = _camera(tester).width as double;
    final plan = RealMatchReplayCoachingPlan.forData(_testReplay);
    final closeIndex = plan.moments.indexWhere(
      (moment) => moment.view == RealMatchReplayCoachingView.close,
    );
    expect(closeIndex, greaterThan(0));
    expect(
      plan.cameraAt(_testReplay, plan.moments[closeIndex].time).width,
      lessThan(_testReplay.scene.camera.width),
      reason: 'The recorded-evidence automatic camera remains a domain API.',
    );

    for (var index = 1; index <= closeIndex; index++) {
      final delta = plan.moments[index].time - plan.moments[index - 1].time;
      await _tap(tester, 'replay-play');
      await tester.pump(
        Duration(milliseconds: (delta * 1000).round() + 80),
      );
    }
    final closeWidth = _camera(tester).width as double;
    expect(closeWidth, closeTo(contextWidth, 1e-9));

    final nextContextIndex = plan.moments.indexWhere(
      (moment) => moment.view == RealMatchReplayCoachingView.context,
      closeIndex + 1,
    );
    expect(nextContextIndex, greaterThan(closeIndex));
    for (var index = closeIndex + 1; index <= nextContextIndex; index++) {
      final delta = plan.moments[index].time - plan.moments[index - 1].time;
      await _tap(tester, 'replay-play');
      await tester.pump(
        Duration(milliseconds: (delta * 1000).round() + 80),
      );
    }
    expect(_camera(tester).width as double, closeTo(contextWidth, .01));
    expect(
        find.byKey(const ValueKey<String>('replay-view-close')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('only supported action badges open the localized close-up',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_app(locale: const Locale('ko')));
    await _pumpLoaded(tester);

    expect(find.text('동작 확대'), findsNothing);
    expect(find.byKey(const ValueKey<String>('replay-action-detail-open')),
        findsNothing);
    await _advanceToAction(tester, _testReplay, RealMatchReplayStepKind.pass);
    final open = find.byKey(
      const ValueKey<String>('replay-action-detail-open'),
    );
    expect(open, findsOneWidget);
    expect(find.text('동작 확대'), findsOneWidget);
    expect(tester.getSemantics(open).label, contains('패스'));

    await tester.tap(open);
    await tester.pump();
    expect(find.text('패스 방향'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('replay-detail-pitch')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('replay-detail-overview')),
        findsOneWidget);
    semantics.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'detail replays slowly, pauses, reaches exact end, and leaves main time unchanged',
      (tester) async {
    final data = _testScenes['transition-wing']!;
    await tester.pumpWidget(_app(
      home: ScanPassRealMatchReplayScreen(dataLoader: () async => data),
    ));
    await _pumpLoaded(tester);
    await _advanceToAction(tester, data, RealMatchReplayStepKind.receive);
    final openedAt = _sourceTime(tester);
    await _tap(tester, 'replay-action-detail-open');
    final detail = _detailModel(tester);
    final initial = _detailTime(tester);
    expect(initial, closeTo(detail.start, .001));

    await tester.pump(const Duration(milliseconds: 400));
    expect(
      _detailTime(tester) - initial,
      closeTo(.4 * RealMatchReplayActionDetail.playbackRate, .025),
    );
    await _tap(tester, 'replay-detail-play');
    final pausedAt = _detailTime(tester);
    await tester.pump(const Duration(seconds: 1));
    expect(_detailTime(tester), closeTo(pausedAt, .001));
    await _tap(tester, 'replay-detail-play');
    await tester.pump(Duration(
      milliseconds:
          (detail.duration / RealMatchReplayActionDetail.playbackRate * 1000)
                  .ceil() +
              80,
    ));
    expect(_detailTime(tester), closeTo(detail.end, .001));
    expect(
        find.text(_l10n(tester).realMatchReplayReplayAction), findsOneWidget);

    await _tap(tester, 'replay-detail-play');
    await tester.pump(const Duration(milliseconds: 100));
    expect(
        _detailTime(tester),
        closeTo(
          detail.start + .1 * RealMatchReplayActionDetail.playbackRate,
          .02,
        ));
    await _tap(tester, 'replay-detail-close');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('replay-detail-pitch')),
        findsNothing);
    expect(_sourceTime(tester), closeTo(openedAt, .001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a carry between teaching stops can be inspected while playing',
      (tester) async {
    final data = _testScenes['vinicius-carry-inside']!;
    await tester.pumpWidget(_app(
      home: ScanPassRealMatchReplayScreen(dataLoader: () async => data),
    ));
    await _pumpLoaded(tester);
    await _advanceToAction(tester, data, RealMatchReplayStepKind.receive);
    await _tap(tester, 'replay-play');
    await tester.pump(const Duration(milliseconds: 800));
    final openedAt = _sourceTime(tester);
    expect(data.stepAt(openedAt).kind, RealMatchReplayStepKind.carry);
    final open =
        find.byKey(const ValueKey<String>('replay-action-detail-open'));
    expect(tester.getSize(open).height, greaterThanOrEqualTo(44));
    await _tap(tester, 'replay-action-detail-open');
    expect(_detailModel(tester).step.kind, RealMatchReplayStepKind.carry);
    expect(find.text(_l10n(tester).realMatchReplayActionDetailCarryTitle),
        findsOneWidget);
    await tester.pump(const Duration(milliseconds: 350));
    await _tap(tester, 'replay-detail-close');
    await tester.pumpAndSettle();
    expect(_sourceTime(tester), closeTo(openedAt, .001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('detail lifecycle pause and route disposal are safe',
      (tester) async {
    await tester.pumpWidget(_app());
    await _pumpLoaded(tester);
    await _advanceToAction(tester, _testReplay, RealMatchReplayStepKind.pass);
    final openedAt = _sourceTime(tester);
    await _tap(tester, 'replay-action-detail-open');
    await tester.pump(const Duration(milliseconds: 180));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    final pausedAt = _detailTime(tester);
    await tester.pump(const Duration(seconds: 1));
    expect(_detailTime(tester), closeTo(pausedAt, .001));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('replay-detail-pitch')),
        findsNothing);
    expect(_sourceTime(tester), closeTo(openedAt, .001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('historical detail states simplified pose and XY-only evidence',
      (tester) async {
    final messi = _testScenes['messi-right-connection']!;
    await tester.pumpWidget(_app(
      home: ScanPassRealMatchReplayScreen(dataLoader: () async => messi),
    ));
    await _pumpLoaded(tester);
    await _advanceToAction(tester, messi, RealMatchReplayStepKind.receive);
    await _tap(tester, 'replay-action-detail-open');
    final l10n = _l10n(tester);

    expect(find.text(l10n.realMatchReplayActionDetailSimplifiedPose),
        findsOneWidget);
    expect(find.text(l10n.realMatchReplayActionDetailHeightXy), findsOneWidget);
    expect(
      find.text(l10n.realMatchReplayActionDetailOverviewReconstructed),
      findsOneWidget,
    );
    final dynamic overviewPainter = tester
        .widget<CustomPaint>(
          find.byKey(const ValueKey<String>('replay-detail-overview')),
        )
        .painter;
    expect(overviewPainter.visiblePlayerCount as int, 22);
    expect(
      tester
          .getSemantics(
            find.byKey(const ValueKey<String>('replay-detail-pitch')),
          )
          .label,
      contains('simplified body motion'),
    );
    expect(tester.takeException(), isNull);
  });

  for (final locale in const <Locale>[
    Locale('en'),
    Locale('ko'),
    Locale('ja'),
  ]) {
    for (final viewport in const <Size>[
      Size(320, 760),
      Size(360, 760),
      Size(667, 320),
      Size(844, 390),
    ]) {
      testWidgets(
          '${locale.languageCode} detail protects close-up and 22-player map at ${viewport.width}x${viewport.height}',
          (tester) async {
        tester.view.physicalSize = viewport;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(_app(
          locale: locale,
          appTheme: true,
          textScale: 1.4,
          home: ScanPassRealMatchReplayScreen(
            dataLoader: () async => _testScenes['transition-wing']!,
          ),
        ));
        await _pumpLoaded(tester);
        await _advanceToAction(
          tester,
          _testScenes['transition-wing']!,
          RealMatchReplayStepKind.receive,
        );
        await _tap(tester, 'replay-action-detail-open');
        await tester.pump(const Duration(milliseconds: 350));

        final closeUp = find.byKey(
          const ValueKey<String>('replay-detail-pitch'),
        );
        final overview = find.byKey(
          const ValueKey<String>('replay-detail-overview'),
        );
        final control = find.byKey(
          const ValueKey<String>('replay-detail-play'),
        );
        final dynamic detailPainter =
            tester.widget<CustomPaint>(closeUp).painter;
        final dynamic overviewPainter =
            tester.widget<CustomPaint>(overview).painter;
        final mainCamera = _camera(tester);
        expect(detailPainter.isActionDetail as bool, isTrue);
        expect(
            detailPainter.bodyScaleMinimum as double, greaterThanOrEqualTo(38));
        expect((detailPainter.camera as RealMatchReplayCamera).width,
            lessThan(mainCamera.width as double));
        expect(overviewPainter.visiblePlayerCount as int, 22);
        expect(tester.getSize(closeUp).width, greaterThan(180));
        expect(tester.getSize(closeUp).height, greaterThan(120));
        expect(tester.getSize(overview).height, greaterThan(45));
        expect(tester.getRect(closeUp).overlaps(tester.getRect(overview)),
            isFalse);
        expect(
            tester.getRect(closeUp).overlaps(tester.getRect(control)), isFalse);
        expect(find.byKey(const ValueKey<String>('replay-detail-phase-cue')),
            findsOneWidget);
        expect(control.hitTestable(), findsOneWidget);
        expect(find.byKey(const ValueKey<String>('replay-detail-close')),
            findsOneWidget);
        expect(tester.takeException(), isNull);

        await _tap(tester, 'replay-detail-close');
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey<String>('replay-detail-pitch')),
            findsNothing);
      });
    }
  }

  testWidgets('scene library stays behind overflow and reaches all categories',
      (tester) async {
    await tester.pumpWidget(_catalogApp());
    await _pumpLoaded(tester);
    final l10n = _l10n(tester);

    expect(find.text(l10n.realMatchReplaySceneCount(1, 25)), findsNothing);
    await _openSceneLibrary(tester);
    expect(find.text(l10n.realMatchReplaySceneLibraryTitle), findsOneWidget);
    final turnover =
        find.byKey(const ValueKey<String>('replay-category-turnover'));
    await tester.ensureVisible(turnover);
    await tester.tap(turnover);
    await tester.pumpAndSettle();
    await _selectOpenScene(tester, 'carry-turnover');
    await tester.pumpAndSettle();
    await _pumpLoaded(tester);

    expect(find.text(l10n.replaySceneCarryTurnover), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('replay-play')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('replay-tracking-only')),
        findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('late scene load cannot replace a newer overflow selection',
      (tester) async {
    final keeper = Completer<RealMatchReplayData>();
    final central = Completer<RealMatchReplayData>();
    await tester.pumpWidget(_app(
      home: ScanPassRealMatchReplayScreen(
        catalogLoader: () async => _testCatalog,
        sceneLoader: (scene) {
          if (scene.id == 'transition-wing') {
            return Future<RealMatchReplayData>.value(_testScenes[scene.id]!);
          }
          if (scene.id == 'keeper-build') return keeper.future;
          if (scene.id == 'central-build') return central.future;
          return Future<RealMatchReplayData>.value(_testScenes[scene.id]!);
        },
      ),
    ));
    await _pumpLoaded(tester);

    await _openSceneLibrary(tester);
    await _selectOpenScene(tester, 'keeper-build');
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await _openSceneLibrary(tester);
    await _selectOpenScene(tester, 'central-build');
    await tester.pump(const Duration(milliseconds: 350));

    central.complete(_testScenes['central-build']!);
    await tester.pump();
    await tester.pump();
    final l10n = _l10n(tester);
    expect(find.text(l10n.replaySceneCentralBuild), findsOneWidget);
    keeper.complete(_testScenes['keeper-build']!);
    await tester.pump();
    await tester.pump();
    expect(find.text(l10n.replaySceneCentralBuild), findsOneWidget);
    expect(find.text(l10n.replaySceneKeeperBuild), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('catalog failure offers a working localized retry',
      (tester) async {
    var attempts = 0;
    await tester.pumpWidget(_app(
      locale: const Locale('ko'),
      home: ScanPassRealMatchReplayScreen(
        catalogLoader: () async {
          attempts++;
          if (attempts == 1) throw StateError('temporary');
          return _testCatalog;
        },
        sceneLoader: (scene) async => _testScenes[scene.id]!,
      ),
    ));
    await tester.pump();
    final l10n = _l10n(tester);
    expect(find.text(l10n.realMatchReplayLoadFailed), findsOneWidget);
    await tester.tap(find.text(l10n.realMatchReplayRetry));
    await _pumpLoaded(tester);
    expect(find.byKey(const ValueKey<String>('replay-pitch')), findsOneWidget);
    expect(attempts, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('scene information discloses tracking and source provenance',
      (tester) async {
    Uri? openedSource;
    await tester.pumpWidget(_app(
      home: ScanPassRealMatchReplayScreen(
        sourceLauncher: (uri) async {
          openedSource = uri;
          return false;
        },
        catalogLoader: () async => _testCatalog,
        sceneLoader: (scene) async => _testScenes[scene.id]!,
      ),
    ));
    await _pumpLoaded(tester);
    final l10n = _l10n(tester);
    expect(
      find.byKey(const ValueKey<String>('replay-reconstructed-legend')),
      findsOneWidget,
    );
    expect(find.text(l10n.realMatchReplayReconstructedLegend), findsOneWidget);
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey<String>('replay-pitch')))
          .label,
      contains('clearly marked reconstructed display positions'),
    );

    await _openMenu(tester);
    await tester.tap(find.byKey(const ValueKey<String>('replay-scene-info')));
    await tester.pumpAndSettle();
    final first = _testScenes[_testCatalog.scenes.first.id]!;
    expect(find.text(l10n.realMatchReplaySceneInfo), findsOneWidget);
    expect(find.textContaining(first.sourceCommit), findsOneWidget);
    expect(find.text(l10n.realMatchReplayBroadcastDisclosure), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('replay-source')));
    await tester.pumpAndSettle();
    expect(openedSource.toString(), first.sourceUrl);
    expect(find.text(l10n.realMatchReplaySourceUnavailable), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('all 25 distinct payloads play through their true endpoint',
      (tester) async {
    for (final entry in _testCatalog.scenes) {
      final data = _testScenes[entry.id]!;
      await tester.pumpWidget(_app(
        home: ScanPassRealMatchReplayScreen(
          key: ValueKey<String>(entry.id),
          dataLoader: () async => data,
        ),
      ));
      await _pumpLoaded(tester);
      expect(find.byKey(const ValueKey<String>('replay-pitch')), findsOneWidget,
          reason: entry.id);
      expect(find.byType(FilledButton), findsOneWidget, reason: entry.id);
      expect(
          find.byKey(const ValueKey<String>('replay-moment-0')), findsOneWidget,
          reason: entry.id);
      final dynamic painter = tester
          .widget<CustomPaint>(
            find.byKey(const ValueKey<String>('replay-pitch')),
          )
          .painter;
      expect((painter.data as RealMatchReplayData).scene.id, entry.id);
      final plan = RealMatchReplayCoachingPlan.forData(data);
      for (var index = 1; index < plan.moments.length; index++) {
        final delta = plan.moments[index].time - plan.moments[index - 1].time;
        await _tap(tester, 'replay-play');
        await tester.pump(
          Duration(milliseconds: (delta * 1000).round() + 80),
        );
        expect(_sourceTime(tester), closeTo(plan.moments[index].time, .001),
            reason: '${entry.id} moment $index');
      }
      expect(_sourceTime(tester), data.duration, reason: entry.id);
      expect(
          find.text(_l10n(tester).realMatchReplayReplayAction), findsOneWidget,
          reason: entry.id);
      expect(tester.takeException(), isNull, reason: entry.id);
    }
  });

  testWidgets('European default and library expose player and team names',
      (tester) async {
    await tester.pumpWidget(_catalogApp());
    await _pumpLoaded(tester);
    final l10n = _l10n(tester);
    expect(find.text(l10n.replaySceneDeBruynePressureReceive), findsOneWidget);
    expect(
      find.text(
        l10n.realMatchReplaySelectedMatch('Manchester City', 'Liverpool'),
      ),
      findsOneWidget,
    );
    await _openSceneLibrary(tester);
    expect(find.textContaining('Manchester City'), findsWidgets);
    expect(find.textContaining('2020-07-02'), findsWidgets);
    expect(find.text(l10n.replaySceneSalahRightRecycle), findsOneWidget);
    await _selectOpenScene(tester, 'messi-right-connection');
    await _pumpLoaded(tester);
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey<String>('replay-scene-title')),
          )
          .data,
      l10n.replaySceneMessiRightConnection,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('XY-only historical source disclosure states no inferred height',
      (tester) async {
    await tester.pumpWidget(_catalogApp());
    await _pumpLoaded(tester);
    await _openSceneLibrary(tester);
    await _selectOpenScene(tester, 'messi-right-connection');
    await _pumpLoaded(tester);
    await _openMenu(tester);
    await tester.tap(find.byKey(const ValueKey<String>('replay-scene-info')));
    await tester.pumpAndSettle();
    expect(
      find.text(_l10n(tester).realMatchReplayBallHeightUnavailable),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'catalog rejects a scene payload from a different source revision',
      (tester) async {
    final entry = _testCatalog.scenes.first;
    final source = jsonDecode(File(entry.asset).readAsStringSync())
        as Map<String, dynamic>;
    source['sourceCommit'] = 'wrong-source-revision';
    final mismatched = RealMatchReplayData.fromJson(source);
    await tester.pumpWidget(_app(
      home: ScanPassRealMatchReplayScreen(
        catalogLoader: () async => _testCatalog,
        sceneLoader: (_) async => mismatched,
      ),
    ));
    await tester.pump();
    await tester.pump();
    expect(
      find.text(_l10n(tester).realMatchReplayLoadFailed),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('pausing within the last source frame still offers continuation',
      (tester) async {
    await tester.pumpWidget(_app());
    await _pumpLoaded(tester);
    final plan = RealMatchReplayCoachingPlan.forData(_testReplay);
    for (var index = 1; index < plan.moments.length - 1; index++) {
      await _tap(tester, 'replay-play');
      await tester.pump(Duration(
        milliseconds:
            ((plan.moments[index].time - plan.moments[index - 1].time) * 1000)
                    .round() +
                80,
      ));
    }
    final remaining = _testReplay.duration - _sourceTime(tester);
    await _tap(tester, 'replay-play');
    await tester.pump(Duration(milliseconds: (remaining * 1000).round() - 10));
    await _tap(tester, 'replay-play');
    expect(_sourceTime(tester), lessThan(_testReplay.duration));
    expect(find.text(_l10n(tester).realMatchReplayNextAction), findsOneWidget);
    expect(find.text(_l10n(tester).realMatchReplayReplayAction), findsNothing);
    await _tap(tester, 'replay-play');
    await tester.pump(const Duration(milliseconds: 30));
    expect(_sourceTime(tester), _testReplay.duration);
    expect(tester.takeException(), isNull);
  });

  testWidgets('scene information scrolls in short landscape with large text',
      (tester) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app(textScale: 1.4, appTheme: true));
    await _pumpLoaded(tester);
    await _openMenu(tester);
    await tester.tap(find.byKey(const ValueKey<String>('replay-scene-info')));
    await tester.pumpAndSettle();
    final source = find.byKey(const ValueKey<String>('replay-source'));
    await tester.ensureVisible(source);
    await tester.pumpAndSettle();
    expect(source.hitTestable(), findsOneWidget);
    expect(tester.getRect(source).bottom, lessThanOrEqualTo(390));
    expect(tester.takeException(), isNull);
  });

  for (final locale in const <Locale>[
    Locale('en'),
    Locale('ko'),
    Locale('ja'),
  ]) {
    for (final width in <double>[320, 360]) {
      testWidgets(
          '${locale.languageCode} keeps the pitch and one CTA at ${width}px',
          (tester) async {
        tester.view.physicalSize = Size(width, 760);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(_catalogAppFor(
          locale: locale,
          appTheme: true,
          textScale: 1.4,
        ));
        await _pumpLoaded(tester);
        final pitch = find.byKey(const ValueKey<String>('replay-pitch'));
        final control = find.byKey(const ValueKey<String>('replay-play'));
        expect(
          find.text(_l10n(tester).realMatchReplayReconstructedLegend),
          findsOneWidget,
        );
        expect(tester.getSize(pitch).height, greaterThan(520));
        expect(control.hitTestable(), findsOneWidget);
        expect(tester.getRect(control).bottom, lessThanOrEqualTo(760));
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('844x390 landscape and dark theme devote most space to play',
      (tester) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_catalogAppFor(
      locale: const Locale('ja'),
      appTheme: true,
      dark: true,
      textScale: 1.4,
    ));
    await _pumpLoaded(tester);

    final pitch = find.byKey(const ValueKey<String>('replay-pitch'));
    expect(tester.getSize(pitch).height, greaterThan(350));
    final control = find.byKey(const ValueKey<String>('replay-play'));
    expect(
        tester.getRect(control).left, greaterThan(tester.getRect(pitch).right));
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(find.byKey(const ValueKey<String>('replay-play')).hitTestable(),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Korean playback labels match the approved interaction',
      (tester) async {
    await tester.pumpWidget(_app(locale: const Locale('ko')));
    await _pumpLoaded(tester);
    expect(find.text('다음 동작'), findsOneWidget);
    await _tap(tester, 'replay-play');
    await tester.pump();
    expect(find.text('멈추기'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('public ScanPassGameScreen enters the spatial library',
      (tester) async {
    await tester.pumpWidget(_app(
      home: ScanPassGameScreen(optionRepository: _Options()),
    ));
    for (var attempt = 0; attempt < 30; attempt++) {
      await tester.pump();
      if (find
          .byKey(const ValueKey<String>('spatial-pitch'))
          .evaluate()
          .isNotEmpty) {
        break;
      }
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
    }
    expect(find.byType(ScanPassSpatialLibraryScreen), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('spatial-play')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('replay-play')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

AppLocalizations _l10n(WidgetTester tester) => AppLocalizations.of(
      tester.element(find.byType(ScanPassRealMatchReplayScreen)),
    )!;

double _sourceTime(WidgetTester tester) {
  final customPaint = tester.widget<CustomPaint>(
    find.byKey(const ValueKey<String>('replay-pitch')),
  );
  final dynamic painter = customPaint.painter;
  return painter.time as double;
}

dynamic _camera(WidgetTester tester) {
  final customPaint = tester.widget<CustomPaint>(
    find.byKey(const ValueKey<String>('replay-pitch')),
  );
  final dynamic painter = customPaint.painter;
  return painter.camera;
}

double _detailTime(WidgetTester tester) {
  final customPaint = tester.widget<CustomPaint>(
    find.byKey(const ValueKey<String>('replay-detail-pitch')),
  );
  final dynamic painter = customPaint.painter;
  return painter.time as double;
}

RealMatchReplayActionDetail _detailModel(WidgetTester tester) {
  final customPaint = tester.widget<CustomPaint>(
    find.byKey(const ValueKey<String>('replay-detail-pitch')),
  );
  final dynamic painter = customPaint.painter;
  return painter.actionDetail as RealMatchReplayActionDetail;
}

Future<void> _advanceToAction(
  WidgetTester tester,
  RealMatchReplayData data,
  RealMatchReplayStepKind kind,
) async {
  final plan = RealMatchReplayCoachingPlan.forData(data);
  final target = plan.moments.indexWhere((moment) => moment.step.kind == kind);
  expect(target, greaterThanOrEqualTo(0), reason: '$kind is not in the plan');
  var current = plan.momentIndexAt(_sourceTime(tester));
  while (current < target) {
    final delta = plan.moments[current + 1].time - _sourceTime(tester);
    await _tap(tester, 'replay-play');
    await tester.pump(
      Duration(milliseconds: (delta * 1000).round() + 80),
    );
    current++;
  }
}

Future<void> _tap(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey<String>(key));
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
}

Future<void> _openMenu(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey<String>('replay-more')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _openSceneLibrary(WidgetTester tester) async {
  await _openMenu(tester);
  await tester.tap(find.byKey(const ValueKey<String>('replay-choose-scene')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

Future<void> _selectOpenScene(WidgetTester tester, String id) async {
  final scene = find.byKey(ValueKey<String>('replay-scene-$id'));
  for (var attempt = 0; scene.evaluate().isEmpty && attempt < 30; attempt++) {
    await tester.drag(find.byType(ListView), const Offset(0, -240));
    await tester.pump();
  }
  await tester.ensureVisible(scene);
  await tester.pump();
  await tester.tap(scene);
  await tester.pump();
}

Future<void> _pumpLoaded(WidgetTester tester) async {
  await tester.pump();
  for (var attempt = 0; attempt < 30; attempt++) {
    if (find
        .byKey(const ValueKey<String>('replay-pitch'))
        .evaluate()
        .isNotEmpty) {
      return;
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
  fail('Replay asset did not load.');
}

Widget _app({
  Widget? home,
  Locale locale = const Locale('en'),
  bool appTheme = false,
  bool dark = false,
  double textScale = 1,
}) =>
    MaterialApp(
      theme: appTheme ? AppTheme.light() : null,
      darkTheme: appTheme ? AppTheme.dark() : null,
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: home ??
          ScanPassRealMatchReplayScreen(
            dataLoader: () async => _testReplay,
          ),
    );

Widget _catalogApp() => _app(
      home: ScanPassRealMatchReplayScreen(
        catalogLoader: () async => _testCatalog,
        sceneLoader: (scene) async => _testScenes[scene.id]!,
      ),
    );

Widget _catalogAppFor({
  required Locale locale,
  required bool appTheme,
  bool dark = false,
  required double textScale,
}) =>
    _app(
      locale: locale,
      appTheme: appTheme,
      dark: dark,
      textScale: textScale,
      home: ScanPassRealMatchReplayScreen(
        catalogLoader: () async => _testCatalog,
        sceneLoader: (scene) async => _testScenes[scene.id]!,
      ),
    );

class _Options implements OptionRepository {
  @override
  List<String> getOptions(String key, List<String> defaults) => defaults;

  @override
  List<int> getIntOptions(String key, List<int> defaults) => defaults;

  @override
  T? getValue<T>(String key) => null;

  @override
  Future<void> saveOptions(String key, List<dynamic> options) async {}

  @override
  Future<void> setValue(String key, dynamic value) async {}
}
