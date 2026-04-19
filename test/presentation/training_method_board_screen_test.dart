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

  testWidgets('adding multiple player routes keeps previous routes', (
    WidgetTester tester,
  ) async {
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

    await tester.tap(find.byKey(const ValueKey('training-path-mode-button')));
    await tester.pumpAndSettle();

    final boardFinder = find.byKey(const ValueKey('training-board-canvas'));

    await _drawRoute(
      tester,
      boardFinder,
      const Offset(80, 220),
      const Offset(200, 160),
    );
    await _drawRoute(
      tester,
      boardFinder,
      const Offset(120, 260),
      const Offset(260, 240),
    );

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final routes = saved.pages.single.routes;
    expect(
      routes.where((route) => route.kind == TrainingMethodRouteKind.player),
      hasLength(2),
    );
    expect(routes.every((route) => route.linkedItemId?.isNotEmpty == true),
        isTrue);
  });

  testWidgets('selected route can be deleted without clearing others', (
    WidgetTester tester,
  ) async {
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
              y: 0.5,
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
              linkedItemId: 'player-1',
              points: <TrainingMethodPoint>[
                TrainingMethodPoint(x: 0.22, y: 0.55),
                TrainingMethodPoint(x: 0.62, y: 0.7),
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

    await tester.tap(find.byKey(const ValueKey('training-path-mode-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('사람 2'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, '선택 이동선 삭제'));
    await tester.pumpAndSettle();

    expect(find.text('사람 2'), findsNothing);

    await tester.tap(find.widgetWithText(TextButton, '저장'));
    await tester.pumpAndSettle();

    final saved = TrainingMethodLayout.decode(savedLayout ?? '');
    final routes = saved.pages.single.routes;
    expect(
      routes.where((route) => route.kind == TrainingMethodRouteKind.player),
      hasLength(1),
    );
  });
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
