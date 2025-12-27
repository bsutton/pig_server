import 'package:fixed/fixed.dart';

class Longitude {
  final Fixed longitude;

  Longitude(String longitude) : longitude = Fixed.parse(longitude);

  // Factory constructor to create a Longitude from JSON
  factory Longitude.fromJson(Map<String, dynamic> json) =>
      Longitude(json['longitude'] as String);

  @override
  String toString() => 'Longitude=$longitude';

  // Method to convert Longitude to JSON
  Map<String, dynamic> toJson() => {
        'longitude': longitude.toString(),
      };
}
