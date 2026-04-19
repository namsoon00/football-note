import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../application/korean_air_quality_service.dart';
import '../../application/weather_current_service.dart';
import '../../application/weather_location_service.dart';
import '../widgets/app_background.dart';

class WeatherHomeWarmupResult {
  final String summary;
  final int? weatherCode;

  const WeatherHomeWarmupResult({required this.summary, this.weatherCode});
}

enum WeatherDetailInitialAction { none, outfitGuide }

class WeatherDetailScreen extends StatefulWidget {
  final String initialLocation;
  final String initialSummary;
  final int? initialWeatherCode;
  final WeatherDetailInitialAction initialAction;

  const WeatherDetailScreen({
    super.key,
    this.initialLocation = '',
    this.initialSummary = '',
    this.initialWeatherCode,
    this.initialAction = WeatherDetailInitialAction.none,
  });

  static Future<WeatherHomeWarmupResult> fetchForHome({
    required double latitude,
    required double longitude,
    required String location,
    required AppLocalizations l10n,
    required Locale locale,
  }) async {
    final snapshot = await _fetchWeatherSnapshotStatic(
      latitude: latitude,
      longitude: longitude,
      l10n: l10n,
    );
    _cacheHomeSnapshot(location: location, snapshot: snapshot, locale: locale);
    return WeatherHomeWarmupResult(
      summary: snapshot.summary,
      weatherCode: snapshot.weatherCode,
    );
  }

  static void _cacheHomeSnapshot({
    required String location,
    required _WeatherDetailsSnapshot snapshot,
    required Locale locale,
  }) {
    _WeatherDetailScreenState._cachedDetails = _CachedWeatherDetails(
      location: location.trim(),
      snapshot: snapshot,
      localeTag: locale.toLanguageTag(),
      fetchedAt: DateTime.now(),
    );
  }

  static Future<_WeatherDetailsSnapshot> _fetchWeatherSnapshotStatic({
    required double latitude,
    required double longitude,
    required AppLocalizations l10n,
  }) async {
    final referenceTime = DateTime.now();
    final weatherDetailsFuture = WeatherCurrentService.fetchDetailedWeather(
      latitude: latitude,
      longitude: longitude,
    );
    final airQualityFuture = _fetchAirQualitySnapshot(
      latitude: latitude,
      longitude: longitude,
    );
    final yesterdayTemperatureFuture = _fetchYesterdayTemperatureAtSameHour(
      latitude: latitude,
      longitude: longitude,
      now: referenceTime,
    );
    final responses = await Future.wait<Object?>([
      weatherDetailsFuture,
      airQualityFuture,
      yesterdayTemperatureFuture,
    ]);
    final weatherSnapshot = responses[0] as WeatherDetailsSnapshot;
    final airSnapshot = responses[1] as _ResolvedAirQualitySnapshot;
    final yesterdayTemperature = responses[2] as double?;

    if (!airSnapshot.snapshot.hasData && !weatherSnapshot.hasData) {
      return const _WeatherDetailsSnapshot(summary: '');
    }

    final localizer = _WeatherLocalizer(l10n: l10n);
    final weatherCode = weatherSnapshot.weatherCode;
    final temperature = weatherSnapshot.temperature;
    final temperatureDeltaFromYesterday =
        temperature == null || yesterdayTemperature == null
            ? null
            : temperature - yesterdayTemperature;
    final summary = _buildWeatherSummaryStatic(
      temperature: temperature,
      weatherCode: weatherCode,
      localizer: localizer,
    );
    final forecasts = weatherSnapshot.dailyForecasts
        .map(
          (forecast) => _DailyWeatherForecast(
            date: forecast.date,
            label: '',
            weekdayLabel: '',
            weatherCode: forecast.weatherCode,
            summary: _weatherLabelFromCodeStatic(
              forecast.weatherCode,
              localizer: localizer,
            ),
            temperatureMax: forecast.temperatureMax,
            temperatureMin: forecast.temperatureMin,
            precipitationSum: forecast.precipitationSum,
            windSpeedMax: forecast.windSpeedMax,
            uvIndexMax: forecast.uvIndexMax,
            hourlyPrecipitations: forecast.hourlyPrecipitations
                .map(
                  (entry) => _HourlyPrecipitationEntry(
                    time: entry.time,
                    precipitation: entry.precipitation,
                  ),
                )
                .toList(growable: false),
          ),
        )
        .toList(growable: false);

    return _WeatherDetailsSnapshot(
      summary: summary,
      weatherCode: weatherCode,
      apparentTemperature: weatherSnapshot.apparentTemperature,
      humidity: weatherSnapshot.humidity,
      precipitation: weatherSnapshot.precipitation,
      windSpeed: weatherSnapshot.windSpeed,
      temperatureMax: weatherSnapshot.temperatureMax,
      temperatureMin: weatherSnapshot.temperatureMin,
      temperatureDeltaFromYesterday: temperatureDeltaFromYesterday,
      pm10: airSnapshot.snapshot.pm10,
      pm25: airSnapshot.snapshot.pm25,
      aqi: airSnapshot.snapshot.aqi,
      airQualityScale: airSnapshot.scale,
      dailyForecasts: forecasts,
    );
  }

