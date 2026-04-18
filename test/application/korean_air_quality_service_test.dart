import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/korean_air_quality_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('KoreanAirQualityService', () {
    test('uses nearby AirKorea station from coordinates when Kakao key exists',
        () async {
      final client = MockClient((request) async {
        if (request.url.host == 'dapi.kakao.com') {
          expect(request.headers['Authorization'], 'KakaoAK test-kakao');
          expect(request.url.path, '/v2/local/geo/transcoord.json');
          expect(request.url.queryParameters['input_coord'], 'WGS84');
          expect(request.url.queryParameters['output_coord'], 'TM');
          return http.Response.bytes(
            utf8.encode(
              jsonEncode(<String, dynamic>{
                'documents': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'x': '203000.0',
                    'y': '442000.0',
                  },
                ],
              }),
            ),
            200,
          );
        }

        expect(request.url.host, 'apis.data.go.kr');
        if (request.url.path.endsWith('/getNearbyMsrstnList')) {
          expect(request.url.queryParameters['tmX'], '203000.0');
          expect(request.url.queryParameters['tmY'], '442000.0');
          return http.Response.bytes(
            utf8.encode(
              jsonEncode(<String, dynamic>{
                'response': <String, dynamic>{
                  'header': <String, dynamic>{
                    'resultCode': '00',
                    'resultMsg': 'NORMAL_SERVICE',
                  },
                  'body': <String, dynamic>{
                    'items': <Map<String, dynamic>>[
                      <String, dynamic>{
                        'stationName': '점검소',
                      },
                      <String, dynamic>{
                        'stationName': '강남대로',
                      },
                    ],
                  },
                },
              }),
            ),
            200,
          );
        }
        if (request.url.path.endsWith('/getMsrstnAcctoRltmMesureDnsty')) {
          final stationName = request.url.queryParameters['stationName'];
          expect(request.url.queryParameters['numOfRows'], '24');
          if (stationName == '점검소') {
            return http.Response.bytes(
              utf8.encode(
                jsonEncode(<String, dynamic>{
                  'response': <String, dynamic>{
                    'header': <String, dynamic>{
                      'resultCode': '00',
                      'resultMsg': 'NORMAL_SERVICE',
                    },
                    'body': <String, dynamic>{
                      'items': <Map<String, dynamic>>[
                        <String, dynamic>{
                          'pm10Value': '-',
                          'pm25Value': '-',
                          'khaiValue': '-',
                        },
                      ],
                    },
                  },
                }),
              ),
              200,
            );
          }
          expect(stationName, '강남대로');
          return http.Response.bytes(
            utf8.encode(
              jsonEncode(<String, dynamic>{
                'response': <String, dynamic>{
                  'header': <String, dynamic>{
                    'resultCode': '00',
                    'resultMsg': 'NORMAL_SERVICE',
                  },
                  'body': <String, dynamic>{
                    'items': <Map<String, dynamic>>[
                      <String, dynamic>{
                        'pm10Value': '42',
                        'pm25Value': '18',
                        'khaiValue': '87',
                      },
                    ],
                  },
                },
              }),
            ),
            200,
          );
        }
        fail('Unexpected request: ${request.url}');
      });

      final snapshot = await KoreanAirQualityService.fetchCurrentAirQuality(
        latitude: 37.4981,
        longitude: 127.0276,
        client: client,
        serviceKey: 'test-key',
        kakaoRestApiKey: 'test-kakao',
      );

      expect(snapshot.pm10, 42);
      expect(snapshot.pm25, 18);
      expect(snapshot.aqi, 87);
      expect(snapshot.scale, AirQualityScale.khai);
    });

    test('falls back to address-based AirKorea lookup when nearby lookup fails',
        () async {
      final client = MockClient((request) async {
        if (request.url.host == 'dapi.kakao.com') {
          return http.Response('kakao unavailable', 500);
        }

        expect(request.url.host, 'apis.data.go.kr');
        if (request.url.path.endsWith('/getCtprvnRltmMesureDnsty')) {
          expect(request.url.queryParameters['sidoName'], '서울');
          return http.Response.bytes(
            utf8.encode(
              jsonEncode(<String, dynamic>{
                'response': <String, dynamic>{
                  'header': <String, dynamic>{
                    'resultCode': '00',
                    'resultMsg': 'NORMAL_SERVICE',
                  },
                  'body': <String, dynamic>{
                    'items': <Map<String, dynamic>>[],
                  },
                },
              }),
            ),
            200,
          );
        }
        if (request.url.path.endsWith('/getMsrstnList')) {
          expect(request.url.queryParameters['addr'], '서울특별시 강남구');
          return http.Response.bytes(
            utf8.encode(
              jsonEncode(<String, dynamic>{
                'response': <String, dynamic>{
                  'header': <String, dynamic>{
                    'resultCode': '00',
                    'resultMsg': 'NORMAL_SERVICE',
                  },
                  'body': <String, dynamic>{
                    'items': <Map<String, dynamic>>[
                      <String, dynamic>{
                        'stationName': '강남구',
                      },
                    ],
                  },
                },
              }),
            ),
            200,
          );
        }
        if (request.url.path.endsWith('/getMsrstnAcctoRltmMesureDnsty')) {
          expect(request.url.queryParameters['stationName'], '강남구');
          expect(request.url.queryParameters['numOfRows'], '24');
          return http.Response.bytes(
            utf8.encode(
              jsonEncode(<String, dynamic>{
                'response': <String, dynamic>{
                  'header': <String, dynamic>{
                    'resultCode': '00',
                    'resultMsg': 'NORMAL_SERVICE',
                  },
                  'body': <String, dynamic>{
                    'items': <Map<String, dynamic>>[
                      <String, dynamic>{
                        'pm10Value': '42',
                        'pm25Value': '18',
                        'khaiValue': '87',
                      },
                    ],
                  },
                },
              }),
            ),
            200,
          );
        }
        fail('Unexpected request: ${request.url}');
      });

      final snapshot = await KoreanAirQualityService.fetchCurrentAirQuality(
        latitude: 37.4981,
        longitude: 127.0276,
        client: client,
        serviceKey: 'test-key',
        kakaoRestApiKey: 'test-kakao',
        administrativeAreaQueries: const <String>['서울특별시 강남구'],
      );

      expect(snapshot.pm10, 42);
      expect(snapshot.pm25, 18);
      expect(snapshot.aqi, 87);
      expect(snapshot.scale, AirQualityScale.khai);
    });

    test(
        'falls back to province measurements when nearby station endpoint returns invalid body',
        () async {
      final client = MockClient((request) async {
        if (request.url.host == 'dapi.kakao.com') {
          return http.Response.bytes(
            utf8.encode(
              jsonEncode(<String, dynamic>{
                'documents': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'x': '203000.0',
                    'y': '442000.0',
                  },
                ],
              }),
            ),
            200,
          );
        }

        expect(request.url.host, 'apis.data.go.kr');
        if (request.url.path.endsWith('/getNearbyMsrstnList')) {
          return http.Response('Forbidden', 200);
        }
        if (request.url.path.endsWith('/getCtprvnRltmMesureDnsty')) {
          expect(request.url.queryParameters['sidoName'], '서울');
          return http.Response.bytes(
            utf8.encode(
              jsonEncode(<String, dynamic>{
                'response': <String, dynamic>{
                  'header': <String, dynamic>{
                    'resultCode': '00',
                    'resultMsg': 'NORMAL_SERVICE',
                  },
                  'body': <String, dynamic>{
                    'items': <Map<String, dynamic>>[
                      <String, dynamic>{
                        'stationName': '중구',
                        'pm10Value': '21',
                        'pm25Value': '9',
                        'khaiValue': '44',
                      },
                      <String, dynamic>{
                        'stationName': '강남대로',
                        'pm10Value': '-',
                        'pm10Value24': '37',
                        'pm25Value': '-',
                        'pm25Value24': '16',
                        'khaiValue': '79',
                      },
                    ],
                  },
                },
              }),
            ),
            200,
          );
        }
        if (request.url.path.endsWith('/getMsrstnList') ||
            request.url.path.endsWith('/getMsrstnAcctoRltmMesureDnsty')) {
          fail(
              'Regional fallback should resolve before station lookup: ${request.url}');
        }
        fail('Unexpected request: ${request.url}');
      });

      final snapshot = await KoreanAirQualityService.fetchCurrentAirQuality(
        latitude: 37.4981,
        longitude: 127.0276,
        client: client,
        serviceKey: 'test-key',
        kakaoRestApiKey: 'test-kakao',
        administrativeAreaQueries: const <String>[
          '서울특별시 강남구',
          '강남구 역삼1동',
        ],
      );

      expect(snapshot.pm10, 37);
      expect(snapshot.pm25, 16);
      expect(snapshot.aqi, 79);
      expect(snapshot.scale, AirQualityScale.khai);
    });

    test('returns empty snapshot for non-Korean coordinates', () async {
      final snapshot = await KoreanAirQualityService.fetchCurrentAirQuality(
        latitude: 35.6764,
        longitude: 139.6500,
        serviceKey: 'test-key',
      );

      expect(snapshot.hasData, isFalse);
      expect(snapshot.scale, AirQualityScale.usAqi);
    });
  });
}
