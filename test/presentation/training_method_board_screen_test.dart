import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  test('training sketch routes preserve player action ownership', () {
    final encoded = const TrainingMethodLayout(
      pages: <TrainingMethodPage>[
        TrainingMethodPage(
          name: 'Owned action',
          items: <TrainingMethodItem>[],
          routes: <TrainingMethodRoute>[
            TrainingMethodRoute(
              id: 'owned-ball',
              kind: TrainingMethodRouteKind.ball,
              linkedItemId: 'ball-1',
              actorItemId: 'player-1',
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

    expect(decoded.pages.single.routes.single.actorItemId, 'player-1');
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

  testWidgets('same player actions append to one connected route', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);
    String? savedLayout;

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '연속 이동',
          initialLayoutJson: const TrainingMethodLayout(
            pages: <TrainingMethodPage>[
              TrainingMethodPage(
                name: 'Board',
                items: <TrainingMethodItem>[
                  TrainingMethodItem(
                    id: 'player-1',
                    type: 'player',
                    x: 0.24,
                    y: 0.52,
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
    await _tapVisibleOutlinedButton(tester, '이동');
    await _tapBoardRelative(tester, boardFinder, const Offset(0.48, 0.44));
    await _tapVisibleOutlinedButton(tester, '이동');
    await _tapBoardRelative(tester, boardFinder, const Offset(0.72, 0.38));

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final route = saved.pages.single.routes.single;

    expect(route.kind, TrainingMethodRouteKind.player);
    expect(route.linkedItemId, 'player-1');
    expect(route.points, hasLength(3));
    expect(route.points[1].x, closeTo(0.48, 0.02));
    expect(route.points[1].y, closeTo(0.44, 0.02));
    expect(route.points.last.x, closeTo(0.72, 0.02));
    expect(route.points.last.y, closeTo(0.38, 0.02));
  });

  testWidgets('selected ball does not expose sketch actions', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);

    await tester.pumpWidget(
      _buildApp(
        const TrainingMethodBoardScreen(
          boardTitle: '즉시 공 이동선',
          initialLayoutJson: '',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, '공'));
    await tester.pumpAndSettle();

    final boardFinder = find.byKey(const ValueKey('training-board-canvas'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
          of: boardFinder, matching: find.byIcon(Icons.sports_soccer)),
      findsOneWidget,
    );
    expect(find.widgetWithText(OutlinedButton, '패스'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, '드리블'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, '슈팅'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, '패스 만들기'), findsNothing);
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

  testWidgets('pass after a player move starts from the move end', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);
    String? savedLayout;

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '이동 후 패스',
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
    await _tapVisibleOutlinedButton(tester, '이동');
    await _tapBoardRelative(tester, boardFinder, const Offset(0.50, 0.44));
    await _tapVisibleOutlinedButton(tester, '패스');
    await _tapBoardRelative(tester, boardFinder, const Offset(0.74, 0.38));

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final page = saved.pages.single;
    final playerRoute = page.routes.singleWhere(
      (route) => route.kind == TrainingMethodRouteKind.player,
    );
    final ballRoute = page.routes.singleWhere(
      (route) => route.kind == TrainingMethodRouteKind.ball,
    );
    final moveEnd =
        Offset(playerRoute.points.last.x, playerRoute.points.last.y);
    final passStart =
        Offset(ballRoute.points.first.x, ballRoute.points.first.y);

    expect(playerRoute.stageIndex, 1);
    expect(moveEnd.dx, closeTo(0.50, 0.02));
    expect(moveEnd.dy, closeTo(0.44, 0.02));
    expect(ballRoute.stageIndex, 2);
    expect((passStart - moveEnd).distance, closeTo(0.07, 0.02));
    expect(ballRoute.points.last.x, closeTo(0.74, 0.02));
    expect(ballRoute.points.last.y, closeTo(0.38, 0.02));
  });

  testWidgets('dribble after pass and move continues from the move end', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);
    String? savedLayout;

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '패스 이동 드리블',
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
                    x: 0.54,
                    y: 0.44,
                    colorValue: 0xFF1E88E5,
                  ),
                  TrainingMethodItem(
                    id: 'ball-1',
                    type: 'ball',
                    x: 0.29,
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
      find
          .descendant(of: boardFinder, matching: find.byIcon(Icons.person))
          .first,
    );
    await tester.pumpAndSettle();
    await _tapVisibleOutlinedButton(tester, '패스 후 이동');
    await _tapBoardRelativeThroughWidgets(
      tester,
      boardFinder,
      const Offset(0.54, 0.44),
    );
    await _tapBoardRelative(tester, boardFinder, const Offset(0.64, 0.38));
    await _tapVisibleOutlinedButton(tester, '드리블');
    await _tapBoardRelative(tester, boardFinder, const Offset(0.80, 0.34));

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final page = saved.pages.single;
    final playerRoute = page.routes.singleWhere(
      (route) => route.kind == TrainingMethodRouteKind.player,
    );
    final ballRoutes = page.routes
        .where((route) => route.kind == TrainingMethodRouteKind.ball)
        .toList(growable: false);
    final dribbleRoute = ballRoutes.singleWhere(
      (route) => route.stageIndex == 2,
    );
    final dribbleStart = Offset(
      dribbleRoute.points.first.x,
      dribbleRoute.points.first.y,
    );
    final movePoint = Offset(
      playerRoute.points[playerRoute.points.length - 3].x,
      playerRoute.points[playerRoute.points.length - 3].y,
    );

    expect(ballRoutes, hasLength(2));
    expect(ballRoutes.map((route) => route.linkedItemId).toSet(), {'ball-1'});
    expect(playerRoute.stageIndex, 2);
    expect(playerRoute.points.length, greaterThanOrEqualTo(3));
    expect(movePoint.dx, closeTo(0.64, 0.02));
    expect(movePoint.dy, closeTo(0.38, 0.02));
    expect(dribbleRoute.stageIndex, 2);
    expect((dribbleStart - movePoint).distance, closeTo(0.07, 0.02));
    expect(playerRoute.points.last.x, closeTo(0.80, 0.02));
    expect(playerRoute.points.last.y, closeTo(0.34, 0.02));
    expect(dribbleRoute.points.last.x, closeTo(0.80, 0.02));
    expect(dribbleRoute.points.last.y, closeTo(0.34, 0.02));
  });

  testWidgets('player cone turn action creates a cone and curved route', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);
    String? savedLayout;

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '콘 돌기',
          initialLayoutJson: const TrainingMethodLayout(
            pages: <TrainingMethodPage>[
              TrainingMethodPage(
                name: 'Board',
                items: <TrainingMethodItem>[
                  TrainingMethodItem(
                    id: 'player-1',
                    type: 'player',
                    x: 0.28,
                    y: 0.54,
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
    await _tapVisibleOutlinedButton(tester, '콘 돌기');
    expect(find.text('콘 돌기 대상이나 공간을 누르세요.'), findsOneWidget);
    await _tapBoardRelative(tester, boardFinder, const Offset(0.58, 0.43));

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final page = saved.pages.single;
    final player = page.items.singleWhere((item) => item.type == 'player');
    final cone = page.items.singleWhere((item) => item.type == 'cone');
    final route = page.routes.single;
    final nearConePointCount = route.points.where((point) {
      return Offset(point.x - cone.x, point.y - cone.y).distance < 0.065;
    }).length;

    expect(cone.x, closeTo(0.58, 0.02));
    expect(cone.y, closeTo(0.43, 0.02));
    expect(route.kind, TrainingMethodRouteKind.player);
    expect(route.linkedItemId, player.id);
    expect(route.points, hasLength(greaterThanOrEqualTo(6)));
    expect(nearConePointCount, greaterThanOrEqualTo(3));
  });

  testWidgets('player cone jump action creates a cone and jump route', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);
    String? savedLayout;

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '콘 넘기',
          initialLayoutJson: const TrainingMethodLayout(
            pages: <TrainingMethodPage>[
              TrainingMethodPage(
                name: 'Board',
                items: <TrainingMethodItem>[
                  TrainingMethodItem(
                    id: 'player-1',
                    type: 'player',
                    x: 0.28,
                    y: 0.54,
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
    await _tapVisibleOutlinedButton(tester, '콘 넘기');
    expect(find.text('콘 넘기 대상이나 공간을 누르세요.'), findsOneWidget);
    await _tapBoardRelative(tester, boardFinder, const Offset(0.60, 0.44));

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final page = saved.pages.single;
    final cone = page.items.singleWhere((item) => item.type == 'cone');
    final route = page.routes.single;

    expect(cone.x, closeTo(0.60, 0.02));
    expect(cone.y, closeTo(0.44, 0.02));
    expect(route.kind, TrainingMethodRouteKind.player);
    expect(route.linkedItemId, 'player-1');
    expect(route.points, hasLength(4));
    expect(route.points[2].x, closeTo(cone.x, 0.001));
    expect(route.points[2].y, closeTo(cone.y, 0.001));
  });

  testWidgets('player hurdle jump action creates a hurdle and jump route', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);
    String? savedLayout;

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '뜀틀 넘기',
          initialLayoutJson: const TrainingMethodLayout(
            pages: <TrainingMethodPage>[
              TrainingMethodPage(
                name: 'Board',
                items: <TrainingMethodItem>[
                  TrainingMethodItem(
                    id: 'player-1',
                    type: 'player',
                    x: 0.28,
                    y: 0.54,
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
    await _tapVisibleOutlinedButton(tester, '뜀틀 넘기');
    expect(find.text('뜀틀 넘기 대상이나 공간을 누르세요.'), findsOneWidget);
    await _tapBoardRelative(tester, boardFinder, const Offset(0.60, 0.44));

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final page = saved.pages.single;
    final player = page.items.singleWhere((item) => item.type == 'player');
    final hurdle = page.items.singleWhere((item) => item.type == 'hurdle');
    final route = page.routes.single;

    expect(hurdle.x, closeTo(0.60, 0.02));
    expect(hurdle.y, closeTo(0.44, 0.02));
    expect(route.kind, TrainingMethodRouteKind.player);
    expect(route.linkedItemId, player.id);
    expect(route.points, hasLength(4));
    expect(route.points[2].x, closeTo(hurdle.x, 0.001));
    expect(route.points[2].y, closeTo(hurdle.y, 0.001));
    expect(
      Offset(
        route.points.last.x - hurdle.x,
        route.points.last.y - hurdle.y,
      ).distance,
      greaterThan(0.08),
    );
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
    final ballRoutes = saved.pages.single.routes
        .where((route) => route.kind == TrainingMethodRouteKind.ball)
        .toList(growable: false);

    expect(playerRoute.stageIndex, 1);
    expect(ballRoutes, hasLength(2));
    expect(ballRoutes.map((route) => route.linkedItemId).toSet(), {'ball-1'});
    expect(ballRoutes.map((route) => route.stageIndex).toSet(), {1});
  });

  testWidgets('single selected route only shows its actual stage', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '단일 단계',
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
                ],
                routes: <TrainingMethodRoute>[
                  TrainingMethodRoute(
                    id: 'route-player-1',
                    kind: TrainingMethodRouteKind.player,
                    linkedItemId: 'player-1',
                    points: <TrainingMethodPoint>[
                      TrainingMethodPoint(x: 0.22, y: 0.52),
                      TrainingMethodPoint(x: 0.44, y: 0.44),
                    ],
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
    await tester.tap(
      find.descendant(of: boardFinder, matching: find.byIcon(Icons.person)),
    );
    await tester.pumpAndSettle();

    expect(find.text('1단계'), findsOneWidget);
    expect(find.text('2단계'), findsNothing);
    expect(find.text('3단계'), findsNothing);
  });

  testWidgets('selected route can be extended from the end', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);
    String? savedLayout;

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '이동선 연장',
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
                ],
                routes: <TrainingMethodRoute>[
                  TrainingMethodRoute(
                    id: 'route-player-1',
                    kind: TrainingMethodRouteKind.player,
                    linkedItemId: 'player-1',
                    points: <TrainingMethodPoint>[
                      TrainingMethodPoint(x: 0.22, y: 0.52),
                      TrainingMethodPoint(x: 0.44, y: 0.44),
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
    await _tapVisibleOutlinedButton(tester, '끝에 이어 그리기');
    await _tapBoardRelative(tester, boardFinder, const Offset(0.66, 0.36));
    await _tapVisibleOutlinedButton(tester, '이동선 완료');

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final route = saved.pages.single.routes.single;
    expect(route.points, hasLength(3));
    expect(route.points.first.x, closeTo(0.22, 0.001));
    expect(route.points.first.y, closeTo(0.52, 0.001));
    expect(route.points[1].x, closeTo(0.44, 0.001));
    expect(route.points[1].y, closeTo(0.44, 0.001));
    expect(route.points.last.x, closeTo(0.66, 0.02));
    expect(route.points.last.y, closeTo(0.36, 0.02));
  });

  testWidgets('dragging a route end extends the route directly', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);
    String? savedLayout;

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '끝점 드래그',
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
                ],
                routes: <TrainingMethodRoute>[
                  TrainingMethodRoute(
                    id: 'route-player-1',
                    kind: TrainingMethodRouteKind.player,
                    linkedItemId: 'player-1',
                    points: <TrainingMethodPoint>[
                      TrainingMethodPoint(x: 0.22, y: 0.52),
                      TrainingMethodPoint(x: 0.44, y: 0.44),
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
    await _dragBoardRelative(
      tester,
      boardFinder,
      const Offset(0.44, 0.44),
      const Offset(0.66, 0.36),
    );

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final route = saved.pages.single.routes.single;
    expect(route.points, hasLength(3));
    expect(route.points.first.x, closeTo(0.22, 0.001));
    expect(route.points.first.y, closeTo(0.52, 0.001));
    expect(route.points[1].x, closeTo(0.44, 0.001));
    expect(route.points[1].y, closeTo(0.44, 0.001));
    expect(route.points.last.x, closeTo(0.66, 0.02));
    expect(route.points.last.y, closeTo(0.36, 0.02));
  });

  testWidgets('selected route direction can be reversed', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);
    String? savedLayout;

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '방향 전환',
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
                ],
                routes: <TrainingMethodRoute>[
                  TrainingMethodRoute(
                    id: 'route-player-1',
                    kind: TrainingMethodRouteKind.player,
                    linkedItemId: 'player-1',
                    points: <TrainingMethodPoint>[
                      TrainingMethodPoint(x: 0.22, y: 0.52),
                      TrainingMethodPoint(x: 0.44, y: 0.44),
                      TrainingMethodPoint(x: 0.66, y: 0.36),
                    ],
                    segmentDurationsMs: <int>[300, 700],
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
    await _tapVisibleOutlinedButton(tester, '방향 뒤집기');

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final route = saved.pages.single.routes.single;
    expect(route.points.first.x, closeTo(0.66, 0.001));
    expect(route.points.first.y, closeTo(0.36, 0.001));
    expect(route.points.last.x, closeTo(0.22, 0.001));
    expect(route.points.last.y, closeTo(0.52, 0.001));
    expect(route.segmentDurationsMs, [700, 300]);
  });

  testWidgets('player can dribble then shoot from the dribble end', (
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
                    id: 'player-1',
                    type: 'player',
                    x: 0.30,
                    y: 0.54,
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
        matching: find.byIcon(Icons.person),
      ),
    );
    await tester.pumpAndSettle();
    await _tapVisibleOutlinedButton(tester, '드리블');
    await _tapBoardRelative(tester, boardFinder, const Offset(0.62, 0.42));
    await _tapVisibleOutlinedButton(tester, '슈팅');
    await _tapBoardRelative(tester, boardFinder, const Offset(0.84, 0.34));

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final page = saved.pages.single;
    expect(page.items.where((item) => item.type == 'ball'), hasLength(1));
    final playerRoute = page.routes.singleWhere(
      (route) => route.kind == TrainingMethodRouteKind.player,
    );
    final ballRoutes = page.routes
        .where((route) => route.kind == TrainingMethodRouteKind.ball)
        .toList(growable: false);
    final dribbleRoute = ballRoutes.singleWhere(
      (route) => route.stageIndex == playerRoute.stageIndex,
    );
    final shotRoute = ballRoutes.singleWhere(
      (route) => route.stageIndex != playerRoute.stageIndex,
    );
    final playerEnd = Offset(
      playerRoute.points.last.x,
      playerRoute.points.last.y,
    );
    final shotStart =
        Offset(shotRoute.points.first.x, shotRoute.points.first.y);

    expect(ballRoutes.map((route) => route.linkedItemId).toSet().length, 1);
    expect(playerRoute.linkedItemId, 'player-1');
    expect(playerRoute.points.length, greaterThanOrEqualTo(3));
    expect(dribbleRoute.stageIndex, 1);
    expect(shotRoute.stageIndex, 2);
    expect(playerRoute.points.last.x, closeTo(0.62, 0.02));
    expect(playerRoute.points.last.y, closeTo(0.42, 0.02));
    expect(dribbleRoute.points.last.x, closeTo(0.62, 0.02));
    expect(dribbleRoute.points.last.y, closeTo(0.42, 0.02));
    expect((shotStart - playerEnd).distance, closeTo(0.07, 0.02));
    expect(shotRoute.points.last.x, closeTo(0.84, 0.02));
    expect(shotRoute.points.last.y, closeTo(0.34, 0.02));
  });

  testWidgets('same player can build pass dribble shot as three stages', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);
    String? savedLayout;

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '3단계 공격',
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
                    id: 'ball-1',
                    type: 'ball',
                    x: 0.29,
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
      find.descendant(of: boardFinder, matching: find.byIcon(Icons.person)),
    );
    await tester.pumpAndSettle();
    await _tapVisibleOutlinedButton(tester, '패스');
    await _tapBoardRelative(tester, boardFinder, const Offset(0.44, 0.50));
    await _tapVisibleOutlinedButton(tester, '드리블');
    await _tapBoardRelative(tester, boardFinder, const Offset(0.62, 0.42));
    await _tapVisibleOutlinedButton(tester, '슈팅');
    await _tapBoardRelative(tester, boardFinder, const Offset(0.84, 0.34));

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final page = saved.pages.single;
    final ballStages = page.routes
        .where((route) => route.kind == TrainingMethodRouteKind.ball)
        .map((route) => route.stageIndex)
        .toList(growable: false)
      ..sort();
    final playerRoute = page.routes.singleWhere(
      (route) => route.kind == TrainingMethodRouteKind.player,
    );

    expect(page.items.where((item) => item.type == 'ball'), hasLength(1));
    expect(
        page.routes
            .where((route) => route.kind == TrainingMethodRouteKind.ball)
            .map((route) => route.linkedItemId)
            .toSet(),
        {'ball-1'});
    expect(ballStages, [1, 2, 3]);
    expect(playerRoute.stageIndex, 2);
    expect(playerRoute.points.last.x, closeTo(0.62, 0.02));
    expect(playerRoute.points.last.y, closeTo(0.42, 0.02));
  });

  testWidgets('received pass auto advances stages after reselecting player', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);
    String? savedLayout;

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '수신 후 3단계',
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
                    x: 0.58,
                    y: 0.46,
                    colorValue: 0xFF1E88E5,
                  ),
                  TrainingMethodItem(
                    id: 'ball-1',
                    type: 'ball',
                    x: 0.29,
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
      find
          .descendant(of: boardFinder, matching: find.byIcon(Icons.person))
          .first,
    );
    await tester.pumpAndSettle();
    await _tapVisibleOutlinedButton(tester, '패스');
    await _tapBoardRelativeThroughWidgets(
      tester,
      boardFinder,
      const Offset(0.58, 0.46),
    );
    await _tapBoardRelativeThroughWidgets(
      tester,
      boardFinder,
      const Offset(0.58, 0.46),
    );
    await _tapVisibleOutlinedButton(tester, '드리블');
    await _tapBoardRelative(tester, boardFinder, const Offset(0.72, 0.38));
    await _tapBoardRelativeThroughWidgets(
      tester,
      boardFinder,
      const Offset(0.58, 0.46),
    );
    await _tapVisibleOutlinedButton(tester, '슈팅');
    await _tapBoardRelative(tester, boardFinder, const Offset(0.88, 0.34));

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final page = saved.pages.single;
    final ballRoutes = page.routes
        .where((route) => route.kind == TrainingMethodRouteKind.ball)
        .toList(growable: false);
    final ballStages = ballRoutes
        .map((route) => route.stageIndex)
        .toList(growable: false)
      ..sort();
    final playerRoute = page.routes.singleWhere(
      (route) => route.kind == TrainingMethodRouteKind.player,
    );

    expect(ballRoutes.map((route) => route.linkedItemId).toSet(), {'ball-1'});
    expect(ballStages, [1, 2, 3]);
    expect(playerRoute.linkedItemId, 'player-2');
    expect(playerRoute.stageIndex, 2);
  });

  testWidgets('two players can exchange passes as smart stages', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);
    String? savedLayout;

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '패스 왕복',
          initialLayoutJson: const TrainingMethodLayout(
            pages: <TrainingMethodPage>[
              TrainingMethodPage(
                name: 'Board',
                items: <TrainingMethodItem>[
                  TrainingMethodItem(
                    id: 'player-1',
                    type: 'player',
                    x: 0.24,
                    y: 0.52,
                  ),
                  TrainingMethodItem(
                    id: 'player-2',
                    type: 'player',
                    x: 0.66,
                    y: 0.42,
                    colorValue: 0xFF1E88E5,
                  ),
                  TrainingMethodItem(
                    id: 'ball-1',
                    type: 'ball',
                    x: 0.31,
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
      find
          .descendant(of: boardFinder, matching: find.byIcon(Icons.person))
          .first,
    );
    await tester.pumpAndSettle();
    await _tapVisibleOutlinedButton(tester, '패스');
    await _tapBoardRelativeThroughWidgets(
      tester,
      boardFinder,
      const Offset(0.66, 0.42),
    );
    await _tapVisibleOutlinedButton(tester, '패스');
    await _tapBoardRelativeThroughWidgets(
      tester,
      boardFinder,
      const Offset(0.24, 0.52),
    );

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final ballRoutes = saved.pages.single.routes
        .where((route) => route.kind == TrainingMethodRouteKind.ball)
        .toList(growable: false);

    expect(ballRoutes, hasLength(2));
    expect(ballRoutes.map((route) => route.linkedItemId).toSet(), {'ball-1'});
    expect(ballRoutes.map((route) => route.stageIndex), [1, 2]);
    expect(ballRoutes.last.points.last.x, closeTo(0.24, 0.02));
    expect(ballRoutes.last.points.last.y, closeTo(0.52, 0.02));
  });

  testWidgets('received pass changes the player ball for next actions', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);
    String? savedLayout;

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '수신 공 전환',
          initialLayoutJson: const TrainingMethodLayout(
            pages: <TrainingMethodPage>[
              TrainingMethodPage(
                name: 'Board',
                items: <TrainingMethodItem>[
                  TrainingMethodItem(
                    id: 'player-1',
                    type: 'player',
                    x: 0.24,
                    y: 0.52,
                  ),
                  TrainingMethodItem(
                    id: 'player-2',
                    type: 'player',
                    x: 0.66,
                    y: 0.42,
                    colorValue: 0xFF1E88E5,
                  ),
                  TrainingMethodItem(
                    id: 'ball-1',
                    type: 'ball',
                    x: 0.31,
                    y: 0.52,
                    colorValue: 0xFFFFCA28,
                  ),
                  TrainingMethodItem(
                    id: 'ball-2',
                    type: 'ball',
                    x: 0.72,
                    y: 0.42,
                    colorValue: 0xFF90CAF9,
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
    await _tapVisibleOutlinedButton(tester, '패스');
    await _tapBoardRelativeThroughWidgets(
      tester,
      boardFinder,
      const Offset(0.66, 0.42),
    );
    await _tapVisibleOutlinedButton(tester, '슈팅');
    await _tapBoardRelative(tester, boardFinder, const Offset(0.86, 0.34));

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final page = saved.pages.single;
    final ballRoutes = page.routes
        .where((route) => route.kind == TrainingMethodRouteKind.ball)
        .toList(growable: false);
    final shotRoute = ballRoutes.singleWhere(
      (route) => route.actorItemId == 'player-2',
    );

    expect(page.items.where((item) => item.type == 'ball'), hasLength(2));
    expect(ballRoutes, hasLength(2));
    expect(ballRoutes.map((route) => route.linkedItemId).toSet(), {'ball-1'});
    expect(shotRoute.stageIndex, 2);
    expect(shotRoute.points.first.x, closeTo(0.66, 0.02));
    expect(shotRoute.points.first.y, closeTo(0.42, 0.02));
    expect(shotRoute.points.last.x, closeTo(0.86, 0.02));
    expect(shotRoute.points.last.y, closeTo(0.34, 0.02));
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

  testWidgets('pass then move to a player keeps the passer move connected', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);
    String? savedLayout;

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '패스 후 이동 연결',
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
                    x: 0.54,
                    y: 0.44,
                    colorValue: 0xFF1E88E5,
                  ),
                  TrainingMethodItem(
                    id: 'ball-1',
                    type: 'ball',
                    x: 0.29,
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
      find
          .descendant(of: boardFinder, matching: find.byIcon(Icons.person))
          .first,
    );
    await tester.pumpAndSettle();
    await _tapVisibleOutlinedButton(tester, '패스 후 이동');
    await _tapBoardRelativeThroughWidgets(
      tester,
      boardFinder,
      const Offset(0.54, 0.44),
    );

    expect(find.text('이동 대상이나 공간을 누르세요.'), findsOneWidget);
    await _tapBoardRelative(tester, boardFinder, const Offset(0.72, 0.36));

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
    expect(ballRoute.points.last.x, closeTo(0.54, 0.001));
    expect(ballRoute.points.last.y, closeTo(0.44, 0.001));
    expect(playerRoute.linkedItemId, 'player-1');
    expect(playerRoute.stageIndex, 2);
    expect(playerRoute.points.first.x, closeTo(0.22, 0.001));
    expect(playerRoute.points.first.y, closeTo(0.52, 0.001));
    expect(playerRoute.points.last.x, closeTo(0.72, 0.02));
    expect(playerRoute.points.last.y, closeTo(0.36, 0.02));
  });

  testWidgets('pass then cone turn then shot stays connected', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);
    String? savedLayout;

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '패스 콘 슛 연결',
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
                    x: 0.54,
                    y: 0.44,
                    colorValue: 0xFF1E88E5,
                  ),
                  TrainingMethodItem(
                    id: 'ball-1',
                    type: 'ball',
                    x: 0.29,
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
      find
          .descendant(of: boardFinder, matching: find.byIcon(Icons.person))
          .first,
    );
    await tester.pumpAndSettle();
    await _tapVisibleOutlinedButton(tester, '패스 후 이동');
    await _tapBoardRelativeThroughWidgets(
      tester,
      boardFinder,
      const Offset(0.54, 0.44),
    );

    await _tapVisibleOutlinedButton(tester, '콘 돌기');
    await _tapBoardRelative(tester, boardFinder, const Offset(0.64, 0.34));
    await _tapVisibleOutlinedButton(tester, '슈팅');
    await _tapBoardRelative(tester, boardFinder, const Offset(0.86, 0.42));

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final page = saved.pages.single;
    final ballRoutes = page.routes
        .where((route) => route.kind == TrainingMethodRouteKind.ball)
        .toList(growable: false);
    final passRoute = ballRoutes.singleWhere(
      (route) => route.stageIndex == 1,
    );
    final shotRoute = ballRoutes.singleWhere(
      (route) => route.stageIndex == 3,
    );
    final playerRoute = page.routes.singleWhere(
      (route) => route.kind == TrainingMethodRouteKind.player,
    );
    final playerEnd = Offset(
      playerRoute.points.last.x,
      playerRoute.points.last.y,
    );
    final shotStart =
        Offset(shotRoute.points.first.x, shotRoute.points.first.y);

    expect(page.items.where((item) => item.type == 'cone'), hasLength(1));
    expect(page.items.where((item) => item.type == 'ball'), hasLength(1));
    expect(ballRoutes.map((route) => route.linkedItemId).toSet(), {'ball-1'});
    expect(passRoute.stageIndex, 1);
    expect(playerRoute.linkedItemId, 'player-1');
    expect(playerRoute.stageIndex, 2);
    expect(playerRoute.points.length, greaterThan(6));
    expect(shotRoute.stageIndex, 3);
    expect((shotStart - playerEnd).distance, closeTo(0.07, 0.02));
    expect(shotRoute.points.last.x, closeTo(0.86, 0.02));
    expect(shotRoute.points.last.y, closeTo(0.42, 0.02));
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
      find
          .descendant(
            of: boardFinder,
            matching: find.byIcon(Icons.person),
          )
          .first,
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

  testWidgets('pass action can target a cone spot directly', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);
    String? savedLayout;

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '지점 패스',
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
                    id: 'ball-1',
                    type: 'ball',
                    x: 0.29,
                    y: 0.52,
                    colorValue: 0xFFFFCA28,
                  ),
                  TrainingMethodItem(
                    id: 'cone-1',
                    type: 'cone',
                    x: 0.68,
                    y: 0.42,
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
    await _tapVisibleOutlinedButton(tester, '콘 1에 패스');

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final route = saved.pages.single.routes.single;
    expect(route.kind, TrainingMethodRouteKind.ball);
    expect(route.linkedItemId, 'ball-1');
    expect(route.points.last.x, closeTo(0.68, 0.001));
    expect(route.points.last.y, closeTo(0.42, 0.001));
  });

  testWidgets('pass to a player selects receiver for the next action stage', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);
    String? savedLayout;

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '연결 훈련',
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
                    x: 0.52,
                    y: 0.46,
                    colorValue: 0xFF1E88E5,
                  ),
                  TrainingMethodItem(
                    id: 'ball-1',
                    type: 'ball',
                    x: 0.29,
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
      find
          .descendant(of: boardFinder, matching: find.byIcon(Icons.person))
          .first,
    );
    await tester.pumpAndSettle();
    await _tapVisibleOutlinedButton(tester, '사람 2에게 패스');
    await _tapVisibleOutlinedButton(tester, '뜀틀 넘기');
    await _tapBoardRelative(tester, boardFinder, const Offset(0.72, 0.36));

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final page = saved.pages.single;
    final ballRoute = page.routes.singleWhere(
      (route) => route.kind == TrainingMethodRouteKind.ball,
    );
    final playerRoute = page.routes.singleWhere(
      (route) => route.kind == TrainingMethodRouteKind.player,
    );

    expect(page.items.where((item) => item.type == 'hurdle'), hasLength(1));
    expect(ballRoute.linkedItemId, 'ball-1');
    expect(ballRoute.stageIndex, 1);
    expect(playerRoute.linkedItemId, 'player-2');
    expect(playerRoute.stageIndex, 2);
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
                    id: 'player-1',
                    type: 'player',
                    x: 0.35,
                    y: 0.76,
                  ),
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
      find
          .descendant(
            of: boardFinder,
            matching: find.byIcon(Icons.person),
          )
          .first,
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

  testWidgets('moving a token hides its border and number badge', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '이동 표시',
          initialLayoutJson: const TrainingMethodLayout(
            pages: <TrainingMethodPage>[
              TrainingMethodPage(
                name: 'Board',
                items: <TrainingMethodItem>[
                  TrainingMethodItem(
                    id: 'player-1',
                    type: 'player',
                    x: 0.24,
                    y: 0.52,
                  ),
                  TrainingMethodItem(
                    id: 'ball-1',
                    type: 'ball',
                    x: 0.40,
                    y: 0.52,
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
    final playerIcon = find.descendant(
      of: boardFinder,
      matching: find.byIcon(Icons.person),
    );
    final boardNumbers = find.descendant(
      of: boardFinder,
      matching: find.text('1'),
    );

    expect(boardNumbers, findsNWidgets(2));
    expect(_tokenDecorationForIcon(tester, playerIcon).border, isNotNull);

    final detector = _itemGestureDetectorForIcon(tester, playerIcon);
    detector.onPanStart!(DragStartDetails());
    await tester.pump();
    detector.onPanUpdate!(
      DragUpdateDetails(
        delta: const Offset(28, -14),
        globalPosition: tester.getCenter(playerIcon) + const Offset(28, -14),
      ),
    );
    await tester.pump();

    expect(boardNumbers, findsOneWidget);
    expect(_tokenDecorationForIcon(tester, playerIcon).border, isNull);

    detector.onPanEnd!(DragEndDetails());
    await tester.pumpAndSettle();

    expect(boardNumbers, findsNWidgets(2));
    expect(_tokenDecorationForIcon(tester, playerIcon).border, isNotNull);
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

  testWidgets('dragging a ball moves the ball and its linked route', (
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

  testWidgets('selecting a player after a ball exposes player route tools', (
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
    await tester.tap(
      find.descendant(
        of: boardFinder,
        matching: find.byIcon(Icons.sports_soccer),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.widgetWithText(OutlinedButton, '패스 만들기'), findsNothing);

    await tester.tap(
      find.descendant(of: boardFinder, matching: find.byIcon(Icons.person)),
    );
    await tester.pumpAndSettle();

    expect(find.text('선수 액션'), findsOneWidget);
    await _tapVisibleOutlinedButton(tester, '이동 만들기');

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
    expect(
      find.byKey(const ValueKey('training-selected-color-button')),
      findsOneWidget,
    );
    expect(find.widgetWithText(OutlinedButton, '패스 만들기'), findsNothing);
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
    'selected ball cannot create a pass action route',
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
      expect(
        find.descendant(
            of: boardFinder, matching: find.byIcon(Icons.sports_soccer)),
        findsOneWidget,
      );
      expect(find.widgetWithText(OutlinedButton, '패스'), findsNothing);

      await tester.tap(find.widgetWithText(TextButton, '저장'));
      await tester.pumpAndSettle();

      final saved = TrainingMethodLayout.decode(savedLayout ?? '');
      final page = saved.pages.single;
      expect(page.items.where((item) => item.type == 'ball'), hasLength(1));
      expect(page.items.where((item) => item.type == 'player'), isEmpty);
      expect(page.routes, isEmpty);
    },
  );

  testWidgets('selected item color picker is compact until opened', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);
    String? savedLayout;

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '색상 패널',
          initialLayoutJson: '',
          onSaved: (value) => savedLayout = value,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, '사람'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('training-selected-color-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('training-selected-color-picker')),
      findsNothing,
    );

    await tester.tap(
      find.byKey(const ValueKey('training-selected-color-button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('training-selected-color-picker')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(
        const ValueKey('training-selected-color-option-ff1e88e5'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('training-selected-color-picker')),
      findsNothing,
    );

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final player = saved.pages.single.items.singleWhere(
      (item) => item.type == 'player',
    );

    expect(player.colorValue, 0xFF1E88E5);
  });

  testWidgets(
    'selected player shooting action can set the ball route stage',
    (WidgetTester tester) async {
      _setLandscapeSurface(tester);
      String? savedLayout;

      await tester.pumpWidget(
        _buildApp(
          TrainingMethodBoardScreen(
            boardTitle: '슈팅 훈련',
            initialLayoutJson: const TrainingMethodLayout(
              pages: <TrainingMethodPage>[
                TrainingMethodPage(
                  name: 'Board',
                  items: <TrainingMethodItem>[
                    TrainingMethodItem(
                      id: 'player-1',
                      type: 'player',
                      x: 0.28,
                      y: 0.58,
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

      await _tapVisibleOutlinedButton(tester, '슈팅');
      await _tapBoardRelative(tester, boardFinder, const Offset(0.82, 0.34));

      expect(find.text('동작 단계'), findsOneWidget);
      await _tapVisibleOutlinedButton(tester, '다음 단계');

      await tester.tap(find.widgetWithText(TextButton, '저장'));
      await tester.pumpAndSettle();

      final saved = TrainingMethodLayout.decode(savedLayout ?? '');
      final page = saved.pages.single;
      final ballRoute = page.routes.singleWhere(
        (route) => route.kind == TrainingMethodRouteKind.ball,
      );

      expect(page.items.where((item) => item.type == 'ball'), hasLength(1));
      expect(ballRoute.stageIndex, 2);
    },
  );

  testWidgets('route actions live only inside selected player panels', (
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
    expect(find.text('공 액션'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, '패스 만들기'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, '패스'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, '드리블'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, '슈팅'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, '크로스'), findsNothing);
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

  testWidgets('orientation button waits for a true landscape surface', (
    WidgetTester tester,
  ) async {
    _setPortraitSurface(tester);
    final platformCalls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        platformCalls.add(call);
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    await tester.pumpWidget(
      _buildApp(
        const TrainingMethodBoardScreen(
          boardTitle: '가로 모드',
          initialLayoutJson: '',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('training-sketch-orientation-button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('training-landscape-control-panel')),
      findsNothing,
    );
    final orientationCall = platformCalls.lastWhere(
      (call) => call.method == 'SystemChrome.setPreferredOrientations',
    );
    final arguments = '${orientationCall.arguments}';
    expect(arguments, contains('landscapeLeft'));
    expect(arguments, contains('landscapeRight'));

    tester.view.physicalSize = const Size(1000, 720);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('training-landscape-control-panel')),
      findsOneWidget,
    );
  });

  testWidgets('selected player can register the next action stage', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);
    String? savedLayout;

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '선수 단계',
          initialLayoutJson: const TrainingMethodLayout(
            pages: <TrainingMethodPage>[
              TrainingMethodPage(
                name: 'Board',
                items: <TrainingMethodItem>[
                  TrainingMethodItem(
                    id: 'player-1',
                    type: 'player',
                    x: 0.24,
                    y: 0.58,
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

    expect(find.text('선수 단계'), findsWidgets);
    await _tapVisibleOutlinedButton(tester, '1단계 등록');
    await _tapVisibleOutlinedButton(tester, '패스');
    await _tapBoardRelative(tester, boardFinder, const Offset(0.48, 0.42));

    expect(find.text('1단계 · 동작 1개'), findsOneWidget);
    await _tapVisibleOutlinedButton(tester, '2단계 등록');
    await _tapVisibleOutlinedButton(tester, '슈팅');
    await _tapBoardRelative(tester, boardFinder, const Offset(0.82, 0.34));

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final playerStages = saved.pages.single.routes
        .where((route) => route.actorItemId == 'player-1')
        .map((route) => route.stageIndex)
        .toList(growable: false);

    expect(playerStages, containsAll(<int>[1, 2]));
  });

  testWidgets('sketch PDF export action is visible in the top bar', (
    WidgetTester tester,
  ) async {
    _setPortraitSurface(tester);

    await tester.pumpWidget(
      _buildApp(
        const TrainingMethodBoardScreen(
          boardTitle: 'PDF 스케치',
          initialLayoutJson: '',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('training-sketch-pdf-button')),
      findsOneWidget,
    );
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
    await _openMoveRouteToolForIcon(
      tester,
      find.descendant(
        of: boardFinder,
        matching: find.byIcon(Icons.person),
      ),
    );
    expect(
      find.byKey(const ValueKey('training-route-target-player-player-1')),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(Icons.play_circle_outline).first);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('training-route-target-player-player-1')),
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

BoxDecoration _tokenDecorationForIcon(WidgetTester tester, Finder iconFinder) {
  final containers = find.ancestor(
    of: iconFinder,
    matching: find.byType(AnimatedContainer),
  );
  for (final element in containers.evaluate()) {
    final widget = element.widget as AnimatedContainer;
    final decoration = widget.decoration;
    if (decoration is BoxDecoration && decoration.shape == BoxShape.circle) {
      return decoration;
    }
  }
  throw StateError('Token decoration was not found.');
}

GestureDetector _itemGestureDetectorForIcon(
  WidgetTester tester,
  Finder iconFinder,
) {
  final detectors = find.ancestor(
    of: iconFinder,
    matching: find.byType(GestureDetector),
  );
  for (final element in detectors.evaluate()) {
    final widget = element.widget as GestureDetector;
    if (widget.onTap != null &&
        widget.onPanStart != null &&
        widget.onPanUpdate != null &&
        widget.onPanEnd != null) {
      return widget;
    }
  }
  throw StateError('Item gesture detector was not found.');
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

Future<void> _tapBoardRelativeThroughWidgets(
  WidgetTester tester,
  Finder boardFinder,
  Offset relativePosition,
) async {
  final boardTopLeft = tester.getTopLeft(boardFinder);
  final size = tester.getSize(boardFinder);
  final localPosition = Offset(
    size.width * relativePosition.dx,
    size.height * relativePosition.dy,
  );
  await tester.tapAt(boardTopLeft + localPosition);
  await tester.pumpAndSettle();
}

Future<void> _dragBoardRelative(
  WidgetTester tester,
  Finder boardFinder,
  Offset relativeStart,
  Offset relativeEnd,
) async {
  final detector = tester.widget<GestureDetector>(boardFinder);
  final size = tester.getSize(boardFinder);
  final start =
      Offset(size.width * relativeStart.dx, size.height * relativeStart.dy);
  final end = Offset(size.width * relativeEnd.dx, size.height * relativeEnd.dy);
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
