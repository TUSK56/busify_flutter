import 'dart:async';
import 'dart:io';

import 'package:application/services/service_locator.dart';
import 'package:application/services/trip_live_updates.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class PushNotificationsService {
  PushNotificationsService._();

  static bool _started = false;
  static StreamSubscription<String>? _tokenSub;

  static Future<void> init() async {
    if (_started) return;

    // Firebase can throw if google-services files are missing.
    try {
      await Firebase.initializeApp();
    } catch (e) {
      if (Firebase.apps.isEmpty) {
        debugPrint('Firebase init skipped: $e');
        return;
      }
    }

    _started = true;

    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

    final messaging = FirebaseMessaging.instance;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        await messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      } catch (e) {
        debugPrint('FCM iOS foreground presentation: $e');
      }
    }
    try {
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    } catch (_) {}

    if (Platform.isAndroid) {
      try {
        final status = await Permission.notification.status;
        if (!status.isGranted) {
          await Permission.notification.request();
        }
      } catch (e) {
        debugPrint('Android notification permission: $e');
      }
    }

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

    _attachNotificationOpenHandlers(messaging);
    _attachForegroundMessageHandler(messaging);
  }

  static void _attachForegroundMessageHandler(FirebaseMessaging messaging) {
    FirebaseMessaging.onMessage.listen((message) {
      final type = (message.data['type'] ?? '').toString().toLowerCase();
      if (type.isEmpty) return;
      const tripTypes = {
        'attendance_in',
        'attendance_out',
        'attendance_absent',
        'student_boarded',
        'student_absent',
        'trip_started',
        'trip_ended',
        'emergency_trip_ended',
      };
      if (tripTypes.contains(type)) {
        TripLiveUpdates.instance.notify(type);
      }
    });
  }

  static Future<void> _openMapFromEmergencyData(Map<String, dynamic> data) async {
    String? url = data['mapUrl']?.toString().trim();
    if (url == null || url.isEmpty) {
      final lat = data['latitude']?.toString().trim();
      final lng = data['longitude']?.toString().trim();
      if (lat != null &&
          lng != null &&
          lat.isNotEmpty &&
          lng.isNotEmpty) {
        url = 'https://www.google.com/maps?q=$lat,$lng';
      }
    }
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && kDebugMode) {
        debugPrint('launchUrl failed for $uri');
      }
    } catch (e) {
      debugPrint('launchUrl error: $e');
    }
  }

  static void _handleNotificationOpen(RemoteMessage message) {
    final data = message.data;
    final type = (data['type'] ?? '').toString().toLowerCase();
    if (type == 'emergency_trip_ended') {
      unawaited(_openMapFromEmergencyData(Map<String, dynamic>.from(data)));
    }
  }

  static void _attachNotificationOpenHandlers(FirebaseMessaging messaging) {
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpen);
    messaging.getInitialMessage().then((initial) {
      if (initial != null) {
        _handleNotificationOpen(initial);
      }
    });
  }

  /// Call after parent login so the device token is sent with a valid JWT
  /// (startup init often runs before login and registration may no-op).
  static Future<void> registerTokenAfterParentLogin() async {
    try {
      await Firebase.initializeApp();
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      if (Platform.isAndroid) {
        final status = await Permission.notification.status;
        if (!status.isGranted) {
          await Permission.notification.request();
        }
      }
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
