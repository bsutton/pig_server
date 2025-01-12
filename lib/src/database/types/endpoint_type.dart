/// Enum representing different types of endpoints in the irrigation system.
enum EndPointType {
  valve('Valve'),
  light('Light'),
  masterValve('Master Valve');

  const EndPointType(this.displayName);

  /// Display name for the enum value.
  final String displayName;
}
