import 'json_observations.dart';

class JSONWeatherStationData {
  final JSONObservations observations;

  JSONWeatherStationData({required this.observations});

  factory JSONWeatherStationData.fromJson(Map<String, dynamic> json) =>
      JSONWeatherStationData(
        observations: JSONObservations.fromJson(
            json['observations'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        'observations': observations.toJson(),
      };

  @override
  String toString() => 'JSONWeatherStationData { observations: $observations }';
}
