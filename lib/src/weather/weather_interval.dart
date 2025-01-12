import 'units/humidity.dart';
import 'units/latitude.dart';
import 'units/longitude.dart';
import 'units/pressure.dart';
import 'units/speed.dart';
import 'units/tempurature.dart';
import 'units/wind_direction.dart';
import 'weather_interval_type.dart';

/// Represents a weather interval, which can be a forecast or a historic observation.
abstract class WeatherInterval {
  /// The type of interval, e.g., FORECAST or OBSERVATION.
  WeatherIntervalType get weatherIntervalType;

  /// The air temperature.
  Temperature? get temperature;

  /// The apparent temperature, sometimes referred to as the 'feels like' temperature.
  Temperature? get apparentTemperature;

  /// Rainfall in millimeters during this interval.
  int? get rainFall;

  /// The average pressure during the interval.
  Pressure? get pressure;

  /// The average humidity during the interval.
  Humidity? get humidity;

  /// The average wind speed during the interval.
  Speed? get windSpeed;

  /// The latitude of the location.
  Latitude? get latitude;

  /// The longitude of the location.
  Longitude? get longitude;

  /// The average wind direction during the interval.
  WindDirection? get windDirection;

  /// The start of the interval.
  DateTime? get startOfInterval;

  /// The end of the interval.
  DateTime? get endOfInterval;

  /// The duration of the interval.
  Duration? get intervalDuration;
}
