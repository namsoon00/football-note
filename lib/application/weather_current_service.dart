import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import 'government_api_credentials.dart';
import 'weather_forecast_service.dart';
import 'weather_location_service.dart';

enum WeatherDataProvider { openMeteo, koreaMeteorologicalAdministration }

class WeatherCurrentSnapshot {
  const WeatherCurrentSnapshot({
    required this.provider,
    this.temperature,
    this.weatherCode,
    this.humidity,
    this.windSpeed,
    this.precipitation,
  });

  final WeatherDataProvider provider;
  final double? temperature;
  final int? weatherCode;
  final double? humidity;
  final double? windSpeed;
  final double? precipitation;

  bool get hasData =>
      temperature != null ||
      weatherCode != null ||
      humidity != null ||
      windSpeed != null ||
      precipitation != null;
}

class WeatherDetailsSnapshot {
  const WeatherDetailsSnapshot({
    required this.provider,
    this.temperature,
    this.weatherCode,
    this.apparentTemperature,
    this.humidity,
    this.windSpeed,
    this.precipitation,
    this.temperatureMax,
    this.temperatureMin,
    this.dailyForecasts = const <WeatherDailyForecast>[],
  });

  final WeatherDataProvider provider;
  final double? temperature;
  final int? weatherCode;
  final double? apparentTemperature;
  final double? humidity;
  final double? windSpeed;
  final double? precipitation;
  final double? temperatureMax;
  final double? temperatureMin;
  final List<WeatherDailyForecast> dailyForecasts;

  bool get hasData =>
      temperature != null ||
      weatherCode != null ||
      apparentTemperature != null ||
      humidity != null ||
      windSpeed != null ||
      precipitation != null ||
      temperatureMax != null ||
      temperatureMin != null ||
      dailyForecasts.isNotEmpty;
}

class WeatherDailyForecast {
  const WeatherDailyForecast({
    required this.date,
    this.weatherCode,
    this.temperatureMax,
    this.temperatureMin,
    this.precipitationSum,
    this.windSpeedMax,
    this.uvIndexMax,
    this.morningForecast,
    this.eveningForecast,
    this.hourlyPrecipitations = const <WeatherHourlyPrecipitation>[],
  });

  final DateTime date;
  final int? weatherCode;
  final double? temperatureMax;
  final double? temperatureMin;
  final double? precipitationSum;
  final double? windSpeedMax;
  final double? uvIndexMax;
  final WeatherForecastMoment? morningForecast;
  final WeatherForecastMoment? eveningForecast;
  final List<WeatherHourlyPrecipitation> hourlyPrecipitations;
}

class WeatherHourlyPrecipitation {
  const WeatherHourlyPrecipitation({
    required this.time,
    required this.precipitation,
  });

  final DateTime time;
  final double precipitation;
}

class WeatherForecastMoment {
  const WeatherForecastMoment({
    required this.time,
    this.temperature,
    this.weatherCode,
    this.precipitation,
    this.windSpeed,
  });

  final DateTime time;
  final double? temperature;
  final int? weatherCode;
  final double? precipitation;
  final double? windSpeed;

  bool get hasData =>
      temperature != null ||
      weatherCode != null ||
      precipitation != null ||
      windSpeed != null;
}

class WeatherCurrentService {
  const WeatherCurrentService._();

  static List<_KmaForecastZone>? _forecastZoneCache;

  static Future<WeatherCurrentSnapshot> fetchCurrentWeather({
    required double latitude,
    required double longitude,
    http.Client? client,
    String? kmaApiKey,
    DateTime? now,
  }) async {
    final localClient = client ?? http.Client();
    final ownsClient = client == null;
    try {
      final normalizedKey =
          (kmaApiKey ?? GovernmentApiCredentials.dataGoKrServiceKey).trim();
      if (normalizedKey.isNotEmpty &&
          WeatherLocationService.isLikelyInKorea(latitude, longitude)) {
        final koreanSnapshot = await _fetchKoreanCurrentWeather(
          latitude: latitude,
          longitude: longitude,
          client: localClient,
          apiKey: normalizedKey,
          now: now ?? DateTime.now(),
        );
        return koreanSnapshot ??
            const WeatherCurrentSnapshot(
              provider: WeatherDataProvider.koreaMeteorologicalAdministration,
            );
      }

      return _fetchOpenMeteoCurrentWeather(
        latitude: latitude,
        longitude: longitude,
        client: localClient,
      );
    } finally {
      if (ownsClient) {
        localClient.close();
      }
    }
  }

  static Future<WeatherDetailsSnapshot> fetchDetailedWeather({
    required double latitude,
    required double longitude,
    http.Client? client,
    String? kmaApiKey,
    DateTime? now,
  }) async {
    final localClient = client ?? http.Client();
    final ownsClient = client == null;
    try {
      final normalizedKey =
          (kmaApiKey ?? GovernmentApiCredentials.dataGoKrServiceKey).trim();
      if (normalizedKey.isNotEmpty &&
          WeatherLocationService.isLikelyInKorea(latitude, longitude)) {
        final koreanSnapshot = await _fetchKoreanDetailedWeather(
          latitude: latitude,
          longitude: longitude,
          client: localClient,
          apiKey: normalizedKey,
          now: now ?? DateTime.now(),
        );
        if (koreanSnapshot == null) {
          return const WeatherDetailsSnapshot(
            provider: WeatherDataProvider.koreaMeteorologicalAdministration,
          );
        }

        if (koreanSnapshot.hasData &&
            koreanSnapshot.dailyForecasts.length < 7) {
          try {
            final openMeteoSnapshot = await _fetchOpenMeteoDetailedWeather(
              latitude: latitude,
              longitude: longitude,
              client: localClient,
            );
            return _supplementDetailedForecasts(
              primary: koreanSnapshot,
              supplement: openMeteoSnapshot,
            );
          } catch (_) {
            return koreanSnapshot;
          }
        }

        return koreanSnapshot;
      }

      return _fetchOpenMeteoDetailedWeather(
        latitude: latitude,
        longitude: longitude,
        client: localClient,
      );
    } finally {
      if (ownsClient) {
        localClient.close();
      }
    }
  }

  static Future<WeatherCurrentSnapshot> _fetchOpenMeteoCurrentWeather({
    required double latitude,
    required double longitude,
    required http.Client client,
  }) async {
    final uri = WeatherForecastService.buildForecastUri(
      latitude: latitude,
      longitude: longitude,
      current: const <String>[
        'temperature_2m',
        'weather_code',
        'relative_humidity_2m',
        'precipitation',
        'wind_speed_10m',
      ],
    );
    final response = await client.get(uri);
    if (response.statusCode != 200) {
      return const WeatherCurrentSnapshot(
        provider: WeatherDataProvider.openMeteo,
      );
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      return const WeatherCurrentSnapshot(
        provider: WeatherDataProvider.openMeteo,
      );
    }
    final current = decoded['current'];
    if (current is! Map<String, dynamic>) {
      return const WeatherCurrentSnapshot(
        provider: WeatherDataProvider.openMeteo,
      );
    }

    return WeatherCurrentSnapshot(
      provider: WeatherDataProvider.openMeteo,
      temperature: (current['temperature_2m'] as num?)?.toDouble(),
      weatherCode: (current['weather_code'] as num?)?.toInt(),
      humidity: (current['relative_humidity_2m'] as num?)?.toDouble(),
      precipitation: (current['precipitation'] as num?)?.toDouble(),
      windSpeed: (current['wind_speed_10m'] as num?)?.toDouble(),
    );
  }

