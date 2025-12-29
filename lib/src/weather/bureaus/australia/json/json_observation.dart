import '../../../units/humidity.dart';
import '../../../units/latitude.dart';
import '../../../units/longitude.dart';
import '../../../units/pressure.dart';
import '../../../units/speed.dart';
import '../../../units/tempurature.dart';
import '../../../units/wind_direction.dart';
import '../../../weather_interval.dart';
import '../../../weather_interval_type.dart';

class JSONObservation implements WeatherInterval {
  final int sortOrder;

  final int wmo;

  final String name;

  final String historyProduct;

  final String localDateTime;

  final DateTime? localDateTimeFull;

  final DateTime? aifstimeUtc;

  final Latitude? lat;

  final Longitude? lon;

  final Temperature? apparentT;

  final String? cloud;

  final String? cloudType;

  final Temperature? deltaT;

  final Speed? gustKmh;

  final Speed? gustKt;

  final Temperature? airTemp;

  final Temperature? dewpt;

  final Pressure? press;

  final Pressure? pressMsl;

  final Pressure? pressQnh;

  final String? pressTend;

  final int? rainTrace;

  final Humidity? relHum;

  final String? seaState;

  final String? swellDirWorded;

  final String? visKm;

  final String? weather;

  final WindDirection? windDir;

  final Speed? windSpdKmh;

  final Speed? windSpdKt;

  JSONObservation({
    required this.sortOrder,
    required this.wmo,
    required this.name,
    required this.historyProduct,
    required this.localDateTime,
    this.localDateTimeFull,
    this.aifstimeUtc,
    this.lat,
    this.lon,
    this.apparentT,
    this.cloud,
    this.cloudType,
    this.deltaT,
    this.gustKmh,
    this.gustKt,
    this.airTemp,
    this.dewpt,
    this.press,
    this.pressMsl,
    this.pressQnh,
    this.pressTend,
    this.rainTrace,
    this.relHum,
    this.seaState,
    this.swellDirWorded,
    this.visKm,
    this.weather,
    this.windDir,
    this.windSpdKmh,
    this.windSpdKt,
  });

  factory JSONObservation.fromJson(Map<String, dynamic> json) =>
      JSONObservation(
        sortOrder: _parseInt(json['sort_order']) ?? 0,
        wmo: _parseInt(json['wmo']) ?? 0,
        name: json['name']?.toString() ?? '',
        historyProduct: json['history_product']?.toString() ?? '',
        localDateTime: json['local_date_time']?.toString() ?? '',
        localDateTimeFull:
            _parseBomLocal(json['local_date_time_full'] as String?),
        aifstimeUtc: _parseBomUtc(json['aifstime_utc'] as String?),
        lat: json['lat'] != null ? Latitude(json['lat'].toString()) : null,
        lon: json['lon'] != null ? Longitude(json['lon'].toString()) : null,
        apparentT: json['apparent_t'] != null
            ? Temperature(json['apparent_t'].toString())
            : null,
        cloud: json['cloud']?.toString(),
        cloudType: json['cloud_type']?.toString(),
        deltaT: json['delta_t'] != null
            ? Temperature(json['delta_t'].toString())
            : null,
        gustKmh: json['gust_kmh'] != null
            ? Speed(json['gust_kmh'].toString())
            : null,
        gustKt:
            json['gust_kt'] != null ? Speed(json['gust_kt'].toString()) : null,
        airTemp: json['air_temp'] != null
            ? Temperature(json['air_temp'].toString())
            : null,
        dewpt: json['dewpt'] != null
            ? Temperature(json['dewpt'].toString())
            : null,
        press:
            json['press'] != null ? Pressure(json['press'].toString()) : null,
        pressMsl: json['press_msl'] != null
            ? Pressure(json['press_msl'].toString())
            : null,
        pressQnh: json['press_qnh'] != null
            ? Pressure(json['press_qnh'].toString())
            : null,
        pressTend: json['press_tend']?.toString(),
        rainTrace: _parseInt(json['rain_trace']),
        relHum: json['rel_hum'] != null
            ? Humidity(json['rel_hum'].toString())
            : null,
        seaState: json['sea_state']?.toString(),
        swellDirWorded: json['swell_dir_worded']?.toString(),
        visKm: json['vis_km']?.toString(),
        weather: json['weather']?.toString(),
        windDir: json['wind_dir'] != null
            ? WindDirection.fromAbbreviation(json['wind_dir'] as String)
            : null,
        windSpdKmh: json['wind_spd_kmh'] != null
            ? Speed(json['wind_spd_kmh'].toString())
            : null,
        windSpdKt: json['wind_spd_kt'] != null
            ? Speed(json['wind_spd_kt'].toString())
            : null,
      );

