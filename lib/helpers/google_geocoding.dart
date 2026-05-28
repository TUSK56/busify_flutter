import 'dart:convert';

import 'package:application/utils/maps_config.dart';
import 'package:http/http.dart' as http;

/// Reverse-geocode lat/lng via Geoapify Geocoding API.
/// Returns governorate (admin area) and street line for parent forms.
Future<({String governorate, String street, String formatted})>
    reverseGeocodeGeoapify({
  required double latitude,
  required double longitude,
}) async {
  final key = MapsConfig.geoapifyApiKey.trim();
  if (key.isEmpty) {
    throw Exception(
      'Geoapify API key is not configured. Set GEOAPIFY_API_KEY.',
    );
  }

  final url = Uri.parse('https://api.geoapify.com/v1/geocode/reverse').replace(
    queryParameters: {
      'lat': '$latitude',
      'lon': '$longitude',
      'format': 'json',
      'apiKey': key,
    },
  );

  final response = await http.get(url);
  if (response.statusCode != 200) {
    throw Exception(
      'Could not resolve address from location (HTTP ${response.statusCode}).',
    );
  }

  final data = jsonDecode(response.body) as Map<String, dynamic>;
  final results = data['results'] as List<dynamic>? ?? const [];
  if (results.isEmpty) {
    throw Exception('Could not resolve address from location.');
  }

  final first = results.first as Map<String, dynamic>;
  final governorate = [
    (first['state'] ?? '').toString().trim(),
    (first['city'] ?? '').toString().trim(),
    (first['county'] ?? '').toString().trim(),
  ].firstWhere((s) => s.isNotEmpty, orElse: () => '');

  final street = [
    (first['street'] ?? '').toString().trim(),
    (first['suburb'] ?? '').toString().trim(),
    (first['district'] ?? '').toString().trim(),
    (first['formatted'] ?? '').toString().trim(),
  ].firstWhere((s) => s.isNotEmpty, orElse: () => '');
  final formatted = (first['formatted'] ?? '').toString().trim();

  if (governorate.isEmpty || street.isEmpty) {
    throw Exception('Could not detect governorate/street from GPS.');
  }

  return (governorate: governorate, street: street, formatted: formatted);
}

/// Forward-geocode address text via Geoapify Geocoding API.
/// Returns first match lat/lon/formatted for Egypt.
Future<({double latitude, double longitude, String formatted})>
    forwardGeocodeGeoapify({
  required String text,
}) async {
  final key = MapsConfig.geoapifyApiKey.trim();
  if (key.isEmpty) {
    throw Exception(
      'Geoapify API key is not configured. Set GEOAPIFY_API_KEY.',
    );
  }

  final q = text.trim();
  if (q.isEmpty) {
    throw Exception('Address text is required.');
  }

  final url = Uri.parse('https://api.geoapify.com/v1/geocode/search').replace(
    queryParameters: {
      'text': q,
      'format': 'json',
      'limit': '1',
      'filter': 'countrycode:eg',
      'apiKey': key,
    },
  );

  final response = await http.get(url);
  if (response.statusCode != 200) {
    throw Exception('Could not resolve address (HTTP ${response.statusCode}).');
  }

  final data = jsonDecode(response.body) as Map<String, dynamic>;
  final results = data['results'] as List<dynamic>? ?? const [];
  if (results.isEmpty) {
    throw Exception('No matching address found.');
  }

  final first = results.first as Map<String, dynamic>;
  final lat = (first['lat'] as num?)?.toDouble();
  final lon = (first['lon'] as num?)?.toDouble();
  final formatted = (first['formatted'] ?? '').toString().trim();

  if (lat == null || lon == null || formatted.isEmpty) {
    throw Exception('Incomplete geocoding response.');
  }

  return (latitude: lat, longitude: lon, formatted: formatted);
}