  static Future<WeatherDetailsSnapshot> _fetchOpenMeteoDetailedWeather({
    required double latitude,
    required double longitude,
    required http.Client client,
  }) async {
    final uri = WeatherForecastService.buildForecastUri(
      latitude: latitude,
      longitude: longitude,
      current: const <String>[
        'temperature_2m',
        'apparent_temperature',
        'relative_humidity_2m',
        'precipitation',
        'weather_code',
        'wind_speed_10m',
      ],
      hourly: const <String>[
        'temperature_2m',
        'weather_code',
        'precipitation',
        'wind_speed_10m',
      ],
      daily: const <String>[
        'weather_code',
        'uv_index_max',
        'temperature_2m_max',
        'temperature_2m_min',
        'precipitation_sum',
        'wind_speed_10m_max',
      ],
      forecastDays: 7,
    );
    final response = await client.get(uri);
    if (response.statusCode != 200) {
      return const WeatherDetailsSnapshot(
        provider: WeatherDataProvider.openMeteo,
      );
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      return const WeatherDetailsSnapshot(
        provider: WeatherDataProvider.openMeteo,
      );
    }
    final current = decoded['current'];
    final hourly = decoded['hourly'];
    final daily = decoded['daily'];
    final currentMap =
        current is Map<String, dynamic> ? current : const <String, dynamic>{};
    final hourlyMap =
        hourly is Map<String, dynamic> ? hourly : const <String, dynamic>{};
    final dailyMap =
        daily is Map<String, dynamic> ? daily : const <String, dynamic>{};
    final hourlyForecastsByDay = _buildOpenMeteoHourlyForecastsByDay(hourlyMap);
    final forecasts = _buildOpenMeteoDailyForecasts(
      dailyMap,
      hourlyForecastsByDay: hourlyForecastsByDay,
    );

    return WeatherDetailsSnapshot(
      provider: WeatherDataProvider.openMeteo,
      temperature: (currentMap['temperature_2m'] as num?)?.toDouble(),
      weatherCode: (currentMap['weather_code'] as num?)?.toInt(),
      apparentTemperature:
          (currentMap['apparent_temperature'] as num?)?.toDouble(),
      humidity: (currentMap['relative_humidity_2m'] as num?)?.toDouble(),
      precipitation: (currentMap['precipitation'] as num?)?.toDouble(),
      windSpeed: (currentMap['wind_speed_10m'] as num?)?.toDouble(),
      temperatureMax: forecasts.isEmpty ? null : forecasts.first.temperatureMax,
      temperatureMin: forecasts.isEmpty ? null : forecasts.first.temperatureMin,
      dailyForecasts: forecasts,
    );
  }

  static WeatherDetailsSnapshot _supplementDetailedForecasts({
    required WeatherDetailsSnapshot primary,
    required WeatherDetailsSnapshot supplement,
  }) {
    if (primary.dailyForecasts.length >= 7 || !supplement.hasData) {
      return primary;
    }

    final mergedForecasts = _mergeDetailedForecastLists(
      primary: primary.dailyForecasts,
      supplement: supplement.dailyForecasts,
    );
    final firstForecast =
        mergedForecasts.isEmpty ? null : mergedForecasts.first;

    return WeatherDetailsSnapshot(
      provider: primary.provider,
      temperature: primary.temperature ?? supplement.temperature,
      weatherCode: primary.weatherCode ?? supplement.weatherCode,
      apparentTemperature:
          primary.apparentTemperature ?? supplement.apparentTemperature,
      humidity: primary.humidity ?? supplement.humidity,
      windSpeed: primary.windSpeed ?? supplement.windSpeed,
      precipitation: primary.precipitation ?? supplement.precipitation,
      temperatureMax: primary.temperatureMax ??
          supplement.temperatureMax ??
          firstForecast?.temperatureMax,
      temperatureMin: primary.temperatureMin ??
          supplement.temperatureMin ??
          firstForecast?.temperatureMin,
      dailyForecasts: mergedForecasts,
    );
  }

  static List<WeatherDailyForecast> _mergeDetailedForecastLists({
    required List<WeatherDailyForecast> primary,
    required List<WeatherDailyForecast> supplement,
  }) {
    final mergedByDate = <DateTime, WeatherDailyForecast>{};

    for (final forecast in primary) {
      final date = _normalizeForecastDate(forecast.date);
      mergedByDate[date] = _normalizedDailyForecast(forecast);
    }

    for (final forecast in supplement) {
      final date = _normalizeForecastDate(forecast.date);
      final existing = mergedByDate[date];
      final normalizedForecast = _normalizedDailyForecast(forecast);
      mergedByDate[date] = existing == null
          ? normalizedForecast
          : _mergeDailyForecast(
              primary: existing,
              supplement: normalizedForecast,
            );
    }

    final dates = mergedByDate.keys.toList()..sort();
    return dates
        .take(7)
        .map((date) => mergedByDate[date]!)
        .toList(growable: false);
  }

  static WeatherDailyForecast _normalizedDailyForecast(
      WeatherDailyForecast forecast) {
    return WeatherDailyForecast(
      date: _normalizeForecastDate(forecast.date),
      weatherCode: forecast.weatherCode,
      temperatureMax: forecast.temperatureMax,
      temperatureMin: forecast.temperatureMin,
      precipitationSum: forecast.precipitationSum,
      windSpeedMax: forecast.windSpeedMax,
      uvIndexMax: forecast.uvIndexMax,
      morningForecast: forecast.morningForecast,
      eveningForecast: forecast.eveningForecast,
      hourlyPrecipitations: forecast.hourlyPrecipitations,
    );
  }

  static WeatherDailyForecast _mergeDailyForecast({
    required WeatherDailyForecast primary,
    required WeatherDailyForecast supplement,
  }) {
    return WeatherDailyForecast(
      date: _normalizeForecastDate(primary.date),
      weatherCode: primary.weatherCode ?? supplement.weatherCode,
      temperatureMax: primary.temperatureMax ?? supplement.temperatureMax,
      temperatureMin: primary.temperatureMin ?? supplement.temperatureMin,
      precipitationSum: primary.precipitationSum ?? supplement.precipitationSum,
      windSpeedMax: primary.windSpeedMax ?? supplement.windSpeedMax,
      uvIndexMax: primary.uvIndexMax ?? supplement.uvIndexMax,
      morningForecast: primary.morningForecast ?? supplement.morningForecast,
      eveningForecast: primary.eveningForecast ?? supplement.eveningForecast,
      hourlyPrecipitations: primary.hourlyPrecipitations.isNotEmpty
          ? primary.hourlyPrecipitations
          : supplement.hourlyPrecipitations,
    );
  }

