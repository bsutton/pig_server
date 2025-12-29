// overview_handler.dart
import 'dart:convert';
import 'dart:math';

import 'package:pig_common/pig_common.dart';
import 'package:shelf/shelf.dart';

import '../../config.dart';
import '../../database/dao/dao_endpoint.dart';
import '../../database/dao/dao_garden_bed.dart';
import '../../database/dao/dao_history.dart';
import '../../logger.dart';
import '../../weather/bom_v1_api.dart';
import '../../weather/bureaus/australia/bom_observations.dart';
import '../../weather/bureaus/australia/bom_weather_station.dart';
import '../../weather/bureaus/weather_bureaus.dart';

/// Returns data needed by the Overview screen:
/// - do we have any endpoints? do we have any garden beds?
/// - forecast data (optional placeholders for this example)
/// - last 5 watering events
///
/// POST /api/overview
/// Request: {}
/// Response: {
///   "gardenBedsCount": 3,
///   "endpointsCount": 2,
///   "temp": 21,
///   "forecastHigh": 25,
///   "forecastLow": 12,
///   "rain24": 4,
///   "rain7days": 21,
///   "lastWateringEvents": [
///     {
///       "start": "2023-09-18T15:00:00.000Z",
///       "durationMinutes": 10,
///       "gardenBedName": "Bed 1"
///     },
///     ...
///   ]
/// }
Future<Response> handleOverview(Request request) async {
  try {
    // If you have query params, parse them. Otherwise no body needed.
    final daoGardenBed = DaoGardenBed();
    final daoEndPoint = DaoEndPoint();
    final daoHistory = DaoHistory();

    final beds = await daoGardenBed.getAll();
    final endpoints = await daoEndPoint.getAll();

    // get last 5 watering events from history
    final histories = await daoHistory.getAll();
    // sort by event_start descending or filter in your actual query
    histories.sort((a, b) => b.eventStart.compareTo(a.eventStart));
    final last5 = histories.take(5).toList();

    final weather = await _fetchWeatherSnapshot();
    final currentTemp = weather?.currentTemp ?? 0.0;
    final forecastHigh = weather?.forecastHigh ?? 0.0;
    final forecastLow = weather?.forecastLow ?? 0.0;
    final rain24 = weather?.rain24 ?? 0.0;
    final rain7days = weather?.rain7days ?? 0.0;
    final rainForecastNext3Days =
        weather?.rainForecastNext3Days ?? <WeatherDayForecastData>[];
    final weatherNames = _resolveWeatherNames(Config());

    // Convert histories to JSON
    final eventsJson = <Map<String, dynamic>>[];

    for (final last in last5) {
      final bed = await DaoGardenBed().getById(last.gardenFeatureId);
      if (bed == null) {
        continue;
      }
      eventsJson.add({
        'start': last.eventStart.toIso8601String(),
        'durationMinutes': last.eventDuration?.inMinutes ?? 0,
        'gardenBedName': bed.name,
      });
    }

    final responseMap = {
      'gardenBedsCount': beds.length,
      'endpointsCount': endpoints.length,
      'temp': currentTemp,
      'forecastHigh': forecastHigh,
      'forecastLow': forecastLow,
      'rain24': rain24,
      'rain7days': rain7days,
      'weatherBureauName': weatherNames.bureauName,
      'weatherStationName': weatherNames.stationName,
      'lastWateringEvents': eventsJson,
      'rainForecastNext3Days':
          rainForecastNext3Days.map((e) => e.toJson()).toList(),
    };

    return Response.ok(jsonEncode(responseMap),
        headers: {'Content-Type': 'application/json'});
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode({'error': e.toString()}),
      headers: {'Content-Type': 'application/json'},
    );
  }
}

class _WeatherSnapshot {
  _WeatherSnapshot({
    required this.currentTemp,
    required this.forecastHigh,
    required this.forecastLow,
    required this.rain24,
    required this.rain7days,
    required this.rainForecastNext3Days,
  });

  final double currentTemp;
  final double forecastHigh;
  final double forecastLow;
  final double rain24;
  final double rain7days;
  final List<WeatherDayForecastData> rainForecastNext3Days;
}

({String bureauName, String stationName}) _resolveWeatherNames(Config config) {
  final geohash = config.weatherGeohash ?? '';
  if (geohash.isEmpty) {
    return (bureauName: '', stationName: '');
  }

  if (geohash.startsWith('station:')) {
    final parts = geohash.split(':');
    final bureauId = parts.length >= 3 ? int.tryParse(parts[1]) : 1;
    final stationId =
        parts.length >= 3 ? parts[2] : geohash.substring('station:'.length);
    return _stationNamesFor(bureauId, stationId, config);
  }

  return (
    bureauName: _bureauNameFor(1),
    stationName: config.weatherLocationName ?? '',
  );
}

({String bureauName, String stationName}) _stationNamesFor(
  int? bureauId,
  String stationId,
  Config config,
) {
  final id = bureauId ?? 1;
  final bureauName = _bureauNameFor(id);
  final stationName =
      _stationNameFor(id, stationId) ?? config.weatherLocationName ?? '';
  return (bureauName: bureauName, stationName: stationName);
}

String _bureauNameFor(int bureauId) {
  for (final bureau in WeatherBureaus.getBureaus()) {
    if (bureau.id == bureauId) {
      return bureau.countryName;
    }
  }
  return '';
}

