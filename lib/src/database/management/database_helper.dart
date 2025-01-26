import 'dart:async';

import 'package:sqflite_common/sqlite_api.dart';

import '../factory/pig_database_factory.dart';
import '../versions/db_upgrade.dart';
import '../versions/script_source.dart';
import 'backup_provider.dart';

class DatabaseHelper {
  factory DatabaseHelper() => instance;
  DatabaseHelper._();
  static Database? _database;
  static final DatabaseHelper instance = DatabaseHelper._();

  Database get database => _database!;

  Future<void> initDatabase({
    required ScriptSource src,
    required BackupProvider backupProvider,
    required bool backup,
    required PigDatabaseFactory databaseFactory,
  }) async {
    await openDb(
        src: src,
        backupProvider: backupProvider,
        databaseFactory: databaseFactory,
        backup: backup);
  }

  Future<void> openDb({
    required ScriptSource src,
    required BackupProvider backupProvider,
    required PigDatabaseFactory databaseFactory,
    required bool backup,
  }) async {
    final path = backupProvider.databasePath;
    final targetVersion = await getLatestVersion(src);
    print('target db version: $targetVersion');
    _database = await databaseFactory.openDatabase(path,
        options: OpenDatabaseOptions(
            version: targetVersion,
            onUpgrade: (db, oldVersion, newVersion) => upgradeDb(
                db: db,
                backup: backup,
                oldVersion: oldVersion,
                newVersion: newVersion,
                src: src,
                backupProvider: backupProvider)));
  }

  Future<void> closeDb() async {
    final db = database;
    _database = null;
    await db.close();
  }

  bool isOpen() => _database != null;

  Future<int> getVersion() async => database.getVersion();

  Future<void> withOpenDatabase(PigDatabaseFactory databaseFactory,
      String pathToDb, Future<void> Function() action) async {
    var wasOpen = false;
    try {
      if (_database == null) {
        _database = await databaseFactory.openDatabase(pathToDb,
            options: OpenDatabaseOptions());
        wasOpen = true;
      }

      await action();
    } finally {
      if (wasOpen) {
        await closeDb();
      }
    }
  }
}
