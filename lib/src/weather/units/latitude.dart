import 'package:fixed/fixed.dart';

class Latitude {
  Latitude(String latitude) : latitude = Fixed.parse(latitude);

  // Factory constructor to create a Latitude from JSON
  factory Latitude.fromJson(Map<String, dynamic> json) =>
      Latitude(json['latitude'] as String);
  final Fixed latitude;

  @override
  String toString() => 'Latitude=$latitude';

  // Method to convert Latitude to JSON
  Map<String, dynamic> toJson() => {
        'latitude': latitude.toString(),
      };
}