  static Future<double?> _fetchYesterdayTemperatureAtSameHour({
    required double latitude,
    required double longitude,
    required DateTime now,
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
    final response = await http.get(uri);
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

  static Future<_ResolvedAirQualitySnapshot> _fetchAirQualitySnapshot({
    required double latitude,
    required double longitude,
  }) async {
    if (WeatherLocationService.isLikelyInKorea(latitude, longitude)) {
      try {
        final koreanAir = await KoreanAirQualityService.fetchCurrentAirQuality(
          latitude: latitude,
          longitude: longitude,
        );
        return _ResolvedAirQualitySnapshot(
          snapshot: koreanAir,
          scale: koreanAir.scale == AirQualityScale.khai
              ? _AirQualityScale.khai
              : _AirQualityScale.usAqi,
        );
      } catch (_) {
        return const _ResolvedAirQualitySnapshot(
          snapshot: AirQualitySnapshot(),
          scale: _AirQualityScale.usAqi,
        );
      }
    }

    final airQualityUri =
        Uri.https('air-quality-api.open-meteo.com', '/v1/air-quality', {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'current': 'pm10,pm2_5,us_aqi',
      'timezone': 'auto',
    });
    final airResponse = await http.get(airQualityUri);
    if (airResponse.statusCode != 200) {
      return const _ResolvedAirQualitySnapshot(
        snapshot: AirQualitySnapshot(),
        scale: _AirQualityScale.usAqi,
      );
    }

    final decoded = jsonDecode(airResponse.body);
    if (decoded is! Map<String, dynamic>) {
      return const _ResolvedAirQualitySnapshot(
        snapshot: AirQualitySnapshot(),
        scale: _AirQualityScale.usAqi,
      );
    }
    final airCurrent = decoded['current'];
    final openMeteoAir = airCurrent is Map<String, dynamic>
        ? airCurrent
        : const <String, dynamic>{};

    return _ResolvedAirQualitySnapshot(
      snapshot: AirQualitySnapshot(
        pm10: (openMeteoAir['pm10'] as num?)?.toDouble(),
        pm25: (openMeteoAir['pm2_5'] as num?)?.toDouble(),
        aqi: (openMeteoAir['us_aqi'] as num?)?.toInt(),
        scale: AirQualityScale.usAqi,
      ),
      scale: _AirQualityScale.usAqi,
    );
  }

  static String _buildWeatherSummaryStatic({
    required double? temperature,
    required int? weatherCode,
    required _WeatherLabelLocalizer localizer,
  }) {
    final weatherText = weatherCode == null
        ? ''
        : _weatherLabelFromCodeStatic(weatherCode, localizer: localizer);
    final tempText =
        temperature == null ? '' : '${temperature.toStringAsFixed(1)}°C';
    if (weatherText.isEmpty) return tempText;
    if (tempText.isEmpty) return weatherText;
    return '$weatherText $tempText';
  }

  static String _weatherLabelFromCodeStatic(
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

  @override
  State<WeatherDetailScreen> createState() => _WeatherDetailScreenState();
}

class _WeatherDetailScreenState extends State<WeatherDetailScreen> {
  static const Duration _cacheTtl = Duration(minutes: 10);
  static _CachedWeatherDetails? _cachedDetails;

  bool _loading = false;
  bool _handledInitialAction = false;
  String _location = '';
  String _summary = '';
  int? _weatherCode;
  double? _apparentTemperature;
  double? _humidity;
  double? _precipitation;
  double? _windSpeed;
  double? _temperatureMax;
  double? _temperatureMin;
  double? _temperatureDeltaFromYesterday;
  double? _pm10;
  double? _pm25;
  int? _aqi;
  _AirQualityScale _airQualityScale = _AirQualityScale.usAqi;
  List<_DailyWeatherForecast> _dailyForecasts = const <_DailyWeatherForecast>[];

  @override
  void initState() {
    super.initState();
    _location = widget.initialLocation.trim();
    _summary = widget.initialSummary.trim();
    _weatherCode = widget.initialWeatherCode;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final localeTag = Localizations.localeOf(context).toLanguageTag();
      final cachedDetails = _cachedDetails;
      if (cachedDetails != null &&
          cachedDetails.localeTag == localeTag &&
          DateTime.now().difference(cachedDetails.fetchedAt) < _cacheTtl) {
        setState(() {
          _applySnapshot(cachedDetails.location, cachedDetails.snapshot);
        });
      }
      _maybeHandleInitialAction();
      final shouldRequestPermission =
          widget.initialAction == WeatherDetailInitialAction.outfitGuide &&
              _summary.isEmpty;
      unawaited(
        _loadWeather(
          requestPermission: shouldRequestPermission,
          showFailureFeedback: false,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final hasWeather = _summary.isNotEmpty;
    final pm10Level = _pm10Level(l10n, _pm10);
    final pm25Level = _pm25Level(l10n, _pm25);
    final detailedOutfitGuide = _buildDetailedOutfitGuide(isKo, l10n);
    final trainingGuide = _buildTrainingGuide(isKo, l10n);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.homeWeatherDetailsTitle)),
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _CompactWeatherHeaderCard(
                title: hasWeather ? _summary : l10n.homeWeatherTitle,
                subtitle: _headerLocationLabel(l10n),
                helper: null,
                icon: _weatherIcon(_weatherCode),
                loading: _loading,
                onRefresh: _loading
                    ? null
                    : () => _loadWeather(
                          requestPermission: true,
                          showFailureFeedback: true,
                        ),
                metrics: hasWeather
                    ? [
                        _CompactMetricData(
                          label: l10n.homeWeatherTemperatureRange,
                          value: _formatCompactRange(
                            _temperatureMax,
                            _temperatureMin,
                          ),
                          icon: Icons.device_thermostat_outlined,
                        ),
                        _CompactMetricData(
                          label: l10n.homeWeatherFeelsLike,
                          value: _formatTemperature(_apparentTemperature),
                          icon: Icons.thermostat_auto_outlined,
                        ),
                        _CompactMetricData(
                          label: l10n.homeWeatherComparedYesterday,
                          value: _formatTemperatureDelta(
                            _temperatureDeltaFromYesterday,
                          ),
                          icon: Icons.compare_arrows_rounded,
                        ),
                        _CompactMetricData(
                          label: l10n.homeWeatherHumidity,
                          value: _formatPercent(_humidity),
                          icon: Icons.water_drop_outlined,
                        ),
                        _CompactMetricData(
                          label: l10n.homeWeatherPrecipitation,
                          value: _formatMillimeter(_todayPrecipitation),
                          icon: Icons.umbrella_outlined,
                        ),
                        _CompactMetricData(
                          label: l10n.homeWeatherWindSpeed,
                          value: _formatWind(_windSpeed),
                          icon: Icons.air_rounded,
                        ),
                      ]
                    : const <_CompactMetricData>[],
                footer: _todayHourlyPrecipitations.isEmpty
                    ? null
                    : _HourlyPrecipitationSection(
                        title: l10n.homeWeatherHourlyPrecipitation,
                        entries: _todayHourlyPrecipitations,
                        formatTime: _formatHourlyTime,
                        formatPrecipitation: _formatCompactMillimeter,
                        accentStyle: true,
                      ),
              ),
              if (hasWeather) ...[
                const SizedBox(height: 16),
                _TodayAirQualitySection(
                  title: l10n.homeWeatherAirQualityTitle,
                  pm10Label: l10n.homeWeatherPm10,
                  pm10Value: _formatAirMetricValue(_pm10),
                  pm10Status: pm10Level.label,
                  pm10Level: pm10Level.level,
                  pm25Label: l10n.homeWeatherPm25,
                  pm25Value: _formatAirMetricValue(_pm25),
                  pm25Status: pm25Level.label,
                  pm25Level: pm25Level.level,
                ),
                const SizedBox(height: 16),
                _WeatherRecommendationActions(
                  outfitLabel: l10n.homeWeatherOutfitButton,
                  trainingLabel: l10n.homeWeatherSuggestionButton,
                  onOutfitTap: () => _openOutfitGuideScreen(
                    l10n: l10n,
                    guide: detailedOutfitGuide,
                  ),
                  onTrainingTap: () =>
                      _showTrainingGuideSheet(isKo: isKo, guide: trainingGuide),
                ),
                const SizedBox(height: 16),
                _TomorrowWeatherCard(
                  title: l10n.homeWeatherTomorrowTitle,
                  conditionLabel: l10n.homeWeatherTomorrowCondition,
                  highLowLabel: l10n.homeWeatherDailyHighLow,
                  precipitationLabel: l10n.homeWeatherPrecipitation,
                  hourlyPrecipitationLabel: l10n.homeWeatherHourlyPrecipitation,
                  windLabel: l10n.homeWeatherWindSpeed,
                  tomorrowForecast:
                      _dailyForecasts.length > 1 ? _dailyForecasts[1] : null,
                  tomorrowFallback: l10n.homeWeatherTomorrowFallback,
                  formatRange: _formatRange,
                  formatMillimeter: _formatMillimeter,
                  formatCompactMillimeter: _formatCompactMillimeter,
                  formatWind: _formatWind,
                  formatTime: _formatHourlyTime,
                  iconForCode: _weatherIcon,
                ),
                const SizedBox(height: 16),
                _WeeklyForecastCard(
                  title: l10n.homeWeatherWeeklyTitle,
                  precipitationLabel: l10n.homeWeatherPrecipitation,
                  windLabel: l10n.homeWeatherWindSpeed,
                  forecasts: _dailyForecasts.take(7).toList(growable: false),
                  formatRange: _formatRange,
                  formatMillimeter: _formatMillimeter,
                  formatWind: _formatWind,
                  iconForCode: _weatherIcon,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadWeather({
    required bool requestPermission,
    required bool showFailureFeedback,
  }) async {
    if (_loading || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final cachedDetails = _cachedDetails;
    if (cachedDetails != null &&
        cachedDetails.localeTag == localeTag &&
        DateTime.now().difference(cachedDetails.fetchedAt) < _cacheTtl) {
      setState(() {
        _applySnapshot(cachedDetails.location, cachedDetails.snapshot);
      });
      _maybeHandleInitialAction();
      return;
    }
    setState(() => _loading = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (showFailureFeedback && mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.homeWeatherLoadFailed)));
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && requestPermission) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (showFailureFeedback && mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.homeWeatherLoadFailed)));
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final place = await _resolvePlaceName(
        latitude: position.latitude,
        longitude: position.longitude,
        isKo: isKo,
        koreaLabel: l10n.homeWeatherCountryKorea,
      );
      if (!mounted) return;
      setState(() {
        _location = place;
      });

      _WeatherDetailsSnapshot? snapshot;
      try {
        snapshot = await _fetchWeatherSnapshot(
          latitude: position.latitude,
          longitude: position.longitude,
          l10n: l10n,
        );
      } catch (_) {
        snapshot = null;
      }

      if (!mounted) return;
      if (snapshot != null && _hasSnapshotData(snapshot)) {
        setState(() {
          _applySnapshot(place, snapshot!);
        });
        _maybeHandleInitialAction();
        _cachedDetails = _CachedWeatherDetails(
          location: place,
          snapshot: snapshot,
          localeTag: localeTag,
          fetchedAt: DateTime.now(),
        );
      }
    } catch (_) {
      if (showFailureFeedback && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.homeWeatherLoadFailed)));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
      _maybeHandleInitialAction();
    }
  }

  Future<String> _resolvePlaceName({
    required double latitude,
    required double longitude,
    required bool isKo,
    required String koreaLabel,
  }) =>
      WeatherLocationService.resolvePlaceName(
        latitude: latitude,
        longitude: longitude,
        isKo: isKo,
        koreaLabel: koreaLabel,
      );

  Future<_WeatherDetailsSnapshot> _fetchWeatherSnapshot({
    required double latitude,
    required double longitude,
    required AppLocalizations l10n,
  }) =>
      WeatherDetailScreen._fetchWeatherSnapshotStatic(
        latitude: latitude,
        longitude: longitude,
        l10n: l10n,
      );

  String _headerLocationLabel(AppLocalizations l10n) {
    if (_location.isNotEmpty) return _location;
    return l10n.homeWeatherLocationUnknown;
  }

