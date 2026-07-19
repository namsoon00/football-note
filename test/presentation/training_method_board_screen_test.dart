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

  test('training sketch routes preserve pass target ownership', () {
    final encoded = const TrainingMethodLayout(
      pages: <TrainingMethodPage>[
        TrainingMethodPage(
          name: 'Targeted action',
          items: <TrainingMethodItem>[],
          routes: <TrainingMethodRoute>[
            TrainingMethodRoute(
              id: 'targeted-ball',
              kind: TrainingMethodRouteKind.ball,
              linkedItemId: 'ball-1',
              actorItemId: 'player-1',
              targetItemId: 'player-2',
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

    expect(decoded.pages.single.routes.single.targetItemId, 'player-2');
  });

  testWidgets('route stages can be changed with compact stage chips', (
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
    await tester.tap(
      find
          .descendant(of: boardFinder, matching: find.byIcon(Icons.person))
          .first,
    );
    await tester.pumpAndSettle();
    await _tapRouteStageChip(tester, 2);

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final routes = saved.pages.single.routes;
    expect(routes, hasLength(4));
    expect(_samePoint(routes[0].points[0], routes[0].points[1]), isFalse);
    expect(_samePoint(routes[2].points[0], routes[2].points[1]), isFalse);
    expect(_samePoint(routes[3].points[0], routes[3].points[1]), isFalse);
    expect(routes.map((route) => route.stageIndex), [2, 1, 1, 1]);
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
    expect(find.widgetWithText(OutlinedButton, '공'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, '사다리'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, '낮은 뜀틀'), findsNothing);

    await pumpSport(SportCatalog.baseballId);
    expect(find.widgetWithText(OutlinedButton, '공'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, '베이스'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '목표'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '골대'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, '사다리'), findsNothing);

    await pumpSport(SportCatalog.basketballId);
    expect(find.widgetWithText(OutlinedButton, '공'), findsNothing);
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

    expect(
      find.byKey(const ValueKey('training-player-next-action-item-1')),
      findsOneWidget,
    );
    expect(find.widgetWithText(OutlinedButton, '사람'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '콘'), findsOneWidget);
    expect(find.text('이동'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '공'), findsNothing);
    expect(
      find.byKey(const ValueKey('training-add-element-menu')),
      findsNothing,
    );

    final boardFinder = find.byKey(const ValueKey('training-board-canvas'));
    await _tapVisibleOutlinedButton(tester, '이동');
    expect(find.text('이동 대상이나 공간을 누르세요.'), findsOneWidget);
    await _tapBoardRelative(tester, boardFinder, const Offset(0.72, 0.38));
    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final item = saved.pages.single.items.single;
    final route = saved.pages.single.routes.singleWhere(
      (route) => route.kind == TrainingMethodRouteKind.player,
    );
    expect(item.type, 'player');
    expect(route.kind, TrainingMethodRouteKind.player);
    expect(route.linkedItemId, item.id);
    expect(route.points.first.x, closeTo(item.x, 0.001));
    expect(route.points.first.y, closeTo(item.y, 0.001));
    expect(route.points.last.x, closeTo(0.72, 0.02));
    expect(route.points.last.y, closeTo(0.38, 0.02));
  });

  testWidgets('adding a player to an existing sketch continues item ids', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);
    String? savedLayout;

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '기존 스케치 수정',
          initialLayoutJson: const TrainingMethodLayout(
            pages: <TrainingMethodPage>[
              TrainingMethodPage(
                name: 'Board',
                items: <TrainingMethodItem>[
                  TrainingMethodItem(
                    id: 'item-1',
                    type: 'player',
                    x: 0.22,
                    y: 0.52,
                  ),
                  TrainingMethodItem(
                    id: 'item-2',
                    type: 'player',
                    x: 0.48,
                    y: 0.42,
                    colorValue: 0xFF1E88E5,
                  ),
                ],
                routes: <TrainingMethodRoute>[
                  TrainingMethodRoute(
                    id: 'route-3',
                    kind: TrainingMethodRouteKind.player,
                    linkedItemId: 'item-1',
                    stageIndex: 1,
                    points: <TrainingMethodPoint>[
                      TrainingMethodPoint(x: 0.22, y: 0.52),
                      TrainingMethodPoint(x: 0.34, y: 0.48),
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

    await tester.tap(find.widgetWithText(OutlinedButton, '사람'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('training-player-next-action-item-4')),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final itemIds =
        saved.pages.single.items.map((item) => item.id).toList(growable: false);

    expect(itemIds, contains('item-4'));
    expect(itemIds.toSet(), hasLength(itemIds.length));
    expect(
      saved.pages.single.items.where((item) => item.type == 'player'),
      hasLength(3),
    );
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
      find
          .descendant(of: boardFinder, matching: find.byIcon(Icons.person))
          .first,
    );
    await tester.pumpAndSettle();
    await _tapVisibleOutlinedButton(tester, '이동');
    await _tapBoardRelative(tester, boardFinder, const Offset(0.48, 0.44));
    await _tapVisibleOutlinedButton(tester, '이동');
    await _tapBoardRelative(tester, boardFinder, const Offset(0.72, 0.38));

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final route = saved.pages.single.routes.singleWhere(
      (route) => route.kind == TrainingMethodRouteKind.player,
    );

    expect(route.kind, TrainingMethodRouteKind.player);
    expect(route.linkedItemId, 'player-1');
    expect(route.points, hasLength(3));
    expect(route.points[1].x, closeTo(0.48, 0.02));
    expect(route.points[1].y, closeTo(0.44, 0.02));
    expect(route.points.last.x, closeTo(0.72, 0.02));
    expect(route.points.last.y, closeTo(0.38, 0.02));
  });

  testWidgets('ball is not a direct sketch tool', (
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

    expect(find.widgetWithText(OutlinedButton, '공'), findsNothing);
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
                  TrainingMethodItem(
                    id: 'player-2',
                    type: 'player',
                    x: 0.70,
                    y: 0.44,
                    colorValue: 0xFF1E88E5,
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
    expect(
      find.byKey(const ValueKey('training-player-next-action-player-1')),
      findsOneWidget,
    );
    expect(find.text('선수 액션'), findsNothing);
    await _tapVisibleOutlinedButton(tester, '패스');
    await _tapBoardRelative(tester, boardFinder, const Offset(0.70, 0.44));

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final page = saved.pages.single;
    final player = page.items.singleWhere((item) => item.id == 'player-1');
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
      find
          .descendant(of: boardFinder, matching: find.byIcon(Icons.person))
          .first,
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

  testWidgets('created next action can be undone from snackbar', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);
    String? savedLayout;

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '되돌리기',
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
      find
          .descendant(of: boardFinder, matching: find.byIcon(Icons.person))
          .first,
    );
    await tester.pumpAndSettle();
    await _tapVisibleOutlinedButton(tester, '이동');
    await _tapBoardRelative(tester, boardFinder, const Offset(0.62, 0.42));

    expect(find.text('동작을 추가했어요.'), findsOneWidget);
    await tester.tap(find.text('되돌리기'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    expect(saved.pages.single.routes, isEmpty);
    expect(
      find.byKey(const ValueKey('training-player-next-action-player-1')),
      findsOneWidget,
    );
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
                  TrainingMethodItem(
                    id: 'player-2',
                    type: 'player',
                    x: 0.74,
                    y: 0.38,
                    colorValue: 0xFF1E88E5,
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

  testWidgets('passer cannot dribble after passing possession away', (
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

    expect(find.widgetWithText(OutlinedButton, '드리블'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, '슈팅'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, '사람 2에게 패스'), findsNothing);

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

    expect(ballRoutes, hasLength(1));
    expect(ballRoutes.single.linkedItemId, 'ball-1');
    expect(ballRoutes.single.targetItemId, 'player-2');
    expect(playerRoute.stageIndex, 1);
    expect(playerRoute.points.length, greaterThanOrEqualTo(3));
    expect(playerRoute.points.last.x, closeTo(0.64, 0.02));
    expect(playerRoute.points.last.y, closeTo(0.38, 0.02));
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
      find
          .descendant(of: boardFinder, matching: find.byIcon(Icons.person))
          .first,
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

  testWidgets('cone turn carries the ball when the player has possession', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);
    String? savedLayout;

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '공 소유 콘 돌기',
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
                  TrainingMethodItem(
                    id: 'ball-1',
                    type: 'ball',
                    x: 0.35,
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
      find
          .descendant(of: boardFinder, matching: find.byIcon(Icons.person))
          .first,
    );
    await tester.pumpAndSettle();
    await _tapVisibleOutlinedButton(tester, '드리블');
    await _tapBoardRelative(tester, boardFinder, const Offset(0.44, 0.50));
    await _tapVisibleOutlinedButton(tester, '콘 돌기');
    await _tapBoardRelative(tester, boardFinder, const Offset(0.58, 0.43));

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final page = saved.pages.single;
    final cone = page.items.singleWhere((item) => item.type == 'cone');
    final playerRoute = page.routes.singleWhere(
      (route) => route.kind == TrainingMethodRouteKind.player,
    );
    final ballRoutes = page.routes
        .where((route) => route.kind == TrainingMethodRouteKind.ball)
        .toList(growable: false);
    final coneCarryRoute = ballRoutes.singleWhere(
      (route) => route.targetItemId == 'player-1',
    );
    final ballNearConePointCount = coneCarryRoute.points.where((point) {
      return Offset(point.x - cone.x, point.y - cone.y).distance < 0.12;
    }).length;

    expect(ballRoutes, hasLength(2));
    expect(ballRoutes.map((route) => route.linkedItemId).toSet(), {'ball-1'});
    expect(coneCarryRoute.actorItemId, 'player-1');
    expect(coneCarryRoute.stageIndex, playerRoute.stageIndex);
    expect(coneCarryRoute.points.length, greaterThanOrEqualTo(5));
    expect(ballNearConePointCount, greaterThanOrEqualTo(3));
    expect(
        playerRoute.points.last.x, closeTo(coneCarryRoute.points.last.x, 0.12));
    expect(
        playerRoute.points.last.y, closeTo(coneCarryRoute.points.last.y, 0.12));
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
                  TrainingMethodItem(
                    id: 'cone-1',
                    type: 'cone',
                    x: 0.60,
                    y: 0.44,
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
    await _tapBoardRelativeThroughWidgets(
      tester,
      boardFinder,
      const Offset(0.28, 0.54),
    );
    await _tapVisibleFinder(
      tester,
      find.byKey(
        const ValueKey(
          'training-player-flow-prop-action-player-1-coneJump-cone-1',
        ),
      ),
    );

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

  testWidgets('dribble after an owned ball route advances to the next stage', (
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
                    actorItemId: 'player-1',
                    targetItemId: 'player-1',
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

    expect(playerRoute.stageIndex, 2);
    expect(ballRoutes, hasLength(2));
    expect(ballRoutes.map((route) => route.linkedItemId).toSet(), {'ball-1'});
    expect(ballRoutes.map((route) => route.stageIndex).toSet(), {1, 2});
  });

  testWidgets('single selected route offers the next editable stage', (
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
    expect(find.text('2단계'), findsOneWidget);
    expect(find.text('3단계'), findsNothing);
  });

  testWidgets('selected player stage controls hide advanced route edit buttons',
      (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);

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
        ),
      ),
    );
    await tester.pumpAndSettle();

    final boardFinder = find.byKey(const ValueKey('training-board-canvas'));
    await tester.tap(
      find.descendant(of: boardFinder, matching: find.byIcon(Icons.person)),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(OutlinedButton, '끝에 이어 그리기'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, '방향 뒤집기'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, '선택 이동선 다시 그리기'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, '단계 액션 삭제'), findsOneWidget);
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
    final route = saved.pages.single.routes.singleWhere(
      (route) => route.kind == TrainingMethodRouteKind.player,
    );
    expect(route.points, hasLength(3));
    expect(route.points.first.x, closeTo(0.22, 0.001));
    expect(route.points.first.y, closeTo(0.52, 0.001));
    expect(route.points[1].x, closeTo(0.44, 0.001));
    expect(route.points[1].y, closeTo(0.44, 0.001));
    expect(route.points.last.x, closeTo(0.66, 0.02));
    expect(route.points.last.y, closeTo(0.36, 0.02));
  });

  testWidgets('selected route can be removed from compact stage controls', (
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
    await _tapVisibleOutlinedButton(tester, '단계 액션 삭제');

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    expect(saved.pages.single.routes, isEmpty);
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

  testWidgets('player moves immediately after shooting starts', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);
    String? savedLayout;

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '슈팅 후 이동',
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
                  TrainingMethodItem(
                    id: 'ball-1',
                    type: 'ball',
                    x: 0.37,
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
        matching: find.byIcon(Icons.person),
      ),
    );
    await tester.pumpAndSettle();
    await _tapVisibleOutlinedButton(tester, '슈팅');
    await _tapBoardRelative(tester, boardFinder, const Offset(0.84, 0.34));
    await tester.tap(
      find.descendant(
        of: boardFinder,
        matching: find.byIcon(Icons.person),
      ),
    );
    await tester.pumpAndSettle();
    await _tapVisibleOutlinedButton(tester, '이동');
    await _tapBoardRelative(tester, boardFinder, const Offset(0.56, 0.42));

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final page = saved.pages.single;
    final shotRoute = page.routes.singleWhere(
      (route) => route.kind == TrainingMethodRouteKind.ball,
    );
    final playerRoute = page.routes.singleWhere(
      (route) => route.kind == TrainingMethodRouteKind.player,
    );

    expect(shotRoute.actorItemId, 'player-1');
    expect(shotRoute.targetItemId, isNull);
    expect(playerRoute.linkedItemId, 'player-1');
    expect(playerRoute.stageIndex, shotRoute.stageIndex);
    expect(playerRoute.points.last.x, closeTo(0.56, 0.02));
    expect(playerRoute.points.last.y, closeTo(0.42, 0.02));
  });

  testWidgets('receiving player can build pass dribble shot as three stages', (
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
                    id: 'player-2',
                    type: 'player',
                    x: 0.44,
                    y: 0.50,
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

  testWidgets('reselected player adds next action after their latest stage', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);
    String? savedLayout;

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '재선택 단계',
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
                    x: 0.58,
                    y: 0.46,
                    colorValue: 0xFFFFCA28,
                  ),
                ],
                routes: <TrainingMethodRoute>[
                  TrainingMethodRoute(
                    id: 'player-1-route',
                    kind: TrainingMethodRouteKind.player,
                    linkedItemId: 'player-1',
                    actorItemId: 'player-1',
                    stageIndex: 1,
                    points: <TrainingMethodPoint>[
                      TrainingMethodPoint(x: 0.22, y: 0.52),
                      TrainingMethodPoint(x: 0.34, y: 0.52),
                    ],
                  ),
                  TrainingMethodRoute(
                    id: 'ball-1-route',
                    kind: TrainingMethodRouteKind.ball,
                    linkedItemId: 'ball-1',
                    stageIndex: 2,
                    points: <TrainingMethodPoint>[
                      TrainingMethodPoint(x: 0.58, y: 0.46),
                      TrainingMethodPoint(x: 0.70, y: 0.46),
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
    final player1Icon = find.descendant(
      of: boardFinder,
      matching: find.byIcon(Icons.person),
    );
    final player1Detector = _itemGestureDetectorForIcon(tester, player1Icon);
    player1Detector.onTap!();
    await tester.pumpAndSettle();
    player1Detector.onTap!();
    await tester.pumpAndSettle();
    await _tapVisibleOutlinedButton(tester, '이동');
    expect(find.text('이동 대상이나 공간을 누르세요.'), findsOneWidget);
    await _tapBoardRelative(tester, boardFinder, const Offset(0.46, 0.36));

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final player1Routes = saved.pages.single.routes
        .where(
          (route) =>
              route.kind == TrainingMethodRouteKind.player &&
              route.linkedItemId == 'player-1',
        )
        .toList(growable: false);
    final player1Stages = player1Routes
        .map((route) => route.stageIndex)
        .toList(growable: false)
      ..sort();
    final nextPlayer1Route = player1Routes.singleWhere(
      (route) =>
          route.stageIndex == 2 &&
          route.points.last.x > 0.40 &&
          route.points.last.y < 0.42,
    );

    expect(player1Stages, [1, 2]);
    expect(nextPlayer1Route.points.first.x, closeTo(0.34, 0.02));
    expect(nextPlayer1Route.points.first.y, closeTo(0.52, 0.02));
    expect(nextPlayer1Route.points.last.x, closeTo(0.46, 0.02));
    expect(nextPlayer1Route.points.last.y, closeTo(0.36, 0.02));
  });

  testWidgets('each player can start stages independently', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);
    String? savedLayout;

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '선수별 단계',
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
                    y: 0.46,
                    colorValue: 0xFF1E88E5,
                  ),
                ],
                routes: <TrainingMethodRoute>[
                  TrainingMethodRoute(
                    id: 'player-1-route',
                    kind: TrainingMethodRouteKind.player,
                    linkedItemId: 'player-1',
                    actorItemId: 'player-1',
                    stageIndex: 4,
                    points: <TrainingMethodPoint>[
                      TrainingMethodPoint(x: 0.22, y: 0.52),
                      TrainingMethodPoint(x: 0.34, y: 0.48),
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
      find
          .descendant(of: boardFinder, matching: find.byIcon(Icons.person))
          .at(1),
    );
    await tester.pumpAndSettle();
    await _tapVisibleFinder(
      tester,
      find.byKey(const ValueKey('training-player-flow-action-player-2-move')),
    );
    await _tapBoardRelative(tester, boardFinder, const Offset(0.78, 0.38));

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final player1Route = saved.pages.single.routes.singleWhere(
      (route) => route.linkedItemId == 'player-1',
    );
    final player2Route = saved.pages.single.routes.singleWhere(
      (route) => route.linkedItemId == 'player-2',
    );

    expect(player1Route.stageIndex, 4);
    expect(player2Route.stageIndex, 1);
    expect(player2Route.points.last.x, closeTo(0.78, 0.02));
    expect(player2Route.points.last.y, closeTo(0.38, 0.02));
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

  testWidgets('selected player can create a move route from next action', (
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
    await _tapVisibleFinder(
      tester,
      find.byKey(const ValueKey('training-player-flow-action-player-1-move')),
    );
    await _tapBoardRelative(tester, boardFinder, const Offset(0.50, 0.36));

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
    expect(find.text('패스 후 이동 받을 선수를 누르세요.'), findsOneWidget);
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
    expect(playerRoute.stageIndex, 1);
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
    expect(playerRoute.stageIndex, 1);
    expect(playerRoute.points.first.x, closeTo(0.22, 0.001));
    expect(playerRoute.points.first.y, closeTo(0.52, 0.001));
    expect(playerRoute.points.last.x, closeTo(0.72, 0.02));
    expect(playerRoute.points.last.y, closeTo(0.36, 0.02));
  });

  testWidgets('passer cone turn stays off-ball after passing away possession', (
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

    expect(find.widgetWithText(OutlinedButton, '슈팅'), findsNothing);

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
    final playerRoute = page.routes.singleWhere(
      (route) => route.kind == TrainingMethodRouteKind.player,
    );

    expect(page.items.where((item) => item.type == 'cone'), hasLength(1));
    expect(page.items.where((item) => item.type == 'ball'), hasLength(1));
    expect(ballRoutes, hasLength(1));
    expect(passRoute.linkedItemId, 'ball-1');
    expect(passRoute.targetItemId, 'player-2');
    expect(passRoute.stageIndex, 1);
    expect(playerRoute.linkedItemId, 'player-1');
    expect(playerRoute.stageIndex, 1);
    expect(playerRoute.points.length, greaterThan(6));
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
    expect(find.text('패스 받을 선수를 누르세요.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('training-action-target-valid-player-2')),
      findsOneWidget,
    );
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

  testWidgets('pass action cannot target a cone spot directly', (
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
                    id: 'player-2',
                    type: 'player',
                    x: 0.52,
                    y: 0.46,
                    colorValue: 0xFF1E88E5,
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
    await _tapBoardRelativeThroughWidgets(
      tester,
      boardFinder,
      const Offset(0.22, 0.52),
    );

    await _tapVisibleOutlinedButton(tester, '패스');
    expect(
      find.byKey(const ValueKey('training-action-target-valid-player-2')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('training-action-target-valid-cone-1')),
      findsNothing,
    );
    await _tapBoardRelative(tester, boardFinder, const Offset(0.68, 0.42));

    expect(find.text('패스 받을 선수를 누르세요.'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();
    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    expect(saved.pages.single.routes, isEmpty);
  });

  testWidgets(
      'player flow target prop action jumps an existing hurdle with owned ball',
      (WidgetTester tester) async {
    _setLandscapeSurface(tester);
    String? savedLayout;

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '뜀틀 대상',
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
                    id: 'hurdle-1',
                    type: 'hurdle',
                    x: 0.58,
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
    await _tapVisibleFinder(
      tester,
      find.byKey(
        const ValueKey(
          'training-player-flow-prop-action-player-1-hurdleJump-hurdle-1',
        ),
      ),
    );

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

    expect(page.items.where((item) => item.type == 'hurdle'), hasLength(1));
    expect(playerRoute.linkedItemId, 'player-1');
    expect(playerRoute.points, hasLength(4));
    expect(playerRoute.points[2].x, closeTo(0.58, 0.001));
    expect(playerRoute.points[2].y, closeTo(0.42, 0.001));
    expect(ballRoute.linkedItemId, 'ball-1');
    expect(ballRoute.actorItemId, 'player-1');
    expect(ballRoute.targetItemId, 'player-1');
    expect(ballRoute.stageIndex, playerRoute.stageIndex);
  });

  testWidgets('player flow move carries the initially owned ball', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);
    String? savedLayout;

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '공 동반 이동',
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
    await _tapVisibleFinder(
      tester,
      find.byKey(const ValueKey('training-player-flow-action-player-1-move')),
    );
    await _tapBoardRelative(tester, boardFinder, const Offset(0.56, 0.42));

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final routes = saved.pages.single.routes;
    final playerRoute = routes.singleWhere(
      (route) => route.kind == TrainingMethodRouteKind.player,
    );
    final ballRoute = routes.singleWhere(
      (route) => route.kind == TrainingMethodRouteKind.ball,
    );

    expect(playerRoute.linkedItemId, 'player-1');
    expect(playerRoute.points.last.x, closeTo(0.56, 0.02));
    expect(playerRoute.points.last.y, closeTo(0.42, 0.02));
    expect(ballRoute.linkedItemId, 'ball-1');
    expect(ballRoute.actorItemId, 'player-1');
    expect(ballRoute.targetItemId, 'player-1');
    expect(ballRoute.stageIndex, playerRoute.stageIndex);
    expect(ballRoute.points.last.x, greaterThan(playerRoute.points.last.x));
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
    await _tapVisibleOutlinedButton(tester, '패스');
    await _tapBoardRelativeThroughWidgets(
      tester,
      boardFinder,
      const Offset(0.52, 0.46),
    );
    await _tapVisibleOutlinedButton(tester, '뜀틀 넘기');
    await _tapBoardRelative(tester, boardFinder, const Offset(0.72, 0.36));

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final page = saved.pages.single;
    final ballRoutes = page.routes
        .where((route) => route.kind == TrainingMethodRouteKind.ball)
        .toList(growable: false);
    final passRoute = ballRoutes.singleWhere((route) => route.stageIndex == 1);
    final carryRoute = ballRoutes.singleWhere((route) => route.stageIndex == 2);
    final playerRoute = page.routes.singleWhere(
      (route) => route.kind == TrainingMethodRouteKind.player,
    );

    expect(page.items.where((item) => item.type == 'hurdle'), hasLength(1));
    expect(ballRoutes, hasLength(2));
    expect(passRoute.linkedItemId, 'ball-1');
    expect(carryRoute.linkedItemId, 'ball-1');
    expect(carryRoute.actorItemId, 'player-2');
    expect(carryRoute.targetItemId, 'player-2');
    expect(playerRoute.linkedItemId, 'player-2');
    expect(playerRoute.stageIndex, 2);
  });

  testWidgets('moving pass receiver keeps the ball route end attached', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);
    String? savedLayout;

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '패스 수신자 이동',
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
    final playerIcons = find.descendant(
      of: boardFinder,
      matching: find.byIcon(Icons.person),
    );
    await tester.tap(playerIcons.first);
    await tester.pumpAndSettle();
    await _tapVisibleOutlinedButton(tester, '패스');
    await _tapBoardRelativeThroughWidgets(
      tester,
      boardFinder,
      const Offset(0.52, 0.46),
    );

    await tester.drag(playerIcons.at(1), const Offset(58, -30));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final page = saved.pages.single;
    final receiver = page.items.singleWhere((item) => item.id == 'player-2');
    final ballRoute = page.routes.singleWhere(
      (route) => route.kind == TrainingMethodRouteKind.ball,
    );
    final dx = receiver.x - 0.52;
    final dy = receiver.y - 0.46;

    expect(dx.abs(), greaterThan(0.001));
    expect(dy.abs(), greaterThan(0.001));
    expect(ballRoute.linkedItemId, 'ball-1');
    expect(ballRoute.actorItemId, 'player-1');
    expect(ballRoute.targetItemId, 'player-2');
    expect(ballRoute.points.first.x, closeTo(0.29, 0.03));
    expect(ballRoute.points.first.y, closeTo(0.52, 0.03));
    expect(ballRoute.points.last.x, closeTo(0.52 + dx, 0.0001));
    expect(ballRoute.points.last.y, closeTo(0.46 + dy, 0.0001));
  });

  testWidgets('pass to a moving receiver targets the receiver route end', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);
    String? savedLayout;

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '움직이는 수신자 패스',
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
                routes: <TrainingMethodRoute>[
                  TrainingMethodRoute(
                    id: 'route-player-2',
                    kind: TrainingMethodRouteKind.player,
                    linkedItemId: 'player-2',
                    actorItemId: 'player-2',
                    points: <TrainingMethodPoint>[
                      TrainingMethodPoint(x: 0.52, y: 0.46),
                      TrainingMethodPoint(x: 0.72, y: 0.36),
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

    await _tapBoardRelativeThroughWidgets(
      tester,
      boardFinder,
      const Offset(0.22, 0.52),
    );
    await _tapVisibleOutlinedButton(tester, '패스');
    await _tapBoardRelativeThroughWidgets(
      tester,
      boardFinder,
      const Offset(0.72, 0.36),
    );

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final page = saved.pages.single;
    final receiverRoute = page.routes.singleWhere(
      (route) =>
          route.kind == TrainingMethodRouteKind.player &&
          route.linkedItemId == 'player-2',
    );
    final ballRoute = page.routes.singleWhere(
      (route) => route.kind == TrainingMethodRouteKind.ball,
    );
    final receiverEnd = receiverRoute.points.last;
    final passEnd = ballRoute.points.last;

    expect(ballRoute.linkedItemId, 'ball-1');
    expect(ballRoute.actorItemId, 'player-1');
    expect(ballRoute.targetItemId, 'player-2');
    expect(receiverEnd.x, closeTo(0.72, 0.02));
    expect(receiverEnd.y, closeTo(0.36, 0.02));
    expect(passEnd.x, closeTo(receiverEnd.x, 0.0001));
    expect(passEnd.y, closeTo(receiverEnd.y, 0.0001));
  });

  testWidgets('player flow connects passes across multiple board targets', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);
    String? savedLayout;

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '패스 연계',
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
                    id: 'player-3',
                    type: 'player',
                    x: 0.76,
                    y: 0.38,
                    colorValue: 0xFF43A047,
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
    expect(
      find.byKey(const ValueKey('training-action-target-valid-player-2')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('training-action-target-valid-player-3')),
      findsOneWidget,
    );
    await _tapBoardRelativeThroughWidgets(
      tester,
      boardFinder,
      const Offset(0.52, 0.46),
    );

    expect(
      find.byKey(const ValueKey('training-player-next-action-player-2')),
      findsOneWidget,
    );
    await _tapVisibleOutlinedButton(tester, '패스');
    expect(
      find.byKey(const ValueKey('training-action-target-valid-player-3')),
      findsOneWidget,
    );
    await _tapBoardRelativeThroughWidgets(
      tester,
      boardFinder,
      const Offset(0.76, 0.38),
    );

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final ballRoutes = saved.pages.single.routes
        .where((route) => route.kind == TrainingMethodRouteKind.ball)
        .toList(growable: false);
    final stages =
        ballRoutes.map((route) => route.stageIndex).toList(growable: false);

    expect(ballRoutes, hasLength(2));
    expect(ballRoutes.map((route) => route.actorItemId), [
      'player-1',
      'player-2',
    ]);
    expect(ballRoutes.map((route) => route.linkedItemId).toSet(), {'ball-1'});
    expect(stages, [1, 2]);
    expect(ballRoutes.last.points.last.x, closeTo(0.76, 0.02));
    expect(ballRoutes.last.points.last.y, closeTo(0.38, 0.02));
  });

  testWidgets('selected player shows next action first with complete actions', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '다음 동작',
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
                    x: 0.56,
                    y: 0.44,
                    colorValue: 0xFF1E88E5,
                  ),
                  TrainingMethodItem(
                    id: 'cone-1',
                    type: 'cone',
                    x: 0.42,
                    y: 0.36,
                  ),
                  TrainingMethodItem(
                    id: 'hurdle-1',
                    type: 'hurdle',
                    x: 0.62,
                    y: 0.36,
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

    final nextAction =
        find.byKey(const ValueKey('training-player-next-action-player-1'));
    expect(nextAction, findsOneWidget);
    expect(find.text('추천'), findsOneWidget);
    expect(find.text('다음 1단계'), findsOneWidget);
    expect(find.text('선수 액션'), findsNothing);
    expect(find.widgetWithText(FilledButton, '패스'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '드리블'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '슈팅'), findsOneWidget);
    for (final entry in <String>[
      'coneTurn-cone-1',
      'coneJump-cone-1',
      'hurdleJump-hurdle-1',
    ]) {
      expect(
        find.byKey(
          ValueKey('training-player-flow-prop-action-player-1-$entry'),
        ),
        findsOneWidget,
      );
    }
    expect(
      find.byKey(
        const ValueKey('training-player-flow-target-player-1-player-2'),
      ),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('training-player-flow-new-receiver-player-1')),
      findsNothing,
    );
    for (final action in <String>[
      'pass',
      'passAndMove',
      'dribble',
      'shot',
      'cross',
      'move',
      'stay',
      'returnMove',
      'coneTurn',
      'coneJump',
      'hurdleJump',
    ]) {
      expect(
        find.byKey(ValueKey('training-player-flow-action-player-1-$action')),
        findsOneWidget,
      );
    }
  });

  testWidgets('player flow stay action pauses player and owned ball', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);
    String? savedLayout;

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '제자리',
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
      find
          .descendant(of: boardFinder, matching: find.byIcon(Icons.person))
          .first,
    );
    await tester.pumpAndSettle();
    await _tapVisibleFinder(
      tester,
      find.byKey(const ValueKey('training-player-flow-action-player-1-stay')),
    );

    expect(find.text('사람 1 제자리'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final routes = saved.pages.single.routes;
    final playerRoute = routes.singleWhere(
      (route) => route.kind == TrainingMethodRouteKind.player,
    );
    final ballRoute = routes.singleWhere(
      (route) => route.kind == TrainingMethodRouteKind.ball,
    );

    expect(playerRoute.linkedItemId, 'player-1');
    expect(playerRoute.actorItemId, 'player-1');
    expect(playerRoute.segmentDurationsMs, [900]);
    expect(playerRoute.points.last.x, closeTo(0.2212, 0.0002));
    expect(playerRoute.points.last.y, closeTo(0.52, 0.0001));
    expect(ballRoute.linkedItemId, 'ball-1');
    expect(ballRoute.actorItemId, 'player-1');
    expect(ballRoute.targetItemId, 'player-1');
    expect(ballRoute.stageIndex, playerRoute.stageIndex);
  });

  testWidgets('player flow only shows possible ball actions', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '가능한 동작',
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
                    x: 0.62,
                    y: 0.48,
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
        ),
      ),
    );
    await tester.pumpAndSettle();

    final boardFinder = find.byKey(const ValueKey('training-board-canvas'));
    await tester.tap(
      find
          .descendant(of: boardFinder, matching: find.byIcon(Icons.person))
          .last,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(
        const ValueKey('training-player-flow-target-player-2-player-1'),
      ),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('training-player-flow-new-receiver-player-2')),
      findsNothing,
    );
    expect(
      find.byKey(
          const ValueKey('training-player-flow-action-player-2-dribble')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('training-player-flow-action-player-2-shot')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('training-player-flow-action-player-2-move')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('training-player-flow-action-player-2-moveToBall'),
      ),
      findsNothing,
    );
  });

  testWidgets('player flow can move to a nearby unowned ball and claim it', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);
    String? savedLayout;

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '공 확보',
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
                    x: 0.30,
                    y: 0.52,
                    colorValue: 0xFFFFCA28,
                  ),
                ],
                routes: <TrainingMethodRoute>[
                  TrainingMethodRoute(
                    id: 'shot-ball',
                    kind: TrainingMethodRouteKind.ball,
                    linkedItemId: 'ball-1',
                    actorItemId: 'player-1',
                    points: <TrainingMethodPoint>[
                      TrainingMethodPoint(x: 0.22, y: 0.52),
                      TrainingMethodPoint(x: 0.30, y: 0.52),
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
    expect(find.text('공 1: 소유자 없음'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey('training-player-flow-action-player-1-moveToBall'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
          const ValueKey('training-player-flow-action-player-1-dribble')),
      findsNothing,
    );

    await tester.tap(
      find.byKey(
        const ValueKey('training-player-flow-action-player-1-moveToBall'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('공 1: 사람 1 보유'), findsOneWidget);
    expect(find.text('사람 1 공 확보'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final page = saved.pages.single;
    final playerRoute = page.routes.singleWhere(
      (route) => route.kind == TrainingMethodRouteKind.player,
    );
    final pickupRoute = page.routes.singleWhere(
      (route) =>
          route.kind == TrainingMethodRouteKind.ball &&
          route.id != 'shot-ball' &&
          route.targetItemId == 'player-1',
    );

    expect(playerRoute.stageIndex, 2);
    expect(playerRoute.points.first.x, closeTo(0.22, 0.001));
    expect(playerRoute.points.last.x, closeTo(0.30, 0.001));
    expect(pickupRoute.stageIndex, 2);
    expect(pickupRoute.actorItemId, 'player-1');
    expect(pickupRoute.targetItemId, 'player-1');
    expect(
        pickupRoute.points.first.x, closeTo(pickupRoute.points.last.x, 0.001));
    expect(
        pickupRoute.points.first.y, closeTo(pickupRoute.points.last.y, 0.001));
  });

  testWidgets('player flow hides pass creation when no receiver exists', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '자동 수신자',
          initialLayoutJson: const TrainingMethodLayout(
            pages: <TrainingMethodPage>[
              TrainingMethodPage(
                name: 'Board',
                items: <TrainingMethodItem>[
                  TrainingMethodItem(
                    id: 'player-1',
                    type: 'player',
                    x: 0.28,
                    y: 0.52,
                  ),
                  TrainingMethodItem(
                    id: 'ball-1',
                    type: 'ball',
                    x: 0.35,
                    y: 0.52,
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

    final boardFinder = find.byKey(const ValueKey('training-board-canvas'));
    await tester.tap(
      find
          .descendant(of: boardFinder, matching: find.byIcon(Icons.person))
          .first,
    );
    await tester.pumpAndSettle();
    final player1NextAction =
        find.byKey(const ValueKey('training-player-next-action-player-1'));
    expect(player1NextAction, findsOneWidget);

    expect(
      find.byKey(const ValueKey('training-player-flow-new-receiver-player-1')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('training-player-flow-action-player-1-pass')),
      findsNothing,
    );
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
    await tester.tap(playerFinder.first);
    await tester.pumpAndSettle();
    await _tapVisibleFinder(
      tester,
      find.byKey(const ValueKey('training-player-flow-action-player-1-move')),
    );
    await _tapBoardRelative(tester, boardFinder, const Offset(0.32, 0.28));

    await _tapBoardRelativeThroughWidgets(
      tester,
      boardFinder,
      const Offset(0.74, 0.66),
    );
    await _tapVisibleFinder(
      tester,
      find.byKey(const ValueKey('training-player-flow-action-player-2-move')),
    );
    await _tapBoardRelative(tester, boardFinder, const Offset(0.84, 0.50));

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
    await tester.tap(
      find
          .descendant(of: boardFinder, matching: find.byIcon(Icons.person))
          .at(1),
    );
    await tester.pumpAndSettle();

    await _tapVisibleOutlinedButton(tester, '단계 액션 삭제');

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final routes = saved.pages.single.routes;
    expect(
      routes.where((route) => route.kind == TrainingMethodRouteKind.player),
      hasLength(1),
    );
  });

  testWidgets('global stage action can be deleted directly from summary', (
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
              x: 0.62,
              y: 0.46,
            ),
            TrainingMethodItem(id: 'ball-1', type: 'ball', x: 0.27, y: 0.5),
          ],
          routes: <TrainingMethodRoute>[
            TrainingMethodRoute(
              id: 'route-pass',
              kind: TrainingMethodRouteKind.ball,
              linkedItemId: 'ball-1',
              actorItemId: 'player-1',
              targetItemId: 'player-2',
              stageIndex: 1,
              points: <TrainingMethodPoint>[
                TrainingMethodPoint(x: 0.27, y: 0.5),
                TrainingMethodPoint(x: 0.62, y: 0.46),
              ],
            ),
            TrainingMethodRoute(
              id: 'route-move',
              kind: TrainingMethodRouteKind.player,
              linkedItemId: 'player-2',
              actorItemId: 'player-2',
              stageIndex: 2,
              points: <TrainingMethodPoint>[
                TrainingMethodPoint(x: 0.62, y: 0.46),
                TrainingMethodPoint(x: 0.76, y: 0.40),
              ],
            ),
          ],
        ),
      ],
    ).encode();

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '단계 삭제',
          initialLayoutJson: initialLayout,
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

    final deletePassAction = find.byKey(
      const ValueKey('training-global-stage-action-delete-route-pass'),
    );
    expect(deletePassAction, findsOneWidget);
    await tester.tap(deletePassAction);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final routeIds = saved.pages.single.routes.map((route) => route.id);
    expect(routeIds, isNot(contains('route-pass')));
    expect(routeIds, contains('route-move'));
  });

  testWidgets('global stage action selects compact stage controls from summary',
      (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);
    final initialLayout = const TrainingMethodLayout(
      pages: <TrainingMethodPage>[
        TrainingMethodPage(
          name: 'Board',
          items: <TrainingMethodItem>[
            TrainingMethodItem(id: 'player-1', type: 'player', x: 0.2, y: 0.5),
            TrainingMethodItem(id: 'ball-1', type: 'ball', x: 0.27, y: 0.5),
          ],
          routes: <TrainingMethodRoute>[
            TrainingMethodRoute(
              id: 'route-shot',
              kind: TrainingMethodRouteKind.ball,
              linkedItemId: 'ball-1',
              actorItemId: 'player-1',
              stageIndex: 1,
              points: <TrainingMethodPoint>[
                TrainingMethodPoint(x: 0.27, y: 0.5),
                TrainingMethodPoint(x: 0.82, y: 0.34),
              ],
            ),
          ],
        ),
      ],
    ).encode();

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '단계 수정',
          initialLayoutJson: initialLayout,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final boardFinder = find.byKey(const ValueKey('training-board-canvas'));
    await tester.tap(
      find.descendant(of: boardFinder, matching: find.byIcon(Icons.person)),
    );
    await tester.pumpAndSettle();

    final editAction = find.byKey(
      const ValueKey('training-global-stage-action-edit-route-shot'),
    );
    expect(editAction, findsOneWidget);
    await tester.tap(editAction);
    await tester.pumpAndSettle();

    expect(find.text('동작 단계'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '단계 액션 삭제'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '이동선 완료'), findsNothing);
    expect(
      find.text('도착 지점을 누르고 이동선 완료를 누르면 선택한 이동선이 바뀝니다.'),
      findsNothing,
    );
  });

  testWidgets('receiver inline action adds the next global stage', (
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
              x: 0.58,
              y: 0.46,
              colorValue: 0xFF1E88E5,
            ),
            TrainingMethodItem(
              id: 'ball-1',
              type: 'ball',
              x: 0.27,
              y: 0.5,
              colorValue: 0xFFFFCA28,
            ),
          ],
          routes: <TrainingMethodRoute>[
            TrainingMethodRoute(
              id: 'route-pass',
              kind: TrainingMethodRouteKind.ball,
              linkedItemId: 'ball-1',
              actorItemId: 'player-1',
              targetItemId: 'player-2',
              stageIndex: 1,
              points: <TrainingMethodPoint>[
                TrainingMethodPoint(x: 0.27, y: 0.5),
                TrainingMethodPoint(x: 0.58, y: 0.46),
              ],
            ),
          ],
        ),
      ],
    ).encode();

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '단계 이어쓰기',
          initialLayoutJson: initialLayout,
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

    expect(
      find.byKey(
        const ValueKey('training-global-stage-action-add-same-route-pass'),
      ),
      findsNothing,
    );
    expect(
      find.byKey(
        const ValueKey('training-global-stage-action-add-next-route-pass'),
      ),
      findsNothing,
    );
    await _tapBoardRelativeThroughWidgets(
      tester,
      boardFinder,
      const Offset(0.58, 0.46),
    );

    final dribbleAction = find.byKey(
      const ValueKey('training-player-flow-action-player-2-dribble'),
    );
    expect(dribbleAction, findsOneWidget);
    await _tapVisibleFinder(tester, dribbleAction);
    await _tapBoardRelative(tester, boardFinder, const Offset(0.72, 0.38));

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final player2Route = saved.pages.single.routes.singleWhere(
      (route) =>
          route.kind == TrainingMethodRouteKind.player &&
          route.linkedItemId == 'player-2',
    );
    final player2BallRoute = saved.pages.single.routes.singleWhere(
      (route) =>
          route.kind == TrainingMethodRouteKind.ball &&
          route.actorItemId == 'player-2',
    );

    expect(player2Route.stageIndex, 2);
    expect(player2BallRoute.stageIndex, 2);
    expect(player2BallRoute.linkedItemId, 'ball-1');
    expect(player2Route.points.last.x, closeTo(0.72, 0.02));
    expect(player2Route.points.last.y, closeTo(0.38, 0.02));
  });

  testWidgets('flow review warns when another player uses owned ball', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);
    final initialLayout = const TrainingMethodLayout(
      pages: <TrainingMethodPage>[
        TrainingMethodPage(
          name: 'Board',
          items: <TrainingMethodItem>[
            TrainingMethodItem(id: 'player-1', type: 'player', x: 0.2, y: 0.5),
            TrainingMethodItem(
              id: 'player-2',
              type: 'player',
              x: 0.62,
              y: 0.46,
            ),
            TrainingMethodItem(id: 'ball-1', type: 'ball', x: 0.27, y: 0.5),
          ],
          routes: <TrainingMethodRoute>[
            TrainingMethodRoute(
              id: 'route-stolen-carry',
              kind: TrainingMethodRouteKind.ball,
              linkedItemId: 'ball-1',
              actorItemId: 'player-2',
              targetItemId: 'player-2',
              stageIndex: 1,
              points: <TrainingMethodPoint>[
                TrainingMethodPoint(x: 0.27, y: 0.5),
                TrainingMethodPoint(x: 0.70, y: 0.42),
              ],
            ),
          ],
        ),
      ],
    ).encode();

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '흐름 점검',
          initialLayoutJson: initialLayout,
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

    expect(find.text('흐름 점검'), findsOneWidget);
    expect(
      find.text('공 1는 사람 1 보유인데 사람 2가 사용합니다.'),
      findsOneWidget,
    );
  });

  testWidgets('flow review warns when unowned shot ball is reused', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);
    final initialLayout = const TrainingMethodLayout(
      pages: <TrainingMethodPage>[
        TrainingMethodPage(
          name: 'Board',
          items: <TrainingMethodItem>[
            TrainingMethodItem(id: 'player-1', type: 'player', x: 0.2, y: 0.5),
            TrainingMethodItem(
              id: 'player-2',
              type: 'player',
              x: 0.62,
              y: 0.46,
            ),
            TrainingMethodItem(id: 'ball-1', type: 'ball', x: 0.27, y: 0.5),
          ],
          routes: <TrainingMethodRoute>[
            TrainingMethodRoute(
              id: 'route-shot',
              kind: TrainingMethodRouteKind.ball,
              linkedItemId: 'ball-1',
              actorItemId: 'player-1',
              stageIndex: 1,
              points: <TrainingMethodPoint>[
                TrainingMethodPoint(x: 0.27, y: 0.5),
                TrainingMethodPoint(x: 0.84, y: 0.34),
              ],
            ),
            TrainingMethodRoute(
              id: 'route-reuse',
              kind: TrainingMethodRouteKind.ball,
              linkedItemId: 'ball-1',
              actorItemId: 'player-2',
              targetItemId: 'player-2',
              stageIndex: 2,
              points: <TrainingMethodPoint>[
                TrainingMethodPoint(x: 0.84, y: 0.34),
                TrainingMethodPoint(x: 0.70, y: 0.42),
              ],
            ),
          ],
        ),
      ],
    ).encode();

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '슈팅 후 재사용',
          initialLayoutJson: initialLayout,
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

    expect(
      find.text('공 1는 소유자 없음 상태인데 사람 2가 사용합니다.'),
      findsOneWidget,
    );
  });

  testWidgets('deleting a carry action removes paired player and ball routes', (
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
            TrainingMethodItem(id: 'ball-1', type: 'ball', x: 0.27, y: 0.5),
          ],
          routes: <TrainingMethodRoute>[
            TrainingMethodRoute(
              id: 'route-player-carry',
              kind: TrainingMethodRouteKind.player,
              linkedItemId: 'player-1',
              actorItemId: 'player-1',
              stageIndex: 1,
              points: <TrainingMethodPoint>[
                TrainingMethodPoint(x: 0.2, y: 0.5),
                TrainingMethodPoint(x: 0.46, y: 0.42),
              ],
            ),
            TrainingMethodRoute(
              id: 'route-ball-carry',
              kind: TrainingMethodRouteKind.ball,
              linkedItemId: 'ball-1',
              actorItemId: 'player-1',
              targetItemId: 'player-1',
              stageIndex: 1,
              points: <TrainingMethodPoint>[
                TrainingMethodPoint(x: 0.27, y: 0.5),
                TrainingMethodPoint(x: 0.53, y: 0.42),
              ],
            ),
          ],
        ),
      ],
    ).encode();

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '운반 삭제',
          initialLayoutJson: initialLayout,
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

    final deleteCarryAction = find.byKey(
      const ValueKey('training-global-stage-action-delete-route-ball-carry'),
    );
    expect(deleteCarryAction, findsOneWidget);
    await tester.tap(deleteCarryAction);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    expect(saved.pages.single.routes, isEmpty);
    expect(saved.pages.single.items.map((item) => item.id), contains('ball-1'));
  });

  testWidgets('deleting a player also deletes the ball they own', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);
    String? savedLayout;

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '소유자 삭제',
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
                    y: 0.48,
                    colorValue: 0xFF1E88E5,
                  ),
                  TrainingMethodItem(
                    id: 'ball-1',
                    type: 'ball',
                    x: 0.38,
                    y: 0.50,
                    colorValue: 0xFFFFCA28,
                  ),
                ],
                routes: <TrainingMethodRoute>[
                  TrainingMethodRoute(
                    id: 'route-ball-1',
                    kind: TrainingMethodRouteKind.ball,
                    linkedItemId: 'ball-1',
                    actorItemId: 'player-2',
                    targetItemId: 'player-1',
                    points: <TrainingMethodPoint>[
                      TrainingMethodPoint(x: 0.58, y: 0.48),
                      TrainingMethodPoint(x: 0.22, y: 0.52),
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
      find
          .descendant(of: boardFinder, matching: find.byIcon(Icons.person))
          .first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('삭제').last);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final page = saved.pages.single;
    expect(page.items.map((item) => item.id), isNot(contains('player-1')));
    expect(page.items.map((item) => item.id), isNot(contains('ball-1')));
    expect(page.items.map((item) => item.id), contains('player-2'));
    expect(page.routes, isEmpty);
  });

  testWidgets('deleting a player also deletes unowned balls', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);
    String? savedLayout;

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '소유 없는 공 삭제',
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
                    x: 0.82,
                    y: 0.28,
                    colorValue: 0xFFFFCA28,
                  ),
                  TrainingMethodItem(
                    id: 'ball-2',
                    type: 'ball',
                    x: 0.65,
                    y: 0.46,
                    colorValue: 0xFF90CAF9,
                  ),
                ],
                routes: <TrainingMethodRoute>[
                  TrainingMethodRoute(
                    id: 'owned-ball',
                    kind: TrainingMethodRouteKind.ball,
                    linkedItemId: 'ball-2',
                    actorItemId: 'player-2',
                    targetItemId: 'player-2',
                    points: <TrainingMethodPoint>[
                      TrainingMethodPoint(x: 0.65, y: 0.46),
                      TrainingMethodPoint(x: 0.66, y: 0.46),
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
      find
          .descendant(of: boardFinder, matching: find.byIcon(Icons.person))
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('삭제'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final page = saved.pages.single;
    expect(page.items.map((item) => item.id), isNot(contains('player-1')));
    expect(page.items.map((item) => item.id), isNot(contains('ball-1')));
    expect(
        page.items.map((item) => item.id), containsAll(['player-2', 'ball-2']));
    expect(page.routes.single.linkedItemId, 'ball-2');
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

  testWidgets('long pressing a linked item moves it with its route', (
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

  testWidgets('dragging a linked player moves the player and route', (
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
    await tester.drag(playerFinder, const Offset(48, -28));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final player = saved.pages.single.items.single;
    final route = saved.pages.single.routes.singleWhere(
      (route) => route.kind == TrainingMethodRouteKind.player,
    );
    final dx = player.x - 0.2;
    final dy = player.y - 0.5;

    expect(dx, greaterThan(0.001));
    expect(dy, lessThan(-0.001));
    expect(route.points[0].x, closeTo(0.2 + dx, 0.0001));
    expect(route.points[0].y, closeTo(0.5 + dy, 0.0001));
    expect(route.points[1].x, closeTo(0.45 + dx, 0.0001));
    expect(route.points[1].y, closeTo(0.35 + dy, 0.0001));
  });

  testWidgets('dragging a ball is ignored because ball follows players', (
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
    await tester.dragFrom(tester.getCenter(ballFinder), const Offset(56, -22));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final ball = saved.pages.single.items.single;
    final route = saved.pages.single.routes.single;

    expect(ball.x, closeTo(0.24, 0.0001));
    expect(ball.y, closeTo(0.58, 0.0001));
    expect(route.points[0].x, closeTo(0.24, 0.0001));
    expect(route.points[0].y, closeTo(0.58, 0.0001));
    expect(route.points[1].x, closeTo(0.62, 0.0001));
    expect(route.points[1].y, closeTo(0.46, 0.0001));
  });

  testWidgets('existing ball does not block player next actions', (
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
    expect(find.widgetWithText(OutlinedButton, '패스 만들기'), findsNothing);

    await tester.tap(
      find.descendant(of: boardFinder, matching: find.byIcon(Icons.person)),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('training-player-next-action-player-1')),
      findsOneWidget,
    );
    expect(find.text('선수 액션'), findsNothing);
    await _tapVisibleOutlinedButton(tester, '이동');
    await _tapBoardRelative(tester, boardFinder, const Offset(0.52, 0.36));

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final route = saved.pages.single.routes.singleWhere(
      (route) => route.kind == TrainingMethodRouteKind.player,
    );
    expect(route.kind, TrainingMethodRouteKind.player);
    expect(route.linkedItemId, 'player-1');
    expect(route.points.first.x, closeTo(0.22, 0.001));
    expect(route.points.first.y, closeTo(0.52, 0.001));
  });

  testWidgets('players stay interactive above props while balls stay passive', (
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
    expect(find.widgetWithText(OutlinedButton, '이동 만들기'), findsNothing);
    expect(
      find.byKey(const ValueKey('training-player-next-action-player-1')),
      findsOneWidget,
    );

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
      await tester.tap(
        find
            .descendant(of: boardFinder, matching: find.byIcon(Icons.person))
            .at(1),
      );
      await tester.pumpAndSettle();
      await _tapVisibleOutlinedButton(tester, '이동');
      await _tapBoardRelative(tester, boardFinder, const Offset(0.86, 0.36));

      await tester.tap(find.widgetWithText(TextButton, '저장'));
      await tester.pumpAndSettle();

      final saved = TrainingMethodLayout.decode(savedLayout ?? '');
      final route = saved.pages.single.routes.single;
      expect(route.linkedItemId, 'player-2');
      expect(route.colorValue, 0xFFE53935);
    },
  );

  testWidgets(
    'ball cannot be added as a direct sketch token',
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

      expect(find.widgetWithText(OutlinedButton, '공'), findsNothing);

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
        findsNothing,
      );
      expect(find.widgetWithText(OutlinedButton, '패스'), findsNothing);

      await tester.tap(find.widgetWithText(TextButton, '저장'));
      await tester.pumpAndSettle();

      final saved = TrainingMethodLayout.decode(savedLayout ?? '');
      final page = saved.pages.single;
      expect(page.items.where((item) => item.type == 'ball'), isEmpty);
      expect(page.items.where((item) => item.type == 'player'), isEmpty);
      expect(page.routes, isEmpty);
    },
  );

  testWidgets(
    'player cannot use a ball owned by another player without a pass',
    (WidgetTester tester) async {
      _setLandscapeSurface(tester);

      await tester.pumpWidget(
        _buildApp(
          TrainingMethodBoardScreen(
            boardTitle: '공 소유 제한',
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
                      x: 0.60,
                      y: 0.52,
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
          ),
        ),
      );
      await tester.pumpAndSettle();

      final boardFinder = find.byKey(const ValueKey('training-board-canvas'));
      await tester.tap(
        find
            .descendant(of: boardFinder, matching: find.byIcon(Icons.person))
            .at(1),
      );
      await tester.pumpAndSettle();

      expect(find.text('공 1: 사람 1 보유'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, '드리블'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, '슈팅'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, '패스'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, '사람 1에게 패스'), findsNothing);
      expect(
        find.byKey(
          const ValueKey('training-player-flow-action-player-2-move'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('training-player-flow-action-player-2-dribble'),
        ),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey('training-player-flow-action-player-2-shot'),
        ),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey('training-player-flow-action-player-2-pass'),
        ),
        findsNothing,
      );
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

    await tester.tap(find.widgetWithText(OutlinedButton, '콘'));
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
        const ValueKey('training-selected-color-option-ffe53935'),
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
    final cone = saved.pages.single.items.singleWhere(
      (item) => item.type == 'cone',
    );

    expect(cone.colorValue, 0xFFE53935);
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

      expect(find.text('공 1: 소유자 없음'), findsOneWidget);
      expect(find.text('동작 단계'), findsOneWidget);
      await _tapRouteStageChip(tester, 2);

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
    expect(find.widgetWithText(OutlinedButton, '이동 만들기'), findsNothing);
    expect(
      find.byKey(const ValueKey('training-player-next-action-player-1')),
      findsOneWidget,
    );
    expect(find.widgetWithText(OutlinedButton, '돌아오기'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '오버랩'), findsOneWidget);

    expect(
      find.descendant(
        of: boardFinder,
        matching: find.byIcon(Icons.sports_soccer),
      ),
      findsOneWidget,
    );
    expect(find.text('공 액션'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, '패스 만들기'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, '패스'), findsNothing);
    expect(find.text('패스·드리블 플로우'), findsNothing);

    expect(
      find.byKey(
        const ValueKey('training-player-flow-action-player-1-returnMove'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('training-player-flow-action-player-1-overlap'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('training-player-flow-action-player-1-pass')),
      findsNothing,
    );
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

  testWidgets('initial sketch title input keeps usable width in landscape', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);

    await tester.pumpWidget(
      _buildApp(
        const TrainingMethodBoardScreen(
          boardTitle: '패스 워밍업',
          initialLayoutJson: '',
          presets: <TrainingBoardPreset>[
            TrainingBoardPreset(
              title: '기본',
              subtitle: '',
              layoutJson: '',
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester
        .tap(find.byKey(const ValueKey('training-landscape-topbar-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('스케치명 수정').last);
    await tester.pumpAndSettle();

    expect(find.text('스케치명 수정'), findsOneWidget);
    final fieldRect = tester.getRect(find.byType(TextFormField));
    expect(fieldRect.width, greaterThanOrEqualTo(280));
    expect(fieldRect.width, lessThanOrEqualTo(420));
  });

  testWidgets('sketch screen starts portrait and toggles orientation both ways',
      (
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

    expect(
      find.byKey(const ValueKey('training-portrait-inspector-panel')),
      findsOneWidget,
    );
    expect(
      platformCalls.where(
        (call) => call.method == 'SystemChrome.setPreferredOrientations',
      ),
      isEmpty,
    );

    await tester.tap(
      find.byKey(const ValueKey('training-sketch-orientation-button')),
    );
    await tester.pumpAndSettle();
    final landscapeOrientationCall = platformCalls.lastWhere(
      (call) => call.method == 'SystemChrome.setPreferredOrientations',
    );
    final landscapeArguments = '${landscapeOrientationCall.arguments}';
    expect(landscapeArguments, contains('landscapeLeft'));
    expect(landscapeArguments, contains('landscapeRight'));

    tester.view.physicalSize = const Size(1000, 720);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('training-landscape-control-panel')),
      findsOneWidget,
    );

    platformCalls.clear();
    await tester.tap(
      find.byKey(const ValueKey('training-sketch-orientation-button')),
    );
    await tester.pumpAndSettle();
    final portraitOrientationCall = platformCalls.lastWhere(
      (call) => call.method == 'SystemChrome.setPreferredOrientations',
    );
    final portraitArguments = '${portraitOrientationCall.arguments}';
    expect(portraitArguments, contains('portraitUp'));
    expect(portraitArguments, contains('portraitDown'));

    tester.view.physicalSize = const Size(430, 900);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('training-portrait-inspector-panel')),
      findsOneWidget,
    );
  });

  testWidgets('selected player can add actions to global sketch stages', (
    WidgetTester tester,
  ) async {
    _setLandscapeSurface(tester);
    String? savedLayout;

    await tester.pumpWidget(
      _buildApp(
        TrainingMethodBoardScreen(
          boardTitle: '전체 단계',
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
                  TrainingMethodItem(
                    id: 'player-2',
                    type: 'player',
                    x: 0.48,
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
      find
          .descendant(of: boardFinder, matching: find.byIcon(Icons.person))
          .first,
    );
    await tester.pumpAndSettle();

    expect(find.text('전체 단계'), findsWidgets);
    await _tapVisibleOutlinedButton(tester, '패스');
    await _tapBoardRelativeThroughWidgets(
      tester,
      boardFinder,
      const Offset(0.48, 0.42),
    );

    expect(find.text('1단계 · 액션 1개'), findsOneWidget);
    expect(find.text('사람 1에서 사람 2로 공 이동'), findsOneWidget);
    expect(find.text('공 소유 관계'), findsOneWidget);
    expect(find.text('공 1: 사람 2 보유'), findsOneWidget);
    final addNextAction = find.byWidgetPredicate((widget) {
      final key = widget.key;
      return key is ValueKey<String> &&
          key.value.startsWith('training-global-stage-action-add-next-');
    });
    expect(addNextAction, findsNothing);
    await _tapVisibleOutlinedButton(tester, '슈팅');
    await _tapBoardRelative(tester, boardFinder, const Offset(0.82, 0.34));

    expect(find.text('2단계 · 액션 1개'), findsOneWidget);
    expect(find.text('사람 2 공 이동'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final actionStages = saved.pages.single.routes
        .where((route) => route.actorItemId != null)
        .map((route) => route.stageIndex)
        .toList(growable: false);

    expect(actionStages, containsAll(<int>[1, 2]));
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

  testWidgets('player can keep adding move actions after panels change', (
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

    await tester.tap(playerFinder);
    await tester.pumpAndSettle();
    await _tapVisibleOutlinedButton(tester, '이동');
    await _tapTopBarMenuItem(
      tester,
      isLandscape: true,
      itemKey: 'training-topbar-menu-controls',
    );

    await _tapBoardRelative(tester, boardFinder, const Offset(0.43, 0.32));
    await _tapTopBarMenuItem(
      tester,
      isLandscape: true,
      itemKey: 'training-topbar-menu-controls',
    );
    await _tapVisibleOutlinedButton(tester, '이동');
    await _tapBoardRelative(tester, boardFinder, const Offset(0.52, 0.39));

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final routes = saved.pages.single.routes;
    final route = routes.last;
    expect(routes, hasLength(1));
    expect(route.linkedItemId, 'player-1');
    expect(route.points, hasLength(3));
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
      await _tapVisibleOutlinedButton(tester, '이동');
      await _tapBoardRelative(tester, boardFinder, const Offset(0.29, 0.16));

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

  testWidgets('playback keeps the selected player next action panel', (
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
    await tester.tap(
      find.descendant(
        of: boardFinder,
        matching: find.byIcon(Icons.person),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('training-player-next-action-player-1')),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(Icons.play_circle_outline).first);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('training-player-next-action-player-1')),
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

Future<void> _tapRouteStageChip(WidgetTester tester, int stageIndex) async {
  final chipFinder = find.byWidgetPredicate((widget) {
    if (widget is! ChoiceChip) return false;
    final label = widget.label;
    return label is Text && label.data == '$stageIndex단계';
  });
  expect(chipFinder, findsWidgets);
  final targetChip = chipFinder.last;
  await tester.ensureVisible(targetChip);
  await tester.pumpAndSettle();
  await tester.tap(targetChip);
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
  Future<bool> tapIfPresent(Finder finder) async {
    if (finder.evaluate().isEmpty) return false;
    final target = finder.last;
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
    return true;
  }

  final finder = find.widgetWithText(OutlinedButton, label);
  if (await tapIfPresent(finder)) return;

  if (await tapIfPresent(find.text(label))) return;

  expect(find.text(label), findsOneWidget);
}

Future<void> _tapVisibleFinder(WidgetTester tester, Finder finder) async {
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
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
