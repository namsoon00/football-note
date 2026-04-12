import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/weather_detail_screen.dart';

import '../helpers/test_asset_bundle.dart';

void main() {
  testWidgets('Weather detail header renders without layout exceptions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: TestAssetBundle(),
        child: const MaterialApp(
          locale: Locale('ko', 'KR'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('en'), Locale('ko', 'KR')],
          home: WeatherDetailScreen(
            initialLocation: '강남구 역삼1동, 한국',
            initialSummary: '맑음 21.0°C',
            initialWeatherCode: 0,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('상세 날씨'), findsOneWidget);
    expect(find.text('강남구 역삼1동, 한국'), findsOneWidget);
    expect(find.text('맑음 21.0°C'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
