import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

/// Stops a Geolocator stream without throwing when Android has no native listener.
Future<void> cancelPositionSubscription(
  StreamSubscription<Position>? subscription,
) async {
  if (subscription == null) return;

  try {
    await subscription.cancel();
  } on PlatformException catch (e) {
    debugPrint('GPS subscription cancel ignored: ${e.message}');
  } catch (e) {
    debugPrint('GPS subscription cancel error: $e');
  }
}

void detachPositionSubscription(StreamSubscription<Position>? subscription) {
  if (subscription == null) return;
  unawaited(cancelPositionSubscription(subscription));
}
