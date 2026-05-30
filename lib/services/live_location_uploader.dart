import 'dart:async';
import 'dart:convert';

import 'package:application/services/service_locator.dart';
import 'package:application/utils/api_config.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Buffers GPS fixes and uploads them in batches so Railway gets ~1 row/sec
/// without one HTTP round-trip per fix (which caused 4–6s gaps under load).
class LiveLocationUploader {
  LiveLocationUploader._();

  static final LiveLocationUploader instance = LiveLocationUploader._();
  static final http.Client _client = http.Client();

  final List<Map<String, dynamic>> _pending = [];
  Timer? _flushTimer;
  bool _flushing = false;

  void start() {
    _flushTimer ??= Timer.periodic(
      const Duration(milliseconds: 900),
      (_) => unawaited(flush()),
    );
  }

  void stop() {
    _flushTimer?.cancel();
    _flushTimer = null;
    _pending.clear();
  }

  void enqueue(double lat, double lng) {
    _pending.add({
      'latitude': lat,
      'longitude': lng,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });
    if (_pending.length >= 3) {
      unawaited(flush());
    }
  }

  Future<void> flush() async {
    if (_flushing || _pending.isEmpty) return;
    _flushing = true;
    final batch = List<Map<String, dynamic>>.from(_pending);
    _pending.clear();

    try {
      final ok = await _postBatch(batch);
      if (!ok && batch.isNotEmpty) {
        final last = batch.last;
        await _postSingle(
          (last['latitude'] as num).toDouble(),
          (last['longitude'] as num).toDouble(),
        );
      }
    } finally {
      _flushing = false;
      if (_pending.isNotEmpty) {
        unawaited(flush());
      }
    }
  }

  Future<bool> _postBatch(List<Map<String, dynamic>> points) async {
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
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return true;
      }
      debugPrint('Batch location save failed: HTTP ${resp.statusCode}');
      return false;
    } catch (e) {
      debugPrint('Batch location upload error: $e');
      return false;
    }
  }

  Future<void> _postSingle(double lat, double lng) async {
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
              'timestamp': DateTime.now().toUtc().toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        debugPrint('Location save failed: HTTP ${resp.statusCode}');
      }
    } catch (e) {
      debugPrint('Error sending location to backend: $e');
    }
  }
}
