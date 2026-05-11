import 'dart:convert';
import 'dart:io';

import 'package:application/models/supervisor_dashboard.dart';
import 'package:application/models/login_response.dart';
import 'package:application/services/token_storage.dart';
import 'package:application/utils/api_config.dart';
import 'package:http/http.dart' as http;

/// Service for supervisor authentication.
class SupervisorService {
  final TokenStorage _tokenStorage;

  SupervisorService(this._tokenStorage);

  static const String _basePath = '/v1/Supervisor';

  /// POST /v1/Supervisor/login
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
      throw SupervisorServiceException(message, statusCode: response.statusCode);
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

  /// POST /v1/Supervisor/send-otp — sends a reset code to the supervisor email (server must exist).
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
      throw SupervisorServiceException(message, statusCode: response.statusCode);
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

  /// GET /v1/Supervisor/me
  Future<SupervisorDashboard> getMe() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$_basePath/me');
    final resp = await http.get(uri, headers: _authHeaders());
    if (resp.statusCode != 200) {
      throw SupervisorServiceException(
        'Failed to load profile (${resp.statusCode})',
        statusCode: resp.statusCode,
      );
    }
    final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
    final dashboard = SupervisorDashboard.fromJson(decoded);

    await _tokenStorage.saveUser(
      id: dashboard.id,
      name: dashboard.name,
      email: dashboard.email,
      phone: dashboard.phone,
      photoUrl: dashboard.photoUrl,
    );
    return dashboard;
  }

  /// POST /v1/Supervisor/profile-photo
  /// Uploads a JPEG/PNG file by converting it to base64 (backend expects `imageBase64`).
  /// Returns the relative `photoUrl` returned by the server and saves it to token storage.
  Future<String> uploadProfilePhotoFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw SupervisorServiceException('Selected image file not found');
    }

    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw SupervisorServiceException('Selected image is empty');
    }

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
        } else if (decoded is Map && decoded['error'] != null) {
          message = decoded['error'] as String;
        }
      } catch (_) {}
      throw SupervisorServiceException(message, statusCode: response.statusCode);
    }

    String? photoUrl;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['photoUrl'] != null) {
        photoUrl = decoded['photoUrl']?.toString();
      }
    } catch (_) {}

    if (photoUrl == null || photoUrl.trim().isEmpty) {
      throw SupervisorServiceException('Upload succeeded but photoUrl was missing');
    }

    await _tokenStorage.saveUserPhotoUrl(photoUrl);
    return photoUrl;
  }

  /// POST /v1/Supervisor/reset-password
  /// Same structure as parent.
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
      throw SupervisorServiceException(message, statusCode: response.statusCode);
    }
  }

  /// POST /v1/Supervisor/change-password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$_basePath/change-password');
    final response = await http.post(
      uri,
      headers: _authHeaders(),
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      String message = 'Change password failed';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['message'] != null) {
          message = decoded['message'] as String;
        }
      } catch (_) {}
      throw SupervisorServiceException(message, statusCode: response.statusCode);
    }
  }

  /// POST /v1/Supervisor/sos
  Future<void> sendSos({
    double? latitude,
    double? longitude,
    String? note,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$_basePath/sos');
    final payload = <String, dynamic>{};
    if (latitude != null) payload['latitude'] = latitude;
    if (longitude != null) payload['longitude'] = longitude;
    if (note != null && note.trim().isNotEmpty) payload['note'] = note.trim();

    final response = await http.post(
      uri,
      headers: _authHeaders(),
      body: jsonEncode(payload),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Failed to send SOS';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['message'] != null) {
          message = decoded['message'] as String;
        }
      } catch (_) {}
      throw SupervisorServiceException(message, statusCode: response.statusCode);
    }
  }
}

class SupervisorServiceException implements Exception {
  final String message;
  final int? statusCode;

  SupervisorServiceException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
