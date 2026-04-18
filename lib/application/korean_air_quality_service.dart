import 'dart:convert';

import 'package:http/http.dart' as http;

import 'government_api_credentials.dart';
import 'weather_location_service.dart';

enum AirQualityScale {
  usAqi,
  khai,
}

class AirQualitySnapshot {
  const AirQualitySnapshot({
    this.pm10,
    this.pm25,
    this.aqi,
    this.scale = AirQualityScale.usAqi,
  });

  final double? pm10;
  final double? pm25;
  final int? aqi;
  final AirQualityScale scale;

  bool get hasData => pm10 != null || pm25 != null || aqi != null;
}

class KoreanAirQualityService {
  const KoreanAirQualityService._();

  static Future<AirQualitySnapshot> fetchCurrentAirQuality({
    required double latitude,
    required double longitude,
    http.Client? client,
    String? serviceKey,
    String? kakaoRestApiKey,
    List<String>? administrativeAreaQueries,
  }) async {
    if (!WeatherLocationService.isLikelyInKorea(latitude, longitude)) {
      return const AirQualitySnapshot();
    }

    final normalizedKey =
        (serviceKey ?? GovernmentApiCredentials.dataGoKrServiceKey).trim();
    if (normalizedKey.isEmpty) {
      return const AirQualitySnapshot();
    }

    final localClient = client ?? http.Client();
    final ownsClient = client == null;
    try {
      final normalizedKakaoKey =
          (kakaoRestApiKey ?? GovernmentApiCredentials.kakaoRestApiKey).trim();

      final nearbyStationName = await _resolveNearbyStationName(
        client: localClient,
        kakaoRestApiKey: normalizedKakaoKey,
        latitude: latitude,
        longitude: longitude,
        serviceKey: normalizedKey,
      );
      if (nearbyStationName.isNotEmpty) {
        final nearbySnapshot = await _fetchStationMeasurement(
          client: localClient,
          serviceKey: normalizedKey,
          stationName: nearbyStationName,
        );
        if (nearbySnapshot.hasData) {
          return nearbySnapshot;
        }
      }

      final queries = administrativeAreaQueries ??
          await WeatherLocationService.resolveAdministrativeAreaQueries(
            latitude: latitude,
            longitude: longitude,
            client: localClient,
            kakaoRestApiKey: normalizedKakaoKey,
          );

      if (queries.isEmpty) {
        return const AirQualitySnapshot();
      }

      final stationName = await _resolveStationName(
        client: localClient,
        serviceKey: normalizedKey,
        queries: queries,
      );
      if (stationName.isEmpty) {
        return const AirQualitySnapshot();
      }

      return _fetchStationMeasurement(
        client: localClient,
        serviceKey: normalizedKey,
        stationName: stationName,
      );
    } finally {
      if (ownsClient) {
        localClient.close();
      }
    }
  }

  static Future<String> _resolveNearbyStationName({
    required http.Client client,
    required String kakaoRestApiKey,
    required double latitude,
    required double longitude,
    required String serviceKey,
  }) async {
    if (kakaoRestApiKey.isEmpty) return '';

    final tmCoordinates = await _convertToTmCoordinates(
      client: client,
      kakaoRestApiKey: kakaoRestApiKey,
      latitude: latitude,
      longitude: longitude,
    );
    if (tmCoordinates == null) return '';

    for (final keyName in const <String>['serviceKey', 'ServiceKey']) {
      final uri = Uri.https(
        'apis.data.go.kr',
        '/B552584/MsrstnInfoInqireSvc/getNearbyMsrstnList',
        <String, String>{
          keyName: serviceKey,
          'returnType': 'json',
          'numOfRows': '10',
          'pageNo': '1',
          'tmX': tmCoordinates.x,
          'tmY': tmCoordinates.y,
        },
      );
      final response = await client.get(uri);
      if (response.statusCode != 200) continue;
      final items = _parseAirKoreaItems(response.bodyBytes);
      if (items == null || items.isEmpty) continue;
      for (final item in items) {
        final stationName = (item['stationName'] ?? '').toString().trim();
        if (stationName.isNotEmpty) {
          return stationName;
        }
      }
    }

    return '';
  }

