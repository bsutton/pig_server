
import 'weather_interval.dart';

/// Represents weather history containing multiple intervals.
abstract class WeatherHistory {
  /// Returns a list of weather intervals.
  List<WeatherInterval> getIntervals();
}
