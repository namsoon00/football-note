import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'korean_air_quality_service.dart';
import 'weather_current_service.dart';
import 'weather_location_service.dart';

class WeatherSharedHourlyPrecipitation {
  const WeatherSharedHourlyPrecipitation({
    required this.time,
    required this.precipitation,
  });

  final DateTime time;
  final double precipitation;
}

class WeatherSharedForecastMoment {
  const WeatherSharedForecastMoment({
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
}

class WeatherSharedDailyForecast {
  const WeatherSharedDailyForecast({
    required this.date,
    required this.summary,
    this.weatherCode,
    this.temperatureMax,
    this.temperatureMin,
    this.precipitationSum,
    this.windSpeedMax,
    this.uvIndexMax,
    this.morningForecast,
    this.eveningForecast,
    this.hourlyPrecipitations = const <WeatherSharedHourlyPrecipitation>[],
  });

  final DateTime date;
  final String summary;
  final int? weatherCode;
  final double? temperatureMax;
  final double? temperatureMin;
  final double? precipitationSum;
  final double? windSpeedMax;
  final double? uvIndexMax;
  final WeatherSharedForecastMoment? morningForecast;
  final WeatherSharedForecastMoment? eveningForecast;
  final List<WeatherSharedHourlyPrecipitation> hourlyPrecipitations;
}

class WeatherSharedSnapshot {
  const WeatherSharedSnapshot({
    required this.location,
    required this.localeTag,
    required this.fetchedAt,
    required this.summary,
    this.weatherCode,
    this.temperature,
    this.apparentTemperature,
    this.humidity,
    this.precipitation,
    this.windSpeed,
    this.temperatureMax,
    this.temperatureMin,
    this.temperatureDeltaFromYesterday,
    this.pm10,
    this.pm25,
    this.aqi,
    this.airQualityScale = AirQualityScale.usAqi,
    this.dailyForecasts = const <WeatherSharedDailyForecast>[],
  });

  final String location;
  final String localeTag;
  final DateTime fetchedAt;
  final String summary;
  final int? weatherCode;
  final double? temperature;
  final double? apparentTemperature;
  final double? humidity;
  final double? precipitation;
  final double? windSpeed;
  final double? temperatureMax;
  final double? temperatureMin;
  final double? temperatureDeltaFromYesterday;
  final double? pm10;
  final double? pm25;
  final int? aqi;
  final AirQualityScale airQualityScale;
  final List<WeatherSharedDailyForecast> dailyForecasts;

  bool get hasData =>
      summary.trim().isNotEmpty ||
      weatherCode != null ||
      temperature != null ||
      apparentTemperature != null ||
      humidity != null ||
      precipitation != null ||
      windSpeed != null ||
      temperatureMax != null ||
      temperatureMin != null ||
      temperatureDeltaFromYesterday != null ||
      pm10 != null ||
      pm25 != null ||
      aqi != null ||
      dailyForecasts.isNotEmpty;
}

class WeatherSharedResource {
  const WeatherSharedResource._();

  static const Duration cacheTtl = Duration(minutes: 10);
  static WeatherSharedSnapshot? _cachedSnapshot;

  static WeatherSharedSnapshot? cachedSnapshot({required Locale locale}) {
    final cachedSnapshot = _cachedSnapshot;
    if (cachedSnapshot == null) return null;
    if (cachedSnapshot.localeTag != locale.toLanguageTag()) {
      return null;
    }
    if (DateTime.now().difference(cachedSnapshot.fetchedAt) >= cacheTtl) {
      return null;
    }
    return cachedSnapshot;
  }

  static void primeSnapshot(WeatherSharedSnapshot snapshot) {
    _cachedSnapshot = snapshot;
  }

  static void debugClearCache() {
    _cachedSnapshot = null;
  }

  static Future<WeatherSharedSnapshot> fetchForLocation({
    required double latitude,
    required double longitude,
    required String location,
    required AppLocalizations l10n,
    required Locale locale,
    http.Client? client,
    DateTime? now,
  }) async {
    final localClient = client ?? http.Client();
    final ownsClient = client == null;
    final referenceTime = now ?? DateTime.now();
    try {
      final responses = await Future.wait<Object?>(<Future<Object?>>[
        WeatherCurrentService.fetchDetailedWeather(
          latitude: latitude,
          longitude: longitude,
          client: localClient,
        ),
        _fetchAirQualitySnapshot(
          latitude: latitude,
          longitude: longitude,
          client: localClient,
        ),
        _fetchYesterdayTemperatureAtSameHour(
          latitude: latitude,
          longitude: longitude,
          now: referenceTime,
          client: localClient,
        ),
      ]);
      final snapshot = composeSnapshot(
        location: location,
        locale: locale,
        fetchedAt: referenceTime,
        l10n: l10n,
        weatherSnapshot: responses[0] as WeatherDetailsSnapshot,
        airQualitySnapshot: responses[1] as AirQualitySnapshot,
        yesterdayTemperature: responses[2] as double?,
      );
      if (snapshot.hasData) {
        _cachedSnapshot = snapshot;
      }
      return snapshot;
    } finally {
      if (ownsClient) {
        localClient.close();
      }
    }
  }

  static WeatherSharedSnapshot composeSnapshot({
    required String location,
    required Locale locale,
    required DateTime fetchedAt,
    required AppLocalizations l10n,
    required WeatherDetailsSnapshot weatherSnapshot,
    required AirQualitySnapshot airQualitySnapshot,
    double? yesterdayTemperature,
  }) {
    final localizer = _WeatherLocalizer(l10n: l10n);
    final weatherCode = weatherSnapshot.weatherCode;
    final temperature = weatherSnapshot.temperature;
    final temperatureDeltaFromYesterday =
        temperature == null || yesterdayTemperature == null
            ? null
            : temperature - yesterdayTemperature;
    final forecasts = weatherSnapshot.dailyForecasts
        .map(
          (forecast) => WeatherSharedDailyForecast(
            date: forecast.date,
            weatherCode: forecast.weatherCode,
            summary: _weatherLabelFromCode(
              forecast.weatherCode,
              localizer: localizer,
            ),
            temperatureMax: forecast.temperatureMax,
            temperatureMin: forecast.temperatureMin,
            precipitationSum: forecast.precipitationSum,
            windSpeedMax: forecast.windSpeedMax,
            uvIndexMax: forecast.uvIndexMax,
            morningForecast: forecast.morningForecast == null
                ? null
                : WeatherSharedForecastMoment(
                    time: forecast.morningForecast!.time,
                    temperature: forecast.morningForecast!.temperature,
                    weatherCode: forecast.morningForecast!.weatherCode,
                    precipitation: forecast.morningForecast!.precipitation,
                    windSpeed: forecast.morningForecast!.windSpeed,
                  ),
            eveningForecast: forecast.eveningForecast == null
                ? null
                : WeatherSharedForecastMoment(
                    time: forecast.eveningForecast!.time,
                    temperature: forecast.eveningForecast!.temperature,
                    weatherCode: forecast.eveningForecast!.weatherCode,
                    precipitation: forecast.eveningForecast!.precipitation,
                    windSpeed: forecast.eveningForecast!.windSpeed,
                  ),
            hourlyPrecipitations: forecast.hourlyPrecipitations
                .map(
                  (entry) => WeatherSharedHourlyPrecipitation(
                    time: entry.time,
                    precipitation: entry.precipitation,
                  ),
                )
                .toList(growable: false),
          ),
        )
        .toList(growable: false);
    final summary = _buildWeatherSummary(
      temperature: temperature,
      weatherCode: weatherCode,
      localizer: localizer,
    );

    return WeatherSharedSnapshot(
      location: location.trim(),
      localeTag: locale.toLanguageTag(),
      fetchedAt: fetchedAt,
      summary: summary,
      weatherCode: weatherCode,
      temperature: temperature,
      apparentTemperature: weatherSnapshot.apparentTemperature,
      humidity: weatherSnapshot.humidity,
      precipitation: weatherSnapshot.precipitation,
      windSpeed: weatherSnapshot.windSpeed,
      temperatureMax: weatherSnapshot.temperatureMax,
      temperatureMin: weatherSnapshot.temperatureMin,
      temperatureDeltaFromYesterday: temperatureDeltaFromYesterday,
      pm10: airQualitySnapshot.pm10,
      pm25: airQualitySnapshot.pm25,
      aqi: airQualitySnapshot.aqi,
      airQualityScale: airQualitySnapshot.scale,
      dailyForecasts: forecasts,
    );
  }

  static Future<double?> _fetchYesterdayTemperatureAtSameHour({
    required double latitude,
    required double longitude,
    required DateTime now,
    required http.Client client,
  }) async {
    final yesterday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 1));
    final dateLabel = DateFormat('yyyy-MM-dd').format(yesterday);
    final uri =
        Uri.https('archive-api.open-meteo.com', '/v1/archive', <String, String>{
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'start_date': dateLabel,
      'end_date': dateLabel,
      'hourly': 'temperature_2m',
      'timezone': 'auto',
    });
    final response = await client.get(uri);
    if (response.statusCode != 200) return null;

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) return null;
    final hourly = decoded['hourly'];
    if (hourly is! Map<String, dynamic>) return null;

