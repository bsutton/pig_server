import 'dart:math';

/// Utility class for generating random strings.
class RandomString {
  /// Creates a [RandomString] generator with the given [length], [random]
  /// instance, and character [symbols].
  RandomString({int length = 21, Random? random, String? symbols})
      : _length = length,
        _random = random ?? Random.secure(),
        _symbols = symbols ?? _alphanum {
    if (length < 1) {
      throw ArgumentError('Length must be greater than 0');
    }
    if (_symbols.length < 2) {
      throw ArgumentError('Symbols must contain at least 2 characters');
    }
  }
  static const String _upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _lower = 'abcdefghijklmnopqrstuvwxyz';
  static const String _digits = '0123456789';
  static const String _alphanum = '$_upper$_lower$_digits';

  final Random _random;
  final String _symbols;
  final int _length;

  /// Generates a random string of the specified length.
  String nextString() => List.generate(
      _length, (index) => _symbols[_random.nextInt(_symbols.length)]).join();

  /// Static utility methods for quick access.
  static String generate({int length = 21, String? symbols}) =>
      RandomString(length: length, symbols: symbols).nextString();
}
