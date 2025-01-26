import 'package:dcli/dcli.dart';

import '../config.dart';
import '../logger.dart';

/// launch the pig_server and restart it if it fails.
/// We expect the pig_server to be in the same directory as the piglaunch exe
///
Future<void> doLaunch(Config config, {required bool debug}) async {
  print('Logging to: ${Config().pathToLogfile}');
  final String pathToPigServer;

  pathToPigServer = DartScript.self.pathToScript;
  Logger().log('Launching pig --server from $pathToPigServer');

  // start the server and relaunch it if it fails.
  for (;;) {
    final result = startFromArgs(pathToPigServer, ['--server'],
        nothrow: true, progress: Progress(qlog, stderr: qlogerr));
    qlog(red('pig --server failed with exitCode: ${result.exitCode}'));
    qlog('restarting pig --server in 10 seconds');
    sleep(10);
  }
}
