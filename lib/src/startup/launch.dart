import 'package:self/self.dart';

import '../config.dart';

/// launch the pig_server and restart it if it fails.
/// We expect the pig_server to be in the same directory as the piglaunch exe
///
Future<void> doLaunch(Self self, Config config, {required bool debug}) async {
  print('Launching Pig Server...');

  await self.launch(args: ['--server']);
}
