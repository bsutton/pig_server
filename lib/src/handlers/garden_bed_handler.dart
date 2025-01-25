// garden_bed_handlers.dart
import 'dart:convert';

import 'package:pig_common/pig_common.dart';
import 'package:shelf/shelf.dart';
import 'package:strings/strings.dart';

import '../controllers/timer_control.dart';
import '../database/dao/dao_endpoint.dart';
import '../database/dao/dao_garden_bed.dart';
import '../database/dao/dao_history.dart';

/// POST /api/garden_beds/list
/// Request body: {}
/// Response: {
///   "beds": [
///     {
///       "id": 123,
///       "name": "Tomato Bed",
///       "isOn": true
///     },
///     ...
///   ]
/// }
Future<Response> handleGardenBedList(Request request) async {
  try {
    final daoGardenBed = DaoGardenBed();
    final daoEndPoint = DaoEndPoint();
    final beds = <GardenBedData>[];

    for (final bed in await daoGardenBed.getAll()) {
      final history = await DaoHistory().getMostRecent(bed);
      beds.add(GardenBedData.fromBed(
        bed,
        allowDelete: true,
        isOn: await daoGardenBed.isOn(bed),
        remainingDuration: TimerControl().timeRemaining(bed),
        lastWateringDateTime: history?.eventStart,
        lastWateringDuration: history?.eventDuration?.inSeconds,
      ));
    }
    final valves = await _getValves(daoEndPoint);

    final masterValves = await _getMasterValves(daoEndPoint);

    final bedListData = GardenBedListData(
        beds: beds, valves: valves, masterValves: masterValves);

    return Response.ok(
      jsonEncode(bedListData),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}));
  }
}

/// POST /api/garden_beds/toggle
/// Request body: { "bedId": 123, "turnOn": true }
/// Response: { "result": "OK" }
Future<Response> handleGardenBedToggle(Request request) async {
  try {
    final bodyStr = await request.readAsString();
    final body = jsonDecode(bodyStr) as Map<String, dynamic>;
    final bedId = body['bedId'] as int?;
    final turnOn = body['turnOn'] as bool?;

    if (bedId == null || turnOn == null) {
      return Response.badRequest(
          body: jsonEncode({'error': 'Missing bedId or turnOn'}));
    }

    final daoGardenBed = DaoGardenBed();
    final bed = await daoGardenBed.getById(bedId);
    if (bed == null) {
      return Response.notFound(jsonEncode({'error': 'Garden bed not found'}));
    }

    if (turnOn) {
      await daoGardenBed.softOn(bed);
    } else {
      await daoGardenBed.softOff(bed);
    }

    return Response.ok(jsonEncode({'result': 'OK'}));
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode({'error': e.toString()}),
    );
  }
}

/// POST /api/garden_beds/start_timer
/// Request body: { "bedId": 123, "durationSeconds": 100
///     , "description" : "User triggered" }
/// Response: { "result": "OK" }
Future<Response> handleGardenBedStartTimer(Request request) async {
  try {
    final bodyStr = await request.readAsString();
    final body = jsonDecode(bodyStr) as Map<String, dynamic>;
    final bedId = body['bedId'] as int?;
    final durationInSeconds = body['durationSeconds'] as int?;
    final description = body['description'] as String?;

    if (bedId == null || durationInSeconds == null) {
      return Response.badRequest(
          body: jsonEncode({'error': 'Missing bedId or durationSeconds'}));
    }

    final daoGardenBed = DaoGardenBed();
    final bed = await daoGardenBed.getById(bedId);
    if (bed == null) {
      return Response.notFound(jsonEncode({'error': 'Garden bed not found'}));
    }

    final runTime = Duration(seconds: durationInSeconds);

    await daoGardenBed.runForTime(
        feature: bed, description: description ?? '', runTime: runTime);

    return Response.ok(jsonEncode({'result': 'OK'}));
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode({'error': e.toString()}),
    );
  }
}

/// POST /api/garden_beds/start_timer
/// Request body: { "bedId": 123, "durationSeconds": 100
///     , "description" : "User triggered" }
/// Response: { "result": "OK" }
Future<Response> handleGardenBedStopTimer(Request request) async {
  try {
    final bodyStr = await request.readAsString();
    final body = jsonDecode(bodyStr) as Map<String, dynamic>;
    final bedId = body['bedId'] as int?;

    if (bedId == null) {
      return Response.badRequest(body: jsonEncode({'error': 'Missing bedId'}));
    }

    final daoGardenBed = DaoGardenBed();
    final bed = await daoGardenBed.getById(bedId);
    if (bed == null) {
      return Response.notFound(jsonEncode({'error': 'Garden bed not found'}));
    }

    await daoGardenBed.softOff(bed);

    final existingTimer = TimerControl().getTimer(bed);

    if (TimerControl().isTimerRunning(bed)) {
      final startTime = existingTimer?.startTime ?? DateTime.now();
      await DaoHistory().insert(History.forInsert(
          gardenFeatureId: bedId,
          eventStart: startTime,
          eventDuration: DateTime.now().difference(startTime)));

      TimerControl().stopTimer(bed);
    }

    return Response.ok(jsonEncode({'result': 'OK'}));
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode({'error': e.toString()}),
    );
  }
}

