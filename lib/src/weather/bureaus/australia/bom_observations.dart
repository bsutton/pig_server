import 'json/json_observations.dart';

/// Represents Bureau of Meteorology (BOM) observations.
class BOMObservations {
  /// The JSON observations associated with this instance.
  final JSONObservations observations;

  /// Creates a [BOMObservations] instance with the given [observations].
  BOMObservations(this.observations);

  @override
  String toString() {
    return 'BOMObservations [observations=$observations]';
  }
}
