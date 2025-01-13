// ignore_for_file: unused_element

import 'package:intl/intl.dart';

import '../../units/humidity.dart';
import '../../units/latitude.dart';
import '../../units/longitude.dart';
import '../../units/millimetres.dart';
import '../../units/pressure.dart';
import '../../units/speed.dart';
import '../../units/tempurature.dart';
import '../../units/wind_direction.dart';
import '../../weather_forecast.dart';
import '../weather_bureau.dart';
import '../weather_station.dart';
import 'bom_weather_forecast.dart';
import 'bom_weather_station.dart';

/// Implementation for access to the Australian Bureau of Meteorology.
class BureauOfMeterologyAustralia implements WeatherBureau {
  WeatherStation? _defaultStation;

  static final DateFormat _dateFormat = DateFormat('yyyyMMddHHmmss');

  @override
  void setDefaultStation(WeatherStation station) {
    _defaultStation = station;
  }

  @override
  String get countryName => 'Australia';

  @override
  List<WeatherStation> get stations => BOMWeatherStation.values;

  WeatherForecast fetchForecast(DateTime date) =>
      _defaultStation?.fetchForecast(date) ?? BomWeatherForecast();

  /// Deserialization helpers to parse JSON data.
  static T? _parseJsonField<T>(dynamic value, T Function(String) converter) {
    if (value is String) {
      return converter(value);
    }
    return null;
  }

  static DateTime? _parseDateTime(String value) => _dateFormat.parse(value);

  static Temperature? _parseTemperature(String value) => Temperature(value);

  static Humidity? _parseHumidity(String value) => Humidity(value);

  static Pressure? _parsePressure(String value) => Pressure(value);

  static Speed? _parseSpeed(String value) => Speed(value);

  static WindDirection? _parseWindDirection(String value) =>
      WindDirection.fromAbbreviation(value);

  static Latitude? _parseLatitude(String value) => Latitude(value);

  static Longitude? _parseLongitude(String value) => Longitude(value);

  static Millimetres? _parseMillimetres(String value) => Millimetres(value);

  /// Parses JSON into specific types.
  static T fromJson<T>(dynamic json, T Function(dynamic) factory) {
    if (json == null) {
      throw ArgumentError('JSON cannot be null');
    }
    return factory(json);
  }
}
