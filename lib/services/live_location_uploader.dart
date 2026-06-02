import 'dart:async';
import 'dart:convert';

import 'package:application/services/service_locator.dart';
import 'package:application/utils/api_config.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Sends at least one GPS row per second while a trip is active.
class LiveLocationUploader {
  LiveLocationUploader._();

  static final LiveLocationUploader instance = LiveLocationUploader._();
  static final http.Client _client = http.Client();

  Timer? _tickTimer;
  int? _tripId;
  double? _lastLat;
  double? _lastLng;
  bool _uploadInFlight = false;
  bool _pendingTick = false;

  void setTripId(int? tripId) {
    _tripId = tripId;
  }

  void start({required int tripId}) {
    stop();
    _tripId = tripId;
    _tickTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _uploadTick();
    });
    // Don't wait for the first GPS stream event — try an upload on the next tick.
    Future<void>.delayed(const Duration(milliseconds: 200), _uploadTick);
  }

  void stop() {
    _tickTimer?.cancel();
    _tickTimer = null;
    _tripId = null;
    _lastLat = null;
    _lastLng = null;
    _uploadInFlight = false;
    _pendingTick = false;
  }

  void updatePosition(double lat, double lng) {
    _lastLat = lat;
    _lastLng = lng;
  }

  void _uploadTick() {
    final tripId = _tripId;
    final lat = _lastLat;
    final lng = _lastLng;
    if (tripId == null || tripId <= 0 || lat == null || lng == null) return;
    if (_uploadInFlight) {
      _pendingTick = true;
      return;
    }

    _uploadInFlight = true;
    unawaited(
      _postBatch(tripId, [
        {
          'latitude': lat,
          'longitude': lng,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        },
      ]).whenComplete(() {
        _uploadInFlight = false;
        if (_pendingTick) {
          _pendingTick = false;
          _uploadTick();
        }
      }),
    );
  }

  Future<void> _postBatch(int tripId, List<Map<String, dynamic>> points) async {
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
            body: jsonEncode({'tripId': tripId, 'points': points}),
          )
          .timeout(const Duration(seconds: 6));

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return;
      }
      debugPrint(
        'Batch location save failed: tripId=$tripId HTTP ${resp.statusCode} ${resp.body}',
      );
    } catch (e) {
      debugPrint('Batch location upload error: $e');
    }
  }
}
