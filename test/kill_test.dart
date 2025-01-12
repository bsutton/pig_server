import 'package:test/test.dart';

import '../tool/deploy.dart';

void main() {
  test('kill process', () {
    killProcess('piglaunch.sh');
    killProcess('dart:pig_launch');
    killProcess('dart:pig_server.d');
  });
}
