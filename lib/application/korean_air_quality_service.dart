import 'dart:convert';
import 'dart:developer' as developer;

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

      final nearbyStationNames = await _resolveNearbyStationNames(
        client: localClient,
        kakaoRestApiKey: normalizedKakaoKey,
        latitude: latitude,
        longitude: longitude,
        serviceKey: normalizedKey,
      );
      final nearbySnapshot = await _fetchFirstAvailableStationMeasurement(
        client: localClient,
        serviceKey: normalizedKey,
        stationNames: nearbyStationNames,
      );
      if (nearbySnapshot.hasData) {
        return nearbySnapshot;
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

      final regionalSnapshot = await _fetchRegionalMeasurement(
        client: localClient,
        serviceKey: normalizedKey,
        queries: queries,
      );
      if (regionalSnapshot.hasData) {
        return regionalSnapshot;
      }

      final stationNames = await _resolveStationNames(
        client: localClient,
        serviceKey: normalizedKey,
        queries: queries,
      );
      return _fetchFirstAvailableStationMeasurement(
        client: localClient,
        serviceKey: normalizedKey,
        stationNames: stationNames,
      );
    } finally {
      if (ownsClient) {
        localClient.close();
      }
    }
  }

  static Future<List<String>> _resolveNearbyStationNames({
    required http.Client client,
    required String kakaoRestApiKey,
    required double latitude,
    required double longitude,
    required String serviceKey,
  }) async {
    if (kakaoRestApiKey.isEmpty) return const <String>[];

    final tmCoordinates = await _convertToTmCoordinates(
      client: client,
      kakaoRestApiKey: kakaoRestApiKey,
      latitude: latitude,
      longitude: longitude,
    );
    if (tmCoordinates == null) return const <String>[];

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
      if (response.statusCode != 200) {
        _logApiFailure(
          service: 'MsrstnInfoInqireSvc/getNearbyMsrstnList',
          message:
              'status=${response.statusCode} body=${_truncateBody(response.body)}',
        );
        continue;
      }
      final items = _parseAirKoreaItems(response.bodyBytes);
      if (items == null || items.isEmpty) continue;
      return _extractStationNames(items);
    }

    return const <String>[];
  }

  static Future<List<String>> _resolveStationNames({
    required http.Client client,
    required String serviceKey,
    required List<String> queries,
  }) async {
    final stationNames = <String>[];
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
        if (response.statusCode != 200) {
          _logApiFailure(
            service: 'MsrstnInfoInqireSvc/getMsrstnList',
            message:
                'query=$query status=${response.statusCode} body=${_truncateBody(response.body)}',
          );
          continue;
        }
        final items = _parseAirKoreaItems(response.bodyBytes);
        if (items == null || items.isEmpty) continue;
        stationNames.addAll(_extractStationNames(items));
      }
    }
    return _dedupeStationNames(stationNames);
  }

  static Future<AirQualitySnapshot> _fetchFirstAvailableStationMeasurement({
    required http.Client client,
    required String serviceKey,
    required List<String> stationNames,
  }) async {
    for (final stationName in stationNames) {
      final snapshot = await _fetchStationMeasurement(
        client: client,
        serviceKey: serviceKey,
        stationName: stationName,
      );
      if (snapshot.hasData) {
        return snapshot;
      }
    }
    return const AirQualitySnapshot();
  }

  static Future<AirQualitySnapshot> _fetchRegionalMeasurement({
    required http.Client client,
    required String serviceKey,
    required List<String> queries,
  }) async {
    final sidoName = _resolveSidoName(queries);
    if (sidoName.isEmpty) {
      return const AirQualitySnapshot();
    }

    for (final keyName in const <String>['serviceKey', 'ServiceKey']) {
      final uri = Uri.https(
        'apis.data.go.kr',
        '/B552584/ArpltnInforInqireSvc/getCtprvnRltmMesureDnsty',
        <String, String>{
          keyName: serviceKey,
          'returnType': 'json',
          'numOfRows': '200',
          'pageNo': '1',
          'sidoName': sidoName,
          'ver': '1.3',
        },
      );
      final response = await client.get(uri);
      if (response.statusCode != 200) {
        _logApiFailure(
          service: 'ArpltnInforInqireSvc/getCtprvnRltmMesureDnsty',
          message:
              'sidoName=$sidoName status=${response.statusCode} body=${_truncateBody(response.body)}',
        );
        continue;
      }
      final items = _parseAirKoreaItems(response.bodyBytes);
      if (items == null || items.isEmpty) continue;
      final selectedItem = _selectRegionalMeasurementItem(
        items: items,
        queries: queries,
      );
      if (selectedItem == null) continue;
      final snapshot = _snapshotFromMeasurementItem(selectedItem);
      if (snapshot.hasData) {
        return snapshot;
      }
    }

    return const AirQualitySnapshot();
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
          'numOfRows': '24',
          'pageNo': '1',
          'stationName': stationName,
          'dataTerm': 'DAILY',
          'ver': '1.3',
        },
      );
      final response = await client.get(uri);
      if (response.statusCode != 200) {
        _logApiFailure(
          service: 'ArpltnInforInqireSvc/getMsrstnAcctoRltmMesureDnsty',
          message:
              'stationName=$stationName status=${response.statusCode} body=${_truncateBody(response.body)}',
        );
        continue;
      }
      final items = _parseAirKoreaItems(response.bodyBytes);
      if (items == null || items.isEmpty) continue;
      for (final item in items) {
        final snapshot = _snapshotFromMeasurementItem(item);
        if (snapshot.hasData) {
          return snapshot;
        }
      }
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
    try {
      final decoded = jsonDecode(utf8.decode(bodyBytes, allowMalformed: true));
      if (decoded is! Map<String, dynamic>) return null;
      final response = decoded['response'];
      if (response is! Map<String, dynamic>) return null;
      final header = response['header'];
      if (header is! Map<String, dynamic>) return null;
      if ((header['resultCode'] ?? '').toString() != '00') {
        _logApiFailure(
          service: 'AirKorea',
          message:
              'resultCode=${header['resultCode']} resultMsg=${header['resultMsg']}',
        );
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
    } catch (_) {
      _logApiFailure(
        service: 'AirKorea',
        message: 'failed to parse body=${_truncateBodyBytes(bodyBytes)}',
      );
      return null;
    }
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

  static AirQualitySnapshot _snapshotFromMeasurementItem(
    Map<String, dynamic> item,
  ) {
    final pm10 = _parseAirKoreaDouble(item['pm10Value']) ??
        _parseAirKoreaDouble(item['pm10Value24']);
    final pm25 = _parseAirKoreaDouble(item['pm25Value']) ??
        _parseAirKoreaDouble(item['pm25Value24']);
    final khai = _parseAirKoreaInt(item['khaiValue']);
    if (pm10 == null && pm25 == null && khai == null) {
      return const AirQualitySnapshot();
    }
    return AirQualitySnapshot(
      pm10: pm10,
      pm25: pm25,
      aqi: khai,
      scale: AirQualityScale.khai,
    );
  }

  static List<String> _extractStationNames(List<Map<String, dynamic>> items) {
    return _dedupeStationNames(
      items
          .map((item) => (item['stationName'] ?? '').toString().trim())
          .where((stationName) => stationName.isNotEmpty)
          .toList(growable: false),
    );
  }

  static List<String> _dedupeStationNames(List<String> stationNames) {
    final deduped = <String>[];
    final seen = <String>{};
    for (final stationName in stationNames) {
      final normalized = stationName.trim();
      if (normalized.isEmpty || !seen.add(normalized)) continue;
      deduped.add(normalized);
    }
    return deduped;
  }

  static String _resolveSidoName(List<String> queries) {
    for (final query in queries) {
      for (final token in query.split(RegExp(r'[\s,]+'))) {
        final normalized = _normalizeSidoName(token);
        if (normalized.isNotEmpty) {
          return normalized;
        }
      }
    }
    return '';
  }

  static String _normalizeSidoName(String raw) {
    final normalized = raw.trim();
    if (normalized.isEmpty) return '';

    const directMap = <String, String>{
      '서울특별시': '서울',
      '부산광역시': '부산',
      '대구광역시': '대구',
      '인천광역시': '인천',
      '광주광역시': '광주',
      '대전광역시': '대전',
      '울산광역시': '울산',
      '세종특별자치시': '세종',
      '경기도': '경기',
      '강원도': '강원',
      '강원특별자치도': '강원',
      '충청북도': '충북',
      '충청남도': '충남',
      '전라북도': '전북',
      '전북특별자치도': '전북',
      '전라남도': '전남',
      '경상북도': '경북',
      '경상남도': '경남',
      '제주도': '제주',
      '제주특별자치도': '제주',
    };
    return directMap[normalized] ?? '';
  }

  static Map<String, dynamic>? _selectRegionalMeasurementItem({
    required List<Map<String, dynamic>> items,
    required List<String> queries,
  }) {
    final keywords = _buildStationMatchKeywords(queries);
    Map<String, dynamic>? selected;
    var selectedScore = 0;

    for (final item in items) {
      final snapshot = _snapshotFromMeasurementItem(item);
      if (!snapshot.hasData) continue;
      final stationName = (item['stationName'] ?? '').toString().trim();
      if (stationName.isEmpty) continue;
      final score = _stationMatchScore(
        stationName: stationName,
        keywords: keywords,
      );
      if (selected == null || score > selectedScore) {
        selected = item;
        selectedScore = score;
      }
    }

    if (selected != null && selectedScore > 0) {
      return selected;
    }
    return null;
  }

  static List<String> _buildStationMatchKeywords(List<String> queries) {
    final keywords = <String>[];
    for (final query in queries) {
      for (final token in query.split(RegExp(r'[\s,]+'))) {
        final trimmed = token.trim();
        if (trimmed.isEmpty || trimmed == '대한민국') continue;
        keywords.add(trimmed);
        final compact = _compactStationKeyword(trimmed);
        if (compact.isNotEmpty && compact != trimmed) {
          keywords.add(compact);
        }
      }
    }
    return _dedupeStationNames(keywords);
  }

  static String _compactStationKeyword(String raw) {
    var normalized = raw.trim();
    if (normalized.isEmpty) return '';
    normalized = normalized.replaceAll(
      RegExp(r'(특별자치시|특별자치도|특별시|광역시)$'),
      '',
    );
    normalized = normalized.replaceAll(
      RegExp(r'(자치시|자치도|시|도|군|구|읍|면|동|로|대로|가)$'),
      '',
    );
    return normalized.trim();
  }

  static int _stationMatchScore({
    required String stationName,
    required List<String> keywords,
  }) {
    final compactStationName = _compactStationKeyword(stationName);
    var score = 0;
    for (final keyword in keywords) {
      if (keyword == stationName) {
        score += 100;
        continue;
      }
      if (stationName.contains(keyword) || keyword.contains(stationName)) {
        score += 40;
      }
      final compactKeyword = _compactStationKeyword(keyword);
      if (compactKeyword.isEmpty) continue;
      if (compactKeyword == compactStationName) {
        score += 80;
        continue;
      }
      if (compactStationName.contains(compactKeyword) ||
          compactKeyword.contains(compactStationName)) {
        score += 20;
      }
    }
    return score;
  }

  static String _truncateBody(String body) {
    final normalized = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= 180) return normalized;
    return '${normalized.substring(0, 180)}...';
  }

  static String _truncateBodyBytes(List<int> bodyBytes) {
    return _truncateBody(utf8.decode(bodyBytes, allowMalformed: true));
  }

  static void _logApiFailure({
    required String service,
    required String message,
  }) {
    developer.log(
      message,
      name: 'KoreanAirQualityService.$service',
    );
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
