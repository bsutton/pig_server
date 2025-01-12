import 'package:dcli/dcli.dart';
import 'package:path/path.dart';

int extractVerionForSQLUpgradeScript(PackedResource packedResource) {
  final basename = basenameWithoutExtension(packedResource.originalPath);

  return int.parse(basename.substring(1));
}
