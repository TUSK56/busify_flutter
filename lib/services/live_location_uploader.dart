import 'dart:async';
import 'dart:convert';

import 'package:application/services/service_locator.dart';
import 'package:application/utils/api_config.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Fire-and-forget live location uploads so the GPS stream never waits on HTTP.
class LiveLocationUploader {
  LiveLocationUploader._();

  static final LiveLocationUploader instance = LiveLocationUploader._();

  void enqueue(double lat, double lng) {
    unawaited(_post(lat, lng));
  }

  Future<void> _post(double lat, double lng) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/v1/Supervisor/live-location');
      final token = ServiceLocator.tokenStorage.getToken();
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      final body = jsonEncode({
        'latitude': lat,
        'longitude': lng,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });
      final resp = await http
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        debugPrint(
          'Location save failed: HTTP ${resp.statusCode} ${resp.body}',
        );
      }
    } catch (e) {
      debugPrint('Error sending location to backend: $e');
    }
  }
}
