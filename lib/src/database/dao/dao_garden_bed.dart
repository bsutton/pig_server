import 'package:sqflite_common/sqlite_api.dart';

import '../../controllers/end_point_bus.dart';
import '../entity/endpoint.dart';
import '../entity/garden_bed.dart';
import 'dao.dart';
import 'dao_endpoint.dart';
import 'dao_garden_feature.dart';
import 'dao_history.dart';

class DaoGardenBed extends Dao<GardenBed> with DaoGardenFeature {
  @override
  String get tableName => 'garden_bed';

  @override
  GardenBed fromMap(Map<String, dynamic> map) => GardenBed.fromMap(map);

  /// Get all GardenBeds
  @override
  Future<List<GardenBed>> getAll({String? orderByClause}) async {
    final db = withoutTransaction();
    final data = await db.query(
      tableName,
      orderBy: orderByClause ?? 'id ASC',
    );
    return List.generate(data.length, (i) => fromMap(data[i]));
  }

  @override
  Future<int> delete(int id, [Transaction? transaction]) async {
    DaoHistory().deleteByGardenBed(id);

    return super.delete(id, transaction);
  }

  /// Get all GardenBeds controlled by a specific master valve
  Future<List<GardenBed>> getControlledBy(EndPoint masterValve) async {
    final db = withoutTransaction();
    final data = await db.query(
      tableName,
      where: 'master_valve_id = ?',
      whereArgs: [masterValve.id],
    );
    return List.generate(data.length, (i) => fromMap(data[i]));
  }

  /// Get all GardenBeds by valve
  Future<List<GardenBed>> getByValve(EndPoint valve) async {
    final db = withoutTransaction();
    final data = await db.query(
      tableName,
      where: 'valve_id = ?',
      whereArgs: [valve.id],
    );
    return List.generate(data.length, (i) => fromMap(data[i]));
  }

  Future<EndPoint> getEndPoint(GardenBed gardenBed) async =>
      (await DaoEndPoint().getById(gardenBed.valveId))!;

  Future<bool> isOn(GardenBed gardenBed) async {
    final endPoint = await getEndPoint(gardenBed);
    return DaoEndPoint().isOn(endPoint);
  }

  @override
  Future<void> softOn(covariant GardenBed feature) async {
    await super.softOn(feature);

    final endPoint = await DaoEndPoint().getById(feature.valveId);

    await DaoEndPoint().hardOn(endPoint!);

    EndPointBus.instance.notifyHardOn(endPoint);
  }

  @override
  Future<void> softOff(covariant GardenBed feature) async {
    await super.softOff(feature);

    final endPoint = await DaoEndPoint().getById(feature.valveId);

    await DaoEndPoint().hardOff(endPoint!);

    EndPointBus.instance.notifyHardOff(endPoint);
  }
}
