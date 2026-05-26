import 'dart:convert';

import 'package:application/utils/maps_config.dart';
import 'package:http/http.dart' as http;

/// Reverse-geocode lat/lng via Google Geocoding API.
/// Returns governorate (admin area) and street line for parent forms.
Future<({String governorate, String street})> reverseGeocodeGoogle({
  required double latitude,
  required double longitude,
}) async {
  final key = MapsConfig.googleMapsApiKey.trim();
  if (key.isEmpty) {
    throw Exception(
      'Google Maps API key is not configured. Set GOOGLE_MAPS_API_KEY.',
    );
  }

  final url = Uri.parse(
    'https://maps.googleapis.com/maps/api/geocode/json'
    '?latlng=$latitude,$longitude&key=$key',
  );
  final response = await http.get(url);
  if (response.statusCode != 200) {
    throw Exception('Could not resolve address from location.');
  }

  final data = jsonDecode(response.body) as Map<String, dynamic>;
  final status = (data['status'] ?? '').toString();
  if (status != 'OK') {
    throw Exception('Could not resolve address from location ($status).');
  }

  final results = data['results'] as List<dynamic>? ?? const [];
  if (results.isEmpty) {
    throw Exception('Could not resolve address from location.');
  }

  final components =
      ((results.first as Map<String, dynamic>)['address_components']
              as List<dynamic>?) ??
          const [];

  String pickType(String type) {
    for (final raw in components) {
      final c = raw as Map<String, dynamic>;
      final types = (c['types'] as List<dynamic>? ?? const [])
          .map((t) => t.toString())
          .toList();
      if (types.contains(type)) {
        return (c['long_name'] ?? c['short_name'] ?? '').toString().trim();
      }
    }
    return '';
  }

  final governorate = [
    pickType('administrative_area_level_1'),
    pickType('locality'),
    pickType('administrative_area_level_2'),
  ].firstWhere((s) => s.isNotEmpty, orElse: () => '');

  final street = [
    pickType('route'),
    pickType('sublocality'),
    pickType('neighborhood'),
    pickType('premise'),
  ].firstWhere((s) => s.isNotEmpty, orElse: () => '');

  if (governorate.isEmpty || street.isEmpty) {
    throw Exception('Could not detect governorate/street from GPS.');
  }

  return (governorate: governorate, street: street);
}
