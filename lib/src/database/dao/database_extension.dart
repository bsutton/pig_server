
import 'package:sqflite_common/sqlite_api.dart';

extension Db on Database {
  Future<void> x(String command) async {
    await execute(command);
  }
}
