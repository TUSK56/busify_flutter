import 'dart:async';
import 'dart:convert';

import 'package:application/services/service_locator.dart';
import 'package:application/utils/api_config.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Sends GPS fixes in parallel batches — never waits for a slow HTTP response.
class LiveLocationUploader {
  LiveLocationUploader._();

  static final LiveLocationUploader instance = LiveLocationUploader._();
  static final http.Client _client = http.Client();

  final List<Map<String, dynamic>> _pending = [];
  Timer? _flushTimer;
  int _inFlight = 0;
  static const int _maxInFlight = 12;

  void start() {
    _flushTimer ??= Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => _scheduleFlush(),
    );
  }

  void stop() {
    _flushTimer?.cancel();
    _flushTimer = null;
    _pending.clear();
    _inFlight = 0;
  }

  void enqueue(double lat, double lng) {
    final now = DateTime.now().toUtc();
    final last = _pending.isNotEmpty ? _pending.last : null;
    if (last != null) {
      final lastAt = DateTime.tryParse(last['timestamp'] as String? ?? '');
      final sameCoords =
          (last['latitude'] as num).toDouble() == lat &&
          (last['longitude'] as num).toDouble() == lng;
      if (sameCoords &&
          lastAt != null &&
          now.difference(lastAt).inMilliseconds < 800) {
        return;
      }
    }

    _pending.add({
      'latitude': lat,
      'longitude': lng,
      'timestamp': now.toIso8601String(),
    });

    if (_pending.length >= 3) {
      _scheduleFlush();
    }
  }

  void _scheduleFlush() {
    if (_pending.isEmpty || _inFlight >= _maxInFlight) return;

    final batch = List<Map<String, dynamic>>.from(_pending);
    _pending.clear();
    _inFlight++;

    unawaited(
      _postBatch(batch).whenComplete(() {
        _inFlight--;
        if (_pending.isNotEmpty) {
          _scheduleFlush();
        }
      }),
    );
  }

  Future<void> _postBatch(List<Map<String, dynamic>> points) async {
    if (points.isEmpty) return;

    try {
      final uri =
          Uri.parse('${ApiConfig.baseUrl}/v1/Supervisor/live-location/batch');
      final token = ServiceLocator.tokenStorage.getToken();
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      final resp = await _client
          .post(
            uri,
            headers: headers,
            body: jsonEncode({'points': points}),
          )
          .timeout(const Duration(seconds: 8));

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return;
      }

      debugPrint('Batch location save failed: HTTP ${resp.statusCode}');
      for (final point in points) {
        await _postSingle(
          (point['latitude'] as num).toDouble(),
          (point['longitude'] as num).toDouble(),
          point['timestamp'] as String?,
        );
      }
    } catch (e) {
      debugPrint('Batch location upload error: $e');
    }
  }

  Future<void> _postSingle(
    double lat,
    double lng,
    String? timestamp,
  ) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/v1/Supervisor/live-location');
      final token = ServiceLocator.tokenStorage.getToken();
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      final resp = await _client
          .post(
            uri,
            headers: headers,
            body: jsonEncode({
              'latitude': lat,
              'longitude': lng,
              'timestamp': timestamp ?? DateTime.now().toUtc().toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 6));
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        debugPrint('Location save failed: HTTP ${resp.statusCode}');
      }
    } catch (e) {
      debugPrint('Error sending location to backend: $e');
    }
  }
}
