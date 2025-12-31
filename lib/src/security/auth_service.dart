import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

import '../config.dart';
import 'helper.dart';

class AuthChallenge {
  final String nonce;

  final String algorithm;

  final List<int> params;

  final String salt;

  AuthChallenge({
    required this.nonce,
    required this.algorithm,
    required this.params,
    required this.salt,
  });

  Map<String, dynamic> toJson() => {
        'nonce': nonce,
        'algorithm': algorithm,
        'params': params,
        'salt': salt,
      };
}

class AuthToken {
  final String value;

  final DateTime expiresAt;

  AuthToken(this.value, this.expiresAt);
}

class AuthService {
  static final instance = AuthService._();

  static const _nonceTtl = Duration(minutes: 5);

  static const _tokenTtl = Duration(hours: 12);

  static const _pbkdf2BlockLength = 64;

  static const _pbkdf2Iterations = 20000;

  static const _pbkdf2KeyLength = 32;

  static const _algorithmId = 'pbkdf2-sha256';

  final Map<String, DateTime> _nonceExpiry = {};

  final Map<String, DateTime> _tokenExpiry = {};

  AuthService._();

  AuthChallenge createChallenge() {
    final stored = Config().password;
    if (stored == null || stored.isEmpty) {
      throw StateError('Server password is not configured');
    }
    final parsed = _parseHash(stored);
    final nonce = _randomBase64(32);
    _nonceExpiry[nonce] = DateTime.now().add(_nonceTtl);
    return AuthChallenge(
      nonce: nonce,
      algorithm: parsed.algorithm,
      params: parsed.params,
      salt: parsed.salt,
    );
  }

  AuthToken? verifyLogin({
    required String nonce,
    required String responseHex,
  }) {
    final expiresAt = _nonceExpiry[nonce];
    if (expiresAt == null || DateTime.now().isAfter(expiresAt)) {
      _nonceExpiry.remove(nonce);
      return null;
    }
    final stored = Config().password;
    if (stored == null || stored.isEmpty) {
      return null;
    }
    final parsed = _parseHash(stored);
    final expected = _hmacHex(
      key: base64.decode(parsed.hash),
      message: 'pigation:$nonce',
    );
    if (!_constantTimeEquals(expected, responseHex)) {
      return null;
    }
    _nonceExpiry.remove(nonce);
    final token = _randomBase64(32);
    final tokenExpiresAt = DateTime.now().add(_tokenTtl);
    _tokenExpiry[token] = tokenExpiresAt;
    return AuthToken(token, tokenExpiresAt);
  }

  bool isValidToken(String? token) {
    if (token == null || token.isEmpty) {
      return false;
    }
    final expiresAt = _tokenExpiry[token];
    if (expiresAt == null) {
      return false;
    }
    if (DateTime.now().isAfter(expiresAt)) {
      _tokenExpiry.remove(token);
      return false;
    }
    return true;
  }

  _ParsedPassword _parseHash(String hash) {
    final parts = hash.split(r'$');
    if (parts.length != 2) {
      throw StateError(
        r"Invalid password hash format. Expected 'salt$hash'.",
      );
    }
    const algorithm = _algorithmId;
    final params = [
      _pbkdf2BlockLength,
      _pbkdf2Iterations,
      _pbkdf2KeyLength,
    ];
    final salt = parts[0];
    final derivedBase64 = parts[1];
    return _ParsedPassword(
      algorithm: algorithm,
      params: params,
      salt: salt,
      hash: derivedBase64,
    );
  }

  String _hmacHex({
    required Uint8List key,
    required String message,
  }) {
    final hmac = HMac(SHA256Digest(), 64)..init(KeyParameter(key));
    final digest = hmac.process(Uint8List.fromList(utf8.encode(message)));
    return formatBytesAsHexString(digest);
  }

  String _randomBase64(int length) {
    final rnd = Random.secure();
    final bytes = Uint8List.fromList(
      List<int>.generate(length, (_) => rnd.nextInt(256)),
    );
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) {
      return false;
    }
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }
}

class _ParsedPassword {
  final String algorithm;

  final List<int> params;

  final String salt;

  final String hash;

  _ParsedPassword({
    required this.algorithm,
    required this.params,
    required this.salt,
    required this.hash,
  });
}
