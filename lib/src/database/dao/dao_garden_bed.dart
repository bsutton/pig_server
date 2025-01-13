import 'package:sqflite_common/sqlite_api.dart';

import '../entity/endpoint.dart';
import '../entity/garden_bed.dart';
import 'dao.dart';
import 'dao_endpoint.dart';

class DaoGardenBed extends Dao<GardenBed> {
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

  /// Delete all GardenBeds
  @override
  Future<int> deleteAll([Transaction? transaction]) async {
    final db = withinTransaction(transaction);
    return db.delete(tableName);
  }

  /// Persist a new GardenBed
  Future<int> persist(GardenBed gardenBed) async {
    final db = withoutTransaction();
    return db.insert(tableName, gardenBed.toMap());
  }

  /// Delete a specific GardenBed
  @override
  Future<int> delete(int id, [Transaction? transaction]) async {
    final db = withinTransaction(transaction);
    return db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Update (merge) an existing GardenBed
  Future<int> merge(GardenBed gardenBed) async {
    final db = withoutTransaction();
    return db.update(
      tableName,
      gardenBed.toMap(),
      where: 'id = ?',
      whereArgs: [gardenBed.id],
    );
  }

  Future<EndPoint> getEndPoint(GardenBed gardenBed) async =>
      (await DaoEndPoint().getById(gardenBed.valveId))!;

  Future<bool> isOn(GardenBed gardenBed) async {
    final endPoint = await getEndPoint(gardenBed);
    return DaoEndPoint().isOn(endPoint);
  }
}
