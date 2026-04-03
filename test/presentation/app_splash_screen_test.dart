import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/presentation/screens/app_splash_screen.dart';

import '../helpers/test_asset_bundle.dart';

void main() {
  testWidgets('AppSplashScreen renders tunnel-to-pitch splash and completes', (
    tester,
  ) async {
    var completed = false;

    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: TestAssetBundle(),
        child: MaterialApp(
          locale: const Locale('ko', 'KR'),
          home: AppSplashScreen(onCompleted: () => completed = true),
        ),
      ),
    );

    expect(find.byType(AppSplashScreen), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);

    await tester.pump(const Duration(milliseconds: 2200));

    expect(completed, isTrue);
  });
}
