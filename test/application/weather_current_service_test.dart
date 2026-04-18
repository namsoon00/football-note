import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/weather_current_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('WeatherCurrentService', () {
    test('falls back to Open-Meteo when KMA key is missing', () async {
      final client = MockClient((request) async {
        expect(request.url.host, 'api.open-meteo.com');
        return http.Response.bytes(
          utf8.encode(
            jsonEncode(<String, dynamic>{
              'current': <String, dynamic>{
                'temperature_2m': 17.4,
                'weather_code': 3,
                'relative_humidity_2m': 62,
                'precipitation': 0,
                'wind_speed_10m': 3.8,
              },
            }),
          ),
          200,
        );
      });

      final snapshot = await WeatherCurrentService.fetchCurrentWeather(
        latitude: 37.5665,
        longitude: 126.9780,
        client: client,
        kmaApiKey: '',
      );

      expect(snapshot.provider, WeatherDataProvider.openMeteo);
      expect(snapshot.temperature, 17.4);
      expect(snapshot.weatherCode, 3);
      expect(snapshot.humidity, 62);
      expect(snapshot.windSpeed, 3.8);
    });

    test('uses KMA current weather for Korean coordinates when key exists',
        () async {
      final client = MockClient((request) async {
        expect(request.url.host, 'apis.data.go.kr');
        expect(request.url.queryParameters.values, contains('test-key'));
        if (request.url.path.endsWith('/getUltraSrtNcst')) {
          return http.Response.bytes(
            utf8.encode(
              jsonEncode(<String, dynamic>{
                'response': <String, dynamic>{
                  'header': <String, dynamic>{
                    'resultCode': '00',
                    'resultMsg': 'NORMAL_SERVICE',
                  },
                  'body': <String, dynamic>{
                    'items': <String, dynamic>{
                      'item': <Map<String, dynamic>>[
                        <String, dynamic>{
                          'category': 'T1H',
                          'obsrValue': '18.2'
                        },
                        <String, dynamic>{'category': 'REH', 'obsrValue': '51'},
                        <String, dynamic>{
                          'category': 'RN1',
                          'obsrValue': '강수없음'
                        },
                        <String, dynamic>{'category': 'PTY', 'obsrValue': '0'},
                        <String, dynamic>{
                          'category': 'WSD',
                          'obsrValue': '2.3'
                        },
                      ],
                    },
                  },
                },
              }),
            ),
            200,
          );
        }
        if (request.url.path.endsWith('/getVilageFcst')) {
          return http.Response.bytes(
            utf8.encode(
              jsonEncode(<String, dynamic>{
                'response': <String, dynamic>{
                  'header': <String, dynamic>{
                    'resultCode': '00',
                    'resultMsg': 'NORMAL_SERVICE',
                  },
                  'body': <String, dynamic>{
                    'items': <String, dynamic>{
                      'item': <Map<String, dynamic>>[
                        <String, dynamic>{
                          'category': 'SKY',
                          'fcstDate': '20260418',
                          'fcstTime': '1200',
                          'fcstValue': '1',
                        },
                        <String, dynamic>{
                          'category': 'PTY',
                          'fcstDate': '20260418',
                          'fcstTime': '1200',
                          'fcstValue': '0',
                        },
                      ],
                    },
                  },
                },
              }),
            ),
            200,
          );
        }
        fail('Unexpected request: ${request.url}');
      });

      final snapshot = await WeatherCurrentService.fetchCurrentWeather(
        latitude: 37.5665,
        longitude: 126.9780,
        client: client,
        kmaApiKey: 'test-key',
        now: DateTime.utc(2026, 4, 18, 3, 20),
      );

      expect(
        snapshot.provider,
        WeatherDataProvider.koreaMeteorologicalAdministration,
      );
      expect(snapshot.temperature, 18.2);
      expect(snapshot.weatherCode, 0);
      expect(snapshot.humidity, 51);
      expect(snapshot.windSpeed, 2.3);
      expect(snapshot.precipitation, 0);
    });

    test('falls back to Open-Meteo when KMA requests fail', () async {
      final client = MockClient((request) async {
        if (request.url.host == 'apis.data.go.kr') {
          return http.Response.bytes(
            utf8.encode(
              jsonEncode(<String, dynamic>{
                'response': <String, dynamic>{
                  'header': <String, dynamic>{
                    'resultCode': '30',
                    'resultMsg': 'NO_DATA',
                  },
                },
              }),
            ),
            200,
          );
        }
        expect(request.url.host, 'api.open-meteo.com');
        return http.Response.bytes(
          utf8.encode(
            jsonEncode(<String, dynamic>{
              'current': <String, dynamic>{
                'temperature_2m': 16.1,
                'weather_code': 61,
                'relative_humidity_2m': 78,
                'precipitation': 2.1,
                'wind_speed_10m': 5.4,
              },
            }),
          ),
          200,
        );
      });

      final snapshot = await WeatherCurrentService.fetchCurrentWeather(
        latitude: 37.5665,
        longitude: 126.9780,
        client: client,
        kmaApiKey: 'test-key',
        now: DateTime.utc(2026, 4, 18, 3, 20),
      );

      expect(snapshot.provider, WeatherDataProvider.openMeteo);
      expect(snapshot.temperature, 16.1);
      expect(snapshot.weatherCode, 61);
      expect(snapshot.humidity, 78);
      expect(snapshot.windSpeed, 5.4);
    });
  });
}
