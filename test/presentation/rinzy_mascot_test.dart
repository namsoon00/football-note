import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/presentation/widgets/rinzy_mascot.dart';

void main() {
  testWidgets('home Rinzy widgets use painted giraffe characters', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Row(
          children: [
            RinzyMascot(size: 64, animate: false),
            CheerRinzyMascot(size: 64, animate: false),
            SadRinzyMascot(size: 64),
          ],
        ),
      ),
    );

    expect(find.byType(Image), findsNothing);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('challenge Rinzy widgets use painted challenge characters', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Row(
          children: [
            ChallengeRinzyMascot(size: 64, animate: false),
            ChallengeCheerRinzyMascot(size: 64, animate: false),
            ChallengeSadRinzyMascot(size: 64, animate: false),
          ],
        ),
      ),
    );

    expect(find.byType(Image), findsNothing);
    expect(find.byKey(const ValueKey('challenge-rinzy-ready')), findsOneWidget);
    expect(find.byKey(const ValueKey('challenge-rinzy-cheer')), findsOneWidget);
    expect(find.byKey(const ValueKey('challenge-rinzy-sad')), findsOneWidget);
  });
}
