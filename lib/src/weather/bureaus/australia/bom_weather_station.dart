import 'dart:convert';
import 'dart:io';

import '../../../util/irrigation_exception.dart';
import '../../weather_forecast.dart';
import '../weather_station.dart';
import 'bom_observations.dart';
import 'bom_weather_forecast.dart';
import 'json/json_weather_stastion_data.dart';

/// Represents BOM weather stations with observation and forecast capabilities.
enum BOMWeatherStation implements WeatherStation {
  viewBank(
    identifier: 'IDCJAC0009',
    observationSource: 'http://www.bom.gov.au/fwo/IDV60801/IDV60801.95874.json',
    forecastSource: '',
  );

  final String identifier;
  final String observationSource;
  final String forecastSource;

  const BOMWeatherStation({
    required this.identifier,
    required this.observationSource,
    required this.forecastSource,
  });

  @override
  // Placeholder: Implement actual forecast fetching logic here
  WeatherForecast fetchForecast(DateTime date) => BomWeatherForecast();

  /// Fetches observations for the given [date].
  Future<BOMObservations> fetchObservations(DateTime date) async {
    try {
      // Download the observation data
      final response = await HttpClient()
          .getUrl(Uri.parse(observationSource))
          .then((request) => request.close());

      final result = await response.transform(utf8.decoder).join();
      print('Raw JSON data: $result');

      // Parse JSON data
      final jsonData = jsonDecode(result) as Map<String, dynamic>;
      final jsonWeatherStationData = JSONWeatherStationData.fromJson(jsonData);

      return BOMObservations(jsonWeatherStationData.observations);
    } on IOException catch (e) {
      throw IrrigationException(e);
    } catch (e) {
      throw IrrigationException(Exception('Unexpected error: $e'));
    }
  }
}
