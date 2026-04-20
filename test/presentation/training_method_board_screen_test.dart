import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/models/training_method_layout.dart';
import 'package:football_note/presentation/screens/training_method_board_screen.dart';

void main() {
  test('legacy training sketch paths decode into routes', () {
    final layout = TrainingMethodLayout.decode(
      '{"version":1,"pages":[{"name":"Board","methodText":"","items":[],"strokes":[],"playerPath":[{"x":0.2,"y":0.4},{"x":0.5,"y":0.6}],"ballPath":[{"x":0.25,"y":0.45},{"x":0.62,"y":0.58}]}]}',
    );

    final routes = layout.pages.single.routes;
    expect(routes, hasLength(2));
    expect(routes[0].kind, TrainingMethodRouteKind.player);
    expect(routes[0].points, hasLength(2));
    expect(routes[1].kind, TrainingMethodRouteKind.ball);
    expect(routes[1].points, hasLength(2));
  });

  testWidgets('player routes are capped by available players', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);
    String? savedLayout;
    final initialLayout = const TrainingMethodLayout(
      pages: <TrainingMethodPage>[
        TrainingMethodPage(
          name: 'Board',
          items: <TrainingMethodItem>[
            TrainingMethodItem(id: 'player-1', type: 'player', x: 0.18, y: 0.3),
            TrainingMethodItem(
              id: 'player-2',
              type: 'player',
              x: 0.74,
              y: 0.66,
            ),
            TrainingMethodItem(id: 'cone-1', type: 'cone', x: 0.5, y: 0.48),
          ],
        ),
      ],
    ).encode();

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '패스 워밍업',
          initialLayoutJson: initialLayout,
          onSaved: (value) => savedLayout = value,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('training-player-path-mode-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('training-landscape-panel-toggle')),
    );
    await tester.pumpAndSettle();

    final boardFinder = find.byKey(const ValueKey('training-board-canvas'));
    final playerFinder = find.descendant(
      of: boardFinder,
      matching: find.byIcon(Icons.person),
    );
    final coneFinder = find.descendant(
      of: boardFinder,
      matching: find.byIcon(Icons.change_history),
    );

    await tester.tap(playerFinder.first);
    await tester.pumpAndSettle();

    await _drawRoute(
      tester,
      boardFinder,
      const Offset(180, 220),
      const Offset(320, 180),
    );

    await tester.tap(playerFinder.at(1));
    await tester.pumpAndSettle();

    await _drawRoute(
      tester,
      boardFinder,
      const Offset(730, 470),
      const Offset(840, 360),
    );

    await tester.tap(coneFinder);
    await tester.pumpAndSettle();

    await _drawRoute(
      tester,
      boardFinder,
      const Offset(520, 320),
      const Offset(680, 260),
    );

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final routes = saved.pages.single.routes;
    expect(
      routes.where((route) => route.kind == TrainingMethodRouteKind.player),
      hasLength(2),
    );
    expect(routes.map((route) => route.linkedItemId).toSet(), {
      'player-1',
      'player-2',
    });
  });

  testWidgets('selected route can be deleted without clearing others', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);
    String? savedLayout;
    final initialLayout = const TrainingMethodLayout(
      pages: <TrainingMethodPage>[
        TrainingMethodPage(
          name: 'Board',
          items: <TrainingMethodItem>[
            TrainingMethodItem(id: 'player-1', type: 'player', x: 0.2, y: 0.5),
            TrainingMethodItem(
              id: 'player-2',
              type: 'player',
              x: 0.72,
              y: 0.55,
            ),
          ],
          routes: <TrainingMethodRoute>[
            TrainingMethodRoute(
              id: 'route-1',
              kind: TrainingMethodRouteKind.player,
              linkedItemId: 'player-1',
              points: <TrainingMethodPoint>[
                TrainingMethodPoint(x: 0.2, y: 0.5),
                TrainingMethodPoint(x: 0.45, y: 0.35),
              ],
            ),
            TrainingMethodRoute(
              id: 'route-2',
              kind: TrainingMethodRouteKind.player,
              linkedItemId: 'player-2',
              points: <TrainingMethodPoint>[
                TrainingMethodPoint(x: 0.72, y: 0.55),
                TrainingMethodPoint(x: 0.58, y: 0.72),
              ],
            ),
          ],
        ),
      ],
    ).encode();

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '패스 워밍업',
          initialLayoutJson: initialLayout,
          onSaved: (value) => savedLayout = value,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('training-player-path-mode-button')),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('사람 2'));
    await tester.tap(find.text('사람 2'));
    await tester.pumpAndSettle();

    final deleteRouteButton = find.widgetWithText(OutlinedButton, '선택 이동선 삭제');
    await tester.ensureVisible(deleteRouteButton);
    await tester.tap(deleteRouteButton);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final routes = saved.pages.single.routes;
    expect(
      routes.where((route) => route.kind == TrainingMethodRouteKind.player),
      hasLength(1),
    );
  });

  testWidgets('dragging a linked item moves only its linked route', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);
    String? savedLayout;
    final initialLayout = const TrainingMethodLayout(
      pages: <TrainingMethodPage>[
        TrainingMethodPage(
          name: 'Board',
          items: <TrainingMethodItem>[
            TrainingMethodItem(id: 'player-1', type: 'player', x: 0.2, y: 0.5),
            TrainingMethodItem(
              id: 'player-2',
              type: 'player',
              x: 0.72,
              y: 0.64,
            ),
          ],
          routes: <TrainingMethodRoute>[
            TrainingMethodRoute(
              id: 'route-1',
              kind: TrainingMethodRouteKind.player,
              linkedItemId: 'player-1',
              points: <TrainingMethodPoint>[
                TrainingMethodPoint(x: 0.2, y: 0.5),
                TrainingMethodPoint(x: 0.45, y: 0.35),
              ],
            ),
            TrainingMethodRoute(
              id: 'route-2',
              kind: TrainingMethodRouteKind.player,
              linkedItemId: 'player-2',
              points: <TrainingMethodPoint>[
                TrainingMethodPoint(x: 0.72, y: 0.64),
                TrainingMethodPoint(x: 0.86, y: 0.52),
              ],
            ),
          ],
        ),
      ],
    ).encode();

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '패스 워밍업',
          initialLayoutJson: initialLayout,
          onSaved: (value) => savedLayout = value,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final boardFinder = find.byKey(const ValueKey('training-board-canvas'));
    final playerFinder = find.descendant(
      of: boardFinder,
      matching: find.byIcon(Icons.person),
    );

    await tester.drag(playerFinder.first, const Offset(42, -26));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final page = saved.pages.single;
    final player = page.items.firstWhere((item) => item.id == 'player-1');
    final dx = player.x - 0.2;
    final dy = player.y - 0.5;

    expect(dx.abs(), greaterThan(0.001));
    expect(dy.abs(), greaterThan(0.001));

    final movedRoute1 = page.routes.firstWhere(
      (route) => route.id == 'route-1',
    );
    expect(movedRoute1.points[0].x, closeTo(0.2 + dx, 0.0001));
    expect(movedRoute1.points[0].y, closeTo(0.5 + dy, 0.0001));
    expect(movedRoute1.points[1].x, closeTo(0.45 + dx, 0.0001));
    expect(movedRoute1.points[1].y, closeTo(0.35 + dy, 0.0001));

    final movedRoute2 = page.routes.firstWhere(
      (route) => route.id == 'route-2',
    );
    expect(movedRoute2.points[0].x, closeTo(0.72, 0.0001));
    expect(movedRoute2.points[0].y, closeTo(0.64, 0.0001));
    expect(movedRoute2.points[1].x, closeTo(0.86, 0.0001));
    expect(movedRoute2.points[1].y, closeTo(0.52, 0.0001));
  });

  testWidgets(
    'new route links to the nearest matching item when none is selected',
    (WidgetTester tester) async {
      _setLandscapeSurface(tester);
      String? savedLayout;
      final initialLayout = const TrainingMethodLayout(
        pages: <TrainingMethodPage>[
          TrainingMethodPage(
            name: 'Board',
            items: <TrainingMethodItem>[
              TrainingMethodItem(
                id: 'player-1',
                type: 'player',
                x: 0.18,
                y: 0.28,
              ),
              TrainingMethodItem(
                id: 'player-2',
                type: 'player',
                x: 0.72,
                y: 0.66,
                colorValue: 0xFFE53935,
              ),
            ],
          ),
        ],
      ).encode();

      await tester.pumpWidget(
        _buildApp(
          TrainingMethodBoardScreen(
            boardTitle: '패스 워밍업',
            initialLayoutJson: initialLayout,
            onSaved: (value) => savedLayout = value,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('training-player-path-mode-button')),
      );
      await tester.pumpAndSettle();

      final boardFinder = find.byKey(const ValueKey('training-board-canvas'));
      await _drawRoute(
        tester,
        boardFinder,
        const Offset(700, 440),
        const Offset(860, 360),
      );

      await tester.tap(find.widgetWithText(TextButton, '저장'));
      await tester.pumpAndSettle();

      final saved = TrainingMethodLayout.decode(savedLayout ?? '');
      final route = saved.pages.single.routes.single;
      expect(route.linkedItemId, 'player-2');
      expect(route.colorValue, 0xFFE53935);
    },
  );

  testWidgets(
    'player and ball route buttons stay separate and ball routes keep ball color',
    (WidgetTester tester) async {
      _setLandscapeSurface(tester);
      String? savedLayout;

      await tester.pumpWidget(
        _buildApp(
          TrainingMethodBoardScreen(
            boardTitle: '패스 워밍업',
            initialLayoutJson: '',
            onSaved: (value) => savedLayout = value,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, '사람'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, '공'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('training-player-path-mode-button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('training-ball-path-mode-button')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('training-ball-path-mode-button')),
      );
      await tester.pumpAndSettle();

      final boardFinder = find.byKey(const ValueKey('training-board-canvas'));
      await _drawRoute(
        tester,
        boardFinder,
        const Offset(520, 320),
        const Offset(760, 260),
      );

      await tester.tap(find.widgetWithText(TextButton, '저장'));
      await tester.pumpAndSettle();

      final saved = TrainingMethodLayout.decode(savedLayout ?? '');
      final page = saved.pages.single;
      final player = page.items.firstWhere((item) => item.type == 'player');
      final ball = page.items.firstWhere((item) => item.type == 'ball');
      final ballRoute = page.routes.single;

      expect(player.colorValue, isNot(ball.colorValue));
      expect(ballRoute.kind, TrainingMethodRouteKind.ball);
      expect(ballRoute.linkedItemId, ball.id);
      expect(ballRoute.colorValue, ball.colorValue);
    },
  );

  testWidgets('landscape controls and memo stay beside the board', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);

    await tester.pumpWidget(
      _buildApp(
        const TrainingMethodBoardScreen(
          boardTitle: '패스 워밍업',
          initialLayoutJson: '',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('training-landscape-control-panel')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('training-landscape-memo-panel')),
      findsNothing,
    );
    expect(find.byType(TextField), findsNothing);
    final boardRect = tester.getRect(
      find.byKey(const ValueKey('training-board-canvas')),
    );
    final controlRect = tester.getRect(
      find.byKey(const ValueKey('training-landscape-control-panel')),
    );
    expect(controlRect.left, greaterThan(boardRect.right));

    await tester.tap(
      find.byKey(const ValueKey('training-landscape-panel-toggle')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('training-landscape-control-panel')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('training-board-canvas')), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('training-landscape-memo-toggle')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('training-landscape-control-panel')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('training-landscape-memo-panel')),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsOneWidget);
    final memoRect = tester.getRect(
      find.byKey(const ValueKey('training-landscape-memo-panel')),
    );
    final boardRectWithMemo = tester.getRect(
      find.byKey(const ValueKey('training-board-canvas')),
    );
    expect(memoRect.left, greaterThan(boardRectWithMemo.right));
  });

  testWidgets('portrait inspector starts open and both panels are foldable', (
    WidgetTester tester,
  ) async {
    _setPortraitSurface(tester);

    await tester.pumpWidget(
      _buildApp(
        const TrainingMethodBoardScreen(
          boardTitle: '패스 워밍업',
          initialLayoutJson: '',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('training-portrait-memo-panel')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('training-portrait-inspector-panel')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('training-portrait-inspector-toggle')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('training-portrait-inspector-panel')),
      findsNothing,
    );

    await tester.tap(
      find.byKey(const ValueKey('training-portrait-memo-toggle')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('training-portrait-memo-panel')),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('training-portrait-inspector-toggle')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('training-portrait-inspector-panel')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('training-portrait-tool-strip')),
      findsOneWidget,
    );
  });

  testWidgets('player can be selected in routes mode to replace its route', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);
    String? savedLayout;
    final initialLayout = const TrainingMethodLayout(
      pages: <TrainingMethodPage>[
        TrainingMethodPage(
          name: 'Board',
          items: <TrainingMethodItem>[
            TrainingMethodItem(id: 'player-1', type: 'player', x: 0.2, y: 0.5),
          ],
        ),
      ],
    ).encode();

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '패스 워밍업',
          initialLayoutJson: initialLayout,
          onSaved: (value) => savedLayout = value,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('training-player-path-mode-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('training-landscape-panel-toggle')),
    );
    await tester.pumpAndSettle();

    final boardFinder = find.byKey(const ValueKey('training-board-canvas'));
    final playerFinder = find.descendant(
      of: boardFinder,
      matching: find.byIcon(Icons.person),
    );

    await tester.tap(playerFinder);
    await tester.pumpAndSettle();

    await _drawRoute(
      tester,
      boardFinder,
      const Offset(220, 340),
      const Offset(430, 210),
    );
    await _drawRoute(
      tester,
      boardFinder,
      const Offset(240, 300),
      const Offset(520, 250),
    );

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final route = saved.pages.single.routes.single;
    expect(route.linkedItemId, 'player-1');
    expect(route.points.first.x, closeTo(0.24, 0.02));
    expect(route.points.first.y, closeTo(0.47, 0.03));
    expect(route.points.last.x, closeTo(0.52, 0.02));
    expect(route.points.last.y, closeTo(0.39, 0.03));
  });

  testWidgets(
    'new linked routes inherit item color and play animates all items',
    (WidgetTester tester) async {
      _setLandscapeSurface(tester);
      String? savedLayout;
      final initialLayout = const TrainingMethodLayout(
        pages: <TrainingMethodPage>[
          TrainingMethodPage(
            name: 'Board',
            items: <TrainingMethodItem>[
              TrainingMethodItem(
                id: 'player-1',
                type: 'player',
                x: 0.2,
                y: 0.3,
              ),
              TrainingMethodItem(
                id: 'player-2',
                type: 'player',
                x: 0.22,
                y: 0.72,
                colorValue: 0xFFFFCA28,
              ),
              TrainingMethodItem(
                id: 'ball-1',
                type: 'ball',
                x: 0.32,
                y: 0.52,
                colorValue: 0xFFE53935,
              ),
            ],
            routes: <TrainingMethodRoute>[
              TrainingMethodRoute(
                id: 'route-player-1',
                kind: TrainingMethodRouteKind.player,
                linkedItemId: 'player-1',
                points: <TrainingMethodPoint>[
                  TrainingMethodPoint(x: 0.2, y: 0.3),
                  TrainingMethodPoint(x: 0.58, y: 0.28),
                ],
              ),
              TrainingMethodRoute(
                id: 'route-player-2',
                kind: TrainingMethodRouteKind.player,
                linkedItemId: 'player-2',
                points: <TrainingMethodPoint>[
                  TrainingMethodPoint(x: 0.22, y: 0.72),
                  TrainingMethodPoint(x: 0.66, y: 0.74),
                ],
              ),
              TrainingMethodRoute(
                id: 'route-ball-1',
                kind: TrainingMethodRouteKind.ball,
                linkedItemId: 'ball-1',
                points: <TrainingMethodPoint>[
                  TrainingMethodPoint(x: 0.32, y: 0.52),
                  TrainingMethodPoint(x: 0.72, y: 0.44),
                ],
              ),
            ],
          ),
        ],
      ).encode();

      await tester.pumpWidget(
        _buildApp(
          TrainingMethodBoardScreen(
            boardTitle: '패스 워밍업',
            initialLayoutJson: initialLayout,
            onSaved: (value) => savedLayout = value,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, '사람'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('training-player-path-mode-button')),
      );
      await tester.pumpAndSettle();

      final boardFinder = find.byKey(const ValueKey('training-board-canvas'));
      await _drawRoute(
        tester,
        boardFinder,
        const Offset(150, 120),
        const Offset(290, 160),
      );

      await tester.tap(find.widgetWithText(TextButton, '저장'));
      await tester.pumpAndSettle();

      final saved = TrainingMethodLayout.decode(savedLayout ?? '');
      final page = saved.pages.single;
      final newestPlayer = page.items.last;
      final newestRoute = page.routes.last;
      expect(newestPlayer.type, 'player');
      expect(newestRoute.linkedItemId, newestPlayer.id);
      expect(newestRoute.colorValue, newestPlayer.colorValue);

      final playerIcons = find.descendant(
        of: boardFinder,
        matching: find.byIcon(Icons.person),
      );
      final ballIcons = find.descendant(
        of: boardFinder,
        matching: find.byIcon(Icons.sports_soccer),
      );
      expect(playerIcons, findsNWidgets(3));
      expect(ballIcons, findsOneWidget);

      final player1Before = tester.getCenter(playerIcons.at(0));
      final player2Before = tester.getCenter(playerIcons.at(1));
      final ballBefore = tester.getCenter(ballIcons);

      await tester.tap(find.byIcon(Icons.play_circle_outline).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      final player1After = tester.getCenter(playerIcons.at(0));
      final player2After = tester.getCenter(playerIcons.at(1));
      final ballAfter = tester.getCenter(ballIcons);

      expect((player1After - player1Before).distance, greaterThan(1));
      expect((player2After - player2Before).distance, greaterThan(1));
      expect((ballAfter - ballBefore).distance, greaterThan(1));
    },
  );
}

Widget _buildApp(Widget home) {
  return MaterialApp(
    locale: const Locale('ko', 'KR'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );
}

Future<void> _drawRoute(
  WidgetTester tester,
  Finder boardFinder,
  Offset start,
  Offset end,
) async {
  final detector = tester.widget<GestureDetector>(boardFinder);
  final mid = Offset.lerp(start, end, 0.5)!;
  detector.onPanStart!(DragStartDetails(localPosition: start));
  await tester.pump();
  detector.onPanUpdate!(
    DragUpdateDetails(
      localPosition: mid,
      globalPosition: mid,
      delta: mid - start,
    ),
  );
  await tester.pump(const Duration(milliseconds: 16));
  detector.onPanUpdate!(
    DragUpdateDetails(
      localPosition: end,
      globalPosition: end,
      delta: end - mid,
    ),
  );
  await tester.pump(const Duration(milliseconds: 16));
  detector.onPanEnd!(DragEndDetails());
  await tester.pumpAndSettle();
}

void _setLandscapeSurface(
  WidgetTester tester, {
  Size size = const Size(1000, 720),
}) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void _setPortraitSurface(
  WidgetTester tester, {
  Size size = const Size(430, 900),
}) {
  _setLandscapeSurface(tester, size: size);
}
