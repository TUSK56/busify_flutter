import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPermissionsService {
  AppPermissionsService._();

  static const _promptedKey = 'busify_permissions_prompted_v1';

  static Future<bool> hasPromptedBefore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_promptedKey) == true;
  }

  static Future<void> requestOnFirstLaunchIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_promptedKey) == true) return;

    await prefs.setBool(_promptedKey, true);

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
    } catch (e) {
      debugPrint('Firebase init for permissions: $e');
    }

    if (Platform.isAndroid) {
      try {
        final status = await Permission.notification.status;
        if (!status.isGranted) {
          await Permission.notification.request();
        }
      } catch (e) {
        debugPrint('Notification permission: $e');
      }
    }

    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    } catch (e) {
      debugPrint('FCM permission: $e');
    }

    try {
      var loc = await Geolocator.checkPermission();
      if (loc == LocationPermission.denied) {
        loc = await Geolocator.requestPermission();
      }
      if (loc == LocationPermission.deniedForever) {
        debugPrint('Location permanently denied');
      }
    } catch (e) {
      debugPrint('Location permission: $e');
    }
  }
}
