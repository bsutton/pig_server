
import '../weather_forecast.dart';

/// Represents a weather station capable of fetching forecasts.
abstract class WeatherStation {
  /// Fetches the weather forecast for the specified [date].
  WeatherForecast fetchForecast(DateTime date);
}
