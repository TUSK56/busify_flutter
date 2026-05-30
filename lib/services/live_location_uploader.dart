import 'dart:async';
import 'dart:convert';

import 'package:application/services/service_locator.dart';
import 'package:application/utils/api_config.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Sends GPS fixes every second using the latest coordinates (parallel HTTP).
class LiveLocationUploader {
  LiveLocationUploader._();

  static final LiveLocationUploader instance = LiveLocationUploader._();
  static final http.Client _client = http.Client();

  final List<Map<String, dynamic>> _pending = [];
  Timer? _flushTimer;
  Timer? _tickTimer;
  double? _lastLat;
  double? _lastLng;

  void start() {
    _flushTimer ??= Timer.periodic(
      const Duration(milliseconds: 200),
      (_) => _scheduleFlush(),
    );
    _tickTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      final lat = _lastLat;
      final lng = _lastLng;
      if (lat != null && lng != null) {
        _enqueueInternal(lat, lng);
      }
    });
  }

  void stop() {
    _flushTimer?.cancel();
    _flushTimer = null;
    _tickTimer?.cancel();
    _tickTimer = null;
    _pending.clear();
    _lastLat = null;
    _lastLng = null;
  }

  void updatePosition(double lat, double lng) {
    _lastLat = lat;
    _lastLng = lng;
    _enqueueInternal(lat, lng);
  }

  void _enqueueInternal(double lat, double lng) {
    final now = DateTime.now().toUtc();
    final last = _pending.isNotEmpty ? _pending.last : null;
    if (last != null) {
      final lastAt = DateTime.tryParse(last['timestamp'] as String? ?? '');
      final sameCoords =
          (last['latitude'] as num).toDouble() == lat &&
          (last['longitude'] as num).toDouble() == lng;
      if (sameCoords &&
          lastAt != null &&
          now.difference(lastAt).inMilliseconds < 400) {
        return;
      }
    }

    _pending.add({
      'latitude': lat,
      'longitude': lng,
      'timestamp': now.toIso8601String(),
    });

    _scheduleFlush();
  }

  void _scheduleFlush() {
    if (_pending.isEmpty) return;

    final batch = List<Map<String, dynamic>>.from(_pending);
    _pending.clear();

    unawaited(_postBatch(batch));
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
          .timeout(const Duration(seconds: 6));

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return;
      }

      debugPrint('Batch location save failed: HTTP ${resp.statusCode}');
    } catch (e) {
      debugPrint('Batch location upload error: $e');
    }
  }
}
