import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/welcome_screen.dart';

void main() {
  testWidgets('welcome screen presents polished guide and starts', (
    WidgetTester tester,
  ) async {
    var started = false;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko', 'KR'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: WelcomeScreen(onStart: () => started = true),
      ),
    );

    expect(find.text('태오의 노트'), findsOneWidget);
    expect(find.text('축구 하루를 차분한 노트로 정리해요'), findsOneWidget);
    expect(find.text('홈'), findsWidgets);
    expect(find.text('첫 탭'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('welcome-section-logs')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('훈련기록'), findsWidgets);
    expect(find.text('기록 추가'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('welcome-start-button')));

    expect(started, isTrue);
  });
}
