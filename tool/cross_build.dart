#! /usr/bin/env dart

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:dcli/dcli.dart';
import 'package:path/path.dart' as path;
import 'package:path/path.dart';
import 'package:pigation/src/database/management/db_utility.dart';
import 'package:settings_yaml/settings_yaml.dart';

void main(List<String> args) async {
  final parser = ArgParser()
    ..addFlag('wasm',
        defaultsTo: true,
        help: 'Build the wasm front end as well as the server');

  ArgResults parsed;
  try {
    parsed = parser.parse(args);
  } on FormatException catch (e) {
    print(e);
    rethrow;
  }

  await updateAssetList();

  final project = DartProject.self;

  final buildWasm = parsed.flag('wasm');
  if (buildWasm) {
    print(green('building wasm front end with source maps'));
    'tool/build.dart --build --wasm --source-maps'
        .start(workingDirectory: '../pig_app');
    print(green('wasm build completed'));
  }

  print(green('Packing deployable resources'));
  Resources().pack();

  final buildSettings = SettingsYaml.load(
      pathToSettings: join(project.pathToProjectRoot, 'tool', 'build.yaml'));

  final scpCommand = buildSettings.asString('scp_command');
  final targetServer = buildSettings.asString('target_server');
  final targetDirectory = buildSettings.asString('target_directory');

  /// Order is important.
  /// We must compile iahserver and the resources as they are all
  /// compiled into the deploy script.
  ///
  print(green('Compiling pig_install'));

  /// this is the pig server but we call it pig_install so the user
  /// knows what to run.
  'dart compile exe --target-os=linux --target-arch=arm64 bin/pig.dart -o bin/pig_install'
      .run;

  print(green("deploying 'pig_install' to $targetDirectory"));
  '$scpCommand bin/pig_install $targetServer:$targetDirectory'.run;

  print(orange('build complete'));
  print(
      '''log into the $targetServer and run 'cd $targetDirectory;chmod +x pig_install;sudo PATH=\$PATH ./pig_install' ''');
}

/// Update the list of sql upgrade scripts we ship as assets.
/// The lists is held in assets/sql/upgrade_list.json
Future<void> updateAssetList() async {
  final pathToAssets = join(
      DartProject.self.pathToProjectRoot, 'resource', 'sql', 'upgrade_scripts');
  final assetFiles = find('v*.sql', workingDirectory: pathToAssets).toList();

  final posix = path.posix;
  final relativePaths = assetFiles

      /// We are creating asset path which must us the posix path delimiter \
      .map((path) {
    final rel = relative(path, from: DartProject.self.pathToProjectRoot);
    return posix.joinAll(split(rel));
  }).toList()
    ..sort((a, b) =>
        extractVerionForSQLUpgradeScript(b) -
        extractVerionForSQLUpgradeScript(a));

  var jsonContent = jsonEncode(relativePaths);

  // make the json file more readable
  jsonContent = jsonContent.replaceAllMapped(
    RegExp(r'\[|\]'),
    (match) => match.group(0) == '[' ? '[\n  ' : '\n]',
  );
  jsonContent = jsonContent.replaceAll(RegExp(r',\s*'), ',\n  ');

  final jsonFile = File('resource/sql/upgrade_list.json')
    ..writeAsStringSync(jsonContent);

  print('SQL Asset list generated: ${jsonFile.path}');

  // After updating the assets, create the clean test database.
  // await createCleanTestDatabase();
}
