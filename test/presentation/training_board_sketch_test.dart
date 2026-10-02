import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/presentation/models/training_method_layout.dart';
import 'package:football_note/presentation/widgets/training_board_sketch.dart';

void main() {
  testWidgets('legacy template players use team-local fallback numbers', (
    WidgetTester tester,
  ) async {
    const page = TrainingMethodPage(
      name: 'Board',
      items: <TrainingMethodItem>[
        TrainingMethodItem(type: 'player', x: 0.15, y: 0.25, teamId: 'A'),
        TrainingMethodItem(type: 'player', x: 0.35, y: 0.25, teamId: 'A'),
        TrainingMethodItem(type: 'player', x: 0.65, y: 0.25, teamId: 'B'),
        TrainingMethodItem(type: 'player', x: 0.85, y: 0.25, teamId: 'B'),
      ],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 220,
            child: TrainingBoardSketch(page: page),
          ),
        ),
      ),
    );

    expect(find.text('A1'), findsOneWidget);
    expect(find.text('A2'), findsOneWidget);
    expect(find.text('B1'), findsOneWidget);
    expect(find.text('B2'), findsOneWidget);
  });
}
