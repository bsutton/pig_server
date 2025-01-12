#! /usr/bin/env dcli

import 'package:dcli/dcli.dart';
import 'package:path/path.dart';
import 'package:pig_server/src/config.dart';
import 'package:pig_server/src/logger.dart';

/// launch the pig_server and restart it if it fails.
/// We expect the pig_server to be in the same directory as the piglaunch exe
///

void main(List<String> args) {
  print('Logging to: ${Config().pathToLogfile}');
  final pathToPigServer =
      join(dirname(DartScript.self.pathToScript), 'pig_server');
  Logger().log('Launching pig_server');

  // start the server and relaunch it if it fails.
  for (;;) {
    final result = pathToPigServer.start(
        nothrow: true, progress: Progress(qlog, stderr: qlogerr));
    qlog(red('pig_server failed with exitCode: ${result.exitCode}'));
    qlog('restarting pig_server in 10 seconds');
    sleep(10);
  }
}
