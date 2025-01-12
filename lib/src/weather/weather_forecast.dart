import 'weather_interval.dart';

/// Represents a weather forecast containing multiple intervals.
abstract class WeatherForecast {
  /// Returns a list of weather intervals.
  List<WeatherInterval> getIntervals();
}