  static DateTime _normalizeForecastDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static Future<WeatherCurrentSnapshot?> _fetchKoreanCurrentWeather({
    required double latitude,
    required double longitude,
    required http.Client client,
    required String apiKey,
    required DateTime now,
  }) async {
    final grid = _toForecastGrid(latitude: latitude, longitude: longitude);
    final currentItems = await _requestKmaItems(
      client: client,
      apiKey: apiKey,
      endpoint: 'getUltraSrtNcst',
      grid: grid,
      baseTimes: _ultraShortBaseTimes(now),
      numOfRows: 60,
    );
    if (currentItems == null || currentItems.isEmpty) return null;

    final currentValues = <String, String>{};
    for (final item in currentItems) {
      final category = (item['category'] ?? '').toString().trim();
      final observed = (item['obsrValue'] ?? '').toString().trim();
      if (category.isEmpty || observed.isEmpty) continue;
      currentValues[category] = observed;
    }

    final forecastItems = await _requestKmaItems(
      client: client,
      apiKey: apiKey,
      endpoint: 'getVilageFcst',
      grid: grid,
      baseTimes: <_KmaBaseTime>[_villageForecastBaseTime(now)],
      numOfRows: 1000,
    );

    final nearestForecastValues = forecastItems == null
        ? const <String, String>{}
        : _nearestForecastValues(items: forecastItems, targetTime: _toKst(now));

    final precipitationType = _parseKmaInt(currentValues['PTY']) ??
        _parseKmaInt(nearestForecastValues['PTY']);
    final sky = _parseKmaInt(nearestForecastValues['SKY']);

    return WeatherCurrentSnapshot(
      provider: WeatherDataProvider.koreaMeteorologicalAdministration,
      temperature: _parseKmaDouble(currentValues['T1H']),
      humidity: _parseKmaDouble(currentValues['REH']),
      precipitation: _parseKmaPrecipitation(currentValues['RN1']),
      windSpeed: _parseKmaDouble(currentValues['WSD']),
      weatherCode: _mapKoreanWeatherCode(
        precipitationType: precipitationType,
        sky: sky,
      ),
    );
  }

  static Future<WeatherDetailsSnapshot?> _fetchKoreanDetailedWeather({
    required double latitude,
    required double longitude,
    required http.Client client,
    required String apiKey,
    required DateTime now,
  }) async {
    final grid = _toForecastGrid(latitude: latitude, longitude: longitude);
    final currentItems = await _requestKmaItems(
      client: client,
      apiKey: apiKey,
      endpoint: 'getUltraSrtNcst',
      grid: grid,
      baseTimes: _ultraShortBaseTimes(now),
      numOfRows: 60,
    );
    final forecastItems = await _requestKmaItems(
      client: client,
      apiKey: apiKey,
      endpoint: 'getVilageFcst',
      grid: grid,
      baseTimes: <_KmaBaseTime>[_villageForecastBaseTime(now)],
      numOfRows: 1000,
    );

    final currentValues = <String, String>{};
    if (currentItems != null) {
      for (final item in currentItems) {
        final category = (item['category'] ?? '').toString().trim();
        final observed = (item['obsrValue'] ?? '').toString().trim();
        if (category.isEmpty || observed.isEmpty) continue;
        currentValues[category] = observed;
      }
    }

    final forecastValuesByTime = forecastItems == null
        ? const <DateTime, Map<String, String>>{}
        : _forecastValuesByTime(forecastItems);
    final nearestForecastValues = forecastValuesByTime.isEmpty
        ? const <String, String>{}
        : _nearestForecastValues(
            items: forecastItems!,
            targetTime: _toKst(now),
          );
    if (currentValues.isEmpty && nearestForecastValues.isEmpty) {
      return null;
    }

    final temperature = _parseKmaDouble(currentValues['T1H']) ??
        _parseKmaDouble(nearestForecastValues['TMP']);
    final humidity = _parseKmaDouble(currentValues['REH']) ??
        _parseKmaDouble(nearestForecastValues['REH']);
    final windSpeed = _parseKmaDouble(currentValues['WSD']) ??
        _parseKmaDouble(nearestForecastValues['WSD']);
    final precipitation = _parseKmaPrecipitation(currentValues['RN1']) ??
        _parseKmaPrecipitation(nearestForecastValues['PCP']);
    final precipitationType = _parseKmaInt(currentValues['PTY']) ??
        _parseKmaInt(nearestForecastValues['PTY']);
    final sky = _parseKmaInt(nearestForecastValues['SKY']);
    final shortRangeDailyForecasts = _buildKmaDailyForecasts(
      forecastValuesByTime,
    );
    List<WeatherDailyForecast> midRangeDailyForecasts =
        const <WeatherDailyForecast>[];
    try {
      midRangeDailyForecasts = await _fetchKmaMidRangeDailyForecasts(
        latitude: latitude,
        longitude: longitude,
        client: client,
        apiKey: apiKey,
        now: now,
      );
    } catch (_) {
      midRangeDailyForecasts = const <WeatherDailyForecast>[];
    }
    final dailyForecasts = _mergeKmaDailyForecasts(
      shortRange: shortRangeDailyForecasts,
      midRange: midRangeDailyForecasts,
      anchorDate: _toKst(now),
    );

    return WeatherDetailsSnapshot(
      provider: WeatherDataProvider.koreaMeteorologicalAdministration,
      temperature: temperature,
      weatherCode: _mapKoreanWeatherCode(
        precipitationType: precipitationType,
        sky: sky,
      ),
      apparentTemperature: _calculateApparentTemperature(
        temperature: temperature,
        humidity: humidity,
        windSpeed: windSpeed,
      ),
      humidity: humidity,
      precipitation: precipitation,
      windSpeed: windSpeed,
      temperatureMax:
          dailyForecasts.isEmpty ? null : dailyForecasts.first.temperatureMax,
      temperatureMin:
          dailyForecasts.isEmpty ? null : dailyForecasts.first.temperatureMin,
      dailyForecasts: dailyForecasts,
    );
  }

  static Future<List<WeatherDailyForecast>> _fetchKmaMidRangeDailyForecasts({
    required double latitude,
    required double longitude,
    required http.Client client,
    required String apiKey,
    required DateTime now,
  }) async {
    final forecastZones = await _fetchKmaForecastZones(
      client: client,
      apiKey: apiKey,
    );
    if (forecastZones.isEmpty) return const <WeatherDailyForecast>[];

    final zone = _selectNearestForecastZone(
      latitude: latitude,
      longitude: longitude,
      zones: forecastZones,
    );
    if (zone == null) return const <WeatherDailyForecast>[];

    final zoneById = <String, _KmaForecastZone>{
      for (final forecastZone in forecastZones)
        forecastZone.regId: forecastZone,
    };
    final stationIds = _midForecastStationIdCandidates(
      zone: zone,
      zonesById: zoneById,
    );
    if (stationIds.isEmpty) {
      return const <WeatherDailyForecast>[];
    }

    for (final tmFc in _midForecastBaseTimes(now)) {
      final midForecastResponse = await _requestKmaMidForecastItemForTmFc(
        client: client,
        apiKey: apiKey,
        tmFc: tmFc,
        stationIds: stationIds,
      );
      if (midForecastResponse == null) {
        continue;
      }

      final forecasts = _buildKmaMidRangeDailyForecasts(
        forecast: midForecastResponse.item,
        tmFc: midForecastResponse.tmFc,
      );
      if (forecasts.isNotEmpty) {
        return forecasts;
      }
    }

    return const <WeatherDailyForecast>[];
  }

