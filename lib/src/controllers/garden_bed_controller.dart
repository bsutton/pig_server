// ignore_for_file: avoid_classes_with_only_static_members
import 'package:collection/collection.dart';

import '../database/dao/dao_endpoint.dart';
import '../database/entity/garden_bed.dart';
import '../database/types/endpoint_type.dart';
import 'master_valve_controller.dart';

/// A controller to manage the operation of garden beds and their valves.
class GardenBedController {
  static final List<MasterValveController> _masterValveControllers = [];

  /// Initialize the list of master valve controllers.
  static Future<void> init() async {
    final daoEndPoint = DaoEndPoint();

    // Fetch all master valves
    final masterValves = await daoEndPoint.getMasterValves();

    // Clear any existing controllers
    _masterValveControllers.clear();

    for (final masterValve in masterValves) {
      final controller = await MasterValveController.create(masterValve);
      _masterValveControllers.add(controller);
    }
  }

  /// Turn off the valve of a specified garden bed with soft control.
  static Future<void> softOff(GardenBed gardenBed) async {
    print('Turning ${gardenBed.name} Off.');

    final masterValveController = _getMasterValveForBed(gardenBed);

    if (masterValveController != null) {
      await masterValveController.softOff(gardenBed);
    } else {
      final valve = await DaoEndPoint().getById(gardenBed.valveId);
      await DaoEndPoint().hardOff(valve!);
    }
  }

  /// Turn on the valve of a specified garden bed with soft control.
  static Future<void> softOn(GardenBed gardenBed) async {
    print('Turning ${gardenBed.name} On.');

    final masterValveController = _getMasterValveForBed(gardenBed);

    if (masterValveController != null) {
      await masterValveController.softOn(gardenBed);
    } else {
      await DaoEndPoint().hardOffById(gardenBed.valveId);
    }
  }

  /// Check if any valve is currently running.
  static Future<bool> isAnyValveRunning() async {
    final daoEndPoint = DaoEndPoint();

    // Fetch all endpoints
    final endPoints = await daoEndPoint.getAll();

    for (final endPoint in endPoints) {
      if ((endPoint.endPointType == EndPointType.masterValve ||
              endPoint.endPointType == EndPointType.valve) &&
          DaoEndPoint().isOn(endPoint)) {
        return true;
      }
    }
    return false;
  }

  /// Get the master valve controller for a specified garden bed.
  static MasterValveController? _getMasterValveForBed(GardenBed gardenBed) =>
      _masterValveControllers.firstWhereOrNull(
        (controller) => controller.masterValve.id == gardenBed.masterValveId,
      );
}
