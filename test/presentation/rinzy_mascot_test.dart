import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/presentation/widgets/rinzy_mascot.dart';

void main() {
  testWidgets('challenge Rinzy widgets use challenge-specific assets', (
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

    final imageAssets = tester
        .widgetList<Image>(find.byType(Image))
        .map((image) => (image.image as AssetImage).assetName);

    expect(imageAssets, contains(ChallengeRinzyMascot.assetPath));
    expect(imageAssets, contains(ChallengeCheerRinzyMascot.assetPath));
    expect(imageAssets, contains(ChallengeSadRinzyMascot.assetPath));
    expect(imageAssets, isNot(contains(RinzyMascot.assetPath)));
  });
}
