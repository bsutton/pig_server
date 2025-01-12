import 'package:sqflite_common/sqlite_api.dart';

import '../entity/endpoint.dart';
import '../entity/garden_feature.dart';
import 'dao.dart';

class DaoGardenFeature extends Dao<GardenFeature> {
  @override
  String get tableName => 'garden_feature';

  @override
  GardenFeature fromMap(Map<String, dynamic> map) {
    // This needs to be overridden in subclasses to provide correct implementations.
    throw UnimplementedError(
        'DaoGardenFeature.fromMap must be implemented in a subclass.');
  }

  /// Get a GardenFeature by its ID
  @override
  Future<GardenFeature?> getById(int id) async {
    final db = withoutTransaction();
    final data = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (data.isNotEmpty) {
      return fromMap(data.first);
    }
    return null;
  }

  /// Get all GardenFeatures
  @override
  Future<List<GardenFeature>> getAll({String? orderByClause}) async {
    final db = withoutTransaction();
    final data = await db.query(
      tableName,
      orderBy: orderByClause ?? 'id ASC',
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

  /// Delete all GardenFeatures
  @override
  Future<int> deleteAll([Transaction? transaction]) async {
    final db = withinTransaction(transaction);
    return db.delete(tableName);
  }

  /// Persist a new GardenFeature
  Future<int> persist(GardenFeature gardenFeature) async {
    final db = withoutTransaction();
    return db.insert(tableName, gardenFeature.toMap());
  }

  /// Delete a specific GardenFeature
  @override
  Future<int> delete(int id, [Transaction? transaction]) async {
    final db = withinTransaction(transaction);
    return db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Update (merge) an existing GardenFeature
  Future<int> merge(GardenFeature gardenFeature) async {
    final db = withoutTransaction();
    return db.update(
      tableName,
      gardenFeature.toMap(),
      where: 'id = ?',
      whereArgs: [gardenFeature.id],
    );
  }
}
