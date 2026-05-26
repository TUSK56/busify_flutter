import 'package:geolocator/geolocator.dart';

/// Live supervisor GPS sampling interval (was 2s; now sub-second for accuracy).
const Duration kLiveLocationInterval = Duration(milliseconds: 800);

/// Fast fix for one-shot parent address capture.
const LocationSettings kFastLocationSettings = LocationSettings(
  accuracy: LocationAccuracy.bestForNavigation,
  timeLimit: Duration(milliseconds: 900),
);
