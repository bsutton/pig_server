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
        sortOrder: json['sort_order'] as int,
        wmo: json['wmo'] as int,
        name: json['name'] as String,
        historyProduct: json['history_product'] as String,
        localDateTime: json['local_date_time'] as String,
        localDateTimeFull: json['local_date_time_full'] != null
            ? DateTime.parse(json['local_date_time_full'] as String)
            : null,
        aifstimeUtc: json['aifstime_utc'] != null
            ? DateTime.parse(json['aifstime_utc'] as String)
            : null,
        lat: json['lat'] != null
            ? Latitude.fromJson(json['lat'] as Map<String, dynamic>)
            : null,
        lon: json['lon'] != null
            ? Longitude.fromJson(json['lon'] as Map<String, dynamic>)
            : null,
        apparentT: json['apparent_t'] != null
            ? Temperature.fromJson(json['apparent_t'] as Map<String, dynamic>)
            : null,
        cloud: json['cloud'] as String?,
        cloudType: json['cloud_type'] as String?,
        deltaT: json['delta_t'] != null
            ? Temperature.fromJson(json['delta_t'] as Map<String, dynamic>)
            : null,
        gustKmh: json['gust_kmh'] != null
            ? Speed.fromJson(json['gust_kmh'] as Map<String, dynamic>)
            : null,
        gustKt: json['gust_kt'] != null
            ? Speed.fromJson(json['gust_kt'] as Map<String, dynamic>)
            : null,
        airTemp: json['air_temp'] != null
            ? Temperature.fromJson(json['air_temp'] as Map<String, dynamic>)
            : null,
        dewpt: json['dewpt'] != null
            ? Temperature.fromJson(json['dewpt'] as Map<String, dynamic>)
            : null,
        press: json['press'] != null
            ? Pressure.fromJson(json['press'] as Map<String, dynamic>)
            : null,
        pressMsl: json['press_msl'] != null
            ? Pressure.fromJson(json['press_msl'] as Map<String, dynamic>)
            : null,
        pressQnh: json['press_qnh'] != null
            ? Pressure.fromJson(json['press_qnh'] as Map<String, dynamic>)
            : null,
        pressTend: json['press_tend'] as String?,
        rainTrace: json['rain_trace'] as int?,
        relHum: json['rel_hum'] != null
            ? Humidity.fromJson(json['rel_hum'] as Map<String, dynamic>)
            : null,
        seaState: json['sea_state'] as String?,
        swellDirWorded: json['swell_dir_worded'] as String?,
        visKm: json['vis_km'] as String?,
        weather: json['weather'] as String?,
        windDir: json['wind_dir'] != null
            ? WindDirection.fromAbbreviation(json['wind_dir'] as String)
            : null,
        windSpdKmh: json['wind_spd_kmh'] != null
            ? Speed.fromJson(json['wind_spd_kmh'] as Map<String, dynamic>)
            : null,
        windSpdKt: json['wind_spd_kt'] != null
            ? Speed.fromJson(json['wind_spd_kt'] as Map<String, dynamic>)
            : null,
      );
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
