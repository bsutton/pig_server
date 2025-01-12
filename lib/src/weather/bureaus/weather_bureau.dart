import 'weather_station.dart';

/// Interface representing a weather bureau.
abstract class WeatherBureau {
  /// Sets the default weather station.
  void setDefaultStation(WeatherStation station);

  /// Returns the name of the country the bureau operates in.
  String get countryName;

  /// Returns a list of weather stations managed by the bureau.
  List<WeatherStation> get stations;
}
