import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:dcli/posix.dart';
import 'package:path/path.dart';
import 'package:posix/posix.dart' as posix;

import '../database/factory/cli_database_factory.dart';
import '../database/management/local_backup_provider.dart';
import '../dcli/resource/generated/resource_registry.g.dart';

final pathToPigation = join(rootPath, 'opt', 'pigation');
final pathToPigationBin = join(rootPath, 'opt', 'pigation', 'bin');

/// when deploying we copy the executable to an alternate location as the
/// existing execs will be running and therefore locked.
final pathToPigationAltBin = join(rootPath, 'opt', 'pigation', 'altbin');
final pathToWwwRoot = join(pathToPigation, 'www_root');
final pathToPigServer = join(pathToPigationBin, 'pig');
final pathToLauncher = join(pathToPigationBin, 'pig');
final pathToLauncherScript = join(pathToPigationBin, 'pig_launch.sh');

Future<void> doInstall() async {
  await _deploy();
}

Future<void> _deploy() async {
  _createDirectory(pathToWwwRoot);

  final owner = Shell.current.loggedInUser!;
  Shell.current.withPrivileges(() {
    fixDirectoryPermissions(pathToPigation, owner);
  });

  unpackResources(pathToPigation);

  /// copy this exe into altbin as we are the pig server.
  copy(DartScript.self.pathToExe, pathToPigationAltBin);

  /// Create the dir to store letsencrypt files
  final pathToLetsEncrypt = join(pathToPigation, 'letsencrypt', 'live');
  _createDir(pathToLetsEncrypt);

  Shell.current.withPrivileges(() {
    final pathToLog = join(rootPath, 'var', 'log', 'pig_server.log');
    touch(pathToLog, create: true);

    chown(pathToLog, user: owner, group: owner);
    chmod(pathToLog, permission: '644');
  });

  await Shell.current.withPrivilegesAsync(() async {
    _addCronBoot(pathToLauncherScript);

    // restart t
    await _restart(owner);
  });
}

/// Restart the the pig_server by killing the existing processes
/// and spawning them detached.
Future<void> _restart(String owner) async {
  killProcess('pig_launch.sh');
  killProcess('dart:pig');

  // on first time install the bin directory won't exist.
  if (!exists(pathToPigationBin)) {
    createDir(pathToPigationBin, recursive: true);
  }

  copyTree(pathToPigationAltBin, pathToPigationBin, overwrite: true);

  fixDirectoryPermissions(pathToPigationAltBin, owner);
  fixDirectoryPermissions(pathToPigationBin, owner);

  // set execute priviliged
  makeExecutable(pathToPigServer, pathToLauncherScript);

  await _initDatabase(owner);

  pathToLauncherScript.start(detached: true);

  print(red('The pig web server has been launched'));
}

Future<void> _initDatabase(String owner) async {
  if (which('sqlite3').notfound) {
    print(green('Install sqllite3'));
    Shell.current.withPrivileges(() {
      'apt update'.run;
      'apt install sqlite3 libsqlite3-dev'.run;
    });
  }

  final provider = LocalBackupProvider(CliDatabaseFactory());
  final pathToDbDirectory = dirname(provider.databasePath);

  if (!exists(pathToDbDirectory)) {
    createDir(pathToDbDirectory, recursive: true);
    fixDirectoryPermissions(pathToDbDirectory, owner);
  }

  final pathToBackups = await provider.backupLocation;
  dirname(LocalBackupProvider(CliDatabaseFactory()).databasePath);

  if (!exists(pathToDbDirectory)) {
    createDir(pathToDbDirectory, recursive: true);
    fixDirectoryPermissions(pathToDbDirectory, owner);
  }
}

void fixDirectoryPermissions(String pathToFix, String owner) {
  chown(pathToFix, user: owner, group: owner);
  chmod(pathToFix, permission: '755');

  find('*', workingDirectory: pathToFix, types: [Find.directory, Find.file])
      .forEach((entry) {
    print('fixing $entry');
    chown(entry, user: owner, group: owner);

    if (isFile(entry)) {
      chmod(entry, permission: '644');
    }
    if (isDirectory(entry)) {
      chmod(entry, permission: '755');
    }
  });
}

void killProcess(String processName) {
  final pid = posix.getpid();
  final processes = ProcessHelper().getProcessesByName(processName);
  for (final process in processes) {
    if (process.pid == pid) {
      /// don't kill ourself.
      continue;
    }
    'kill -9 ${process.pid}'.start(progress: Progress.devNull());
  }
}

void makeExecutable(String pathToPig, String pathToLauncherScript) {
  // set execute priviliged
  chmod(pathToPig, permission: '710');
  chmod(pathToLauncherScript, permission: '710');
}

void unpackResources(String pathToPigation) {
  print(green('unpacking resources to: $pathToPigation'));
  for (final resource in ResourceRegistry.resources.values) {
    final localPathTo = join(pathToPigation, resource.originalPath);
    final resourceDir = dirname(localPathTo);
    _createDir(resourceDir);

    print('unpacking $localPathTo');

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
