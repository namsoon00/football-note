import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:football_note/gen/app_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../../application/korean_air_quality_service.dart';
import '../../application/weather_location_service.dart';
import '../../application/weather_shared_resource.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bar_action_button.dart';
import '../widgets/app_background.dart';
import '../widgets/app_skeleton.dart';

enum WeatherDetailInitialAction {
  none,
  outfitGuide,
  tomorrowForecast,
  weeklyForecast
}

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

  @override
  State<WeatherDetailScreen> createState() => _WeatherDetailScreenState();
}

class _WeatherDetailScreenState extends State<WeatherDetailScreen> {
  bool _loading = false;
  bool _handledInitialAction = false;
  String _location = '';
  String _summary = '';
  int? _weatherCode;
  double? _temperature;
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
  AirQualityScale _airQualityScale = AirQualityScale.usAqi;
  List<_DailyWeatherForecast> _dailyForecasts = const <_DailyWeatherForecast>[];

  @override
  void initState() {
    super.initState();
    _location = widget.initialLocation.trim();
    _summary = widget.initialSummary.trim();
    _weatherCode = widget.initialWeatherCode;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cachedSnapshot = WeatherSharedResource.cachedSnapshot(
        locale: Localizations.localeOf(context),
      );
      if (cachedSnapshot != null) {
        setState(() {
          _applySnapshot(cachedSnapshot);
        });
      }
      _maybeHandleInitialAction();
      final shouldRequestPermission =
          widget.initialAction != WeatherDetailInitialAction.none &&
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
    final detailedOutfitGuide = _buildDetailedOutfitGuide(l10n);
    final tomorrowForecast =
        _dailyForecasts.length > 1 ? _dailyForecasts[1] : null;
    final weeklyForecasts = _dailyForecasts.take(7).toList(growable: false);
    final todayInsightPanel =
        hasWeather ? _buildTodayHourlyWeatherFooter(l10n) : null;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeWeatherDetailsTitle),
        actions: hasWeather
            ? [
                _WeatherHeaderActionButton(
                  label: l10n.homeWeatherOutfitActionLabel,
                  tooltip: l10n.homeWeatherOutfitTitle,
                  icon: const Icon(Icons.checkroom_outlined),
                  onPressed: () => _openOutfitGuideScreen(
                    l10n: l10n,
                    guide: detailedOutfitGuide,
                  ),
                ),
                _WeatherHeaderActionButton(
                  label: l10n.homeWeatherTomorrowActionLabel,
                  tooltip: l10n.homeWeatherTomorrowTitle,
                  icon: Icon(_weatherIcon(tomorrowForecast?.weatherCode)),
                  onPressed: () => _openWeatherForecastScreen(
                    title: l10n.homeWeatherTomorrowTitle,
                    child: _buildTomorrowWeatherCard(
                      l10n: l10n,
                      isKo: isKo,
                      tomorrowForecast: tomorrowForecast,
                    ),
                  ),
                ),
                _WeatherHeaderActionButton(
                  label: l10n.homeWeatherWeeklyActionLabel,
                  tooltip: l10n.homeWeatherWeeklyTitle,
                  icon: const Icon(Icons.calendar_month_rounded),
                  onPressed: () => _openWeatherForecastScreen(
                    title: l10n.homeWeatherWeeklyTitle,
                    child: _buildWeeklyForecastCard(
                      l10n: l10n,
                      weeklyForecasts: weeklyForecasts,
                    ),
                  ),
                ),
              ]
            : null,
      ),
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xl,
            ),
            children: [
              _CompactWeatherHeaderCard(
                title: hasWeather ? _summary : l10n.homeWeatherTitle,
                sectionLabel: l10n.homeWeatherTodayTitle,
                subtitle: _headerLocationLabel(l10n),
                helper: null,
                icon: _weatherIcon(_weatherCode),
                loading: _loading,
                onRefresh: _loading
                    ? null
                    : () => _loadWeather(
                          requestPermission: true,
                          showFailureFeedback: true,
                          forceRefresh: true,
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
                          role: _CompactMetricRole.temperatureRange,
                        ),
                        _CompactMetricData(
                          label: l10n.homeWeatherFeelsLike,
                          value: _formatTemperature(_apparentTemperature),
                          icon: Icons.thermostat_auto_outlined,
                          role: _CompactMetricRole.feelsLike,
                        ),
                        _CompactMetricData(
                          label: l10n.homeWeatherComparedYesterday,
                          value: _formatTemperatureDelta(
                            _temperatureDeltaFromYesterday,
                          ),
                          icon: Icons.compare_arrows_rounded,
                          role: _CompactMetricRole.comparedYesterday,
                        ),
                        _CompactMetricData(
                          label: l10n.homeWeatherHumidity,
                          value: _formatPercent(_humidity),
                          icon: Icons.water_drop_outlined,
                          role: _CompactMetricRole.humidity,
                        ),
                        _CompactMetricData(
                          label: l10n.homeWeatherPrecipitation,
                          value: _formatMillimeter(_todayPrecipitation),
                          icon: Icons.umbrella_outlined,
                          role: _CompactMetricRole.precipitation,
                        ),
                        _CompactMetricData(
                          label: l10n.homeWeatherPrecipitationProbability,
                          value: _formatProbability(
                            _todayPrecipitationProbabilityMax,
                          ),
                          icon: Icons.water_drop_rounded,
                          role: _CompactMetricRole.precipitationProbability,
                        ),
                        _CompactMetricData(
                          label: l10n.homeWeatherWindSpeed,
                          value: _formatWind(_windSpeed),
                          icon: Icons.air_rounded,
                          role: _CompactMetricRole.wind,
                        ),
                        _CompactMetricData(
                          label: l10n.homeWeatherPm10,
                          value:
                              '${_formatAirMetricValue(_pm10)} ${pm10Level.label}',
                          icon: Icons.blur_on_rounded,
                          airLevel: pm10Level.level,
                          role: _CompactMetricRole.airQuality,
                        ),
                        _CompactMetricData(
                          label: l10n.homeWeatherPm25,
                          value:
                              '${_formatAirMetricValue(_pm25)} ${pm25Level.label}',
                          icon: Icons.blur_circular_rounded,
                          airLevel: pm25Level.level,
                          role: _CompactMetricRole.airQuality,
                        ),
                      ]
                    : const <_CompactMetricData>[],
              ),
              if (todayInsightPanel != null) ...[
                const SizedBox(height: AppSpacing.sm),
                todayInsightPanel,
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _openWeatherForecastScreen({
    required String title,
    required Widget child,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _WeatherForecastSubscreen(
          title: title,
          child: child,
        ),
      ),
    );
  }

  Widget _buildTomorrowWeatherCard({
    required AppLocalizations l10n,
    required bool isKo,
    required _DailyWeatherForecast? tomorrowForecast,
  }) {
    return _TomorrowWeatherCard(
      title: l10n.homeWeatherTomorrowTitle,
      highLowLabel: l10n.homeWeatherDailyHighLow,
      precipitationLabel: l10n.homeWeatherPrecipitation,
      precipitationProbabilityLabel: l10n.homeWeatherPrecipitationProbability,
      hourlyPrecipitationLabel: l10n.homeWeatherHourlyPrecipitation,
      hourlyOverviewLabel: l10n.homeWeatherHourlyOverview,
      windLabel: l10n.homeWeatherWindSpeed,
      fineDustLabel: l10n.homeWeatherPm10,
      ultraFineDustLabel: l10n.homeWeatherPm25,
      outfitTitle: l10n.homeWeatherTomorrowOutfitTitle,
      outfitFallback: l10n.homeWeatherTomorrowOutfitFallback,
      outfitPreviews: tomorrowForecast == null
          ? const <_OutfitMomentPreviewData>[]
          : _buildForecastOutfitPreviews(
              forecast: tomorrowForecast,
              l10n: l10n,
            ),
      tomorrowForecast: tomorrowForecast,
      tomorrowFallback: l10n.homeWeatherTomorrowFallback,
      formatRange: _formatRange,
      formatTemperature: _formatTemperature,
      formatMillimeter: _formatMillimeter,
      formatProbability: _formatProbability,
      formatPrecipitationEntry: _formatPrecipitationTimelineLabel,
      formatWind: _formatWind,
      formatTime: _formatHourlyTime,
      formatFineDust: _formatAirMetricValue,
      pm10LevelForValue: (value) => _pm10Level(l10n, value),
      pm25LevelForValue: (value) => _pm25Level(l10n, value),
      iconForCode: _weatherIcon,
    );
  }

  Widget _buildWeeklyForecastCard({
    required AppLocalizations l10n,
    required List<_DailyWeatherForecast> weeklyForecasts,
  }) {
    return _WeeklyForecastCard(
      title: l10n.homeWeatherWeeklyTitle,
      precipitationLabel: l10n.homeWeatherPrecipitation,
      windLabel: l10n.homeWeatherWindSpeed,
      fineDustLabel: l10n.homeWeatherPm10,
      ultraFineDustLabel: l10n.homeWeatherPm25,
      airQualityMissingReason: l10n.homeWeatherAirQualityForecastMissingReason,
      fallback: l10n.homeWeatherWeeklyFallback,
      forecasts: weeklyForecasts,
      formatRange: _formatRange,
      formatMillimeter: _formatMillimeter,
      formatWind: _formatWind,
      formatFineDust: _formatAirMetricValue,
      pm10LevelForValue: (value) => _pm10Level(l10n, value).level,
      pm25LevelForValue: (value) => _pm25Level(l10n, value).level,
      iconForCode: _weatherIcon,
    );
  }

  Future<void> _loadWeather({
    required bool requestPermission,
    required bool showFailureFeedback,
    bool forceRefresh = false,
  }) async {
    if (_loading || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final isKo = Localizations.localeOf(context).languageCode == 'ko';
    final locale = Localizations.localeOf(context);
    final cachedSnapshot = forceRefresh
        ? null
        : WeatherSharedResource.cachedSnapshot(locale: locale);
    if (cachedSnapshot != null) {
      setState(() {
        _applySnapshot(cachedSnapshot);
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
          timeLimit: Duration(seconds: 8),
        ),
      );
      final placeFuture = _resolvePlaceName(
        latitude: position.latitude,
        longitude: position.longitude,
        isKo: isKo,
        koreaLabel: l10n.homeWeatherCountryKorea,
      ).timeout(const Duration(seconds: 5)).catchError((_) => '');
      final weatherFuture = _fetchWeatherSnapshot(
        latitude: position.latitude,
        longitude: position.longitude,
        location: '',
        l10n: l10n,
        locale: locale,
      )
          .then<WeatherSharedSnapshot?>((snapshot) => snapshot)
          .catchError((_) => null);
      final results = await Future.wait<Object?>([placeFuture, weatherFuture]);
      final place = results[0] as String;
      if (!mounted) return;
      setState(() {
        _location = place;
      });

      if (!mounted) return;
      final snapshot = (results[1] as WeatherSharedSnapshot?)?.copyWith(
        location: place,
      );
      if (snapshot != null && snapshot.hasData) {
        WeatherSharedResource.primeSnapshot(snapshot);
      }
      if (snapshot != null && snapshot.hasData) {
        setState(() {
          _applySnapshot(snapshot);
        });
        _maybeHandleInitialAction();
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

  Future<WeatherSharedSnapshot> _fetchWeatherSnapshot({
    required double latitude,
    required double longitude,
    required String location,
    required AppLocalizations l10n,
    required Locale locale,
  }) =>
      location.trim().isEmpty
          ? WeatherSharedResource.fetchForCoordinates(
              latitude: latitude,
              longitude: longitude,
              l10n: l10n,
              locale: locale,
            )
          : WeatherSharedResource.fetchForLocation(
              latitude: latitude,
              longitude: longitude,
              location: location,
              l10n: l10n,
              locale: locale,
            );

  String _headerLocationLabel(AppLocalizations l10n) {
    if (_location.isNotEmpty) return _location;
    return l10n.homeWeatherLocationUnknown;
  }

  void _maybeHandleInitialAction() {
    if (_handledInitialAction ||
        widget.initialAction == WeatherDetailInitialAction.none ||
        !mounted ||
        (_summary.trim().isEmpty && _dailyForecasts.isEmpty)) {
      return;
    }
    _handledInitialAction = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      final isKo = Localizations.localeOf(context).languageCode == 'ko';
      switch (widget.initialAction) {
        case WeatherDetailInitialAction.outfitGuide:
          _openOutfitGuideScreen(
            l10n: l10n,
            guide: _buildDetailedOutfitGuide(l10n),
          );
          break;
        case WeatherDetailInitialAction.tomorrowForecast:
          final tomorrowForecast =
              _dailyForecasts.length > 1 ? _dailyForecasts[1] : null;
          _openWeatherForecastScreen(
            title: l10n.homeWeatherTomorrowTitle,
            child: _buildTomorrowWeatherCard(
              l10n: l10n,
              isKo: isKo,
              tomorrowForecast: tomorrowForecast,
            ),
          );
          break;
        case WeatherDetailInitialAction.weeklyForecast:
          _openWeatherForecastScreen(
            title: l10n.homeWeatherWeeklyTitle,
            child: _buildWeeklyForecastCard(
              l10n: l10n,
              weeklyForecasts: _dailyForecasts.take(7).toList(growable: false),
            ),
          );
          break;
        case WeatherDetailInitialAction.none:
          break;
      }
    });
  }

  void _applySnapshot(WeatherSharedSnapshot snapshot) {
    _location = snapshot.location;
    _summary = snapshot.summary;
    _weatherCode = snapshot.weatherCode;
    _temperature = snapshot.temperature;
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
          (forecast) => _DailyWeatherForecast(
            date: forecast.date,
            label: _formatForecastDate(forecast.date),
            weekdayLabel: _formatForecastWeekday(forecast.date),
            weatherCode: forecast.weatherCode,
            summary: forecast.summary,
            temperatureMax: forecast.temperatureMax,
            temperatureMin: forecast.temperatureMin,
            precipitationSum: forecast.precipitationSum,
            precipitationProbabilityMax: forecast.precipitationProbabilityMax,
            windSpeedMax: forecast.windSpeedMax,
            pm10: forecast.pm10,
            pm25: forecast.pm25,
            uvIndexMax: forecast.uvIndexMax,
            morningForecast: forecast.morningForecast == null
                ? null
                : _ForecastMomentPreview(
                    time: forecast.morningForecast!.time,
                    temperature: forecast.morningForecast!.temperature,
                    weatherCode: forecast.morningForecast!.weatherCode,
                    precipitation: forecast.morningForecast!.precipitation,
                    precipitationProbability:
                        forecast.morningForecast!.precipitationProbability,
                    windSpeed: forecast.morningForecast!.windSpeed,
                  ),
            eveningForecast: forecast.eveningForecast == null
                ? null
                : _ForecastMomentPreview(
                    time: forecast.eveningForecast!.time,
                    temperature: forecast.eveningForecast!.temperature,
                    weatherCode: forecast.eveningForecast!.weatherCode,
                    precipitation: forecast.eveningForecast!.precipitation,
                    precipitationProbability:
                        forecast.eveningForecast!.precipitationProbability,
                    windSpeed: forecast.eveningForecast!.windSpeed,
                  ),
            hourlyForecasts: forecast.hourlyForecasts
                .map(
                  (entry) => _ForecastMomentPreview(
                    time: entry.time,
                    temperature: entry.temperature,
                    weatherCode: entry.weatherCode,
                    precipitation: entry.precipitation,
                    precipitationProbability: entry.precipitationProbability,
                    windSpeed: entry.windSpeed,
                  ),
                )
                .toList(growable: false),
            hourlyPrecipitations: forecast.hourlyPrecipitations
                .map(
                  (entry) => _HourlyPrecipitationEntry(
                    time: entry.time,
                    precipitation: entry.precipitation,
                    precipitationProbability: entry.precipitationProbability,
                  ),
                )
                .toList(growable: false),
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

  _AirLevelLabel _aqiLevel(
    AppLocalizations l10n,
    int? value,
    AirQualityScale scale,
  ) {
    if (value == null) {
      return const _AirLevelLabel('--', _AirQualityLevel.unknown);
    }
    if (scale == AirQualityScale.khai) {
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
      value == null ? '--' : '${value.round()}°C';

  String _formatCompactTemperature(double? value) {
    if (value == null) return '--';
    return '${value.round()}°';
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

  String _formatProbability(double? value) {
    if (value == null) return '--';
    return '${value.clamp(0, 100).round()}%';
  }

  String _formatMillimeter(double? value) {
    if (value == null) return '--';
    return '${value.toStringAsFixed(1)} · ${_precipitationAmountLabel(value)}';
  }

  String _formatPrecipitationTimelineLabel(_HourlyPrecipitationEntry entry) {
    final amount = entry.precipitation.toStringAsFixed(1);
    return '$amount\n${_precipitationAmountLabel(entry.precipitation)}';
  }

  String _precipitationAmountLabel(double value) {
    final l10n = AppLocalizations.of(context)!;
    return switch (_precipitationAmountLevel(value)) {
      _PrecipitationAmountLevel.none => l10n.weatherPrecipitationNone,
      _PrecipitationAmountLevel.trace => l10n.weatherPrecipitationTrace,
      _PrecipitationAmountLevel.light => l10n.weatherPrecipitationLight,
      _PrecipitationAmountLevel.moderate => l10n.weatherPrecipitationModerate,
      _PrecipitationAmountLevel.heavy => l10n.weatherPrecipitationHeavy,
      _PrecipitationAmountLevel.veryHeavy => l10n.weatherPrecipitationVeryHeavy,
    };
  }

  String _formatHourlyTime(DateTime value) => DateFormat('HH:mm').format(value);

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
    final normalized = value.abs() < 0.5 ? 0 : value;
    final rounded = normalized.round();
    if (rounded > 0) {
      return '↑ $rounded°C';
    }
    if (rounded < 0) {
      return '↓ ${rounded.abs()}°C';
    }
    return '0°C';
  }

  double? get _todayPrecipitation {
    if (_dailyForecasts.isNotEmpty) {
      return _dailyForecasts.first.precipitationSum ?? _precipitation;
    }
    return _precipitation;
  }

  double? get _todayPrecipitationProbabilityMax {
    if (_dailyForecasts.isEmpty) return null;
    return _dailyForecasts.first.precipitationProbabilityMax;
  }

  DateTime? get _todayHourlyFocusTime {
    if (_dailyForecasts.isEmpty) return null;
    return _hourlyFocusTimeForForecastDate(_dailyForecasts.first.date);
  }

  List<_DailyWeatherForecast> get _todayAndNextDayForecasts {
    if (_dailyForecasts.isEmpty) return const <_DailyWeatherForecast>[];
    final today = _dateOnly(_dailyForecasts.first.date);
    final nextDay = today.add(const Duration(days: 1));
    return _dailyForecasts.where((forecast) {
      final date = _dateOnly(forecast.date);
      return !date.isBefore(today) && !date.isAfter(nextDay);
    }).toList(growable: false);
  }

  List<_HourlyPrecipitationEntry> get _todayHourlyPrecipitations {
    if (_dailyForecasts.isEmpty) return const <_HourlyPrecipitationEntry>[];
    final entriesByHour = <DateTime, _HourlyPrecipitationEntry>{};
    for (final forecast in _todayAndNextDayForecasts) {
      for (final entry in forecast.hourlyPrecipitations) {
        entriesByHour[_hourBucket(entry.time)] = entry;
      }
    }
    return _visibleHourlyPrecipitationEntries(entriesByHour.values.toList());
  }

  List<_ForecastMomentPreview> get _todayHourlyForecasts {
    if (_dailyForecasts.isEmpty) return const <_ForecastMomentPreview>[];
    final forecastsByHour = <DateTime, _ForecastMomentPreview>{};
    for (final forecast in _todayAndNextDayForecasts) {
      for (final entry in forecast.hourlyForecasts) {
        if (entry.temperature != null) {
          forecastsByHour[_hourBucket(entry.time)] = entry;
        }
      }
    }
    return forecastsByHour.values.toList(growable: false)
      ..sort((left, right) => left.time.compareTo(right.time));
  }

  Widget? _buildTodayHourlyWeatherFooter(
    AppLocalizations l10n, {
    bool accentStyle = false,
  }) {
    final temperatureEntries = _todayHourlyForecasts;
    final precipitationEntries = _todayHourlyPrecipitations;
    if (temperatureEntries.isEmpty && precipitationEntries.isEmpty) {
      return null;
    }
    final overviewEntries = _hourlyWeatherOverviewEntries(
      forecasts: temperatureEntries,
      precipitations: precipitationEntries,
    );
    if (overviewEntries.isNotEmpty && temperatureEntries.isNotEmpty) {
      return _HourlyTemperatureSection(
        title: l10n.homeWeatherHourlyOverview,
        entries: overviewEntries,
        precipitationProbabilityLabel: l10n.homeWeatherPrecipitationProbability,
        precipitationLabel: l10n.homeWeatherPrecipitation,
        windLabel: l10n.homeWeatherWindSpeed,
        formatTime: _formatHourlyTime,
        formatTemperature: _formatTemperature,
        formatProbability: _formatProbability,
        formatPrecipitation: _formatPrecipitationTimelineLabel,
        formatWind: _formatWind,
        iconForCode: _weatherIcon,
        focusTime: _todayHourlyFocusTime,
        accentStyle: accentStyle,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (precipitationEntries.isNotEmpty)
          _HourlyPrecipitationSection(
            title: l10n.homeWeatherHourlyPrecipitation,
            entries: precipitationEntries,
            formatTime: _formatHourlyTime,
            formatPrecipitation: _formatPrecipitationTimelineLabel,
            focusTime: _todayHourlyFocusTime,
            accentStyle: accentStyle,
          ),
      ],
    );
  }

  double? get _currentOutfitTemperature =>
      _apparentTemperature ?? _temperature ?? _temperatureMax;

  _DetailedOutfitGuide _buildDetailedOutfitGuide(AppLocalizations l10n) =>
      _buildOutfitGuide(
        l10n: l10n,
        apparentTemperature: _currentOutfitTemperature,
        precipitationMm: _todayPrecipitation,
        windSpeed: _windSpeed ?? 0,
        weatherCode: _weatherCode,
        airLevel: _worstAirQualityLevel(),
      );

  List<_OutfitMomentPreviewData> _buildForecastOutfitPreviews({
    required _DailyWeatherForecast forecast,
    required AppLocalizations l10n,
  }) {
    final slots = <({
      String label,
      _ForecastMomentPreview? preview,
      double? fallbackTemperature,
    })>[
      (
        label: l10n.homeWeatherMorningLabel,
        preview: forecast.morningForecast,
        fallbackTemperature: forecast.temperatureMin ?? forecast.temperatureMax,
      ),
      (
        label: l10n.homeWeatherEveningLabel,
        preview: forecast.eveningForecast,
        fallbackTemperature: forecast.temperatureMax ?? forecast.temperatureMin,
      ),
    ];
    return slots
        .map((slot) {
          final preview = slot.preview;
          final temperature = preview?.temperature ?? slot.fallbackTemperature;
          final weatherCode = preview?.weatherCode ?? forecast.weatherCode;
          final precipitation =
              preview?.precipitation ?? forecast.precipitationSum;
          final windSpeed = preview?.windSpeed ?? forecast.windSpeedMax ?? 0;
          if (temperature == null &&
              weatherCode == null &&
              precipitation == null &&
              forecast.windSpeedMax == null) {
            return null;
          }
          final guide = _buildOutfitGuide(
            l10n: l10n,
            apparentTemperature: temperature,
            precipitationMm: precipitation,
            windSpeed: windSpeed,
            weatherCode: weatherCode,
            airLevel: _AirQualityLevel.good,
          );
          return _OutfitMomentPreviewData(
            label: slot.label,
            temperatureLabel: _formatTemperature(temperature),
            icon: _weatherIcon(weatherCode),
            layers: guide.layers,
            outer: guide.outer,
          );
        })
        .whereType<_OutfitMomentPreviewData>()
        .toList(growable: false);
  }

  _DetailedOutfitGuide _buildOutfitGuide({
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
      layers = l10n.homeWeatherOutfitLayersDefault;
      outer = l10n.homeWeatherOutfitOuterDefault;
      bottom = l10n.homeWeatherOutfitBottomDefault;
      accessories = l10n.homeWeatherOutfitAccessoriesDefault;
    } else if (apparentTemperature >= 30) {
      layers = l10n.homeWeatherOutfitLayersHot;
      outer = l10n.homeWeatherOutfitOuterNone;
      bottom = l10n.homeWeatherOutfitBottomHot;
      accessories = l10n.homeWeatherOutfitAccessoriesHot;
      notes.add(l10n.homeWeatherOutfitNoteHotBreaks);
    } else if (apparentTemperature >= 22) {
      layers = l10n.homeWeatherOutfitLayersWarm;
      outer = l10n.homeWeatherOutfitOuterNone;
      bottom = l10n.homeWeatherOutfitBottomWarm;
      accessories = l10n.homeWeatherOutfitAccessoriesWarm;
    } else if (apparentTemperature >= 15) {
      layers = l10n.homeWeatherOutfitLayersMild;
      outer = l10n.homeWeatherOutfitOuterMild;
      bottom = l10n.homeWeatherOutfitBottomMild;
      accessories = l10n.homeWeatherOutfitAccessoriesMild;
    } else if (apparentTemperature >= 8) {
      layers = l10n.homeWeatherOutfitLayersCool;
      outer = l10n.homeWeatherOutfitOuterCool;
      bottom = l10n.homeWeatherOutfitBottomTrackPants;
      accessories = l10n.homeWeatherOutfitAccessoriesCool;
    } else if (apparentTemperature >= 2) {
      layers = l10n.homeWeatherOutfitLayersCold;
      outer = l10n.homeWeatherOutfitOuterCold;
      bottom = l10n.homeWeatherOutfitBottomTrackPants;
      accessories = l10n.homeWeatherOutfitAccessoriesCold;
    } else {
      layers = l10n.homeWeatherOutfitLayersVeryCold;
      outer = l10n.homeWeatherOutfitOuterVeryCold;
      bottom = l10n.homeWeatherOutfitBottomVeryCold;
      accessories = l10n.homeWeatherOutfitAccessoriesVeryCold;
      notes.add(l10n.homeWeatherOutfitNoteVeryCold);
    }

    if (isWindy) {
      notes.add(l10n.homeWeatherOutfitNoteStrongWind);
      callouts.add(
        _OutfitCoachCallout(
          icon: Icons.air_rounded,
          text: l10n.homeWeatherOutfitWind,
        ),
      );
    }
    if (isRainy) {
      outer = isStormy || hasHeavyPrecipitation || isVeryWindy
          ? l10n.homeWeatherOutfitOuterWaterproof
          : l10n.homeWeatherOutfitOuterRainLight;
      accessories = l10n.homeWeatherOutfitAccessoriesRain(accessories);
      notes.add(l10n.homeWeatherOutfitNoteWetGrass);
      if (hasHeavyPrecipitation ||
          isStormy ||
          (apparentTemperature != null && apparentTemperature < 18)) {
        bottom = l10n.homeWeatherOutfitBottomTrackPants;
      }
      callouts.add(
        _OutfitCoachCallout(
          icon: Icons.umbrella_outlined,
          text: l10n.homeWeatherOutfitRain,
        ),
      );
    }
    if (isSnowy) {
      outer = l10n.homeWeatherOutfitOuterWaterproof;
      accessories = l10n.homeWeatherOutfitAccessoriesSnow(accessories);
      notes.add(l10n.homeWeatherOutfitNoteIcy);
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
      bottom = l10n.homeWeatherOutfitBottomFleece;
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
          ? l10n.homeWeatherOutfitCautionNormal
          : notes.join(' · '),
    );
  }

  List<_OutfitCase> _buildAllOutfitCases(AppLocalizations l10n) {
    final hotGuide = _buildOutfitGuide(
      l10n: l10n,
      apparentTemperature: 31,
      precipitationMm: 0,
      windSpeed: 8,
      weatherCode: 0,
      airLevel: _AirQualityLevel.good,
    );
    final warmGuide = _buildOutfitGuide(
      l10n: l10n,
      apparentTemperature: 25,
      precipitationMm: 0,
      windSpeed: 10,
      weatherCode: 1,
      airLevel: _AirQualityLevel.good,
    );
    final mildGuide = _buildOutfitGuide(
      l10n: l10n,
      apparentTemperature: 18,
      precipitationMm: 0,
      windSpeed: 11,
      weatherCode: 1,
      airLevel: _AirQualityLevel.good,
    );
    final coolGuide = _buildOutfitGuide(
      l10n: l10n,
      apparentTemperature: 11,
      precipitationMm: 0,
      windSpeed: 15,
      weatherCode: 2,
      airLevel: _AirQualityLevel.good,
    );
    final coldGuide = _buildOutfitGuide(
      l10n: l10n,
      apparentTemperature: 5,
      precipitationMm: 0,
      windSpeed: 12,
      weatherCode: 0,
      airLevel: _AirQualityLevel.good,
    );
    final wetGuide = _buildOutfitGuide(
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

enum _CompactMetricRole {
  detail,
  temperatureRange,
  feelsLike,
  comparedYesterday,
  humidity,
  precipitation,
  precipitationProbability,
  wind,
  airQuality,
}

class _CompactMetricData {
  final String label;
  final String value;
  final IconData icon;
  final _AirQualityLevel? airLevel;
  final _CompactMetricRole role;

  const _CompactMetricData({
    required this.label,
    required this.value,
    required this.icon,
    this.airLevel,
    this.role = _CompactMetricRole.detail,
  });
}

class _MetricSkeletonData {
  final Key key;
  final double labelWidthFactor;
  final double valueWidthFactor;

  const _MetricSkeletonData({
    required this.key,
    required this.labelWidthFactor,
    required this.valueWidthFactor,
  });
}

const _loadingDetailMetricSkeletons = <_MetricSkeletonData>[
  _MetricSkeletonData(
    key: ValueKey<String>('weatherMetricSkeleton.precipitation'),
    labelWidthFactor: 0.62,
    valueWidthFactor: 0.5,
  ),
  _MetricSkeletonData(
    key: ValueKey<String>('weatherMetricSkeleton.precipitationProbability'),
    labelWidthFactor: 0.78,
    valueWidthFactor: 0.58,
  ),
  _MetricSkeletonData(
    key: ValueKey<String>('weatherMetricSkeleton.pm10'),
    labelWidthFactor: 0.7,
    valueWidthFactor: 0.54,
  ),
  _MetricSkeletonData(
    key: ValueKey<String>('weatherMetricSkeleton.pm25'),
    labelWidthFactor: 0.76,
    valueWidthFactor: 0.54,
  ),
];

class _WeatherMetricOverview extends StatelessWidget {
  final List<_CompactMetricData> metrics;

  const _WeatherMetricOverview({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return _MetricClusterCard(metrics: metrics);
  }
}

class _WeatherMetricSkeletonOverview extends StatelessWidget {
  final List<_MetricSkeletonData> metrics;

  const _WeatherMetricSkeletonOverview({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < metrics.length; index++) ...[
          if (index > 0) const SizedBox(width: 6),
          Expanded(
            child: _MetricSkeletonCard(
              key: metrics[index].key,
              labelWidthFactor: metrics[index].labelWidthFactor,
              valueWidthFactor: metrics[index].valueWidthFactor,
            ),
          ),
        ],
      ],
    );
  }
}

class _MetricClusterCard extends StatelessWidget {
  final List<_CompactMetricData> metrics;

  const _MetricClusterCard({required this.metrics});

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        for (var index = 0; index < metrics.length; index++) ...[
          if (index > 0) const SizedBox(width: 6),
          Expanded(
            child: _MetricCard(
              label: metrics[index].label,
              value: metrics[index].value,
              icon: metrics[index].icon,
              airLevel: metrics[index].airLevel,
            ),
          ),
        ],
      ],
    );
  }
}

class _WeatherForecastSubscreen extends StatelessWidget {
  final String title;
  final Widget child;

  const _WeatherForecastSubscreen({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xl,
            ),
            children: [child],
          ),
        ),
      ),
    );
  }
}

