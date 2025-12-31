// end_point_handlers.dart
import 'dart:convert';

import 'package:pig_common/pig_common.dart';
import 'package:shelf/shelf.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:strings/strings.dart';

import '../../controllers/garden_bed_controller.dart';
import '../../database/dao/dao_endpoint.dart';
import '../../database/types/pin_logic_state.dart';
import '../../logger.dart';
import '../../pi/gpio_manager.dart';
import '../../weather/bureaus/weather_bureaus.dart';

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
/// POST /api/end_point/list
/// Request: {}
/// Response (JSON):
/// {
///   "endPoints": [ { …EndPointData JSON… }, … ],
///   "weatherBureaus": [ { …WeatherBureauInfo JSON… }, … ],
///   "weatherStations": [ { …WeatherStationInfo JSON… }, … ]
/// }
Future<Response> handleEndPointList(Request request) async {
  try {
    final dao = DaoEndPoint();
    final allEndpoints = await dao.getAllOrderedByOrdinal();

    // Build List<EndPointData>
    final endPointList = <EndPointData>[];
    for (final ep in allEndpoints) {
      final isOn = (dao.getCurrentStatus(ep)) == PinLogicState.on;
      endPointList.add(
        EndPointData.fromEndPoint(ep, on: isOn),
      );
    }

    // Build List<WeatherBureauInfo>
    final rawBureaus = WeatherBureaus.getBureaus();
    final bureauList = rawBureaus
        .map((b) => WeatherBureauData(
              id: b.id,
              countryName: b.countryName,
            ))
        .toList();

    final stationList = <WeatherStationData>[];
    for (final bureau in rawBureaus) {
      stationList.addAll(bureau.stations);
    }

    // Create our typed DTO
    final dto = EndPointListData(
      endPoints: endPointList,
      bureaus: bureauList,
      stations: stationList,
    );

    return Response.ok(
      jsonEncode(dto.toJson()),
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

    final endPointJson =
        endPoint == null ? null : EndPointData.fromEndPoint(endPoint).toJson();

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
    qlog('end_point/toggle endPointId: $endPointId, turnOn: $turnOn');

    if (endPointId == null || turnOn == null) {
      qlog('end_point/toggle Missing endPointId or turnOn');
      return Response.badRequest(
        body: jsonEncode({'error': 'Missing endPointId or turnOn'}),
      );
    }

    final dao = DaoEndPoint();
    final endPoint = await dao.getById(endPointId);
    if (endPoint == null) {
      qlog('end_point/toggle EndPoint not found');
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

/// POST /api/end_point/pulse_pin
/// Request body: {
///   "pinNo": 17,
///   "durationMs": 700,
///   "activationType": "highIsOn"
/// }
/// Response: { "result": "OK" }
Future<Response> handleEndPointPulsePin(Request request) async {
  try {
    final bodyStr = await request.readAsString();
    final body = jsonDecode(bodyStr) as Map<String, dynamic>? ?? {};
    final pinNo = body['pinNo'] as int?;
    final durationMs = body['durationMs'] as int?;
    final activationTypeName = body['activationType'] as String?;

    if (pinNo == null || durationMs == null) {
      qlog('end_point/pulse_pin Missing pinNo or durationMs');
      return Response.badRequest(
        body: jsonEncode({'error': 'Missing pinNo or durationMs'}),
      );
    }

    final availablePins = GpioManager().availablePins;
    if (!availablePins.any((pin) => pin.gpioPin == pinNo)) {
      return Response.badRequest(
        body: jsonEncode({'error': 'Pin $pinNo is not available'}),
      );
    }

    final activationType = activationTypeName == null
        ? PinActivationType.highIsOn
        : PinActivationType.fromJson(activationTypeName);

    await GpioManager().pulsePin(
      pinNo: pinNo,
      activationType: activationType,
      duration: Duration(milliseconds: durationMs),
    );

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

    final endPointInfo = EndPointData.fromJson(body);
    final pinAssignment = endPointInfo.gpioPinAssignment;

    // final id = body['id'] as int?;
    // final name = body['name'] as String?;
    // final pinNo = body['pinNo'] as int?;
    // final activationTypeStr = body['activationType'] as String?;

    if (pinAssignment == GPIOPinAssignment.none) {
      if (endPointInfo.id != null) {
        await DaoEndPoint().delete(endPointInfo.id!);
      }
      return Response.ok(
        jsonEncode({'result': 'OK'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    if (Strings.isBlank(endPointInfo.name)) {
      return Response.badRequest(
        body: jsonEncode({
          'error':
              'Missing required fields: "name", "pinNo", or "activationType".'
        }),
      );
    }

    if (await _pinInUse(endPointInfo)) {
      return Response.badRequest(
          body: jsonEncode({
        'error': '''
The GPIO Pin ${pinAssignment.gpioPin} is already in use.'''
      }));
    }

    final dao = DaoEndPoint();

    if (endPointInfo.id == null) {
      // Create a new EndPoint
      final newEndPoint = EndPoint(
          id: 0, // or auto-assigned
          ordinal: endPointInfo.ordinal,
          name: endPointInfo.name,
          gpioPinNo: endPointInfo.gpioPinAssignment.gpioPin,
          endPointType: endPointInfo.endPointType,
          activationType: endPointInfo.activationType,
          createdDate: DateTime.now(),
          modifiedDate: DateTime.now());
      await dao.insert(newEndPoint);
    } else {
      // Update an existing EndPoint
      final existing = await dao.getById(endPointInfo.id);
      if (existing == null) {
        return Response.notFound(jsonEncode({'error': 'EndPoint not found'}));
      }
      existing
        ..ordinal = endPointInfo.ordinal
        ..name = endPointInfo.name
        ..gpioPinNo = endPointInfo.gpioPinAssignment.gpioPin
        ..activationType = endPointInfo.activationType
        ..endPointType = endPointInfo.endPointType;
      await dao.update(existing);
    }

    return Response.ok(
      jsonEncode({'result': 'OK'}),
      headers: {'Content-Type': 'application/json'},
    );
  } on DatabaseException catch (e) {
    if (e.getResultCode() == 2067) {
      return Response.badRequest(
        body: jsonEncode({'error': 'End Point name must be unique.'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
    return Response.internalServerError(
      body: jsonEncode({'error': e.toString()}),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode({'error': e.toString()}),
      headers: {'Content-Type': 'application/json'},
    );
  }
}

Future<bool> _pinInUse(EndPointData endPointInfo) async {
  final assignment = endPointInfo.gpioPinAssignment;
  if (assignment == GPIOPinAssignment.none) {
    return false;
  }
  final endPoint = await DaoEndPoint().getByPin(assignment.gpioPin);

  return endPoint != null && endPoint.id != endPointInfo.id;
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
