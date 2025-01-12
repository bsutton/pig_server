import 'package:sqflite_common/sqlite_api.dart';

import '../entity/garden_bed.dart';
import '../entity/history.dart';
import 'dao.dart';

class DaoHistory extends Dao<History> {
  @override
  String get tableName => 'history';

  @override
  History fromMap(Map<String, dynamic> map) => History.fromMap(map);

  /// Get all History records, ordered by event start time descending
  @override
  Future<List<History>> getAll({String? orderByClause}) async {
    final db = withoutTransaction();
    final data = await db.query(
      tableName,
      orderBy: orderByClause ?? 'event_start DESC',
    );
    return List.generate(data.length, (i) => fromMap(data[i]));
  }

  /// Get History records by a specific GardenBed
  Future<List<History>> getByGardenBed(GardenBed gardenBed) async {
    final db = withoutTransaction();
    final data = await db.query(
      tableName,
      where: 'garden_feature_id = ?',
      whereArgs: [gardenBed.id],
    );
    return List.generate(data.length, (i) => fromMap(data[i]));
  }

  /// Delete History records by a specific GardenBed
  Future<int> deleteByGardenBed(GardenBed gardenBed) async {
    final db = withoutTransaction();
    return db.delete(
      tableName,
      where: 'garden_feature_id = ?',
      whereArgs: [gardenBed.id],
    );
  }

  /// Persist a new History record
  Future<int> persist(History history) async {
    final db = withoutTransaction();
    return db.insert(tableName, history.toMap());
  }

  /// Delete a specific History record
  @override
  Future<int> delete(int id, [Transaction? transaction]) async {
    final db = withinTransaction(transaction);
    return db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Update (merge) an existing History record
  Future<int> merge(History history) async {
    final db = withoutTransaction();
    return db.update(
      tableName,
      history.toMap(),
      where: 'id = ?',
      whereArgs: [history.id],
    );
  }
}
