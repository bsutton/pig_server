/// taken from https://github.com/leocavalcante/password-dart
/// BSD 3-Clause "New" or "Revised" License
///
library;

import 'dart:typed_data';

/// Creates a hexdecimal representation of the given [bytes].
String formatBytesAsHexString(Uint8List bytes) {
  final result = StringBuffer();
  for (var i = 0; i < bytes.lengthInBytes; i++) {
    final part = bytes[i];
    result.write('${part < 16 ? '0' : ''}${part.toRadixString(16)}');
  }
  return result.toString();
}

/// Creates binary data from the given [hex] hexdecimal String.
Uint8List createUint8ListFromHexString(String hex) {
  final result = Uint8List(hex.length ~/ 2);
  for (var i = 0; i < hex.length; i += 2) {
    final num = hex.substring(i, i + 2);
    final byte = int.parse(num, radix: 16);
    result[i ~/ 2] = byte;
  }
  return result;
}
