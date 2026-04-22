import 'dart:convert';

import 'package:application/models/child.dart';
import 'package:application/models/login_response.dart';
import 'package:application/services/token_storage.dart';
import 'package:application/utils/api_config.dart';
import 'package:http/http.dart' as http;

/// Service for parent authentication and registration.
class ParentService {
  final TokenStorage _tokenStorage;

  ParentService(this._tokenStorage);

  static const String _basePath = '/v1/parent';

  /// POST /v1/parent/register
  /// photoUrl is sent as null (not required).
  Future<void> register({
    required String name,
    required String phone,
    required String email,
    required String password,
    required double latitude,
    required double longitude,
    required String governorate,
    required String street,
    required List<Child> children,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$_basePath/register');
    final body = {
      'name': name,
      'phone': phone,
      'email': email,
      'password': password,
      'address': '$latitude,$longitude',
      'governorate': governorate,
      'street': street,
      // NOTE: Backend currently validates parent-level schoolId.
      // We derive it from the selected child's schoolId.
      if (children.isNotEmpty) 'schoolId': children.first.schoolId,
      'children': children.map((c) => c.toJson()).toList(),
    };

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final errorBody = response.body;
      String message = 'Registration failed';
      try {
        final decoded = jsonDecode(errorBody);
        if (decoded is Map && decoded['message'] != null) {
          message = decoded['message'] as String;
        } else if (decoded is Map && decoded['errors'] != null) {
          message = (decoded['errors'] as Map).values.join(', ');
        }
      } catch (_) {}
      throw ParentServiceException(message, statusCode: response.statusCode);
    }
  }

  /// POST /v1/parent/login
  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$_basePath/login');
    final body = {'email': email, 'password': password};

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      String message = 'Login failed';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['message'] != null) {
          message = decoded['message'] as String;
        }
      } catch (_) {}
      throw ParentServiceException(message, statusCode: response.statusCode);
    }

    final loginResponse = LoginResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
    await _tokenStorage.saveToken(loginResponse.token);
    await _tokenStorage.saveUser(
      id: loginResponse.user.id,
      name: loginResponse.user.name,
      email: loginResponse.user.email,
      phone: loginResponse.user.phone,
    );
    return loginResponse;
  }

  /// POST /v1/parent/reset-password
  /// OTP validated locally as "0000" for testing.
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$_basePath/reset-password');
    final body = {
      'email': email,
      'otp': otp,
      'newPassword': newPassword,
    };

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      String message = 'Reset password failed';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['message'] != null) {
          message = decoded['message'] as String;
        }
      } catch (_) {}
      throw ParentServiceException(message, statusCode: response.statusCode);
    }
  }

  Map<String, String> _authHeaders() {
    final token = _tokenStorage.getToken();
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// GET /v1/parent/child
  Future<Map<String, dynamic>> getChildOverview() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$_basePath/child');
    final response = await http.get(uri, headers: _authHeaders());
    if (response.statusCode != 200) {
      throw ParentServiceException(
        'Failed to load child data (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// GET /v1/parent/profile
  Future<Map<String, dynamic>> getProfile() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$_basePath/profile');
    final response = await http.get(uri, headers: _authHeaders());
    if (response.statusCode != 200) {
      throw ParentServiceException(
        'Failed to load parent profile (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// POST /v1/parent/child
  /// Creates a new child (student) for the logged-in parent.
  Future<Map<String, dynamic>> addChild({
    required String name,
    required String birthdate, // yyyy-MM-dd
    required String grade,
    required int parentId,
    int? busId,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$_basePath/child');
    final body = {
      'name': name,
      'birthdate': birthdate,
      'grade': grade,
      'parentId': parentId,
      if (busId != null) 'busId': busId,
    };
    final response = await http.post(
      uri,
      headers: _authHeaders(),
      body: jsonEncode(body),
    );
    if (response.statusCode != 200 &&
        response.statusCode != 201 &&
        response.statusCode != 204) {
      throw ParentServiceException(
        'Failed to add child (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }
    if (response.body.isEmpty) {
      return const <String, dynamic>{};
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// GET /v1/parent/current-trip
  Future<Map<String, dynamic>> getCurrentTrip() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$_basePath/current-trip');
    final response = await http.get(uri, headers: _authHeaders());
    if (response.statusCode != 200) {
      throw ParentServiceException(
        'Failed to load current trip (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// GET /v1/parent/live-location?tripId=...
  Future<Map<String, dynamic>> getLiveLocation(int tripId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$_basePath/live-location?tripId=$tripId');
    final response = await http.get(uri, headers: _authHeaders());
    if (response.statusCode != 200) {
      throw ParentServiceException(
        'Failed to load live location (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}

class ParentServiceException implements Exception {
  final String message;
  final int? statusCode;

  ParentServiceException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
