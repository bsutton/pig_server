import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:dcli/posix.dart';
import 'package:path/path.dart';
import 'package:posix/posix.dart' as posix;

import '../config.dart';
import '../database/factory/cli_database_factory.dart';
import '../database/management/local_backup_provider.dart';
import '../dcli/resource/generated/resource_registry.g.dart';
import '../security/password.dart';
import '../security/pbkdf2.dart';

final pathToPigation = join(rootPath, 'opt', 'pigation');
final pathToPigationBin = join(rootPath, 'opt', 'pigation', 'bin');

/// when deploying we copy the executable to an alternate location as the
/// existing execs will be running and therefore locked.
final pathToPigationAltBin = join(rootPath, 'opt', 'pigation', 'altbin');
final pathToWwwRoot = join(pathToPigation, 'www_root');
final pathToPigServer = join(pathToPigationBin, 'pig');
final pathToLauncher = join(pathToPigationBin, 'pig');
final pathToLauncherScript = join(pathToPigationBin, 'pig_launch.sh');

Future<void> doInstall({required bool debug}) async {
  if (debug) {
    Settings().setVerbose(enabled: true);
  }

  if (!Shell.current.isPrivilegedUser) {
    printerr(red('You must run this script as sudo'));
    exit(1);
  }
  await _getConfigFromUser();

  await _deploy();
}

Future<void> _getConfigFromUser() async {
  Config.init();

  final config = Config()..password = _createPassword();

  print(green('''

If port 80 and 433 are exposed to the internet AND you have a public DNS A record
for your RiPi, you can choose HTTPS.

Otherwise choose HTTP'''));
  final protocol = menu('Server Protocol:',
      options: ['HTTP', 'HTTPS'],
      defaultOption: config.useHttps ? 'HTTPS' : 'HTTP');
  config.useHttps = protocol == 'HTTPS';

  print(green('''

The PiGation app needs the FQDN or IP address of you RiPi to connect back to the PiGation server.
If you want to access the RiPi externally via NAT then this must be your external FQDN/IP'''));
  config.fqdn = ask('FQDN (or IP): ',
      defaultValue: config.fqdn,
      validator: Ask.any([Ask.fqdn, Ask.ipAddress()]));

  print(green('''

If your RiPI is behind a NAT you may want to use alternate port numbers.

Note: if you are using HTTPS then the externally exposed ports must be 80/443'''));

  config.httpPort = int.parse(ask('HTTP Port: ',
      defaultValue: '${config.httpPort}', validator: Ask.integer));

  if (config.useHttps) {
    config.httpsPort = int.parse(ask('HTTPS Port: ',
        defaultValue: '${config.httpsPort}', validator: Ask.integer));

    print(green('''

Lets Encrypt requires a contact email when requesting a certificate'''));
    config.domainEmail = ask('Email Address',
        defaultValue: config.domainEmail, validator: Ask.email);

    print(green('''
PiGation uses Lets Encrypt to allocate a cert.
Lets Encrypt has strict rate limits when issuing live certificates.
If this is your first attempt to get a cert we recommend that you use a staging certificate until you are sure your configuration is correct.
'''));
    final type = menu('Certifcate Type:',
        options: ['Staging', 'Live'],
        defaultOption: config.production ?? false ? 'Live' : 'Staging');
    config
      ..production = type == 'Live'
      ..pathToLetsEncryptLive =
          join(rootPath, 'opt', 'pigation', 'letsencrypt', 'live');
  }

  await config.save();
}

String _createPassword() {
  print(green('''

To secure access to PiGation you need to create a password that will be entered each time you access the app'''));

  var password = 'not set';
  var confirm = 'also not set';

  while (password != confirm) {
    password = ask('Password:', hidden: true);
    confirm = ask('Confirm your password', hidden: true);

    if (password != confirm) {
      print(red('The passwords did not match'));
    }
  }

  return Password.hash(password, PBKDF2());
}

