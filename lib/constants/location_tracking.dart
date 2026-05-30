import 'dart:io';

import 'package:geolocator/geolocator.dart';

/// Platform-tuned GPS stream for live trip tracking.
LocationSettings liveTripStreamSettings() {
  if (Platform.isAndroid) {
    return AndroidSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
      intervalDuration: const Duration(milliseconds: 500),
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationText: 'Busify is tracking your trip location.',
        notificationTitle: 'Live trip tracking',
        enableWakeLock: true,
      ),
    );
  }

  if (Platform.isIOS) {
    return AppleSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 5,
      activityType: ActivityType.automotiveNavigation,
      pauseLocationUpdatesAutomatically: false,
      showBackgroundLocationIndicator: true,
    );
  }

  return const LocationSettings(
    accuracy: LocationAccuracy.bestForNavigation,
    distanceFilter: 0,
  );
}

/// One-shot parent GPS capture for signup/profile address.
const LocationSettings kParentLocationSettings = LocationSettings(
  accuracy: LocationAccuracy.bestForNavigation,
  timeLimit: Duration(seconds: 12),
);

const LocationAccuracy kLiveTrackingAccuracy = LocationAccuracy.bestForNavigation;
