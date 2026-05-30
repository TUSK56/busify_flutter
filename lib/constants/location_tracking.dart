import 'package:geolocator/geolocator.dart';

/// Live supervisor GPS sampling interval (target: under 1s between fixes).
const Duration kLiveLocationInterval = Duration(milliseconds: 500);

/// Stream settings for continuous GPS during an active trip.
const LocationSettings kLiveTripStreamSettings = LocationSettings(
  accuracy: LocationAccuracy.bestForNavigation,
  distanceFilter: 3,
);

/// One-shot parent GPS capture for signup/profile address.
/// Kept generous to avoid timeout errors on slower devices/networks.
const LocationSettings kParentLocationSettings = LocationSettings(
  accuracy: LocationAccuracy.bestForNavigation,
  timeLimit: Duration(seconds: 12),
);

/// Continuous live-trip tracking should not hard-timeout every sub-second tick.
const LocationAccuracy kLiveTrackingAccuracy = LocationAccuracy.bestForNavigation;
