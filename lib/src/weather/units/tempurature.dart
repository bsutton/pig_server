import 'package:fixed/fixed.dart';

/// Represents a temperature measurement.
class Temperature {
  /// Creates a [Temperature] object from a string representation of
  /// the temperature value.
  Temperature(String temperature) : temperature = Fixed.parse(temperature);

  /// Creates a [Temperature] object from a JSON representation.
  factory Temperature.fromJson(Map<String, dynamic> json) =>
      Temperature(json['temperature'] as String);

  final Fixed temperature;

  @override
  String toString() => 'Temperature=$temperature °C';

  /// Converts a [Temperature] object to a JSON representation.
  Map<String, dynamic> toJson() => {
        'temperature': temperature.toString(),
      };
}
