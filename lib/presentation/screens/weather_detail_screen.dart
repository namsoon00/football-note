import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../widgets/app_background.dart';

class WeatherDetailScreen extends StatefulWidget {
  final String initialLocation;
  final String initialSummary;
  final int? initialWeatherCode;

  const WeatherDetailScreen({
    super.key,
    this.initialLocation = '',
    this.initialSummary = '',
    this.initialWeatherCode,
  });

  @override
  State<WeatherDetailScreen> createState() => _WeatherDetailScreenState();
}

class _WeatherDetailScreenState extends State<WeatherDetailScreen> {
  static const Duration _cacheTtl = Duration(minutes: 10);
  static _CachedWeatherDetails? _cachedDetails;

  bool _loading = false;
  String _location = '';
  String _summary = '';
  int? _weatherCode;
  double? _apparentTemperature;
  double? _humidity;
  double? _precipitation;
  double? _windSpeed;
  double? _uvIndexMax;
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
      unawaited(_loadWeather(requestPermission: false));
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasWeather = _summary.isNotEmpty;
    final airLevel = _aqiLevel(l10n, _aqi);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.homeWeatherDetailsTitle)),
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _CompactWeatherHeaderCard(
                title: hasWeather ? _summary : l10n.homeWeatherUnavailable,
                subtitle: _location.isEmpty
                    ? l10n.homeWeatherLocationUnknown
                    : _location,
                helper: l10n.homeWeatherCacheHint,
                icon: _weatherIcon(_weatherCode),
                loading: _loading,
                buttonLabel:
                    _loading ? l10n.homeWeatherLoading : l10n.homeWeatherLoad,
                onRefresh: _loading
                    ? null
                    : () => _loadWeather(requestPermission: true),
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
                _AirQualityCard(
                  title: l10n.homeWeatherAirQualityTitle,
                  status: '${l10n.homeWeatherAqi} · ${airLevel.label}',
                  aqiLabel: l10n.homeWeatherAqi,
                  aqiValue: _aqi == null ? '--' : '$_aqi',
                  aqiStatus: airLevel.label,
                  aqiLevel: airLevel.level,
                  pm10Label: l10n.homeWeatherPm10,
                  pm10Value: _formatParticles(_pm10),
                  pm10Status: _pm10Level(l10n, _pm10).label,
                  pm10Level: _pm10Level(l10n, _pm10).level,
                  pm25Label: l10n.homeWeatherPm25,
                  pm25Value: _formatParticles(_pm25),
                  pm25Status: _pm25Level(l10n, _pm25).label,
                  pm25Level: _pm25Level(l10n, _pm25).level,
                ),
                const SizedBox(height: 16),
                _ForecastOverviewCard(
                  tomorrowTitle: l10n.homeWeatherTomorrowTitle,
                  title: l10n.homeWeatherWeeklyTitle,
                  highLowLabel: l10n.homeWeatherDailyHighLow,
                  precipitationLabel: l10n.homeWeatherPrecipitation,
                  windLabel: l10n.homeWeatherWindSpeed,
                  uvLabel: l10n.homeWeatherUvIndex,
                  currentPrecipitation: _formatMillimeter(_precipitation),
                  currentUv: _formatUv(_uvIndexMax),
                  tomorrowForecast:
                      _dailyForecasts.length > 1 ? _dailyForecasts[1] : null,
                  tomorrowFallback: l10n.homeWeatherTomorrowFallback,
                  forecasts: _dailyForecasts,
                  formatRange: _formatRange,
                  formatMillimeter: _formatMillimeter,
                  formatWind: _formatWind,
                  iconForCode: _weatherIcon,
                ),
                const SizedBox(height: 16),
                _TrainingGuideCard(
                  title: l10n.homeWeatherSuggestionTitle,
                  suggestion: _buildTrainingSuggestion(l10n),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadWeather({required bool requestPermission}) async {
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
      return;
    }
    setState(() => _loading = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && requestPermission) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (requestPermission && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.homeWeatherPermissionNeeded)),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
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
      _cachedDetails = _CachedWeatherDetails(
        location: place,
        snapshot: snapshot,
        localeTag: localeTag,
        fetchedAt: DateTime.now(),
      );
    } catch (_) {
      if (requestPermission && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.homeWeatherLoadFailed)));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<String> _resolvePlaceName({
    required double latitude,
    required double longitude,
    required bool isKo,
    required String koreaLabel,
  }) async {
    final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/reverse', {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'count': '1',
      'language': isKo ? 'ko' : 'en',
    });
    final response = await http.get(uri);
    if (response.statusCode != 200) return '';
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return '';
    final results = decoded['results'];
    if (results is! List || results.isEmpty) return '';
    final first = results.first;
    if (first is! Map<String, dynamic>) return '';
    final city = (first['city'] ?? first['name'] ?? '').toString().trim();
    final region = (first['admin1'] ?? '').toString().trim();
    final country = (first['country'] ?? '').toString().trim();
    if (_isKoreaCountry(country)) {
      if (city.isNotEmpty) return '$city, $koreaLabel';
      if (region.isNotEmpty) return '$region, $koreaLabel';
      return koreaLabel;
    }
    final parts = <String>[
      if (city.isNotEmpty) city,
      if (region.isNotEmpty && region != city) region,
      if (country.isNotEmpty) country,
    ];
    return parts.take(2).join(', ');
  }

  Future<_WeatherDetailsSnapshot> _fetchWeatherSnapshot({
    required double latitude,
    required double longitude,
    required AppLocalizations l10n,
  }) async {
    final weatherUri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'current':
          'temperature_2m,apparent_temperature,relative_humidity_2m,precipitation,weather_code,wind_speed_10m',
      'daily':
          'weather_code,uv_index_max,temperature_2m_max,temperature_2m_min,precipitation_sum,wind_speed_10m_max',
      'forecast_days': '7',
      'timezone': 'auto',
    });
    final airQualityUri =
        Uri.https('air-quality-api.open-meteo.com', '/v1/air-quality', {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'current': 'pm10,pm2_5,us_aqi',
      'timezone': 'auto',
    });
    final responses = await Future.wait([
      http.get(weatherUri),
      http.get(airQualityUri),
    ]);
    if (responses[0].statusCode != 200 || responses[1].statusCode != 200) {
      return const _WeatherDetailsSnapshot(summary: '');
    }
    final weatherDecoded = jsonDecode(responses[0].body);
    final airDecoded = jsonDecode(responses[1].body);
    if (weatherDecoded is! Map<String, dynamic> ||
        airDecoded is! Map<String, dynamic>) {
      return const _WeatherDetailsSnapshot(summary: '');
    }

    final current = weatherDecoded['current'];
    final daily = weatherDecoded['daily'];
    final airCurrent = airDecoded['current'];
    if (current is! Map<String, dynamic> ||
        daily is! Map<String, dynamic> ||
        airCurrent is! Map<String, dynamic>) {
      return const _WeatherDetailsSnapshot(summary: '');
    }

    final temperature = (current['temperature_2m'] as num?)?.toDouble();
    final weatherCode = (current['weather_code'] as num?)?.toInt();
    final weatherText = _weatherLabelFromCode(weatherCode, l10n);
    final summary = temperature == null
        ? weatherText
        : '$weatherText ${temperature.toStringAsFixed(1)}°C';
    final dailyMax = _firstDailyNumber(daily['temperature_2m_max']);
    final dailyMin = _firstDailyNumber(daily['temperature_2m_min']);
    final uvIndexMax = _firstDailyNumber(daily['uv_index_max']);
    final forecasts = _buildDailyForecasts(daily, l10n);

    return _WeatherDetailsSnapshot(
      summary: summary,
      weatherCode: weatherCode,
      apparentTemperature:
          (current['apparent_temperature'] as num?)?.toDouble(),
      humidity: (current['relative_humidity_2m'] as num?)?.toDouble(),
      precipitation: (current['precipitation'] as num?)?.toDouble(),
      windSpeed: (current['wind_speed_10m'] as num?)?.toDouble(),
      uvIndexMax: uvIndexMax,
      temperatureMax: dailyMax,
      temperatureMin: dailyMin,
      pm10: (airCurrent['pm10'] as num?)?.toDouble(),
      pm25: (airCurrent['pm2_5'] as num?)?.toDouble(),
      aqi: (airCurrent['us_aqi'] as num?)?.toInt(),
      dailyForecasts: forecasts,
    );
  }

  void _applySnapshot(String location, _WeatherDetailsSnapshot snapshot) {
    _location = location;
    _summary = snapshot.summary;
    _weatherCode = snapshot.weatherCode;
    _apparentTemperature = snapshot.apparentTemperature;
    _humidity = snapshot.humidity;
    _precipitation = snapshot.precipitation;
    _windSpeed = snapshot.windSpeed;
    _uvIndexMax = snapshot.uvIndexMax;
    _temperatureMax = snapshot.temperatureMax;
    _temperatureMin = snapshot.temperatureMin;
    _pm10 = snapshot.pm10;
    _pm25 = snapshot.pm25;
    _aqi = snapshot.aqi;
    _dailyForecasts = snapshot.dailyForecasts;
  }

  String _weatherLabelFromCode(int? code, AppLocalizations l10n) {
    switch (code) {
      case 0:
        return l10n.weatherLabelClear;
      case 1:
      case 2:
      case 3:
        return l10n.weatherLabelCloudy;
      case 45:
      case 48:
        return l10n.weatherLabelFog;
      case 51:
      case 53:
      case 55:
      case 56:
      case 57:
        return l10n.weatherLabelDrizzle;
      case 61:
      case 63:
      case 65:
      case 66:
      case 67:
      case 80:
      case 81:
      case 82:
        return l10n.weatherLabelRain;
      case 71:
      case 73:
      case 75:
      case 77:
      case 85:
      case 86:
        return l10n.weatherLabelSnow;
      case 95:
      case 96:
      case 99:
        return l10n.weatherLabelThunderstorm;
      default:
        return l10n.weatherLabelDefault;
    }
  }

  double? _firstDailyNumber(Object? value) {
    if (value is List && value.isNotEmpty) {
      return (value.first as num?)?.toDouble();
    }
    return null;
  }

  List<_DailyWeatherForecast> _buildDailyForecasts(
    Map<String, dynamic> daily,
    AppLocalizations l10n,
  ) {
    final times = daily['time'];
    final codes = daily['weather_code'];
    final maxTemps = daily['temperature_2m_max'];
    final minTemps = daily['temperature_2m_min'];
    final precipitationSums = daily['precipitation_sum'];
    final maxWinds = daily['wind_speed_10m_max'];
    if (times is! List) return const <_DailyWeatherForecast>[];

    final forecasts = <_DailyWeatherForecast>[];
    for (var index = 0; index < times.length; index++) {
      final rawDate = times[index]?.toString();
      final date = rawDate == null ? null : DateTime.tryParse(rawDate);
      if (date == null) continue;
      final weatherCode = _numberAt(codes, index)?.toInt();
      forecasts.add(
        _DailyWeatherForecast(
          date: date,
          label: _formatForecastDay(date, l10n),
          weatherCode: weatherCode,
          summary: _weatherLabelFromCode(weatherCode, l10n),
          temperatureMax: _numberAt(maxTemps, index)?.toDouble(),
          temperatureMin: _numberAt(minTemps, index)?.toDouble(),
          precipitationSum: _numberAt(precipitationSums, index)?.toDouble(),
          windSpeedMax: _numberAt(maxWinds, index)?.toDouble(),
        ),
      );
    }
    return forecasts;
  }

  num? _numberAt(Object? values, int index) {
    if (values is! List || index >= values.length) return null;
    return values[index] as num?;
  }

  String _formatForecastDay(DateTime date, AppLocalizations l10n) {
    final today = DateTime.now();
    final localDate = DateTime(date.year, date.month, date.day);
    final localToday = DateTime(today.year, today.month, today.day);
    final diff = localDate.difference(localToday).inDays;
    if (diff == 0) {
      return MaterialLocalizations.of(context).formatShortDate(localDate);
    }
    return DateFormat.MMMd(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(localDate);
  }

  bool _isKoreaCountry(String country) {
    final normalized = country.trim().toLowerCase();
    return normalized == 'south korea' ||
        normalized == 'korea' ||
        normalized == 'republic of korea' ||
        country == '대한민국' ||
        country == '한국';
  }

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

  String _buildTrainingSuggestion(AppLocalizations l10n) {
    final suggestions = <String>[_baseTrainingSuggestion(l10n)];
    final apparentTemperature = _apparentTemperature;
    if (apparentTemperature != null) {
      if (apparentTemperature >= 30) {
        suggestions.add(l10n.homeWeatherSuggestionHot);
      } else if (apparentTemperature <= 5) {
        suggestions.add(l10n.homeWeatherSuggestionCold);
      }
    }

    final airLevel = _worstAirQualityLevel();
    if (airLevel.index >= _AirQualityLevel.sensitive.index) {
      suggestions.add(l10n.homeWeatherSuggestionAirCaution);
    } else if (airLevel == _AirQualityLevel.moderate) {
      suggestions.add(l10n.homeWeatherSuggestionAirWatch);
    }

    return suggestions.join(' ');
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

class _CompactWeatherHeaderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String helper;
  final IconData icon;
  final bool loading;
  final String buttonLabel;
  final VoidCallback? onRefresh;
  final List<_CompactMetricData> metrics;

  const _CompactWeatherHeaderCard({
    required this.title,
    required this.subtitle,
    required this.helper,
    required this.icon,
    required this.loading,
    required this.buttonLabel,
    required this.onRefresh,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withValues(alpha: 0.95),
            theme.colorScheme.secondaryContainer.withValues(alpha: 0.82),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.42),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, size: 30, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  helper,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: onRefresh,
                icon: loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2.0),
                      )
                    : const Icon(Icons.my_location_rounded),
                label: Text(buttonLabel),
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
  final String status;
  final String aqiLabel;
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

  const _AirQualityCard({
    required this.title,
    required this.status,
    required this.aqiLabel,
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
            status,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
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

class _TrainingGuideCard extends StatelessWidget {
  final String title;
  final String suggestion;

  const _TrainingGuideCard({required this.title, required this.suggestion});

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
          const SizedBox(height: 10),
          Text(
            suggestion,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ForecastOverviewCard extends StatelessWidget {
  final String tomorrowTitle;
  final String title;
  final String highLowLabel;
  final String precipitationLabel;
  final String windLabel;
  final String uvLabel;
  final String currentPrecipitation;
  final String currentUv;
  final _DailyWeatherForecast? tomorrowForecast;
  final String tomorrowFallback;
  final List<_DailyWeatherForecast> forecasts;
  final String Function(double?, double?) formatRange;
  final String Function(double?) formatMillimeter;
  final String Function(double?) formatWind;
  final IconData Function(int?) iconForCode;

  const _ForecastOverviewCard({
    required this.tomorrowTitle,
    required this.title,
    required this.highLowLabel,
    required this.precipitationLabel,
    required this.windLabel,
    required this.uvLabel,
    required this.currentPrecipitation,
    required this.currentUv,
    required this.tomorrowForecast,
    required this.tomorrowFallback,
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
          Text(
            tomorrowTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          _TomorrowWeatherCard(
            title: tomorrowTitle,
            highLowLabel: highLowLabel,
            precipitationLabel: precipitationLabel,
            windLabel: windLabel,
            forecast: tomorrowForecast,
            fallback: tomorrowFallback,
            formatRange: formatRange,
            formatMillimeter: formatMillimeter,
            formatWind: formatWind,
            iconForCode: iconForCode,
            embedded: true,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InlineMetricChip(
                label: precipitationLabel,
                value: currentPrecipitation,
              ),
              _InlineMetricChip(label: uvLabel, value: currentUv),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          for (final forecast in forecasts) ...[
            _WeeklyForecastRow(
              forecast: forecast,
              range: formatRange(
                forecast.temperatureMax,
                forecast.temperatureMin,
              ),
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

class _TomorrowWeatherCard extends StatelessWidget {
  final String title;
  final String highLowLabel;
  final String precipitationLabel;
  final String windLabel;
  final _DailyWeatherForecast? forecast;
  final String fallback;
  final String Function(double?, double?) formatRange;
  final String Function(double?) formatMillimeter;
  final String Function(double?) formatWind;
  final IconData Function(int?) iconForCode;
  final bool embedded;

  const _TomorrowWeatherCard({
    required this.title,
    required this.highLowLabel,
    required this.precipitationLabel,
    required this.windLabel,
    required this.forecast,
    required this.fallback,
    required this.formatRange,
    required this.formatMillimeter,
    required this.formatWind,
    required this.iconForCode,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final forecast = this.forecast;
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!embedded) ...[
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (forecast == null)
          Text(
            fallback,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  iconForCode(forecast.weatherCode),
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      forecast.label,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      forecast.summary,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _InlineMetricChip(
                          label: highLowLabel,
                          value: formatRange(
                            forecast.temperatureMax,
                            forecast.temperatureMin,
                          ),
                        ),
                        _InlineMetricChip(
                          label: precipitationLabel,
                          value: formatMillimeter(forecast.precipitationSum),
                        ),
                        _InlineMetricChip(
                          label: windLabel,
                          value: formatWind(forecast.windSpeedMax),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
    if (embedded) return body;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: body,
    );
  }
}

class _WeeklyForecastRow extends StatelessWidget {
  final _DailyWeatherForecast forecast;
  final String range;
  final IconData icon;

  const _WeeklyForecastRow({
    required this.forecast,
    required this.range,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox(
          width: 66,
          child: Text(
            forecast.label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            forecast.summary,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          range,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _InlineMetricChip extends StatelessWidget {
  final String label;
  final String value;

  const _InlineMetricChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
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
  final double? uvIndexMax;
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
    this.precipitation,
    this.windSpeed,
    this.uvIndexMax,
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
  final int? weatherCode;
  final String summary;
  final double? temperatureMax;
  final double? temperatureMin;
  final double? precipitationSum;
  final double? windSpeedMax;

  const _DailyWeatherForecast({
    required this.date,
    required this.label,
    required this.weatherCode,
    required this.summary,
    this.temperatureMax,
    this.temperatureMin,
    this.precipitationSum,
    this.windSpeedMax,
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
