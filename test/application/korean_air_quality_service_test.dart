import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/korean_air_quality_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('KoreanAirQualityService', () {
    test('uses AirKorea station and measurement APIs for Korean coordinates',
        () async {
      final client = MockClient((request) async {
        expect(request.url.host, 'apis.data.go.kr');
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
        administrativeAreaQueries: const <String>['서울특별시 강남구'],
      );

      expect(snapshot.pm10, 42);
      expect(snapshot.pm25, 18);
      expect(snapshot.aqi, 87);
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