  static Future<String> _resolveStationName({
    required http.Client client,
    required String serviceKey,
    required List<String> queries,
  }) async {
    for (final keyName in const <String>['serviceKey', 'ServiceKey']) {
      for (final query in queries) {
        final uri = Uri.https(
          'apis.data.go.kr',
          '/B552584/MsrstnInfoInqireSvc/getMsrstnList',
          <String, String>{
            keyName: serviceKey,
            'returnType': 'json',
            'numOfRows': '20',
            'pageNo': '1',
            'addr': query,
          },
        );
        final response = await client.get(uri);
        if (response.statusCode != 200) continue;
        final items = _parseAirKoreaItems(response.bodyBytes);
        if (items == null || items.isEmpty) continue;
        for (final item in items) {
          final stationName = (item['stationName'] ?? '').toString().trim();
          if (stationName.isNotEmpty) return stationName;
        }
      }
    }
    return '';
  }

  static Future<AirQualitySnapshot> _fetchStationMeasurement({
    required http.Client client,
    required String serviceKey,
    required String stationName,
  }) async {
    for (final keyName in const <String>['serviceKey', 'ServiceKey']) {
      final uri = Uri.https(
        'apis.data.go.kr',
        '/B552584/ArpltnInforInqireSvc/getMsrstnAcctoRltmMesureDnsty',
        <String, String>{
          keyName: serviceKey,
          'returnType': 'json',
          'numOfRows': '1',
          'pageNo': '1',
          'stationName': stationName,
          'dataTerm': 'DAILY',
          'ver': '1.3',
        },
      );
      final response = await client.get(uri);
      if (response.statusCode != 200) continue;
      final items = _parseAirKoreaItems(response.bodyBytes);
      if (items == null || items.isEmpty) continue;
      final item = items.first;
      final pm10 = _parseAirKoreaDouble(item['pm10Value']);
      final pm25 = _parseAirKoreaDouble(item['pm25Value']);
      final khai = _parseAirKoreaInt(item['khaiValue']);
      if (pm10 == null && pm25 == null && khai == null) continue;
      return AirQualitySnapshot(
        pm10: pm10,
        pm25: pm25,
        aqi: khai,
        scale: AirQualityScale.khai,
      );
    }
    return const AirQualitySnapshot();
  }

  static Future<_TmCoordinates?> _convertToTmCoordinates({
    required http.Client client,
    required String kakaoRestApiKey,
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.https(
      'dapi.kakao.com',
      '/v2/local/geo/transcoord.json',
      <String, String>{
        'x': longitude.toString(),
        'y': latitude.toString(),
        'input_coord': 'WGS84',
        'output_coord': 'TM',
      },
    );
    final response = await client.get(
      uri,
      headers: <String, String>{
        'Authorization': 'KakaoAK $kakaoRestApiKey',
      },
    );
    if (response.statusCode != 200) return null;

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) return null;
    final documents = decoded['documents'];
    if (documents is! List || documents.isEmpty) return null;
    final first = documents.first;
    if (first is! Map<String, dynamic>) return null;

    final x = first['x']?.toString().trim() ?? '';
    final y = first['y']?.toString().trim() ?? '';
    if (x.isEmpty || y.isEmpty) return null;
    return _TmCoordinates(x: x, y: y);
  }

  static List<Map<String, dynamic>>? _parseAirKoreaItems(List<int> bodyBytes) {
    final decoded = jsonDecode(utf8.decode(bodyBytes));
    if (decoded is! Map<String, dynamic>) return null;
    final response = decoded['response'];
    if (response is! Map<String, dynamic>) return null;
    final header = response['header'];
    if (header is! Map<String, dynamic>) return null;
    if ((header['resultCode'] ?? '').toString() != '00') {
      return null;
    }
    final body = response['body'];
    if (body is! Map<String, dynamic>) return null;
    final items = body['items'];
    if (items is List) {
      return items
          .whereType<Map>()
          .map((value) => value.cast<String, dynamic>())
          .toList(growable: false);
    }
    if (items is Map<String, dynamic>) {
      return <Map<String, dynamic>>[items];
    }
    return null;
  }

  static double? _parseAirKoreaDouble(Object? value) {
    final normalized = value?.toString().trim() ?? '';
    if (normalized.isEmpty || normalized == '-') return null;
    return double.tryParse(normalized);
  }

  static int? _parseAirKoreaInt(Object? value) {
    final normalized = value?.toString().trim() ?? '';
    if (normalized.isEmpty || normalized == '-') return null;
    return int.tryParse(normalized);
  }
}

class _TmCoordinates {
  const _TmCoordinates({
    required this.x,
    required this.y,
  });

  final String x;
  final String y;
}
