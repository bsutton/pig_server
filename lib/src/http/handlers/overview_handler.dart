// overview_handler.dart
import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../../database/dao/dao_endpoint.dart';
import '../../database/dao/dao_garden_bed.dart';
import '../../database/dao/dao_history.dart';

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

    // Placeholder weather data
    const currentTemp = 21;
    const forecastHigh = 25;
    const forecastLow = 12;
    const rain24 = 4; // mm in last 24 hrs
    const rain7days = 21; // mm in last 7 days

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
      'lastWateringEvents': eventsJson
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