  static Future<List<Map<String, dynamic>>?> _requestKmaItems({
    required http.Client client,
    required String apiKey,
    required String endpoint,
    required _ForecastGrid grid,
    required List<_KmaBaseTime> baseTimes,
    required int numOfRows,
  }) async {
    for (final serviceKeyName in const <String>['ServiceKey', 'serviceKey']) {
      for (final baseTime in baseTimes) {
        final uri = Uri.https(
          'apis.data.go.kr',
          '/1360000/VilageFcstInfoService_2.0/$endpoint',
          <String, String>{
            serviceKeyName: apiKey,
            'pageNo': '1',
            'numOfRows': '$numOfRows',
            'dataType': 'JSON',
            'base_date': baseTime.date,
            'base_time': baseTime.time,
            'nx': '${grid.x}',
            'ny': '${grid.y}',
          },
        );
        final response = await client.get(uri);
        if (response.statusCode != 200) {
          _logKmaFailure(
            service: endpoint,
            message:
                'baseDate=${baseTime.date} baseTime=${baseTime.time} status=${response.statusCode} body=${_truncateBody(response.body)}',
          );
          continue;
        }
        final items = _parseKmaItems(response.bodyBytes);
        if (items != null && items.isNotEmpty) {
          return items;
        }
      }
    }
    return null;
  }

  static Future<_KmaMidForecastResponse?> _requestKmaMidForecastItemForTmFc({
    required http.Client client,
    required String apiKey,
    required String tmFc,
    required List<String> stationIds,
  }) async {
    for (final serviceKeyName in const <String>['ServiceKey', 'serviceKey']) {
      for (final stationId in stationIds) {
        final uri = Uri.https(
          'apis.data.go.kr',
          '/1360000/MidFcstInfoService/getMidFcst',
          <String, String>{
            serviceKeyName: apiKey,
            'pageNo': '1',
            'numOfRows': '10',
            'dataType': 'JSON',
            'stnId': stationId,
            'tmFc': tmFc,
          },
        );
        final response = await client.get(uri);
        if (response.statusCode != 200) {
          _logKmaFailure(
            service: 'getMidFcst',
            message:
                'tmFc=$tmFc stnId=$stationId status=${response.statusCode} body=${_truncateBody(response.body)}',
          );
          continue;
        }
        final items = _parseKmaItems(response.bodyBytes);
        if (items == null || items.isEmpty) continue;
        return _KmaMidForecastResponse(
          tmFc: tmFc,
          stationId: stationId,
          item: items.first,
        );
      }
    }
    return null;
  }

  static Future<List<_KmaForecastZone>> _fetchKmaForecastZones({
    required http.Client client,
    required String apiKey,
  }) async {
    final cached = _forecastZoneCache;
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    for (final serviceKeyName in const <String>['ServiceKey', 'serviceKey']) {
      final zones = <_KmaForecastZone>[];
      for (var page = 1; page <= 10; page++) {
        final uri = Uri.https(
          'apis.data.go.kr',
          '/1360000/FcstZoneInfoService/getFcstZoneCd',
          <String, String>{
            serviceKeyName: apiKey,
            'pageNo': '$page',
            'numOfRows': '999',
            'dataType': 'JSON',
            'tmSt': '201004300900',
            'tmEd': '210012310900',
          },
        );
        final response = await client.get(uri);
        if (response.statusCode != 200) {
          _logKmaFailure(
            service: 'getFcstZoneCd',
            message:
                'page=$page status=${response.statusCode} body=${_truncateBody(response.body)}',
          );
          break;
        }
        final items = _parseKmaItems(response.bodyBytes);
        if (items == null || items.isEmpty) break;
        zones.addAll(
          items.map(_KmaForecastZone.fromItem).whereType<_KmaForecastZone>(),
        );
        if (items.length < 999) break;
      }
      if (zones.isNotEmpty) {
        final deduped = _dedupeForecastZones(zones);
        _forecastZoneCache = deduped;
        return deduped;
      }
    }

    return const <_KmaForecastZone>[];
  }

  static List<_KmaForecastZone> _dedupeForecastZones(
    List<_KmaForecastZone> zones,
  ) {
    final deduped = <String, _KmaForecastZone>{};
    for (final zone in zones) {
      final existing = deduped[zone.regId];
      if (existing == null) {
        deduped[zone.regId] = zone;
        continue;
      }
      final currentScore = _forecastZoneCompletenessScore(zone);
      final existingScore = _forecastZoneCompletenessScore(existing);
      if (currentScore > existingScore) {
        deduped[zone.regId] = zone;
      }
    }
    return deduped.values.toList(growable: false);
  }

  static int _forecastZoneCompletenessScore(_KmaForecastZone zone) {
    var score = 0;
    if (zone.latitude != null && zone.longitude != null) score += 2;
    if (zone.regUp.isNotEmpty) score += 1;
    if (zone.regName.isNotEmpty) score += 1;
    if (zone.weeklyForecastOfficeId.isNotEmpty) score += 1;
    return score;
  }

  static _KmaForecastZone? _selectNearestForecastZone({
    required double latitude,
    required double longitude,
    required List<_KmaForecastZone> zones,
  }) {
    _KmaForecastZone? selected;
    var selectedTypeRank = 1 << 30;
    var selectedDistance = double.infinity;

    for (final zone in zones) {
      if (!_isLandForecastZone(zone.regSp)) continue;
      final zoneLatitude = zone.latitude;
      final zoneLongitude = zone.longitude;
      if (zoneLatitude == null || zoneLongitude == null) continue;

      final typeRank = _forecastZoneTypeRank(zone.regSp);
      final distance = _squaredDistance(
        latitude,
        longitude,
        zoneLatitude,
        zoneLongitude,
      );
      if (typeRank < selectedTypeRank ||
          (typeRank == selectedTypeRank && distance < selectedDistance)) {
        selected = zone;
        selectedTypeRank = typeRank;
        selectedDistance = distance;
      }
    }

    if (selected != null) return selected;
    for (final zone in zones) {
      if (_isLandForecastZone(zone.regSp)) {
        return zone;
      }
    }
    return null;
  }

  static bool _isLandForecastZone(String regSp) {
    return regSp.startsWith('A') ||
        regSp.startsWith('B') ||
        regSp.startsWith('C') ||
        regSp.startsWith('D') ||
        regSp.startsWith('E');
  }

  static int _forecastZoneTypeRank(String regSp) {
    if (regSp.startsWith('C')) return 0;
    if (regSp.startsWith('B')) return 1;
    if (regSp.startsWith('D') || regSp.startsWith('E')) return 2;
    if (regSp.startsWith('A')) return 3;
    return 4;
  }

  static double _squaredDistance(
    double latitude,
    double longitude,
    double otherLatitude,
    double otherLongitude,
  ) {
    final latDelta = latitude - otherLatitude;
    final lonDelta = longitude - otherLongitude;
    return (latDelta * latDelta) + (lonDelta * lonDelta);
  }

