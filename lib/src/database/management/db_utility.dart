import 'package:path/path.dart';

int extractVerionForSQLUpgradeScript(String originPath) {
  final basename = basenameWithoutExtension(originPath);

  return int.parse(basename.substring(1));
}
