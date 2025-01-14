// garden_bed_handlers.dart
import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../database/dao/dao_endpoint.dart';
import '../database/dao/dao_garden_bed.dart';
import '../database/entity/endpoint.dart';
import '../database/entity/garden_bed.dart';

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
    final beds = await daoGardenBed.getAll();

    final result = <Map<String, dynamic>>[];
    for (final bed in beds) {
      result.add({
        'id': bed.id,
        'name': bed.name,
        // Let's assume we have a method isOn(bed) or bed.isOn
        'isOn': await daoGardenBed.isOn(bed),
      });
    }

    return Response.ok(
      jsonEncode({'beds': result}),
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

    // We'll build this map to return
    final responseMap = <String, dynamic>{};

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
      final bedJson = {
        'id': bed.id,
        'name': bed.name,
        'description': bed.description,
        'valveId': bed.valveId,
        'masterValveId': bed.masterValveId,
        'allowDelete': true,
      };
      responseMap['bed'] = bedJson;
    } else {
      // Return an empty bed object
      responseMap['bed'] = null;
    }

    // 2) Fetch all valves and masterValves
    final valves = await daoEndPoint.getAllValves(); // Example
    final masterValves = await daoEndPoint.getMasterValves(); // Example

    responseMap['valves'] = valves.map(_endPointToJson).toList();
    responseMap['masterValves'] = masterValves.map(_endPointToJson).toList();

    return Response.ok(
      jsonEncode(responseMap),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode({'error': e.toString()}),
      headers: {'Content-Type': 'application/json'},
    );
  }
}

/// Converts an EndPoint to JSON. Adjust fields to match your usage.
Map<String, dynamic> _endPointToJson(EndPoint endPoint) => {
      'id': endPoint.id,
      'name': endPoint.name, // or simply 'name'
      'pinNo': endPoint.pinNo,
    };

/// POST /api/garden_beds/save
/// Request body: { "id": 123 (optional), "name": "...", ...}
/// If id is null => insert, else update
/// Response: { "result": "OK", "bedId": 123 }
Future<Response> handleGardenBedSave(Request request) async {
  try {
    final bodyStr = await request.readAsString();
    final body = jsonDecode(bodyStr) as Map<String, dynamic>;

    final id = body['id'] as int?;
    final name = body['name'] as String?;
    if (name == null || name.trim().isEmpty) {
      return Response.badRequest(
          body: jsonEncode({'error': 'GardenBed name is required'}));
    }
    final description = body['description'] as String? ?? '';
    final valveId = body['valve_id'] as int?;
    final masterValveId =
        int.tryParse(body['master_valve_id'] as String? ?? '');

    if (valveId == null) {
      return Response.badRequest(
          body: jsonEncode({'error': 'valveId is required'}));
    }

    final daoGardenBed = DaoGardenBed();
    if (id == null) {
      // Insert
      final bed = GardenBed.forInsert(
          name: name,
          description: description,
          valveId: valveId,
          moistureContent: 0);
      final newBedId = await daoGardenBed.insert(bed);
      return Response.ok(jsonEncode({
        'result': 'OK',
        'bedId': newBedId,
      }));
    } else {
      // Update
      final existingBed = await daoGardenBed.getById(id);
      if (existingBed == null) {
        return Response.notFound(jsonEncode({'error': 'Garden bed not found'}));
      }
      existingBed
        ..name = name
        ..description = description
        ..valveId = valveId
        ..masterValveId = masterValveId;

      await daoGardenBed.update(existingBed);
      return Response.ok(jsonEncode({
        'result': 'OK',
        'bedId': id,
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