  static List<String> _midForecastStationIdCandidates({
    required _KmaForecastZone zone,
    required Map<String, _KmaForecastZone> zonesById,
  }) {
    final lineage = _zoneLineage(zone: zone, zonesById: zonesById);
    return _dedupeStrings(<String>[
      for (final candidate in lineage)
        if (candidate.weeklyForecastOfficeId.isNotEmpty)
          candidate.weeklyForecastOfficeId,
      for (final candidate in lineage)
        if (candidate.regSp.startsWith('A') &&
            candidate.weeklyForecastOfficeId.isNotEmpty)
          candidate.weeklyForecastOfficeId,
    ]);
  }

  static List<_KmaForecastZone> _zoneLineage({
    required _KmaForecastZone zone,
    required Map<String, _KmaForecastZone> zonesById,
  }) {
    final lineage = <_KmaForecastZone>[];
    final visited = <String>{};
    _KmaForecastZone? current = zone;
    while (current != null && visited.add(current.regId)) {
      lineage.add(current);
      current = current.regUp.isEmpty ? null : zonesById[current.regUp];
    }
    return lineage;
  }

  static List<String> _dedupeStrings(List<String> values) {
    final deduped = <String>[];
    final seen = <String>{};
    for (final value in values) {
      final normalized = value.trim();
      if (normalized.isEmpty || !seen.add(normalized)) continue;
      deduped.add(normalized);
    }
    return deduped;
  }

  static List<String> _midForecastBaseTimes(DateTime now) {
    final kst = _toKst(now).subtract(const Duration(minutes: 40));
    final candidates = <String>[];
    for (var daysBack = 0; daysBack <= 1; daysBack++) {
      final day = DateTime(
        kst.year,
        kst.month,
        kst.day,
      ).subtract(Duration(days: daysBack));
      for (final hour in const <int>[18, 6]) {
        final candidate = DateTime(day.year, day.month, day.day, hour);
        if (!candidate.isAfter(kst)) {
          final baseTime = _formatKmaBaseTime(candidate);
          candidates.add('${baseTime.date}${baseTime.time}');
        }
      }
    }
    return candidates;
  }

  static List<WeatherDailyForecast> _buildKmaMidRangeDailyForecasts({
    required Map<String, dynamic>? forecast,
    required String tmFc,
  }) {
    if (forecast == null) {
      return const <WeatherDailyForecast>[];
    }

    final anchorDate = _parseKmaAnchorDate(tmFc);
    if (anchorDate == null) return const <WeatherDailyForecast>[];

    final forecasts = <WeatherDailyForecast>[];
    for (var dayOffset = 3; dayOffset <= 10; dayOffset++) {
      final date = anchorDate.add(Duration(days: dayOffset));
      final weatherCode = _kmaMidRangeWeatherCode(
        forecast: forecast,
        dayOffset: dayOffset,
      );
      final temperatureMin = _parseKmaDouble(
        forecast['taMin$dayOffset']?.toString(),
      );
      final temperatureMax = _parseKmaDouble(
        forecast['taMax$dayOffset']?.toString(),
      );
      if (weatherCode == null &&
          temperatureMin == null &&
          temperatureMax == null) {
        continue;
      }

      forecasts.add(
        WeatherDailyForecast(
          date: date,
          weatherCode: weatherCode,
          temperatureMax: temperatureMax,
          temperatureMin: temperatureMin,
        ),
      );
    }
    return forecasts;
  }

  static DateTime? _parseKmaAnchorDate(String tmFc) {
    if (tmFc.length < 8) return null;
    final year = int.tryParse(tmFc.substring(0, 4));
    final month = int.tryParse(tmFc.substring(4, 6));
    final day = int.tryParse(tmFc.substring(6, 8));
    if (year == null || month == null || day == null) return null;
    return DateTime(year, month, day);
  }

  static int? _kmaMidRangeWeatherCode({
    required Map<String, dynamic>? forecast,
    required int dayOffset,
  }) {
    if (forecast == null) return null;
    if (dayOffset <= 7) {
      final amText = forecast['wf${dayOffset}Am']?.toString();
      final pmText = forecast['wf${dayOffset}Pm']?.toString();
      return _mapKmaMidWeatherTextPairToCode(
        morningText: amText,
        afternoonText: pmText,
      );
    }
    return _mapKmaMidWeatherTextToCode(forecast['wf$dayOffset']?.toString());
  }

  static int? _mapKmaMidWeatherTextPairToCode({
    required String? morningText,
    required String? afternoonText,
  }) {
    final morningCode = _mapKmaMidWeatherTextToCode(morningText);
    final afternoonCode = _mapKmaMidWeatherTextToCode(afternoonText);
    if (morningCode == null) return afternoonCode;
    if (afternoonCode == null) return morningCode;
    final morningSeverity = _weatherCodeSeverity(morningCode);
    final afternoonSeverity = _weatherCodeSeverity(afternoonCode);
    if (morningSeverity > afternoonSeverity) return morningCode;
    if (afternoonSeverity > morningSeverity) return afternoonCode;
    return morningCode >= afternoonCode ? morningCode : afternoonCode;
  }

  static int? _mapKmaMidWeatherTextToCode(String? weatherText) {
    if (weatherText == null) return null;
    final normalized = weatherText.trim();
    if (normalized.isEmpty) return null;

    if ((normalized.contains('비') && normalized.contains('눈')) ||
        normalized.contains('진눈깨비')) {
      return 67;
    }
    if (normalized.contains('눈')) return 71;
    if (normalized.contains('비') || normalized.contains('소나기')) return 61;
    if (normalized.contains('흐림')) return 3;
    if (normalized.contains('구름많')) return 2;
    if (normalized.contains('구름조금')) return 1;
    if (normalized.contains('맑')) return 0;
    return null;
  }

  static List<WeatherDailyForecast> _mergeKmaDailyForecasts({
    required List<WeatherDailyForecast> shortRange,
    required List<WeatherDailyForecast> midRange,
    required DateTime anchorDate,
  }) {
    final today = DateTime(anchorDate.year, anchorDate.month, anchorDate.day);
    final mergedByDate = <DateTime, WeatherDailyForecast>{};

    for (final forecast in [...shortRange, ...midRange]) {
      final date = DateTime(
        forecast.date.year,
        forecast.date.month,
        forecast.date.day,
      );
      if (date.isBefore(today)) continue;
      mergedByDate.putIfAbsent(
        date,
        () => WeatherDailyForecast(
          date: date,
          weatherCode: forecast.weatherCode,
          temperatureMax: forecast.temperatureMax,
          temperatureMin: forecast.temperatureMin,
          precipitationSum: forecast.precipitationSum,
          windSpeedMax: forecast.windSpeedMax,
          uvIndexMax: forecast.uvIndexMax,
          morningForecast: forecast.morningForecast,
          eveningForecast: forecast.eveningForecast,
          hourlyPrecipitations: forecast.hourlyPrecipitations,
        ),
      );
    }

    final dates = mergedByDate.keys.toList()..sort();
    return dates
        .take(7)
        .map((date) => mergedByDate[date]!)
        .toList(growable: false);
  }

