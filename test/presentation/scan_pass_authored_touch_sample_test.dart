import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/domain/scan_pass/authored_touch_sample.dart';
import 'package:football_note/domain/scan_pass/real_match_replay.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/scan_pass_game_screen.dart';
import 'package:football_note/presentation/theme/app_theme.dart';

late AuthoredTouchSample _sample;
late RealMatchReplayData _replay;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;

  setUpAll(() {
    _sample = AuthoredTouchSample.fromJsonString(
      File('assets/scan_pass_authored/first-touch-open-side.json')
          .readAsStringSync(),
    );
    _replay = RealMatchReplayData.fromJsonString(
      File('assets/scan_pass_replay/replay-data.json').readAsStringSync(),
    );
  });

  testWidgets('localized overflow entry opens the disclosed authored sample',
      (tester) async {
    await tester.pumpWidget(_app(
      locale: const Locale('ko'),
      home: ScanPassRealMatchReplayScreen(dataLoader: () async => _replay),
    ));
    await _pumpReplay(tester);

    await tester.tap(find.byKey(const ValueKey<String>('replay-more')));
    await tester.pumpAndSettle();
    expect(find.text('직접 제작 샘플'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('replay-authored-touch-sample')),
    );
    await _pumpAuthored(tester);

    expect(find.byType(ScanPassAuthoredTouchSampleScreen), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ScanPassAuthoredTouchSampleScreen),
        matching: find.text('직접 제작 샘플'),
      ),
      findsOneWidget,
    );
    expect(find.text('교육용으로 직접 만든 장면입니다.'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('authored-touch-context')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('authored-touch-detail')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('context and close-up stay synchronized through full playback',
      (tester) async {
    await tester.pumpWidget(_authoredApp());
    await _pumpAuthored(tester);
    final l10n = _l10n(tester);

    expect(_contextPainter(tester).time as double, 0);
    expect(_detailPainter(tester).time as double, 0);
    await _tap(tester, 'authored-touch-play');
    await tester.pump(const Duration(seconds: 1));
    final context = _contextPainter(tester);
    final detail = _detailPainter(tester);
    expect(context.time as double, closeTo(.7, .02));
    expect(detail.time as double, closeTo(context.time as double, 1e-9));
    expect(
      (detail.ballPoint as AuthoredTouchPoint)
          .distanceTo(context.ballPoint as AuthoredTouchPoint),
      lessThan(1e-12),
    );
    expect(
      (detail.receiverRoot as AuthoredTouchPoint)
          .distanceTo(context.receiverRoot as AuthoredTouchPoint),
      lessThan(1e-12),
    );
    expect(find.text(l10n.authoredTouchPause), findsOneWidget);

    await tester.pump(Duration(
      milliseconds:
          (_sample.duration / _sample.playbackRate * 1000).ceil() + 100,
    ));
    expect(_contextPainter(tester).time as double,
        closeTo(_sample.duration, .001));
    expect(
        _detailPainter(tester).time as double, closeTo(_sample.duration, .001));
    expect(find.text(l10n.authoredTouchOpenFeedback), findsOneWidget);
    expect(find.text(l10n.authoredTouchReplay), findsOneWidget);

    await _tap(tester, 'authored-touch-play');
    await tester.pump(const Duration(milliseconds: 150));
    expect(_contextPainter(tester).time as double, inExclusiveRange(0, .2));
    expect(find.text(l10n.authoredTouchPause), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('comparison during playback resets to the identical start',
      (tester) async {
    await tester.pumpWidget(_authoredApp());
    await _pumpAuthored(tester);
    final initial = _contextPainter(tester).ballPoint as AuthoredTouchPoint;

    await _tap(tester, 'authored-touch-play');
    await tester.pump(const Duration(seconds: 3));
    expect(_contextPainter(tester).time as double, greaterThan(2));
    await _tap(tester, 'authored-touch-compare');

    final context = _contextPainter(tester);
    final detail = _detailPainter(tester);
    expect(context.time as double, 0);
    expect(detail.time as double, 0);
    expect(context.continuation as AuthoredTouchContinuation,
        AuthoredTouchContinuation.pressureSide);
    expect(detail.continuation as AuthoredTouchContinuation,
        AuthoredTouchContinuation.pressureSide);
    expect(
      (context.ballPoint as AuthoredTouchPoint).distanceTo(initial),
      lessThan(1e-12),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(_contextPainter(tester).time as double, 0,
        reason: 'The old animation must be cancelled.');

    await _tap(tester, 'authored-touch-play');
    await tester.pump(const Duration(seconds: 7));
    expect(
      _contextPainter(tester).continuation as AuthoredTouchContinuation,
      AuthoredTouchContinuation.pressureSide,
    );
    expect(
      (_contextPainter(tester).ballPoint as AuthoredTouchPoint).y,
      greaterThan(4.5),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('close-up keeps the first touch and controlled ball in frame',
      (tester) async {
    await tester.pumpWidget(_authoredApp());
    await _pumpAuthored(tester);
    await _tap(tester, 'authored-touch-play');
    await tester.pump(const Duration(milliseconds: 4428));
    for (var index = 0; index < 25; index++) {
      final painter = _detailPainter(tester);
      final bounds = painter.cameraBounds(tester.getSize(
        find.byKey(const ValueKey<String>('authored-touch-detail')),
      )) as AuthoredTouchBounds;
      final time = painter.time as double;
      final frame = _sample.sampleAt(time, AuthoredTouchContinuation.openSide);
      expect(bounds.contains(frame.ball.point, margin: -.1), isTrue,
          reason:
              'The contact and its immediate roll must stay visible: $time');
      for (final foot in [
        frame.players['receiver']!.leftFoot,
        frame.players['receiver']!.rightFoot
      ]) {
        expect(bounds.contains(foot, margin: -.1), isTrue);
      }
      await tester.pump(const Duration(milliseconds: 140));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('lifecycle pause and route disposal cancel playback safely',
      (tester) async {
    await tester.pumpWidget(_authoredApp());
    await _pumpAuthored(tester);
    await _tap(tester, 'authored-touch-play');
    await tester.pump(const Duration(milliseconds: 600));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    final pausedAt = _contextPainter(tester).time as double;
    await tester.pump(const Duration(seconds: 1));
    expect(_contextPainter(tester).time as double, closeTo(pausedAt, .001));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    await _tap(tester, 'authored-touch-play');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('closing sample preserves the paused real-replay position',
      (tester) async {
    await tester.pumpWidget(_app(
      home: ScanPassRealMatchReplayScreen(
        dataLoader: () async => _replay,
        authoredSampleLoader: () async => _sample,
      ),
    ));
    await _pumpReplay(tester);
    await _tap(tester, 'replay-play');
    await tester.pump(const Duration(milliseconds: 260));
    await tester.tap(find.byKey(const ValueKey<String>('replay-more')));
    await tester.pumpAndSettle();
    final openedAt = _replayTime(tester);
    expect(openedAt, greaterThan(0));
    await tester.tap(
      find.byKey(const ValueKey<String>('replay-authored-touch-sample')),
    );
    await _pumpAuthored(tester);
    await _tap(tester, 'authored-touch-play');
    await tester.pump(const Duration(milliseconds: 300));
    await _tap(tester, 'authored-touch-close');
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('replay-pitch')), findsOneWidget);
    expect(_replayTime(tester), closeTo(openedAt, .001));
    await tester.pump(const Duration(seconds: 1));
    expect(_replayTime(tester), closeTo(openedAt, .001));
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
          '${locale.languageCode} authored sample fits ${viewport.width}x${viewport.height} at 1.4x text',
          (tester) async {
        final semantics = tester.ensureSemantics();
        tester.view.physicalSize = viewport;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(_authoredApp(
          locale: locale,
          textScale: 1.4,
          appTheme: true,
        ));
        await _pumpAuthored(tester);

        final context =
            find.byKey(const ValueKey<String>('authored-touch-context'));
        final detail =
            find.byKey(const ValueKey<String>('authored-touch-detail'));
        final play = find.byKey(const ValueKey<String>('authored-touch-play'));
        final compare =
            find.byKey(const ValueKey<String>('authored-touch-compare'));
        expect(_contextPainter(tester).visiblePlayerCount as int, 5);
        expect(_detailPainter(tester).visiblePlayerCount as int, 2);
        final camera = _detailPainter(tester).cameraBounds(
          tester.getSize(detail),
        ) as AuthoredTouchBounds;
        expect(camera.height, inInclusiveRange(6.4, 9.2));
        expect(
          _detailPainter(tester).scaledCueFontSize as double,
          greaterThanOrEqualTo(15.39),
        );
        expect(tester.getSize(context).width, greaterThan(100));
        expect(tester.getSize(context).height, greaterThan(70));
        expect(tester.getSize(detail).width, greaterThan(100));
        expect(tester.getSize(detail).height, greaterThan(70));
        expect(
            tester.getRect(context).overlaps(tester.getRect(detail)), isFalse);
        expect(tester.getRect(context).overlaps(tester.getRect(play)), isFalse);
        expect(
            tester.getRect(detail).overlaps(tester.getRect(compare)), isFalse);
        expect(play.hitTestable(), findsOneWidget);
        expect(compare.hitTestable(), findsOneWidget);
        expect(
          tester.getSemantics(context).label,
          contains(_l10n(tester).authoredTouchOpenSide),
        );
        expect(
          tester.getSemantics(detail).label,
          contains(_l10n(tester).authoredTouchPhasePrepare),
        );
        expect(find.byKey(const ValueKey<String>('authored-touch-close')),
            findsOneWidget);
        expect(tester.takeException(), isNull);
        semantics.dispose();
      });
    }
  }
}

dynamic _contextPainter(WidgetTester tester) => tester
    .widget<CustomPaint>(
      find.byKey(const ValueKey<String>('authored-touch-context')),
    )
    .painter;

dynamic _detailPainter(WidgetTester tester) => tester
    .widget<CustomPaint>(
      find.byKey(const ValueKey<String>('authored-touch-detail')),
    )
    .painter;

double _replayTime(WidgetTester tester) {
  final dynamic painter = tester
      .widget<CustomPaint>(
        find.byKey(const ValueKey<String>('replay-pitch')),
      )
      .painter;
  return painter.time as double;
}

AppLocalizations _l10n(WidgetTester tester) => AppLocalizations.of(
      tester.element(find.byType(ScanPassAuthoredTouchSampleScreen)),
    )!;

Future<void> _tap(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey<String>(key));
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
}

Future<void> _pumpReplay(WidgetTester tester) async {
  await tester.pump();
  for (var attempt = 0; attempt < 30; attempt++) {
    if (find
        .byKey(const ValueKey<String>('replay-pitch'))
        .evaluate()
        .isNotEmpty) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 20));
  }
  fail('Replay did not load.');
}

Future<void> _pumpAuthored(WidgetTester tester) async {
  await tester.pump();
  for (var attempt = 0; attempt < 30; attempt++) {
    if (find
        .byKey(const ValueKey<String>('authored-touch-context'))
        .evaluate()
        .isNotEmpty) {
      return;
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
  fail('Authored sample did not load.');
}

Widget _authoredApp({
  Locale locale = const Locale('en'),
  double textScale = 1,
  bool appTheme = false,
}) =>
    _app(
      locale: locale,
      textScale: textScale,
      appTheme: appTheme,
      home: ScanPassAuthoredTouchSampleScreen(
        dataLoader: () async => _sample,
      ),
    );

Widget _app({
  required Widget home,
  Locale locale = const Locale('en'),
  double textScale = 1,
  bool appTheme = false,
}) =>
    MaterialApp(
      theme: appTheme ? AppTheme.light() : null,
      darkTheme: appTheme ? AppTheme.dark() : null,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: home,
    );