    final times = hourly['time'];
    final temperatures = hourly['temperature_2m'];
    if (times is! List || temperatures is! List || times.isEmpty) return null;

    final targetTime = DateTime(
      yesterday.year,
      yesterday.month,
      yesterday.day,
      now.hour,
    );
    var bestIndex = -1;
    var bestDiffSeconds = 1 << 30;

    for (var index = 0;
        index < times.length && index < temperatures.length;
        index++) {
      final rawTime = times[index]?.toString();
      if (rawTime == null || rawTime.trim().isEmpty) continue;
      final parsedTime = DateTime.tryParse(rawTime);
      if (parsedTime == null) continue;
      final diffSeconds = parsedTime.difference(targetTime).inSeconds.abs();
      if (diffSeconds < bestDiffSeconds) {
        bestDiffSeconds = diffSeconds;
        bestIndex = index;
      }
    }

    if (bestIndex < 0 || bestDiffSeconds > const Duration(hours: 3).inSeconds) {
      return null;
    }
    final value = temperatures[bestIndex];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static Future<AirQualitySnapshot> _fetchAirQualitySnapshot({
    required double latitude,
    required double longitude,
    required http.Client client,
  }) async {
    if (WeatherLocationService.isLikelyInKorea(latitude, longitude)) {
      try {
        return await KoreanAirQualityService.fetchCurrentAirQuality(
          latitude: latitude,
          longitude: longitude,
          client: client,
        );
      } catch (_) {
        return const AirQualitySnapshot();
      }
    }

    final airQualityUri =
        Uri.https('air-quality-api.open-meteo.com', '/v1/air-quality', {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'current': 'pm10,pm2_5,us_aqi',
      'timezone': 'auto',
    });
    final airResponse = await client.get(airQualityUri);
    if (airResponse.statusCode != 200) {
      return const AirQualitySnapshot();
    }

    final decoded = jsonDecode(airResponse.body);
    if (decoded is! Map<String, dynamic>) {
      return const AirQualitySnapshot();
    }
    final airCurrent = decoded['current'];
    final openMeteoAir = airCurrent is Map<String, dynamic>
        ? airCurrent
        : const <String, dynamic>{};

    return AirQualitySnapshot(
      pm10: (openMeteoAir['pm10'] as num?)?.toDouble(),
      pm25: (openMeteoAir['pm2_5'] as num?)?.toDouble(),
      aqi: (openMeteoAir['us_aqi'] as num?)?.toInt(),
      scale: AirQualityScale.usAqi,
    );
  }

