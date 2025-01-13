// ignore_for_file: avoid_classes_with_only_static_members

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

class Password {
  // The higher the number of iterations, the more expensive computing
  //the hash is for us and attackers.
  static const int iterations = 20000;
  static const int saltLen = 32;
  static const int keyLen = 32; // 256 bits

  /// Computes a salted PBKDF2 hash of the given plaintext password suitable
  /// for storing in a database.
  /// Empty passwords are not supported.
  static String getSaltedHash(String password) {
    if (password.isEmpty) {
      throw ArgumentError('Password cannot be empty.');
    }

    final salt = _generateSalt(saltLen);
    final hash = _generatePBKDF2Hash(password, salt);

    // Store the salt with the hash, separated by a `$` character
    return '${base64.encode(salt)}\$${base64.encode(hash)}';
  }

  /// Checks whether the given plaintext password corresponds to a stored
  ///  salted hash.
  static bool validate(String password, String stored) {
    if (stored.isEmpty) {
      return false;
    }

    final parts = stored.split(r'$');
    if (parts.length != 2) {
      throw StateError(r"The stored password must have the form 'salt$hash'.");
    }

    final salt = base64.decode(parts[0]);
    final storedHash = base64.decode(parts[1]);

    final computedHash = _generatePBKDF2Hash(password, salt);

    return storedHash == computedHash;
  }

  /// Generates a PBKDF2 hash of the password using the given salt.
  static Uint8List _generatePBKDF2Hash(String password, Uint8List salt) {
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, iterations, keyLen));
    return pbkdf2.process(Uint8List.fromList(utf8.encode(password)));
  }

  /// Generates a random salt of the specified length.
  static Uint8List _generateSalt(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)),
    );
  }
}
