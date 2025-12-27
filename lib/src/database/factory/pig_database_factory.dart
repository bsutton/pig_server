import 'package:sqflite_common_ffi/sqflite_ffi.dart';

abstract class PigDatabaseFactory {
  Future<Database> openDatabase(String path,
      {required OpenDatabaseOptions options});
}