class _WeatherHeaderActionButton extends StatelessWidget {
  final String label;
  final String tooltip;
  final Widget icon;
  final VoidCallback onPressed;

  const _WeatherHeaderActionButton({
    required this.label,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBarActionButton.label(
      tooltip: tooltip,
      icon: icon,
      label: label,
      maxLabelWidth: 64,
      onPressed: onPressed,
    );
  }
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
  final String sectionLabel;
  final String subtitle;
  final IconData subtitleIcon;
  final String? helper;
  final IconData icon;
  final bool loading;
  final VoidCallback? onRefresh;
  final List<_CompactMetricData> metrics;

  const _CompactWeatherHeaderCard({
    required this.title,
    required this.sectionLabel,
    required this.subtitle,
    this.subtitleIcon = Icons.place_rounded,
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
    _CompactMetricData? metricByRole(_CompactMetricRole role) {
      for (final metric in metrics) {
        if (metric.role == role) return metric;
      }
      return null;
    }

    final comparedMetric = metricByRole(
      _CompactMetricRole.comparedYesterday,
    );
    final temperatureRangeMetric = metricByRole(
      _CompactMetricRole.temperatureRange,
    );
    final inlineMetrics = <_CompactMetricData>[];
    for (final role in const [
      _CompactMetricRole.feelsLike,
      _CompactMetricRole.humidity,
      _CompactMetricRole.wind,
    ]) {
      final metric = metricByRole(role);
      if (metric != null) inlineMetrics.add(metric);
    }
    final detailMetrics = metrics
        .where(
          (metric) => !const {
            _CompactMetricRole.temperatureRange,
            _CompactMetricRole.comparedYesterday,
            _CompactMetricRole.feelsLike,
            _CompactMetricRole.humidity,
            _CompactMetricRole.wind,
          }.contains(metric.role),
        )
        .toList(growable: false);
    final showDetailMetricSkeleton = loading && detailMetrics.isEmpty;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withValues(alpha: 0.95),
            theme.colorScheme.secondaryContainer.withValues(alpha: 0.82),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.14),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
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
                        subtitleIcon,
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
              if (onRefresh != null || loading) ...[
                const SizedBox(width: AppSpacing.xs),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(
                      alpha: 0.2,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.surface.withValues(
                        alpha: 0.16,
                      ),
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: onRefresh,
                    child: Center(
                      child: loading
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
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            sectionLabel,
            style: theme.textTheme.labelLarge?.copyWith(
              color: onGradientMuted,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: theme.colorScheme.surface.withValues(
                      alpha: 0.16,
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
                      : Icon(icon, size: 42, color: onGradient),
                ),
              ),
              const SizedBox(width: 14),
              Flexible(
                child: Text(
                  headline.primary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.displayMedium?.copyWith(
                    color: onGradient,
                    fontWeight: FontWeight.w900,
                    height: 0.95,
                  ),
                ),
              ),
            ],
          ),
          if (comparedMetric != null || temperatureRangeMetric != null) ...[
            const SizedBox(height: 10),
            _WeatherDeltaSummaryRow(
              comparedMetric: comparedMetric,
              temperatureRangeMetric: temperatureRangeMetric,
              labelColor: onGradientMuted,
              valueColor: onGradient,
            ),
          ],
          if (headline.secondary != null) ...[
            const SizedBox(height: 4),
            Text(
              headline.secondary!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                color: onGradient,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
          if (helper != null && helper!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              helper!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: onGradientMuted,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (inlineMetrics.isNotEmpty) ...[
            const SizedBox(height: 10),
            _WeatherInlineMetricStrip(
              metrics: inlineMetrics,
              labelColor: onGradientMuted,
              valueColor: onGradient,
            ),
          ],
          if (detailMetrics.isNotEmpty || showDetailMetricSkeleton) ...[
            const SizedBox(height: AppSpacing.sm),
            if (showDetailMetricSkeleton)
              const _WeatherMetricSkeletonOverview(
                metrics: _loadingDetailMetricSkeletons,
              )
            else
              _WeatherMetricOverview(metrics: detailMetrics),
          ],
        ],
      ),
    );
  }
}

class _WeatherDeltaSummaryRow extends StatelessWidget {
  final _CompactMetricData? comparedMetric;
  final _CompactMetricData? temperatureRangeMetric;
  final Color labelColor;
  final Color valueColor;

  const _WeatherDeltaSummaryRow({
    required this.comparedMetric,
    required this.temperatureRangeMetric,
    required this.labelColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metrics = [
      if (comparedMetric != null) comparedMetric!,
      if (temperatureRangeMetric != null) temperatureRangeMetric!,
    ];
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        for (var index = 0; index < metrics.length; index++) ...[
          if (index > 0)
            Text(
              '·',
              style: theme.textTheme.titleSmall?.copyWith(
                color: labelColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          _WeatherDeltaLine(
            metric: metrics[index],
            labelColor: labelColor,
            valueColor: valueColor,
          ),
        ],
      ],
    );
  }
}

class _WeatherDeltaLine extends StatelessWidget {
  final _CompactMetricData metric;
  final Color labelColor;
  final Color valueColor;

  const _WeatherDeltaLine({
    required this.metric,
    required this.labelColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          metric.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            color: labelColor,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          metric.value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _WeatherInlineMetricStrip extends StatelessWidget {
  final List<_CompactMetricData> metrics;
  final Color labelColor;
  final Color valueColor;

  const _WeatherInlineMetricStrip({
    required this.metrics,
    required this.labelColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        for (var index = 0; index < metrics.length; index++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (index > 0)
                Text(
                  '·',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: labelColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              if (index > 0) const SizedBox(width: 8),
              Text(
                metrics[index].label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: labelColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                metrics[index].value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: valueColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final _AirQualityLevel? airLevel;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    this.airLevel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette =
        airLevel == null ? null : _airQualityPalette(theme, airLevel!);
    final foreground =
        palette?.foreground ?? theme.colorScheme.onPrimaryContainer;
    final labelColor = palette == null
        ? theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.72)
        : palette.foreground.withValues(alpha: 0.82);
    return Semantics(
      label: '$label $value',
      child: Container(
        constraints: const BoxConstraints(minHeight: 58),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
        decoration: BoxDecoration(
          color: palette?.background ??
              theme.colorScheme.surface.withValues(alpha: 0.68),
          borderRadius: AppRadius.small,
          border: Border.all(
            color: palette?.border ??
                theme.colorScheme.surface.withValues(alpha: 0.22),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: foreground,
            ),
            const SizedBox(height: 3),
            SizedBox(
              width: double.infinity,
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: labelColor,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
            ),
            const SizedBox(height: 2),
            SizedBox(
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  maxLines: 1,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricSkeletonCard extends StatelessWidget {
  final double labelWidthFactor;
  final double valueWidthFactor;

  const _MetricSkeletonCard({
    super.key,
    required this.labelWidthFactor,
    required this.valueWidthFactor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.68),
        borderRadius: AppRadius.small,
        border: Border.all(
          color: theme.colorScheme.surface.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppSkeletonBlock(
            width: 14,
            height: 14,
            borderRadius: BorderRadius.circular(999),
          ),
          const SizedBox(height: 5),
          FractionallySizedBox(
            widthFactor: labelWidthFactor,
            child: AppSkeletonBlock(
              height: 8,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 5),
          FractionallySizedBox(
            widthFactor: valueWidthFactor,
            child: AppSkeletonBlock(
              height: 10,
              borderRadius: BorderRadius.circular(999),
            ),
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
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xl,
            ),
            children: [
              _StructuredOutfitGuideCard(
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
            ],
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
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xl,
            ),
            itemCount: cases.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: AppSurfaces.subtleDecoration(
                    theme.colorScheme,
                    theme.brightness,
                    accent: theme.colorScheme.primary,
                    accentAlpha: 0.05,
                  ),
                  child: Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      height: 1.45,
                    ),
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

List<String> _splitOutfitItems(String raw, Pattern separator) => raw
    .split(separator)
    .map((item) => item.trim())
    .where((item) => item.isNotEmpty)
    .toList(growable: false);

class _OutfitDetailItem {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final Color foreground;

  const _OutfitDetailItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    required this.foreground,
  });
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final brightness = theme.brightness;
    final cautionItems = _splitOutfitItems(outfitCase.guide.caution, '·');
    final items = [
      _OutfitDetailItem(
        label: layersLabel,
        value: outfitCase.guide.layers,
        icon: Icons.checkroom_rounded,
        accent: scheme.primaryContainer,
        foreground: scheme.primary,
      ),
      _OutfitDetailItem(
        label: outerLabel,
        value: outfitCase.guide.outer,
        icon: Icons.shield_outlined,
        accent: scheme.secondaryContainer,
        foreground: scheme.secondary,
      ),
      _OutfitDetailItem(
        label: bottomLabel,
        value: outfitCase.guide.bottom,
        icon: Icons.directions_run_rounded,
        accent: scheme.tertiaryContainer,
        foreground: scheme.tertiary,
      ),
      _OutfitDetailItem(
        label: accessoriesLabel,
        value: outfitCase.guide.accessories,
        icon: Icons.backpack_outlined,
        accent: scheme.surfaceContainerHighest,
        foreground: scheme.onSurfaceVariant,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppSurfaces.cardDecoration(scheme, brightness),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(
                    alpha: brightness == Brightness.dark ? 0.22 : 0.10,
                  ),
                  borderRadius: AppRadius.small,
                ),
                child: Icon(
                  Icons.checkroom_rounded,
                  size: 22,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      outfitCase.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      outfitCase.summary,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _NeutralInfoChip(label: outfitCase.range),
          const SizedBox(height: AppSpacing.md),
          _OutfitDetailGrid(items: items),
          if (cautionItems.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _OutfitNotePanel(
              label: cautionLabel,
              items: cautionItems,
              icon: Icons.tips_and_updates_outlined,
            ),
          ],
        ],
      ),
    );
  }
}

class _OutfitDetailGrid extends StatelessWidget {
  final List<_OutfitDetailItem> items;

  const _OutfitDetailGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = AppSpacing.xs;
        final columns = constraints.maxWidth >= 640
            ? math.min(items.length, 4)
            : constraints.maxWidth >= 430
                ? math.min(items.length, 2)
                : 1;
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final item in items)
              SizedBox(
                width: itemWidth,
                child: _OutfitVisualCard(
                  label: item.label,
                  value: item.value,
                  icon: item.icon,
                  accent: item.accent,
                  foreground: item.foreground,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _OutfitNotePanel extends StatelessWidget {
  final String label;
  final List<String> items;
  final IconData icon;

  const _OutfitNotePanel({
    required this.label,
    required this.items,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final brightness = theme.brightness;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppSurfaces.subtleColor(scheme, brightness),
        borderRadius: AppRadius.small,
        border: Border.all(color: AppSurfaces.borderColor(scheme, brightness)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: scheme.primary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xxs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '•',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      item,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w700,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final brightness = theme.brightness;
    final cautionItems = _splitOutfitItems(guide.caution, '·');
    final contextChips = [
      if (weatherSummary.trim().isNotEmpty) weatherSummary.trim(),
      if (feelsLikeValue != '--') '$feelsLikeLabel $feelsLikeValue',
      if (windValue != '--') '$windLabel $windValue',
      if (airValue != '--') '$airLabel $airValue',
    ];
    final items = [
      _OutfitDetailItem(
        label: layersLabel,
        value: guide.layers,
        icon: Icons.checkroom_rounded,
        accent: scheme.primaryContainer,
        foreground: scheme.primary,
      ),
      _OutfitDetailItem(
        label: outerLabel,
        value: guide.outer,
        icon: Icons.shield_outlined,
        accent: scheme.secondaryContainer,
        foreground: scheme.secondary,
      ),
      _OutfitDetailItem(
        label: bottomLabel,
        value: guide.bottom,
        icon: Icons.directions_run_rounded,
        accent: scheme.tertiaryContainer,
        foreground: scheme.tertiary,
      ),
      _OutfitDetailItem(
        label: accessoriesLabel,
        value: guide.accessories,
        icon: Icons.backpack_outlined,
        accent: scheme.surfaceContainerHighest,
        foreground: scheme.onSurfaceVariant,
      ),
    ];
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppSurfaces.cardDecoration(scheme, brightness),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(
                    alpha: brightness == Brightness.dark ? 0.22 : 0.10,
                  ),
                  borderRadius: AppRadius.small,
                ),
                child: Icon(
                  Icons.checkroom_rounded,
                  size: 25,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (contextChips.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: contextChips
                  .map((label) => _NeutralInfoChip(label: label))
                  .toList(growable: false),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppSurfaces.subtleColor(scheme, brightness),
              borderRadius: AppRadius.small,
              border: Border.all(
                color: AppSurfaces.borderColor(scheme, brightness),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.tune_rounded,
                  size: 18,
                  color: scheme.primary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    guide.coachSummary,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w800,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (guide.callouts.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            ...guide.callouts.map(
              (callout) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: _OutfitCoachCalloutCard(callout: callout),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          _OutfitDetailGrid(items: items),
          if (cautionItems.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _OutfitNotePanel(
              label: cautionLabel,
              items: cautionItems,
              icon: Icons.tips_and_updates_outlined,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
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
    final scheme = theme.colorScheme;
    final brightness = theme.brightness;
    return Container(
      constraints: const BoxConstraints(minHeight: 86),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppSurfaces.subtleColor(scheme, brightness),
        borderRadius: AppRadius.small,
        border: Border.all(
          color: AppSurfaces.borderColor(scheme, brightness),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(
                alpha: brightness == Brightness.dark ? 0.24 : 0.56,
              ),
              borderRadius: AppRadius.small,
            ),
            child: Icon(icon, size: 19, color: foreground),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  value,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
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

class _OutfitCoachCalloutCard extends StatelessWidget {
  final _OutfitCoachCallout callout;

  const _OutfitCoachCalloutCard({required this.callout});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final brightness = theme.brightness;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppSurfaces.subtleColor(scheme, brightness),
        borderRadius: AppRadius.small,
        border: Border.all(
          color: AppSurfaces.borderColor(scheme, brightness),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(
                alpha: brightness == Brightness.dark ? 0.22 : 0.10,
              ),
              borderRadius: AppRadius.small,
            ),
            child: Icon(callout.icon, size: 17, color: scheme.primary),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              callout.text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OutfitMomentPreviewData {
  final String label;
  final String temperatureLabel;
  final IconData icon;
  final String layers;
  final String outer;

  const _OutfitMomentPreviewData({
    required this.label,
    required this.temperatureLabel,
    required this.icon,
    required this.layers,
    required this.outer,
  });
}

class _OutfitMomentPreviewCard extends StatelessWidget {
  final _OutfitMomentPreviewData preview;

  const _OutfitMomentPreviewCard({required this.preview});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final brightness = theme.brightness;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppSurfaces.subtleColor(scheme, brightness),
        borderRadius: AppRadius.small,
        border: Border.all(
          color: AppSurfaces.borderColor(scheme, brightness),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(
                    alpha: brightness == Brightness.dark ? 0.22 : 0.10,
                  ),
                  borderRadius: AppRadius.small,
                ),
                child: Icon(
                  preview.icon,
                  size: 18,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  preview.label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                preview.temperatureLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            preview.layers,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            preview.outer,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
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
  final String highLowLabel;
  final String precipitationLabel;
  final String precipitationProbabilityLabel;
  final String hourlyPrecipitationLabel;
  final String hourlyOverviewLabel;
  final String windLabel;
  final String fineDustLabel;
  final String ultraFineDustLabel;
  final String outfitTitle;
  final String outfitFallback;
  final List<_OutfitMomentPreviewData> outfitPreviews;
  final _DailyWeatherForecast? tomorrowForecast;
  final String tomorrowFallback;
  final String Function(double?, double?) formatRange;
  final String Function(double?) formatTemperature;
  final String Function(double?) formatMillimeter;
  final String Function(double?) formatProbability;
  final String Function(_HourlyPrecipitationEntry) formatPrecipitationEntry;
  final String Function(double?) formatWind;
  final String Function(DateTime) formatTime;
  final String Function(double?) formatFineDust;
  final _AirLevelLabel Function(double?) pm10LevelForValue;
  final _AirLevelLabel Function(double?) pm25LevelForValue;
  final IconData Function(int?) iconForCode;

  const _TomorrowWeatherCard({
    required this.title,
    required this.highLowLabel,
    required this.precipitationLabel,
    required this.precipitationProbabilityLabel,
    required this.hourlyPrecipitationLabel,
    required this.hourlyOverviewLabel,
    required this.windLabel,
    required this.fineDustLabel,
    required this.ultraFineDustLabel,
    required this.outfitTitle,
    required this.outfitFallback,
    required this.outfitPreviews,
    required this.tomorrowForecast,
    required this.tomorrowFallback,
    required this.formatRange,
    required this.formatTemperature,
    required this.formatMillimeter,
    required this.formatProbability,
    required this.formatPrecipitationEntry,
    required this.formatWind,
    required this.formatTime,
    required this.formatFineDust,
    required this.pm10LevelForValue,
    required this.pm25LevelForValue,
    required this.iconForCode,
  });

  String _headlineFor(_DailyWeatherForecast forecast) {
    final headlineTemperature =
        forecast.temperatureMax ?? forecast.temperatureMin;
    if (headlineTemperature == null) return forecast.summary;
    return '${forecast.summary} ${formatTemperature(headlineTemperature)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final forecast = tomorrowForecast;
    if (forecast == null) {
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
            Text(
              tomorrowFallback,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    final temperatureEntries = forecast.hourlyForecasts
        .where((entry) => entry.temperature != null)
        .toList(growable: false);
    final precipitationEntries = _visibleHourlyPrecipitationEntries(
      forecast.hourlyPrecipitations,
    );
    final overviewEntries = _hourlyWeatherOverviewEntries(
      forecasts: temperatureEntries,
      precipitations: precipitationEntries,
    );
    final pm10Level = pm10LevelForValue(forecast.pm10);
    final pm25Level = pm25LevelForValue(forecast.pm25);
    final metrics = <_CompactMetricData>[
      _CompactMetricData(
        label: highLowLabel,
        value: formatRange(forecast.temperatureMax, forecast.temperatureMin),
        icon: Icons.thermostat_outlined,
        role: _CompactMetricRole.temperatureRange,
      ),
      _CompactMetricData(
        label: precipitationLabel,
        value: formatMillimeter(forecast.precipitationSum),
        icon: Icons.umbrella_outlined,
        role: _CompactMetricRole.precipitation,
      ),
      _CompactMetricData(
        label: precipitationProbabilityLabel,
        value: formatProbability(forecast.precipitationProbabilityMax),
        icon: Icons.water_drop_rounded,
        role: _CompactMetricRole.precipitationProbability,
      ),
      _CompactMetricData(
        label: windLabel,
        value: formatWind(forecast.windSpeedMax),
        icon: Icons.air_rounded,
        role: _CompactMetricRole.wind,
      ),
      if (forecast.pm10 != null)
        _CompactMetricData(
          label: fineDustLabel,
          value: '${formatFineDust(forecast.pm10)} ${pm10Level.label}',
          icon: Icons.blur_on_rounded,
          airLevel: pm10Level.level,
          role: _CompactMetricRole.airQuality,
        ),
      if (forecast.pm25 != null)
        _CompactMetricData(
          label: ultraFineDustLabel,
          value: '${formatFineDust(forecast.pm25)} ${pm25Level.label}',
          icon: Icons.blur_circular_rounded,
          airLevel: pm25Level.level,
          role: _CompactMetricRole.airQuality,
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CompactWeatherHeaderCard(
          title: _headlineFor(forecast),
          sectionLabel: title,
          subtitle: '${forecast.weekdayLabel} · ${forecast.label}',
          subtitleIcon: Icons.calendar_today_rounded,
          helper: null,
          icon: iconForCode(forecast.weatherCode),
          loading: false,
          onRefresh: null,
          metrics: metrics,
        ),
        if (temperatureEntries.isNotEmpty || precipitationEntries.isNotEmpty)
          const SizedBox(height: 12),
        if (temperatureEntries.isNotEmpty && overviewEntries.isNotEmpty)
          _HourlyTemperatureSection(
            title: hourlyOverviewLabel,
            entries: overviewEntries,
            precipitationProbabilityLabel: precipitationProbabilityLabel,
            precipitationLabel: precipitationLabel,
            windLabel: windLabel,
            formatTime: formatTime,
            formatTemperature: formatTemperature,
            formatProbability: formatProbability,
            formatPrecipitation: formatPrecipitationEntry,
            formatWind: formatWind,
            iconForCode: iconForCode,
          ),
        if (temperatureEntries.isEmpty && precipitationEntries.isNotEmpty)
          _HourlyPrecipitationSection(
            title: hourlyPrecipitationLabel,
            entries: precipitationEntries,
            formatTime: formatTime,
            formatPrecipitation: formatPrecipitationEntry,
          ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
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
                outfitTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              if (outfitPreviews.isEmpty)
                Text(
                  outfitFallback,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidth = (constraints.maxWidth - 10) / 2;
                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: outfitPreviews
                          .map(
                            (preview) => SizedBox(
                              width: cardWidth,
                              child: _OutfitMomentPreviewCard(
                                preview: preview,
                              ),
                            ),
                          )
                          .toList(growable: false),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeeklyForecastCard extends StatelessWidget {
  final String title;
  final String precipitationLabel;
  final String windLabel;
  final String fineDustLabel;
  final String ultraFineDustLabel;
  final String airQualityMissingReason;
  final String fallback;
  final List<_DailyWeatherForecast> forecasts;
  final String Function(double?, double?) formatRange;
  final String Function(double?) formatMillimeter;
  final String Function(double?) formatWind;
  final String Function(double?) formatFineDust;
  final _AirQualityLevel Function(double?) pm10LevelForValue;
  final _AirQualityLevel Function(double?) pm25LevelForValue;
  final IconData Function(int?) iconForCode;

  const _WeeklyForecastCard({
    required this.title,
    required this.precipitationLabel,
    required this.windLabel,
    required this.fineDustLabel,
    required this.ultraFineDustLabel,
    required this.airQualityMissingReason,
    required this.fallback,
    required this.forecasts,
    required this.formatRange,
    required this.formatMillimeter,
    required this.formatWind,
    required this.formatFineDust,
    required this.pm10LevelForValue,
    required this.pm25LevelForValue,
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
          if (forecasts.isEmpty)
            Text(
              fallback,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          for (final forecast in forecasts) ...[
            _WeeklyForecastRow(
              precipitationLabel: precipitationLabel,
              windLabel: windLabel,
              fineDustLabel: fineDustLabel,
              ultraFineDustLabel: ultraFineDustLabel,
              forecast: forecast,
              range: formatRange(
                forecast.temperatureMax,
                forecast.temperatureMin,
              ),
              precipitation: formatMillimeter(forecast.precipitationSum),
              wind: formatWind(forecast.windSpeedMax),
              fineDust:
                  forecast.pm10 == null ? null : formatFineDust(forecast.pm10),
              fineDustLevel: forecast.pm10 == null
                  ? null
                  : pm10LevelForValue(forecast.pm10),
              ultraFineDust:
                  forecast.pm25 == null ? null : formatFineDust(forecast.pm25),
              ultraFineDustLevel: forecast.pm25 == null
                  ? null
                  : pm25LevelForValue(forecast.pm25),
              airQualityMissingReason: airQualityMissingReason,
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
  final String fineDustLabel;
  final String ultraFineDustLabel;
  final _DailyWeatherForecast forecast;
  final String range;
  final String precipitation;
  final String wind;
  final String? fineDust;
  final _AirQualityLevel? fineDustLevel;
  final String? ultraFineDust;
  final _AirQualityLevel? ultraFineDustLevel;
  final String airQualityMissingReason;
  final IconData icon;

  const _WeeklyForecastRow({
    required this.precipitationLabel,
    required this.windLabel,
    required this.fineDustLabel,
    required this.ultraFineDustLabel,
    required this.forecast,
    required this.range,
    required this.precipitation,
    required this.wind,
    required this.fineDust,
    required this.fineDustLevel,
    required this.ultraFineDust,
    required this.ultraFineDustLevel,
    required this.airQualityMissingReason,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasAirQualityInfo = fineDust != null || ultraFineDust != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.72),
        borderRadius: AppRadius.small,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.42),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 54,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      forecast.weekdayLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      forecast.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.86,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.14),
                  ),
                ),
                child: Icon(
                  icon,
                  size: 21,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  forecast.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.08,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                range,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ForecastStatPill(
                icon: Icons.water_drop_outlined,
                label: precipitationLabel,
                value: precipitation,
                dense: true,
              ),
              _ForecastStatPill(
                icon: Icons.air_rounded,
                label: windLabel,
                value: wind,
                dense: true,
              ),
              if (hasAirQualityInfo) ...[
                if (fineDust != null)
                  _ForecastStatPill(
                    icon: Icons.blur_on_rounded,
                    label: fineDustLabel,
                    value: fineDust!,
                    airLevel: fineDustLevel,
                    dense: true,
                  ),
                if (ultraFineDust != null)
                  _ForecastStatPill(
                    icon: Icons.blur_circular_rounded,
                    label: ultraFineDustLabel,
                    value: ultraFineDust!,
                    airLevel: ultraFineDustLevel,
                    dense: true,
                  ),
              ] else
                _ForecastStatPill(
                  icon: Icons.info_outline_rounded,
                  label: fineDustLabel,
                  value: airQualityMissingReason,
                  dense: true,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ForecastStatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final _AirQualityLevel? airLevel;
  final bool dense;

  const _ForecastStatPill({
    required this.icon,
    required this.label,
    required this.value,
    this.airLevel,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette =
        airLevel == null ? null : _airQualityPalette(theme, airLevel!);
    final visibleText = '$label $value';
    return Semantics(
      label: '$label $value',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 8 : 10,
          vertical: dense ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: palette?.background ?? theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(dense ? 12 : 14),
          border: Border.all(
            color: palette?.border ??
                theme.colorScheme.outlineVariant.withValues(alpha: 0.32),
          ),
        ),
        child: IntrinsicWidth(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: dense ? 14 : 16,
                color: palette?.foreground ?? theme.colorScheme.primary,
              ),
              SizedBox(width: dense ? 6 : 8),
              Flexible(
                child: Text(
                  visibleText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette?.foreground ??
                        theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                    height: 1.12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<_HourlyPrecipitationEntry> _visibleHourlyPrecipitationEntries(
  List<_HourlyPrecipitationEntry> entries,
) {
  final sortedEntries = [...entries]
    ..sort((left, right) => left.time.compareTo(right.time));
  final hasRainSignal = sortedEntries.any(
    (entry) =>
        entry.precipitation > 0.05 ||
        (entry.precipitationProbability ?? 0) >= 30,
  );
  if (!hasRainSignal) return const <_HourlyPrecipitationEntry>[];
  return sortedEntries;
}

DateTime _hourBucket(DateTime time) =>
    DateTime(time.year, time.month, time.day, time.hour);

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

DateTime _hourlyFocusTimeForForecastDate(DateTime forecastDate) {
  final now = DateTime.now();
  return DateTime(
    forecastDate.year,
    forecastDate.month,
    forecastDate.day,
    now.hour,
    now.minute,
  );
}

int? _closestHourlyIndex<T>(
  List<T> entries,
  DateTime? focusTime,
  DateTime Function(T entry) timeOf,
) {
  if (entries.isEmpty || focusTime == null) return null;
  final focusHour = _hourBucket(focusTime);
  var closestIndex = 0;
  var closestDistance =
      _hourBucket(timeOf(entries.first)).difference(focusHour).abs().inMinutes;
  for (var index = 1; index < entries.length; index++) {
    final distance = _hourBucket(timeOf(entries[index]))
        .difference(focusHour)
        .abs()
        .inMinutes;
    if (distance < closestDistance) {
      closestDistance = distance;
      closestIndex = index;
    }
  }
  return closestIndex;
}

List<_HourlyWeatherOverviewEntry> _hourlyWeatherOverviewEntries({
  required List<_ForecastMomentPreview> forecasts,
  required List<_HourlyPrecipitationEntry> precipitations,
}) {
  final forecastByHour = <DateTime, _ForecastMomentPreview>{
    for (final forecast in forecasts) _hourBucket(forecast.time): forecast,
  };
  final precipitationByHour = <DateTime, _HourlyPrecipitationEntry>{
    for (final precipitation in precipitations)
      _hourBucket(precipitation.time): precipitation,
  };
  final hours = <DateTime>{
    ...forecastByHour.keys,
    ...precipitationByHour.keys,
  }.toList(growable: false)
    ..sort();
  return [
    for (final hour in hours)
      _HourlyWeatherOverviewEntry.from(
        hour: hour,
        forecast: forecastByHour[hour],
        precipitationEntry: precipitationByHour[hour],
      ),
  ].where((entry) => entry.hasDisplayData).toList(growable: false);
}

const _hourlyWeatherLabelWidth = 70.0;
const _hourlyWeatherColumnWidth = 64.0;

class _HourlyWeatherOverviewEntry {
  final DateTime time;
  final double? temperature;
  final int? weatherCode;
  final double? precipitation;
  final double? precipitationProbability;
  final double? windSpeed;

  const _HourlyWeatherOverviewEntry({
    required this.time,
    this.temperature,
    this.weatherCode,
    this.precipitation,
    this.precipitationProbability,
    this.windSpeed,
  });

  factory _HourlyWeatherOverviewEntry.from({
    required DateTime hour,
    required _ForecastMomentPreview? forecast,
    required _HourlyPrecipitationEntry? precipitationEntry,
  }) {
    return _HourlyWeatherOverviewEntry(
      time: hour,
      temperature: forecast?.temperature,
      weatherCode: forecast?.weatherCode,
      precipitation:
          precipitationEntry?.precipitation ?? forecast?.precipitation,
      precipitationProbability: precipitationEntry?.precipitationProbability ??
          forecast?.precipitationProbability,
      windSpeed: forecast?.windSpeed,
    );
  }

  bool get hasDisplayData =>
      temperature != null ||
      weatherCode != null ||
      precipitation != null ||
      precipitationProbability != null ||
      windSpeed != null;

  _HourlyPrecipitationEntry toPrecipitationEntry() {
    return _HourlyPrecipitationEntry(
      time: time,
      precipitation: precipitation ?? 0,
      precipitationProbability: precipitationProbability,
    );
  }
}

enum _PrecipitationAmountLevel {
  none,
  trace,
  light,
  moderate,
  heavy,
  veryHeavy,
}

_PrecipitationAmountLevel _precipitationAmountLevel(double value) {
  if (value <= 0.05) return _PrecipitationAmountLevel.none;
  if (value < 1) return _PrecipitationAmountLevel.trace;
  if (value < 5) return _PrecipitationAmountLevel.light;
  if (value < 15) return _PrecipitationAmountLevel.moderate;
  if (value < 30) return _PrecipitationAmountLevel.heavy;
  return _PrecipitationAmountLevel.veryHeavy;
}

class _FocusedHorizontalScrollView extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double? initialCenterOffset;

  const _FocusedHorizontalScrollView({
    required this.child,
    required this.padding,
    required this.initialCenterOffset,
  });

  @override
  State<_FocusedHorizontalScrollView> createState() =>
      _FocusedHorizontalScrollViewState();
}

class _FocusedHorizontalScrollViewState
    extends State<_FocusedHorizontalScrollView> {
  late final ScrollController _controller;
  bool _appliedInitialOffset = false;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    _scheduleInitialOffset();
  }

  @override
  void didUpdateWidget(covariant _FocusedHorizontalScrollView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCenterOffset != widget.initialCenterOffset) {
      _appliedInitialOffset = false;
      _scheduleInitialOffset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _scheduleInitialOffset() {
    if (widget.initialCenterOffset == null || _appliedInitialOffset) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          _appliedInitialOffset ||
          widget.initialCenterOffset == null ||
          !_controller.hasClients) {
        return;
      }
      final position = _controller.position;
      final target =
          (widget.initialCenterOffset! - (position.viewportDimension / 2))
              .clamp(0.0, position.maxScrollExtent)
              .toDouble();
      _controller.jumpTo(target);
      _appliedInitialOffset = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _controller,
      scrollDirection: Axis.horizontal,
      padding: widget.padding,
      child: widget.child,
    );
  }
}

class _HourlyPrecipitationSection extends StatelessWidget {
  final String title;
  final List<_HourlyPrecipitationEntry> entries;
  final String Function(DateTime) formatTime;
  final String Function(_HourlyPrecipitationEntry) formatPrecipitation;
  final DateTime? focusTime;
  final bool accentStyle;

  const _HourlyPrecipitationSection({
    required this.title,
    required this.entries,
    required this.formatTime,
    required this.formatPrecipitation,
    this.focusTime,
    this.accentStyle = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sortedEntries = _visibleHourlyPrecipitationEntries(entries);
    if (sortedEntries.isEmpty) return const SizedBox.shrink();
    final background = accentStyle
        ? theme.colorScheme.surface.withValues(alpha: 0.16)
        : theme.colorScheme.surfaceContainerLow;
    final borderColor = accentStyle
        ? theme.colorScheme.surface.withValues(alpha: 0.16)
        : theme.colorScheme.outlineVariant.withValues(alpha: 0.5);
    final titleColor = accentStyle
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface;
    final chartColor = accentStyle
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.primary;
    final timeTextColor = accentStyle
        ? theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.72)
        : theme.colorScheme.onSurfaceVariant;
    final chartBackground = accentStyle
        ? theme.colorScheme.surface.withValues(alpha: 0.12)
        : theme.colorScheme.primaryContainer.withValues(alpha: 0.32);
    final maxEntry = sortedEntries.fold<_HourlyPrecipitationEntry?>(
      null,
      (current, value) {
        if (current == null) return value;
        if (value.precipitation > current.precipitation) return value;
        if (value.precipitation == current.precipitation &&
            (value.precipitationProbability ?? 0) >
                (current.precipitationProbability ?? 0)) {
          return value;
        }
        return current;
      },
    );
    final focusedIndex = _closestHourlyIndex<_HourlyPrecipitationEntry>(
      sortedEntries,
      focusTime,
      (entry) => entry.time,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.control,
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (maxEntry != null)
                Text(
                  formatPrecipitation(maxEntry),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: timeTextColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          DecoratedBox(
            decoration: BoxDecoration(
              color: chartBackground,
              borderRadius: AppRadius.small,
            ),
            child: _FocusedHorizontalScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              initialCenterOffset:
                  focusedIndex == null ? null : (focusedIndex * 62.0) + 31.0,
              child: _HourlyPrecipitationChart(
                entries: sortedEntries,
                formatTime: formatTime,
                formatPrecipitation: formatPrecipitation,
                barColor: chartColor,
                labelColor: accentStyle
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onPrimaryContainer,
                mutedLabelColor: timeTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HourlyPrecipitationChart extends StatelessWidget {
  final List<_HourlyPrecipitationEntry> entries;
  final String Function(DateTime) formatTime;
  final String Function(_HourlyPrecipitationEntry) formatPrecipitation;
  final Color barColor;
  final Color labelColor;
  final Color mutedLabelColor;

  const _HourlyPrecipitationChart({
    required this.entries,
    required this.formatTime,
    required this.formatPrecipitation,
    required this.barColor,
    required this.labelColor,
    required this.mutedLabelColor,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    final width = math.max(320.0, entries.length * 62.0);
    const chartHeight = 72.0;
    const precipitationLabelHeight = 34.0;
    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: chartHeight,
            child: CustomPaint(
              size: Size(width, chartHeight),
              painter: _HourlyPrecipitationChartPainter(
                entries: entries,
                barColor: barColor,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: List<Widget>.generate(entries.length, (index) {
              final entry = entries[index];
              final previousEntry = index == 0 ? null : entries[index - 1];
              final showPrecipitationLabel = previousEntry == null ||
                  _precipitationAmountLevel(entry.precipitation) !=
                      _precipitationAmountLevel(
                        previousEntry.precipitation,
                      );
              return SizedBox(
                width: width / entries.length,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: precipitationLabelHeight,
                      child: Center(
                        child: showPrecipitationLabel
                            ? Text(
                                formatPrecipitation(entry),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      color: labelColor,
                                      fontWeight: FontWeight.w900,
                                      height: 1.05,
                                    ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatTime(entry.time),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: mutedLabelColor,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _HourlyPrecipitationChartPainter extends CustomPainter {
  final List<_HourlyPrecipitationEntry> entries;
  final Color barColor;

  const _HourlyPrecipitationChartPainter({
    required this.entries,
    required this.barColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;
    final maxPrecipitation =
        entries.map((entry) => entry.precipitation).fold<double>(0, math.max);
    const topPadding = 12.0;
    const bottomPadding = 14.0;
    final usableHeight = size.height - topPadding - bottomPadding;
    final step = entries.length <= 1 ? size.width : size.width / entries.length;
    final zeroLineY = size.height - bottomPadding;
    final basePaint = Paint()
      ..color = barColor.withValues(alpha: 0.18)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(step / 3, zeroLineY),
      Offset(size.width - (step / 3), zeroLineY),
      basePaint,
    );
    final positivePaint = Paint()
      ..color = barColor
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    final zeroPaint = Paint()
      ..color = barColor.withValues(alpha: 0.32)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index < entries.length; index++) {
      final precipitation = entries[index].precipitation;
      final x = (step * index) + (step / 2);
      if (precipitation <= 0 || maxPrecipitation <= 0) {
        canvas.drawLine(
          Offset(x, zeroLineY),
          Offset(x, zeroLineY - 2),
          zeroPaint,
        );
        continue;
      }
      final normalized = (precipitation / maxPrecipitation).clamp(0.0, 1.0);
      final y = topPadding + ((1 - normalized) * usableHeight);
      canvas.drawLine(Offset(x, zeroLineY), Offset(x, y), positivePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HourlyPrecipitationChartPainter oldDelegate) {
    return oldDelegate.entries != entries || oldDelegate.barColor != barColor;
  }
}

class _HourlyTemperatureSection extends StatelessWidget {
  final String title;
  final List<_HourlyWeatherOverviewEntry> entries;
  final String precipitationProbabilityLabel;
  final String precipitationLabel;
  final String windLabel;
  final String Function(DateTime) formatTime;
  final String Function(double?) formatTemperature;
  final String Function(double?) formatProbability;
  final String Function(_HourlyPrecipitationEntry) formatPrecipitation;
  final String Function(double?) formatWind;
  final IconData Function(int?) iconForCode;
  final DateTime? focusTime;
  final bool accentStyle;

  const _HourlyTemperatureSection({
    required this.title,
    required this.entries,
    required this.precipitationProbabilityLabel,
    required this.precipitationLabel,
    required this.windLabel,
    required this.formatTime,
    required this.formatTemperature,
    required this.formatProbability,
    required this.formatPrecipitation,
    required this.formatWind,
    required this.iconForCode,
    this.focusTime,
    this.accentStyle = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sortedEntries = [...entries]
      ..sort((left, right) => left.time.compareTo(right.time));
    final temperatureEntries = sortedEntries
        .where((entry) => entry.temperature != null)
        .toList(growable: false);
    if (temperatureEntries.isEmpty) return const SizedBox.shrink();
    final background = accentStyle
        ? theme.colorScheme.surface.withValues(alpha: 0.16)
        : theme.colorScheme.surfaceContainerLow;
    final borderColor = accentStyle
        ? theme.colorScheme.surface.withValues(alpha: 0.16)
        : theme.colorScheme.outlineVariant.withValues(alpha: 0.5);
    final titleColor = accentStyle
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface;
    final timeTextColor = accentStyle
        ? theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.72)
        : theme.colorScheme.onSurfaceVariant;
    final chartBackground = accentStyle
        ? theme.colorScheme.surface.withValues(alpha: 0.12)
        : theme.colorScheme.secondaryContainer.withValues(alpha: 0.42);
    final rowDividerColor = accentStyle
        ? theme.colorScheme.surface.withValues(alpha: 0.14)
        : theme.colorScheme.outlineVariant.withValues(alpha: 0.42);
    final minTemperature = temperatureEntries
        .map((entry) => entry.temperature!)
        .fold<double?>(null, (current, value) {
      if (current == null) return value;
      return math.min(current, value);
    });
    final maxTemperature = temperatureEntries
        .map((entry) => entry.temperature!)
        .fold<double?>(null, (current, value) {
      if (current == null) return value;
      return math.max(current, value);
    });
    final hasProbability = sortedEntries.any(
      (entry) => entry.precipitationProbability != null,
    );
    final hasPrecipitation = sortedEntries.any(
      (entry) => entry.precipitation != null,
    );
    final hasWind = sortedEntries.any((entry) => entry.windSpeed != null);
    final width = _hourlyWeatherLabelWidth +
        (sortedEntries.length * _hourlyWeatherColumnWidth);
    final focusedIndex = _closestHourlyIndex<_HourlyWeatherOverviewEntry>(
      sortedEntries,
      focusTime,
      (entry) => entry.time,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.control,
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (minTemperature != null && maxTemperature != null)
                Text(
                  '↓ ${formatTemperature(minTemperature)}  ↑ ${formatTemperature(maxTemperature)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: timeTextColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          DecoratedBox(
            decoration: BoxDecoration(
              color: chartBackground,
              borderRadius: AppRadius.small,
            ),
            child: _FocusedHorizontalScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              initialCenterOffset: focusedIndex == null
                  ? null
                  : _hourlyWeatherLabelWidth +
                      (focusedIndex * _hourlyWeatherColumnWidth) +
                      (_hourlyWeatherColumnWidth / 2),
              child: SizedBox(
                width: width,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _HourlyTemperatureChart(
                      entries: sortedEntries,
                      formatTime: formatTime,
                      formatTemperature: formatTemperature,
                      temperatureColors: [
                        for (final entry in sortedEntries)
                          entry.temperature == null
                              ? timeTextColor
                              : _temperatureGraphColor(entry.temperature!),
                      ],
                      pointFillColor: accentStyle
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surface,
                      mutedLabelColor: timeTextColor,
                      iconForCode: iconForCode,
                    ),
                    if (hasProbability)
                      _HourlyWeatherMetricRow(
                        label: precipitationProbabilityLabel,
                        values: [
                          for (final entry in sortedEntries)
                            formatProbability(entry.precipitationProbability),
                        ],
                        labelColor: timeTextColor,
                        valueColor: titleColor,
                        dividerColor: rowDividerColor,
                      ),
                    if (hasPrecipitation)
                      _HourlyWeatherMetricRow(
                        label: precipitationLabel,
                        values: [
                          for (var index = 0;
                              index < sortedEntries.length;
                              index++)
                            _precipitationOverviewLabel(
                              sortedEntries,
                              index,
                            ),
                        ],
                        labelColor: timeTextColor,
                        valueColor: titleColor,
                        dividerColor: rowDividerColor,
                      ),
                    if (hasWind)
                      _HourlyWeatherMetricRow(
                        label: windLabel,
                        values: [
                          for (final entry in sortedEntries)
                            formatWind(entry.windSpeed),
                        ],
                        labelColor: timeTextColor,
                        valueColor: titleColor,
                        dividerColor: rowDividerColor,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _precipitationOverviewLabel(
    List<_HourlyWeatherOverviewEntry> entries,
    int index,
  ) {
    final entry = entries[index];
    final precipitation = entry.precipitation;
    if (precipitation == null) return '--';
    final previous = index == 0 ? null : entries[index - 1];
    final level = _precipitationAmountLevel(precipitation);
    final previousLevel = previous?.precipitation == null
        ? null
        : _precipitationAmountLevel(previous!.precipitation!);
    if (previousLevel == level) return '';
    return formatPrecipitation(entry.toPrecipitationEntry());
  }
}

class _HourlyWeatherMetricRow extends StatelessWidget {
  final String label;
  final List<String> values;
  final Color labelColor;
  final Color valueColor;
  final Color dividerColor;

  const _HourlyWeatherMetricRow({
    required this.label,
    required this.values,
    required this.labelColor,
    required this.valueColor,
    required this.dividerColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 40),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: dividerColor)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: _hourlyWeatherLabelWidth,
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: labelColor,
                fontWeight: FontWeight.w900,
                height: 1.08,
              ),
            ),
          ),
          for (final value in values)
            SizedBox(
              width: _hourlyWeatherColumnWidth,
              child: Center(
                child: Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: valueColor,
                    fontWeight: value.trim().isEmpty
                        ? FontWeight.w600
                        : FontWeight.w900,
                    height: 1.08,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Color _temperatureGraphColor(double temperature) {
  if (temperature <= 0) return const Color(0xFF2563EB);
  if (temperature <= 10) return const Color(0xFF0891B2);
  if (temperature <= 20) return const Color(0xFF059669);
  if (temperature <= 28) return const Color(0xFFD97706);
  return const Color(0xFFDC2626);
}

class _HourlyTemperatureChart extends StatelessWidget {
  final List<_HourlyWeatherOverviewEntry> entries;
  final String Function(DateTime) formatTime;
  final String Function(double?) formatTemperature;
  final List<Color> temperatureColors;
  final Color pointFillColor;
  final Color mutedLabelColor;
  final IconData Function(int?) iconForCode;

  const _HourlyTemperatureChart({
    required this.entries,
    required this.formatTime,
    required this.formatTemperature,
    required this.temperatureColors,
    required this.pointFillColor,
    required this.mutedLabelColor,
    required this.iconForCode,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    final width =
        _hourlyWeatherLabelWidth + (entries.length * _hourlyWeatherColumnWidth);
    const chartHeight = 72.0;
    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const SizedBox(width: _hourlyWeatherLabelWidth),
              for (var index = 0; index < entries.length; index++)
                SizedBox(
                  width: _hourlyWeatherColumnWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatTime(entries[index].time),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: mutedLabelColor,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Icon(
                        iconForCode(entries[index].weatherCode),
                        size: 20,
                        color: temperatureColors[index],
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: chartHeight,
            child: CustomPaint(
              size: Size(width, chartHeight),
              painter: _HourlyTemperatureChartPainter(
                entries: entries,
                temperatureColors: temperatureColors,
                pointFillColor: pointFillColor,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const SizedBox(width: _hourlyWeatherLabelWidth),
              for (var index = 0; index < entries.length; index++)
                SizedBox(
                  width: _hourlyWeatherColumnWidth,
                  child: Text(
                    formatTemperature(entries[index].temperature),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: temperatureColors[index],
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HourlyTemperatureChartPainter extends CustomPainter {
  final List<_HourlyWeatherOverviewEntry> entries;
  final List<Color> temperatureColors;
  final Color pointFillColor;

  const _HourlyTemperatureChartPainter({
    required this.entries,
    required this.temperatureColors,
    required this.pointFillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final temperatures = entries
        .map((entry) => entry.temperature)
        .whereType<double>()
        .toList(growable: false);
    if (temperatures.isEmpty) return;
    final minTemperature = temperatures.reduce(math.min);
    final maxTemperature = temperatures.reduce(math.max);
    final spread = math.max(1.0, maxTemperature - minTemperature);
    const topPadding = 12.0;
    const bottomPadding = 14.0;
    final usableHeight = size.height - topPadding - bottomPadding;
    final points = <({Offset point, Color color})>[];
    for (var index = 0; index < entries.length; index++) {
      final temperature = entries[index].temperature;
      if (temperature == null) continue;
      final x = _hourlyWeatherLabelWidth +
          (_hourlyWeatherColumnWidth * index) +
          (_hourlyWeatherColumnWidth / 2);
      final normalized = (temperature - minTemperature) / spread;
      final y = topPadding + ((1 - normalized) * usableHeight);
      final color = temperatureColors[index];
      points.add((point: Offset(x, y), color: color));
      final barPaint = Paint()
        ..color = color.withValues(alpha: 0.26)
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(x, size.height - bottomPadding),
        Offset(x, y),
        barPaint,
      );
    }
    if (points.length >= 2) {
      for (var index = 1; index < points.length; index++) {
        final previous = points[index - 1];
        final current = points[index];
        final segmentColor =
            Color.lerp(previous.color, current.color, 0.5) ?? current.color;
        canvas.drawLine(
          previous.point,
          current.point,
          Paint()
            ..color = segmentColor
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      }
    }
    final pointFillPaint = Paint()..color = pointFillColor;
    for (final point in points) {
      final pointBorderPaint = Paint()..color = point.color;
      canvas.drawCircle(point.point, 5.5, pointBorderPaint);
      canvas.drawCircle(point.point, 3.2, pointFillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HourlyTemperatureChartPainter oldDelegate) {
    return oldDelegate.entries != entries ||
        oldDelegate.temperatureColors != temperatureColors ||
        oldDelegate.pointFillColor != pointFillColor;
  }
}

class _HourlyPrecipitationEntry {
  final DateTime time;
  final double precipitation;
  final double? precipitationProbability;

  const _HourlyPrecipitationEntry({
    required this.time,
    required this.precipitation,
    this.precipitationProbability,
  });
}

class _NeutralInfoChip extends StatelessWidget {
  final String label;

  const _NeutralInfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final brightness = theme.brightness;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppSurfaces.subtleColor(scheme, brightness),
        borderRadius: AppRadius.full,
        border: Border.all(
          color: AppSurfaces.borderColor(scheme, brightness),
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelMedium?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
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

class _DailyWeatherForecast {
  final DateTime date;
  final String label;
  final String weekdayLabel;
  final int? weatherCode;
  final String summary;
  final double? temperatureMax;
  final double? temperatureMin;
  final double? precipitationSum;
  final double? precipitationProbabilityMax;
  final double? windSpeedMax;
  final double? pm10;
  final double? pm25;
  final double? uvIndexMax;
  final _ForecastMomentPreview? morningForecast;
  final _ForecastMomentPreview? eveningForecast;
  final List<_ForecastMomentPreview> hourlyForecasts;
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
    this.precipitationProbabilityMax,
    this.windSpeedMax,
    this.pm10,
    this.pm25,
    this.uvIndexMax,
    this.morningForecast,
    this.eveningForecast,
    this.hourlyForecasts = const <_ForecastMomentPreview>[],
    this.hourlyPrecipitations = const <_HourlyPrecipitationEntry>[],
  });
}

class _ForecastMomentPreview {
  final DateTime time;
  final double? temperature;
  final int? weatherCode;
  final double? precipitation;
  final double? precipitationProbability;
  final double? windSpeed;

  const _ForecastMomentPreview({
    required this.time,
    this.temperature,
    this.weatherCode,
    this.precipitation,
    this.precipitationProbability,
    this.windSpeed,
  });
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
