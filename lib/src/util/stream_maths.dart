import 'dart:async';

/// Utility class for performing mathematical operations on streams.
class StreamMaths {
  /// Sums the durations in a stream using the provided [functor] 
  /// to map each element.
  static Future<Duration> sum<T>(
    Stream<T> stream,
    Duration Function(T) functor,
  ) async {
    var total = Duration.zero;
    await for (final element in stream) {
      total += functor(element);
    }
    return total;
  }
}
