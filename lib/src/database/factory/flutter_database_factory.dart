import 'dart:io';

import 'package:sqflite_common/sqflite.dart';
import 'package:sqflite_common/sqlite_api.dart';

import 'hmb_database_factory.dart' as local;

class FlutterDatabaseFactory implements local.HMBDatabaseFactory {
  factory FlutterDatabaseFactory() {
    if (instance == null) {
      instance = FlutterDatabaseFactory._();
      instance!.initDatabaseFactory();
    }

    return instance!;
  }

  FlutterDatabaseFactory._();
  static FlutterDatabaseFactory? instance;

  void initDatabaseFactory() {
    if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      /// required for non-mobile platforms.
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    } else if (Platform.isAndroid || Platform.isIOS) {
      /// uses the default factory.
    }
  }

  @override
  Future<Database> openDatabase(String path,
          {required OpenDatabaseOptions options}) async =>
      databaseFactory.openDatabase(path, options: options);
}
