import 'package:fixed/fixed.dart';

/// Represents the speed of a measurement.
class Speed {
  /// Creates a [Speed] object from a string representation of the speed value.
  Speed(String speed) : speed = Fixed.parse(speed);

  /// Creates a [Speed] object from a JSON representation.
  Speed.fromJson(Map<String, dynamic> json)
      : speed = Fixed.parse(json['speed'] as String);

  final Fixed speed;

  @override
  String toString() => 'Speed=$speed km';

  /// Converts a [Speed] object to a JSON representation.
  Map<String, dynamic> toJson() => {
        'speed': speed.toString(),
      };
}
