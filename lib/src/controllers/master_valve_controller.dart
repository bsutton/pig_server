import 'dart:async';

import '../database/dao/dao_endpoint.dart';
import '../database/dao/dao_garden_bed.dart';
import '../database/entity/endpoint.dart';
import '../database/entity/garden_bed.dart';
import 'end_point_bus.dart';


/// A controller for managing a master valve and its associated garden beds.
class MasterValveController {
  final EndPoint masterValve;
  final List<GardenBed> controlledBeds;
  GardenBed? drainOutVia;
  Timer? drainOutTimer;

  MasterValveController(this.masterValve)
      : controlledBeds = await DaoGardenBed().getControlledBy(masterValve);

  /// Turn off the specified garden bed's valve with additional master valve logic.
  Future<void> softOff(GardenBed gardenBed) async {
    assert(gardenBed.masterValveId == masterValve.id);

    final gardenBedValve = DaoEndPoint().getById(gardenBed.valveId);

    if (masterValve.isDrainingLine) {
      assert(drainOutVia == null);

      if (!isOtherValveRunning(gardenBed)) {
        // Enter drain mode
        drainOutVia = gardenBed;

        // Turn off the master valve
        await masterValve.hardOff();

        // Let the line drain for 30 seconds, then turn off the garden bed valve
        print("Draining Line via Valve: $gardenBedValve");
        drainOutTimer = Timer(Duration(seconds: 30), drainLineCompleted);
        EndPointBus.instance.timerStarted(gardenBedValve);
      } else {
        // Other valves are running, turn off the garden bed valve directly
        await gardenBedValve.hardOff();
      }
    } else {
      // Turn off the master valve if no other valves are running
      if (!isOtherValveRunning(gardenBed)) {
        await masterValve.hardOff();
      }
      await gardenBedValve.hardOff();
    }
  }

  /// Completes the drain process by turning off the drain valve.
  void drainLineCompleted() {
    final drainOutValve = drainOutVia?.valve;
    drainOutValve?.hardOff();
    print("Drain process completed. Setting drainOutVia to null.");
    drainOutVia = null;
    drainOutTimer = null;
    EndPointBus.instance.timerFinished(drainOutValve);
  }

  /// Check if any other valve associated with the master valve is running.
  bool isOtherValveRunning(GardenBed gardenBed) {
    return controlledBeds.any(
      (current) => current.id != gardenBed.id && current.isOn,
    );
  }

  /// Turn on the specified garden bed's valve and manage master valve logic.
  Future<void> softOn(GardenBed gardenBed) async {
    assert(gardenBed.masterValveId == masterValve.id);

    final gardenBedValve = gardenBed.valve;

    // Turn on the garden bed valve first to avoid pressure buildup
    await gardenBedValve.hardOn();

    if (!masterValve.isOn) {
      if (masterValve.isDrainingLine && drainOutVia != null) {
        // Cancel the current drain process
        drainOutVia?.valve.hardOff();
        print("Cancelling drain process due to new valve activation.");
        drainOutTimer?.cancel();
        drainOutVia = null;
      }
      await masterValve.hardOn();
    }
  }

  /// Returns the master valve controlled by this controller.
  EndPoint getMasterValve() => masterValve;

  @override
  String toString() {
    return 'MasterValveController { masterValve: $masterValve, controlledBeds: $controlledBeds, drainOutVia: $drainOutVia }';
  }
}
