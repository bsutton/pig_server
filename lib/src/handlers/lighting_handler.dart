// lighting_handlers.dart
import 'dart:convert';

import 'package:pig_common/pig_common.dart';
import 'package:shelf/shelf.dart';

import '../controllers/timer_control.dart';
import '../database/dao/dao_history.dart';
import '../database/dao/dao_lighting.dart';

/// POST /api/lighting/list
///
/// Request body: {}
/// Response: { "lights": [ { "id": 123, "name": "...", "isOn": true,
/// "lastOnDate": "...", "timerRunning": false, "timerRemainingSeconds": 0 },
///  ... ] }
Future<Response> handleLightingList(Request request) async {
  try {
    // No request body needed in this example, or add filter parameters
    //if needed
    final lights = await DaoLighting().getAll();

    final result = <Map<String, dynamic>>[];
    for (final light in lights) {
      final timer = TimerControl.getTimer(light);
      final isTimerRunning = timer?.isTimerRunning() ?? false;
      final remaining = isTimerRunning ? timer!.timeRemaining().inSeconds : 0;

      result.add({
        'id': light.id,
        'name': light.name, // Or however you reference the name
        'isOn': DaoLighting().isOn(light),
        'lastOnDate': _getLastActivation(light),
        'timerRunning': isTimerRunning,
        'timerRemainingSeconds': remaining,
        // ... add more fields as needed
      });
    }

    return Response.ok(
      jsonEncode({'lights': result}),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}));
  }
}

Future<DateTime?> _getLastActivation(Lighting light) async =>
    (await DaoHistory().getLastRecord(light))?.eventStart;

/// POST /api/lighting/toggle
///
/// Request body: { "lightId": 123, "turnOn": true,
///   "durationSeconds": 1800 (optional) }
/// Response: { "result": "OK", "timerStarted": true,
///   "timerRemainingSeconds": 1800 }
Future<Response> handleLightingToggle(Request request) async {
  try {
    final bodyStr = await request.readAsString();
    final body = jsonDecode(bodyStr) as Map<String, dynamic>;
    final lightId = body['lightId'] as int?;
    final turnOn = body['turnOn'] as bool?;
    final durationSeconds = body['durationSeconds'] as int?; // optional

    if (lightId == null || turnOn == null) {
      return Response.badRequest(
        body: jsonEncode({'error': 'Missing lightId or turnOn'}),
      );
    }

    final lighting = await DaoLighting().getById(lightId);
    if (lighting == null) {
      return Response.notFound(jsonEncode({'error': 'Light not found'}));
    }

    if (turnOn) {
      // Possibly start a timer
      if (durationSeconds != null && durationSeconds > 0) {
        // Start a timed run
        await TimerControl.startTimer(
          lighting,
          'Lighting Timer',
          Duration(seconds: durationSeconds),
          (feature) async {
            // Callback when finished
            // your logic for turning the light off
            await DaoLighting().softOff(feature as Lighting);
            return;
          },
        );
        // turn the light on
        await DaoLighting().softOn(lighting);
        return Response.ok(
          jsonEncode({
            'result': 'OK',
            'timerStarted': true,
            'timerRemainingSeconds': durationSeconds,
          }),
        );
      } else {
        // Just turn on (no timer)
        await DaoLighting().softOn(lighting);
        return Response.ok(jsonEncode({'result': 'OK', 'timerStarted': false}));
      }
    } else {
      // turn off
      TimerControl.removeTimer(lighting);
      await DaoLighting().softOff(lighting);
      return Response.ok(jsonEncode({'result': 'OK'}));
    }
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode({'error': e.toString()}),
    );
  }
}