/// POST /garden_bed/edit_data
///
/// Request body: { "gardenBedId": 123? }
/// Response example:
/// {
///   "bed": {
///     "id": 123,
///     "name": "Tomato Bed",
///     "description": "A bed for tomato plants",
///     "valveId": 9,
///     "masterValveId": 10,
///     "allowDelete": true
///   },
///   "valves": [ { "id": 9, "name": "...", "pinNo": 17 }, ... ],
///   "masterValves": [ { "id": 10, "name": "...", "pinNo": 4 }, ... ]
/// }
Future<Response> handleGardenBedEditData(Request request) async {
  try {
    final bodyStr = await request.readAsString();
    final body = jsonDecode(bodyStr) as Map<String, dynamic>? ?? {};

    final gardenBedId = body['gardenBedId'] as int?;
    final daoBed = DaoGardenBed();
    final daoEndPoint = DaoEndPoint();

    final valves = await _getValves(daoEndPoint);

    final masterValves = await _getMasterValves(daoEndPoint);

    /// We always pass the valves even if there is no garden bed
    /// to handle adding new beds.
    var data =
        GardenBedListData(beds: [], valves: valves, masterValves: masterValves);

    // 1) If a gardenBedId is provided, load that bed from the DB
    //    If none is provided, we'll return an empty bed
    if (gardenBedId != null) {
      final bed = await daoBed.getById(gardenBedId);
      if (bed == null) {
        // The bed doesn't exist
        return Response.notFound(jsonEncode({'error': 'Garden bed not found'}));
      }

      // Example: We allow delete if it’s found
      // (You can add more advanced logic if needed.)
      final gardenBedData = GardenBedData(
          id: bed.id,
          name: bed.name,
          description: bed.description,
          valveId: bed.valveId,
          masterValveId: bed.masterValveId,
          allowDelete: true);

      data = GardenBedListData(
          beds: [gardenBedData], valves: valves, masterValves: masterValves);
    }

    return Response.ok(
      jsonEncode(data.toJson()),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode({'error': e.toString()}),
      headers: {'Content-Type': 'application/json'},
    );
  }
}

Future<List<EndPointInfo>> _getMasterValves(DaoEndPoint daoEndPoint) async {
  final masterValves = (await daoEndPoint.getMasterValves())
      .map(EndPointInfo.fromEndPoint)
      .toList();
  return masterValves;
}

Future<List<EndPointInfo>> _getValves(DaoEndPoint daoEndPoint) async {
  final valves = (await daoEndPoint.getAllValves())
      .map(EndPointInfo.fromEndPoint)
      .toList();
  return valves;
}

/// POST /api/garden_beds/save
/// Request body: { "id": 123 (optional), "name": "...", ...}
/// If id is null => insert, else update
/// Response: { "result": "OK", "bedId": 123 }
Future<Response> handleGardenBedSave(Request request) async {
  try {
    final bodyStr = await request.readAsString();
    final body = jsonDecode(bodyStr) as Map<String, dynamic>;

    final bedData = GardenBedData.fromJson(body);

    if (Strings.isBlank(bedData.name)) {
      return Response.badRequest(
          body: jsonEncode({'error': 'GardenBed name is required'}));
    }

    if (bedData.valveId == null) {
      return Response.badRequest(
          body: jsonEncode({'error': 'valveId is required'}));
    }

    final daoGardenBed = DaoGardenBed();
    if (bedData.id == null) {
      // Insert
      final bed = GardenBed.forInsert(
          name: bedData.name!,
          description: bedData.description,
          valveId: bedData.valveId!,
          masterValveId: bedData.masterValveId,
          moistureContent: 0);
      final newBedId = await daoGardenBed.insert(bed);
      return Response.ok(jsonEncode({
        'result': 'OK',
        'bedId': newBedId,
      }));
    } else {
      // Update
      final existingBed = await daoGardenBed.getById(bedData.id);
      if (existingBed == null) {
        return Response.notFound(jsonEncode({'error': 'Garden bed not found'}));
      }
      existingBed
        ..name = bedData.name!
        ..description = bedData.description
        ..valveId = bedData.valveId!
        ..masterValveId = bedData.masterValveId;

      await daoGardenBed.update(existingBed);
      return Response.ok(jsonEncode({
        'result': 'OK',
        'bedId': bedData.id,
      }));
    }
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode({'error': e.toString()}),
    );
  }
}

/// POST /api/garden_beds/delete
/// Request body: { "bedId": 123 }
/// Response: { "result": "OK" }
Future<Response> handleGardenBedDelete(Request request) async {
  try {
    final bodyStr = await request.readAsString();
    final body = jsonDecode(bodyStr) as Map<String, dynamic>;
    final bedId = body['bedId'] as int?;
    if (bedId == null) {
      return Response.badRequest(body: jsonEncode({'error': 'Missing bedId'}));
    }

    final daoGardenBed = DaoGardenBed();
    final bed = await daoGardenBed.getById(bedId);
    if (bed == null) {
      return Response.notFound(jsonEncode({'error': 'Garden bed not found'}));
    }

    await daoGardenBed.delete(bedId);
    return Response.ok(jsonEncode({'result': 'OK'}));
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode({'error': e.toString()}),
    );
  }
}
