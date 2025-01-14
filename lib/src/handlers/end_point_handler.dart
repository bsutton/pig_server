// end_point_handlers.dart
import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../controllers/garden_bed_controller.dart';
import '../database/dao/dao_endpoint.dart';
import '../database/entity/endpoint.dart';
import '../database/types/endpoint_type.dart';
import '../database/types/pin_activation_type.dart';
import '../pi/gpio_manager.dart';
import '../weather/bureaus/weather_bureaus.dart';

/// POST /api/end_point/list
/// Request: {}
/// Response: {
///   "endPoints": [
///     { "id": 1, "name": "Valve 1", "isOn": true },
///     ...
///   ],
///   "weatherBureaus": [ { "id": "...", "countryName": "..." }, ...],
///   "weatherStations": [ ... ]
/// }
Future<Response> handleEndPointList(Request request) async {
  try {
    final dao = DaoEndPoint();
    final endPoints = await dao.getAll();

    // Build the list of endPoints for JSON
    final endPointList = <Map<String, dynamic>>[];
    for (final ep in endPoints) {
      endPointList.add({
        'id': ep.id,
        'name': ep.name,
        'isOn': dao.isOn(ep), // or ep.getCurrentStatus()==ON
      });
    }

    // If you have WeatherBureaus, WeatherStations:
    final bureaus = WeatherBureaus.getBureaus(); // e.g. [BureauOfXYZ...]
    final bureauList = bureaus
        .map((b) => {
              'id': b.hashCode, // or some real ID if needed
              'countryName': b.countryName,
            })
        .toList();

    // If each bureau has stations
    // You might flatten them or fetch them from the selected bureau
    final stationList = <Map<String, dynamic>>[];
    // for demonstration, leave it empty or fill it as needed

    final responseMap = {
      'endPoints': endPointList,
      'weatherBureaus': bureauList,
      'weatherStations': stationList, // or ignore if not needed
    };

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

/// POST /api/end_point/edit_data
/// Request body: { "endPointId": 123? }
/// Response example:
/// {
///   "endPoint": {
///     "id": 123,
///     "name": "Garden Valve",
///     "pinNo": 17,
///     "activationType": "HIGH_IS_ON"
///   },
///   "availablePins": [ 17, 18, 22, 23 ],
///   "activationTypes": [ "HIGH_IS_ON", "LOW_IS_ON" ]
/// }
Future<Response> handleEndPointEditData(Request request) async {
  try {
    final bodyStr = await request.readAsString();
    final body = jsonDecode(bodyStr) as Map<String, dynamic>? ?? {};
    final endPointId = body['endPointId'] as int?;

    final dao = DaoEndPoint();
    EndPoint? endPoint;
    if (endPointId != null) {
      endPoint = await dao.getById(endPointId);
      if (endPoint == null) {
        return Response.notFound(jsonEncode({'error': 'EndPoint not found'}));
      }
    }

    // Example: gather a list of pins we can use
    final availablePins = GpioManager().availablePins;

    // Provide a list of activation types
    final activationTypes = PinActivationType.values
        .map((type) => type.name) // e.g. "highIsOn", "lowIsOn"
        .toList();

    final endPointJson = endPoint == null
        ? null
        : {
            'id': endPoint.id,
            'name': endPoint.name,
            'pinNo': endPoint.pinNo,
            'activationType': endPoint.activationType.name,
          };

    final responseMap = {
      'endPoint': endPointJson,
      'availablePins': availablePins,
      'activationTypes': activationTypes,
    };

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

/// POST /api/end_point/toggle
/// Request body: { "endPointId": 123, "turnOn": true }
/// Response: { "result": "OK" }
Future<Response> handleEndPointToggle(Request request) async {
  try {
    final bodyStr = await request.readAsString();
    final body = jsonDecode(bodyStr) as Map<String, dynamic>? ?? {};
    final endPointId = body['endPointId'] as int?;
    final turnOn = body['turnOn'] as bool?;

    if (endPointId == null || turnOn == null) {
      return Response.badRequest(
        body: jsonEncode({'error': 'Missing endPointId or turnOn'}),
      );
    }

    final dao = DaoEndPoint();
    final endPoint = await dao.getById(endPointId);
    if (endPoint == null) {
      return Response.notFound(jsonEncode({'error': 'EndPoint not found'}));
    }

    if (turnOn) {
      await dao.hardOn(endPoint);
    } else {
      await dao.hardOff(endPoint);
    }

    return Response.ok(jsonEncode({'result': 'OK'}));
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode({'error': e.toString()}),
      headers: {'Content-Type': 'application/json'},
    );
  }
}

/// POST /api/end_point/save
///
/// Request body: {
///   "id": 123?,              // null for new, non-null for existing
///   "name": "Garden Valve",
///   "pinNo": 17,
///   "activationType": "HIGH_IS_ON" // or "LOW_IS_ON"
/// }
///
/// Response: { "result": "OK" }
Future<Response> handleEndPointSave(Request request) async {
  try {
    final bodyStr = await request.readAsString();
    final body = jsonDecode(bodyStr) as Map<String, dynamic>? ?? {};

    final id = body['id'] as int?;
    final name = body['name'] as String?;
    final pinNo = body['pinNo'] as int?;
    final activationTypeStr = body['activationType'] as String?;

    if (name == null || pinNo == null || activationTypeStr == null) {
      return Response.badRequest(
        body: jsonEncode({
          'error':
              'Missing required fields: "name", "pinNo", or "activationType".'
        }),
      );
    }

    // Convert the activationType string to enum
    final activationType = _parsePinActivationType(activationTypeStr);
    if (activationType == null) {
      return Response.badRequest(
        body: jsonEncode({
          'error': 'Invalid activationType: $activationTypeStr',
        }),
      );
    }

    final dao = DaoEndPoint();

    if (id == null) {
      // Create a new EndPoint
      final newEndPoint = EndPoint(
          id: 0, // or auto-assigned
          name: name,
          pinNo: pinNo,
          endPointType: EndPointType.valve,
          activationType: activationType,
          createdDate: DateTime.now(),
          modifiedDate: DateTime.now());
      await dao.insert(newEndPoint);
    } else {
      // Update an existing EndPoint
      final existing = await dao.getById(id);
      if (existing == null) {
        return Response.notFound(jsonEncode({'error': 'EndPoint not found'}));
      }
      existing
        ..name = name
        ..pinNo = pinNo
        ..activationType = activationType;
      await dao.update(existing);
    }

    return Response.ok(
      jsonEncode({'result': 'OK'}),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode({'error': e.toString()}),
      headers: {'Content-Type': 'application/json'},
    );
  }
}

/// Helper to parse the activation type string into a [PinActivationType] enum
PinActivationType? _parsePinActivationType(String value) {
  // Adjust logic depending on how your enum is declared
  // e.g., "HIGH_IS_ON", "LOW_IS_ON"
  // Some code might look like:
  //   return PinActivationType.values.firstWhere(
  //      (v) => v.name == value,
  //      orElse: () => null
  //   );
  for (final type in PinActivationType.values) {
    if (type.name.toUpperCase() == value.toUpperCase()) {
      return type;
    }
  }
  return null;
}

/// POST /api/end_point/delete
/// Request: { "endPointId": 123 }
/// Response: { "result": "OK" }
Future<Response> handleEndPointDelete(Request request) async {
  try {
    final bodyStr = await request.readAsString();
    final body = jsonDecode(bodyStr) as Map<String, dynamic>? ?? {};
    final endPointId = body['endPointId'] as int?;
    if (endPointId == null) {
      return Response.badRequest(
          body: jsonEncode({'error': 'Missing endPointId'}));
    }

    // If you want to block deletion if any valve is running, check here
    final isAnyValveRunning = GardenBedController.isAnyValveRunning();
    if (await isAnyValveRunning) {
      return Response.badRequest(
        body: jsonEncode(
            {'error': 'Cannot delete an EndPoint while any valves are on.'}),
      );
    }

    final dao = DaoEndPoint();
    final endPoint = await dao.getById(endPointId);
    if (endPoint == null) {
      return Response.notFound(jsonEncode({'error': 'EndPoint not found'}));
    }

    await dao.delete(endPointId);
    return Response.ok(jsonEncode({'result': 'OK'}));
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode({'error': e.toString()}),
      headers: {'Content-Type': 'application/json'},
    );
  }
}
