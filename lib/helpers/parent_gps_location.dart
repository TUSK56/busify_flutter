import 'package:application/constants/location_tracking.dart';
import 'package:application/helpers/google_geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// Result of resolving GPS → governorate/street (Geoapify Geocoding).
class ParentResolvedGps {
  const ParentResolvedGps({
    required this.latitude,
    required this.longitude,
    required this.governorate,
    required this.street,
  });

  final double latitude;
  final double longitude;
  final String governorate;
  final String street;

  /// Same display format as signup: "Governorate, Street"
  String get displayLine => '$governorate, $street';

  /// Stored in API `address` field at registration.
  String get addressLatLngCsv =>
      '${latitude.toStringAsFixed(6)},${longitude.toStringAsFixed(6)}';
}

/// Throws [Exception] with a user-facing message on failure.
Future<ParentResolvedGps> resolveParentGpsWithNominatim() async {
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    throw Exception('Please enable location services.');
  }

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    throw Exception('Location permission is required to continue.');
  }

  final position = await Geolocator.getCurrentPosition(
    desiredAccuracy: kFastLocationSettings.accuracy,
    timeLimit: kFastLocationSettings.timeLimit,
  );

  final address = await reverseGeocodeGeoapify(
    latitude: position.latitude,
    longitude: position.longitude,
  );

  return ParentResolvedGps(
    latitude: position.latitude,
    longitude: position.longitude,
    governorate: address.governorate,
    street: address.street,
  );
}
