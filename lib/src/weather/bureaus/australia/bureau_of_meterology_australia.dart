// ignore_for_file: unused_element

import 'package:intl/intl.dart';
import 'package:pig_common/pig_common.dart';

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
import 'bom_weather_forecast.dart';
import 'bom_weather_station.dart';

/// Implementation for access to the Australian Bureau of Meteorology.
class BureauOfMeterologyAustralia implements WeatherBureau {
  String? _defaultStationId;

  static final _dateFormat = DateFormat('yyyyMMddHHmmss');

  @override
  void setDefaultStation(WeatherStationData station) {
    _defaultStationId = station.stationId;
  }

  @override
  String get countryName => 'Australia';

  @override
  int get id => 1;

  @override
  List<WeatherStationData> get stations => BOMWeatherStation.values
      .map(
        (station) => WeatherStationData(
          bureauId: id,
          stationId: station.identifier,
          name: station.displayName,
        ),
      )
      .toList();

  WeatherForecast fetchForecast(DateTime date) =>
      _stationById(_defaultStationId)?.fetchForecast(date) ??
      BomWeatherForecast();

  BOMWeatherStation? _stationById(String? stationId) {
    if (stationId == null || stationId.isEmpty) {
      return null;
    }
    for (final station in BOMWeatherStation.values) {
      if (station.identifier == stationId) {
        return station;
      }
    }
    return null;
  }

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
