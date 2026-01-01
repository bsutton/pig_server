#! /usr/bin/env dart
// ignore_for_file: avoid_types_on_closure_parameters

import 'dart:io';

import 'package:args/args.dart';
import 'package:dcli/dcli.dart';
import 'package:pigation/src/config.dart';
import 'package:pigation/src/database/dao/password.dart';
import 'package:pigation/src/dcli/resource/generated/resource_registry.g.dart';
import 'package:pigation/src/logger.dart';
import 'package:pigation/src/pi/gpio_manager.dart';
import 'package:pigation/src/startup/startup.g.dart';
import 'package:self/self.dart';

/// PiGation server side app that can install, launch and
/// run the PiGation web server based on the command line args passed
///
void main(List<String> args) async {
  final parser = ArgParser()
    ..options
    ..addFlag('install',
        abbr: 'i', negatable: false, help: 'Installs PiGation into /opt/pig')
    ..addFlag('reset-password',
        abbr: 'p',
        negatable: false,
        help: 'Reset the PiGation server password in config.yaml')
    ..addFlag('launch', abbr: 'l', negatable: false, help: '''
Launches pig in server mode as a sub-process and will restart it if it crashes.''')
    ..addFlag('server',
        abbr: 's',
        negatable: false,
        help:
            'Starts the web server. Use /opt/pig/config/config.yaml to control its settings')
    ..addFlag('debug', abbr: 'd', negatable: false, help: '''
starts the server in debug mode. Opens config.yaml from ./config/config.yaml.''');
  bool install;
  bool resetPassword;
  bool launch;

  bool server;
  bool debug;

  ArgResults parsed;

  try {
    parsed = parser.parse(args);
    install = parsed['install'] as bool? ?? false;
    resetPassword = parsed['reset-password'] as bool? ?? false;
    launch = parsed['launch'] as bool? ?? false;
    server = parsed['server'] as bool? ?? false;
    debug = parsed['debug'] as bool? ?? false;
  } on FormatException catch (e) {
    print(red('Invalid command args: $e'));
    usage(parser);
    exit(1);
  }

  if (!isOneOrNoneTrue(
    install: install,
    resetPassword: resetPassword,
    launch: launch,
    server: server,
  )) {
    print(red(
        '''You may select only one of 'install', 'reset-password', 'launch' or 'server' '''));
    usage(parser);
    exit(1);
  }

  if (debug) {
    Settings().setVerbose(enabled: true);
  }

  final config = _loadConfig(debug);

  final self = Self(
    logger: Logger(),
    installPath: '/opt/pigation',
    executableName: 'pig',
    resources: ResourceRegistry.resources,
  );

  if (install) {
    await doInstall(self, debug: debug);

    exit(0);
  }

  if (resetPassword) {
    await _resetPassword(config);
    exit(0);
  }

  if (launch) {
    await doLaunch(self, config, debug: debug);
    exit(0);
  }
  if (config.debugMode ?? false) {
    print(red('Running in debug mode, CORS protection is disabled'));
  }
  if (server) {
    final server = await runServer(config);

    print('Logging to: ${config.pathToLogfile}');

    print('Pig Server is running - CTRL-C to stop it gracefully');

    // Wait for shutdown signal (CTRL+C or SIGTERM)
    await _waitForShutdown();

    await server.close();

    shutdown();
    exit(0);
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
    {required bool install,
    required bool resetPassword,
    required bool launch,
    required bool server}) {
  // Count the number of true values.
  var trueCount = 0;

  if (install) {
    trueCount++;
  }
  if (resetPassword) {
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

Future<void> _resetPassword(Config config) async {
  print(green('''
Resetting the PiGation server password.
'''));
  var password = 'not set';
  var confirm = 'also not set';

  while (password != confirm) {
    password = ask('Password:', hidden: true);
    confirm = ask('Confirm your password', hidden: true);

    if (password != confirm) {
      print(red('The passwords did not match'));
    }
  }

  config.password = Password.getSaltedHash(password);
  await config.save();
  print(green('Password updated in ${config.loadedFrom}'));
}

void shutdown() {
  qlog('');
  qlog('Irrigation Manager is shutting down.');
  // stop all GPIO activity/threads by shutting down the GPIO controller
  // (this method will forcefully shutdown all GPIO monitoring threads and
  // scheduled tasks)
  GpioManager().shutdown();
}

// Function to wait for a shutdown signal
Future<void> _waitForShutdown() async {
  // Listen for SIGINT (Ctrl+C) or SIGTERM (termination signal)
  final shutdownSignal = ProcessSignal.sigint.watch().first;
  print('Waiting for shutdown signal...');
  await shutdownSignal;
}