String? _stationNameFor(int bureauId, String stationId) {
  for (final bureau in WeatherBureaus.getBureaus()) {
    if (bureau.id != bureauId) {
      continue;
    }
    for (final station in bureau.stations) {
      if (station.stationId == stationId) {
        return station.name;
      }
    }
  }
  if (bureauId == 1) {
    for (final station in BOMWeatherStation.values) {
      if (station.identifier == stationId) {
        return station.displayName;
      }
    }
  }
  return null;
}

Future<_WeatherSnapshot?> _fetchWeatherSnapshot() async {
  try {
    final config = Config();
    final geohash = config.weatherGeohash;
    if (geohash == null || geohash.isEmpty) {
      return null;
    }

    if (geohash.startsWith('station:')) {
      final parts = geohash.split(':');
      final bureauId = parts.length >= 3 ? int.tryParse(parts[1]) : 1;
      final stationId =
          parts.length >= 3 ? parts[2] : geohash.substring('station:'.length);
      if (bureauId == null || stationId.isEmpty) {
        return null;
      }
      final station = _stationById(bureauId, stationId);
      if (station == null) {
        return null;
      }
      final observations = await station.fetchObservations(DateTime.now());
      // Legacy station forecasts use the BOM FTP feed. Avoid it and return
      // observations only; the BOM v1 geohash path provides forecasts.
      return _fromStation(observations, <WeatherDayForecastData>[]);
    }

    final api = BomV1Api();
    final observations = await api.observations(geohash);
    final daily = await api.forecastsDaily(geohash);
    final rain24 = await api.forecastRain(geohash: geohash, period: '24h');
    final rain7d = await api.forecastRain(geohash: geohash, period: '7d');

    return _fromBomV1(
      observations: observations,
      daily: daily,
      rain24: rain24,
      rain7d: rain7d,
    );
  } catch (e, st) {
    qlog('Weather fetch failed: $e, $st');
    return null;
  }
}

BOMWeatherStation? _stationById(int bureauId, String id) {
  if (bureauId != 1) {
    return null;
  }
  for (final station in BOMWeatherStation.values) {
    if (station.identifier == id) {
      return station;
    }
  }
  return null;
}

_WeatherSnapshot? _fromStation(
  BOMObservations observations,
  List<WeatherDayForecastData> forecast,
) {
  final data = observations.observations.observations;
  if (data.isEmpty) {
    return null;
  }
  final first = data.first;
  final currentTemp = first.airTemp?.temperature.toDecimal().toDouble() ?? 0.0;
  final temps = forecast.isEmpty
      ? [currentTemp]
      : forecast.expand((day) => [day.minTempC, day.maxTempC]).toList();
  final forecastHigh = temps.reduce(max);
  final forecastLow = temps.reduce(min);
  return _WeatherSnapshot(
    currentTemp: currentTemp,
    forecastHigh: forecastHigh,
    forecastLow: forecastLow,
    rain24: 0,
    rain7days: 0,
    rainForecastNext3Days: forecast,
  );
}

_WeatherSnapshot? _fromBomV1({
  required Map<String, dynamic>? observations,
  required List<Map<String, dynamic>> daily,
  required Map<String, dynamic>? rain24,
  required Map<String, dynamic>? rain7d,
}) {
  final currentTemp = _firstNum(observations, ['temp', 'temp_now', 'temp_c']) ??
      _firstNum(observations, ['air_temp']) ??
      0.0;

  final forecast = _buildForecast(daily).take(3).toList();

  final forecastHigh = forecast.isEmpty
      ? currentTemp
      : forecast.map((e) => e.maxTempC).reduce(max);
  final forecastLow = forecast.isEmpty
      ? currentTemp
      : forecast.map((e) => e.minTempC).reduce(min);

  final rain24Total = _extractRainTotal(rain24) ?? 0.0;
  final rain7dTotal = _extractRainTotal(rain7d) ?? 0.0;

  return _WeatherSnapshot(
    currentTemp: currentTemp,
    forecastHigh: forecastHigh,
    forecastLow: forecastLow,
    rain24: rain24Total,
    rain7days: rain7dTotal,
    rainForecastNext3Days: forecast,
  );
}

List<WeatherDayForecastData> _buildForecast(List<Map<String, dynamic>> daily) =>
    daily.map((entry) {
      final date =
          entry['date']?.toString() ?? entry['local_date']?.toString() ?? '';
      final minTemp =
          _firstNum(entry, ['min_temp', 'temp_min', 'temp_low']) ?? 0.0;
      final maxTemp =
          _firstNum(entry, ['max_temp', 'temp_max', 'temp_high']) ?? 0.0;

      final rain = entry['rain'] as Map<String, dynamic>?;
      final rainChance = _firstNum(rain, ['chance', 'chance_percent']) ?? 0.0;
      final amount = rain?['amount'] as Map<String, dynamic>?;
      final rainMin = _firstNum(amount, ['min']) ?? 0.0;
      final rainMax = _firstNum(amount, ['max']) ?? 0.0;

      return WeatherDayForecastData(
        date: date,
        minTempC: minTemp,
        maxTempC: maxTemp,
        rainChancePercent: rainChance,
        rainMinMm: rainMin,
        rainMaxMm: rainMax,
      );
    }).toList();

double? _extractRainTotal(Map<String, dynamic>? rainData) {
  if (rainData == null) {
    return null;
  }
  return _firstNum(rainData, [
        'total',
        'rain_mm',
        'rain_mm_total',
        'rainfall',
        'value',
      ]) ??
      _firstNum(rainData['amount'] as Map<String, dynamic>?, ['max', 'min']);
}

double? _firstNum(Map<String, dynamic>? map, List<String> keys) {
  if (map == null) {
    return null;
  }
  for (final key in keys) {
    final value = map[key];
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }
  }
  return null;
}
