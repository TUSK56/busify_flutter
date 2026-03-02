import 'dart:convert';

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
    return loginResponse;
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
}

class SupervisorServiceException implements Exception {
  final String message;
  final int? statusCode;

  SupervisorServiceException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
