import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart' as latlng;

/// Animates map position between GPS fixes (Google Maps–style movement).
class SmoothedLatLng {
  SmoothedLatLng({this.duration = const Duration(milliseconds: 450)});

  final Duration duration;
  latlng.LatLng? _display;
  latlng.LatLng? _from;
  latlng.LatLng? _to;
  Timer? _timer;

  latlng.LatLng? get value => _display;

  void setTarget(latlng.LatLng target, {VoidCallback? onTick}) {
    if (_display == null) {
      _display = target;
      _from = target;
      _to = target;
      return;
    }

    if (_to != null &&
        _to!.latitude == target.latitude &&
        _to!.longitude == target.longitude) {
      return;
    }

    _from = _display;
    _to = target;
    _timer?.cancel();
    final started = DateTime.now();
    _timer = Timer.periodic(const Duration(milliseconds: 16), (t) {
      final from = _from;
      final to = _to;
      if (from == null || to == null) {
        t.cancel();
        return;
      }
      final elapsed = DateTime.now().difference(started);
      final raw = elapsed.inMilliseconds / duration.inMilliseconds;
      final t01 = raw.clamp(0.0, 1.0);
      final eased = t01 * (2 - t01);
      _display = latlng.LatLng(
        from.latitude + (to.latitude - from.latitude) * eased,
        from.longitude + (to.longitude - from.longitude) * eased,
      );
      onTick?.call();
      if (t01 >= 1.0) {
        _display = to;
        _from = to;
        t.cancel();
      }
    });
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
