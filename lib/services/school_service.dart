import 'dart:convert';

import 'package:application/models/school.dart';
import 'package:application/utils/api_config.dart';
import 'package:http/http.dart' as http;

/// Service for school-related API calls.
class SchoolService {
  static const String _schoolsPath = '/v1/schools';

  /// Fetches list of schools (id, name) from GET /v1/schools.
  Future<List<School>> getSchools() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$_schoolsPath');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw SchoolServiceException(
        'Failed to load schools: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    final dynamic decoded = jsonDecode(response.body);

    // API may return a raw list:
    //   [ { "id": 1, "name": "..." }, ... ]
    // Or a wrapped object:
    //   { "schools": [ ... ] }
    //   { "data": [ ... ] }
    final List<dynamic> list = switch (decoded) {
      List<dynamic> l => l,
      Map<String, dynamic> m when m['schools'] is List<dynamic> => m['schools'] as List<dynamic>,
      Map<String, dynamic> m when m['data'] is List<dynamic> => m['data'] as List<dynamic>,
      _ => throw SchoolServiceException('Unexpected schools response format'),
    };

    return list
        .map((e) => School.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

class SchoolServiceException implements Exception {
  final String message;
  final int? statusCode;

  SchoolServiceException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
