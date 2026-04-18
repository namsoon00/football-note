import 'dart:convert';

import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

import 'government_api_credentials.dart';

class WeatherLocationService {
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
            kakaoRestApiKey:
                kakaoRestApiKey ?? GovernmentApiCredentials.kakaoRestApiKey,
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

  static Future<List<String>> resolveAdministrativeAreaQueries({
    required double latitude,
    required double longitude,
    http.Client? client,
    String? kakaoRestApiKey,
  }) async {
    if (!isLikelyInKorea(latitude, longitude)) {
      return const <String>[];
    }

    final localClient = client ?? http.Client();
    final ownsClient = client == null;
    try {
      final normalizedKey =
          (kakaoRestApiKey ?? GovernmentApiCredentials.kakaoRestApiKey).trim();
      if (normalizedKey.isNotEmpty) {
        try {
          final regionDocument = await _requestKakaoRegionDocument(
            latitude: latitude,
            longitude: longitude,
            client: localClient,
            kakaoRestApiKey: normalizedKey,
          );
          final regionQueries = _buildStationQueriesFromRegionDocument(
            regionDocument,
          );
          if (regionQueries.isNotEmpty) {
            return regionQueries;
          }
        } catch (_) {
          // Fall through to native geocoding and secondary lookups.
        }
      }

      final nativeQueries = _buildStationQueriesFromPlacemark(
        await _resolveNativePlacemark(
          latitude: latitude,
          longitude: longitude,
        ),
      );
      if (nativeQueries.isNotEmpty) {
        return nativeQueries;
      }

      if (normalizedKey.isNotEmpty) {
        try {
          final addressLabel = await _resolveKakaoAddressName(
            latitude: latitude,
            longitude: longitude,
            koreaLabel: '대한민국',
            client: localClient,
            kakaoRestApiKey: normalizedKey,
          );
          final addressQueries =
              _buildStationQueriesFromAddressLabel(addressLabel);
          if (addressQueries.isNotEmpty) {
            return addressQueries;
          }
        } catch (_) {
          // Return empty queries if every fallback fails.
        }
      }

      return const <String>[];
    } finally {
      if (ownsClient) {
        localClient.close();
      }
    }
  }

  static Future<String> _resolveKoreanPlaceName({
    required double latitude,
    required double longitude,
    required String koreaLabel,
    required http.Client client,
    required String kakaoRestApiKey,
  }) async {
    final normalizedKey = kakaoRestApiKey.trim();
    if (normalizedKey.isNotEmpty) {
      try {
        final regionDocument = await _requestKakaoRegionDocument(
          latitude: latitude,
          longitude: longitude,
          client: client,
          kakaoRestApiKey: normalizedKey,
        );
        final regionLabel = _buildRegionLabel(
          regionDocument: regionDocument,
          koreaLabel: koreaLabel,
        );
        if (regionLabel.isNotEmpty) return regionLabel;
      } catch (_) {
        // Continue with native geocoding.
      }
    }

    final nativePlacemark = await _resolveNativePlacemark(
      latitude: latitude,
      longitude: longitude,
    );
    final nativeLabel = _buildPlacemarkLabel(
      placemark: nativePlacemark,
      koreaLabel: koreaLabel,
    );
    if (nativeLabel.isNotEmpty) return nativeLabel;

    if (normalizedKey.isEmpty) return '';

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

  static Future<Map<String, dynamic>?> _requestKakaoRegionDocument({
    required double latitude,
    required double longitude,
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
    if (decoded == null) return null;
    final documents = decoded['documents'];
    if (documents is! List || documents.isEmpty) return null;

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
    return administrative ?? fallback;
  }

  static String _buildRegionLabel({
    required Map<String, dynamic>? regionDocument,
    required String koreaLabel,
  }) {
    if (regionDocument == null) return '';
    final region1 =
        (regionDocument['region_1depth_name'] ?? '').toString().trim();
    final region2 =
        (regionDocument['region_2depth_name'] ?? '').toString().trim();
    final region3 =
        (regionDocument['region_3depth_name'] ?? '').toString().trim();
    final region4 =
        (regionDocument['region_4depth_name'] ?? '').toString().trim();
    final addressName =
        (regionDocument['address_name'] ?? '').toString().trim();

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
    return '';
  }

  static List<String> _buildStationQueriesFromRegionDocument(
    Map<String, dynamic>? regionDocument,
  ) {
    if (regionDocument == null) return const <String>[];
    final region1 =
        (regionDocument['region_1depth_name'] ?? '').toString().trim();
    final region2 =
        (regionDocument['region_2depth_name'] ?? '').toString().trim();
    final region3 =
        (regionDocument['region_3depth_name'] ?? '').toString().trim();
    return _dedupeStationQueries(<String>[
      if (region1.isNotEmpty && region2.isNotEmpty) '$region1 $region2',
      if (region2.isNotEmpty && region3.isNotEmpty) '$region2 $region3',
      if (region2.isNotEmpty) region2,
      if (region1.isNotEmpty) region1,
    ]);
  }

  static List<String> _buildStationQueriesFromAddressLabel(String label) {
    final normalized = label.split(',').first.trim();
    if (normalized.isEmpty) return const <String>[];
    final parts = normalized
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) return const <String>[];
    return _dedupeStationQueries(<String>[
      if (parts.length >= 2) '${parts[0]} ${parts[1]}',
      parts.last,
      parts.first,
    ]);
  }

  static Future<Placemark?> _resolveNativePlacemark({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isEmpty) return null;
      return placemarks.first;
    } catch (_) {
      return null;
    }
  }

