#! /usr/bin/env dart

import 'dart:io';

import 'package:args/args.dart';
import 'package:dcli/dcli.dart';
import 'package:dcli/posix.dart';
import 'package:path/path.dart';
import 'package:pig_server/src/dcli/resource/generated/resource_registry.g.dart';

final pathToPigation = join(rootPath, 'opt', 'pigation');
final pathToPigationBin = join(rootPath, 'opt', 'pigation', 'bin');

/// when deploying we copy the executable to an alternate location as the
/// existing execs will be running and therefore locked.
final pathToPigationAltBin = join(rootPath, 'opt', 'pigation', 'altbin');
final pathToWwwRoot = join(pathToPigation, 'www_root');
final pathToPigServer = join(pathToPigationBin, 'pig_server');
final pathToLauncher = join(pathToPigationBin, 'pig_launch');
final pathToLauncherScript = join(pathToPigationBin, 'pig_launch.sh');

void main(List<String> args) {
  final argParser = ArgParser()..addFlag('verbose', abbr: 'v');
  final parsed = argParser.parse(args);

  Settings().setVerbose(enabled: parsed['verbose'] as bool);

  _createDirectory(pathToWwwRoot);

  print(green('unpacking resources to: $pathToPigation'));
  final owner = Shell.current.loggedInUser!;
  Shell.current.withPrivileges(() {
    fixDirectoryPermissions(pathToPigation, owner);
  });

  unpackResources(pathToPigation);

  /// Create the dir to store letsencrypt files
  final pathToLetsEncrypt = join(pathToPigation, 'letsencrypt', 'live');
  _createDir(pathToLetsEncrypt);

  Shell.current.withPrivileges(() {
    final pathToLog = join(rootPath, 'var', 'log', 'pig_server.log');
    touch(pathToLog, create: true);

    chown(pathToLog, user: owner, group: owner);
    chmod(pathToLog, permission: '644');
  });

  Shell.current.withPrivileges(() {
    _addCronBoot(pathToLauncherScript);

    // restart t
    _restart(owner);
  });
}

/// Restart the the pig_server by killing the existing processes
/// and spawning them detached.
void _restart(String owner) {
  killProcess('pig_launch.sh');
  killProcess('dart:pig_launch');
  killProcess('dart:pig_server');

  // on first time install the bin directory won't exist.
  if (!exists(pathToPigationBin)) {
    createDir(pathToPigationBin, recursive: true);
  }

  copyTree(pathToPigationAltBin, pathToPigationBin, overwrite: true);

  fixDirectoryPermissions(pathToPigationAltBin, owner);
  fixDirectoryPermissions(pathToPigationBin, owner);

  // set execute priviliged
  makeExecutable(pathToPigServer, pathToLauncher, pathToLauncherScript);

  pathToLauncherScript.start(detached: true);

  print(red('Reboot the system to complete the deployment'));

  print(green('sudo reboot now'));
}

void fixDirectoryPermissions(String pathToFix, String owner) {
  chown(pathToFix, user: owner, group: owner);
  chmod(pathToFix, permission: '755');

  find('*', workingDirectory: pathToFix).forEach((entry) {
    chown(entry, user: owner, group: owner);
    if (isFile(entry)) {
      chmod(entry, permission: '755');
    }
    if (isDirectory(entry)) {
      chmod(entry, permission: '644');
    }
  });
}

void killProcess(String processName) {
  final processes = ProcessHelper().getProcessesByName(processName);
  for (final process in processes) {
    'kill -9 ${process.pid}'.run;
  }
}

void makeExecutable(String pathToPigServer, String pathToLauncher,
    String pathToLauncherScript) {
  // set execute priviliged
  chmod(pathToPigServer, permission: '710');
  chmod(pathToLauncher, permission: '710');
  chmod(pathToLauncherScript, permission: '710');
}

void unpackResources(String pathToPigation) {
  for (final resource in ResourceRegistry.resources.values) {
    final localPathTo = join(pathToPigation, resource.originalPath);
    final resourceDir = dirname(localPathTo);
    _createDir(resourceDir);

    resource.unpack(localPathTo);
  }
}

/// Add cron job so we get rebooted each time the system is rebooted.
void _addCronBoot(String pathToLauncher) {
  print(green('Adding cronjob to restart pig_server on reboot'));
  join(rootPath, 'etc', 'cron.d', 'pig_server').write('''
@reboot root $pathToLauncher
''');

  // ('(crontab -l ; echo "@reboot $pathToPigServer")' | 'crontab -').run;
}

void _createDir(String pathToDir) {
  if (!exists(pathToDir)) {
    createDir(pathToDir, recursive: true);
  }
}

void _createDirectory(String pathToWwwRoot) {
  if (!Shell.current.isPrivilegedUser) {
    printerr(red('You must run this script as sudo'));
    exit(1);
  }

  Shell.current.releasePrivileges();

  Shell.current.withPrivileges(() {
    if (exists(pathToWwwRoot)) {
      deleteDir(pathToWwwRoot);
    }
    createDir(pathToWwwRoot, recursive: true);

    chown(pathToWwwRoot, user: 'bsutton', group: 'bsutton');
  });
}
