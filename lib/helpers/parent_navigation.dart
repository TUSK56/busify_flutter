import 'package:application/routes/fade_route.dart';
import 'package:application/screens/parent/parent_home_screen.dart';
import 'package:application/screens/parent/parent_profile_screen.dart';
import 'package:application/screens/parent/parent_track_bus_screen.dart';
import 'package:flutter/material.dart';

/// Prefer popping back to an existing home screen so trip state is preserved.
void parentNavigateHome(BuildContext context) {
  final nav = Navigator.of(context);
  if (nav.canPop()) {
    nav.pop();
    return;
  }
  nav.pushReplacement(fadeRoute(const ParentHomeScreen()));
}

void parentNavigateTrackBus(
  BuildContext context, {
  int? studentId,
  String? studentName,
  String? studentPhotoUrl,
}) {
  Navigator.of(context).push(
    fadeRoute(
      ParentTrackBusScreen(
        studentId: studentId,
        studentName: studentName,
        studentPhotoUrl: studentPhotoUrl,
      ),
    ),
  );
}

void parentNavigateProfile(BuildContext context) {
  Navigator.of(context).push(fadeRoute(const ParentProfileScreen()));
}
