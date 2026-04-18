import 'dart:convert';

import 'package:http/http.dart' as http;

class WeatherLocationService {
  static const String _kakaoRestApiKey = String.fromEnvironment(
    'KAKAO_REST_API_KEY',
  );

  static Future<String> resolvePlaceName({
    required double latitude,
    required double longitude,
    required bool isKo,
    required String koreaLabel,
    http.Client? client,
    String? kakaoRestApiKey,
  }) async {
    final localClient = client ?? http.Client();
    final ownsClient = client == null;
    try {
      if (isLikelyInKorea(latitude, longitude)) {
        final koreanPlace = await _resolveKoreanPlaceName(
          latitude: latitude,
          longitude: longitude,
          koreaLabel: koreaLabel,
          client: localClient,
          kakaoRestApiKey: kakaoRestApiKey ?? _kakaoRestApiKey,
        );
        if (koreanPlace.isNotEmpty) return koreanPlace;
      }
      return _resolveOpenMeteoPlaceName(
        latitude: latitude,
        longitude: longitude,
        isKo: isKo,
        koreaLabel: koreaLabel,
        client: localClient,
      );
    } finally {
      if (ownsClient) {
        localClient.close();
      }
    }
  }

  static bool isLikelyInKorea(double latitude, double longitude) {
    return latitude >= 32.8 &&
        latitude <= 39.0 &&
        longitude >= 124.0 &&
        longitude <= 132.0;
  }

  static Future<String> _resolveKoreanPlaceName({
    required double latitude,
    required double longitude,
    required String koreaLabel,
    required http.Client client,
    required String kakaoRestApiKey,
  }) async {
    final normalizedKey = kakaoRestApiKey.trim();
    if (normalizedKey.isEmpty) return '';

    final uri = Uri.https(
      'dapi.kakao.com',
      '/v2/local/geo/coord2regioncode.json',
      <String, String>{
        'x': longitude.toString(),
        'y': latitude.toString(),
        'input_coord': 'WGS84',
        'output_coord': 'WGS84',
      },
    );
    final response = await client.get(
      uri,
      headers: <String, String>{
        'Authorization': 'KakaoAK $normalizedKey',
      },
    );
    if (response.statusCode != 200) return '';

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) return '';
    final documents = decoded['documents'];
    if (documents is! List || documents.isEmpty) return '';

    Map<String, dynamic>? administrative;
    Map<String, dynamic>? fallback;
    for (final document in documents) {
      if (document is! Map<String, dynamic>) continue;
      fallback ??= document;
      if ((document['region_type'] ?? '').toString().trim() == 'H') {
        administrative = document;
        break;
      }
    }
    final selected = administrative ?? fallback;
    if (selected == null) return '';

    final region1 = (selected['region_1depth_name'] ?? '').toString().trim();
    final region2 = (selected['region_2depth_name'] ?? '').toString().trim();
    final region3 = (selected['region_3depth_name'] ?? '').toString().trim();
    final region4 = (selected['region_4depth_name'] ?? '').toString().trim();
    final addressName = (selected['address_name'] ?? '').toString().trim();

    final compactParts = <String>[
      if (region2.isNotEmpty) region2,
      if (region3.isNotEmpty && region3 != region2) region3,
      if (region4.isNotEmpty && region4 != region3) region4,
    ];
    if (compactParts.isNotEmpty) {
      return '${compactParts.take(3).join(' ')}, $koreaLabel';
    }

    final addressParts = addressName
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList(growable: false);
    if (addressParts.isNotEmpty) {
      final compactAddress = addressParts.length > 3
          ? addressParts.sublist(addressParts.length - 3)
          : addressParts;
      return '${compactAddress.join(' ')}, $koreaLabel';
    }
    if (region1.isNotEmpty) return '$region1, $koreaLabel';
    return koreaLabel;
  }

  static Future<String> _resolveOpenMeteoPlaceName({
    required double latitude,
    required double longitude,
    required bool isKo,
    required String koreaLabel,
    required http.Client client,
  }) async {
    final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/reverse', {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'count': '3',
      'language': isKo ? 'ko' : 'en',
    });
    final response = await client.get(uri);
    if (response.statusCode != 200) return '';
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) return '';
    final results = decoded['results'];
    if (results is! List || results.isEmpty) return '';
    final first = results.first;
    if (first is! Map<String, dynamic>) return '';
    final city = (first['city'] ?? '').toString().trim();
    final neighborhood = (first['admin4'] ?? '').toString().trim();
    final township = (first['admin3'] ?? '').toString().trim();
    final district = (first['admin2'] ?? '').toString().trim();
    final region = (first['admin1'] ?? '').toString().trim();
    final name = (first['name'] ?? '').toString().trim();
    final country = (first['country'] ?? '').toString().trim();
    if (_isKoreaCountry(country)) {
      final localParts = <String>[
        if (neighborhood.isNotEmpty) neighborhood,
        if (township.isNotEmpty && township != neighborhood) township,
        if (district.isNotEmpty &&
            district != neighborhood &&
            district != township &&
            district != city)
          district,
        if (city.isNotEmpty) city,
        if (region.isNotEmpty &&
            region != neighborhood &&
            region != township &&
            region != city &&
            region != district)
          region,
        if (name.isNotEmpty &&
            name != neighborhood &&
            name != township &&
            name != city &&
            name != district &&
            name != region)
          name,
      ];
      if (localParts.isNotEmpty) {
        return '${localParts.take(2).join(' ')}, $koreaLabel';
      }
      if (region.isNotEmpty) return '$region, $koreaLabel';
      return koreaLabel;
    }
    final parts = <String>[
      if (neighborhood.isNotEmpty) neighborhood,
      if (township.isNotEmpty && township != neighborhood) township,
      if (city.isNotEmpty) city,
      if (district.isNotEmpty &&
          district != neighborhood &&
          district != township &&
          district != city)
        district,
      if (region.isNotEmpty &&
          region != neighborhood &&
          region != township &&
          region != city &&
          region != district)
        region,
      if (name.isNotEmpty &&
          name != neighborhood &&
          name != township &&
          name != city &&
          name != district &&
          name != region)
        name,
      if (country.isNotEmpty) country,
    ];
    return parts.take(2).join(', ');
  }

  static bool _isKoreaCountry(String country) {
    final normalized = country.trim().toLowerCase();
    return normalized == 'south korea' ||
        normalized == 'korea' ||
        normalized == 'republic of korea' ||
        country == '대한민국' ||
        country == '한국';
  }
}
