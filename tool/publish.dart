#! /home/bsutton/.dswitch/active/dart

import 'package:dcli/dcli.dart';
import 'package:pub_release/pub_release.dart';
import 'package:pubspec_manager/pubspec_manager.dart' as pm;

void main() {
  /// Ask the user for a new version and save it to the pubspec.yaml.
  final pubspec = pm.PubSpec.load();
  final currentVersion = pubspec.version;

  final newVersion = askForVersion(currentVersion.semVersion);

  pubspec.version.setSemVersion(newVersion);
  pubspec.save();

  print(orange('Forcing a build of the pig_app wasm target'));
  'tool/build.dart --build --wasm'.start(workingDirectory: '../pig_app');

  Resources().pack();
  'dart pub publish'.run;
}
