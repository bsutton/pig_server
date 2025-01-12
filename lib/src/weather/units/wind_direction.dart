/// Represents the possible wind directions with their abbreviations.
enum WindDirection {
  calm('Calm'),
  south('S'),
  southWest('SW'),
  southSouthWest('SSW'),
  southEast('SE'),
  southSouthEast('SSE'),
  north('North'),
  northWest('NW'),
  northNorthWest('NNW'),
  northEast('NE'),
  northNorthEast('NNE'),
  west('W'),
  westNorthWest('WNW'),
  westSouthWest('WSW'),
  east('E'),
  eastNorthEast('ENE'),
  eastSouthEast('ESE');

  final String abbreviation;

  /// Constructor for each wind direction with an associated abbreviation.
  const WindDirection(this.abbreviation);

  /// Returns a [WindDirection] based on its abbreviation.
  /// Defaults to [WindDirection.calm] if no match is found.
  static WindDirection fromAbbreviation(String abbreviation) =>
      WindDirection.values.firstWhere(
        (direction) => direction.abbreviation == abbreviation,
        orElse: () => WindDirection.calm,
      );
}
