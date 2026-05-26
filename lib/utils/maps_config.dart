/// Google Maps / Geocoding API key.
///
/// Pass at build/run time:
/// `flutter run --dart-define=GOOGLE_MAPS_API_KEY=your_key`
///
/// Also set the same key in:
/// - [android/app/src/main/res/values/strings.xml] (`google_maps_key`)
/// - [ios/Runner/Info.plist] (`GMSApiKey`)
class MapsConfig {
  MapsConfig._();

  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  static bool get hasApiKey => googleMapsApiKey.trim().isNotEmpty;
}
