import 'package:pig_common/pig_common.dart';

/// Interface representing a weather bureau.
abstract class WeatherBureau {
  /// Sets the default weather station.
  void setDefaultStation(WeatherStationData station);

  /// Returns the name of the country the bureau operates in.
  String get countryName;

  /// Returns a unique identifier for the bureau.
  int get id;

  /// Returns a list of weather stations managed by the bureau.
  List<WeatherStationData> get stations;
}
