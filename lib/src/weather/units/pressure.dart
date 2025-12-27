import 'package:fixed/fixed.dart';

class Pressure {
  final Fixed pressure;

  Pressure(String pressure) : pressure = Fixed.parse(pressure);

  // Factory constructor to create a Pressure from JSON
  factory Pressure.fromJson(Map<String, dynamic> json) =>
      Pressure(json['pressure'] as String);

  @override
  String toString() => 'Pressure=$pressure';

  // Method to convert Pressure to JSON
  Map<String, dynamic> toJson() => {
        'pressure': pressure.toString(),
      };
}