  static List<Map<String, dynamic>>? _parseKmaItems(List<int> bodyBytes) {
    try {
      final decoded = jsonDecode(utf8.decode(bodyBytes, allowMalformed: true));
      if (decoded is! Map<String, dynamic>) return null;
      final response = decoded['response'];
      if (response is! Map<String, dynamic>) return null;
      final header = response['header'];
      if (header is! Map<String, dynamic>) return null;
      if ((header['resultCode'] ?? '').toString() != '00') {
        _logKmaFailure(
          service: 'KMA',
          message:
              'resultCode=${header['resultCode']} resultMsg=${header['resultMsg']}',
        );
        return null;
      }
      final body = response['body'];
      if (body is! Map<String, dynamic>) return null;
      final items = body['items'];
      if (items is! Map<String, dynamic>) return null;
      final item = items['item'];
      if (item is List) {
        return item
            .whereType<Map>()
            .map((value) => value.cast<String, dynamic>())
            .toList(growable: false);
      }
      if (item is Map<String, dynamic>) {
        return <Map<String, dynamic>>[item];
      }
      return null;
    } catch (_) {
      _logKmaFailure(
        service: 'KMA',
        message: 'failed to parse body=${_truncateBodyBytes(bodyBytes)}',
      );
      return null;
    }
  }

