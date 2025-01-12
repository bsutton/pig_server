import 'australia/bureau_of_meterology_australia.dart';
import 'weather_bureau.dart';

/// Manages a collection of weather bureaus.
class WeatherBureaus {
  /// The list of registered weather bureaus.
  static final List<WeatherBureau> _bureaus = [];

  /// The default weather bureau.
  static WeatherBureau? _defaultBureau;

  /// Static initializer to register the default bureaus.
  static void initialize() {
    // Register your bureau here.
    // Ensure minimal initialization logic to avoid early runtime issues.
    register(BureauOfMeterologyAustralia());
  }

  /// Registers a [WeatherBureau].
  static void register(WeatherBureau bureau) {
    _bureaus.add(bureau);
  }

  /// Sets the default weather bureau.
  static void setDefaultBureau(WeatherBureau bureau) {
    _defaultBureau = bureau;
  }

  /// Gets the default weather bureau.
  static WeatherBureau? getDefaultBureau() {
    return _defaultBureau;
  }

  /// Gets the list of all registered weather bureaus.
  static List<WeatherBureau> getBureaus() {
    return _bureaus;
  }
}
