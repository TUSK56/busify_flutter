import 'dart:convert';
import 'dart:io';

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
      photoUrl: loginResponse.user.photoUrl,
    );
    return loginResponse;
  }

  /// POST /v1/parent/send-otp — sends a reset code when the parent email exists.
  Future<void> sendPasswordResetOtp({required String email}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$_basePath/send-otp');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim()}),
    );

    if (response.statusCode != 200) {
      String message = 'Could not send code';
      if (response.statusCode == 404) {
        message = 'No account found for this email.';
      } else {
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map && decoded['message'] != null) {
            message = decoded['message'] as String;
          }
        } catch (_) {}
      }
      throw ParentServiceException(message, statusCode: response.statusCode);
    }
  }

  /// POST /v1/parent/reset-password
  Future<void> verifyResetOtp({
    required String email,
    required String otp,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$_basePath/verify-reset-otp');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'otp': otp.trim(),
      }),
    );

    if (response.statusCode != 200) {
      String message = 'Invalid or expired OTP';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['message'] != null) {
          message = decoded['message'] as String;
        }
      } catch (_) {}
      throw ParentServiceException(message, statusCode: response.statusCode);
    }
  }

  /// POST /v1/parent/reset-password
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
  Future<Map<String, dynamic>> getChildOverview({int? studentId}) async {
    final qp = <String, String>{};
    if (studentId != null && studentId > 0) {
      qp['studentId'] = '$studentId';
    }
    final uri = Uri.parse('${ApiConfig.baseUrl}$_basePath/child')
        .replace(queryParameters: qp.isEmpty ? null : qp);
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

  /// GET /v1/schools (public)
  Future<List<Map<String, dynamic>>> getSchools() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/v1/schools');
    final response = await http.get(uri, headers: {'Content-Type': 'application/json'});
    if (response.statusCode != 200) {
      throw ParentServiceException(
        'Failed to load schools (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is Map && decoded['schools'] is List) {
      return (decoded['schools'] as List)
          .whereType<Map>()
          .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
          .cast<Map<String, dynamic>>()
          .toList();
    }
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
          .cast<Map<String, dynamic>>()
          .toList();
    }
    return const [];
  }

  /// POST /v1/parent/change-password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$_basePath/change-password');
    final body = {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    };
    final response = await http.post(
      uri,
      headers: _authHeaders(),
      body: jsonEncode(body),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      String message = 'Change password failed';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['message'] != null) {
          message = decoded['message'] as String;
        }
      } catch (_) {}
      throw ParentServiceException(message, statusCode: response.statusCode);
    }
  }

  /// POST /v1/parent/profile-photo
  Future<String> uploadProfilePhotoFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw ParentServiceException('Selected image file not found');
    }
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) throw ParentServiceException('Selected image is empty');

    final base64Data = base64Encode(bytes);
    final uri = Uri.parse('${ApiConfig.baseUrl}$_basePath/profile-photo');
    final body = {'imageBase64': base64Data};

    final response = await http.post(
      uri,
      headers: _authHeaders(),
      body: jsonEncode(body),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      String message = 'Upload failed';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['message'] != null) {
          message = decoded['message'] as String;
        }
      } catch (_) {}
      throw ParentServiceException(message, statusCode: response.statusCode);
    }
    final decoded = jsonDecode(response.body);
    final photoUrl = decoded is Map ? decoded['photoUrl']?.toString() : null;
    if (photoUrl == null || photoUrl.trim().isEmpty) {
      throw ParentServiceException('Upload succeeded but photoUrl was missing');
    }
    await _tokenStorage.saveUserPhotoUrl(photoUrl);
    return photoUrl;
  }

  /// POST /v1/parent/device-token
  Future<void> upsertDeviceToken(String token) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$_basePath/device-token');
    final response = await http.post(
      uri,
      headers: _authHeaders(),
      body: jsonEncode({'token': token}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ParentServiceException(
        'Failed to register device token (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }
  }

  /// PATCH /v1/parent/profile
  Future<Map<String, dynamic>> updateProfile({
    required String email,
    required String phone,
    String? address,
    String? governorate,
    String? street,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$_basePath/profile');
    final body = <String, dynamic>{
      'email': email,
      'phone': phone,
      if (address != null) 'address': address,
      if (governorate != null) 'governorate': governorate,
      if (street != null) 'street': street,
    };
    final response = await http.patch(
      uri,
      headers: _authHeaders(),
      body: jsonEncode(body),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      String message = 'Update profile failed';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['message'] != null) {
          message = decoded['message'] as String;
        }
      } catch (_) {}
      throw ParentServiceException(message, statusCode: response.statusCode);
    }
    if (response.body.isEmpty) return const {};
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// POST /v1/parent/child
  /// Creates a new child (student) for the logged-in parent.
  Future<Map<String, dynamic>> addChild({
    required String name,
    required String birthdate, // yyyy-MM-dd
    required String grade,
    required int parentId,
    required int schoolId,
    int? busId,
    String? photoBase64,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$_basePath/child');
    final body = {
      'name': name,
      'birthdate': birthdate,
      'grade': grade,
      'parentId': parentId,
      'schoolId': schoolId,
      if (busId != null) 'busId': busId,
      if (photoBase64 != null && photoBase64.trim().isNotEmpty)
        'photoBase64': photoBase64.trim(),
    };
    final response = await http.post(
      uri,
      headers: _authHeaders(),
      body: jsonEncode(body),
    );
    if (response.statusCode != 200 &&
        response.statusCode != 201 &&
        response.statusCode != 204) {
      String message = 'Failed to add child';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['message'] != null) {
          message = decoded['message'] as String;
        }
      } catch (_) {}
      throw ParentServiceException('$message (${response.statusCode})', statusCode: response.statusCode);
    }
    if (response.body.isEmpty) {
      return const <String, dynamic>{};
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// GET /v1/parent/current-trip
  Future<Map<String, dynamic>> getCurrentTrip({int? studentId}) async {
    final qp = <String, String>{};
    if (studentId != null && studentId > 0) {
      qp['studentId'] = '$studentId';
    }
    final uri = Uri.parse('${ApiConfig.baseUrl}$_basePath/current-trip')
        .replace(queryParameters: qp.isEmpty ? null : qp);
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

  /// GET /v1/parent/attendance
  Future<List<Map<String, dynamic>>> getAttendance({
    int? studentId,
    int? tripId,
    String? fromDate, // yyyy-MM-dd
    String? toDate, // yyyy-MM-dd
  }) async {
    final qp = <String, String>{};
    if (studentId != null && studentId > 0) qp['studentId'] = '$studentId';
    if (tripId != null && tripId > 0) qp['tripId'] = '$tripId';
    if (fromDate != null && fromDate.trim().isNotEmpty) qp['fromDate'] = fromDate.trim();
    if (toDate != null && toDate.trim().isNotEmpty) qp['toDate'] = toDate.trim();

    final uri = Uri.parse('${ApiConfig.baseUrl}$_basePath/attendance').replace(
      queryParameters: qp.isEmpty ? null : qp,
    );
    final response = await http.get(uri, headers: _authHeaders());
    if (response.statusCode != 200) {
      throw ParentServiceException(
        'Failed to load attendance (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is Map && decoded['attendance'] is List) {
      return (decoded['attendance'] as List)
          .whereType<Map>()
          .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
          .cast<Map<String, dynamic>>()
          .toList();
    }
    return const [];
  }
}

class ParentServiceException implements Exception {
  final String message;
  final int? statusCode;

  ParentServiceException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
