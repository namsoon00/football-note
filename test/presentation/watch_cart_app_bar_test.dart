import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/theme/app_theme.dart';
import 'package:football_note/presentation/widgets/watch_cart/main_app_bar.dart';

void main() {
  testWidgets('top actions stay visible on narrow Android widths', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko', 'KR'),
        theme: AppTheme.light(),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('ko', 'KR')],
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: WatchCartAppBar(
                leadingIcon: Icons.arrow_back_rounded,
                onNewsTap: () {},
                newsBadgeCount: 3,
                onQuizTap: () {},
                onMatchTap: () {},
                onProfileTap: () {},
                onNotificationTap: () {},
                notificationBadgeCount: 2,
                onSettingsTap: () {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.newspaper_outlined), findsOneWidget);
    expect(find.byIcon(Icons.quiz_outlined), findsOneWidget);
    expect(find.byIcon(Icons.more_horiz), findsNothing);
  });
}
