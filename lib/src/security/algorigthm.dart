/// taken from https://github.com/leocavalcante/password-dart
/// BSD 3-Clause "New" or "Revised" License
library;

import 'pbkdf2.dart';

typedef AlgorithmFactory = Algorithm Function(
    List<dynamic> params, String salt);

/// Base class for all algorithms.
abstract class Algorithm {
  static final Map<String, AlgorithmFactory> _algorithms = {
    PBKDF2.id: (List<dynamic> params, String salt) => PBKDF2(
        blockLength: int.parse(params[0] as String),
        iterationCount: int.parse(params[1] as String),
        desiredKeyLength: int.parse(params[2] as String),
        salt: salt),
  };

  /// Creates the Algorithm based on the given [hash] and using the [hash]
  /// encoded params.
  static Algorithm decode(String hash) {
    final parts = hash.split(r'$');
    final algoFactory = _algorithms[parts[1]];
    final algorithm = algoFactory!(parts[2].split(','), parts[3]);

    return algorithm;
  }

  /// Hashes the given plain-text [password].
  String process(String password);

  /// Encodes the Algorithm [id] and its [params] to the used [salt] and the
  ///  generated [hash].
  String encode(String id, List<dynamic> params, String salt, String hash) =>
      ['', id, params.join(','), salt, hash].join(r'$');
}
