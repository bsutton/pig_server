import 'dart:convert';

import 'package:pig_common/pig_common.dart';
import 'package:shelf/shelf.dart';
import '../../config.dart';
import '../../logger.dart';
import '../../weather/bom_v1_api.dart';
import '../../weather/bureaus/weather_bureaus.dart';

Future<Response> handleWeatherSearch(Request request) async {
  try {
    final bodyStr = await request.readAsString();
    final body = jsonDecode(bodyStr) as Map<String, dynamic>? ?? {};
    final query = body['query']?.toString().trim();
    if (query == null || query.isEmpty) {
      return Response.badRequest(
        body: jsonEncode({'error': 'Missing query'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final results = await BomV1Api().searchLocations(query);
    final data = await _filterLocationsWithData(results);
    final stationFallbacks =
        data.isEmpty ? _stationMatches(query) : <BomLocation>[];

    if (data.isEmpty) {
      qlog('No BOM data available for search "$query".');
    }

    final payload = [
      ...data,
      ...stationFallbacks,
    ]
        .map((loc) => WeatherLocationData(
              id: loc.id,
              name: loc.name,
              state: loc.state,
              geohash: loc.geohash,
            ))
        .toList();

    return Response.ok(
      jsonEncode({'locations': payload.map((e) => e.toJson()).toList()}),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode({'error': e.toString()}),
      headers: {'Content-Type': 'application/json'},
    );
  }
}

Future<List<BomLocation>> _filterLocationsWithData(
  List<BomLocation> locations,
) async {
  if (locations.isEmpty) {
    return [];
  }
  const maxCandidates = 12;
  const maxResults = 8;
  final api = BomV1Api();
  final filtered = <BomLocation>[];
  for (final location in locations.take(maxCandidates)) {
    final hasData = await api.hasData(location.geohash);
    if (hasData) {
      filtered.add(location);
      if (filtered.length >= maxResults) {
        break;
      }
    }
  }
  return filtered;
}

List<BomLocation> _stationMatches(String query) {
  final needle = query.toLowerCase();
  final stations = [
    for (final bureau in WeatherBureaus.getBureaus()) ...bureau.stations,
  ];
  final matches = stations
      .where((station) => station.name.toLowerCase().contains(needle))
      .toList();
  final candidates = matches.isEmpty ? stations : matches;
  return candidates
      .map((station) => BomLocation(
            id: station.stationId,
            name: station.name,
            state: '',
            geohash: 'station:${station.bureauId}:${station.stationId}',
          ))
      .toList();
}

Future<Response> handleWeatherLocation(Request request) async {
  try {
    final bodyStr = await request.readAsString();
    final body = jsonDecode(bodyStr) as Map<String, dynamic>? ?? {};
    final geohash = body['geohash']?.toString();
    final name = body['name']?.toString();
    final state = body['state']?.toString();
    final id = body['id']?.toString();
    final query = body['query']?.toString();

    if (geohash != null && geohash.isNotEmpty) {
      final config = Config()
        ..weatherGeohash = geohash
        ..weatherLocationId = id
        ..weatherLocationName = name
        ..weatherLocationState = state
        ..weatherLocationQuery = query;
      await config.save();
    }

    final config = Config();
    final current = WeatherLocationData(
      id: config.weatherLocationId ?? '',
      name: config.weatherLocationName ?? '',
      state: config.weatherLocationState ?? '',
      geohash: config.weatherGeohash ?? '',
    );

    return Response.ok(
      jsonEncode(current.toJson()),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode({'error': e.toString()}),
      headers: {'Content-Type': 'application/json'},
    );
  }
}
