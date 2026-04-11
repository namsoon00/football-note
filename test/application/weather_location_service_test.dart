import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/weather_location_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('WeatherLocationService', () {
    test('uses Kakao reverse geocoding for Korean coordinates when key exists',
        () async {
      final client = MockClient((request) async {
        expect(request.url.host, 'dapi.kakao.com');
        expect(request.headers['Authorization'], 'KakaoAK test-key');
        return http.Response.bytes(
          utf8.encode(
            jsonEncode(<String, dynamic>{
              'documents': <Map<String, dynamic>>[
                <String, dynamic>{
                  'region_type': 'H',
                  'address_name': '서울특별시 강남구 역삼1동',
                  'region_1depth_name': '서울특별시',
                  'region_2depth_name': '강남구',
                  'region_3depth_name': '역삼1동',
                  'region_4depth_name': '',
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

      expect(place, '강남구 역삼1동, 대한민국');
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

      expect(place, '강남구 서울, 대한민국');
    });
  });
}
