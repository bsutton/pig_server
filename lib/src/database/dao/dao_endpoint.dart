import 'package:sqflite_common/sqlite_api.dart';

import '../entity/endpoint.dart';
import '../types/endpoint_type.dart';
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
    return List.generate(data.length, (i) => fromMap(data[i]));
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
    return List.generate(data.length, (i) => fromMap(data[i]));
  }

  /// Get EndPoints by pin number
  Future<List<EndPoint>> getByPin(int pinNo) async {
    final db = withoutTransaction();
    final data = await db.query(
      tableName,
      where: 'pin_no = ?',
      whereArgs: [pinNo],
      orderBy: 'LOWER(end_point_name)',
    );
    return List.generate(data.length, (i) => fromMap(data[i]));
  }

  /// Delete all EndPoints
  @override
  Future<int> deleteAll([Transaction? transaction]) async {
    final db = withinTransaction(transaction);
    return db.delete(tableName);
  }

  /// Persist a new EndPoint
  Future<int> persist(EndPoint endPoint) async {
    final db = withoutTransaction();
    return db.insert(tableName, endPoint.toMap());
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

  /// Update (merge) an existing EndPoint
  Future<int> merge(EndPoint endPoint) async {
    final db = withoutTransaction();
    return db.update(
      tableName,
      endPoint.toMap(),
      where: 'id = ?',
      whereArgs: [endPoint.id],
    );
  }
}
