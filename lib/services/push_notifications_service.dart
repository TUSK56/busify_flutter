import 'dart:async';

import 'package:application/services/service_locator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class PushNotificationsService {
  PushNotificationsService._();

  static bool _started = false;
  static StreamSubscription<String>? _tokenSub;

  static Future<void> init() async {
    if (_started) return;
    _started = true;

    // Firebase can throw if google-services files are missing.
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('Firebase init skipped: $e');
      return;
    }

    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

    final messaging = FirebaseMessaging.instance;
    try {
      await messaging.requestPermission();
    } catch (_) {}

    try {
      final token = await messaging.getToken();
      if (token != null) {
        await _registerToken(token);
      }
    } catch (e) {
      debugPrint('FCM getToken failed: $e');
    }

    _tokenSub?.cancel();
    _tokenSub = messaging.onTokenRefresh.listen((token) async {
      await _registerToken(token);
    });
  }

  /// Call after parent login so the device token is sent with a valid JWT
  /// (startup init often runs before login and registration may no-op).
  static Future<void> registerTokenAfterParentLogin() async {
    try {
      await Firebase.initializeApp();
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _registerToken(token);
      }
    } catch (e) {
      debugPrint('FCM register after login skipped: $e');
    }
  }

  static Future<void> _registerToken(String token) async {
    // Only parents have the backend endpoint; supervisors will get 401 and we ignore it.
    try {
      await ServiceLocator.parentService.upsertDeviceToken(token);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Device token register skipped: $e');
      }
    }
  }

  static Future<void> dispose() async {
    await _tokenSub?.cancel();
    _tokenSub = null;
    _started = false;
  }
}

@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
}

