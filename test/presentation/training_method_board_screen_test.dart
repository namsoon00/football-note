import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/player_level_service.dart';
import 'package:football_note/application/training_board_service.dart';
import 'package:football_note/domain/entities/sport_definition.dart';
import 'package:football_note/domain/repositories/option_repository.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/gen/app_localizations_ko.dart';
import 'package:football_note/presentation/models/training_board_templates.dart';
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

  test('training sketch routes preserve draw timing segments', () {
    final encoded = const TrainingMethodLayout(
      pages: <TrainingMethodPage>[
        TrainingMethodPage(
          name: 'Timed route',
          items: <TrainingMethodItem>[],
          routes: <TrainingMethodRoute>[
            TrainingMethodRoute(
              id: 'timed-player',
              kind: TrainingMethodRouteKind.player,
              points: <TrainingMethodPoint>[
                TrainingMethodPoint(x: 0.2, y: 0.2),
                TrainingMethodPoint(x: 0.4, y: 0.3),
                TrainingMethodPoint(x: 0.8, y: 0.7),
              ],
              segmentDurationsMs: <int>[80, 460],
            ),
          ],
        ),
      ],
    ).encode();

    final decoded = TrainingMethodLayout.decode(encoded);

    expect(decoded.pages.single.routes.single.segmentDurationsMs, [80, 460]);
  });

  test('training sketch routes preserve movement stages', () {
    final encoded = const TrainingMethodLayout(
      pages: <TrainingMethodPage>[
        TrainingMethodPage(
          name: 'Staged route',
          items: <TrainingMethodItem>[],
          routes: <TrainingMethodRoute>[
            TrainingMethodRoute(
              id: 'staged-player',
              kind: TrainingMethodRouteKind.player,
              stageIndex: 3,
              points: <TrainingMethodPoint>[
                TrainingMethodPoint(x: 0.2, y: 0.2),
                TrainingMethodPoint(x: 0.4, y: 0.3),
              ],
            ),
          ],
        ),
      ],
    ).encode();

    final decoded = TrainingMethodLayout.decode(encoded);

    expect(decoded.pages.single.routes.single.stageIndex, 3);
  });

  testWidgets('routes can be split into editable movement stages', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);
    String? savedLayout;
    final initialLayout = const TrainingMethodLayout(
      pages: <TrainingMethodPage>[
        TrainingMethodPage(
          name: 'Board',
          items: <TrainingMethodItem>[
            TrainingMethodItem(
                id: 'player-1', type: 'player', x: 0.26, y: 0.61),
            TrainingMethodItem(
              id: 'player-2',
              type: 'player',
              x: 0.52,
              y: 0.48,
              colorValue: 0xFF1E88E5,
            ),
            TrainingMethodItem(
              id: 'player-3',
              type: 'player',
              x: 0.73,
              y: 0.64,
              colorValue: 0xFF26C6DA,
            ),
            TrainingMethodItem(
              id: 'ball-1',
              type: 'ball',
              x: 0.31,
              y: 0.60,
              colorValue: 0xFFFFCA28,
            ),
          ],
          routes: <TrainingMethodRoute>[
            TrainingMethodRoute(
              id: 'route-player-1',
              kind: TrainingMethodRouteKind.player,
              linkedItemId: 'player-1',
              points: <TrainingMethodPoint>[
                TrainingMethodPoint(x: 0.26, y: 0.61),
                TrainingMethodPoint(x: 0.34, y: 0.56),
              ],
            ),
            TrainingMethodRoute(
              id: 'route-ball-1',
              kind: TrainingMethodRouteKind.ball,
              linkedItemId: 'ball-1',
              points: <TrainingMethodPoint>[
                TrainingMethodPoint(x: 0.31, y: 0.60),
                TrainingMethodPoint(x: 0.52, y: 0.48),
                TrainingMethodPoint(x: 0.69, y: 0.45),
              ],
            ),
            TrainingMethodRoute(
              id: 'route-player-2',
              kind: TrainingMethodRouteKind.player,
              linkedItemId: 'player-2',
              points: <TrainingMethodPoint>[
                TrainingMethodPoint(x: 0.52, y: 0.48),
                TrainingMethodPoint(x: 0.69, y: 0.45),
              ],
            ),
            TrainingMethodRoute(
              id: 'route-player-3',
              kind: TrainingMethodRouteKind.player,
              linkedItemId: 'player-3',
              points: <TrainingMethodPoint>[
                TrainingMethodPoint(x: 0.73, y: 0.64),
                TrainingMethodPoint(x: 0.79, y: 0.36),
              ],
            ),
          ],
        ),
      ],
    ).encode();

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '연계 스케치',
          initialLayoutJson: initialLayout,
          onSaved: (value) => savedLayout = value,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final boardFinder = find.byKey(const ValueKey('training-board-canvas'));
    await _openMoveRouteToolForIcon(
      tester,
      find
          .descendant(of: boardFinder, matching: find.byIcon(Icons.person))
          .first,
    );
    await _tapVisibleOutlinedButton(tester, '단계 자동 나누기');
    await _tapVisibleOutlinedButton(tester, '다음 단계');

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final routes = saved.pages.single.routes;
    expect(routes, hasLength(4));
    expect(_samePoint(routes[0].points[0], routes[0].points[1]), isFalse);
    expect(_samePoint(routes[2].points[0], routes[2].points[1]), isFalse);
    expect(_samePoint(routes[3].points[0], routes[3].points[1]), isFalse);
    expect(routes.map((route) => route.stageIndex), [2, 2, 3, 4]);
  });

  testWidgets('ball tokens show their own numbers', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '번호 스케치',
          initialLayoutJson: const TrainingMethodLayout(
            pages: <TrainingMethodPage>[
              TrainingMethodPage(
                name: 'Board',
                items: <TrainingMethodItem>[
                  TrainingMethodItem(
                    id: 'player-1',
                    type: 'player',
                    x: 0.2,
                    y: 0.4,
                  ),
                  TrainingMethodItem(
                    id: 'ball-1',
                    type: 'ball',
                    x: 0.36,
                    y: 0.4,
                  ),
                  TrainingMethodItem(
                    id: 'ball-2',
                    type: 'ball',
                    x: 0.52,
                    y: 0.4,
                  ),
                ],
              ),
            ],
          ).encode(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final boardFinder = find.byKey(const ValueKey('training-board-canvas'));
    expect(
      find.descendant(of: boardFinder, matching: find.text('1')),
      findsNWidgets(2),
    );
    expect(
      find.descendant(of: boardFinder, matching: find.text('2')),
      findsOneWidget,
    );
  });

  testWidgets('sport-specific board surfaces are used for sketch boards', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);

    Future<void> pumpSport(String sportId, String surfaceName) async {
      await tester.pumpWidget(
        _buildApp(
          TrainingMethodBoardScreen(
            boardTitle: '종목 보드',
            initialLayoutJson: '',
            sportId: sportId,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(ValueKey('training-board-surface-$surfaceName')),
        findsOneWidget,
      );
    }

    await pumpSport(SportCatalog.tennisId, 'tennis');
    await pumpSport(SportCatalog.baseballId, 'baseball');
    await pumpSport(SportCatalog.basketballId, 'basketball');
  });

  testWidgets('sport-specific sketch tools show only useful elements', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);

    Future<void> pumpSport(String sportId) async {
      await tester.pumpWidget(
        _buildApp(
          TrainingMethodBoardScreen(
            boardTitle: '종목 도구',
            initialLayoutJson: '',
            sportId: sportId,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await pumpSport(SportCatalog.tennisId);
    expect(find.widgetWithText(OutlinedButton, '목표'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '사람'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '공'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '사다리'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, '낮은 뜀틀'), findsNothing);

    await pumpSport(SportCatalog.baseballId);
    expect(find.widgetWithText(OutlinedButton, '베이스'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '목표'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '골대'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, '사다리'), findsNothing);

    await pumpSport(SportCatalog.basketballId);
    expect(find.widgetWithText(OutlinedButton, '골대'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '목표'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '베이스'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, '낮은 뜀틀'), findsNothing);
  });

  test('football templates include coach-ready action layouts', () {
    final templates = buildTrainingBoardTemplateOptions(
      AppLocalizationsKo(),
      sportId: SportCatalog.footballId,
    );

    expect(templates.map((template) => template.id), contains('switch_play'));
    expect(
      templates.map((template) => template.id),
      contains('defensive_shift'),
    );
    expect(templates, hasLength(11));

    for (final template in templates.where((entry) => entry.id != 'blank')) {
      final page = template.buildLayout(template.label).pages.single;
      expect(page.items.where((item) => item.type == 'player').length,
          greaterThanOrEqualTo(3));
      expect(
        page.routes.any((route) => route.kind == TrainingMethodRouteKind.ball),
        isTrue,
      );
      expect(
        page.routes
            .any((route) => route.kind == TrainingMethodRouteKind.player),
        isTrue,
      );
      expect(
        page.routes.every((route) => route.linkedItemId?.isNotEmpty == true),
        isTrue,
      );
    }
  });

  testWidgets('new player creates a movement route by action and target tap', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);
    String? savedLayout;

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '즉시 이동선',
          initialLayoutJson: '',
          onSaved: (value) => savedLayout = value,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, '사람'));
    await tester.pumpAndSettle();

    final boardFinder = find.byKey(const ValueKey('training-board-canvas'));
    await _tapVisibleOutlinedButton(tester, '이동');
    expect(find.text('이동 대상이나 공간을 누르세요.'), findsOneWidget);
    await _tapBoardRelative(tester, boardFinder, const Offset(0.72, 0.38));
    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final item = saved.pages.single.items.single;
    final route = saved.pages.single.routes.single;
    expect(item.type, 'player');
    expect(route.kind, TrainingMethodRouteKind.player);
    expect(route.linkedItemId, item.id);
    expect(route.points.first.x, closeTo(item.x, 0.001));
    expect(route.points.first.y, closeTo(item.y, 0.001));
    expect(route.points.last.x, closeTo(0.72, 0.02));
    expect(route.points.last.y, closeTo(0.38, 0.02));
  });

  testWidgets('new ball creates a ball route by action and target tap', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);
    String? savedLayout;

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '즉시 공 이동선',
          initialLayoutJson: '',
          onSaved: (value) => savedLayout = value,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, '공'));
    await tester.pumpAndSettle();

    final boardFinder = find.byKey(const ValueKey('training-board-canvas'));
    await _tapVisibleOutlinedButton(tester, '패스');
    expect(find.text('패스 대상이나 공간을 누르세요.'), findsOneWidget);
    await _tapBoardRelative(tester, boardFinder, const Offset(0.70, 0.42));
    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final page = saved.pages.single;
    final item = page.items.singleWhere((entry) => entry.type == 'ball');
    final player = page.items.singleWhere((entry) => entry.type == 'player');
    final route = saved.pages.single.routes.single;
    expect((player.x - item.x).abs(), lessThan(0.08));
    expect((player.y - item.y).abs(), lessThan(0.06));
    expect(_isItemAheadOf(item, player, const Offset(0.70, 0.42)), isTrue);
    expect(item.type, 'ball');
    expect(route.kind, TrainingMethodRouteKind.ball);
    expect(route.linkedItemId, item.id);
    expect(route.points.first.x, closeTo(item.x, 0.001));
    expect(route.points.first.y, closeTo(item.y, 0.001));
    expect(route.points.last.x, closeTo(0.70, 0.02));
    expect(route.points.last.y, closeTo(0.42, 0.02));
  });

  testWidgets('player pass action creates a controlled ball when needed', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);
    String? savedLayout;

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '선수 패스',
          initialLayoutJson: const TrainingMethodLayout(
            pages: <TrainingMethodPage>[
              TrainingMethodPage(
                name: 'Board',
                items: <TrainingMethodItem>[
                  TrainingMethodItem(
                    id: 'player-1',
                    type: 'player',
                    x: 0.24,
                    y: 0.50,
                  ),
                ],
              ),
            ],
          ).encode(),
          onSaved: (value) => savedLayout = value,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final boardFinder = find.byKey(const ValueKey('training-board-canvas'));
    await tester.tap(
      find.descendant(of: boardFinder, matching: find.byIcon(Icons.person)),
    );
    await tester.pumpAndSettle();
    expect(find.text('선수 액션'), findsOneWidget);
    await _tapVisibleOutlinedButton(tester, '패스');
    await _tapBoardRelative(tester, boardFinder, const Offset(0.70, 0.44));

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final page = saved.pages.single;
    final player = page.items.singleWhere((item) => item.type == 'player');
    final ball = page.items.singleWhere((item) => item.type == 'ball');
    final route = page.routes.single;

    expect((ball.x - player.x).abs(), lessThan(0.08));
    expect((ball.y - player.y).abs(), lessThan(0.05));
    expect(_isItemAheadOf(ball, player, const Offset(0.70, 0.44)), isTrue);
    expect(route.kind, TrainingMethodRouteKind.ball);
    expect(route.linkedItemId, ball.id);
    expect(route.points.last.x, closeTo(0.70, 0.02));
    expect(route.points.last.y, closeTo(0.44, 0.02));
  });

  testWidgets('player dribble action creates linked player and ball routes', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);
    String? savedLayout;

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '선수 드리블',
          initialLayoutJson: const TrainingMethodLayout(
            pages: <TrainingMethodPage>[
              TrainingMethodPage(
                name: 'Board',
                items: <TrainingMethodItem>[
                  TrainingMethodItem(
                    id: 'player-1',
                    type: 'player',
                    x: 0.30,
                    y: 0.55,
                  ),
                ],
              ),
            ],
          ).encode(),
          onSaved: (value) => savedLayout = value,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final boardFinder = find.byKey(const ValueKey('training-board-canvas'));
    await tester.tap(
      find.descendant(of: boardFinder, matching: find.byIcon(Icons.person)),
    );
    await tester.pumpAndSettle();
    await _tapVisibleOutlinedButton(tester, '드리블');
    await _tapBoardRelative(tester, boardFinder, const Offset(0.62, 0.42));

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final page = saved.pages.single;
    expect(page.items.where((item) => item.type == 'ball'), hasLength(1));
    final player = page.items.singleWhere((item) => item.type == 'player');
    final ball = page.items.singleWhere((item) => item.type == 'ball');
    final playerRoute = page.routes.singleWhere(
      (route) => route.kind == TrainingMethodRouteKind.player,
    );
    final ballRoute = page.routes.singleWhere(
      (route) => route.kind == TrainingMethodRouteKind.ball,
    );

    expect(playerRoute.linkedItemId, 'player-1');
    expect(ballRoute.stageIndex, playerRoute.stageIndex);
    expect(playerRoute.stageIndex, 1);
    expect(_isItemAheadOf(ball, player, const Offset(0.62, 0.42)), isTrue);
    expect(playerRoute.points.last.x, closeTo(0.62, 0.02));
    expect(playerRoute.points.last.y, closeTo(0.42, 0.02));
    expect(ballRoute.points.last.x, closeTo(0.62, 0.02));
    expect(ballRoute.points.last.y, closeTo(0.42, 0.02));
  });

  testWidgets('dribble does not move a paired carry route to stage two', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);
    String? savedLayout;

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '드리블 단계',
          initialLayoutJson: const TrainingMethodLayout(
            pages: <TrainingMethodPage>[
              TrainingMethodPage(
                name: 'Board',
                items: <TrainingMethodItem>[
                  TrainingMethodItem(
                    id: 'player-1',
                    type: 'player',
                    x: 0.30,
                    y: 0.55,
                  ),
                  TrainingMethodItem(
                    id: 'ball-1',
                    type: 'ball',
                    x: 0.36,
                    y: 0.55,
                    colorValue: 0xFFFFCA28,
                  ),
                ],
                routes: <TrainingMethodRoute>[
                  TrainingMethodRoute(
                    id: 'route-ball-1',
                    kind: TrainingMethodRouteKind.ball,
                    linkedItemId: 'ball-1',
                    stageIndex: 1,
                    points: <TrainingMethodPoint>[
                      TrainingMethodPoint(x: 0.36, y: 0.55),
                      TrainingMethodPoint(x: 0.48, y: 0.50),
                    ],
                  ),
                ],
              ),
            ],
          ).encode(),
          onSaved: (value) => savedLayout = value,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final boardFinder = find.byKey(const ValueKey('training-board-canvas'));
    await tester.tap(
      find.descendant(of: boardFinder, matching: find.byIcon(Icons.person)),
    );
    await tester.pumpAndSettle();
    await _tapVisibleOutlinedButton(tester, '드리블');
    await _tapBoardRelative(tester, boardFinder, const Offset(0.62, 0.42));

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final playerRoute = saved.pages.single.routes.singleWhere(
      (route) => route.kind == TrainingMethodRouteKind.player,
    );
    final ballRoute = saved.pages.single.routes.singleWhere(
      (route) => route.kind == TrainingMethodRouteKind.ball,
    );

    expect(playerRoute.stageIndex, 1);
    expect(ballRoute.stageIndex, 1);
  });

  testWidgets('ball dribble action creates a controlled player when needed', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);
    String? savedLayout;

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '공 드리블',
          initialLayoutJson: const TrainingMethodLayout(
            pages: <TrainingMethodPage>[
              TrainingMethodPage(
                name: 'Board',
                items: <TrainingMethodItem>[
                  TrainingMethodItem(
                    id: 'ball-1',
                    type: 'ball',
                    x: 0.36,
                    y: 0.54,
                    colorValue: 0xFFFFCA28,
                  ),
                ],
              ),
            ],
          ).encode(),
          onSaved: (value) => savedLayout = value,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final boardFinder = find.byKey(const ValueKey('training-board-canvas'));
    await tester.tap(
      find.descendant(
        of: boardFinder,
        matching: find.byIcon(Icons.sports_soccer),
      ),
    );
    await tester.pumpAndSettle();
    await _tapVisibleOutlinedButton(tester, '드리블');
    await _tapBoardRelative(tester, boardFinder, const Offset(0.62, 0.42));

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final page = saved.pages.single;
    expect(page.items.where((item) => item.type == 'player'), hasLength(1));
    final player = page.items.singleWhere((item) => item.type == 'player');
    final ball = page.items.singleWhere((item) => item.type == 'ball');
    final playerRoute = page.routes.singleWhere(
      (route) => route.kind == TrainingMethodRouteKind.player,
    );
    final ballRoute = page.routes.singleWhere(
      (route) => route.kind == TrainingMethodRouteKind.ball,
    );

    expect((player.x - ball.x).abs(), lessThan(0.08));
    expect((player.y - ball.y).abs(), lessThan(0.06));
    expect(_isItemAheadOf(ball, player, const Offset(0.62, 0.42)), isTrue);
    expect(playerRoute.linkedItemId, player.id);
    expect(ballRoute.linkedItemId, 'ball-1');
    expect(ballRoute.stageIndex, playerRoute.stageIndex);
    expect(playerRoute.points.last.x, closeTo(0.62, 0.02));
    expect(playerRoute.points.last.y, closeTo(0.42, 0.02));
    expect(ballRoute.points.last.x, closeTo(0.62, 0.02));
    expect(ballRoute.points.last.y, closeTo(0.42, 0.02));
  });

  testWidgets(
      'selected player can create a route with taps and undo last point', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);
    String? savedLayout;

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '탭 이동선',
          initialLayoutJson: const TrainingMethodLayout(
            pages: <TrainingMethodPage>[
              TrainingMethodPage(
                name: 'Board',
                items: <TrainingMethodItem>[
                  TrainingMethodItem(
                    id: 'player-1',
                    type: 'player',
                    x: 0.2,
                    y: 0.5,
                  ),
                ],
              ),
            ],
          ).encode(),
          onSaved: (value) => savedLayout = value,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final boardFinder = find.byKey(const ValueKey('training-board-canvas'));
    await tester.tap(
      find.descendant(of: boardFinder, matching: find.byIcon(Icons.person)),
    );
    await tester.pumpAndSettle();
    await _tapVisibleOutlinedButton(tester, '이동 만들기');
    await _tapBoardRelative(tester, boardFinder, const Offset(0.50, 0.36));
    await _tapBoardRelative(tester, boardFinder, const Offset(0.72, 0.36));
    await _tapVisibleOutlinedButton(tester, '마지막 점 취소');
    await _tapVisibleOutlinedButton(tester, '이동선 완료');

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final route = saved.pages.single.routes.single;
    expect(route.linkedItemId, 'player-1');
    expect(route.points, hasLength(2));
    expect(route.points.first.x, closeTo(0.2, 0.001));
    expect(route.points.first.y, closeTo(0.5, 0.001));
    expect(route.points.last.x, closeTo(0.50, 0.02));
    expect(route.points.last.y, closeTo(0.36, 0.02));
  });

  testWidgets('quick pass then move creates staged ball and player routes', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);
    String? savedLayout;

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '빠른 동작',
          initialLayoutJson: const TrainingMethodLayout(
            pages: <TrainingMethodPage>[
              TrainingMethodPage(
                name: 'Board',
                items: <TrainingMethodItem>[
                  TrainingMethodItem(
                    id: 'player-1',
                    type: 'player',
                    x: 0.2,
                    y: 0.5,
                  ),
                  TrainingMethodItem(
                    id: 'player-2',
                    type: 'player',
                    x: 0.62,
                    y: 0.46,
                    colorValue: 0xFF1E88E5,
                  ),
                  TrainingMethodItem(
                    id: 'ball-1',
                    type: 'ball',
                    x: 0.28,
                    y: 0.50,
                    colorValue: 0xFFFFCA28,
                  ),
                ],
              ),
            ],
          ).encode(),
          onSaved: (value) => savedLayout = value,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final boardFinder = find.byKey(const ValueKey('training-board-canvas'));
    await tester.tap(
      find
          .descendant(of: boardFinder, matching: find.byIcon(Icons.person))
          .first,
    );
    await tester.pumpAndSettle();
    await _tapVisibleOutlinedButton(tester, '패스 후 이동');
    expect(find.text('패스 후 이동 대상이나 공간을 누르세요.'), findsOneWidget);
    await _tapBoardRelative(tester, boardFinder, const Offset(0.62, 0.46));

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final routes = saved.pages.single.routes;
    final ballRoute = routes.singleWhere(
      (route) => route.kind == TrainingMethodRouteKind.ball,
    );
    final playerRoute = routes.singleWhere(
      (route) => route.kind == TrainingMethodRouteKind.player,
    );

    expect(ballRoute.linkedItemId, 'ball-1');
    expect(ballRoute.stageIndex, 1);
    expect(playerRoute.linkedItemId, 'player-1');
    expect(playerRoute.stageIndex, 2);
  });

  testWidgets('targeted pass action creates a ball route to player number', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);
    String? savedLayout;

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '대상 패스',
          initialLayoutJson: const TrainingMethodLayout(
            pages: <TrainingMethodPage>[
              TrainingMethodPage(
                name: 'Board',
                items: <TrainingMethodItem>[
                  TrainingMethodItem(
                    id: 'player-1',
                    type: 'player',
                    x: 0.22,
                    y: 0.52,
                  ),
                  TrainingMethodItem(
                    id: 'player-2',
                    type: 'player',
                    x: 0.68,
                    y: 0.42,
                    colorValue: 0xFF1E88E5,
                  ),
                  TrainingMethodItem(
                    id: 'ball-1',
                    type: 'ball',
                    x: 0.32,
                    y: 0.52,
                    colorValue: 0xFFFFCA28,
                  ),
                ],
              ),
            ],
          ).encode(),
          onSaved: (value) => savedLayout = value,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final boardFinder = find.byKey(const ValueKey('training-board-canvas'));
    await tester.tap(
      find.descendant(
        of: boardFinder,
        matching: find.byIcon(Icons.sports_soccer),
      ),
    );
    await tester.pumpAndSettle();
    await _tapVisibleOutlinedButton(tester, '패스');
    expect(find.text('패스 대상이나 공간을 누르세요.'), findsOneWidget);
    await _tapBoardRelative(tester, boardFinder, const Offset(0.68, 0.42));

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final route = saved.pages.single.routes.single;
    expect(route.kind, TrainingMethodRouteKind.ball);
    expect(route.linkedItemId, 'ball-1');
    expect(route.points.last.x, closeTo(0.68, 0.001));
    expect(route.points.last.y, closeTo(0.42, 0.001));
  });

  testWidgets('tennis serve action creates a ball route to a target', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);
    String? savedLayout;

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '서브 스케치',
          initialLayoutJson: const TrainingMethodLayout(
            pages: <TrainingMethodPage>[
              TrainingMethodPage(
                name: 'Board',
                items: <TrainingMethodItem>[
                  TrainingMethodItem(
                    id: 'ball-1',
                    type: 'ball',
                    x: 0.42,
                    y: 0.76,
                    colorValue: 0xFFFFCA28,
                  ),
                  TrainingMethodItem(
                    id: 'target-1',
                    type: 'target',
                    x: 0.70,
                    y: 0.34,
                    colorValue: 0xFFEC407A,
                  ),
                ],
              ),
            ],
          ).encode(),
          sportId: SportCatalog.tennisId,
          onSaved: (value) => savedLayout = value,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final boardFinder = find.byKey(const ValueKey('training-board-canvas'));
    await tester.tap(
      find.descendant(
        of: boardFinder,
        matching: find.byIcon(Icons.sports_tennis),
      ),
    );
    await tester.pumpAndSettle();
    await _tapVisibleOutlinedButton(tester, '서브');
    expect(find.text('서브 대상이나 공간을 누르세요.'), findsOneWidget);
    await _tapBoardRelative(tester, boardFinder, const Offset(0.70, 0.34));

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final route = saved.pages.single.routes.single;
    expect(route.kind, TrainingMethodRouteKind.ball);
    expect(route.linkedItemId, 'ball-1');
    expect(route.points.last.x, closeTo(0.70, 0.001));
    expect(route.points.last.y, closeTo(0.34, 0.001));
  });

  testWidgets('training sketch auto saves after memo edit', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);
    String? savedLayout;

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '자동 저장',
          initialLayoutJson: const TrainingMethodLayout(
            pages: <TrainingMethodPage>[
              TrainingMethodPage(name: '자동 저장', items: <TrainingMethodItem>[]),
            ],
          ).encode(),
          onSaved: (value) => savedLayout = value,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _tapTopBarMenuItem(
      tester,
      isLandscape: true,
      itemKey: 'training-topbar-menu-notes',
    );
    await tester.enterText(find.byType(TextField).first, '메모 자동 저장');
    await tester.pump(const Duration(milliseconds: 900));

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    expect(saved.pages.single.methodText, '메모 자동 저장');
  });

  testWidgets('managed training sketch auto save awards daily sketch xp', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);
    final optionRepository = _MemoryOptionRepository();
    final board = await TrainingBoardService(optionRepository).createBoard(
      title: '자동 저장 XP',
      layoutJson: const TrainingMethodLayout(
        pages: <TrainingMethodPage>[
          TrainingMethodPage(name: '자동 저장 XP', items: <TrainingMethodItem>[]),
        ],
      ).encode(),
    );

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: board.title,
          initialLayoutJson: board.layoutJson,
          optionRepository: optionRepository,
          initialSelectedBoardIds: <String>[board.id],
          initialBoardId: board.id,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _tapTopBarMenuItem(
      tester,
      isLandscape: true,
      itemKey: 'training-topbar-menu-notes',
    );
    await tester.enterText(find.byType(TextField).first, '자동 저장도 XP');
    await tester.pump(const Duration(milliseconds: 900));

    expect(PlayerLevelService(optionRepository).loadState().totalXp, 2);
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

    final boardFinder = find.byKey(const ValueKey('training-board-canvas'));
    final playerFinder = find.descendant(
      of: boardFinder,
      matching: find.byIcon(Icons.person),
    );
    final coneFinder = find.descendant(
      of: boardFinder,
      matching: find.byIcon(Icons.change_history),
    );
    await _openMoveRouteToolForIcon(tester, playerFinder.first);
    await _tapTopBarMenuItem(
      tester,
      isLandscape: true,
      itemKey: 'training-topbar-menu-controls',
    );

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

    final boardFinder = find.byKey(const ValueKey('training-board-canvas'));
    await _openMoveRouteToolForIcon(
      tester,
      find
          .descendant(of: boardFinder, matching: find.byIcon(Icons.person))
          .at(1),
    );

    await _tapVisibleOutlinedButton(tester, '선택 이동선 삭제');

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

  testWidgets('long pressing a linked item moves it while route tool is active',
      (
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
    await _openMoveRouteToolForIcon(tester, playerFinder);

    final gesture = await tester.startGesture(tester.getCenter(playerFinder));
    await tester.pump(const Duration(milliseconds: 700));
    await gesture.moveBy(const Offset(52, -34));
    await tester.pumpAndSettle();
    await gesture.up();
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final page = saved.pages.single;
    final player = page.items.single;
    final dx = player.x - 0.2;
    final dy = player.y - 0.5;

    expect(dx, greaterThan(0.001));
    expect(dy, lessThan(-0.001));

    final route = page.routes.single;
    expect(route.points[0].x, closeTo(0.2 + dx, 0.0001));
    expect(route.points[0].y, closeTo(0.5 + dy, 0.0001));
    expect(route.points[1].x, closeTo(0.45 + dx, 0.0001));
    expect(route.points[1].y, closeTo(0.35 + dy, 0.0001));
  });

  testWidgets('dragging a player while route tool is active moves the player', (
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
    await _openMoveRouteToolForIcon(tester, playerFinder);
    await tester.drag(playerFinder, const Offset(48, -28));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final player = saved.pages.single.items.single;
    final route = saved.pages.single.routes.single;
    final dx = player.x - 0.2;
    final dy = player.y - 0.5;

    expect(dx, greaterThan(0.001));
    expect(dy, lessThan(-0.001));
    expect(route.points[0].x, closeTo(0.2 + dx, 0.0001));
    expect(route.points[0].y, closeTo(0.5 + dy, 0.0001));
    expect(route.points[1].x, closeTo(0.45 + dx, 0.0001));
    expect(route.points[1].y, closeTo(0.35 + dy, 0.0001));
  });

  testWidgets('dragging a ball while route tool is active moves the ball', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);
    String? savedLayout;
    final initialLayout = const TrainingMethodLayout(
      pages: <TrainingMethodPage>[
        TrainingMethodPage(
          name: 'Board',
          items: <TrainingMethodItem>[
            TrainingMethodItem(
              id: 'ball-1',
              type: 'ball',
              x: 0.24,
              y: 0.58,
              colorValue: 0xFFFFCA28,
            ),
          ],
          routes: <TrainingMethodRoute>[
            TrainingMethodRoute(
              id: 'route-ball-1',
              kind: TrainingMethodRouteKind.ball,
              linkedItemId: 'ball-1',
              points: <TrainingMethodPoint>[
                TrainingMethodPoint(x: 0.24, y: 0.58),
                TrainingMethodPoint(x: 0.62, y: 0.46),
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
    final ballFinder = find.descendant(
      of: boardFinder,
      matching: find.byIcon(Icons.sports_soccer),
    );
    await _openPassRouteToolForIcon(tester, ballFinder);
    await tester.drag(ballFinder, const Offset(56, -22));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final ball = saved.pages.single.items.single;
    final route = saved.pages.single.routes.single;
    final dx = ball.x - 0.24;
    final dy = ball.y - 0.58;

    expect(dx, greaterThan(0.001));
    expect(dy, lessThan(-0.001));
    expect(route.points[0].x, closeTo(0.24 + dx, 0.0001));
    expect(route.points[0].y, closeTo(0.58 + dy, 0.0001));
    expect(route.points[1].x, closeTo(0.62 + dx, 0.0001));
    expect(route.points[1].y, closeTo(0.46 + dy, 0.0001));
  });

  testWidgets(
      'selecting a player while ball route tool is active switches tools', (
    WidgetTester tester,
  ) async {
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
              x: 0.22,
              y: 0.52,
            ),
            TrainingMethodItem(
              id: 'ball-1',
              type: 'ball',
              x: 0.36,
              y: 0.52,
              colorValue: 0xFFFFCA28,
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
    await _openPassRouteToolForIcon(
      tester,
      find.descendant(
        of: boardFinder,
        matching: find.byIcon(Icons.sports_soccer),
      ),
    );
    await tester.tap(
      find.descendant(of: boardFinder, matching: find.byIcon(Icons.person)),
    );
    await tester.pumpAndSettle();

    expect(find.text('사람 동작'), findsOneWidget);

    await _tapBoardRelative(tester, boardFinder, const Offset(0.52, 0.36));
    await _tapVisibleOutlinedButton(tester, '이동선 완료');

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final route = saved.pages.single.routes.single;
    expect(route.kind, TrainingMethodRouteKind.player);
    expect(route.linkedItemId, 'player-1');
    expect(route.points.first.x, closeTo(0.22, 0.001));
    expect(route.points.first.y, closeTo(0.52, 0.001));
  });

  testWidgets('players and balls are hit-tested above training props', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);
    final initialLayout = const TrainingMethodLayout(
      pages: <TrainingMethodPage>[
        TrainingMethodPage(
          name: 'Board',
          items: <TrainingMethodItem>[
            TrainingMethodItem(id: 'cone-1', type: 'cone', x: 0.28, y: 0.50),
            TrainingMethodItem(
                id: 'player-1', type: 'player', x: 0.28, y: 0.50),
            TrainingMethodItem(
                id: 'ladder-1', type: 'ladder', x: 0.62, y: 0.50),
            TrainingMethodItem(
              id: 'ball-1',
              type: 'ball',
              x: 0.62,
              y: 0.50,
              colorValue: 0xFFFFCA28,
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
        ),
      ),
    );
    await tester.pumpAndSettle();

    final boardFinder = find.byKey(const ValueKey('training-board-canvas'));
    final boardTopLeft = tester.getTopLeft(boardFinder);
    final boardSize = tester.getSize(boardFinder);

    await tester.tapAt(
      boardTopLeft + Offset(boardSize.width * 0.28, boardSize.height * 0.50),
    );
    await tester.pumpAndSettle();
    expect(find.widgetWithText(OutlinedButton, '이동 만들기'), findsOneWidget);

    await tester.tapAt(
      boardTopLeft + Offset(boardSize.width * 0.62, boardSize.height * 0.50),
    );
    await tester.pumpAndSettle();
    expect(find.widgetWithText(OutlinedButton, '패스 만들기'), findsOneWidget);
  });

  testWidgets(
    'new move route links to the selected player',
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

      final boardFinder = find.byKey(const ValueKey('training-board-canvas'));
      await _openMoveRouteToolForIcon(
        tester,
        find
            .descendant(of: boardFinder, matching: find.byIcon(Icons.person))
            .at(1),
      );
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
    'selected ball pass action creates a ball route with ball color',
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
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('training-ball-path-mode-button')),
        findsNothing,
      );

      final boardFinder = find.byKey(const ValueKey('training-board-canvas'));
      await _tapVisibleOutlinedButton(tester, '패스');
      await _tapBoardRelative(tester, boardFinder, const Offset(0.72, 0.32));

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

  testWidgets('route actions live inside selected player and ball panels', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '패스 워밍업',
          initialLayoutJson: const TrainingMethodLayout(
            pages: <TrainingMethodPage>[
              TrainingMethodPage(
                name: 'Board',
                items: <TrainingMethodItem>[
                  TrainingMethodItem(
                    id: 'player-1',
                    type: 'player',
                    x: 0.2,
                    y: 0.5,
                  ),
                  TrainingMethodItem(
                    id: 'ball-1',
                    type: 'ball',
                    x: 0.62,
                    y: 0.46,
                    colorValue: 0xFFFFCA28,
                  ),
                ],
              ),
            ],
          ).encode(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('training-player-path-mode-button')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('training-ball-path-mode-button')),
      findsNothing,
    );

    final boardFinder = find.byKey(const ValueKey('training-board-canvas'));
    await tester.tap(
      find.descendant(of: boardFinder, matching: find.byIcon(Icons.person)),
    );
    await tester.pumpAndSettle();
    expect(find.widgetWithText(OutlinedButton, '이동 만들기'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '돌아오기'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '오버랩'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: boardFinder,
        matching: find.byIcon(Icons.sports_soccer),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.widgetWithText(OutlinedButton, '패스 만들기'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '슈팅'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '크로스'), findsOneWidget);
    expect(find.text('패스·드리블 플로우'), findsNothing);
  });

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

    await _tapTopBarMenuItem(
      tester,
      isLandscape: true,
      itemKey: 'training-topbar-menu-controls',
    );

    expect(
      find.byKey(const ValueKey('training-landscape-control-panel')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('training-board-canvas')), findsOneWidget);

    await _tapTopBarMenuItem(
      tester,
      isLandscape: true,
      itemKey: 'training-topbar-menu-notes',
    );

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

  testWidgets('tactical overlay can be toggled from the sketch menu', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);

    await tester.pumpWidget(
      _buildApp(
        const TrainingMethodBoardScreen(
          boardTitle: '전술 보드',
          initialLayoutJson: '',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester
        .tap(find.byKey(const ValueKey('training-landscape-topbar-menu')));
    await tester.pumpAndSettle();

    expect(find.text('전술 구역 표시'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('training-topbar-menu-tactical-overlay')).last,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('training-board-canvas')), findsOneWidget);
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

    await _tapTopBarMenuItem(
      tester,
      isLandscape: false,
      itemKey: 'training-topbar-menu-controls',
    );

    expect(
      find.byKey(const ValueKey('training-portrait-inspector-panel')),
      findsNothing,
    );

    await _tapTopBarMenuItem(
      tester,
      isLandscape: false,
      itemKey: 'training-topbar-menu-notes',
    );

    expect(
      find.byKey(const ValueKey('training-portrait-memo-panel')),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsOneWidget);

    await _tapTopBarMenuItem(
      tester,
      isLandscape: false,
      itemKey: 'training-topbar-menu-controls',
    );

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

    final boardFinder = find.byKey(const ValueKey('training-board-canvas'));
    final playerFinder = find.descendant(
      of: boardFinder,
      matching: find.byIcon(Icons.person),
    );

    await _openMoveRouteToolForIcon(tester, playerFinder);
    await _tapTopBarMenuItem(
      tester,
      isLandscape: true,
      itemKey: 'training-topbar-menu-controls',
    );

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
    expect(route.points.first.x, closeTo(0.20, 0.02));
    expect(route.points.first.y, closeTo(0.50, 0.03));
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

      final boardFinder = find.byKey(const ValueKey('training-board-canvas'));
      await _tapVisibleOutlinedButton(tester, '이동 만들기');
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

  testWidgets('playback keeps the previously selected route tool', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);
    final initialLayout = const TrainingMethodLayout(
      pages: <TrainingMethodPage>[
        TrainingMethodPage(
          name: 'Board',
          items: <TrainingMethodItem>[
            TrainingMethodItem(id: 'player-1', type: 'player', x: 0.2, y: 0.5),
            TrainingMethodItem(id: 'ball-1', type: 'ball', x: 0.34, y: 0.5),
          ],
          routes: <TrainingMethodRoute>[
            TrainingMethodRoute(
              id: 'route-player-1',
              kind: TrainingMethodRouteKind.player,
              linkedItemId: 'player-1',
              points: <TrainingMethodPoint>[
                TrainingMethodPoint(x: 0.2, y: 0.5),
                TrainingMethodPoint(x: 0.38, y: 0.5),
              ],
            ),
            TrainingMethodRoute(
              id: 'route-ball-1',
              kind: TrainingMethodRouteKind.ball,
              linkedItemId: 'ball-1',
              points: <TrainingMethodPoint>[
                TrainingMethodPoint(x: 0.34, y: 0.5),
                TrainingMethodPoint(x: 0.56, y: 0.44),
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
        ),
      ),
    );
    await tester.pumpAndSettle();

    final boardFinder = find.byKey(const ValueKey('training-board-canvas'));
    await _openPassRouteToolForIcon(
      tester,
      find.descendant(
        of: boardFinder,
        matching: find.byIcon(Icons.sports_soccer),
      ),
    );
    expect(
      find.byKey(const ValueKey('training-route-target-ball-ball-1')),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(Icons.play_circle_outline).first);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('training-route-target-ball-ball-1')),
      findsOneWidget,
    );
  });

  testWidgets(
    'playback moves the ball farther than the player over equal time',
    (WidgetTester tester) async {
      _setLandscapeSurface(tester);

      final initialLayout = const TrainingMethodLayout(
        pages: <TrainingMethodPage>[
          TrainingMethodPage(
            name: 'Board',
            items: <TrainingMethodItem>[
              TrainingMethodItem(
                id: 'player-1',
                type: 'player',
                x: 0.18,
                y: 0.3,
              ),
              TrainingMethodItem(
                id: 'ball-1',
                type: 'ball',
                x: 0.18,
                y: 0.62,
                colorValue: 0xFFE53935,
              ),
            ],
            routes: <TrainingMethodRoute>[
              TrainingMethodRoute(
                id: 'route-player-1',
                kind: TrainingMethodRouteKind.player,
                linkedItemId: 'player-1',
                points: <TrainingMethodPoint>[
                  TrainingMethodPoint(x: 0.18, y: 0.3),
                  TrainingMethodPoint(x: 0.38, y: 0.3),
                ],
              ),
              TrainingMethodRoute(
                id: 'route-ball-1',
                kind: TrainingMethodRouteKind.ball,
                linkedItemId: 'ball-1',
                points: <TrainingMethodPoint>[
                  TrainingMethodPoint(x: 0.18, y: 0.62),
                  TrainingMethodPoint(x: 0.58, y: 0.62),
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
          ),
        ),
      );
      await tester.pumpAndSettle();

      final boardFinder = find.byKey(const ValueKey('training-board-canvas'));
      final playerFinder = find.descendant(
        of: boardFinder,
        matching: find.byIcon(Icons.person),
      );
      final ballFinder = find.descendant(
        of: boardFinder,
        matching: find.byIcon(Icons.sports_soccer),
      );

      final playerBefore = tester.getCenter(playerFinder);
      final ballBefore = tester.getCenter(ballFinder);

      await tester.tap(find.byIcon(Icons.play_circle_outline).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final playerAfter = tester.getCenter(playerFinder);
      final ballAfter = tester.getCenter(ballFinder);
      final playerDelta = (playerAfter - playerBefore).distance;
      final ballDelta = (ballAfter - ballBefore).distance;

      expect(playerDelta, greaterThan(1));
      expect(ballDelta, greaterThan(1));
      expect(ballDelta, greaterThan(playerDelta + 8));
    },
  );
}

bool _samePoint(TrainingMethodPoint a, TrainingMethodPoint b) {
  return (a.x - b.x).abs() < 0.0001 && (a.y - b.y).abs() < 0.0001;
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

Future<void> _tapBoardRelative(
  WidgetTester tester,
  Finder boardFinder,
  Offset relativePosition,
) async {
  final detector = tester.widget<GestureDetector>(boardFinder);
  final size = tester.getSize(boardFinder);
  final localPosition = Offset(
    size.width * relativePosition.dx,
    size.height * relativePosition.dy,
  );
  detector.onTapUp!(
    TapUpDetails(
      kind: PointerDeviceKind.touch,
      localPosition: localPosition,
      globalPosition: localPosition,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapVisibleOutlinedButton(
  WidgetTester tester,
  String label,
) async {
  final finder = find.widgetWithText(OutlinedButton, label);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _openMoveRouteToolForIcon(
  WidgetTester tester,
  Finder iconFinder,
) async {
  await tester.tap(iconFinder);
  await tester.pumpAndSettle();
  await _tapVisibleOutlinedButton(tester, '이동 만들기');
}

Future<void> _openPassRouteToolForIcon(
  WidgetTester tester,
  Finder iconFinder,
) async {
  await tester.tap(iconFinder);
  await tester.pumpAndSettle();
  await _tapVisibleOutlinedButton(tester, '패스 만들기');
}

Future<void> _tapTopBarMenuItem(
  WidgetTester tester, {
  required bool isLandscape,
  required String itemKey,
}) async {
  final menuKey = ValueKey(
    isLandscape
        ? 'training-landscape-topbar-menu'
        : 'training-portrait-topbar-menu',
  );
  await tester.tap(find.byKey(menuKey));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ValueKey(itemKey)).last);
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

bool _isItemAheadOf(
  TrainingMethodItem item,
  TrainingMethodItem origin,
  Offset target,
) {
  final itemVector = Offset(item.x - origin.x, item.y - origin.y);
  final targetVector = Offset(target.dx - origin.x, target.dy - origin.y);
  final dot =
      (itemVector.dx * targetVector.dx) + (itemVector.dy * targetVector.dy);
  return dot > 0 && itemVector.distance > 0.045;
}

class _MemoryOptionRepository implements OptionRepository {
  final Map<String, dynamic> _values = <String, dynamic>{};

  @override
  List<String> getOptions(String key, List<String> defaults) {
    final stored = _values[key];
    if (stored is List) {
      return stored.map((item) => item.toString()).toList();
    }
    _values[key] = List<String>.from(defaults);
    return List<String>.from(defaults);
  }

  @override
  List<int> getIntOptions(String key, List<int> defaults) {
    final stored = _values[key];
    if (stored is List) {
      return stored.map((item) => int.tryParse(item.toString()) ?? 0).toList();
    }
    _values[key] = List<int>.from(defaults);
    return List<int>.from(defaults);
  }

  @override
  T? getValue<T>(String key) {
    final value = _values[key];
    if (value is T) return value;
    return null;
  }

  @override
  Future<void> setValue(String key, dynamic value) async {
    _values[key] = value;
  }

  @override
  Future<void> saveOptions(String key, List<dynamic> options) async {
    _values[key] = List<dynamic>.from(options);
  }
}
