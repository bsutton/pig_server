import 'package:sqflite_common_ffi/sqflite_ffi.dart';

extension Db on Database {
  Future<void> x(String command) async {
    await execute(command);
  }
}
