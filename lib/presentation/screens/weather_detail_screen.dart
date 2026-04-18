import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../application/weather_current_service.dart';
import '../../application/weather_forecast_service.dart';
import '../../application/weather_location_service.dart';
import '../widgets/app_background.dart';

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

  static Future<void> warmUpFromHomeSync({
    required double latitude,
    required double longitude,
    required String location,
    required AppLocalizations l10n,
    required Locale locale,
    required String summary,
    required int? weatherCode,
  }) async {
    final fetched = await _fetchWeatherSnapshotStatic(
      latitude: latitude,
      longitude: longitude,
      l10n: l10n,
    );
    final snapshot = fetched.summary.trim().isEmpty
        ? _WeatherDetailsSnapshot(
            summary: summary.trim(),
            weatherCode: weatherCode,
          )
        : fetched;
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
    final currentWeatherFuture = WeatherCurrentService.fetchCurrentWeather(
      latitude: latitude,
      longitude: longitude,
    );
    final weatherUri = WeatherForecastService.buildForecastUri(
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
    final airQualityUri =
        Uri.https('air-quality-api.open-meteo.com', '/v1/air-quality', {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'current': 'pm10,pm2_5,us_aqi',
      'timezone': 'auto',
    });
    final responses = await Future.wait([
      currentWeatherFuture,
      http.get(weatherUri),
      http.get(airQualityUri),
    ]);
    final currentSnapshot = responses[0] as WeatherCurrentSnapshot;
    final weatherResponse = responses[1] as http.Response;
    final airResponse = responses[2] as http.Response;

    Map<String, dynamic>? weatherDecoded;
    if (weatherResponse.statusCode == 200) {
      final decoded = jsonDecode(weatherResponse.body);
      if (decoded is Map<String, dynamic>) {
        weatherDecoded = decoded;
      }
    }

    Map<String, dynamic>? airDecoded;
    if (airResponse.statusCode == 200) {
      final decoded = jsonDecode(airResponse.body);
      if (decoded is Map<String, dynamic>) {
        airDecoded = decoded;
      }
    }

    if (weatherDecoded == null &&
        airDecoded == null &&
        !currentSnapshot.hasData) {
      return const _WeatherDetailsSnapshot(summary: '');
    }

    final current = weatherDecoded?['current'];
    final daily = weatherDecoded?['daily'];
    final airCurrent = airDecoded?['current'];
    final openMeteoCurrent =
        current is Map<String, dynamic> ? current : const <String, dynamic>{};
    final openMeteoDaily =
        daily is Map<String, dynamic> ? daily : const <String, dynamic>{};
    final openMeteoAir = airCurrent is Map<String, dynamic>
        ? airCurrent
        : const <String, dynamic>{};

    final localizer = _WeatherLocalizer(l10n: l10n);
    final weatherCode = currentSnapshot.weatherCode ??
        (openMeteoCurrent['weather_code'] as num?)?.toInt();
    final temperature = currentSnapshot.temperature ??
        (openMeteoCurrent['temperature_2m'] as num?)?.toDouble();
    final summary = _buildWeatherSummaryStatic(
      temperature: temperature,
      weatherCode: weatherCode,
      localizer: localizer,
    );
    final dailyMax =
        _firstDailyNumberStatic(openMeteoDaily['temperature_2m_max']);
    final dailyMin =
        _firstDailyNumberStatic(openMeteoDaily['temperature_2m_min']);
    final forecasts = _buildDailyForecastsStatic(
      openMeteoDaily,
      localizer: localizer,
    );

    return _WeatherDetailsSnapshot(
      summary: summary,
      weatherCode: weatherCode,
      apparentTemperature:
          (openMeteoCurrent['apparent_temperature'] as num?)?.toDouble(),
      humidity: currentSnapshot.humidity ??
          (openMeteoCurrent['relative_humidity_2m'] as num?)?.toDouble(),
      windSpeed: currentSnapshot.windSpeed ??
          (openMeteoCurrent['wind_speed_10m'] as num?)?.toDouble(),
      temperatureMax: dailyMax,
      temperatureMin: dailyMin,
      pm10: (openMeteoAir['pm10'] as num?)?.toDouble(),
      pm25: (openMeteoAir['pm2_5'] as num?)?.toDouble(),
      aqi: (openMeteoAir['us_aqi'] as num?)?.toInt(),
      dailyForecasts: forecasts,
    );
  }

  static String _buildWeatherSummaryStatic({
    required double? temperature,
    required int? weatherCode,
    required _WeatherLabelLocalizer localizer,
  }) {
    final weatherText = weatherCode == null
        ? ''
        : _weatherLabelFromCodeStatic(
            weatherCode,
            localizer: localizer,
          );
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

  static double? _firstDailyNumberStatic(Object? value) {
    if (value is List && value.isNotEmpty) {
      return (value.first as num?)?.toDouble();
    }
    return null;
  }

  static List<_DailyWeatherForecast> _buildDailyForecastsStatic(
    Map<String, dynamic> daily, {
    required _WeatherLabelLocalizer localizer,
  }) {
    final times = daily['time'];
    final codes = daily['weather_code'];
    final maxTemps = daily['temperature_2m_max'];
    final minTemps = daily['temperature_2m_min'];
    final precipitationSums = daily['precipitation_sum'];
    final maxWinds = daily['wind_speed_10m_max'];
    final uvIndexMax = daily['uv_index_max'];
    if (times is! List) return const <_DailyWeatherForecast>[];

    final forecasts = <_DailyWeatherForecast>[];
    for (var index = 0; index < times.length; index++) {
      final rawDate = times[index]?.toString();
      final date = rawDate == null ? null : DateTime.tryParse(rawDate);
      if (date == null) continue;
      final weatherCode = _numberAtStatic(codes, index)?.toInt();
      forecasts.add(
        _DailyWeatherForecast(
          date: date,
          label: '',
          weekdayLabel: '',
          weatherCode: weatherCode,
          summary: _weatherLabelFromCodeStatic(
            weatherCode,
            localizer: localizer,
          ),
          temperatureMax: _numberAtStatic(maxTemps, index)?.toDouble(),
          temperatureMin: _numberAtStatic(minTemps, index)?.toDouble(),
          precipitationSum: _numberAtStatic(
            precipitationSums,
            index,
          )?.toDouble(),
          windSpeedMax: _numberAtStatic(maxWinds, index)?.toDouble(),
          uvIndexMax: _numberAtStatic(uvIndexMax, index)?.toDouble(),
        ),
      );
    }
    return forecasts;
  }

  static num? _numberAtStatic(Object? values, int index) {
    if (values is! List || index >= values.length) return null;
    return values[index] as num?;
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
  double? _windSpeed;
  double? _temperatureMax;
  double? _temperatureMin;
  double? _pm10;
  double? _pm25;
  int? _aqi;
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
    final airLevel = _aqiLevel(l10n, _aqi);
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
                          value: _formatRange(_temperatureMax, _temperatureMin),
                          icon: Icons.device_thermostat_outlined,
                        ),
                        _CompactMetricData(
                          label: l10n.homeWeatherFeelsLike,
                          value: _formatTemperature(_apparentTemperature),
                          icon: Icons.thermostat_auto_outlined,
                        ),
                        _CompactMetricData(
                          label: l10n.homeWeatherHumidity,
                          value: _formatPercent(_humidity),
                          icon: Icons.water_drop_outlined,
                        ),
                        _CompactMetricData(
                          label: l10n.homeWeatherWindSpeed,
                          value: _formatWind(_windSpeed),
                          icon: Icons.air_rounded,
                        ),
                      ]
                    : const <_CompactMetricData>[],
              ),
              if (hasWeather) ...[
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
                _AirQualityCard(
                  title: l10n.homeWeatherAirQualityTitle,
                  subtitle: l10n.homeWeatherAirQualitySubtitle,
                  status: airLevel.label,
                  aqiLabel: l10n.homeWeatherAqiLabel,
                  aqiDescription: l10n.homeWeatherAqiDescription,
                  aqiValue: _aqi == null ? '--' : '$_aqi',
                  aqiStatus: airLevel.label,
                  aqiLevel: airLevel.level,
                  pm10Label: l10n.homeWeatherPm10,
                  pm10Value: _formatParticles(_pm10),
                  pm10Status: pm10Level.label,
                  pm10Level: pm10Level.level,
                  pm25Label: l10n.homeWeatherPm25,
                  pm25Value: _formatParticles(_pm25),
                  pm25Status: pm25Level.label,
                  pm25Level: pm25Level.level,
                  scaleLabels: <String>[
                    l10n.homeWeatherAqiScaleGood,
                    l10n.homeWeatherAqiScaleModerate,
                    l10n.homeWeatherAqiScaleSensitive,
                  ],
                ),
                const SizedBox(height: 16),
                _TomorrowWeatherCard(
                  title: l10n.homeWeatherTomorrowTitle,
                  conditionLabel: l10n.homeWeatherTomorrowCondition,
                  highLowLabel: l10n.homeWeatherDailyHighLow,
                  precipitationLabel: l10n.homeWeatherPrecipitation,
                  windLabel: l10n.homeWeatherWindSpeed,
                  uvLabel: l10n.homeWeatherUvIndex,
                  tomorrowForecast:
                      _dailyForecasts.length > 1 ? _dailyForecasts[1] : null,
                  tomorrowFallback: l10n.homeWeatherTomorrowFallback,
                  formatRange: _formatRange,
                  formatMillimeter: _formatMillimeter,
                  formatWind: _formatWind,
                  formatUv: _formatUv,
                  iconForCode: _weatherIcon,
                ),
                const SizedBox(height: 16),
                _WeeklyForecastCard(
                  title: l10n.homeWeatherWeeklyTitle,
                  dateLabel: l10n.homeWeatherWeeklyDateLabel,
                  highLowLabel: l10n.homeWeatherDailyHighLow,
                  precipitationLabel: l10n.homeWeatherPrecipitation,
                  windLabel: l10n.homeWeatherWindSpeed,
                  forecasts: _dailyForecasts.skip(1).toList(growable: false),
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
      final snapshot = await _fetchWeatherSnapshot(
        latitude: position.latitude,
        longitude: position.longitude,
        l10n: l10n,
      );
      if (!mounted) return;
      setState(() {
        _applySnapshot(place, snapshot);
      });
      _maybeHandleInitialAction();
      _cachedDetails = _CachedWeatherDetails(
        location: place,
        snapshot: snapshot,
        localeTag: localeTag,
        fetchedAt: DateTime.now(),
      );
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
    _windSpeed = snapshot.windSpeed;
    _temperatureMax = snapshot.temperatureMax;
    _temperatureMin = snapshot.temperatureMin;
    _pm10 = snapshot.pm10;
    _pm25 = snapshot.pm25;
    _aqi = snapshot.aqi;
    _dailyForecasts = snapshot.dailyForecasts
        .map(
          (forecast) => forecast.copyWith(
            label: _formatForecastDate(forecast.date),
            weekdayLabel: _formatForecastWeekday(forecast.date),
          ),
        )
        .toList(growable: false);
  }

  String _formatForecastDate(DateTime date) => DateFormat.MMMd(
        Localizations.localeOf(context).toLanguageTag(),
      ).format(date);

  String _formatForecastWeekday(DateTime date) => DateFormat.E(
        Localizations.localeOf(context).toLanguageTag(),
      ).format(date);

  _AirLevelLabel _aqiLevel(AppLocalizations l10n, int? value) {
    if (value == null) {
      return const _AirLevelLabel('--', _AirQualityLevel.unknown);
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

  String _formatRange(double? high, double? low) {
    if (high == null && low == null) return '--';
    return '${_formatTemperature(high)} / ${_formatTemperature(low)}';
  }

  String _formatPercent(double? value) =>
      value == null ? '--' : '${value.toStringAsFixed(0)}%';

  String _formatMillimeter(double? value) =>
      value == null ? '--' : '${value.toStringAsFixed(1)} mm';

  String _formatWind(double? value) =>
      value == null ? '--' : '${value.toStringAsFixed(1)} km/h';

  String _formatUv(double? value) =>
      value == null ? '--' : value.toStringAsFixed(1);

  String _formatParticles(double? value) =>
      value == null ? '--' : '${value.toStringAsFixed(1)} µg/m³';

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
        windSpeed: _windSpeed ?? 0,
        weatherCode: _weatherCode,
        airLevel: _worstAirQualityLevel(),
      );

  _DetailedOutfitGuide _buildOutfitGuide({
    required bool isKo,
    required AppLocalizations l10n,
    required double? apparentTemperature,
    required double windSpeed,
    required int? weatherCode,
    required _AirQualityLevel airLevel,
  }) {
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
        }.contains(weatherCode);
    final isSnowy = weatherCode != null &&
        <int>{71, 73, 75, 77, 85, 86}.contains(weatherCode);

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

    if (windSpeed >= 20) {
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
      outer = isKo
          ? '생활방수 자켓 + 얇은 미들레이어'
          : 'Water-resistant jacket + light midlayer';
      accessories = isKo
          ? '$accessories, 방수 양말 또는 여벌 양말'
          : '$accessories, waterproof or spare socks';
      notes.add(isKo ? '젖은 잔디 미끄럼 주의' : 'Watch slippery wet grass');
      callouts.add(
        _OutfitCoachCallout(
          icon: Icons.umbrella_outlined,
          text: l10n.homeWeatherOutfitRain,
        ),
      );
    } else if (isSnowy) {
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
    if ((isSnowy || windSpeed >= 25) &&
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
      windSpeed: 8,
      weatherCode: 0,
      airLevel: _AirQualityLevel.good,
    );
    final warmGuide = _buildOutfitGuide(
      isKo: isKo,
      l10n: l10n,
      apparentTemperature: 25,
      windSpeed: 10,
      weatherCode: 1,
      airLevel: _AirQualityLevel.good,
    );
    final mildGuide = _buildOutfitGuide(
      isKo: isKo,
      l10n: l10n,
      apparentTemperature: 18,
      windSpeed: 11,
      weatherCode: 1,
      airLevel: _AirQualityLevel.good,
    );
    final coolGuide = _buildOutfitGuide(
      isKo: isKo,
      l10n: l10n,
      apparentTemperature: 11,
      windSpeed: 15,
      weatherCode: 2,
      airLevel: _AirQualityLevel.good,
    );
    final coldGuide = _buildOutfitGuide(
      isKo: isKo,
      l10n: l10n,
      apparentTemperature: 5,
      windSpeed: 12,
      weatherCode: 0,
      airLevel: _AirQualityLevel.good,
    );
    final wetGuide = _buildOutfitGuide(
      isKo: isKo,
      l10n: l10n,
      apparentTemperature: 6,
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
      _aqiLevel(AppLocalizations.of(context)!, _aqi).level,
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

  const _CompactWeatherHeaderCard({
    required this.title,
    required this.subtitle,
    this.helper,
    required this.icon,
    required this.loading,
    required this.onRefresh,
    required this.metrics,
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
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: metrics
                      .map(
                        (metric) => _MetricCard(
                          label: metric.label,
                          value: metric.value,
                          icon: metric.icon,
                        ),
                      )
                      .toList(growable: false),
                ),
              ],
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
    return SizedBox(
      width: 156,
      child: Container(
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AirQualityCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final String aqiLabel;
  final String aqiDescription;
  final String aqiValue;
  final String aqiStatus;
  final _AirQualityLevel aqiLevel;
  final String pm10Label;
  final String pm10Value;
  final String pm10Status;
  final _AirQualityLevel pm10Level;
  final String pm25Label;
  final String pm25Value;
  final String pm25Status;
  final _AirQualityLevel pm25Level;
  final List<String> scaleLabels;

  const _AirQualityCard({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.aqiLabel,
    required this.aqiDescription,
    required this.aqiValue,
    required this.aqiStatus,
    required this.aqiLevel,
    required this.pm10Label,
    required this.pm10Value,
    required this.pm10Status,
    required this.pm10Level,
    required this.pm25Label,
    required this.pm25Value,
    required this.pm25Status,
    required this.pm25Level,
    required this.scaleLabels,
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
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusBadge(label: status, level: aqiLevel),
              for (final scaleLabel in scaleLabels)
                _NeutralInfoChip(label: scaleLabel),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  aqiLabel,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      aqiValue,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: _airQualityPalette(theme, aqiLevel).foreground,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _StatusBadge(label: aqiStatus, level: aqiLevel),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  aqiDescription,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _AirQualityMetric(
                  label: aqiLabel,
                  value: aqiValue,
                  status: aqiStatus,
                  level: aqiLevel,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AirQualityMetric(
                  label: pm10Label,
                  value: pm10Value,
                  status: pm10Status,
                  level: pm10Level,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AirQualityMetric(
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
  final String windLabel;
  final String uvLabel;
  final _DailyWeatherForecast? tomorrowForecast;
  final String tomorrowFallback;
  final String Function(double?, double?) formatRange;
  final String Function(double?) formatMillimeter;
  final String Function(double?) formatWind;
  final String Function(double?) formatUv;
  final IconData Function(int?) iconForCode;

  const _TomorrowWeatherCard({
    required this.title,
    required this.conditionLabel,
    required this.highLowLabel,
    required this.precipitationLabel,
    required this.windLabel,
    required this.uvLabel,
    required this.tomorrowForecast,
    required this.tomorrowFallback,
    required this.formatRange,
    required this.formatMillimeter,
    required this.formatWind,
    required this.formatUv,
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
                    const SizedBox(height: 8),
                    _CompactForecastInfoRow(
                      label: uvLabel,
                      value: formatUv(forecast.uvIndexMax),
                      icon: Icons.wb_sunny_outlined,
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _WeeklyForecastCard extends StatelessWidget {
  final String title;
  final String dateLabel;
  final String highLowLabel;
  final String precipitationLabel;
  final String windLabel;
  final List<_DailyWeatherForecast> forecasts;
  final String Function(double?, double?) formatRange;
  final String Function(double?) formatMillimeter;
  final String Function(double?) formatWind;
  final IconData Function(int?) iconForCode;

  const _WeeklyForecastCard({
    required this.title,
    required this.dateLabel,
    required this.highLowLabel,
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
              dateLabel: dateLabel,
              highLowLabel: highLowLabel,
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
  final String dateLabel;
  final String highLowLabel;
  final String precipitationLabel;
  final String windLabel;
  final _DailyWeatherForecast forecast;
  final String range;
  final String precipitation;
  final String wind;
  final IconData icon;

  const _WeeklyForecastRow({
    required this.dateLabel,
    required this.highLowLabel,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${forecast.weekdayLabel} · ${forecast.label} · ${forecast.summary}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Padding(
            padding: const EdgeInsets.only(left: 46),
            child: Text(
              '$highLowLabel $range',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.only(left: 46),
            child: Row(
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
          ),
        ],
      ),
    );
  }
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

class _StatusBadge extends StatelessWidget {
  final String label;
  final _AirQualityLevel level;

  const _StatusBadge({required this.label, required this.level});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _airQualityPalette(theme, level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.border),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: palette.foreground,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _AirQualityMetric extends StatelessWidget {
  final String label;
  final String value;
  final String status;
  final _AirQualityLevel level;

  const _AirQualityMetric({
    required this.label,
    required this.value,
    required this.status,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _airQualityPalette(theme, level);
    return SizedBox(
      height: 124,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: palette.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.border),
        ),
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
              ),
            ),
            const Spacer(),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: palette.foreground,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              status,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: palette.foreground,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
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
  final double? windSpeed;
  final double? temperatureMax;
  final double? temperatureMin;
  final double? pm10;
  final double? pm25;
  final int? aqi;
  final List<_DailyWeatherForecast> dailyForecasts;

  const _WeatherDetailsSnapshot({
    required this.summary,
    this.weatherCode,
    this.apparentTemperature,
    this.humidity,
    this.windSpeed,
    this.temperatureMax,
    this.temperatureMin,
    this.pm10,
    this.pm25,
    this.aqi,
    this.dailyForecasts = const <_DailyWeatherForecast>[],
  });
}

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
