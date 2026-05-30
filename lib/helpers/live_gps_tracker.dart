import 'dart:async';

import 'package:application/constants/location_tracking.dart';
import 'package:application/helpers/gps_stream_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

typedef GpsFixCallback = void Function(Position position);

/// Combines Geolocator stream + 1s polling so fixes keep arriving even if the
/// native stream throttles on some Android devices.
class LiveGpsTracker {
  StreamSubscription<Position>? _streamSub;
  Timer? _pollTimer;
  bool _running = false;

  Future<void> start(GpsFixCallback onFix) async {
    if (_running) return;
    _running = true;

    await _stopInternal();

    _streamSub = Geolocator.getPositionStream(
      locationSettings: liveTripStreamSettings(),
    ).listen(
      onFix,
      onError: (Object e) => debugPrint('GPS stream error: $e'),
    );

    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!_running) return;
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: kLiveTrackingAccuracy,
        );
        onFix(position);
      } catch (e) {
        debugPrint('GPS poll error: $e');
      }
    });
  }

  Future<void> stop() async {
    _running = false;
    await _stopInternal();
  }

  Future<void> _stopInternal() async {
    _pollTimer?.cancel();
    _pollTimer = null;
    final sub = _streamSub;
    _streamSub = null;
    await cancelPositionSubscription(sub);
  }
}