Future<void> _deploy() async {
  _createDirectory(pathToWwwRoot);

  final owner = Shell.current.loggedInUser!;

  unpackResources(pathToPigation);

  /// copy this exe into altbin as we are the pig server.
  copy(DartScript.self.pathToExe, pathToPigationAltBin, overwrite: true);

  /// Create the dir to store letsencrypt files
  final pathToLetsEncrypt = join(pathToPigation, 'letsencrypt', 'live');
  _createDir(pathToLetsEncrypt);

  final pathToLogFile = Config().pathToLogfile;
  touch(pathToLogFile, create: true);

  await _prepareForDatabase(owner);

  fixDirectoryPermissions(pathToPigation, owner);

  chown(pathToLogFile, user: owner, group: owner);
  chmod(pathToLogFile, permission: '644');

  _addCronBoot(pathToLauncherScript, owner);

  /// start the service.
  await start(owner);
}

/// Restart the the pig  in server mode by killing the existing processes
/// and spawning them detached.
Future<void> start(String owner) async {
  killProcess('pig_launch.sh');
  killProcess('dart:pig');

  /// give the killed processes a moment to be cleanup
  /// otherwise the copyTree can fail
  sleep(2);

  // on first time install the bin directory won't exist.
  if (!exists(pathToPigationBin)) {
    createDir(pathToPigationBin, recursive: true);
  }

  copyTree(pathToPigationAltBin, pathToPigationBin, overwrite: true);

  fixDirectoryPermissions(pathToPigationAltBin, owner);
  fixDirectoryPermissions(pathToPigationBin, owner);

  // set execute priviliged
  makeExecutable(pathToPigServer, pathToLauncherScript);
  setCapabilities(pathToPigServer);

  final preSudo = UserEnvironment.preSudo(
      pathToHome: (Shell.current as PosixShell).loggedInUsersHome);

  /// abandon ability to get privilidges back
  /// as we need to ensure the launched app
  /// has the users uid/gid rather than roots.
  posix.setgid(preSudo.gid);
  posix.setuid(preSudo.uid);

  pathToLauncherScript.start(detached: true);

  print(red('The pig web server has been launched'));
}

/// Allow the pig server to bind to port 80/443 without
/// requiring sudo.
void setCapabilities(String pathToPigServer) {
  if (Platform.isLinux) {
    "setcap 'cap_net_bind_service=+ep' $pathToPigServer".run;
  }
}

Future<void> _prepareForDatabase(String owner) async {
  if (which('sqlite3').notfound) {
    print(green('Install sqllite3'));
    Shell.current.withPrivileges(() {
      'apt update'.run;
      'apt install sqlite3 libsqlite3-dev'.run;
      'apt install libcap2-bin'.run;
    });
  }

  final provider = LocalBackupProvider(CliDatabaseFactory());
  final pathToDbDirectory = dirname(provider.databasePath);

  if (!exists(pathToDbDirectory)) {
    createDir(pathToDbDirectory, recursive: true);
  }

  final pathToBackups = await provider.backupLocation;
  dirname(provider.databasePath);

  if (!exists(pathToDbDirectory)) {
    createDir(pathToDbDirectory, recursive: true);
  }

  if (!exists(pathToBackups)) {
    createDir(pathToBackups, recursive: true);
  }
}

void fixDirectoryPermissions(String pathToFix, String owner) {
  chown(pathToFix, user: owner, group: owner);
  chmod(pathToFix, permission: '755');

  find('*', workingDirectory: pathToFix, types: [Find.directory, Find.file])
      .forEach((entry) {
    // print('fixing $entry');
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
void _addCronBoot(String pathToLauncher, String user) {
  print(green('Adding cronjob to restart pig --server on reboot'));
  join(rootPath, 'etc', 'cron.d', 'pig --server').write('''
@reboot $user $pathToLauncher
''');

  // ('(crontab -l ; echo "@reboot $pathToPigServer")' | 'crontab -').run;
}

void _createDir(String pathToDir) {
  if (!exists(pathToDir)) {
    createDir(pathToDir, recursive: true);
  }
}

void _createDirectory(String pathToWwwRoot) {
  if (exists(pathToWwwRoot)) {
    deleteDir(pathToWwwRoot);
  }
  createDir(pathToWwwRoot, recursive: true);

  chown(pathToWwwRoot, user: 'bsutton', group: 'bsutton');
}
