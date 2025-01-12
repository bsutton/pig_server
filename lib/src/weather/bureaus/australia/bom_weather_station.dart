import 'dart:convert';
import 'dart:io';

import '../../../util/irrigation_exception.dart';
import '../../weather_forecast.dart';
import '../weather_station.dart';
import 'bom_observations.dart';

/// Represents BOM weather stations with observation and forecast capabilities.
enum BOMWeatherStation implements WeatherStation {
  viewBank(
    identifier: 'IDCJAC0009',
    observationSource: 'http://www.bom.gov.au/fwo/IDV60801/IDV60801.95874.json',
    forecastSource: '',
  );

  final String identifier;
  final Uri observationSource;
  final Uri forecastSource;

  const BOMWeatherStation({
    required this.identifier,
    required String observationSource,
    required String forecastSource,
  })  : observationSource = Uri.parse(observationSource),
        forecastSource = Uri.parse(forecastSource);

  @override
  WeatherForecast fetchForecast(DateTime date) {
    // Placeholder: Implement actual forecast fetching logic here
    return WeatherForecast();
  }

  /// Fetches observations for the given [date].
  Future<BOMObservations> fetchObservations(DateTime date) async {
    try {
      // Download the observation data
      final response = await HttpClient()
          .getUrl(observationSource)
          .then((request) => request.close());

      final result = await response.transform(utf8.decoder).join();
      print('Raw JSON data: $result');

      // Parse JSON data
      final Map<String, dynamic> jsonData = jsonDecode(result);
      final jsonWeatherStationData = JSONWeatherStationData.fromJson(jsonData);

      return BOMObservations(jsonWeatherStationData.observations);
    } on IOException catch (e) {
      throw IrrigationException(e);
    } catch (e) {
      throw IrrigationException(Exception('Unexpected error: $e'));
    }
  }
}