  void _maybeHandleInitialAction() {
    if (_handledInitialAction ||
        widget.initialAction != WeatherDetailInitialAction.outfitGuide ||
        !mounted ||
        _summary.trim().isEmpty) {
      return;
    }
    _handledInitialAction = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      _openOutfitGuideScreen(
        l10n: l10n,
        guide: _buildDetailedOutfitGuide(
          Localizations.localeOf(context).languageCode == 'ko',
          l10n,
        ),
      );
    });
  }

  void _applySnapshot(String location, _WeatherDetailsSnapshot snapshot) {
    _location = location;
    _summary = snapshot.summary;
    _weatherCode = snapshot.weatherCode;
    _apparentTemperature = snapshot.apparentTemperature;
    _humidity = snapshot.humidity;
    _precipitation = snapshot.precipitation;
    _windSpeed = snapshot.windSpeed;
    _temperatureMax = snapshot.temperatureMax;
    _temperatureMin = snapshot.temperatureMin;
    _temperatureDeltaFromYesterday = snapshot.temperatureDeltaFromYesterday;
    _pm10 = snapshot.pm10;
    _pm25 = snapshot.pm25;
    _aqi = snapshot.aqi;
    _airQualityScale = snapshot.airQualityScale;
    _dailyForecasts = snapshot.dailyForecasts
        .map(
          (forecast) => forecast.copyWith(
            label: _formatForecastDate(forecast.date),
            weekdayLabel: _formatForecastWeekday(forecast.date),
          ),
        )
        .toList(growable: false);
  }

  bool _hasSnapshotData(_WeatherDetailsSnapshot snapshot) {
    return snapshot.summary.trim().isNotEmpty ||
        snapshot.weatherCode != null ||
        snapshot.apparentTemperature != null ||
        snapshot.humidity != null ||
        snapshot.precipitation != null ||
        snapshot.windSpeed != null ||
        snapshot.temperatureMax != null ||
        snapshot.temperatureMin != null ||
        snapshot.temperatureDeltaFromYesterday != null ||
        snapshot.pm10 != null ||
        snapshot.pm25 != null ||
        snapshot.aqi != null ||
        snapshot.dailyForecasts.isNotEmpty;
  }

  String _formatForecastDate(DateTime date) => DateFormat.MMMd(
        Localizations.localeOf(context).toLanguageTag(),
      ).format(date);

  String _formatForecastWeekday(DateTime date) => DateFormat.E(
        Localizations.localeOf(context).toLanguageTag(),
      ).format(date);

  _AirLevelLabel _aqiLevel(
    AppLocalizations l10n,
    int? value,
    _AirQualityScale scale,
  ) {
    if (value == null) {
      return const _AirLevelLabel('--', _AirQualityLevel.unknown);
    }
    if (scale == _AirQualityScale.khai) {
      if (value <= 50) {
        return _AirLevelLabel(
          l10n.homeWeatherStatusGood,
          _AirQualityLevel.good,
        );
      }
      if (value <= 100) {
        return _AirLevelLabel(
          l10n.homeWeatherStatusModerate,
          _AirQualityLevel.moderate,
        );
      }
      if (value <= 250) {
        return _AirLevelLabel(
          l10n.homeWeatherStatusUnhealthy,
          _AirQualityLevel.unhealthy,
        );
      }
      return _AirLevelLabel(
        l10n.homeWeatherStatusVeryUnhealthy,
        _AirQualityLevel.veryUnhealthy,
      );
    }
    if (value <= 50) {
      return _AirLevelLabel(l10n.homeWeatherStatusGood, _AirQualityLevel.good);
    }
    if (value <= 100) {
      return _AirLevelLabel(
        l10n.homeWeatherStatusModerate,
        _AirQualityLevel.moderate,
      );
    }
    if (value <= 150) {
      return _AirLevelLabel(
        l10n.homeWeatherStatusSensitive,
        _AirQualityLevel.sensitive,
      );
    }
    if (value <= 200) {
      return _AirLevelLabel(
        l10n.homeWeatherStatusUnhealthy,
        _AirQualityLevel.unhealthy,
      );
    }
    if (value <= 300) {
      return _AirLevelLabel(
        l10n.homeWeatherStatusVeryUnhealthy,
        _AirQualityLevel.veryUnhealthy,
      );
    }
    return _AirLevelLabel(
      l10n.homeWeatherStatusHazardous,
      _AirQualityLevel.hazardous,
    );
  }

  _AirLevelLabel _pm10Level(AppLocalizations l10n, double? value) {
    if (value == null) {
      return const _AirLevelLabel('--', _AirQualityLevel.unknown);
    }
    if (value <= 30) {
      return _AirLevelLabel(l10n.homeWeatherStatusGood, _AirQualityLevel.good);
    }
    if (value <= 80) {
      return _AirLevelLabel(
        l10n.homeWeatherStatusModerate,
        _AirQualityLevel.moderate,
      );
    }
    if (value <= 150) {
      return _AirLevelLabel(
        l10n.homeWeatherStatusSensitive,
        _AirQualityLevel.sensitive,
      );
    }
    if (value <= 250) {
      return _AirLevelLabel(
        l10n.homeWeatherStatusUnhealthy,
        _AirQualityLevel.unhealthy,
      );
    }
    if (value <= 350) {
      return _AirLevelLabel(
        l10n.homeWeatherStatusVeryUnhealthy,
        _AirQualityLevel.veryUnhealthy,
      );
    }
    return _AirLevelLabel(
      l10n.homeWeatherStatusHazardous,
      _AirQualityLevel.hazardous,
    );
  }

  _AirLevelLabel _pm25Level(AppLocalizations l10n, double? value) {
    if (value == null) {
      return const _AirLevelLabel('--', _AirQualityLevel.unknown);
    }
    if (value <= 15) {
      return _AirLevelLabel(l10n.homeWeatherStatusGood, _AirQualityLevel.good);
    }
    if (value <= 35) {
      return _AirLevelLabel(
        l10n.homeWeatherStatusModerate,
        _AirQualityLevel.moderate,
      );
    }
    if (value <= 75) {
      return _AirLevelLabel(
        l10n.homeWeatherStatusSensitive,
        _AirQualityLevel.sensitive,
      );
    }
    if (value <= 115) {
      return _AirLevelLabel(
        l10n.homeWeatherStatusUnhealthy,
        _AirQualityLevel.unhealthy,
      );
    }
    if (value <= 150) {
      return _AirLevelLabel(
        l10n.homeWeatherStatusVeryUnhealthy,
        _AirQualityLevel.veryUnhealthy,
      );
    }
    return _AirLevelLabel(
      l10n.homeWeatherStatusHazardous,
      _AirQualityLevel.hazardous,
    );
  }

  String _formatTemperature(double? value) =>
      value == null ? '--' : '${value.toStringAsFixed(1)}°C';

  String _formatCompactTemperature(double? value) {
    if (value == null) return '--';
    final rounded = value.roundToDouble();
    final precision = (value - rounded).abs() < 0.05 ? 0 : 1;
    return '${value.toStringAsFixed(precision)}°';
  }

  String _formatRange(double? high, double? low) {
    if (high == null && low == null) return '--';
    return '${_formatTemperature(high)} / ${_formatTemperature(low)}';
  }

  String _formatCompactRange(double? high, double? low) {
    if (high == null && low == null) return '--';
    return '${_formatCompactTemperature(high)} / ${_formatCompactTemperature(low)}';
  }

  String _formatPercent(double? value) =>
      value == null ? '--' : '${value.toStringAsFixed(0)}%';

  String _formatMillimeter(double? value) =>
      value == null ? '--' : '${value.toStringAsFixed(1)} mm';

  String _formatCompactMillimeter(double value) =>
      '${value.toStringAsFixed(1)} mm';

  String _formatHourlyTime(DateTime value) => DateFormat(
        'HH:mm',
      ).format(value);

  String _formatWind(double? value) =>
      value == null ? '--' : '${value.toStringAsFixed(1)} km/h';

  String _formatAirMetricValue(double? value) {
    if (value == null) return '--';
    final rounded = value.roundToDouble();
    final precision = (value - rounded).abs() < 0.05 ? 0 : 1;
    return value.toStringAsFixed(precision);
  }

  String _formatTemperatureDelta(double? value) {
    if (value == null) return '--';
    final normalized = value.abs() < 0.05 ? 0 : value;
    if (normalized > 0) {
      return '↑ ${normalized.toStringAsFixed(1)}°C';
    }
    if (normalized < 0) {
      return '↓ ${normalized.abs().toStringAsFixed(1)}°C';
    }
    return '0.0°C';
  }

  double? get _todayPrecipitation {
    if (_dailyForecasts.isNotEmpty) {
      return _dailyForecasts.first.precipitationSum ?? _precipitation;
    }
    return _precipitation;
  }

  List<_HourlyPrecipitationEntry> get _todayHourlyPrecipitations {
    if (_dailyForecasts.isEmpty) return const <_HourlyPrecipitationEntry>[];
    return _dailyForecasts.first.hourlyPrecipitations;
  }

  _TrainingGuide _buildTrainingGuide(bool isKo, AppLocalizations l10n) {
    final apparentTemperature = _apparentTemperature ?? _temperatureMax;
    final airLevel = _worstAirQualityLevel();
    final focus = _baseTrainingSuggestion(l10n);
    final caution = <String>[];
    final recovery = <String>[];

    if (apparentTemperature != null && apparentTemperature >= 30) {
      caution.add(
        isKo
            ? '세트 시간을 짧게 끊고 물 섭취를 자주 가져가세요.'
            : 'Shorten sets and hydrate more often.',
      );
      recovery.add(
        isKo
            ? '훈련 후 10분 이상 체온을 먼저 낮춰 주세요.'
            : 'Cool down for at least 10 minutes after training.',
      );
    } else if (apparentTemperature != null && apparentTemperature <= 5) {
      caution.add(
        isKo
            ? '야외 시작 전 실내 워밍업으로 체온을 먼저 올리세요.'
            : 'Start with indoor warm-up before going outside.',
      );
      recovery.add(
        isKo
            ? '젖은 옷은 바로 갈아입고 하체를 따뜻하게 유지하세요.'
            : 'Change damp gear quickly and keep legs warm.',
      );
    } else {
      caution.add(
        isKo
            ? '워밍업 이후 메인 드릴 강도를 천천히 올리세요.'
            : 'Ramp up drill intensity after warm-up.',
      );
      recovery.add(
        isKo
            ? '훈련 후 수분과 가벼운 스트레칭을 챙기세요.'
            : 'Hydrate and stretch lightly after training.',
      );
    }

    if (airLevel.index >= _AirQualityLevel.sensitive.index) {
      caution.add(
        isKo
            ? '미세먼지가 높아 강한 야외 러닝은 줄이는 편이 좋습니다.'
            : 'Air quality is poor, so reduce hard outdoor running.',
      );
    }

    return _TrainingGuide(
      focus: focus,
      caution: caution.join(isKo ? ' ' : ' '),
      recovery: recovery.join(isKo ? ' ' : ' '),
    );
  }

  _DetailedOutfitGuide _buildDetailedOutfitGuide(
    bool isKo,
    AppLocalizations l10n,
  ) =>
      _buildOutfitGuide(
        isKo: isKo,
        l10n: l10n,
        apparentTemperature: _apparentTemperature ?? _temperatureMax,
        precipitationMm: _todayPrecipitation,
        windSpeed: _windSpeed ?? 0,
        weatherCode: _weatherCode,
        airLevel: _worstAirQualityLevel(),
      );

  _DetailedOutfitGuide _buildOutfitGuide({
    required bool isKo,
    required AppLocalizations l10n,
    required double? apparentTemperature,
    required double? precipitationMm,
    required double windSpeed,
    required int? weatherCode,
    required _AirQualityLevel airLevel,
  }) {
    final isStormy =
        weatherCode != null && <int>{95, 96, 99}.contains(weatherCode);
    final hasPrecipitation = (precipitationMm ?? 0) >= 1;
    final hasHeavyPrecipitation = (precipitationMm ?? 0) >= 8;
    final isRainy = weatherCode != null &&
            <int>{
              51,
              53,
              55,
              56,
              57,
              61,
              63,
              65,
              66,
              67,
              80,
              81,
              82,
              95,
              96,
              99,
            }.contains(weatherCode) ||
        hasPrecipitation;
    final isSnowy = weatherCode != null &&
        <int>{71, 73, 75, 77, 85, 86}.contains(weatherCode);
    final isWindy = windSpeed >= 20;
    final isVeryWindy = windSpeed >= 28;

    String layers;
    String outer;
    String bottom;
    String accessories;
    final notes = <String>[];
    final callouts = <_OutfitCoachCallout>[
      _OutfitCoachCallout(
        icon: apparentTemperature != null && apparentTemperature >= 24
            ? Icons.wb_sunny_outlined
            : apparentTemperature != null && apparentTemperature <= 8
                ? Icons.ac_unit_rounded
                : Icons.tune_rounded,
        text: apparentTemperature != null && apparentTemperature >= 24
            ? l10n.homeWeatherOutfitBaseHot
            : apparentTemperature != null && apparentTemperature <= 8
                ? l10n.homeWeatherOutfitBaseCold
                : l10n.homeWeatherOutfitBaseMild,
      ),
    ];

    if (apparentTemperature == null) {
      layers = isKo ? '기능성 이너 + 반팔 훈련복' : 'Base layer + short-sleeve top';
      outer = isKo ? '얇은 집업 또는 조끼' : 'Light zip-up or vest';
      bottom = isKo ? '기본 반바지' : 'Standard shorts';
      accessories = isKo ? '여벌 양말, 물통' : 'Spare socks and water bottle';
    } else if (apparentTemperature >= 30) {
      layers =
          isKo ? '민소매/반팔 + 쿨 이너' : 'Sleeveless/short-sleeve + cooling base';
      outer = isKo ? '아우터 없음' : 'No outerwear';
      bottom = isKo ? '통풍 반바지' : 'Breathable shorts';
      accessories = isKo ? '쿨타월, 얼음물, 챙 모자' : 'Cool towel, iced water, cap';
      notes.add(isKo ? '과열 방지 위해 휴식 간격을 짧게' : 'Take frequent cooling breaks');
    } else if (apparentTemperature >= 22) {
      layers = isKo ? '반팔 훈련복' : 'Short-sleeve training top';
      outer = isKo ? '얇은 조끼(선택)' : 'Light vest (optional)';
      bottom = isKo ? '반바지' : 'Training shorts';
      accessories = isKo ? '여벌 티셔츠, 땀수건' : 'Spare shirt and sweat towel';
    } else if (apparentTemperature >= 15) {
      layers = isKo ? '기능성 이너 + 반팔/긴팔' : 'Base layer + short/long sleeve';
      outer = isKo ? '트레이닝 집업 또는 조끼' : 'Training zip-up or vest';
      bottom = isKo ? '얇은 긴바지 또는 반바지' : 'Light track pants or shorts';
      accessories = isKo ? '워밍업용 겉옷' : 'Warm-up layer';
    } else if (apparentTemperature >= 8) {
      layers = isKo ? '기모 이너 + 긴팔 훈련복' : 'Brushed base layer + long-sleeve top';
      outer = isKo ? '바람막이 + 조끼' : 'Windbreaker + vest';
      bottom = isKo ? '긴 트레이닝 팬츠' : 'Long training pants';
      accessories = isKo ? '얇은 장갑, 넥워머' : 'Light gloves, neck warmer';
    } else if (apparentTemperature >= 2) {
      layers =
          isKo ? '기모 이너 + 긴팔 + 미들레이어' : 'Thermal base + long-sleeve + midlayer';
      outer = isKo ? '방풍 자켓 또는 경량 패딩 조끼' : 'Windproof jacket or padded vest';
      bottom = isKo ? '긴 트레이닝 팬츠' : 'Long training pants';
      accessories =
          isKo ? '방한 장갑, 넥워머, 귀마개' : 'Winter gloves, neck warmer, ear cover';
    } else {
      layers = isKo ? '발열 이너 + 두꺼운 미들레이어' : 'Heat base layer + thick midlayer';
      outer = isKo ? '경량 패딩/훈련용 패딩' : 'Light puffer/training padded jacket';
      bottom = isKo ? '방한 팬츠' : 'Thermal training pants';
      accessories =
          isKo ? '방한 장갑, 넥워머, 비니' : 'Insulated gloves, neck warmer, beanie';
      notes.add(
        isKo
            ? '실내 워밍업 후 짧은 세트로 진행'
            : 'Warm up indoors then do short outdoor sets',
      );
    }

    if (isWindy) {
      notes.add(
        isKo
            ? '강풍: 바람막이/넥워머 필수'
            : 'Strong wind: windbreaker and neck warmer required',
      );
      callouts.add(
        _OutfitCoachCallout(
          icon: Icons.air_rounded,
          text: l10n.homeWeatherOutfitWind,
        ),
      );
    }
    if (isRainy) {
      outer = isStormy || hasHeavyPrecipitation || isVeryWindy
          ? (isKo ? '방수 방풍 자켓' : 'Waterproof windproof jacket')
          : (isKo
              ? '생활방수 자켓 + 얇은 미들레이어'
              : 'Water-resistant jacket + light midlayer');
      accessories = isKo
          ? '$accessories, 방수 양말 또는 여벌 양말'
          : '$accessories, waterproof or spare socks';
      notes.add(isKo ? '젖은 잔디 미끄럼 주의' : 'Watch slippery wet grass');
      if (hasHeavyPrecipitation ||
          isStormy ||
          (apparentTemperature != null && apparentTemperature < 18)) {
        bottom = isKo ? '긴 트레이닝 팬츠' : 'Long training pants';
      }
      callouts.add(
        _OutfitCoachCallout(
          icon: Icons.umbrella_outlined,
          text: l10n.homeWeatherOutfitRain,
        ),
      );
    }
    if (isSnowy) {
      outer = isKo ? '방수 방풍 자켓' : 'Waterproof windproof jacket';
      accessories = isKo
          ? '$accessories, 손난로(선택)'
          : '$accessories, hand warmers (optional)';
      notes.add(isKo ? '빙판 구간 피해서 훈련' : 'Avoid icy zones');
      callouts.add(
        _OutfitCoachCallout(
          icon: Icons.ac_unit_rounded,
          text: l10n.homeWeatherOutfitSnow,
        ),
      );
    }
    if ((isSnowy || isRainy || windSpeed >= 25) &&
        apparentTemperature != null &&
        apparentTemperature < 8) {
      bottom = isKo ? '기모 긴바지' : 'Fleece-lined pants';
    }
    if (airLevel.index >= _AirQualityLevel.sensitive.index) {
      callouts.add(
        _OutfitCoachCallout(
          icon: Icons.masks_outlined,
          text: l10n.homeWeatherOutfitAirCaution,
        ),
      );
    }

    return _DetailedOutfitGuide(
      layers: layers,
      outer: outer,
      bottom: bottom,
      accessories: accessories,
      coachSummary: callouts.first.text,
      callouts: callouts.skip(1).toList(growable: false),
      caution: notes.isEmpty
          ? (isKo
              ? '현재 조건에서 일반 강도 훈련 가능'
              : 'Normal intensity is fine in current conditions')
          : notes.join(isKo ? ' · ' : ' · '),
    );
  }

  List<_OutfitCase> _buildAllOutfitCases(AppLocalizations l10n) {
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final hotGuide = _buildOutfitGuide(
      isKo: isKo,
      l10n: l10n,
      apparentTemperature: 31,
      precipitationMm: 0,
      windSpeed: 8,
      weatherCode: 0,
      airLevel: _AirQualityLevel.good,
    );
    final warmGuide = _buildOutfitGuide(
      isKo: isKo,
      l10n: l10n,
      apparentTemperature: 25,
      precipitationMm: 0,
      windSpeed: 10,
      weatherCode: 1,
      airLevel: _AirQualityLevel.good,
    );
    final mildGuide = _buildOutfitGuide(
      isKo: isKo,
      l10n: l10n,
      apparentTemperature: 18,
      precipitationMm: 0,
      windSpeed: 11,
      weatherCode: 1,
      airLevel: _AirQualityLevel.good,
    );
    final coolGuide = _buildOutfitGuide(
      isKo: isKo,
      l10n: l10n,
      apparentTemperature: 11,
      precipitationMm: 0,
      windSpeed: 15,
      weatherCode: 2,
      airLevel: _AirQualityLevel.good,
    );
    final coldGuide = _buildOutfitGuide(
      isKo: isKo,
      l10n: l10n,
      apparentTemperature: 5,
      precipitationMm: 0,
      windSpeed: 12,
      weatherCode: 0,
      airLevel: _AirQualityLevel.good,
    );
    final wetGuide = _buildOutfitGuide(
      isKo: isKo,
      l10n: l10n,
      apparentTemperature: 6,
      precipitationMm: 12,
      windSpeed: 18,
      weatherCode: 61,
      airLevel: _AirQualityLevel.moderate,
    );
    return [
      _OutfitCase(
        title: l10n.homeWeatherOutfitCaseHotTitle,
        range: l10n.homeWeatherOutfitCaseHotRange,
        summary: hotGuide.coachSummary,
        guide: hotGuide,
      ),
      _OutfitCase(
        title: l10n.homeWeatherOutfitCaseWarmTitle,
        range: l10n.homeWeatherOutfitCaseWarmRange,
        summary: warmGuide.coachSummary,
        guide: warmGuide,
      ),
      _OutfitCase(
        title: l10n.homeWeatherOutfitCaseMildTitle,
        range: l10n.homeWeatherOutfitCaseMildRange,
        summary: mildGuide.coachSummary,
        guide: mildGuide,
      ),
      _OutfitCase(
        title: l10n.homeWeatherOutfitCaseCoolTitle,
        range: l10n.homeWeatherOutfitCaseCoolRange,
        summary: coolGuide.coachSummary,
        guide: coolGuide,
      ),
      _OutfitCase(
        title: l10n.homeWeatherOutfitCaseColdTitle,
        range: l10n.homeWeatherOutfitCaseColdRange,
        summary: coldGuide.coachSummary,
        guide: coldGuide,
      ),
      _OutfitCase(
        title: l10n.homeWeatherOutfitCaseWetTitle,
        range: l10n.homeWeatherOutfitCaseWetRange,
        summary: wetGuide.coachSummary,
        guide: wetGuide,
      ),
    ];
  }

  Future<void> _openOutfitGuideScreen({
    required AppLocalizations l10n,
    required _DetailedOutfitGuide guide,
  }) async {
    final cases = _buildAllOutfitCases(l10n);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _WeatherOutfitGuideScreen(
          title: l10n.homeWeatherOutfitTitle,
          subtitle: _headerLocationLabel(l10n),
          layersLabel: l10n.homeWeatherOutfitLayersLabel,
          outerLabel: l10n.homeWeatherOutfitOuterLabel,
          bottomLabel: l10n.homeWeatherOutfitBottomLabel,
          accessoriesLabel: l10n.homeWeatherOutfitAccessoriesLabel,
          cautionLabel: l10n.homeWeatherOutfitNotesLabel,
          buttonLabel: l10n.homeWeatherOutfitViewAllCases,
          weatherSummary: _summary,
          feelsLikeLabel: l10n.homeWeatherFeelsLike,
          feelsLikeValue: _formatTemperature(_apparentTemperature),
          windLabel: l10n.homeWeatherWindSpeed,
          windValue: _formatWind(_windSpeed),
          airLabel: l10n.homeWeatherAqi,
          airValue: _aqi == null ? '--' : '$_aqi',
          guide: guide,
          casesTitle: l10n.homeWeatherOutfitAllCasesTitle,
          casesSubtitle: l10n.homeWeatherOutfitAllCasesSubtitle,
          cases: cases,
        ),
      ),
    );
  }

  void _showTrainingGuideSheet({
    required bool isKo,
    required _TrainingGuide guide,
  }) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: _StructuredTrainingGuideCard(
            title: isKo ? '추천 훈련 포인트' : 'Recommended Drill Point',
            subtitle: _location.isEmpty
                ? (isKo
                    ? '지금 날씨에서 효율적인 훈련 방향입니다.'
                    : 'Best focus for the current weather.')
                : (isKo
                    ? '$_location 날씨에 맞춘 훈련 방향입니다.'
                    : 'Tailored to $_location weather.'),
            focusLabel: isKo ? '오늘 집중' : 'Focus',
            cautionLabel: isKo ? '운영 팁' : 'Execution tip',
            recoveryLabel: isKo ? '회복 체크' : 'Recovery check',
            guide: guide,
          ),
        ),
      ),
    );
  }

  String _baseTrainingSuggestion(AppLocalizations l10n) {
    switch (_weatherCode) {
      case 0:
        return l10n.homeWeatherSuggestionClear;
      case 1:
      case 2:
      case 3:
      case 45:
      case 48:
        return l10n.homeWeatherSuggestionCloudy;
      case 51:
      case 53:
      case 55:
      case 56:
      case 57:
      case 61:
      case 63:
      case 65:
      case 66:
      case 67:
      case 80:
      case 81:
      case 82:
        return l10n.homeWeatherSuggestionRain;
      case 71:
      case 73:
      case 75:
      case 77:
      case 85:
      case 86:
        return l10n.homeWeatherSuggestionSnow;
      case 95:
      case 96:
      case 99:
        return l10n.homeWeatherSuggestionStorm;
      default:
        return l10n.homeWeatherSuggestionCloudy;
    }
  }

  _AirQualityLevel _worstAirQualityLevel() {
    final levels = [
      _aqiLevel(AppLocalizations.of(context)!, _aqi, _airQualityScale).level,
      _pm10Level(AppLocalizations.of(context)!, _pm10).level,
      _pm25Level(AppLocalizations.of(context)!, _pm25).level,
    ];
    return levels.reduce(
      (current, next) => current.index >= next.index ? current : next,
    );
  }

  IconData _weatherIcon(int? code) {
    switch (code) {
      case 0:
        return Icons.wb_sunny_outlined;
      case 1:
      case 2:
      case 3:
        return Icons.wb_cloudy_outlined;
      case 45:
      case 48:
        return Icons.foggy;
      case 51:
      case 53:
      case 55:
      case 56:
      case 57:
      case 61:
      case 63:
      case 65:
      case 66:
      case 67:
      case 80:
      case 81:
      case 82:
        return Icons.umbrella_outlined;
      case 71:
      case 73:
      case 75:
      case 77:
      case 85:
      case 86:
        return Icons.ac_unit_rounded;
      case 95:
      case 96:
      case 99:
        return Icons.thunderstorm_outlined;
      default:
        return Icons.cloud_outlined;
    }
  }
}