  static String _buildWeatherSummary({
    required double? temperature,
    required int? weatherCode,
    required _WeatherLabelLocalizer localizer,
  }) {
    final weatherText = weatherCode == null
        ? ''
        : _weatherLabelFromCode(weatherCode, localizer: localizer);
    final tempText = temperature == null ? '' : '${temperature.round()}°C';
    if (weatherText.isEmpty) return tempText;
    if (tempText.isEmpty) return weatherText;
    return '$weatherText $tempText';
  }

  static String _weatherLabelFromCode(
    int? code, {
    required _WeatherLabelLocalizer localizer,
  }) {
    switch (code) {
      case 0:
        return localizer.clear;
      case 1:
      case 2:
      case 3:
        return localizer.cloudy;
      case 45:
      case 48:
        return localizer.fog;
      case 51:
      case 53:
      case 55:
      case 56:
      case 57:
        return localizer.drizzle;
      case 61:
      case 63:
      case 65:
      case 66:
      case 67:
      case 80:
      case 81:
      case 82:
        return localizer.rain;
      case 71:
      case 73:
      case 75:
      case 77:
      case 85:
      case 86:
        return localizer.snow;
      case 95:
      case 96:
      case 99:
        return localizer.thunderstorm;
      default:
        return localizer.defaultValue;
    }
  }
}

abstract interface class _WeatherLabelLocalizer {
  String get clear;
  String get cloudy;
  String get fog;
  String get drizzle;
  String get rain;
  String get snow;
  String get thunderstorm;
  String get defaultValue;
}

class _WeatherLocalizer implements _WeatherLabelLocalizer {
  const _WeatherLocalizer({required this.l10n});

  final AppLocalizations l10n;

  @override
  String get clear => l10n.weatherLabelClear;

  @override
  String get cloudy => l10n.weatherLabelCloudy;

  @override
  String get fog => l10n.weatherLabelFog;

  @override
  String get drizzle => l10n.weatherLabelDrizzle;

  @override
  String get rain => l10n.weatherLabelRain;

  @override
  String get snow => l10n.weatherLabelSnow;

  @override
  String get thunderstorm => l10n.weatherLabelThunderstorm;

  @override
  String get defaultValue => l10n.weatherLabelDefault;
}
