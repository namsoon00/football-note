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
    expect(find.text('21.0°C'), findsOneWidget);
    expect(find.text('맑음'), findsOneWidget);
    expect(find.text('어제 대비'), findsOneWidget);
    expect(find.text('대기질'), findsOneWidget);
    expect(find.text('미세먼지'), findsOneWidget);
    expect(find.text('초미세먼지'), findsOneWidget);
    expect(find.text('야외 활동 가이드'), findsNothing);
    expect(find.text('AQI'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Initial outfit action opens outfit sheet', (
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
            initialSummary: '비 12.0°C',
            initialWeatherCode: 61,
            initialAction: WeatherDetailInitialAction.outfitGuide,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('오늘의 축구 복장'), findsAtLeastNWidgets(1));
    expect(find.text('레이어'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('All outfit cases screen shows detailed cold outfit card', (
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
            initialSummary: '맑음 6.0°C',
            initialWeatherCode: 0,
            initialAction: WeatherDetailInitialAction.outfitGuide,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.ensureVisible(find.text('모든 복장 케이스 보기'));
    await tester.tap(find.text('모든 복장 케이스 보기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('전체 복장 케이스'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('추운 날'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('추운 날'), findsOneWidget);
    expect(find.text('긴 트레이닝 팬츠'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