class _CompactMetricData {
  final String label;
  final String value;
  final IconData icon;

  const _CompactMetricData({
    required this.label,
    required this.value,
    required this.icon,
  });
}

class _WeatherHeadlineParts {
  final String primary;
  final String? secondary;

  const _WeatherHeadlineParts({required this.primary, required this.secondary});

  factory _WeatherHeadlineParts.parse(String text) {
    final trimmed = text.trim();
    final match = RegExp(r'^(.+?)\s+(-?\d+(?:\.\d+)?°C)$').firstMatch(trimmed);
    if (match == null) {
      return _WeatherHeadlineParts(primary: trimmed, secondary: null);
    }
    return _WeatherHeadlineParts(
      primary: match.group(2)!,
      secondary: match.group(1)!,
    );
  }
}

class _CompactWeatherHeaderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? helper;
  final IconData icon;
  final bool loading;
  final VoidCallback? onRefresh;
  final List<_CompactMetricData> metrics;
  final Widget? footer;

  const _CompactWeatherHeaderCard({
    required this.title,
    required this.subtitle,
    this.helper,
    required this.icon,
    required this.loading,
    required this.onRefresh,
    required this.metrics,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headline = _WeatherHeadlineParts.parse(title);
    final onGradient = theme.colorScheme.onPrimaryContainer;
    final onGradientMuted = onGradient.withValues(alpha: 0.76);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withValues(alpha: 0.95),
            theme.colorScheme.secondaryContainer.withValues(alpha: 0.82),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.14),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -28,
            right: -20,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -24,
            bottom: -42,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withValues(
                          alpha: 0.22,
                        ),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: theme.colorScheme.surface.withValues(
                            alpha: 0.18,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.place_rounded,
                            size: 16,
                            color: onGradient,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: onGradient,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.surface.withValues(
                          alpha: 0.16,
                        ),
                      ),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: onRefresh,
                      icon: loading
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.1,
                                color: onGradient,
                              ),
                            )
                          : Icon(
                              Icons.refresh_rounded,
                              size: 20,
                              color: onGradient,
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          headline.primary,
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: onGradient,
                            fontWeight: FontWeight.w900,
                            height: 0.95,
                          ),
                        ),
                        if (headline.secondary != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            headline.secondary!,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: onGradient,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                        if (helper != null && helper!.trim().isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            helper!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: onGradientMuted,
                              height: 1.4,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: theme.colorScheme.surface.withValues(
                          alpha: 0.14,
                        ),
                      ),
                    ),
                    child: Center(
                      child: loading
                          ? SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: onGradient,
                              ),
                            )
                          : Icon(icon, size: 40, color: onGradient),
                    ),
                  ),
                ],
              ),
              if (metrics.isNotEmpty) ...[
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    const spacing = 10.0;
                    final halfWidth = (constraints.maxWidth - spacing) / 2;
                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: [
                        for (var index = 0; index < metrics.length; index++)
                          SizedBox(
                            width: metrics.length.isOdd &&
                                    index == metrics.length - 1
                                ? constraints.maxWidth
                                : halfWidth,
                            child: _MetricCard(
                              label: metrics[index].label,
                              value: metrics[index].value,
                              icon: metrics[index].icon,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
              if (footer != null) ...[const SizedBox(height: 14), footer!],
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayAirQualitySection extends StatelessWidget {
  final String title;
  final String pm10Label;
  final String pm10Value;
  final String pm10Status;
  final _AirQualityLevel pm10Level;
  final String pm25Label;
  final String pm25Value;
  final String pm25Status;
  final _AirQualityLevel pm25Level;

  const _TodayAirQualitySection({
    required this.title,
    required this.pm10Label,
    required this.pm10Value,
    required this.pm10Status,
    required this.pm10Level,
    required this.pm25Label,
    required this.pm25Value,
    required this.pm25Status,
    required this.pm25Level,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _AirMetricCard(
                  label: pm10Label,
                  value: pm10Value,
                  status: pm10Status,
                  level: pm10Level,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AirMetricCard(
                  label: pm25Label,
                  value: pm25Value,
                  status: pm25Status,
                  level: pm25Level,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AirMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String status;
  final _AirQualityLevel level;

  const _AirMetricCard({
    required this.label,
    required this.value,
    required this.status,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _airQualityPalette(theme, level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: palette.foreground,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: _AirStatusPill(label: status, level: level),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AirStatusPill extends StatelessWidget {
  final String label;
  final _AirQualityLevel level;

  const _AirStatusPill({required this.label, required this.level});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _airQualityPalette(theme, level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: palette.foreground.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: palette.foreground,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _WeatherOutfitGuideScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final String layersLabel;
  final String outerLabel;
  final String bottomLabel;
  final String accessoriesLabel;
  final String cautionLabel;
  final String buttonLabel;
  final String weatherSummary;
  final String feelsLikeLabel;
  final String feelsLikeValue;
  final String windLabel;
  final String windValue;
  final String airLabel;
  final String airValue;
  final _DetailedOutfitGuide guide;
  final String casesTitle;
  final String casesSubtitle;
  final List<_OutfitCase> cases;

  const _WeatherOutfitGuideScreen({
    required this.title,
    required this.subtitle,
    required this.layersLabel,
    required this.outerLabel,
    required this.bottomLabel,
    required this.accessoriesLabel,
    required this.cautionLabel,
    required this.buttonLabel,
    required this.weatherSummary,
    required this.feelsLikeLabel,
    required this.feelsLikeValue,
    required this.windLabel,
    required this.windValue,
    required this.airLabel,
    required this.airValue,
    required this.guide,
    required this.casesTitle,
    required this.casesSubtitle,
    required this.cases,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: _StructuredOutfitGuideCard(
              title: title,
              subtitle: subtitle,
              layersLabel: layersLabel,
              outerLabel: outerLabel,
              bottomLabel: bottomLabel,
              accessoriesLabel: accessoriesLabel,
              cautionLabel: cautionLabel,
              buttonLabel: buttonLabel,
              weatherSummary: weatherSummary,
              feelsLikeLabel: feelsLikeLabel,
              feelsLikeValue: feelsLikeValue,
              windLabel: windLabel,
              windValue: windValue,
              airLabel: airLabel,
              airValue: airValue,
              guide: guide,
              onViewAll: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _AllOutfitCasesScreen(
                      title: casesTitle,
                      subtitle: casesSubtitle,
                      layersLabel: layersLabel,
                      outerLabel: outerLabel,
                      bottomLabel: bottomLabel,
                      accessoriesLabel: accessoriesLabel,
                      cautionLabel: cautionLabel,
                      cases: cases,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _AllOutfitCasesScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final String layersLabel;
  final String outerLabel;
  final String bottomLabel;
  final String accessoriesLabel;
  final String cautionLabel;
  final List<_OutfitCase> cases;

  const _AllOutfitCasesScreen({
    required this.title,
    required this.subtitle,
    required this.layersLabel,
    required this.outerLabel,
    required this.bottomLabel,
    required this.accessoriesLabel,
    required this.cautionLabel,
    required this.cases,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: AppBackground(
        child: SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: cases.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    height: 1.45,
                  ),
                );
              }
              final outfitCase = cases[index - 1];
              return _OutfitCaseDetailCard(
                outfitCase: outfitCase,
                layersLabel: layersLabel,
                outerLabel: outerLabel,
                bottomLabel: bottomLabel,
                accessoriesLabel: accessoriesLabel,
                cautionLabel: cautionLabel,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _OutfitCaseDetailCard extends StatelessWidget {
  final _OutfitCase outfitCase;
  final String layersLabel;
  final String outerLabel;
  final String bottomLabel;
  final String accessoriesLabel;
  final String cautionLabel;

  const _OutfitCaseDetailCard({
    required this.outfitCase,
    required this.layersLabel,
    required this.outerLabel,
    required this.bottomLabel,
    required this.accessoriesLabel,
    required this.cautionLabel,
  });

  List<String> _splitItems(String raw, Pattern separator) => raw
      .split(separator)
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accessoryItems = _splitItems(outfitCase.guide.accessories, ',');
    final cautionItems = _splitItems(outfitCase.guide.caution, '·');
    final items = [
      (
        label: layersLabel,
        value: outfitCase.guide.layers,
        icon: Icons.checkroom_rounded,
        accent: theme.colorScheme.primaryContainer,
        foreground: theme.colorScheme.primary,
      ),
      (
        label: outerLabel,
        value: outfitCase.guide.outer,
        icon: Icons.shield_outlined,
        accent: theme.colorScheme.secondaryContainer,
        foreground: theme.colorScheme.secondary,
      ),
      (
        label: bottomLabel,
        value: outfitCase.guide.bottom,
        icon: Icons.directions_run_rounded,
        accent: theme.colorScheme.tertiaryContainer,
        foreground: theme.colorScheme.tertiary,
      ),
      (
        label: accessoriesLabel,
        value: outfitCase.guide.accessories,
        icon: Icons.backpack_outlined,
        accent: theme.colorScheme.surfaceContainerHighest,
        foreground: theme.colorScheme.onSurfaceVariant,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            outfitCase.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _NeutralInfoChip(label: outfitCase.range),
              _NeutralInfoChip(label: outfitCase.summary),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: items
                    .map(
                      (item) => SizedBox(
                        width: cardWidth,
                        child: _OutfitVisualCard(
                          label: item.label,
                          value: item.value,
                          icon: item.icon,
                          accent: item.accent,
                          foreground: item.foreground,
                        ),
                      ),
                    )
                    .toList(growable: false),
              );
            },
          ),
          if (accessoryItems.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: accessoryItems
                  .map((item) => _NeutralInfoChip(label: item))
                  .toList(growable: false),
            ),
          ],
          if (cautionItems.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.55,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cautionLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...cautionItems.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '•',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.onSurface,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StructuredOutfitGuideCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String layersLabel;
  final String outerLabel;
  final String bottomLabel;
  final String accessoriesLabel;
  final String cautionLabel;
  final String buttonLabel;
  final String weatherSummary;
  final String feelsLikeLabel;
  final String feelsLikeValue;
  final String windLabel;
  final String windValue;
  final String airLabel;
  final String airValue;
  final _DetailedOutfitGuide guide;
  final VoidCallback onViewAll;

  const _StructuredOutfitGuideCard({
    required this.title,
    required this.subtitle,
    required this.layersLabel,
    required this.outerLabel,
    required this.bottomLabel,
    required this.accessoriesLabel,
    required this.cautionLabel,
    required this.buttonLabel,
    required this.weatherSummary,
    required this.feelsLikeLabel,
    required this.feelsLikeValue,
    required this.windLabel,
    required this.windValue,
    required this.airLabel,
    required this.airValue,
    required this.guide,
    required this.onViewAll,
  });

  List<String> _splitItems(String raw, Pattern separator) => raw
      .split(separator)
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accessoryItems = _splitItems(guide.accessories, ',');
    final cautionItems = _splitItems(guide.caution, '·');
    final items = [
      (
        label: layersLabel,
        value: guide.layers,
        icon: Icons.checkroom_rounded,
        accent: theme.colorScheme.primaryContainer,
        foreground: theme.colorScheme.primary,
      ),
      (
        label: outerLabel,
        value: guide.outer,
        icon: Icons.shield_outlined,
        accent: theme.colorScheme.secondaryContainer,
        foreground: theme.colorScheme.secondary,
      ),
      (
        label: bottomLabel,
        value: guide.bottom,
        icon: Icons.directions_run_rounded,
        accent: theme.colorScheme.tertiaryContainer,
        foreground: theme.colorScheme.tertiary,
      ),
      (
        label: accessoriesLabel,
        value: guide.accessories,
        icon: Icons.backpack_outlined,
        accent: theme.colorScheme.surfaceContainerHighest,
        foreground: theme.colorScheme.onSurfaceVariant,
      ),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primaryContainer.withValues(alpha: 0.95),
                  theme.colorScheme.secondaryContainer.withValues(alpha: 0.86),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer
                              .withValues(alpha: 0.82),
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                      if (weatherSummary.trim().isNotEmpty ||
                          feelsLikeValue != '--' ||
                          windValue != '--' ||
                          airValue != '--') ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (weatherSummary.trim().isNotEmpty)
                              _NeutralInfoChip(label: weatherSummary.trim()),
                            if (feelsLikeValue != '--')
                              _NeutralInfoChip(
                                label: '$feelsLikeLabel $feelsLikeValue',
                              ),
                            if (windValue != '--')
                              _NeutralInfoChip(label: '$windLabel $windValue'),
                            if (airValue != '--')
                              _NeutralInfoChip(label: '$airLabel $airValue'),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        guide.coachSummary,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w800,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(alpha: 0.32),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.checkroom_rounded,
                    size: 34,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (guide.callouts.isNotEmpty) ...[
            ...guide.callouts.map(
              (callout) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _OutfitCoachCalloutCard(callout: callout),
              ),
            ),
            const SizedBox(height: 2),
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: items
                    .map(
                      (item) => SizedBox(
                        width: cardWidth,
                        child: _OutfitVisualCard(
                          label: item.label,
                          value: item.value,
                          icon: item.icon,
                          accent: item.accent,
                          foreground: item.foreground,
                        ),
                      ),
                    )
                    .toList(growable: false),
              );
            },
          ),
          if (accessoryItems.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              accessoriesLabel,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: accessoryItems
                  .map((item) => _NeutralInfoChip(label: item))
                  .toList(growable: false),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.tips_and_updates_outlined,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cautionLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...cautionItems.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '•',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.onSurface,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonalIcon(
              onPressed: onViewAll,
              icon: const Icon(Icons.view_carousel_outlined, size: 18),
              label: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _OutfitVisualCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final Color foreground;

  const _OutfitVisualCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 148,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.92),
            theme.colorScheme.surface.withValues(alpha: 0.96),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -8,
            right: -4,
            child: Icon(
              icon,
              size: 72,
              color: foreground.withValues(alpha: 0.12),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.58),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 22, color: foreground),
              ),
              const Spacer(),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OutfitCoachCalloutCard extends StatelessWidget {
  final _OutfitCoachCallout callout;

  const _OutfitCoachCalloutCard({required this.callout});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              callout.icon,
              size: 18,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              callout.text,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeatherRecommendationActions extends StatelessWidget {
  final String outfitLabel;
  final String trainingLabel;
  final VoidCallback onOutfitTap;
  final VoidCallback onTrainingTap;

  const _WeatherRecommendationActions({
    required this.outfitLabel,
    required this.trainingLabel,
    required this.onOutfitTap,
    required this.onTrainingTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.tonalIcon(
            onPressed: onOutfitTap,
            icon: const Icon(Icons.checkroom_outlined, size: 18),
            label: Text(outfitLabel),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.tonalIcon(
            onPressed: onTrainingTap,
            icon: const Icon(Icons.sports_soccer_rounded, size: 18),
            label: Text(trainingLabel),
          ),
        ),
      ],
    );
  }
}

class _StructuredTrainingGuideCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String focusLabel;
  final String cautionLabel;
  final String recoveryLabel;
  final _TrainingGuide guide;

  const _StructuredTrainingGuideCard({
    required this.title,
    required this.subtitle,
    required this.focusLabel,
    required this.cautionLabel,
    required this.recoveryLabel,
    required this.guide,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          _TrainingGuideBlock(label: focusLabel, value: guide.focus),
          const SizedBox(height: 10),
          _TrainingGuideBlock(label: cautionLabel, value: guide.caution),
          const SizedBox(height: 10),
          _TrainingGuideBlock(label: recoveryLabel, value: guide.recovery),
        ],
      ),
    );
  }
}

class _TrainingGuideBlock extends StatelessWidget {
  final String label;
  final String value;

  const _TrainingGuideBlock({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TomorrowWeatherCard extends StatelessWidget {
  final String title;
  final String conditionLabel;
  final String highLowLabel;
  final String precipitationLabel;
  final String hourlyPrecipitationLabel;
  final String windLabel;
  final _DailyWeatherForecast? tomorrowForecast;
  final String tomorrowFallback;
  final String Function(double?, double?) formatRange;
  final String Function(double?) formatMillimeter;
  final String Function(double) formatCompactMillimeter;
  final String Function(double?) formatWind;
  final String Function(DateTime) formatTime;
  final IconData Function(int?) iconForCode;

  const _TomorrowWeatherCard({
    required this.title,
    required this.conditionLabel,
    required this.highLowLabel,
    required this.precipitationLabel,
    required this.hourlyPrecipitationLabel,
    required this.windLabel,
    required this.tomorrowForecast,
    required this.tomorrowFallback,
    required this.formatRange,
    required this.formatMillimeter,
    required this.formatCompactMillimeter,
    required this.formatWind,
    required this.formatTime,
    required this.iconForCode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final forecast = tomorrowForecast;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: forecast == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  tomorrowFallback,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${forecast.weekdayLabel} · ${forecast.label}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        iconForCode(forecast.weatherCode),
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Column(
                  children: [
                    _CompactForecastInfoRow(
                      label: conditionLabel,
                      value: forecast.summary,
                      icon: iconForCode(forecast.weatherCode),
                    ),
                    const SizedBox(height: 8),
                    _CompactForecastInfoRow(
                      label: highLowLabel,
                      value: formatRange(
                        forecast.temperatureMax,
                        forecast.temperatureMin,
                      ),
                      icon: Icons.thermostat_outlined,
                    ),
                    const SizedBox(height: 8),
                    _CompactForecastInfoRow(
                      label: precipitationLabel,
                      value: formatMillimeter(forecast.precipitationSum),
                      icon: Icons.water_drop_outlined,
                    ),
                    const SizedBox(height: 8),
                    _CompactForecastInfoRow(
                      label: windLabel,
                      value: formatWind(forecast.windSpeedMax),
                      icon: Icons.air_rounded,
                    ),
                    if (forecast.hourlyPrecipitations.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _HourlyPrecipitationSection(
                        title: hourlyPrecipitationLabel,
                        entries: forecast.hourlyPrecipitations,
                        formatTime: formatTime,
                        formatPrecipitation: formatCompactMillimeter,
                      ),
                    ],
                  ],
                ),
              ],
            ),
    );
  }
}

class _WeeklyForecastCard extends StatelessWidget {
  final String title;
  final String precipitationLabel;
  final String windLabel;
  final List<_DailyWeatherForecast> forecasts;
  final String Function(double?, double?) formatRange;
  final String Function(double?) formatMillimeter;
  final String Function(double?) formatWind;
  final IconData Function(int?) iconForCode;

  const _WeeklyForecastCard({
    required this.title,
    required this.precipitationLabel,
    required this.windLabel,
    required this.forecasts,
    required this.formatRange,
    required this.formatMillimeter,
    required this.formatWind,
    required this.iconForCode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${forecasts.length}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final forecast in forecasts) ...[
            _WeeklyForecastRow(
              precipitationLabel: precipitationLabel,
              windLabel: windLabel,
              forecast: forecast,
              range: formatRange(
                forecast.temperatureMax,
                forecast.temperatureMin,
              ),
              precipitation: formatMillimeter(forecast.precipitationSum),
              wind: formatWind(forecast.windSpeedMax),
              icon: iconForCode(forecast.weatherCode),
            ),
            if (!identical(forecast, forecasts.last))
              const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _WeeklyForecastRow extends StatelessWidget {
  final String precipitationLabel;
  final String windLabel;
  final _DailyWeatherForecast forecast;
  final String range;
  final String precipitation;
  final String wind;
  final IconData icon;

  const _WeeklyForecastRow({
    required this.precipitationLabel,
    required this.windLabel,
    required this.forecast,
    required this.range,
    required this.precipitation,
    required this.wind,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 20, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        '${forecast.weekdayLabel} · ${forecast.label}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        range,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  forecast.summary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$precipitationLabel $precipitation',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$windLabel $wind',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HourlyPrecipitationSection extends StatelessWidget {
  final String title;
  final List<_HourlyPrecipitationEntry> entries;
  final String Function(DateTime) formatTime;
  final String Function(double) formatPrecipitation;
  final bool accentStyle;

  const _HourlyPrecipitationSection({
    required this.title,
    required this.entries,
    required this.formatTime,
    required this.formatPrecipitation,
    this.accentStyle = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sortedEntries = [...entries]
      ..sort((left, right) => left.time.compareTo(right.time));
    final background = accentStyle
        ? theme.colorScheme.surface.withValues(alpha: 0.16)
        : theme.colorScheme.surfaceContainerLow;
    final borderColor = accentStyle
        ? theme.colorScheme.surface.withValues(alpha: 0.16)
        : theme.colorScheme.outlineVariant.withValues(alpha: 0.5);
    final titleColor = accentStyle
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface;
    final chipColor = accentStyle
        ? theme.colorScheme.surface.withValues(alpha: 0.22)
        : theme.colorScheme.primaryContainer.withValues(alpha: 0.75);
    final chipTextColor = accentStyle
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onPrimaryContainer;
    final connectorColor = accentStyle
        ? theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.24)
        : theme.colorScheme.primary.withValues(alpha: 0.22);
    final timeTextColor = accentStyle
        ? theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.72)
        : theme.colorScheme.onSurfaceVariant;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              color: titleColor,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var index = 0; index < sortedEntries.length; index++) ...[
                  _HourlyPrecipitationTimelineItem(
                    timeLabel: formatTime(sortedEntries[index].time),
                    precipitationLabel: formatPrecipitation(
                      sortedEntries[index].precipitation,
                    ),
                    markerColor: chipTextColor,
                    connectorColor: connectorColor,
                    timeTextColor: timeTextColor,
                    cardColor: chipColor,
                    cardTextColor: chipTextColor,
                    showLeadingConnector: index > 0,
                    showTrailingConnector: index < sortedEntries.length - 1,
                  ),
                  if (index < sortedEntries.length - 1)
                    const SizedBox(width: 6),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HourlyPrecipitationTimelineItem extends StatelessWidget {
  final String timeLabel;
  final String precipitationLabel;
  final Color markerColor;
  final Color connectorColor;
  final Color timeTextColor;
  final Color cardColor;
  final Color cardTextColor;
  final bool showLeadingConnector;
  final bool showTrailingConnector;

  const _HourlyPrecipitationTimelineItem({
    required this.timeLabel,
    required this.precipitationLabel,
    required this.markerColor,
    required this.connectorColor,
    required this.timeTextColor,
    required this.cardColor,
    required this.cardTextColor,
    required this.showLeadingConnector,
    required this.showTrailingConnector,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 88,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            timeLabel,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium?.copyWith(
              color: timeTextColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: showLeadingConnector
                        ? connectorColor
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: markerColor,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: showTrailingConnector
                        ? connectorColor
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.water_drop_outlined, size: 18, color: cardTextColor),
                const SizedBox(height: 6),
                Text(
                  precipitationLabel,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: cardTextColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HourlyPrecipitationEntry {
  final DateTime time;
  final double precipitation;

  const _HourlyPrecipitationEntry({
    required this.time,
    required this.precipitation,
  });
}

class _CompactForecastInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _CompactForecastInfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _NeutralInfoChip extends StatelessWidget {
  final String label;

  const _NeutralInfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
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
  final AppLocalizations l10n;

  const _WeatherLocalizer({required this.l10n});

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

enum _AirQualityLevel {
  unknown,
  good,
  moderate,
  sensitive,
  unhealthy,
  veryUnhealthy,
  hazardous,
}

class _AirLevelLabel {
  final String label;
  final _AirQualityLevel level;

  const _AirLevelLabel(this.label, this.level);
}

class _AirQualityPalette {
  final Color background;
  final Color border;
  final Color foreground;

  const _AirQualityPalette({
    required this.background,
    required this.border,
    required this.foreground,
  });
}

_AirQualityPalette _airQualityPalette(ThemeData theme, _AirQualityLevel level) {
  final isDark = theme.brightness == Brightness.dark;
  if (isDark) {
    switch (level) {
      case _AirQualityLevel.good:
        return const _AirQualityPalette(
          background: Color(0xFF0D2B1A),
          border: Color(0xFF2F8A54),
          foreground: Color(0xFFA6E9C0),
        );
      case _AirQualityLevel.moderate:
        return const _AirQualityPalette(
          background: Color(0xFF2D260E),
          border: Color(0xFF9B7A2F),
          foreground: Color(0xFFF3D585),
        );
      case _AirQualityLevel.sensitive:
        return const _AirQualityPalette(
          background: Color(0xFF2D1F10),
          border: Color(0xFFB67933),
          foreground: Color(0xFFFFC37A),
        );
      case _AirQualityLevel.unhealthy:
        return const _AirQualityPalette(
          background: Color(0xFF32191A),
          border: Color(0xFFB45353),
          foreground: Color(0xFFFFADAD),
        );
      case _AirQualityLevel.veryUnhealthy:
        return const _AirQualityPalette(
          background: Color(0xFF2A1A33),
          border: Color(0xFF8F63B8),
          foreground: Color(0xFFD6B7F4),
        );
      case _AirQualityLevel.hazardous:
        return const _AirQualityPalette(
          background: Color(0xFF351426),
          border: Color(0xFFB64F81),
          foreground: Color(0xFFFFAED1),
        );
      case _AirQualityLevel.unknown:
        return _AirQualityPalette(
          background: theme.colorScheme.surfaceContainerHigh,
          border: theme.colorScheme.outlineVariant,
          foreground: theme.colorScheme.onSurfaceVariant,
        );
    }
  }
  switch (level) {
    case _AirQualityLevel.good:
      return const _AirQualityPalette(
        background: Color(0xFFE7F7EC),
        border: Color(0xFF6FC38A),
        foreground: Color(0xFF1C6B3D),
      );
    case _AirQualityLevel.moderate:
      return const _AirQualityPalette(
        background: Color(0xFFFFF6DE),
        border: Color(0xFFE6C15A),
        foreground: Color(0xFF8A6A07),
      );
    case _AirQualityLevel.sensitive:
      return const _AirQualityPalette(
        background: Color(0xFFFFF0DF),
        border: Color(0xFFF0A860),
        foreground: Color(0xFF9B5B17),
      );
    case _AirQualityLevel.unhealthy:
      return const _AirQualityPalette(
        background: Color(0xFFFDE8E8),
        border: Color(0xFFE07A7A),
        foreground: Color(0xFF9B2E2E),
      );
    case _AirQualityLevel.veryUnhealthy:
      return const _AirQualityPalette(
        background: Color(0xFFF2E8FA),
        border: Color(0xFFB089D9),
        foreground: Color(0xFF64358E),
      );
    case _AirQualityLevel.hazardous:
      return const _AirQualityPalette(
        background: Color(0xFFFFE3F0),
        border: Color(0xFFE06AA3),
        foreground: Color(0xFF8E1E57),
      );
    case _AirQualityLevel.unknown:
      return _AirQualityPalette(
        background: theme.colorScheme.surfaceContainerHighest,
        border: theme.colorScheme.outlineVariant,
        foreground: theme.colorScheme.onSurfaceVariant,
      );
  }
}

class _WeatherDetailsSnapshot {
  final String summary;
  final int? weatherCode;
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
  final _AirQualityScale airQualityScale;
  final List<_DailyWeatherForecast> dailyForecasts;

  const _WeatherDetailsSnapshot({
    required this.summary,
    this.weatherCode,
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
    this.airQualityScale = _AirQualityScale.usAqi,
    this.dailyForecasts = const <_DailyWeatherForecast>[],
  });
}

class _ResolvedAirQualitySnapshot {
  final AirQualitySnapshot snapshot;
  final _AirQualityScale scale;

  const _ResolvedAirQualitySnapshot({
    required this.snapshot,
    required this.scale,
  });
}

enum _AirQualityScale { usAqi, khai }

class _DailyWeatherForecast {
  final DateTime date;
  final String label;
  final String weekdayLabel;
  final int? weatherCode;
  final String summary;
  final double? temperatureMax;
  final double? temperatureMin;
  final double? precipitationSum;
  final double? windSpeedMax;
  final double? uvIndexMax;
  final List<_HourlyPrecipitationEntry> hourlyPrecipitations;

  const _DailyWeatherForecast({
    required this.date,
    required this.label,
    required this.weekdayLabel,
    required this.weatherCode,
    required this.summary,
    this.temperatureMax,
    this.temperatureMin,
    this.precipitationSum,
    this.windSpeedMax,
    this.uvIndexMax,
    this.hourlyPrecipitations = const <_HourlyPrecipitationEntry>[],
  });

  _DailyWeatherForecast copyWith({String? label, String? weekdayLabel}) {
    return _DailyWeatherForecast(
      date: date,
      label: label ?? this.label,
      weekdayLabel: weekdayLabel ?? this.weekdayLabel,
      weatherCode: weatherCode,
      summary: summary,
      temperatureMax: temperatureMax,
      temperatureMin: temperatureMin,
      precipitationSum: precipitationSum,
      windSpeedMax: windSpeedMax,
      uvIndexMax: uvIndexMax,
      hourlyPrecipitations: hourlyPrecipitations,
    );
  }
}

class _DetailedOutfitGuide {
  final String layers;
  final String outer;
  final String bottom;
  final String accessories;
  final String coachSummary;
  final List<_OutfitCoachCallout> callouts;
  final String caution;

  const _DetailedOutfitGuide({
    required this.layers,
    required this.outer,
    required this.bottom,
    required this.accessories,
    required this.coachSummary,
    this.callouts = const <_OutfitCoachCallout>[],
    required this.caution,
  });
}

class _OutfitCoachCallout {
  final IconData icon;
  final String text;

  const _OutfitCoachCallout({required this.icon, required this.text});
}

class _TrainingGuide {
  final String focus;
  final String caution;
  final String recovery;

  const _TrainingGuide({
    required this.focus,
    required this.caution,
    required this.recovery,
  });
}

class _OutfitCase {
  final String title;
  final String range;
  final String summary;
  final _DetailedOutfitGuide guide;

  const _OutfitCase({
    required this.title,
    required this.range,
    required this.summary,
    required this.guide,
  });
}

class _CachedWeatherDetails {
  final String location;
  final _WeatherDetailsSnapshot snapshot;
  final String localeTag;
  final DateTime fetchedAt;

  const _CachedWeatherDetails({
    required this.location,
    required this.snapshot,
    required this.localeTag,
    required this.fetchedAt,
  });
}
