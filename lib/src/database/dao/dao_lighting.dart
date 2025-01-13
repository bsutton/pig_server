import 'package:sqflite_common/sqlite_api.dart';

import '../../controllers/end_point_bus.dart';
import '../entity/endpoint.dart';
import '../entity/lighting.dart';
import 'dao.dart';
import 'dao_endpoint.dart';
import 'dao_garden_feature.dart';

class DaoLighting extends Dao<Lighting> {
  @override
  String get tableName => 'lighting';

  @override
  Lighting fromMap(Map<String, dynamic> map) => Lighting.fromMap(map);

  /// Get all Lighting entities
  @override
  Future<List<Lighting>> getAll({String? orderByClause}) async {
    final db = withoutTransaction();
    final data = await db.query(
      tableName,
      orderBy: orderByClause ?? 'id ASC',
    );
    return List.generate(data.length, (i) => fromMap(data[i]));
  }

  /// Get Lighting entities by a specific light switch (EndPoint)
  Future<List<Lighting>> getBySwitch(EndPoint lightSwitch) async {
    final db = withoutTransaction();
    final data = await db.query(
      tableName,
      where: 'light_switch_id = ?',
      whereArgs: [lightSwitch.id],
    );
    return List.generate(data.length, (i) => fromMap(data[i]));
  }

  /// Get EndPoints by pin number
  Future<List<EndPoint>> getByPin(int pinNo) async {
    final db = withoutTransaction();
    final data = await db.query(
      'end_point',
      where: 'pin_no = ?',
      whereArgs: [pinNo],
      orderBy: 'LOWER(end_point_name)',
    );
    return List.generate(data.length, (i) => EndPoint.fromMap(data[i]));
  }

  /// Delete Lighting entities associated with a specific EndPoint
  Future<int> deleteByEndPoint(EndPoint endPoint) async {
    final db = withoutTransaction();
    return db.delete(
      tableName,
      where: 'light_switch_id = ?',
      whereArgs: [endPoint.id],
    );
  }

  /// Persist a new Lighting entity
  Future<int> persist(Lighting lighting) async {
    final db = withoutTransaction();
    return db.insert(tableName, lighting.toMap());
  }

  /// Delete a specific Lighting entity
  @override
  Future<int> delete(int id, [Transaction? transaction]) async {
    final db = withinTransaction(transaction);
    return db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Update (merge) an existing Lighting entity
  Future<int> merge(Lighting lighting) async {
    final db = withoutTransaction();
    return db.update(
      tableName,
      lighting.toMap(),
      where: 'id = ?',
      whereArgs: [lighting.id],
    );
  }

  Future<void> softOff(Lighting lighting) async {
    await DaoGardenFeature().softOff(lighting);

    await DaoEndPoint().hardOffById(lighting.lightSwitchId);
  }

  Future<bool> isOn(Lighting light) async =>
      DaoEndPoint().isOnById(light.lightSwitchId);

  Future<void> softOn(Lighting lighting) async {
    await DaoGardenFeature().softOff(lighting);

    final endPoint = await DaoEndPoint().getById(lighting.lightSwitchId);

    await DaoEndPoint().hardOff(endPoint!);

    EndPointBus.instance.notifyHardOff(endPoint);
  }
}
