import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/weather_shared_resource.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:football_note/presentation/screens/weather_detail_screen.dart';
import 'package:football_note/presentation/theme/app_theme.dart';

import '../helpers/test_asset_bundle.dart';

void main() {
  setUp(WeatherSharedResource.debugClearCache);
  tearDown(WeatherSharedResource.debugClearCache);

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
            initialLocation: '강남구 역삼1동',
            initialSummary: '맑음 21°C',
            initialWeatherCode: 0,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('날씨'), findsOneWidget);
    expect(find.text('강남구 역삼1동'), findsOneWidget);
    expect(find.text('21°C'), findsOneWidget);
    expect(find.text('맑음'), findsOneWidget);
    expect(find.text('어제 대비'), findsOneWidget);
    expect(find.text('대기질'), findsNothing);
    expect(find.text('미세먼지'), findsOneWidget);
    expect(find.text('초미세먼지'), findsOneWidget);
    expect(find.text('야외 활동 가이드'), findsNothing);
    expect(find.text('AQI'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Weather outfit guide uses compact themed layout', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: TestAssetBundle(),
        child: MaterialApp(
          locale: const Locale('ko', 'KR'),
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.dark,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('ko', 'KR')],
          home: const WeatherDetailScreen(
            initialLocation: '강남구 역삼1동',
            initialSummary: '맑음 21°C',
            initialWeatherCode: 0,
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('복장'));
    await tester.pumpAndSettle();

    expect(find.text('오늘의 운동 복장'), findsAtLeastNWidgets(1));
    expect(find.text('상의 조합'), findsOneWidget);
    expect(find.text('겉옷'), findsOneWidget);
    expect(find.text('하의'), findsOneWidget);
    expect(find.text('준비물'), findsOneWidget);
    expect(find.text('주의 포인트'), findsOneWidget);
    expect(find.text('모든 복장 케이스 보기'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Weekly forecast shows temperature beside status and PM2.5', (
    WidgetTester tester,
  ) async {
    WeatherSharedResource.primeSnapshot(
      WeatherSharedSnapshot(
        location: '강남구 역삼1동',
        localeTag: 'ko-KR',
        fetchedAt: DateTime.now(),
        summary: '맑음',
        weatherCode: 0,
        temperature: 21,
        dailyForecasts: [
          WeatherSharedDailyForecast(
            date: DateTime(2026, 5, 5),
            summary: '대체로 맑음',
            weatherCode: 0,
            temperatureMax: 25,
            temperatureMin: 14,
            precipitationSum: 1.2,
            windSpeedMax: 5.5,
            pm10: 42,
            pm25: 18,
          ),
        ],
      ),
    );

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
            initialLocation: '강남구 역삼1동',
            initialSummary: '맑음 21°C',
            initialWeatherCode: 0,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('주간'));
    await tester.pumpAndSettle();

    expect(find.text('주간 날씨'), findsAtLeastNWidgets(1));
    expect(find.text('대체로 맑음'), findsOneWidget);
    expect(find.text('25°C / 14°C'), findsOneWidget);
    expect(find.textContaining('미세먼지 42'), findsOneWidget);
    expect(find.textContaining('초미세먼지 18'), findsOneWidget);

    final summaryTopLeft = tester.getTopLeft(find.text('대체로 맑음'));
    final rangeTopLeft = tester.getTopLeft(find.text('25°C / 14°C'));
    expect(rangeTopLeft.dx, greaterThan(summaryTopLeft.dx));
    expect((rangeTopLeft.dy - summaryTopLeft.dy).abs(), lessThan(32));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Hourly precipitation is hidden when rain is not forecast', (
    WidgetTester tester,
  ) async {
    WeatherSharedResource.primeSnapshot(
      WeatherSharedSnapshot(
        location: '강남구 역삼1동',
        localeTag: 'ko-KR',
        fetchedAt: DateTime.now(),
        summary: '맑음',
        weatherCode: 0,
        temperature: 21,
        dailyForecasts: [
          WeatherSharedDailyForecast(
            date: DateTime(2026, 5, 5),
            summary: '맑음',
            weatherCode: 0,
            precipitationSum: 0,
            hourlyPrecipitations: [
              WeatherSharedHourlyPrecipitation(
                time: DateTime(2026, 5, 5, 9),
                precipitation: 0,
              ),
              WeatherSharedHourlyPrecipitation(
                time: DateTime(2026, 5, 5, 10),
                precipitation: 0,
              ),
            ],
          ),
        ],
      ),
    );

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
            initialLocation: '강남구 역삼1동',
            initialSummary: '맑음 21°C',
            initialWeatherCode: 0,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('시간별 비 타임라인'), findsNothing);
    expect(find.text('09:00'), findsNothing);
    expect(find.text('10:00'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Hourly precipitation keeps hours before the first rainy hour', (
    WidgetTester tester,
  ) async {
    WeatherSharedResource.primeSnapshot(
      WeatherSharedSnapshot(
        location: '강남구 역삼1동',
        localeTag: 'ko-KR',
        fetchedAt: DateTime.now(),
        summary: '비',
        weatherCode: 61,
        temperature: 18,
        dailyForecasts: [
          WeatherSharedDailyForecast(
            date: DateTime(2026, 5, 5),
            summary: '비',
            weatherCode: 61,
            precipitationSum: 0.5,
            hourlyPrecipitations: [
              WeatherSharedHourlyPrecipitation(
                time: DateTime(2026, 5, 5, 9),
                precipitation: 0,
              ),
              WeatherSharedHourlyPrecipitation(
                time: DateTime(2026, 5, 5, 10),
                precipitation: 0,
              ),
              WeatherSharedHourlyPrecipitation(
                time: DateTime(2026, 5, 5, 11),
                precipitation: 0.5,
              ),
              WeatherSharedHourlyPrecipitation(
                time: DateTime(2026, 5, 5, 12),
                precipitation: 0,
              ),
            ],
          ),
        ],
      ),
    );

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
            initialLocation: '강남구 역삼1동',
            initialSummary: '비 18°C',
            initialWeatherCode: 61,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('시간별 비 타임라인'), findsOneWidget);
    expect(find.text('09:00'), findsOneWidget);
    expect(find.text('10:00'), findsOneWidget);
    expect(find.text('11:00'), findsAtLeastNWidgets(1));
    expect(find.textContaining('0.5'), findsAtLeastNWidgets(1));
    expect(find.textContaining('조금 와요'), findsAtLeastNWidgets(1));
    expect(find.textContaining('0.0'), findsAtLeastNWidgets(1));
    expect(find.textContaining('안 와요'), findsAtLeastNWidgets(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Hourly weather keeps all hours and focuses current hour', (
    WidgetTester tester,
  ) async {
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final firstHour = todayDate.add(Duration(hours: now.hour - 6));
    String hourLabel(DateTime value) =>
        '${value.hour.toString().padLeft(2, '0')}:00';

    WeatherSharedResource.primeSnapshot(
      WeatherSharedSnapshot(
        location: '강남구 역삼1동',
        localeTag: 'ko-KR',
        fetchedAt: now,
        summary: '맑음',
        weatherCode: 0,
        temperature: 21,
        dailyForecasts: [
          WeatherSharedDailyForecast(
            date: todayDate,
            summary: '맑음',
            weatherCode: 0,
            temperatureMax: 26,
            temperatureMin: 15,
            hourlyForecasts: [
              for (var index = 0; index < 24; index++)
                WeatherSharedForecastMoment(
                  time: firstHour.add(Duration(hours: index)),
                  temperature: 15 + index.toDouble(),
                  weatherCode: 0,
                ),
            ],
          ),
        ],
      ),
    );

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
            initialLocation: '강남구 역삼1동',
            initialSummary: '맑음 21°C',
            initialWeatherCode: 0,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('시간별 날씨'), findsOneWidget);
    expect(find.text(hourLabel(firstHour)), findsOneWidget);
    expect(
      find.text(hourLabel(todayDate.add(Duration(hours: now.hour)))),
      findsOneWidget,
    );

    final horizontalScrollViewFinder = find.byWidgetPredicate(
      (widget) =>
          widget is SingleChildScrollView &&
          widget.scrollDirection == Axis.horizontal,
    );
    expect(horizontalScrollViewFinder, findsOneWidget);
    final horizontalScrollView = tester.widget<SingleChildScrollView>(
      horizontalScrollViewFinder,
    );
    expect(horizontalScrollView.controller, isNotNull);
    expect(horizontalScrollView.controller!.offset, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Hourly weather continues into the next day', (
    WidgetTester tester,
  ) async {
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final tomorrow = todayDate.add(const Duration(days: 1));

    WeatherSharedResource.primeSnapshot(
      WeatherSharedSnapshot(
        location: '강남구 역삼1동',
        localeTag: 'ko-KR',
        fetchedAt: now,
        summary: '맑음',
        weatherCode: 0,
        temperature: 21,
        dailyForecasts: [
          WeatherSharedDailyForecast(
            date: todayDate,
            summary: '맑음',
            weatherCode: 0,
            temperatureMax: 25,
            temperatureMin: 16,
            hourlyForecasts: [
              WeatherSharedForecastMoment(
                time: todayDate.add(const Duration(hours: 23)),
                temperature: 19,
                weatherCode: 1,
              ),
            ],
          ),
          WeatherSharedDailyForecast(
            date: tomorrow,
            summary: '흐림',
            weatherCode: 3,
            temperatureMax: 24,
            temperatureMin: 18,
            hourlyForecasts: [
              WeatherSharedForecastMoment(
                time: tomorrow,
                temperature: 18,
                weatherCode: 3,
              ),
              WeatherSharedForecastMoment(
                time: tomorrow.add(const Duration(hours: 1)),
                temperature: 18.5,
                weatherCode: 3,
              ),
            ],
          ),
        ],
      ),
    );

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
            initialLocation: '강남구 역삼1동',
            initialSummary: '맑음 21°C',
            initialWeatherCode: 0,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('시간별 날씨'), findsOneWidget);
    expect(find.text('23:00'), findsOneWidget);
    expect(find.text('00:00'), findsOneWidget);
    expect(find.text('01:00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Hourly precipitation labels only appear when severity changes', (
    WidgetTester tester,
  ) async {
    WeatherSharedResource.primeSnapshot(
      WeatherSharedSnapshot(
        location: '강남구 역삼1동',
        localeTag: 'ko-KR',
        fetchedAt: DateTime.now(),
        summary: '비',
        weatherCode: 61,
        temperature: 18,
        dailyForecasts: [
          WeatherSharedDailyForecast(
            date: DateTime(2026, 5, 5),
            summary: '비',
            weatherCode: 61,
            precipitationSum: 3.6,
            hourlyPrecipitations: [
              WeatherSharedHourlyPrecipitation(
                time: DateTime(2026, 5, 5, 11),
                precipitation: 0.5,
              ),
              WeatherSharedHourlyPrecipitation(
                time: DateTime(2026, 5, 5, 12),
                precipitation: 0.8,
              ),
              WeatherSharedHourlyPrecipitation(
                time: DateTime(2026, 5, 5, 13),
                precipitation: 1.2,
              ),
              WeatherSharedHourlyPrecipitation(
                time: DateTime(2026, 5, 5, 14),
                precipitation: 1.1,
              ),
              WeatherSharedHourlyPrecipitation(
                time: DateTime(2026, 5, 5, 15),
                precipitation: 0,
              ),
            ],
          ),
        ],
      ),
    );

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
            initialLocation: '강남구 역삼1동',
            initialSummary: '비 18°C',
            initialWeatherCode: 61,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('시간별 비 타임라인'), findsOneWidget);
    expect(find.text('11:00'), findsAtLeastNWidgets(1));
    expect(find.text('12:00'), findsAtLeastNWidgets(1));
    expect(find.text('13:00'), findsAtLeastNWidgets(1));
    expect(find.text('14:00'), findsAtLeastNWidgets(1));
    expect(find.text('15:00'), findsAtLeastNWidgets(1));
    expect(find.textContaining('0.5'), findsOneWidget);
    expect(find.textContaining('0.8'), findsNothing);
    expect(find.textContaining('1.1'), findsNothing);
    expect(find.textContaining('0.0'), findsOneWidget);
    expect(find.textContaining('조금 와요'), findsOneWidget);
    expect(find.textContaining('안 와요'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Hourly precipitation shows daily total and amount severity', (
    WidgetTester tester,
  ) async {
    WeatherSharedResource.primeSnapshot(
      WeatherSharedSnapshot(
        location: '강남구 역삼1동',
        localeTag: 'ko-KR',
        fetchedAt: DateTime.now(),
        summary: '비',
        weatherCode: 61,
        temperature: 18,
        dailyForecasts: [
          WeatherSharedDailyForecast(
            date: DateTime(2026, 5, 5),
            summary: '비',
            weatherCode: 61,
            precipitationSum: 3,
            precipitationProbabilityMax: 85,
            hourlyPrecipitations: [
              WeatherSharedHourlyPrecipitation(
                time: DateTime(2026, 5, 5, 14),
                precipitation: 0,
                precipitationProbability: 20,
              ),
              WeatherSharedHourlyPrecipitation(
                time: DateTime(2026, 5, 5, 15),
                precipitation: 1.2,
                precipitationProbability: 80,
              ),
            ],
          ),
        ],
      ),
    );

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
            initialLocation: '강남구 역삼1동',
            initialSummary: '비 18°C',
            initialWeatherCode: 61,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('비 체크'), findsNothing);
    expect(find.text('강수확률'), findsAtLeastNWidgets(1));
    expect(find.text('85%'), findsAtLeastNWidgets(1));
    expect(find.textContaining('3.0'), findsAtLeastNWidgets(1));
    expect(find.text('15:00'), findsAtLeastNWidgets(1));
    expect(find.textContaining('1.2'), findsAtLeastNWidgets(1));
    expect(find.textContaining('가볍게 와요'), findsAtLeastNWidgets(1));
    expect(find.textContaining('미끄러운 그라운드'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tomorrow forecast uses the same hourly weather format as today',
      (
    WidgetTester tester,
  ) async {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final tomorrow = todayDate.add(const Duration(days: 1));
    WeatherSharedResource.primeSnapshot(
      WeatherSharedSnapshot(
        location: '강남구 역삼1동',
        localeTag: 'ko-KR',
        fetchedAt: DateTime.now(),
        summary: '맑음',
        weatherCode: 0,
        temperature: 21,
        dailyForecasts: [
          WeatherSharedDailyForecast(
            date: todayDate,
            summary: '맑음',
            weatherCode: 0,
            temperatureMax: 24,
            temperatureMin: 18,
          ),
          WeatherSharedDailyForecast(
            date: tomorrow,
            summary: '비',
            weatherCode: 61,
            temperatureMax: 22,
            temperatureMin: 17,
            precipitationSum: 1.2,
            precipitationProbabilityMax: 70,
            windSpeedMax: 6,
            pm10: 30,
            pm25: 12,
            hourlyForecasts: [
              WeatherSharedForecastMoment(
                time: tomorrow.add(const Duration(hours: 9)),
                temperature: 18,
                weatherCode: 3,
              ),
              WeatherSharedForecastMoment(
                time: tomorrow.add(const Duration(hours: 12)),
                temperature: 22,
                weatherCode: 61,
              ),
            ],
            hourlyPrecipitations: [
              WeatherSharedHourlyPrecipitation(
                time: tomorrow.add(const Duration(hours: 14)),
                precipitation: 1.2,
              ),
              WeatherSharedHourlyPrecipitation(
                time: tomorrow.add(const Duration(hours: 15)),
                precipitation: 0,
              ),
            ],
          ),
        ],
      ),
    );

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
            initialLocation: '강남구 역삼1동',
            initialSummary: '맑음 21°C',
            initialWeatherCode: 0,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('내일'));
    await tester.pumpAndSettle();

    expect(find.text('내일 상세 날씨'), findsAtLeastNWidgets(1));
    expect(find.text('22°C'), findsAtLeastNWidgets(1));
    expect(find.text('비'), findsAtLeastNWidgets(1));
    expect(find.text('날씨 상태'), findsNothing);
    expect(find.text('시간별 날씨'), findsOneWidget);
    expect(find.text('시간대별 기온'), findsNothing);
    expect(find.text('시간별 비 타임라인'), findsNothing);
    expect(find.text('09:00'), findsOneWidget);
    expect(find.text('12:00'), findsOneWidget);
    expect(find.text('14:00'), findsAtLeastNWidgets(1));
    expect(find.text('15:00'), findsAtLeastNWidgets(1));
    expect(find.textContaining('1.2'), findsAtLeastNWidgets(1));
    expect(find.textContaining('가볍게 와요'), findsAtLeastNWidgets(1));
    expect(find.textContaining('안 와요'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tomorrow hot outfit previews do not recommend a vest', (
    WidgetTester tester,
  ) async {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final tomorrow = todayDate.add(const Duration(days: 1));
    WeatherSharedResource.primeSnapshot(
      WeatherSharedSnapshot(
        location: '강남구 역삼1동',
        localeTag: 'ko-KR',
        fetchedAt: DateTime.now(),
        summary: '맑음',
        weatherCode: 0,
        temperature: 26,
        dailyForecasts: [
          WeatherSharedDailyForecast(
            date: todayDate,
            summary: '맑음',
            weatherCode: 0,
            temperatureMax: 27,
            temperatureMin: 21,
          ),
          WeatherSharedDailyForecast(
            date: tomorrow,
            summary: '더움',
            weatherCode: 0,
            temperatureMax: 32,
            temperatureMin: 25,
            morningForecast: WeatherSharedForecastMoment(
              time: tomorrow.add(const Duration(hours: 9)),
              temperature: 28,
              weatherCode: 0,
              windSpeed: 2,
            ),
            eveningForecast: WeatherSharedForecastMoment(
              time: tomorrow.add(const Duration(hours: 18)),
              temperature: 31,
              weatherCode: 0,
              windSpeed: 2,
            ),
          ),
        ],
      ),
    );

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
            initialLocation: '강남구 역삼1동',
            initialSummary: '맑음 26°C',
            initialWeatherCode: 0,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('내일'));
    await tester.pumpAndSettle();

    expect(find.text('내일 추천 복장'), findsOneWidget);
    expect(find.text('겉옷 없음'), findsWidgets);
    expect(find.text('얇은 조끼(선택)'), findsNothing);
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
            initialLocation: '강남구 역삼1동',
            initialSummary: '비 12°C',
            initialWeatherCode: 61,
            initialAction: WeatherDetailInitialAction.outfitGuide,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('오늘의 운동 복장'), findsAtLeastNWidgets(1));
    expect(find.text('상의 조합'), findsOneWidget);
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
            initialLocation: '강남구 역삼1동',
            initialSummary: '맑음 6°C',
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