  static String _truncateBody(String body) {
    final normalized = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= 180) return normalized;
    return '${normalized.substring(0, 180)}...';
  }

  static String _truncateBodyBytes(List<int> bodyBytes) {
    return _truncateBody(utf8.decode(bodyBytes, allowMalformed: true));
  }

  static void _logKmaFailure({
    required String service,
    required String message,
  }) {
    developer.log(message, name: 'WeatherCurrentService.$service');
  }

  static List<_KmaBaseTime> _ultraShortBaseTimes(DateTime now) {
    final kst = _toKst(now).subtract(const Duration(minutes: 10));
    final candidates = <_KmaBaseTime>[];
    var candidate = DateTime(
      kst.year,
      kst.month,
      kst.day,
      kst.hour,
      (kst.minute ~/ 10) * 10,
    );
    for (var index = 0; index < 6; index++) {
      candidates.add(_formatKmaBaseTime(candidate));
      candidate = candidate.subtract(const Duration(minutes: 10));
    }
    return candidates;
  }

  static _KmaBaseTime _villageForecastBaseTime(DateTime now) {
    final kst = _toKst(now).subtract(const Duration(minutes: 15));
    const publishHours = <int>[2, 5, 8, 11, 14, 17, 20, 23];
    for (var index = publishHours.length - 1; index >= 0; index--) {
      final hour = publishHours[index];
      if (kst.hour > hour || (kst.hour == hour && kst.minute >= 0)) {
        return _formatKmaBaseTime(DateTime(kst.year, kst.month, kst.day, hour));
      }
    }
    return _formatKmaBaseTime(
      DateTime(kst.year, kst.month, kst.day).subtract(const Duration(hours: 1)),
    ).copyWith(time: '2300');
  }

  static DateTime _toKst(DateTime dateTime) =>
      dateTime.toUtc().add(const Duration(hours: 9));

  static _KmaBaseTime _formatKmaBaseTime(DateTime dateTime) {
    final date = _pad(dateTime.year, 4) +
        _pad(dateTime.month, 2) +
        _pad(dateTime.day, 2);
    final time = _pad(dateTime.hour, 2) + _pad(dateTime.minute, 2);
    return _KmaBaseTime(date: date, time: time);
  }

  static List<WeatherDailyForecast> _buildOpenMeteoDailyForecasts(
    Map<String, dynamic> daily, {
    Map<DateTime, List<WeatherForecastMoment>> hourlyForecastsByDay =
        const <DateTime, List<WeatherForecastMoment>>{},
  }) {
    final times = daily['time'];
    final codes = daily['weather_code'];
    final maxTemps = daily['temperature_2m_max'];
    final minTemps = daily['temperature_2m_min'];
    final precipitationSums = daily['precipitation_sum'];
    final maxWinds = daily['wind_speed_10m_max'];
    final uvIndexMax = daily['uv_index_max'];
    if (times is! List) return const <WeatherDailyForecast>[];

    final forecasts = <WeatherDailyForecast>[];
    for (var index = 0; index < times.length; index++) {
      final rawDate = times[index]?.toString();
      final date = rawDate == null ? null : DateTime.tryParse(rawDate);
      if (date == null) continue;
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final hourlyForecasts = hourlyForecastsByDay[normalizedDate] ??
          const <WeatherForecastMoment>[];
      forecasts.add(
        WeatherDailyForecast(
          date: date,
          weatherCode: _numberAt(codes: codes, index: index)?.toInt(),
          temperatureMax: _numberAt(codes: maxTemps, index: index),
          temperatureMin: _numberAt(codes: minTemps, index: index),
          precipitationSum: _numberAt(codes: precipitationSums, index: index),
          windSpeedMax: _numberAt(codes: maxWinds, index: index),
          uvIndexMax: _numberAt(codes: uvIndexMax, index: index),
          morningForecast: _pickDailyForecastMoment(
            hourlyForecasts,
            targetHour: 8,
          ),
          eveningForecast: _pickDailyForecastMoment(
            hourlyForecasts,
            targetHour: 19,
          ),
          hourlyPrecipitations: _extractHourlyPrecipitations(hourlyForecasts),
        ),
      );
    }
    return forecasts;
  }

  static Map<DateTime, List<WeatherForecastMoment>>
      _buildOpenMeteoHourlyForecastsByDay(Map<String, dynamic> hourly) {
    final times = hourly['time'];
    final temperatures = hourly['temperature_2m'];
    final weatherCodes = hourly['weather_code'];
    final precipitations = hourly['precipitation'];
    final windSpeeds = hourly['wind_speed_10m'];
    if (times is! List) {
      return const <DateTime, List<WeatherForecastMoment>>{};
    }

    final hourlyByDay = <DateTime, List<WeatherForecastMoment>>{};
    for (var index = 0; index < times.length; index++) {
      final rawTime = times[index]?.toString();
      final time = rawTime == null ? null : DateTime.tryParse(rawTime);
      if (time == null) {
        continue;
      }
      final moment = WeatherForecastMoment(
        time: time,
        temperature: _numberAt(codes: temperatures, index: index),
        weatherCode: _numberAt(codes: weatherCodes, index: index)?.toInt(),
        precipitation: _numberAt(codes: precipitations, index: index),
        windSpeed: _numberAt(codes: windSpeeds, index: index),
      );
      if (!moment.hasData) continue;
      final day = DateTime(time.year, time.month, time.day);
      hourlyByDay.putIfAbsent(day, () => <WeatherForecastMoment>[]).add(moment);
    }
    return hourlyByDay;
  }

  static WeatherForecastMoment? _pickDailyForecastMoment(
    List<WeatherForecastMoment> forecasts, {
    required int targetHour,
  }) {
    if (forecasts.isEmpty) return null;
    WeatherForecastMoment? selected;
    var bestDiffSeconds = 1 << 30;
    for (final forecast in forecasts) {
      final target = DateTime(
        forecast.time.year,
        forecast.time.month,
        forecast.time.day,
        targetHour,
      );
      final diffSeconds = forecast.time.difference(target).inSeconds.abs();
      if (diffSeconds < bestDiffSeconds) {
        bestDiffSeconds = diffSeconds;
        selected = forecast;
      }
    }
    return selected;
  }

  static List<WeatherHourlyPrecipitation> _extractHourlyPrecipitations(
    List<WeatherForecastMoment> forecasts,
  ) {
    return forecasts
        .where((forecast) => (forecast.precipitation ?? 0) > 0)
        .map(
          (forecast) => WeatherHourlyPrecipitation(
            time: forecast.time,
            precipitation: forecast.precipitation!,
          ),
        )
        .toList(growable: false);
  }

  static Map<DateTime, Map<String, String>> _forecastValuesByTime(
    List<Map<String, dynamic>> items,
  ) {
    final forecastsByTime = <DateTime, Map<String, String>>{};
    for (final item in items) {
      final category = (item['category'] ?? '').toString().trim();
      final date = (item['fcstDate'] ?? '').toString().trim();
      final time = (item['fcstTime'] ?? '').toString().trim();
      final value = (item['fcstValue'] ?? '').toString().trim();
      if (category.isEmpty || date.isEmpty || time.isEmpty || value.isEmpty) {
        continue;
      }
      final forecastAt = _parseForecastDateTime(date, time);
      if (forecastAt == null) continue;
      forecastsByTime.putIfAbsent(
        forecastAt,
        () => <String, String>{},
      )[category] = value;
    }
    return forecastsByTime;
  }

  static List<WeatherDailyForecast> _buildKmaDailyForecasts(
    Map<DateTime, Map<String, String>> forecastsByTime,
  ) {
    if (forecastsByTime.isEmpty) return const <WeatherDailyForecast>[];

    final daily = <DateTime, _KmaDailyAccumulator>{};
    final sortedTimes = forecastsByTime.keys.toList()..sort();
    for (final forecastAt in sortedTimes) {
      final values = forecastsByTime[forecastAt]!;
      final date = DateTime(forecastAt.year, forecastAt.month, forecastAt.day);
      final accumulator = daily.putIfAbsent(
        date,
        () => _KmaDailyAccumulator(date),
      );
      accumulator.consume(forecastAt: forecastAt, values: values);
    }

    final days = daily.keys.toList()..sort();
    return days.map((day) => daily[day]!.build(day)).toList(growable: false);
  }

  static Map<String, String> _nearestForecastValues({
    required List<Map<String, dynamic>> items,
    required DateTime targetTime,
  }) {
    final forecastsByTime = _forecastValuesByTime(items);
    if (forecastsByTime.isEmpty) return const <String, String>{};

    final sortedTimes = forecastsByTime.keys.toList()..sort();
    for (final forecastAt in sortedTimes) {
      if (!forecastAt.isBefore(
        DateTime(
          targetTime.year,
          targetTime.month,
          targetTime.day,
          targetTime.hour,
        ),
      )) {
        return forecastsByTime[forecastAt]!;
      }
    }
    return forecastsByTime[sortedTimes.last]!;
  }

  static DateTime? _parseForecastDateTime(String date, String time) {
    if (date.length != 8 || time.length != 4) return null;
    final year = int.tryParse(date.substring(0, 4));
    final month = int.tryParse(date.substring(4, 6));
    final day = int.tryParse(date.substring(6, 8));
    final hour = int.tryParse(time.substring(0, 2));
    final minute = int.tryParse(time.substring(2, 4));
    if (year == null ||
        month == null ||
        day == null ||
        hour == null ||
        minute == null) {
      return null;
    }
    return DateTime(year, month, day, hour, minute);
  }

  static double? _parseKmaDouble(String? value) {
    if (value == null) return null;
    return double.tryParse(value.trim());
  }

  static int? _parseKmaInt(String? value) {
    if (value == null) return null;
    return int.tryParse(value.trim());
  }

  static double? _numberAt({required Object? codes, required int index}) {
    if (codes is! List || index >= codes.length) return null;
    return (codes[index] as num?)?.toDouble();
  }

  static double? _parseKmaPrecipitation(String? value) {
    if (value == null) return null;
    final normalized = value.trim();
    if (normalized.isEmpty) return null;
    if (normalized == '강수없음' || normalized == '없음') return 0;
    if (normalized.contains('미만')) {
      final numeric = _extractLeadingNumber(normalized);
      if (numeric != null) return numeric / 2;
    }
    return _extractLeadingNumber(normalized);
  }

  static double? _extractLeadingNumber(String value) {
    final match = RegExp(r'[-+]?\d+(?:\.\d+)?').firstMatch(value);
    if (match == null) return null;
    return double.tryParse(match.group(0)!);
  }

  static double? _calculateApparentTemperature({
    required double? temperature,
    required double? humidity,
    required double? windSpeed,
  }) {
    if (temperature == null || humidity == null || windSpeed == null) {
      return null;
    }
    final vaporPressure = (humidity / 100) *
        6.105 *
        math.exp((17.27 * temperature) / (237.7 + temperature));
    return temperature + (0.33 * vaporPressure) - (0.70 * windSpeed) - 4.0;
  }

  static int? _mapKoreanWeatherCode({
    required int? precipitationType,
    required int? sky,
  }) {
    switch (precipitationType) {
      case 1:
      case 5:
        return 61;
      case 2:
      case 6:
        return 67;
      case 3:
      case 7:
        return 71;
    }

    switch (sky) {
      case 1:
        return 0;
      case 3:
        return 2;
      case 4:
        return 3;
      default:
        return null;
    }
  }

  static int _weatherCodeSeverity(int? code) {
    switch (code) {
      case 95:
      case 96:
      case 99:
        return 7;
      case 71:
      case 73:
      case 75:
      case 77:
      case 85:
      case 86:
        return 6;
      case 61:
      case 63:
      case 65:
      case 66:
      case 67:
      case 80:
      case 81:
      case 82:
        return 5;
      case 51:
      case 53:
      case 55:
      case 56:
      case 57:
        return 4;
      case 45:
      case 48:
        return 3;
      case 2:
      case 3:
        return 2;
      case 1:
        return 1;
      case 0:
        return 0;
      default:
        return -1;
    }
  }

  static _ForecastGrid _toForecastGrid({
    required double latitude,
    required double longitude,
  }) {
    const re = 6371.00877 / 5.0;
    const slat1 = 30.0 * math.pi / 180.0;
    const slat2 = 60.0 * math.pi / 180.0;
    const olon = 126.0 * math.pi / 180.0;
    const olat = 38.0 * math.pi / 180.0;
    const xo = 43.0;
    const yo = 136.0;

    var sn = math.tan(math.pi * 0.25 + slat2 * 0.5) /
        math.tan(math.pi * 0.25 + slat1 * 0.5);
    sn = math.log(math.cos(slat1) / math.cos(slat2)) / math.log(sn);
    var sf = math.tan(math.pi * 0.25 + slat1 * 0.5);
    sf = math.pow(sf, sn).toDouble() * math.cos(slat1) / sn;
    var ro = math.tan(math.pi * 0.25 + olat * 0.5);
    ro = re * sf / math.pow(ro, sn);
    var ra = math.tan(math.pi * 0.25 + latitude * math.pi / 180.0 * 0.5);
    ra = re * sf / math.pow(ra, sn);
    var theta = longitude * math.pi / 180.0 - olon;
    if (theta > math.pi) theta -= 2.0 * math.pi;
    if (theta < -math.pi) theta += 2.0 * math.pi;
    theta *= sn;

    return _ForecastGrid(
      x: (ra * math.sin(theta) + xo + 0.5).floor(),
      y: (ro - ra * math.cos(theta) + yo + 0.5).floor(),
    );
  }

  static String _pad(int value, int width) =>
      value.toString().padLeft(width, '0');
}