  static String _buildPlacemarkLabel({
    required Placemark? placemark,
    required String koreaLabel,
  }) {
    if (placemark == null) return '';
    final region1 = placemark.administrativeArea?.trim() ?? '';
    final region2 = _firstNonEmpty(<String?>[
      placemark.subAdministrativeArea,
      placemark.locality,
    ]);
    final region3 = _firstNonEmpty(<String?>[
      placemark.subLocality,
      placemark.thoroughfare,
      placemark.subThoroughfare,
    ]);
    final parts = <String>[
      if (region2.isNotEmpty) region2,
      if (region3.isNotEmpty && region3 != region2) region3,
    ];
    if (parts.isNotEmpty) {
      return '${parts.join(' ')}, $koreaLabel';
    }
    if (region1.isNotEmpty) return '$region1, $koreaLabel';
    return '';
  }

  static List<String> _buildStationQueriesFromPlacemark(Placemark? placemark) {
    if (placemark == null) return const <String>[];
    final region1 = placemark.administrativeArea?.trim() ?? '';
    final region2 = _firstNonEmpty(<String?>[
      placemark.subAdministrativeArea,
      placemark.locality,
    ]);
    final region3 = _firstNonEmpty(<String?>[
      placemark.subLocality,
      placemark.thoroughfare,
    ]);
    return _dedupeStationQueries(<String>[
      if (region1.isNotEmpty && region2.isNotEmpty) '$region1 $region2',
      if (region2.isNotEmpty && region3.isNotEmpty) '$region2 $region3',
      if (region2.isNotEmpty) region2,
      if (region1.isNotEmpty) region1,
    ]);
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

  static List<String> _dedupeStationQueries(List<String> queries) {
    final deduped = <String>[];
    final seen = <String>{};
    for (final query in queries) {
      final normalized = query.trim();
      if (normalized.isEmpty || !seen.add(normalized)) continue;
      deduped.add(normalized);
    }
    return deduped;
  }

  static String _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final normalized = value?.trim() ?? '';
      if (normalized.isNotEmpty) return normalized;
    }
    return '';
  }

  static String _formatCoordinateLabel({
    required double latitude,
    required double longitude,
  }) {
    return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  }
}
