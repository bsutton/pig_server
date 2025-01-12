import 'dart:async';

import '../database/dao/dao_endpoint.dart';
import '../database/dao/dao_garden_bed.dart';
import '../database/entity/endpoint.dart';
import '../database/entity/garden_bed.dart';
import 'end_point_bus.dart';

/// A controller for managing a master valve and its associated garden beds.
class MasterValveController {
  // Private constructor
  MasterValveController._(this.masterValve, this.controlledBeds);

  // Static factory method
  static Future<MasterValveController> create(EndPoint masterValve) async {
    final controlledBeds = await DaoGardenBed().getControlledBy(masterValve);
    return MasterValveController._(masterValve, controlledBeds);
  }

  final EndPoint masterValve;
  final List<GardenBed> controlledBeds;
  GardenBed? drainOutVia;
  Timer? drainOutTimer;

  /// Turn off the specified garden bed's valve with additional master valve logic.
  Future<void> softOff(GardenBed gardenBed) async {
    assert(gardenBed.masterValveId == masterValve.id,
        'Garden Bed is not associated with this master valve');

    final gardenBedValve = (await DaoEndPoint().getById(gardenBed.valveId))!;

    if (masterValve.isDrainingLine) {
      assert(drainOutVia == null, 'DrainOutVia must be set');

      if (!await isOtherValveRunning(gardenBed)) {
        // Enter drain mode
        drainOutVia = gardenBed;

        // Turn off the master valve
        await DaoEndPoint().hardOff(masterValve);

        // Let the line drain for 30 seconds, then turn off the garden bed valve
        print('Draining Line via Valve: $gardenBedValve');
        drainOutTimer = Timer(const Duration(seconds: 30), drainLineCompleted);
        EndPointBus.instance.timerStarted(gardenBedValve);
      } else {
        // Other valves are running, turn off the garden bed valve directly
        await DaoEndPoint().hardOff(gardenBedValve);
      }
    } else {
      // Turn off the master valve if no other valves are running
      if (!await isOtherValveRunning(gardenBed)) {
        await DaoEndPoint().hardOff(masterValve);
      }
      DaoEndPoint().hardOff(gardenBedValve);
    }
  }

  /// Completes the drain process by turning off the drain valve.
  Future<void> drainLineCompleted() async {
    final drainOutValve = await DaoEndPoint().getById(drainOutVia?.valveId);
    await DaoEndPoint().hardOff(drainOutValve!);
    print('Drain process completed. Setting drainOutVia to null.');
    drainOutVia = null;
    drainOutTimer = null;
    EndPointBus.instance.timerFinished(drainOutValve);
  }

// ... other imports

  /// Check if any other valve associated with the master valve is running.
  Future<bool> isOtherValveRunning(GardenBed gardenBed) async {
    final daoGardenBed = DaoGardenBed();

    for (final current in controlledBeds) {
      if (current.id != gardenBed.id && await daoGardenBed.isOn(current)) {
        return true; // Found another valve that's on, so return true immediately
      }
    }

    return false; // No other valve was found to be on
  }

  /// Turn on the specified garden bed's valve and manage master valve logic.
  Future<void> softOn(GardenBed gardenBed) async {
    assert(gardenBed.masterValveId == masterValve.id,
        'Garden bed is not assocaited with this master valve');

    final gardenBedValve = await DaoEndPoint().getById(gardenBed.valveId);

    // Turn on the garden bed valve first to avoid pressure buildup
    await DaoEndPoint().hardOn(gardenBedValve!);

    if (!DaoEndPoint().isOn(masterValve)) {
      if (masterValve.isDrainingLine && drainOutVia != null) {
        // Cancel the current drain process
        final drainOutValve = await DaoEndPoint().getById(drainOutVia!.valveId);
        await DaoEndPoint().hardOff(drainOutValve!);
        print('Cancelling drain process due to new valve activation.');
        drainOutTimer?.cancel();
        drainOutVia = null;
      }
      await DaoEndPoint().hardOn(masterValve);
    }
  }

  /// Returns the master valve controlled by this controller.
  EndPoint getMasterValve() => masterValve;

  @override
  String toString() => '''
MasterValveController { masterValve: $masterValve, controlledBeds: $controlledBeds, drainOutVia: $drainOutVia }''';
}
