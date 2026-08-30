import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/health_connect_privacy_screen.dart';

void main() {
  testWidgets('shows localized Health Connect data-use details',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: HealthConnectPrivacyScreen(),
      ),
    );

    expect(find.text('Health Connect 데이터 이용 안내'), findsOneWidget);
    expect(find.text('읽는 데이터'), findsOneWidget);
    expect(find.text('허용하는 출처'), findsOneWidget);
    expect(find.text('저장 위치'), findsOneWidget);
    expect(find.text('사용 목적'), findsOneWidget);
    expect(find.text('사용자 제어'), findsOneWidget);
  });
}
