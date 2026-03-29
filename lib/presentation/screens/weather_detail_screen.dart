import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

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
    final theme = Theme.of(context);
    final hasWeather = _summary.isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.homeWeatherDetailsTitle)),
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Text(
                l10n.homeWeatherDetailsSubtitle,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loading
                    ? null
                    : () => _loadWeather(requestPermission: true),
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      )
                    : const Icon(Icons.my_location_rounded),
                label: Text(
                  _loading ? l10n.homeWeatherLoading : l10n.homeWeatherLoad,
                ),
              ),
              const SizedBox(height: 16),
              _HeroWeatherCard(
                title: hasWeather ? _summary : l10n.homeWeatherUnavailable,
                subtitle: _location.isEmpty
                    ? l10n.homeWeatherLocationUnknown
                    : _location,
                icon: _weatherIcon(_weatherCode),
              ),
              if (hasWeather) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _MetricCard(
                      label: l10n.homeWeatherTemperatureRange,
                      value: _formatRange(_temperatureMax, _temperatureMin),
                      icon: Icons.device_thermostat_outlined,
                    ),
                    _MetricCard(
                      label: l10n.homeWeatherFeelsLike,
                      value: _formatTemperature(_apparentTemperature),
                      icon: Icons.thermostat_auto_outlined,
                    ),
                    _MetricCard(
                      label: l10n.homeWeatherHumidity,
                      value: _formatPercent(_humidity),
                      icon: Icons.water_drop_outlined,
                    ),
                    _MetricCard(
                      label: l10n.homeWeatherPrecipitation,
                      value: _formatMillimeter(_precipitation),
                      icon: Icons.grain_outlined,
                    ),
                    _MetricCard(
                      label: l10n.homeWeatherWindSpeed,
                      value: _formatWind(_windSpeed),
                      icon: Icons.air_rounded,
                    ),
                    _MetricCard(
                      label: l10n.homeWeatherUvIndex,
                      value: _formatUv(_uvIndexMax),
                      icon: Icons.wb_sunny_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _AirQualityCard(
                  title: l10n.homeWeatherAirQualityTitle,
                  status: '${l10n.homeWeatherAqi} · ${_aqiLevel(l10n, _aqi).label}',
                  aqiLabel: l10n.homeWeatherAqi,
                  aqiValue: _aqi == null ? '--' : '$_aqi',
                  aqiStatus: _aqiLevel(l10n, _aqi).label,
                  aqiLevel: _aqiLevel(l10n, _aqi).level,
                  pm10Label: l10n.homeWeatherPm10,
                  pm10Value: _formatParticles(_pm10),
                  pm10Status: _pm10Level(l10n, _pm10).label,
                  pm10Level: _pm10Level(l10n, _pm10).level,
                  pm25Label: l10n.homeWeatherPm25,
                  pm25Value: _formatParticles(_pm25),
                  pm25Status: _pm25Level(l10n, _pm25).label,
                  pm25Level: _pm25Level(l10n, _pm25).level,
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
      );
      final snapshot = await _fetchWeatherSnapshot(
        latitude: position.latitude,
        longitude: position.longitude,
        l10n: l10n,
      );
      if (!mounted) return;
      setState(() {
        _location = place;
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
      });
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
      'daily': 'uv_index_max,temperature_2m_max,temperature_2m_min',
      'forecast_days': '1',
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
    );
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

class _HeroWeatherCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _HeroWeatherCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withValues(alpha: 0.92),
            theme.colorScheme.secondaryContainer.withValues(alpha: 0.84),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.42),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, size: 28, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 14),
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
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
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
      width: 164,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(height: 10),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
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
    return Container(
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
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: palette.foreground,
              ),
          ),
          const SizedBox(height: 4),
          Text(
            status,
            style: theme.textTheme.labelSmall?.copyWith(
              color: palette.foreground,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
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
  });
}
