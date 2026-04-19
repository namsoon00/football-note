import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/weather_location_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('WeatherLocationService', () {
    test(
      'uses Kakao administrative region for Korean coordinates when key exists',
      () async {
        final client = MockClient((request) async {
          expect(request.url.host, 'dapi.kakao.com');
          expect(request.headers['Authorization'], 'KakaoAK test-key');
          expect(request.url.path, '/v2/local/geo/coord2regioncode.json');
          return http.Response.bytes(
            utf8.encode(
              jsonEncode(<String, dynamic>{
                'documents': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'region_type': 'H',
                    'region_1depth_name': '서울특별시',
                    'region_2depth_name': '강남구',
                    'region_3depth_name': '역삼동',
                    'address_name': '서울특별시 강남구 역삼동',
                  },
                ],
              }),
            ),
            200,
          );
        });

        final place = await WeatherLocationService.resolvePlaceName(
          latitude: 37.4981,
          longitude: 127.0276,
          isKo: true,
          koreaLabel: '대한민국',
          kakaoRestApiKey: 'test-key',
          client: client,
        );

        expect(place, '강남구 역삼동');
      },
    );

    test('falls back to Kakao address when region lookup is empty', () async {
      final client = MockClient((request) async {
        expect(request.url.host, 'dapi.kakao.com');
        expect(request.headers['Authorization'], 'KakaoAK test-key');
        if (request.url.path == '/v2/local/geo/coord2regioncode.json') {
          return http.Response.bytes(
            utf8.encode(
              jsonEncode(<String, dynamic>{
                'documents': <Map<String, dynamic>>[],
              }),
            ),
            200,
          );
        }
        expect(request.url.path, '/v2/local/geo/coord2address.json');
        return http.Response.bytes(
          utf8.encode(
            jsonEncode(<String, dynamic>{
              'documents': <Map<String, dynamic>>[
                <String, dynamic>{
                  'road_address': <String, dynamic>{
                    'address_name': '서울 강남구 테헤란로 123',
                  },
                },
              ],
            }),
          ),
          200,
        );
      });

      final place = await WeatherLocationService.resolvePlaceName(
        latitude: 37.4981,
        longitude: 127.0276,
        isKo: true,
        koreaLabel: '대한민국',
        kakaoRestApiKey: 'test-key',
        client: client,
      );

      expect(place, '강남구 테헤란로 123');
    });

    test('falls back to Open-Meteo when Kakao key is missing', () async {
      final client = MockClient((request) async {
        expect(request.url.host, 'geocoding-api.open-meteo.com');
        return http.Response.bytes(
          utf8.encode(
            jsonEncode(<String, dynamic>{
              'results': <Map<String, dynamic>>[
                <String, dynamic>{
                  'city': '서울',
                  'admin2': '강남구',
                  'admin1': '서울특별시',
                  'country': '대한민국',
                },
              ],
            }),
          ),
          200,
        );
      });

      final place = await WeatherLocationService.resolvePlaceName(
        latitude: 37.4981,
        longitude: 127.0276,
        isKo: true,
        koreaLabel: '대한민국',
        kakaoRestApiKey: '',
        client: client,
      );

      expect(place, '강남구 서울');
    });

    test(
      'builds AirKorea area queries from Kakao administrative region',
      () async {
        final client = MockClient((request) async {
          expect(request.url.host, 'dapi.kakao.com');
          expect(request.url.path, '/v2/local/geo/coord2regioncode.json');
          return http.Response.bytes(
            utf8.encode(
              jsonEncode(<String, dynamic>{
                'documents': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'region_type': 'H',
                    'region_1depth_name': '서울특별시',
                    'region_2depth_name': '강남구',
                    'region_3depth_name': '역삼동',
                    'address_name': '서울특별시 강남구 역삼동',
                  },
                ],
              }),
            ),
            200,
          );
        });

        final queries =
            await WeatherLocationService.resolveAdministrativeAreaQueries(
              latitude: 37.4981,
              longitude: 127.0276,
              kakaoRestApiKey: 'test-key',
              client: client,
            );

        expect(queries, const <String>['서울특별시 강남구', '강남구 역삼동', '강남구', '서울특별시']);
      },
    );

    test('falls back to Open-Meteo when Kakao request fails', () async {
      final client = MockClient((request) async {
        if (request.url.host == 'dapi.kakao.com') {
          throw http.ClientException('kakao down');
        }
        expect(request.url.host, 'geocoding-api.open-meteo.com');
        return http.Response.bytes(
          utf8.encode(
            jsonEncode(<String, dynamic>{
              'results': <Map<String, dynamic>>[
                <String, dynamic>{
                  'city': '성남',
                  'admin2': '분당구',
                  'admin1': '경기도',
                  'country': '대한민국',
                },
              ],
            }),
          ),
          200,
        );
      });

      final place = await WeatherLocationService.resolvePlaceName(
        latitude: 37.3596,
        longitude: 127.1054,
        isKo: true,
        koreaLabel: '대한민국',
        kakaoRestApiKey: 'test-key',
        client: client,
      );

      expect(place, '분당구 성남');
    });

    test('returns coordinate label when every geocoder fails', () async {
      final client = MockClient((request) async {
        throw http.ClientException('network down');
      });

      final place = await WeatherLocationService.resolvePlaceName(
        latitude: 37.4981,
        longitude: 127.0276,
        isKo: true,
        koreaLabel: '대한민국',
        kakaoRestApiKey: 'test-key',
        client: client,
      );

      expect(place, '37.4981, 127.0276');
    });

    test(
      'hides overseas administrative areas in reverse geocode labels',
      () async {
        final client = MockClient((request) async {
          expect(request.url.host, 'geocoding-api.open-meteo.com');
          return http.Response.bytes(
            utf8.encode(
              jsonEncode(<String, dynamic>{
                'results': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'name': 'Brooklyn',
                    'city': 'New York',
                    'admin2': 'Kings County',
                    'admin1': 'New York',
                    'country': 'United States',
                  },
                ],
              }),
            ),
            200,
          );
        });

        final place = await WeatherLocationService.resolvePlaceName(
          latitude: 40.6782,
          longitude: -73.9442,
          isKo: false,
          koreaLabel: 'Korea',
          kakaoRestApiKey: '',
          client: client,
        );

        expect(place, 'New York, United States');
      },
    );
  });
}
