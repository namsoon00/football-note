import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/korean_air_quality_service.dart';
import 'package:football_note/application/weather_current_service.dart';
import 'package:football_note/application/weather_shared_resource.dart';
import 'package:football_note/gen/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(WeatherSharedResource.debugClearCache);

  group('WeatherSharedResource', () {
    test('composeSnapshot builds reusable shared weather payload', () async {
      const locale = Locale('ko', 'KR');
      final l10n = await AppLocalizations.delegate.load(locale);
      final snapshot = WeatherSharedResource.composeSnapshot(
        location: '잠실보조구장',
        locale: locale,
        fetchedAt: DateTime(2026, 4, 26, 9),
        l10n: l10n,
        weatherSnapshot: WeatherDetailsSnapshot(
          provider: WeatherDataProvider.openMeteo,
          temperature: 21.4,
          weatherCode: 61,
          apparentTemperature: 19.8,
          humidity: 58,
          precipitation: 1.5,
          windSpeed: 3.2,
          temperatureMax: 24,
          temperatureMin: 16,
          dailyForecasts: <WeatherDailyForecast>[
            WeatherDailyForecast(
              date: DateTime(2026, 4, 26),
              weatherCode: 61,
              temperatureMax: 24,
              temperatureMin: 16,
              precipitationSum: 3.4,
              windSpeedMax: 5.2,
              uvIndexMax: 4.6,
              morningForecast: WeatherForecastMoment(
                time: DateTime(2026, 4, 26, 9),
                temperature: 18.5,
                weatherCode: 3,
                precipitation: 0.2,
                windSpeed: 2.4,
              ),
              eveningForecast: WeatherForecastMoment(
                time: DateTime(2026, 4, 26, 18),
                temperature: 20.1,
                weatherCode: 61,
                precipitation: 1.1,
                windSpeed: 3.5,
              ),
              hourlyPrecipitations: <WeatherHourlyPrecipitation>[
                WeatherHourlyPrecipitation(
                  time: DateTime(2026, 4, 26, 12),
                  precipitation: 0.7,
                ),
              ],
            ),
          ],
        ),
        airQualitySnapshot: const AirQualitySnapshot(
          pm10: 31,
          pm25: 14,
          aqi: 82,
          scale: AirQualityScale.khai,
        ),
        yesterdayTemperature: 18.0,
      );

      expect(snapshot.location, '잠실보조구장');
      expect(snapshot.summary, '${l10n.weatherLabelRain} 21°C');
      expect(snapshot.weatherCode, 61);
      expect(snapshot.temperatureDeltaFromYesterday, closeTo(3.4, 0.001));
      expect(snapshot.airQualityScale, AirQualityScale.khai);
      expect(snapshot.dailyForecasts, hasLength(1));
      expect(snapshot.dailyForecasts.first.summary, l10n.weatherLabelRain);
      expect(snapshot.dailyForecasts.first.morningForecast?.weatherCode, 3);
      expect(
        snapshot.dailyForecasts.first.hourlyPrecipitations.single.precipitation,
        0.7,
      );
    });

    test('cachedSnapshot honors locale and ttl', () async {
      const locale = Locale('ko', 'KR');
      final l10n = await AppLocalizations.delegate.load(locale);
      final freshSnapshot = WeatherSharedResource.composeSnapshot(
        location: '탄천',
        locale: locale,
        fetchedAt: DateTime.now(),
        l10n: l10n,
        weatherSnapshot: const WeatherDetailsSnapshot(
          provider: WeatherDataProvider.openMeteo,
          temperature: 17,
          weatherCode: 0,
        ),
        airQualitySnapshot: const AirQualitySnapshot(),
      );
      WeatherSharedResource.primeSnapshot(freshSnapshot);

      expect(
        WeatherSharedResource.cachedSnapshot(locale: locale)?.summary,
        freshSnapshot.summary,
      );
      expect(
        WeatherSharedResource.cachedSnapshot(locale: const Locale('en')),
        isNull,
      );

      final staleSnapshot = WeatherSharedResource.composeSnapshot(
        location: '탄천',
        locale: locale,
        fetchedAt: DateTime.now().subtract(
          WeatherSharedResource.cacheTtl + const Duration(seconds: 1),
        ),
        l10n: l10n,
        weatherSnapshot: const WeatherDetailsSnapshot(
          provider: WeatherDataProvider.openMeteo,
          temperature: 17,
          weatherCode: 0,
        ),
        airQualitySnapshot: const AirQualitySnapshot(),
      );
      WeatherSharedResource.primeSnapshot(staleSnapshot);

      expect(WeatherSharedResource.cachedSnapshot(locale: locale), isNull);
    });
  });
}
