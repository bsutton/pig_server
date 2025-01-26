import 'package:dcli/dcli.dart';

abstract class ScriptSource {
  Future<String> loadSQL(PackedResource pathToScript);
  Future<List<PackedResource>> upgradeScripts();

  static const pathToIndex = 'resource/sql/upgrade_list.json';
}
