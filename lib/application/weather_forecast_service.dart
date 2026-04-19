class WeatherForecastService {
  const WeatherForecastService._();

  static Uri buildForecastUri({
    required double latitude,
    required double longitude,
    required Iterable<String> current,
    Iterable<String> hourly = const <String>[],
    Iterable<String> daily = const <String>[],
    int? forecastDays,
  }) {
    final queryParameters = <String, String>{
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      if (current.isNotEmpty) 'current': current.join(','),
      if (hourly.isNotEmpty) 'hourly': hourly.join(','),
      if (daily.isNotEmpty) 'daily': daily.join(','),
      if (forecastDays != null) 'forecast_days': '$forecastDays',
      'timezone': 'auto',
      // Use the nearest weather grid cell so temperature does not drift toward
      // a cooler land/elevation-adjusted cell around the player.
      'cell_selection': 'nearest',
    };
    return Uri.https('api.open-meteo.com', '/v1/forecast', queryParameters);
  }
}
