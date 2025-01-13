import 'package:sqflite_common/sqlite_api.dart';

import '../entity/garden_feature.dart';
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
  Future<List<History>> getByGardenFeature(GardenFeature gardenFeature) async =>
      getByGardenFeatureId(gardenFeature.id);

  Future<List<History>> getByGardenFeatureId(int featureId) async {
    final db = withoutTransaction();
    final data = await db.query(
      tableName,
      where: 'garden_feature_id = ?',
      whereArgs: [featureId],
    );
    return List.generate(data.length, (i) => fromMap(data[i]));
  }

  /// Returns the most recent [History] record for [feature],
  /// or `null` if none exist.
  Future<History?> getLastRecord(GardenFeature feature) async {
    // fetch all records sorted by most recent first
    final records = await getByGardenFeatureId(feature.id);
    if (records.isEmpty) {
      return null;
    }
    return records.first;
  }

  /// Delete History records by a specific GardenBed
  Future<int> deleteByGardenFeature(GardenFeature gardenFeature) async {
    final db = withoutTransaction();
    return db.delete(
      tableName,
      where: 'garden_feature_id = ?',
      whereArgs: [gardenFeature.id],
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
