import 'package:pig_server/src/startup/startup.g.dart';
import 'package:test/test.dart';

void main() {
  test('kill process', () {
    killProcess('piglaunch.sh');
    killProcess('dart:pig.d');
  });
}
