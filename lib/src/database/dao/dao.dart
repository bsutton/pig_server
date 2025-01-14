import 'package:pig_common/pig_common.dart';

import '../management/database_helper.dart';
import 'dao_base.dart';

abstract class Dao<T extends Entity<T>> extends DaoBase<T> {
  Dao() : super(DatabaseHelper.instance.database, _notifier) {
    super.tableName = tableName;
    super.mapper = fromMap;
  }

  static void _notifier(DaoBase dao) {
    (dao as Dao)._notify();
  }

  void _notify() {
    // June.getState(juneRefresher).setState();
  }

  T fromMap(Map<String, dynamic> map);

  String get tableName;
}
