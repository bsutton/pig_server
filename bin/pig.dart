#! /usr/bin/env dart
// ignore_for_file: avoid_types_on_closure_parameters

import 'dart:io';

import 'package:args/args.dart';
import 'package:dcli/dcli.dart';
import 'package:pig_server/src/config.dart';
import 'package:pig_server/src/logger.dart';
import 'package:pig_server/src/pi/gpio_manager.dart';
import 'package:pig_server/src/startup/startup.g.dart';

/// Simple web server that can serve stastic content and email
/// a booking.
void main(List<String> args) async {
  final parser = ArgParser()
    ..options
    ..addFlag('install',
        abbr: 'i', negatable: false, help: 'Installs PiGation into /opt/pig')
    ..addFlag('launch', abbr: 'l', negatable: false, help: '''
Launches pig in server mode as a sub-process and will restart it if it crashes.''')
    ..addFlag('server',
        abbr: 's',
        negatable: false,
        help:
            'Starts the web server. Use /opt/pig/config/config.yaml to control its settings')
    ..addFlag('debug', abbr: 'd', negatable: false, help: '''
starts the server in debug mode. Opens config.yaml from ./config/config.yaml.''');

  bool launch;
  bool server;
  bool debug;

  ArgResults parsed;

  try {
    parsed = parser.parse(args);
    launch = parsed['launch'] as bool? ?? false;
    server = parsed['server'] as bool? ?? false;
    debug = parsed['debug'] as bool? ?? false;
  } on FormatException catch (e) {
    print(red('Invalid command args: $e'));
    usage(parser);
    exit(1);
  }

  if (!isOneOrNoneTrue(
      install: parsed.wasParsed('install'), launch: launch, server: server)) {
    print(
        red('''You may select only one of 'install', 'launch' or 'server' '''));
    usage(parser);
    exit(1);
  }

  if (debug) {
    Settings().setVerbose(enabled: true);
  }
  if (launch) {
    await doLaunch(_loadConfig(debug), debug: debug);
  } else if (server) {
    await runServer(_loadConfig(debug));
    shutdown();
  } else {
    await doInstall();
  }
}

Config _loadConfig(bool debug) {
  Config config;
  if (debug) {
    config = Config.fromDebugPath();
  } else {
    config = Config();
  }
  return config;
}

bool isOneOrNoneTrue(
    {required bool install, required bool launch, required bool server}) {
  // Count the number of true values.
  var trueCount = 0;

  if (install) {
    trueCount++;
  }
  if (launch) {
    trueCount++;
  }
  if (server) {
    trueCount++;
  }

  // Return true if exactly one is true, otherwise false.
  return trueCount <= 1;
}

void usage(ArgParser parser) {
  print(parser.usage);
}

// TODO(bsutton): call shutdown as the web server stops.
void shutdown() {
  qlog('Irrigation Manager is shutting down.');
  // stop all GPIO activity/threads by shutting down the GPIO controller
  // (this method will forcefully shutdown all GPIO monitoring threads and
  // scheduled tasks)
  GpioManager().shutdown();
}
