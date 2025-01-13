import 'json/json_observations.dart';

/// Represents Bureau of Meteorology (BOM) observations.
class BOMObservations {

  /// Creates a [BOMObservations] instance with the given [observations].
  BOMObservations(this.observations);
  /// The JSON observations associated with this instance.
  final JSONObservations observations;

  @override
  String toString() => 'BOMObservations [observations=$observations]';
}