  static DateTime? _parseBomLocal(String? value) {
    final cleaned = value?.trim();
    if (cleaned == null || cleaned.isEmpty) {
      return null;
    }
    if (cleaned.contains('T')) {
      return DateTime.tryParse(cleaned);
    }
    return _parseCompactDateTime(cleaned, isUtc: false);
  }

  static DateTime? _parseBomUtc(String? value) {
    final cleaned = value?.trim();
    if (cleaned == null || cleaned.isEmpty) {
      return null;
    }
    if (cleaned.contains('T')) {
      return DateTime.tryParse(cleaned)?.toUtc();
    }
    return _parseCompactDateTime(cleaned, isUtc: true);
  }

  static DateTime? _parseCompactDateTime(String value, {required bool isUtc}) {
    if (value.length != 14 || !RegExp(r'^\d{14}$').hasMatch(value)) {
      return null;
    }
    try {
      final year = int.parse(value.substring(0, 4));
      final month = int.parse(value.substring(4, 6));
      final day = int.parse(value.substring(6, 8));
      final hour = int.parse(value.substring(8, 10));
      final minute = int.parse(value.substring(10, 12));
      final second = int.parse(value.substring(12, 14));
      return isUtc
          ? DateTime.utc(year, month, day, hour, minute, second)
          : DateTime(year, month, day, hour, minute, second);
    } catch (_) {
      return null;
    }
  }

  static int? _parseInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'sort_order': sortOrder,
        'wmo': wmo,
        'name': name,
        'history_product': historyProduct,
        'local_date_time': localDateTime,
        'local_date_time_full': localDateTimeFull?.toIso8601String(),
        'aifstime_utc': aifstimeUtc?.toIso8601String(),
        'lat': lat?.toJson(),
        'lon': lon?.toJson(),
        'apparent_t': apparentT?.toJson(),
        'cloud': cloud,
        'cloud_type': cloudType,
        'delta_t': deltaT?.toJson(),
        'gust_kmh': gustKmh?.toJson(),
        'gust_kt': gustKt?.toJson(),
        'air_temp': airTemp?.toJson(),
        'dewpt': dewpt?.toJson(),
        'press': press?.toJson(),
        'press_msl': pressMsl?.toJson(),
        'press_qnh': pressQnh?.toJson(),
        'press_tend': pressTend,
        'rain_trace': rainTrace,
        'rel_hum': relHum?.toJson(),
        'sea_state': seaState,
        'swell_dir_worded': swellDirWorded,
        'vis_km': visKm,
        'weather': weather,
        'wind_dir': windDir?.abbreviation,
        'wind_spd_kmh': windSpdKmh?.toJson(),
        'wind_spd_kt': windSpdKt?.toJson(),
      };

  @override
  WeatherIntervalType get weatherIntervalType =>
      WeatherIntervalType.observation;

  @override
  Temperature? get temperature => airTemp;

  @override
  Temperature? get apparentTemperature => apparentT;

  int? get rainFail => rainTrace;

  @override
  Pressure? get pressure => press;

  @override
  Humidity? get humidity => relHum;

  @override
  Speed? get windSpeed => windSpdKmh;

  @override
  Latitude? get latitude => lat;

  @override
  Longitude? get longitude => lon;

  @override
  WindDirection? get windDirection => windDir;

  @override
  DateTime? get startOfInterval => localDateTimeFull;

  @override
  DateTime? get endOfInterval => null;

  @override
  Duration? get intervalDuration => null;

  @override
  int? get rainFall => rainTrace;

  @override
  String toString() => '''
JSONObservation {
  sortOrder: $sortOrder,
  wmo: $wmo,
  name: $name,
  ...
}
''';
}
