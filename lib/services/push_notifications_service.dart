import 'dart:async';
import 'dart:io';

import 'package:application/helpers/fade_route.dart';
import 'package:application/screens/parent/parent_profile_screen.dart';
import 'package:application/services/service_locator.dart';
import 'package:application/services/trip_live_updates.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:url_launcher/url_launcher.dart';

class PushNotificationsService {
  PushNotificationsService._();

  static bool _started = false;
  static StreamSubscription<String>? _tokenSub;
  static bool _pendingOpenParentProfile = false;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static const String _androidChannelId = 'busify_alerts';
  static const String _androidChannelName = 'Busify Alerts';
  static int _notificationId = 0;

  static Future<void> init() async {
    if (_started) return;

    try {
      await Firebase.initializeApp();
    } catch (e) {
      if (Firebase.apps.isEmpty) {
        debugPrint('Firebase init skipped: $e');
        return;
      }
    }

    await _initLocalNotifications();
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

    _attachNotificationOpenHandlers(messaging);
    _attachForegroundMessageHandler(messaging);
  }

  static Future<void> _initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);
    await _localNotifications.initialize(settings);

    if (Platform.isAndroid) {
      final plugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await plugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _androidChannelId,
          _androidChannelName,
          description: 'Trip, attendance, and bus alerts',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );
    }
  }

  static Future<void> _showBannerNotification(RemoteMessage message) async {
    final title = message.notification?.title?.trim();
    final body = message.notification?.body?.trim();
    final displayTitle =
        (title != null && title.isNotEmpty) ? title : 'Busify';
    final displayBody = (body != null && body.isNotEmpty)
        ? body
        : (message.data['message']?.toString().trim().isNotEmpty == true
            ? message.data['message'].toString()
            : 'You have a new update');

    final id = ++_notificationId;
    const androidDetails = AndroidNotificationDetails(
      _androidChannelId,
      _androidChannelName,
      channelDescription: 'Trip, attendance, and bus alerts',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'Busify',
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    await _localNotifications.show(
      id,
      displayTitle,
      displayBody,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  static void _attachForegroundMessageHandler(FirebaseMessaging messaging) {
    FirebaseMessaging.onMessage.listen((message) async {
      await _showBannerNotification(message);

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
        'bus_near',
        'arrived_school',
      };
      if (tripTypes.contains(type)) {
        TripLiveUpdates.instance.notify(type);
        return;
      }
      if (type == 'student_link_approved' || type == 'student_link_rejected') {
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

  static bool _isParentLinkReviewType(String type) =>
      type == 'student_link_approved' || type == 'student_link_rejected';

  static void openParentProfileScreen() {
    final token = ServiceLocator.tokenStorage.getToken();
    if (token == null || token.trim().isEmpty) {
      _pendingOpenParentProfile = true;
      return;
    }

    final nav = ServiceLocator.navigatorKey.currentState;
    if (nav == null) {
      _pendingOpenParentProfile = true;
      return;
    }

    _pendingOpenParentProfile = false;
    nav.push(fadeRoute(const ParentProfileScreen()));
  }

  static void flushPendingNavigation() {
    if (!_pendingOpenParentProfile) return;
    openParentProfileScreen();
  }

  static void _handleNotificationOpen(RemoteMessage message) {
    final data = message.data;
    final type = (data['type'] ?? '').toString().toLowerCase();
    if (_isParentLinkReviewType(type)) {
      openParentProfileScreen();
      return;
    }
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

  static Future<void> registerTokenAfterParentLogin() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _registerToken(token);
      }
      flushPendingNavigation();
    } catch (e) {
      debugPrint('FCM register after login skipped: $e');
    }

    _tokenSub?.cancel();
    _tokenSub = FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      await _registerToken(token);
    });
  }

  static Future<void> _registerToken(String token) async {
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