class _ForecastGrid {
  const _ForecastGrid({required this.x, required this.y});

  final int x;
  final int y;
}

class _KmaForecastZone {
  const _KmaForecastZone({
    required this.regId,
    required this.regName,
    required this.regSp,
    required this.regUp,
    required this.weeklyForecastOfficeId,
    required this.latitude,
    required this.longitude,
  });

  final String regId;
  final String regName;
  final String regSp;
  final String regUp;
  final String weeklyForecastOfficeId;
  final double? latitude;
  final double? longitude;

  static _KmaForecastZone? fromItem(Map<String, dynamic> item) {
    final regId = (item['regId'] ?? item['regid'] ?? '').toString().trim();
    if (regId.isEmpty) return null;
    return _KmaForecastZone(
      regId: regId,
      regName: (item['regName'] ?? item['regname'] ?? '').toString().trim(),
      regSp: (item['regSp'] ?? item['regsp'] ?? '').toString().trim(),
      regUp: (item['regUp'] ?? item['regup'] ?? '').toString().trim(),
      weeklyForecastOfficeId:
          (item['stnFw'] ?? item['stnfw'] ?? '').toString().trim(),
      latitude: WeatherCurrentService._parseKmaDouble(item['lat']?.toString()),
      longitude: WeatherCurrentService._parseKmaDouble(item['lon']?.toString()),
    );
  }
}

class _KmaMidForecastResponse {
  const _KmaMidForecastResponse({
    required this.tmFc,
    required this.stationId,
    required this.item,
  });

  final String tmFc;
  final String stationId;
  final Map<String, dynamic> item;
}

class _KmaBaseTime {
  const _KmaBaseTime({required this.date, required this.time});

  final String date;
  final String time;

  _KmaBaseTime copyWith({String? date, String? time}) {
    return _KmaBaseTime(date: date ?? this.date, time: time ?? this.time);
  }
}

class _KmaDailyAccumulator {
  _KmaDailyAccumulator(this.date);

  final DateTime date;

  double? temperatureMax;
  double? temperatureMin;
  double? fallbackMaxTemp;
  double? fallbackMinTemp;
  double precipitationSum = 0;
  bool hasPrecipitationValue = false;
  double? windSpeedMax;
  double? uvIndexMax;
  int? representativeWeatherCode;
  int? middayWeatherCode;
  int? worstWeatherCode;
  Duration? middayOffset;
  final List<WeatherForecastMoment> hourlyForecasts = <WeatherForecastMoment>[];
  final List<WeatherHourlyPrecipitation> hourlyPrecipitations =
      <WeatherHourlyPrecipitation>[];

  void consume({
    required DateTime forecastAt,
    required Map<String, String> values,
  }) {
    final tmp = WeatherCurrentService._parseKmaDouble(values['TMP']);
    if (tmp != null) {
      fallbackMaxTemp = fallbackMaxTemp == null || tmp > fallbackMaxTemp!
          ? tmp
          : fallbackMaxTemp;
      fallbackMinTemp = fallbackMinTemp == null || tmp < fallbackMinTemp!
          ? tmp
          : fallbackMinTemp;
    }

    final dailyMax = WeatherCurrentService._parseKmaDouble(values['TMX']);
    if (dailyMax != null) {
      temperatureMax = temperatureMax == null || dailyMax > temperatureMax!
          ? dailyMax
          : temperatureMax;
    }

    final dailyMin = WeatherCurrentService._parseKmaDouble(values['TMN']);
    if (dailyMin != null) {
      temperatureMin = temperatureMin == null || dailyMin < temperatureMin!
          ? dailyMin
          : temperatureMin;
    }

    final precipitation = WeatherCurrentService._parseKmaPrecipitation(
      values['PCP'],
    );
    if (precipitation != null) {
      precipitationSum += precipitation;
      hasPrecipitationValue = true;
      if (precipitation > 0) {
        hourlyPrecipitations.add(
          WeatherHourlyPrecipitation(
            time: forecastAt,
            precipitation: precipitation,
          ),
        );
      }
    }

    final windSpeed = WeatherCurrentService._parseKmaDouble(values['WSD']);
    if (windSpeed != null) {
      windSpeedMax = windSpeedMax == null || windSpeed > windSpeedMax!
          ? windSpeed
          : windSpeedMax;
    }

    final uv = WeatherCurrentService._parseKmaDouble(values['UV']);
    if (uv != null) {
      uvIndexMax = uvIndexMax == null || uv > uvIndexMax! ? uv : uvIndexMax;
    }

    final weatherCode = WeatherCurrentService._mapKoreanWeatherCode(
      precipitationType: WeatherCurrentService._parseKmaInt(values['PTY']),
      sky: WeatherCurrentService._parseKmaInt(values['SKY']),
    );
    final moment = WeatherForecastMoment(
      time: forecastAt,
      temperature: tmp,
      weatherCode: weatherCode,
      precipitation: precipitation,
      windSpeed: windSpeed,
    );
    if (moment.hasData) {
      hourlyForecasts.add(moment);
    }
    _consumeWeatherCode(weatherCode, forecastAt);
  }

  void _consumeWeatherCode(int? weatherCode, DateTime forecastAt) {
    if (weatherCode == null) return;

    final severity = WeatherCurrentService._weatherCodeSeverity(weatherCode);
    final currentSeverity = WeatherCurrentService._weatherCodeSeverity(
      worstWeatherCode,
    );
    if (worstWeatherCode == null || severity > currentSeverity) {
      worstWeatherCode = weatherCode;
    }

    final noon = DateTime(
      forecastAt.year,
      forecastAt.month,
      forecastAt.day,
      12,
    );
    final offset = forecastAt.difference(noon).abs();
    if (middayOffset == null || offset < middayOffset!) {
      middayOffset = offset;
      middayWeatherCode = weatherCode;
    }

    representativeWeatherCode = worstWeatherCode ?? middayWeatherCode;
  }

  WeatherDailyForecast build(DateTime date) {
    return WeatherDailyForecast(
      date: date,
      weatherCode: representativeWeatherCode ?? middayWeatherCode,
      temperatureMax: temperatureMax ?? fallbackMaxTemp,
      temperatureMin: temperatureMin ?? fallbackMinTemp,
      precipitationSum: hasPrecipitationValue ? precipitationSum : null,
      windSpeedMax: windSpeedMax,
      uvIndexMax: uvIndexMax,
      morningForecast: WeatherCurrentService._pickDailyForecastMoment(
        hourlyForecasts,
        targetHour: 8,
      ),
      eveningForecast: WeatherCurrentService._pickDailyForecastMoment(
        hourlyForecasts,
        targetHour: 19,
      ),
      hourlyPrecipitations: List<WeatherHourlyPrecipitation>.unmodifiable(
        hourlyPrecipitations,
      ),
    );
  }
}
