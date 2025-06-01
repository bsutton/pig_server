import 'package:dcli/dcli.dart';

import 'config.dart';

class Logger {
  factory Logger() => _self ??= Logger._();

  Logger._() : pathToLog = Config().pathToLogfile;
  static Logger? _self;
  late final String pathToLog;

  void log(Object? message) {
    if (pathToLog == 'console') {
      qlog(message);
    } else {
      pathToLog.append(message.toString());
    }
  }

  void logerr(String message) {
    if (pathToLog == 'console') {
      qlogerr(message);
    } else {
      pathToLog.append(message);
    }
  }
}

void qlog(Object? message) => Logger().log(message);
void qlogerr(String message) => Logger().log(message);
