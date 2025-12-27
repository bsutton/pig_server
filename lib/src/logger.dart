import 'package:dcli/dcli.dart';
import 'package:self/self.dart';

import 'config.dart';

class Logger implements SelfLogger {
  static Logger? _self;

  late final String pathToLog;

  factory Logger() => _self ??= Logger._();

  Logger._() : pathToLog = Config().pathToLogfile;

  void log(Object? message) {
    if (pathToLog == 'console' || pathToLog == 'print') {
      print(message);
    } else {
      pathToLog.append(message.toString());
    }
  }

  void logerr(String message) {
    if (pathToLog == 'console' || pathToLog == 'print') {
      printerr(message);
    } else {
      pathToLog.append(message);
    }
  }

  @override
  void fine(Object? message, {Object? error, StackTrace? stackTrace}) {
    log(message.toString());
  }

  @override
  void finer(Object? message, {Object? error, StackTrace? stackTrace}) {
    log(message.toString());
  }

  @override
  void info(Object? message, {Object? error, StackTrace? stackTrace}) {
    log(message.toString());
  }

  @override
  void severe(Object? message, {Object? error, StackTrace? stackTrace}) {
    logerr(message.toString());
  }

  @override
  void warning(Object? message, {Object? error, StackTrace? stackTrace}) {
    logerr(message.toString());
  }
}

void qlog(Object? message) => Logger().log(message);
void qlogerr(String message) => Logger().log(message);
