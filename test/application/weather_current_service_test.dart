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

    test(
      'uses KMA current weather for Korean coordinates when key exists',
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
                            'obsrValue': '18.2',
                          },
                          <String, dynamic>{
                            'category': 'REH',
                            'obsrValue': '51',
                          },
                          <String, dynamic>{
                            'category': 'RN1',
                            'obsrValue': '강수없음',
                          },
                          <String, dynamic>{
                            'category': 'PTY',
                            'obsrValue': '0',
                          },
                          <String, dynamic>{
                            'category': 'WSD',
                            'obsrValue': '2.3',
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
      },
    );

    test('returns empty KMA snapshot when KMA requests fail', () async {
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
      expect(snapshot.hasData, isFalse);
    });

    test(
      'parses hourly forecast points from Open-Meteo detailed forecast',
      () async {
        final client = MockClient((request) async {
          expect(request.url.host, 'api.open-meteo.com');
          expect(
            request.url.queryParameters['hourly'],
            'temperature_2m,weather_code,precipitation,wind_speed_10m',
          );
          return http.Response.bytes(
            utf8.encode(
              jsonEncode(<String, dynamic>{
                'current': <String, dynamic>{
                  'temperature_2m': 17.4,
                  'weather_code': 61,
                  'apparent_temperature': 16.1,
                  'relative_humidity_2m': 62,
                  'precipitation': 0.8,
                  'wind_speed_10m': 3.8,
                },
                'hourly': <String, dynamic>{
                  'time': <String>[
                    '2026-04-18T09:00',
                    '2026-04-18T12:00',
                    '2026-04-18T15:00',
                    '2026-04-19T06:00',
                    '2026-04-19T18:00',
                  ],
                  'temperature_2m': <double>[14.2, 17.4, 16.8, 13.1, 18.4],
                  'weather_code': <int>[3, 61, 61, 1, 3],
                  'precipitation': <double>[0, 1.2, 2.4, 0.7, 0],
                  'wind_speed_10m': <double>[2.8, 3.4, 4.1, 2.2, 3.6],
                },
                'daily': <String, dynamic>{
                  'time': <String>['2026-04-18', '2026-04-19'],
                  'weather_code': <int>[61, 3],
                  'temperature_2m_max': <double>[19, 21],
                  'temperature_2m_min': <double>[11, 13],
                  'precipitation_sum': <double>[3.6, 0.7],
                  'wind_speed_10m_max': <double>[5, 4],
                  'uv_index_max': <double>[4, 5],
                },
              }),
            ),
            200,
          );
        });

        final snapshot = await WeatherCurrentService.fetchDetailedWeather(
          latitude: 51.5072,
          longitude: -0.1276,
          client: client,
          kmaApiKey: '',
        );

        expect(snapshot.provider, WeatherDataProvider.openMeteo);
        expect(snapshot.dailyForecasts, hasLength(2));
        expect(
          snapshot.dailyForecasts.first.hourlyPrecipitations,
          hasLength(2),
        );
        expect(
          snapshot.dailyForecasts.first.morningForecast?.temperature,
          14.2,
        );
        expect(snapshot.dailyForecasts.first.morningForecast?.weatherCode, 3);
        expect(
          snapshot.dailyForecasts.first.eveningForecast?.temperature,
          16.8,
        );
        expect(snapshot.dailyForecasts[1].morningForecast?.temperature, 13.1);
        expect(snapshot.dailyForecasts[1].eveningForecast?.temperature, 18.4);
        expect(
          snapshot.dailyForecasts.first.hourlyPrecipitations.first.time,
          DateTime(2026, 4, 18, 12),
        );
        expect(
          snapshot
              .dailyForecasts.first.hourlyPrecipitations.first.precipitation,
          1.2,
        );
        expect(snapshot.dailyForecasts[1].hourlyPrecipitations, hasLength(1));
        expect(
          snapshot.dailyForecasts[1].hourlyPrecipitations.single.precipitation,
          0.7,
        );
      },
    );

    test(
      'uses KMA detailed forecast for Korean coordinates when key exists',
      () async {
        final client = MockClient((request) async {
          expect(request.url.host, 'apis.data.go.kr');
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
                            'obsrValue': '18.2',
                          },
                          <String, dynamic>{
                            'category': 'REH',
                            'obsrValue': '51',
                          },
                          <String, dynamic>{
                            'category': 'RN1',
                            'obsrValue': '강수없음',
                          },
                          <String, dynamic>{
                            'category': 'PTY',
                            'obsrValue': '0',
                          },
                          <String, dynamic>{
                            'category': 'WSD',
                            'obsrValue': '2.3',
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
                            'category': 'TMP',
                            'fcstDate': '20260418',
                            'fcstTime': '0600',
                            'fcstValue': '12',
                          },
                          <String, dynamic>{
                            'category': 'TMN',
                            'fcstDate': '20260418',
                            'fcstTime': '0600',
                            'fcstValue': '12',
                          },
                          <String, dynamic>{
                            'category': 'SKY',
                            'fcstDate': '20260418',
                            'fcstTime': '0600',
                            'fcstValue': '1',
                          },
                          <String, dynamic>{
                            'category': 'PTY',
                            'fcstDate': '20260418',
                            'fcstTime': '0600',
                            'fcstValue': '0',
                          },
                          <String, dynamic>{
                            'category': 'WSD',
                            'fcstDate': '20260418',
                            'fcstTime': '0600',
                            'fcstValue': '2',
                          },
                          <String, dynamic>{
                            'category': 'PCP',
                            'fcstDate': '20260418',
                            'fcstTime': '0600',
                            'fcstValue': '강수없음',
                          },
                          <String, dynamic>{
                            'category': 'TMP',
                            'fcstDate': '20260418',
                            'fcstTime': '1200',
                            'fcstValue': '22',
                          },
                          <String, dynamic>{
                            'category': 'TMX',
                            'fcstDate': '20260418',
                            'fcstTime': '1200',
                            'fcstValue': '24',
                          },
                          <String, dynamic>{
                            'category': 'SKY',
                            'fcstDate': '20260418',
                            'fcstTime': '1200',
                            'fcstValue': '3',
                          },
                          <String, dynamic>{
                            'category': 'PTY',
                            'fcstDate': '20260418',
                            'fcstTime': '1200',
                            'fcstValue': '0',
                          },
                          <String, dynamic>{
                            'category': 'WSD',
                            'fcstDate': '20260418',
                            'fcstTime': '1200',
                            'fcstValue': '4',
                          },
                          <String, dynamic>{
                            'category': 'PCP',
                            'fcstDate': '20260418',
                            'fcstTime': '1200',
                            'fcstValue': '강수없음',
                          },
                          <String, dynamic>{
                            'category': 'TMP',
                            'fcstDate': '20260418',
                            'fcstTime': '1800',
                            'fcstValue': '20',
                          },
                          <String, dynamic>{
                            'category': 'SKY',
                            'fcstDate': '20260418',
                            'fcstTime': '1800',
                            'fcstValue': '4',
                          },
                          <String, dynamic>{
                            'category': 'PTY',
                            'fcstDate': '20260418',
                            'fcstTime': '1800',
                            'fcstValue': '1',
                          },
                          <String, dynamic>{
                            'category': 'WSD',
                            'fcstDate': '20260418',
                            'fcstTime': '1800',
                            'fcstValue': '5',
                          },
                          <String, dynamic>{
                            'category': 'PCP',
                            'fcstDate': '20260418',
                            'fcstTime': '1800',
                            'fcstValue': '3.0mm',
                          },
                          <String, dynamic>{
                            'category': 'TMP',
                            'fcstDate': '20260419',
                            'fcstTime': '0600',
                            'fcstValue': '13',
                          },
                          <String, dynamic>{
                            'category': 'TMN',
                            'fcstDate': '20260419',
                            'fcstTime': '0600',
                            'fcstValue': '11',
                          },
                          <String, dynamic>{
                            'category': 'SKY',
                            'fcstDate': '20260419',
                            'fcstTime': '0600',
                            'fcstValue': '1',
                          },
                          <String, dynamic>{
                            'category': 'PTY',
                            'fcstDate': '20260419',
                            'fcstTime': '0600',
                            'fcstValue': '0',
                          },
                          <String, dynamic>{
                            'category': 'WSD',
                            'fcstDate': '20260419',
                            'fcstTime': '0600',
                            'fcstValue': '1',
                          },
                          <String, dynamic>{
                            'category': 'PCP',
                            'fcstDate': '20260419',
                            'fcstTime': '0600',
                            'fcstValue': '강수없음',
                          },
                          <String, dynamic>{
                            'category': 'TMP',
                            'fcstDate': '20260419',
                            'fcstTime': '1200',
                            'fcstValue': '19',
                          },
                          <String, dynamic>{
                            'category': 'TMX',
                            'fcstDate': '20260419',
                            'fcstTime': '1200',
                            'fcstValue': '20',
                          },
                          <String, dynamic>{
                            'category': 'SKY',
                            'fcstDate': '20260419',
                            'fcstTime': '1200',
                            'fcstValue': '1',
                          },
                          <String, dynamic>{
                            'category': 'PTY',
                            'fcstDate': '20260419',
                            'fcstTime': '1200',
                            'fcstValue': '0',
                          },
                          <String, dynamic>{
                            'category': 'WSD',
                            'fcstDate': '20260419',
                            'fcstTime': '1200',
                            'fcstValue': '2',
                          },
                          <String, dynamic>{
                            'category': 'PCP',
                            'fcstDate': '20260419',
                            'fcstTime': '1200',
                            'fcstValue': '강수없음',
                          },
                          <String, dynamic>{
                            'category': 'TMP',
                            'fcstDate': '20260420',
                            'fcstTime': '0600',
                            'fcstValue': '14',
                          },
                          <String, dynamic>{
                            'category': 'TMN',
                            'fcstDate': '20260420',
                            'fcstTime': '0600',
                            'fcstValue': '12',
                          },
                          <String, dynamic>{
                            'category': 'SKY',
                            'fcstDate': '20260420',
                            'fcstTime': '0600',
                            'fcstValue': '3',
                          },
                          <String, dynamic>{
                            'category': 'PTY',
                            'fcstDate': '20260420',
                            'fcstTime': '0600',
                            'fcstValue': '0',
                          },
                          <String, dynamic>{
                            'category': 'WSD',
                            'fcstDate': '20260420',
                            'fcstTime': '0600',
                            'fcstValue': '2',
                          },
                          <String, dynamic>{
                            'category': 'PCP',
                            'fcstDate': '20260420',
                            'fcstTime': '0600',
                            'fcstValue': '강수없음',
                          },
                          <String, dynamic>{
                            'category': 'TMP',
                            'fcstDate': '20260420',
                            'fcstTime': '1200',
                            'fcstValue': '21',
                          },
                          <String, dynamic>{
                            'category': 'TMX',
                            'fcstDate': '20260420',
                            'fcstTime': '1200',
                            'fcstValue': '22',
                          },
                          <String, dynamic>{
                            'category': 'SKY',
                            'fcstDate': '20260420',
                            'fcstTime': '1200',
                            'fcstValue': '3',
                          },
                          <String, dynamic>{
                            'category': 'PTY',
                            'fcstDate': '20260420',
                            'fcstTime': '1200',
                            'fcstValue': '0',
                          },
                          <String, dynamic>{
                            'category': 'WSD',
                            'fcstDate': '20260420',
                            'fcstTime': '1200',
                            'fcstValue': '3',
                          },
                          <String, dynamic>{
                            'category': 'PCP',
                            'fcstDate': '20260420',
                            'fcstTime': '1200',
                            'fcstValue': '강수없음',
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
          if (request.url.path.endsWith('/getFcstZoneCd')) {
            expect(request.url.queryParameters['tmSt'], '201004300900');
            expect(request.url.queryParameters['tmEd'], '210012310900');
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
                            'regId': '11B10101',
                            'regName': '서울',
                            'regSp': 'C',
                            'regUp': '11B00000',
                            'stnFw': '109',
                            'lat': '37.5665',
                            'lon': '126.9780',
                          },
                          <String, dynamic>{
                            'regId': '11B00000',
                            'regName': '서울,인천,경기도',
                            'regSp': 'A',
                            'regUp': '',
                            'stnFw': '109',
                            'lat': '37.5665',
                            'lon': '126.9780',
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
          if (request.url.path.endsWith('/getMidFcst')) {
            expect(request.url.queryParameters['stnId'], '109');
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
                            'wf3Am': '구름많음',
                            'wf3Pm': '흐림',
                            'wf4Am': '맑음',
                            'wf4Pm': '구름많음',
                            'wf5Am': '맑음',
                            'wf5Pm': '맑음',
                            'wf6Am': '흐림',
                            'wf6Pm': '비',
                            'wf7Am': '구름많음',
                            'wf7Pm': '구름많음',
                            'wf8': '맑음',
                            'wf9': '구름많음',
                            'wf10': '비',
                            'taMin4': '10',
                            'taMax4': '19',
                            'taMin5': '11',
                            'taMax5': '21',
                            'taMin6': '12',
                            'taMax6': '18',
                            'taMin7': '13',
                            'taMax7': '20',
                            'taMin8': '12',
                            'taMax8': '22',
                            'taMin9': '13',
                            'taMax9': '21',
                            'taMin10': '14',
                            'taMax10': '19',
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

        final snapshot = await WeatherCurrentService.fetchDetailedWeather(
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
        expect(snapshot.weatherCode, 2);
        expect(snapshot.humidity, 51);
        expect(snapshot.windSpeed, 2.3);
        expect(snapshot.apparentTemperature, closeTo(16.1, 0.2));
        expect(snapshot.temperatureMax, 24);
        expect(snapshot.temperatureMin, 12);
        expect(snapshot.dailyForecasts, hasLength(7));
        expect(snapshot.dailyForecasts.first.weatherCode, 61);
        expect(snapshot.dailyForecasts.first.precipitationSum, 3);
        expect(
          snapshot.dailyForecasts.first.hourlyPrecipitations,
          hasLength(1),
        );
        expect(
          snapshot.dailyForecasts.first.hourlyPrecipitations.single.time,
          DateTime(2026, 4, 18, 18),
        );
        expect(
          snapshot
              .dailyForecasts.first.hourlyPrecipitations.single.precipitation,
          3,
        );
        expect(snapshot.dailyForecasts.first.windSpeedMax, 5);
        expect(snapshot.dailyForecasts.first.morningForecast?.temperature, 12);
        expect(snapshot.dailyForecasts.first.morningForecast?.weatherCode, 0);
        expect(snapshot.dailyForecasts.first.eveningForecast?.temperature, 20);
        expect(snapshot.dailyForecasts.first.eveningForecast?.weatherCode, 61);
        expect(snapshot.dailyForecasts[1].weatherCode, 0);
        expect(snapshot.dailyForecasts[1].temperatureMax, 20);
        expect(snapshot.dailyForecasts[1].temperatureMin, 11);
        expect(snapshot.dailyForecasts[1].morningForecast?.temperature, 13);
        expect(snapshot.dailyForecasts[1].eveningForecast?.temperature, 19);
        expect(snapshot.dailyForecasts[2].date, DateTime(2026, 4, 20));
        expect(snapshot.dailyForecasts[2].temperatureMax, 22);
        expect(snapshot.dailyForecasts[2].weatherCode, 2);
        expect(snapshot.dailyForecasts[3].date, DateTime(2026, 4, 21));
        expect(snapshot.dailyForecasts[3].weatherCode, 3);
        expect(snapshot.dailyForecasts[3].temperatureMax, null);
        expect(snapshot.dailyForecasts[4].date, DateTime(2026, 4, 22));
        expect(snapshot.dailyForecasts[4].temperatureMax, 19);
        expect(snapshot.dailyForecasts[5].date, DateTime(2026, 4, 23));
        expect(snapshot.dailyForecasts[5].temperatureMin, 11);
        expect(snapshot.dailyForecasts[6].date, DateTime(2026, 4, 24));
        expect(snapshot.dailyForecasts[6].weatherCode, 61);
      },
    );

    test(
      'supplements partial KMA weekly forecast with Open-Meteo when mid-range data is unavailable',
      () async {
        final client = MockClient((request) async {
          if (request.url.host == 'apis.data.go.kr') {
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
                              'obsrValue': '18.2',
                            },
                            <String, dynamic>{
                              'category': 'REH',
                              'obsrValue': '51',
                            },
                            <String, dynamic>{
                              'category': 'RN1',
                              'obsrValue': '강수없음',
                            },
                            <String, dynamic>{
                              'category': 'PTY',
                              'obsrValue': '0',
                            },
                            <String, dynamic>{
                              'category': 'WSD',
                              'obsrValue': '2.3',
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
                              'category': 'TMP',
                              'fcstDate': '20260418',
                              'fcstTime': '1200',
                              'fcstValue': '18',
                            },
                            <String, dynamic>{
                              'category': 'TMX',
                              'fcstDate': '20260418',
                              'fcstTime': '1200',
                              'fcstValue': '24',
                            },
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
                            <String, dynamic>{
                              'category': 'WSD',
                              'fcstDate': '20260418',
                              'fcstTime': '1200',
                              'fcstValue': '3',
                            },
                            <String, dynamic>{
                              'category': 'PCP',
                              'fcstDate': '20260418',
                              'fcstTime': '1200',
                              'fcstValue': '강수없음',
                            },
                            <String, dynamic>{
                              'category': 'TMP',
                              'fcstDate': '20260419',
                              'fcstTime': '0600',
                              'fcstValue': '12',
                            },
                            <String, dynamic>{
                              'category': 'TMN',
                              'fcstDate': '20260419',
                              'fcstTime': '0600',
                              'fcstValue': '11',
                            },
                            <String, dynamic>{
                              'category': 'SKY',
                              'fcstDate': '20260419',
                              'fcstTime': '0600',
                              'fcstValue': '3',
                            },
                            <String, dynamic>{
                              'category': 'PTY',
                              'fcstDate': '20260419',
                              'fcstTime': '0600',
                              'fcstValue': '0',
                            },
                            <String, dynamic>{
                              'category': 'TMP',
                              'fcstDate': '20260419',
                              'fcstTime': '1500',
                              'fcstValue': '20',
                            },
                            <String, dynamic>{
                              'category': 'TMX',
                              'fcstDate': '20260419',
                              'fcstTime': '1500',
                              'fcstValue': '21',
                            },
                            <String, dynamic>{
                              'category': 'SKY',
                              'fcstDate': '20260419',
                              'fcstTime': '1500',
                              'fcstValue': '4',
                            },
                            <String, dynamic>{
                              'category': 'PTY',
                              'fcstDate': '20260419',
                              'fcstTime': '1500',
                              'fcstValue': '1',
                            },
                            <String, dynamic>{
                              'category': 'PCP',
                              'fcstDate': '20260419',
                              'fcstTime': '1500',
                              'fcstValue': '3',
                            },
                            <String, dynamic>{
                              'category': 'TMP',
                              'fcstDate': '20260420',
                              'fcstTime': '1200',
                              'fcstValue': '19',
                            },
                            <String, dynamic>{
                              'category': 'TMX',
                              'fcstDate': '20260420',
                              'fcstTime': '1200',
                              'fcstValue': '22',
                            },
                            <String, dynamic>{
                              'category': 'SKY',
                              'fcstDate': '20260420',
                              'fcstTime': '1200',
                              'fcstValue': '3',
                            },
                            <String, dynamic>{
                              'category': 'PTY',
                              'fcstDate': '20260420',
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
            if (request.url.path.endsWith('/getFcstZoneCd')) {
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
          }

          if (request.url.host == 'api.open-meteo.com') {
            return http.Response.bytes(
              utf8.encode(
                jsonEncode(<String, dynamic>{
                  'current': <String, dynamic>{
                    'temperature_2m': 16.9,
                    'weather_code': 3,
                    'apparent_temperature': 15.4,
                    'relative_humidity_2m': 57,
                    'precipitation': 0.0,
                    'wind_speed_10m': 4.1,
                  },
                  'daily': <String, dynamic>{
                    'time': <String>[
                      '2026-04-18',
                      '2026-04-19',
                      '2026-04-20',
                      '2026-04-21',
                      '2026-04-22',
                      '2026-04-23',
                      '2026-04-24',
                    ],
                    'weather_code': <int>[3, 2, 1, 61, 3, 0, 2],
                    'temperature_2m_max': <double>[30, 29, 28, 18, 17, 19, 21],
                    'temperature_2m_min': <double>[20, 19, 18, 9, 8, 10, 11],
                    'precipitation_sum': <double>[0, 1.2, 0, 4.5, 0.2, 0, 0],
                    'wind_speed_10m_max': <double>[6, 5, 4, 7, 4, 3, 5],
                    'uv_index_max': <double>[5, 6, 6, 4, 5, 6, 6],
                  },
                }),
              ),
              200,
            );
          }

          fail('Unexpected request: ${request.url}');
        });

        final snapshot = await WeatherCurrentService.fetchDetailedWeather(
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
        expect(snapshot.dailyForecasts, hasLength(7));
        expect(snapshot.dailyForecasts[0].date, DateTime(2026, 4, 18));
        expect(snapshot.dailyForecasts[0].temperatureMax, 24);
        expect(snapshot.dailyForecasts[1].weatherCode, 61);
        expect(snapshot.dailyForecasts[1].temperatureMax, 21);
        expect(snapshot.dailyForecasts[2].date, DateTime(2026, 4, 20));
        expect(snapshot.dailyForecasts[2].temperatureMax, 22);
        expect(snapshot.dailyForecasts[3].date, DateTime(2026, 4, 21));
        expect(snapshot.dailyForecasts[3].temperatureMax, 18);
        expect(snapshot.dailyForecasts[6].date, DateTime(2026, 4, 24));
        expect(snapshot.dailyForecasts[6].temperatureMin, 11);
      },
    );

    test('returns empty KMA detailed forecast when KMA fails', () async {
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
        fail('Unexpected request: ${request.url}');
      });

      final snapshot = await WeatherCurrentService.fetchDetailedWeather(
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
      expect(snapshot.hasData, isFalse);
    });
  });
}
