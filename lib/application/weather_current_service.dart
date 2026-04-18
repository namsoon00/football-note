import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import 'weather_forecast_service.dart';
import 'weather_location_service.dart';

enum WeatherDataProvider {
  openMeteo,
  koreaMeteorologicalAdministration,
}

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
  });

  final DateTime date;
  final int? weatherCode;
  final double? temperatureMax;
  final double? temperatureMin;
  final double? precipitationSum;
  final double? windSpeedMax;
  final double? uvIndexMax;
}

class WeatherCurrentService {
  const WeatherCurrentService._();

  static const String _kmaApiKey =
      '5b3956b221d8776d5c6a9ed898c4a9c31fdf60d6b7e39f41e84385d31de0b82c';

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
      final normalizedKey = (kmaApiKey ?? _kmaApiKey).trim();
      if (normalizedKey.isNotEmpty &&
          WeatherLocationService.isLikelyInKorea(latitude, longitude)) {
        final koreanSnapshot = await _fetchKoreanCurrentWeather(
          latitude: latitude,
          longitude: longitude,
          client: localClient,
          apiKey: normalizedKey,
          now: now ?? DateTime.now(),
        );
        if (koreanSnapshot != null && koreanSnapshot.hasData) {
          return koreanSnapshot;
        }
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
      final normalizedKey = (kmaApiKey ?? _kmaApiKey).trim();
      if (normalizedKey.isNotEmpty &&
          WeatherLocationService.isLikelyInKorea(latitude, longitude)) {
        final koreanSnapshot = await _fetchKoreanDetailedWeather(
          latitude: latitude,
          longitude: longitude,
          client: localClient,
          apiKey: normalizedKey,
          now: now ?? DateTime.now(),
        );
        if (koreanSnapshot != null && koreanSnapshot.hasData) {
          return koreanSnapshot;
        }
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
    final daily = decoded['daily'];
    final currentMap =
        current is Map<String, dynamic> ? current : const <String, dynamic>{};
    final dailyMap =
        daily is Map<String, dynamic> ? daily : const <String, dynamic>{};
    final forecasts = _buildOpenMeteoDailyForecasts(dailyMap);

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
        : _nearestForecastValues(
            items: forecastItems,
            targetTime: _toKst(now),
          );

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
    final dailyForecasts = _buildKmaDailyForecasts(forecastValuesByTime);

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
        if (response.statusCode != 200) continue;
        final items = _parseKmaItems(response.bodyBytes);
        if (items != null && items.isNotEmpty) {
          return items;
        }
      }
    }
    return null;
  }

  static List<Map<String, dynamic>>? _parseKmaItems(List<int> bodyBytes) {
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
        return _formatKmaBaseTime(
          DateTime(kst.year, kst.month, kst.day, hour),
        );
      }
    }
    return _formatKmaBaseTime(
      DateTime(kst.year, kst.month, kst.day).subtract(
        const Duration(hours: 1),
      ),
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
    Map<String, dynamic> daily,
  ) {
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
      forecasts.add(
        WeatherDailyForecast(
          date: date,
          weatherCode: _numberAt(codes: codes, index: index)?.toInt(),
          temperatureMax: _numberAt(codes: maxTemps, index: index),
          temperatureMin: _numberAt(codes: minTemps, index: index),
          precipitationSum: _numberAt(codes: precipitationSums, index: index),
          windSpeedMax: _numberAt(codes: maxWinds, index: index),
          uvIndexMax: _numberAt(codes: uvIndexMax, index: index),
        ),
      );
    }
    return forecasts;
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
      final date = DateTime(
        forecastAt.year,
        forecastAt.month,
        forecastAt.day,
      );
      final accumulator = daily.putIfAbsent(
        date,
        () => _KmaDailyAccumulator(date),
      );
      accumulator.consume(
        forecastAt: forecastAt,
        values: values,
      );
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
      if (!forecastAt.isBefore(DateTime(targetTime.year, targetTime.month,
          targetTime.day, targetTime.hour))) {
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

class _KmaBaseTime {
  const _KmaBaseTime({
    required this.date,
    required this.time,
  });

  final String date;
  final String time;

  _KmaBaseTime copyWith({
    String? date,
    String? time,
  }) {
    return _KmaBaseTime(
      date: date ?? this.date,
      time: time ?? this.time,
    );
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
    );
  }
}
