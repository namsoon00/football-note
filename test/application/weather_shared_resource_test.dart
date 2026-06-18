import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/korean_air_quality_service.dart';
import 'package:football_note/application/weather_current_service.dart';
import 'package:football_note/application/weather_shared_resource.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

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
              precipitationProbabilityMax: 80,
              windSpeedMax: 5.2,
              uvIndexMax: 4.6,
              morningForecast: WeatherForecastMoment(
                time: DateTime(2026, 4, 26, 9),
                temperature: 18.5,
                weatherCode: 3,
                precipitation: 0.2,
                precipitationProbability: 30,
                windSpeed: 2.4,
              ),
              eveningForecast: WeatherForecastMoment(
                time: DateTime(2026, 4, 26, 18),
                temperature: 20.1,
                weatherCode: 61,
                precipitation: 1.1,
                precipitationProbability: 80,
                windSpeed: 3.5,
              ),
              hourlyPrecipitations: <WeatherHourlyPrecipitation>[
                WeatherHourlyPrecipitation(
                  time: DateTime(2026, 4, 26, 12),
                  precipitation: 0.7,
                  precipitationProbability: 65,
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
        dailyAirQualityForecasts: <WeatherSharedDailyAirQuality>[
          WeatherSharedDailyAirQuality(
            date: DateTime(2026, 4, 26),
            pm10: 42,
            pm25: 16,
          ),
        ],
        yesterdayTemperature: 18.0,
      );

      expect(snapshot.location, '잠실보조구장');
      expect(snapshot.summary, '${l10n.weatherLabelRain} 21°C');
      expect(snapshot.weatherCode, 61);
      expect(snapshot.temperatureDeltaFromYesterday, closeTo(3.4, 0.001));
      expect(snapshot.airQualityScale, AirQualityScale.khai);
      expect(snapshot.dailyForecasts, hasLength(1));
      expect(snapshot.dailyForecasts.first.summary, l10n.weatherLabelRain);
      expect(snapshot.dailyForecasts.first.pm10, 42);
      expect(snapshot.dailyForecasts.first.pm25, 16);
      expect(snapshot.dailyForecasts.first.precipitationProbabilityMax, 80);
      expect(snapshot.dailyForecasts.first.morningForecast?.weatherCode, 3);
      expect(
        snapshot.dailyForecasts.first.eveningForecast?.precipitationProbability,
        80,
      );
      expect(
        snapshot.dailyForecasts.first.hourlyPrecipitations.single.precipitation,
        0.7,
      );
      expect(
        snapshot.dailyForecasts.first.hourlyPrecipitations.single
            .precipitationProbability,
        65,
      );
    });

    test(
      'composeSnapshot keeps today range consistent with current temperature',
      () async {
        const locale = Locale('ko', 'KR');
        final l10n = await AppLocalizations.delegate.load(locale);
        final snapshot = WeatherSharedResource.composeSnapshot(
          location: '잠실보조구장',
          locale: locale,
          fetchedAt: DateTime(2026, 4, 26, 9),
          l10n: l10n,
          weatherSnapshot: WeatherDetailsSnapshot(
            provider: WeatherDataProvider.openMeteo,
            temperature: 18,
            weatherCode: 0,
            temperatureMax: 24,
            temperatureMin: 20,
            dailyForecasts: <WeatherDailyForecast>[
              WeatherDailyForecast(
                date: DateTime(2026, 4, 26),
                weatherCode: 0,
                temperatureMax: 24,
                temperatureMin: 20,
              ),
            ],
          ),
          airQualitySnapshot: const AirQualitySnapshot(),
        );

        expect(snapshot.temperatureMin, 18);
        expect(snapshot.temperatureMax, 24);
        expect(snapshot.dailyForecasts.first.temperatureMin, 18);
      },
    );

    test('fetchForCoordinates attaches daily fine dust forecasts', () async {
      const locale = Locale('ko', 'KR');
      final l10n = await AppLocalizations.delegate.load(locale);
      final client = MockClient((request) async {
        final uri = request.url;
        if (uri.host == 'api.open-meteo.com' && uri.path == '/v1/forecast') {
          return http.Response(
            jsonEncode(<String, Object?>{
              'current': <String, Object?>{
                'temperature_2m': 21.4,
                'apparent_temperature': 20.2,
                'relative_humidity_2m': 55,
                'precipitation': 0,
                'weather_code': 0,
                'wind_speed_10m': 4.1,
              },
              'hourly': <String, Object?>{
                'time': <String>[
                  '2026-04-26T08:00',
                  '2026-04-26T19:00',
                  '2026-04-27T08:00',
                ],
                'temperature_2m': <double>[17, 20, 18],
                'weather_code': <int>[0, 0, 61],
                'precipitation': <double>[0, 0, 1.2],
                'wind_speed_10m': <double>[3.1, 4.5, 6.2],
              },
              'daily': <String, Object?>{
                'time': <String>['2026-04-26', '2026-04-27'],
                'weather_code': <int>[0, 61],
                'uv_index_max': <double>[5.2, 3.1],
                'temperature_2m_max': <double>[24, 21],
                'temperature_2m_min': <double>[15, 13],
                'precipitation_sum': <double>[0, 2.4],
                'wind_speed_10m_max': <double>[8, 11],
              },
            }),
            200,
          );
        }
        if (uri.host == 'air-quality-api.open-meteo.com' &&
            uri.path == '/v1/air-quality') {
          if (uri.queryParameters.containsKey('hourly')) {
            return http.Response(
              jsonEncode(<String, Object?>{
                'hourly': <String, Object?>{
                  'time': <String>[
                    '2026-04-26T00:00',
                    '2026-04-26T12:00',
                    '2026-04-27T00:00',
                  ],
                  'pm10': <double>[30, 42, 24],
                  'pm2_5': <double>[12, 18, 9],
                },
              }),
              200,
            );
          }
          return http.Response(
            jsonEncode(<String, Object?>{
              'current': <String, Object?>{
                'pm10': 31,
                'pm2_5': 14,
                'us_aqi': 53,
              },
            }),
            200,
          );
        }
        if (uri.host == 'archive-api.open-meteo.com' &&
            uri.path == '/v1/archive') {
          return http.Response(
            jsonEncode(<String, Object?>{
              'hourly': <String, Object?>{
                'time': <String>['2026-04-25T09:00'],
                'temperature_2m': <double>[18],
              },
            }),
            200,
          );
        }
        fail('Unexpected request: $uri');
      });

      final snapshot = await WeatherSharedResource.fetchForCoordinates(
        latitude: 51.5,
        longitude: -0.12,
        l10n: l10n,
        locale: locale,
        client: client,
        now: DateTime(2026, 4, 26, 9),
      );

      expect(snapshot.dailyForecasts, hasLength(2));
      expect(snapshot.dailyForecasts.first.pm10, closeTo(36, 0.001));
      expect(snapshot.dailyForecasts.first.pm25, closeTo(15, 0.001));
      expect(snapshot.dailyForecasts[1].pm10, 24);
      expect(snapshot.pm10, 31);
      expect(snapshot.pm25, 14);
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
