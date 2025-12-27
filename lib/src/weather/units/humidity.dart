import 'package:fixed/fixed.dart';

class Humidity {
  final Fixed humidity;

  Humidity(String humidity) : humidity = Fixed.parse(humidity);

  // Factory constructor to create a Humidity from JSON
  factory Humidity.fromJson(Map<String, dynamic> json) =>
      Humidity(json['humidity'] as String);

  @override
  String toString() => 'Humidity=$humidity';

  // Method to convert Humidity to JSON
  Map<String, dynamic> toJson() => {
        'humidity': humidity.toString(),
      };
}
