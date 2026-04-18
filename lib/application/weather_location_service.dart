import 'dart:convert';

import 'package:http/http.dart' as http;

class WeatherLocationService {
  static const String _kakaoRestApiKey = 'b5b196f485859aa04a479539caab76a3';

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
        try {
          final koreanPlace = await _resolveKoreanPlaceName(
            latitude: latitude,
            longitude: longitude,
            koreaLabel: koreaLabel,
            client: localClient,
            kakaoRestApiKey: kakaoRestApiKey ?? _kakaoRestApiKey,
          );
          if (koreanPlace.isNotEmpty) return koreanPlace;
        } catch (_) {
          // Fall through to secondary geocoding sources.
        }
      }
      try {
        final openMeteoPlace = await _resolveOpenMeteoPlaceName(
          latitude: latitude,
          longitude: longitude,
          isKo: isKo,
          koreaLabel: koreaLabel,
          client: localClient,
        );
        if (openMeteoPlace.isNotEmpty) return openMeteoPlace;
      } catch (_) {
        // Return a coordinate label if every geocoder fails.
      }
      return _formatCoordinateLabel(
        latitude: latitude,
        longitude: longitude,
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

    final regionLabel = await _resolveKakaoRegionName(
      latitude: latitude,
      longitude: longitude,
      koreaLabel: koreaLabel,
      client: client,
      kakaoRestApiKey: normalizedKey,
    );
    if (regionLabel.isNotEmpty) return regionLabel;

    return _resolveKakaoAddressName(
      latitude: latitude,
      longitude: longitude,
      koreaLabel: koreaLabel,
      client: client,
      kakaoRestApiKey: normalizedKey,
    );
  }

  static Future<String> _resolveKakaoAddressName({
    required double latitude,
    required double longitude,
    required String koreaLabel,
    required http.Client client,
    required String kakaoRestApiKey,
  }) async {
    final uri = Uri.https(
      'dapi.kakao.com',
      '/v2/local/geo/coord2address.json',
      <String, String>{
        'x': longitude.toString(),
        'y': latitude.toString(),
        'input_coord': 'WGS84',
      },
    );
    final decoded = await _requestKakaoJson(
      uri: uri,
      client: client,
      kakaoRestApiKey: kakaoRestApiKey,
    );
    if (decoded == null) return '';
    final documents = decoded['documents'];
    if (documents is! List || documents.isEmpty) return '';
    final first = documents.first;
    if (first is! Map<String, dynamic>) return '';

    final roadAddress = first['road_address'];
    if (roadAddress is Map<String, dynamic>) {
      final roadAddressName =
          (roadAddress['address_name'] ?? '').toString().trim();
      if (roadAddressName.isNotEmpty) {
        return _compactKoreanAddress(
          addressName: roadAddressName,
          koreaLabel: koreaLabel,
        );
      }
    }

    final address = first['address'];
    if (address is Map<String, dynamic>) {
      final addressName = (address['address_name'] ?? '').toString().trim();
      if (addressName.isNotEmpty) {
        return _compactKoreanAddress(
          addressName: addressName,
          koreaLabel: koreaLabel,
        );
      }
    }
    return '';
  }

  static Future<String> _resolveKakaoRegionName({
    required double latitude,
    required double longitude,
    required String koreaLabel,
    required http.Client client,
    required String kakaoRestApiKey,
  }) async {
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
    final decoded = await _requestKakaoJson(
      uri: uri,
      client: client,
      kakaoRestApiKey: kakaoRestApiKey,
    );
    if (decoded == null) return '';
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

  static Future<Map<String, dynamic>?> _requestKakaoJson({
    required Uri uri,
    required http.Client client,
    required String kakaoRestApiKey,
  }) async {
    final response = await client.get(
      uri,
      headers: <String, String>{
        'Authorization': 'KakaoAK $kakaoRestApiKey',
      },
    );
    if (response.statusCode != 200) return null;
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) return null;
    return decoded;
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

  static String _compactKoreanAddress({
    required String addressName,
    required String koreaLabel,
  }) {
    final parts = addressName
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) return koreaLabel;
    final compact = parts.length > 3 ? parts.sublist(parts.length - 3) : parts;
    return '${compact.join(' ')}, $koreaLabel';
  }

  static String _formatCoordinateLabel({
    required double latitude,
    required double longitude,
  }) {
    return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  }
}
