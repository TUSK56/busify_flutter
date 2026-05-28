import 'package:geolocator/geolocator.dart';

/// Live supervisor GPS sampling interval (was 2s; now sub-second for accuracy).
const Duration kLiveLocationInterval = Duration(milliseconds: 800);

/// One-shot parent GPS capture for signup/profile address.
/// Kept generous to avoid timeout errors on slower devices/networks.
const LocationSettings kParentLocationSettings = LocationSettings(
  accuracy: LocationAccuracy.bestForNavigation,
  timeLimit: Duration(seconds: 12),
);

/// Continuous live-trip tracking should not hard-timeout every sub-second tick.
const LocationAccuracy kLiveTrackingAccuracy = LocationAccuracy.bestForNavigation;
