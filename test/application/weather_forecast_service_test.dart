import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/application/weather_forecast_service.dart';

void main() {
  test(
    'buildForecastUri uses nearest cell selection for stable local temps',
    () {
      final uri = WeatherForecastService.buildForecastUri(
        latitude: 37.5665,
        longitude: 126.9780,
        current: const <String>['temperature_2m', 'weather_code'],
        daily: const <String>['temperature_2m_max'],
        forecastDays: 7,
      );

      expect(uri.host, 'api.open-meteo.com');
      expect(uri.path, '/v1/forecast');
      expect(uri.queryParameters['cell_selection'], 'nearest');
      expect(uri.queryParameters['current'], 'temperature_2m,weather_code');
      expect(uri.queryParameters['daily'], 'temperature_2m_max');
      expect(uri.queryParameters['forecast_days'], '7');
    },
  );
}
