#! /home/bsutton/.dswitch/active/dart

import 'package:dcli/dcli.dart';

void main() {
  print(orange('Forcing a build of the pig_app wasm target'));
  'tool/build.dart --build --wasm'.start(workingDirectory: '../pig_app');

  print('Packing resouces');
  Resources().pack();
}
