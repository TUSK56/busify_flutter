import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

/// Result of resolving GPS → governorate/street (same Nominatim flow as parent signup).
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
    desiredAccuracy: LocationAccuracy.bestForNavigation,
  );

  final url = Uri.parse(
    'https://nominatim.openstreetmap.org/reverse?lat=${position.latitude}&lon=${position.longitude}&format=jsonv2',
  );
  final response = await http.get(
    url,
    headers: const {'User-Agent': 'busify-parent-app/1.0'},
  );
  if (response.statusCode != 200) {
    throw Exception('Could not resolve address from location.');
  }
  final data = jsonDecode(response.body) as Map<String, dynamic>;
  final address = (data['address'] as Map<String, dynamic>?) ?? const {};
  final governorate =
      (address['state'] ?? address['city'] ?? address['county'] ?? '')
          .toString()
          .trim();
  final street =
      (address['road'] ?? address['suburb'] ?? address['neighbourhood'] ?? '')
          .toString()
          .trim();
  if (governorate.isEmpty || street.isEmpty) {
    throw Exception('Could not detect governorate/street from GPS.');
  }

  return ParentResolvedGps(
    latitude: position.latitude,
    longitude: position.longitude,
    governorate: governorate,
    street: street,
  );
}
