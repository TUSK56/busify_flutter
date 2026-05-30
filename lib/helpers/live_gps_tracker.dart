import 'dart:async';

import 'package:application/constants/location_tracking.dart';
import 'package:application/helpers/gps_stream_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

typedef GpsFixCallback = void Function(Position position);

/// High-frequency GPS stream for live trip tracking.
class LiveGpsTracker {
  StreamSubscription<Position>? _streamSub;
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
  }

  Future<void> stop() async {
    _running = false;
    await _stopInternal();
  }

  Future<void> _stopInternal() async {
    final sub = _streamSub;
    _streamSub = null;
    await cancelPositionSubscription(sub);
  }
}
