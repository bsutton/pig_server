import 'package:pig_common/pig_common.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../controllers/end_point_bus.dart';
import '../../logger.dart';
import '../../pi/gpio_manager.dart';
import '../types/pin_logic_state.dart';
import 'dao.dart';

class DaoEndPoint extends Dao<EndPoint> {
  @override
  String get tableName => 'end_point';

  @override
  EndPoint fromMap(Map<String, dynamic> map) => EndPoint.fromMap(map);

  /// Get all EndPoints, ordered by name
  @override
  Future<List<EndPoint>> getAll({String? orderByClause}) async {
    final db = withoutTransaction();
    final data = await db.query(
      tableName,
      orderBy: orderByClause ?? 'LOWER(end_point_name)',
    );
    return data.map(fromMap).toList();
  }

  Future<List<EndPoint>> getAllOrderedByOrdinal() async {
    final db = withoutTransaction();
    final rows = await db.query(
      tableName,
      orderBy: 'ordinal ASC, end_point_name ASC', // primary sort on `ordinal`
    );
    return rows.map(fromMap).toList();
  }

  /// Get all valves
  Future<List<EndPoint>> getAllValves() async =>
      getAllByType(EndPointType.valve);

  /// Get all master valves
  Future<List<EndPoint>> getMasterValves() async =>
      getAllByType(EndPointType.masterValve);

  /// Get all EndPoints by type
  Future<List<EndPoint>> getAllByType(EndPointType type) async {
    final db = withoutTransaction();
    final data = await db.query(
      tableName,
      where: 'end_point_type = ?',
      whereArgs: [type.name],
      orderBy: 'LOWER(end_point_name)',
    );
    return data.map(fromMap).toList();
  }

  /// Get EndPoints by pin number
  Future<EndPoint?> getByPin(int pinNo) async {
    final db = withoutTransaction();
    final data = await db.query(
      tableName,
      where: 'pin_no = ?',
      whereArgs: [pinNo],
      orderBy: 'LOWER(end_point_name)',
    );
    final list = List.generate(data.length, (i) => fromMap(data[i]));

    if (list.length > 1) {
      throw StateError('''
Found multiple EndPoints with the same gpio pin no. There should only be one. $list''');
    }
    return list.firstOrNull;
  }

  /// Delete a specific EndPoint
  @override
  Future<int> delete(int id, [Transaction? transaction]) async {
    final db = withinTransaction(transaction);
    return db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get the current status of a GPIO pin.
  PinLogicState getCurrentStatus(EndPoint endPoint) =>
      GpioManager().getCurrentStatus(endPoint);

  /// Activates a pin associated with an [EndPoint].
  Future<void> hardOn(EndPoint endPoint) async {
    final pinNo = endPoint.gpioPinNo;

    GpioManager()
        .setEndPointState(endPoint: endPoint, pinState: PinLogicState.on);

    qlog('Pin $pinNo for EndPoint: ${endPoint.name} set On.');
  }

  /// Deactivates a pin associated with an [EndPoint].
  Future<void> hardOff(EndPoint endPoint) async {
    final pinNo = endPoint.gpioPinNo;

    GpioManager()
        .setEndPointState(endPoint: endPoint, pinState: PinLogicState.off);

    EndPointBus.instance.notifyHardOff(endPoint);
    qlog('Pin $pinNo for EndPoint: ${endPoint.name} set Off.');
  }

  Future<void> hardOffById(int valveId) async {
    final valve = await DaoEndPoint().getById(valveId);
    await DaoEndPoint().hardOff(valve!);
  }

  Future<bool> isOnById(int endPointId) async {
    final endPoint = await DaoEndPoint().getById(endPointId);

    return isOn(endPoint!);
  }

  bool isOn(EndPoint endPoint) =>
      GpioManager().getCurrentStatus(endPoint) == PinLogicState.on;

  PinVoltage voltageForState(EndPoint endPoint, PinLogicState pinState) {
    switch (pinState) {
      case PinLogicState.on:
        if (endPoint.activationType == PinActivationType.highIsOn) {
          return PinVoltage.high;
        } else {
          return PinVoltage.low;
        }
      case PinLogicState.off:
        if (endPoint.activationType == PinActivationType.lowIsOn) {
          return PinVoltage.high;
        } else {
          return PinVoltage.low;
        }
    }
  }
}
