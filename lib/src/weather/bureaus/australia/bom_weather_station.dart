import 'dart:convert';
import 'dart:io';

import 'package:pig_common/pig_common.dart';
import 'package:xml/xml.dart';

import '../../../util/irrigation_exception.dart';
import '../../weather_forecast.dart';
import 'bom_observations.dart';
import 'bom_weather_forecast.dart';
import 'json/json_weather_stastion_data.dart';

/// Server-only fetch helpers for BOM weather stations.
extension BOMWeatherStationFetch on BOMWeatherStation {
  /// Placeholder: Implement actual forecast fetching logic here.
  WeatherForecast fetchForecast(DateTime _) => BomWeatherForecast();

  /// Fetches observations for this station.
  Future<BOMObservations> fetchObservations(DateTime _) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      // Download the observation data.
      final request = await client.getUrl(Uri.parse(observationSource));
      request.headers.set(
        HttpHeaders.userAgentHeader,
        'pigation-server/1.0',
      );
      final response = await request.close();
      if (response.statusCode >= 400) {
        final body = await response.transform(utf8.decoder).join();
        throw HttpException(
            '''
BOM request failed: ${response.statusCode} ${response.reasonPhrase} $body''');
      }

      final result = await response.transform(utf8.decoder).join();

      // Parse JSON data.
      final jsonData = jsonDecode(result) as Map<String, dynamic>;
      final jsonWeatherStationData = JSONWeatherStationData.fromJson(jsonData);

      return BOMObservations(jsonWeatherStationData.observations);
    } on IOException catch (e) {
      throw IrrigationException(e);
    } catch (e) {
      throw IrrigationException(Exception('Unexpected error: $e'));
    } finally {
      client.close(force: true);
    }
  }

  /// Fetches daily forecast data for this station.
  Future<List<WeatherDayForecastData>> fetchDailyForecast() async {
    if (forecastSource.isEmpty || forecastLocationName.isEmpty) {
      return <WeatherDayForecastData>[];
    }

    final body = await _downloadText(forecastSource);
    return _parseForecastXml(
      body,
      locationName: forecastLocationName,
    );
  }
}

Future<String> _downloadText(String url) async {
  final client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 10);
  try {
    final request = await client.getUrl(Uri.parse(url));
    request.headers.set(
      HttpHeaders.userAgentHeader,
      'pigation-server/1.0',
    );
    final response = await request.close();
    if (response.statusCode >= 400) {
      final body = await response.transform(utf8.decoder).join();
      throw HttpException(
          '''
BOM request failed: ${response.statusCode} ${response.reasonPhrase} $body''');
    }
    return await response.transform(utf8.decoder).join();
  } on IOException catch (e) {
    throw IrrigationException(e);
  } catch (e) {
    throw IrrigationException(Exception('Unexpected error: $e'));
  } finally {
    client.close(force: true);
  }
}

List<WeatherDayForecastData> _parseForecastXml(
  String xmlBody, {
  required String locationName,
}) {
  final document = XmlDocument.parse(xmlBody);
  final forecasts = document.findAllElements('forecast');
  if (forecasts.isEmpty) {
    return <WeatherDayForecastData>[];
  }
  final forecast = forecasts.first;

  final locations = forecast
      .findElements('area')
      .where((area) => area.getAttribute('type') == 'location')
      .toList();
  if (locations.isEmpty) {
    return <WeatherDayForecastData>[];
  }

  final needle = locationName.toLowerCase();
  final selected = locations.firstWhere(
    (area) => (area.getAttribute('description') ?? '')
        .toLowerCase()
        .contains(needle),
    orElse: () => locations.first,
  );

  final periods = selected.findElements('forecast-period').toList();
  if (periods.isEmpty) {
    return <WeatherDayForecastData>[];
  }

  final results = <WeatherDayForecastData>[];
  for (final period in periods) {
    if (results.length >= 3) {
      break;
    }
    final date = (period.getAttribute('start-time-local') ?? '')
        .split('T')
        .first;
    final minTemp = _elementValue(period, 'air_temperature_minimum');
    final maxTemp = _elementValue(period, 'air_temperature_maximum');
    final rainRange = _elementText(period, 'precipitation_range');
    final range = _parseRange(rainRange);
    final rainMin = range.min;
    final rainMax = range.max;
    final rainChance = _parsePercent(
      _textValue(period, 'probability_of_precipitation'),
    );

    results.add(
      WeatherDayForecastData(
        date: date,
        minTempC: minTemp,
        maxTempC: maxTemp,
        rainChancePercent: rainChance,
        rainMinMm: rainMin,
        rainMaxMm: rainMax,
      ),
    );
  }

  return results;
}

double _elementValue(XmlElement period, String type) {
  final element = period
      .findElements('element')
      .firstWhere(
        (node) => node.getAttribute('type') == type,
        orElse: () => XmlElement(XmlName('element')),
      );
  final value = element.innerText.trim();
  return double.tryParse(value) ?? 0.0;
}

String _elementText(XmlElement period, String type) {
  final element = period
      .findElements('element')
      .firstWhere(
        (node) => node.getAttribute('type') == type,
        orElse: () => XmlElement(XmlName('element')),
      );
  return element.innerText.trim();
}

String _textValue(XmlElement period, String type) {
  final node = period
      .findElements('text')
      .firstWhere(
        (text) => text.getAttribute('type') == type,
        orElse: () => XmlElement(XmlName('text')),
      );
  return node.innerText.trim();
}

double _parsePercent(String value) {
  final number =
      RegExp(r'-?\d+(?:\.\d+)?').firstMatch(value)?.group(0);
  return number == null ? 0.0 : double.tryParse(number) ?? 0.0;
}

({double min, double max}) _parseRange(String value) {
  final matches = RegExp(r'-?\d+(?:\.\d+)?')
      .allMatches(value)
      .toList();
  if (matches.isEmpty) {
    return (min: 0.0, max: 0.0);
  }
  final numbers = matches
      .map((match) => double.tryParse(match.group(0) ?? '') ?? 0.0)
      .toList();
  if (numbers.length == 1) {
    return (min: numbers.first, max: numbers.first);
  }
  return (min: numbers.first, max: numbers[1]);
}
