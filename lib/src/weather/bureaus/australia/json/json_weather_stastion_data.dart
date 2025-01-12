import 'json_observations.dart';

class JSONWeatherStationData {
  JSONWeatherStationData({required this.observations});

  factory JSONWeatherStationData.fromJson(Map<String, dynamic> json) =>
      JSONWeatherStationData(
        observations: JSONObservations.fromJson(
            json['observations'] as Map<String, dynamic>),
      );
  final JSONObservations observations;

  Map<String, dynamic> toJson() => {
        'observations': observations.toJson(),
      };

  @override
  String toString() => 'JSONWeatherStationData { observations: $observations }';
}
