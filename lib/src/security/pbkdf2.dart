/// taken from https://github.com/leocavalcante/password-dart
/// BSD 3-Clause "New" or "Revised" License
///
library;

import 'dart:typed_data';

import 'package:pointycastle/api.dart' show KeyParameter;
import 'package:pointycastle/digests/sha512.dart';
import 'package:pointycastle/key_derivators/api.dart' show Pbkdf2Parameters;
import 'package:pointycastle/key_derivators/pbkdf2.dart';
import 'package:pointycastle/macs/hmac.dart';
import 'package:pointycastle/random/fortuna_random.dart';

import 'algorigthm.dart';
import 'helper.dart';

/// Wraps the PBKDF2 key derivator.
class PBKDF2 extends Algorithm {
  PBKDF2(
      {this.blockLength = 64,
      this.iterationCount = 10000,
      this.desiredKeyLength = 64,
      String? salt}) {
    final rnd = FortunaRandom()..seed(KeyParameter(Uint8List(32)));

    _salt =
        salt == null ? rnd.nextBytes(32) : createUint8ListFromHexString(salt);
    _derivator = PBKDF2KeyDerivator(HMac(SHA512Digest(), blockLength))
      ..init(Pbkdf2Parameters(_salt, iterationCount, desiredKeyLength));
  }
  static String id = 'pcks';
  final int blockLength;
  final int iterationCount;
  final int desiredKeyLength;

  late PBKDF2KeyDerivator _derivator;
  late Uint8List _salt;
  @override
  String process(String password) {
    final bytes = _derivator.process(Uint8List.fromList(password.codeUnits));
    return encode(
      id,
      [blockLength, iterationCount, desiredKeyLength],
      formatBytesAsHexString(_salt),
      formatBytesAsHexString(bytes),
    );
  }
}
