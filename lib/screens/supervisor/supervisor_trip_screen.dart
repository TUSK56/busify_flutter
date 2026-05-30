import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:math' show asin, cos, sqrt;

import 'package:application/constants/app_colors.dart';
import 'package:application/constants/app_images.dart';
import 'package:application/helpers/api_json.dart';
import 'package:application/helpers/app_theme.dart';
import 'package:application/helpers/app_feedback.dart';
import 'package:application/helpers/fade_route.dart';
import 'package:application/screens/supervisor/supervisor_attendance_screen.dart';
import 'package:application/screens/supervisor/supervisor_full_map_screen.dart';
import 'package:application/screens/supervisor/supervisor_home_screen.dart';
import 'package:application/screens/supervisor/supervisor_profile_screen.dart';
import 'package:application/services/live_location_uploader.dart';
import 'package:application/services/service_locator.dart';
import 'package:application/utils/api_config.dart';
import 'package:application/widgets/supervisor/supervisor_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:application/constants/location_tracking.dart';
import 'package:application/helpers/map_bus_marker.dart';
import 'package:application/helpers/map_lat_lng.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart' as latlng;

class SupervisorTripScreen extends StatefulWidget {
  final int? tripId;

  const SupervisorTripScreen({super.key, this.tripId});

  @override
  State<SupervisorTripScreen> createState() => _SupervisorTripScreenState();
}

class _SupervisorTripScreenState extends State<SupervisorTripScreen>
    with TickerProviderStateMixin {
  // --- LOGIC VARIABLES ---
  StreamSubscription<Position>? _positionSub;
  latlng.LatLng? _currentLocation;
  String _eta = "-- min";
  List<latlng.LatLng>? _routePoints;
  latlng.LatLng? _lastLocation;
  DateTime? _lastSampleTime;
  DateTime? _lastValidEta;
  Duration _stoppedTime = Duration.zero;
  DateTime? _lastEtaEngineUpdateTime;
  bool _isMiniMapFollowing = true;
  double? _smoothedSpeedKmh;
  double? _routeDistanceKm;
  double? _routeDurationSeconds;
  double? _initialStraightDistanceKm;

  // Realistic default school-bus cruise speed used until live speed stabilizes.
  static const double _defaultCruiseSpeedKmh = 28.0;

  // Dynamic trip destination (nearest remaining stop, then school).
  latlng.LatLng _currentDestination = const latlng.LatLng(
    30.127157,
    31.375660,
  );
  latlng.LatLng _schoolDestination = const latlng.LatLng(
    30.127157,
    31.375660,
  );
  final List<_TripStop> _stops = [];
  String _busNumber = '7';
  int? _currentStopIndex;

  int _boardedCount = 0;
  int _totalCount = 0;
  int _remainingCount = 0;
  bool _markingAbsent = false;
  bool _sendingSos = false;

  int _consecutiveNoMatchFaceAttempts = 0;

  int _routeProgressIndex = 0;

  String _supervisorName = '';

  int? _resolvedTripId;

  int? get _activeTripId {
    final w = widget.tripId;
    if (w != null && w > 0) return w;
    final r = _resolvedTripId;
    if (r != null && r > 0) return r;
    return null;
  }

  bool get _allStudentStopsCompleted =>
      _stops.isNotEmpty && _stops.every((s) => s.completed);

  gmaps.GoogleMapController? _mapController;
  gmaps.BitmapDescriptor? _busMarkerIcon;
  double _mapZoom = 15;
  AnimationController? _recenterController;

  @override
  void initState() {
    super.initState();
    _supervisorName = ServiceLocator.tokenStorage.getUserName() ?? '';
    unawaited(_bootstrapSupervisorSession());
    unawaited(_loadBusMarkerIcon());
    _startTripTracking();
  }

  Future<void> _loadBusMarkerIcon() async {
    try {
      final icon = await MapBusMarker.icon();
      if (mounted) setState(() => _busMarkerIcon = icon);
    } catch (e) {
      debugPrint('Bus map marker load failed: $e');
    }
  }

  /// Resolves [activeTripId] from GET /Supervisor/me when this screen was opened without [tripId]
  /// (e.g. bottom nav from profile), then loads trip students + attendance summary.
  Future<void> _bootstrapSupervisorSession() async {
    try {
      final me = await ServiceLocator.supervisorService.getMe();
      if (!mounted) return;
      final n = me.name.trim();
      if (n.isNotEmpty) {
        setState(() => _supervisorName = n);
      }
      if ((widget.tripId == null || widget.tripId! <= 0) &&
          me.activeTripId != null &&
          me.activeTripId! > 0) {
        setState(() => _resolvedTripId = me.activeTripId);
      }
    } catch (_) {}
    if (!mounted) return;
    await _loadTripStops();
  }

  Map<String, dynamic>? _coerceJsonMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) {
      return v.map((k, val) => MapEntry(k.toString(), val));
    }
    return null;
  }

  int? _readSummaryInt(Map<String, dynamic>? m, List<String> keys) {
    if (m == null) return null;
    for (final k in keys) {
      final v = m[k];
      if (v is num) return v.toInt();
      final p = int.tryParse(v?.toString() ?? '');
      if (p != null) return p;
    }
    return null;
  }

  bool _readBool(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v.toString().trim().toLowerCase();
    return s == 'true' || s == '1' || s == 'yes';
  }

  bool? _readTriBool(dynamic v) {
    if (v == null) return null;
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v.toString().trim().toLowerCase();
    if (s == 'true' || s == '1' || s == 'yes') return true;
    if (s == 'false' || s == '0' || s == 'no' || s.isEmpty) return false;
    return null;
  }

  Future<void> _loadTripStops() async {
    final tripId = _activeTripId;
    if (tripId == null || tripId <= 0) return;
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/v1/Supervisor/trip/students?tripId=$tripId',
      );
      final token = ServiceLocator.tokenStorage.getToken();
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      final resp = await http.get(uri, headers: headers);
      if (resp.statusCode != 200) return;

      final body = _coerceJsonMap(jsonDecode(resp.body));
      if (body == null) return;

      final tripObj = _coerceJsonMap(body['trip']) ?? _coerceJsonMap(body['Trip']);
      final schoolObj = _coerceJsonMap(body['school']) ?? _coerceJsonMap(body['School']);
      final schoolLat = _toDouble(schoolObj?['latitude']);
      final schoolLng = _toDouble(schoolObj?['longitude']);
      final busObj =
          tripObj != null ? (_coerceJsonMap(tripObj['bus']) ?? _coerceJsonMap(tripObj['Bus'])) : null;
      final busNo = (busObj?['busNumber'] ?? busObj?['bus_number'] ?? '').toString().trim();
      final rawStudents = body['students'] ?? body['Students'];
      final students = rawStudents is List ? rawStudents : const <dynamic>[];
      final summaryMap =
          _coerceJsonMap(body['attendanceSummary']) ?? _coerceJsonMap(body['summary']);
      final summaryBoarded = _readSummaryInt(summaryMap, const ['boarded', 'Boarded']);
      var summaryTotal = _readSummaryInt(summaryMap, const ['total', 'Total']) ?? 0;
      final summaryRemaining = _readSummaryInt(summaryMap, const ['remaining', 'Remaining']);

      final parsed = <_TripStop>[];
      for (final raw in students) {
        final m = _coerceJsonMap(raw);
        if (m == null) continue;
        final sid = _extractStudentId(m);
        if (sid <= 0) continue;
        final point = _extractStudentPoint(m);
        final boardedFlag = _readBool(m['boarded'] ?? m['Boarded']);
        final absentFlag = _readBool(m['absent'] ?? m['Absent']);
        final completedExplicit = m['completed'] ?? m['Completed'];
        final explicit = _readTriBool(completedExplicit);
        final completedResolved = explicit ?? (boardedFlag || absentFlag);
        parsed.add(
          _TripStop(
            studentId: sid,
            studentName: (m['name'] ?? 'Student').toString(),
            studentGrade: (m['grade'] ?? m['studentGrade'] ?? '').toString(),
            studentBirthdate:
                (m['birthdate'] ?? m['studentBirthdate'] ?? '').toString(),
            photoUrl: readPhotoUrlFromMap(m),
            location: point ?? _currentLocation ?? _schoolDestination,
            boarded: boardedFlag,
            completed: completedResolved,
          ),
        );
      }

      if (summaryTotal <= 0 && parsed.isNotEmpty) {
        summaryTotal = parsed.length;
      }
      final fromSummary = summaryTotal > 0;

      if (!mounted) return;
      setState(() {
        if (busNo.isNotEmpty) _busNumber = busNo;
        if (schoolLat != null && schoolLng != null) {
          _schoolDestination = latlng.LatLng(schoolLat, schoolLng);
        }
        if (parsed.isNotEmpty) {
          _stops
            ..clear()
            ..addAll(parsed);
          _currentDestination = parsed.first.location;
        } else {
          _stops.clear();
        }

        if (fromSummary) {
          _totalCount = summaryTotal;
          _boardedCount = summaryBoarded ?? 0;
          _remainingCount = summaryRemaining ??
              math.max(_totalCount - _boardedCount, 0);
        } else if (parsed.isNotEmpty) {
          _boardedCount = parsed.where((s) => s.boarded).length;
          _remainingCount = parsed.where((s) => !s.completed).length;
          _totalCount = parsed.length;
        } else {
          _boardedCount = summaryBoarded ?? 0;
          _totalCount = summaryTotal;
          _remainingCount = summaryRemaining ??
              math.max(_totalCount - _boardedCount, 0);
        }
        _routeProgressIndex = 0;
        _routePoints = null;
        _routeDistanceKm = null;
        _routeDurationSeconds = null;
        _initialStraightDistanceKm = null;
      });
      if (parsed.isNotEmpty) {
        _recomputeNearestNextStop();
      }
    } catch (_) {}
  }

  int _extractStudentId(Map<String, dynamic> raw) {
    final keys = ['id', 'studentId', 'student_id'];
    for (final k in keys) {
      final v = raw[k];
      if (v is num) return v.toInt();
      final parsed = int.tryParse(v?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return 0;
  }

  double? _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '');
  }

  latlng.LatLng? _extractStudentPoint(Map<String, dynamic> raw) {
    final parent = raw['parent'] is Map<String, dynamic>
        ? raw['parent'] as Map<String, dynamic>
        : null;

    final latCandidates = [
      raw['parent_latitude'],
      raw['parentLatitude'],
      raw['latitude'],
      parent?['latitude'],
      parent?['lat'],
    ];
    final lngCandidates = [
      raw['parent_longitude'],
      raw['parentLongitude'],
      raw['longitude'],
      parent?['longitude'],
      parent?['lng'],
    ];

    for (final latV in latCandidates) {
      final lat = _toDouble(latV);
      if (lat == null) continue;
      for (final lngV in lngCandidates) {
        final lng = _toDouble(lngV);
        if (lng == null) continue;
        return latlng.LatLng(lat, lng);
      }
    }

    final address = (parent?['address'] ??
            raw['parentAddress'] ??
            raw['parent_address'] ??
            raw['address'] ??
            '')
        .toString()
        .trim();
    return _parseLatLngAddress(address);
  }

  latlng.LatLng? _parseLatLngAddress(String address) {
    final text = address.trim();
    if (text.isEmpty) return null;
    final matches = RegExp(
      r'[-+]?\d+(?:\.\d+)?',
    ).allMatches(text).toList(growable: false);
    if (matches.length < 2) return null;
    final lat = double.tryParse(matches[0].group(0)!);
    final lng = double.tryParse(matches[1].group(0)!);
    if (lat == null || lng == null) return null;
    return latlng.LatLng(lat, lng);
  }

  void _recomputeNearestNextStop() {
    if (_currentLocation == null || _stops.isEmpty) return;
    final remaining = <int>[];
    for (var i = 0; i < _stops.length; i++) {
      if (!_stops[i].completed) remaining.add(i);
    }
    if (remaining.isEmpty) {
      setState(() {
        _currentDestination = _schoolDestination;
        _routePoints = null;
        _routeProgressIndex = 0;
      });
      return;
    }

    var bestIndex = remaining.first;
    var bestDistance = double.infinity;
    for (final idx in remaining) {
      final stop = _stops[idx];
      final d = _coordinateDistance(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
        stop.location.latitude,
        stop.location.longitude,
      );
      if (d < bestDistance) {
        bestDistance = d;
        bestIndex = idx;
      }
    }
    setState(() {
      _currentStopIndex = bestIndex;
      _currentDestination = _stops[bestIndex].location;
      _routePoints = null;
      _routeProgressIndex = 0;
    });
  }

  Future<String?> _askAbsentReason() async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _MarkAbsentReasonDialog(),
    );
    if (result == null || result.trim().length < 2) return null;
    return result.trim();
  }

  Future<void> _makeAbsent() async {
    final tripId = _activeTripId;
    if (tripId == null || tripId <= 0) return;
    if (_markingAbsent) return;
    if (_allStudentStopsCompleted) return;

    if (_stops.isEmpty) await _loadTripStops();
    if (!mounted) return;

    final idx = _currentStopIndex ??
        _stops.indexWhere((s) => !s.completed);
    if (idx < 0 || idx >= _stops.length) return;

    final reason = await _askAbsentReason();
    if (!mounted || reason == null) return;

    setState(() => _markingAbsent = true);
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/v1/Supervisor/attendance/mark-absent');
      final token = ServiceLocator.tokenStorage.getToken();
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      final body = jsonEncode({
        'tripId': tripId,
        'studentId': _stops[idx].studentId,
        'reason': reason,
      });
      final resp = await http.post(uri, headers: headers, body: body);
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        await _loadTripStops();
        if (!mounted) return;
        _recomputeNearestNextStop();
        final loc = _currentLocation;
        if (loc != null) {
          await _fetchRoute(loc, _currentDestination);
        }
      } else {
        if (!mounted) return;
        await _showAbsentErrorDialog(
          'Mark absent failed (HTTP ${resp.statusCode})',
        );
      }
    } catch (e) {
      if (!mounted) return;
      await _showAbsentErrorDialog('Mark absent error: $e');
    } finally {
      if (mounted) setState(() => _markingAbsent = false);
    }
  }

  Future<void> _showAbsentErrorDialog(String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark absent'),
        content: SingleChildScrollView(
          child: Text(message),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendSos() async {
    if (_sendingSos) return;
    setState(() => _sendingSos = true);
    try {
      var lat = _currentLocation?.latitude;
      var lng = _currentLocation?.longitude;
      if (lat == null || lng == null) {
        final current = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        lat = current.latitude;
        lng = current.longitude;
      }
      final sos = await ServiceLocator.supervisorService.sendSos(
        latitude: lat,
        longitude: lng,
      );
      if (!mounted) return;
      var msg = 'SOS processed; trip ended.';
      if (sos.recipients <= 0) {
        msg = '$msg No parents on this bus to notify.';
      } else if (sos.fcmAttempted <= 0) {
        msg = '$msg Parents have no registered devices — open parent app after login.';
      } else if (sos.fcmDelivered <= 0) {
        msg =
            '$msg Push did not reach devices (${sos.fcmFailed} failed). Check Firebase config and tokens.';
      } else {
        msg = '$msg Notified ${sos.fcmDelivered} device(s).';
      }
      await showAppFeedback(context, msg);
    } catch (e) {
      if (!mounted) return;
      await showAppFeedback(context, 'Failed to send SOS: $e', isError: true);
    } finally {
      if (mounted) setState(() => _sendingSos = false);
    }
  }

  @override
  void dispose() {
    LiveLocationUploader.instance.stop();
    _positionSub?.cancel();
    _recenterController?.dispose();
    _recenterController = null;
    super.dispose();
  }

  void _animateMapTo(latlng.LatLng target, {double? targetZoom}) {
    final controller = _mapController;
    if (!mounted || controller == null) return;
    final zoom = targetZoom ?? _mapZoom;
    _mapZoom = zoom;
    controller.animateCamera(
      gmaps.CameraUpdate.newLatLngZoom(toGoogleLatLng(target), zoom),
    );
  }

  /// 1. Initialize Tracking & Permissions
  void _startTripTracking() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() {
          _eta = 'Location services off';
        });
        await showAppFeedback(
          context,
          'Please enable location services to track the trip.',
          isError: true,
        );
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() {
            _eta = 'Location permission denied';
          });
          await showAppFeedback(
            context,
            'Location permission is required to track the trip.',
            isError: true,
          );
        }
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() {
          _eta = 'Location permanently denied';
        });
        await showAppFeedback(
          context,
          'Location permission permanently denied. Enable it from Settings.',
          isError: true,
        );
      }
      return;
    }

    // Continuous GPS stream (~500ms on Android) — map updates immediately, uploads queued.
    LiveLocationUploader.instance.start();
    _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: liveTripStreamSettings(),
    ).listen(
      (position) async {
      try {
        final nextLocation = latlng.LatLng(
          position.latitude,
          position.longitude,
        );
        final now = DateTime.now();

        // Live speed (km/h): sensor first, then coordinate delta fallback.
        double liveSpeedKmh = 0;
        if (position.speed.isFinite && position.speed > 0.5) {
          liveSpeedKmh = position.speed * 3.6;
        }

        if (_lastLocation != null &&
            _lastSampleTime != null &&
            liveSpeedKmh <= 0) {
          final dtSeconds =
              now.difference(_lastSampleTime!).inMilliseconds / 1000.0;
          if (dtSeconds > 0) {
            final deltaKm = _coordinateDistance(
              _lastLocation!.latitude,
              _lastLocation!.longitude,
              nextLocation.latitude,
              nextLocation.longitude,
            );
            liveSpeedKmh = (deltaKm / dtSeconds) * 3600.0;
          }
        }

        liveSpeedKmh = liveSpeedKmh.clamp(0, 90);
        if (_smoothedSpeedKmh == null) {
          _smoothedSpeedKmh = liveSpeedKmh;
        } else {
          const alpha = 0.35;
          _smoothedSpeedKmh =
              (alpha * liveSpeedKmh) + ((1 - alpha) * _smoothedSpeedKmh!);
        }

        _lastLocation = nextLocation;
        _lastSampleTime = now;

        // Remaining distance in km
        final remainingKm = _coordinateDistance(
          nextLocation.latitude,
          nextLocation.longitude,
          _currentDestination.latitude,
          _currentDestination.longitude,
        );

        final nextEta = _updateRoadBasedEtaEngine(
          now,
          remainingKm,
          _smoothedSpeedKmh ?? 0,
        );

        if (mounted) {
          setState(() {
            _currentLocation = nextLocation;
            _eta = nextEta;
            if (_routePoints != null) {
              _routeProgressIndex =
                  _closestRouteIndex(nextLocation, _routePoints!);
            }
          });
        }
        if (_stops.isNotEmpty) {
          _recomputeNearestNextStop();
        }

        // Fetch road-based route once when we get the first fix
        if (_routePoints == null) {
          await _fetchRoute(nextLocation, _currentDestination);
        }

        // 3. Record to backend without blocking the GPS stream
        LiveLocationUploader.instance.enqueue(
          position.latitude,
          position.longitude,
        );

        // 4. Move map camera to follow Supervisor
        if (_isMiniMapFollowing && _currentLocation != null) {
          _animateMapTo(_currentLocation!, targetZoom: _mapZoom);
        }
      } catch (e) {
        debugPrint('Error during location tracking loop: $e');
      }
    }, onError: (Object e) {
      debugPrint('GPS stream error: $e');
    });
  }

  /// ETA engine (Option 1 + Option 2):
  /// - Use OSRM road duration/distance as the base ETA model.
  /// - Scale remaining duration by current remaining distance ratio.
  /// - When moving, correct ETA based on live speed vs route average speed.
  /// - Fallback to average cruise speed if road metadata is not ready.
  String _updateRoadBasedEtaEngine(
    DateTime now,
    double remainingDistanceKm,
    double liveSpeedKmh,
  ) {
    const double movingThreshold = 2.0;

    Duration delta = Duration.zero;
    if (_lastEtaEngineUpdateTime != null) {
      delta = now.difference(_lastEtaEngineUpdateTime!);
    }
    _lastEtaEngineUpdateTime = now;

    if (_routeDurationSeconds != null &&
        _initialStraightDistanceKm != null &&
        _initialStraightDistanceKm! > 0) {
      final ratio = (remainingDistanceKm / _initialStraightDistanceKm!).clamp(
        0.0,
        1.5,
      );
      double remainingRoadSeconds = (_routeDurationSeconds! * ratio).clamp(
        0.0,
        double.infinity,
      );

      if (liveSpeedKmh > movingThreshold) {
        _stoppedTime = Duration.zero;

        // Correct base ETA by comparing route-average speed to current live speed.
        if (_routeDistanceKm != null &&
            _routeDurationSeconds != null &&
            _routeDurationSeconds! > 0) {
          final routeAvgSpeedKmh =
              _routeDistanceKm! / (_routeDurationSeconds! / 3600.0);
          if (routeAvgSpeedKmh.isFinite && routeAvgSpeedKmh > 0) {
            final speedFactor = (routeAvgSpeedKmh / liveSpeedKmh).clamp(
              0.55,
              1.9,
            );
            final corrected = remainingRoadSeconds * speedFactor;
            // Blend to reduce jitter while still reacting to speed changes.
            remainingRoadSeconds =
                (0.6 * remainingRoadSeconds) + (0.4 * corrected);
          }
        }
      } else if (_lastValidEta != null) {
        // Vehicle nearly stopped: keep ETA moving forward with stopped time.
        _stoppedTime += delta;
        final pausedEta = _lastValidEta!.add(_stoppedTime);
        return _formatEta(pausedEta);
      }

      final eta = now.add(
        Duration(
          seconds: remainingRoadSeconds.isFinite
              ? remainingRoadSeconds.round()
              : 0,
        ),
      );
      _lastValidEta = eta;
      return _formatEta(eta);
    }

    final fallbackHours = remainingDistanceKm / _defaultCruiseSpeedKmh;
    final fallbackSeconds = (fallbackHours * 3600).clamp(0, double.infinity);
    final fallbackEta = now.add(
      Duration(seconds: fallbackSeconds.isFinite ? fallbackSeconds.round() : 0),
    );
    _lastValidEta = fallbackEta;
    return _formatEta(fallbackEta);
  }

  String _formatEta(DateTime eta) {
    final seconds = eta.difference(DateTime.now()).inSeconds;
    if (seconds <= 0) return "0 min";

    final minutes = (seconds / 60).ceil();
    return minutes == 1 ? "1 min" : "$minutes mins";
  }

  double _coordinateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    var p = 0.017453292519943295;
    var c = cos;
    var a =
        0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  int _closestRouteIndex(latlng.LatLng current, List<latlng.LatLng> points) {
    var bestIdx = 0;
    var bestDist = double.infinity;
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final d = _coordinateDistance(
        current.latitude,
        current.longitude,
        p.latitude,
        p.longitude,
      );
      if (d < bestDist) {
        bestDist = d;
        bestIdx = i;
      }
    }
    return bestIdx;
  }

  Set<gmaps.Polyline> _buildColoredRoutePolylines() {
    final points = _routePoints;
    if (points == null || points.length < 2) return const {};

    final idx = _routeProgressIndex.clamp(0, points.length - 1);
    final remaining = points.sublist(idx);

    if (remaining.length < 2) return const {};

    return {
      gmaps.Polyline(
        polylineId: const gmaps.PolylineId('remaining'),
        points: toGoogleLatLngList(remaining),
        color: const Color(0xFF2563EB),
        width: 4,
      ),
    };
  }

  Set<gmaps.Marker> _buildTripMapMarkers() {
    if (_currentLocation == null) return const {};
    final busIcon = _busMarkerIcon ??
        gmaps.BitmapDescriptor.defaultMarkerWithHue(
          gmaps.BitmapDescriptor.hueOrange,
        );
    return {
      gmaps.Marker(
        markerId: const gmaps.MarkerId('bus'),
        position: toGoogleLatLng(_currentLocation!),
        icon: busIcon,
        anchor: const Offset(0.5, 0.5),
      ),
      gmaps.Marker(
        markerId: const gmaps.MarkerId('destination'),
        position: toGoogleLatLng(_currentDestination),
        icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
          gmaps.BitmapDescriptor.hueRed,
        ),
      ),
    };
  }

  Future<void> _takeAttendance() async {
    if (_allStudentStopsCompleted) return;
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (photo != null && mounted) {
        final identifyResult = await _identifyStudentFromFace(photo.path);
        final identified = identifyResult.hit;
        final matched =
            identified != null && identified.studentId > 0;

        if (matched) {
          _consecutiveNoMatchFaceAttempts = 0;
        } else {
          _consecutiveNoMatchFaceAttempts++;
        }

        if (_activeTripId == null || _activeTripId! <= 0) {
          if (!mounted) return;
          await showAppFeedback(
            context,
            'Trip is not started correctly. Please restart trip.',
            isError: true,
          );
          return;
        }

        final manualOpts = _stops
            .where((s) => !s.completed)
            .map(
              (s) => SupervisorManualStudentOption(
                studentId: s.studentId,
                name: s.studentName,
                grade: s.studentGrade,
                birthdate: s.studentBirthdate,
                photoUrl: s.photoUrl,
              ),
            )
            .toList();
        final showManual = !matched &&
            _consecutiveNoMatchFaceAttempts >= 3 &&
            manualOpts.isNotEmpty;

        if (!mounted) return;
        final nav = Navigator.of(context);
        final result = await nav.push<bool>(
          fadeRoute(
            SupervisorAttendanceScreen(
              imagePath: photo.path,
              tripId: _activeTripId,
              studentId: matched ? identified.studentId : 0,
              studentName: matched ? identified.studentName : '',
              studentGrade: matched ? identified.studentGrade : '',
              studentBirthdate: matched ? identified.studentBirthdate : '',
              studentPhotoUrl: matched ? identified.photoUrl : null,
              busNumber: _busNumber,
              faceAttemptId:
                  matched ? identified.faceAttemptId : identifyResult.attemptId,
              matchConfidence: matched ? identified.matchConfidence : 0,
              allowConfirmAttendance: matched,
              noMatchMessage: matched
                  ? null
                  : (identifyResult.message ??
                      'Face not recognized. Please rescan.'),
              allowManualStudentPick: showManual,
              manualStudentOptions: manualOpts,
            ),
          ),
        );
        if (mounted && result == false) {
          // User explicitly chose "Rescan" from confirmation page.
          await _takeAttendance();
          return;
        }
        if (mounted && result == true) {
          _consecutiveNoMatchFaceAttempts = 0;
          await _loadTripStops();
          if (mounted) {
            _recomputeNearestNextStop();
            final loc = _currentLocation;
            if (loc != null) {
              await _fetchRoute(loc, _currentDestination);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error opening camera: $e');
    }
  }

  /// Only [hit] is set when the API returns a confirmed match (`matchFound` + `matchedStudentId`).
  /// Never infer a student from `topCandidates` alone — those are hints when similarity is too low.
  Future<({_FaceIdentifyHit? hit, String? message, int attemptId})>
      _identifyStudentFromFace(
    String imagePath,
  ) async {
    final tripId = _activeTripId;
    if (tripId == null || tripId <= 0) {
      return (hit: null, message: null, attemptId: 0);
    }
    if (_stops.isEmpty) {
      await _loadTripStops();
    }

    try {
      final bytes = await File(imagePath).readAsBytes();
      final imageBase64 = base64Encode(bytes);
      final uri = Uri.parse('${ApiConfig.baseUrl}/v1/Supervisor/attendance/face-identify');
      final token = ServiceLocator.tokenStorage.getToken();
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final payload = jsonEncode({
        'tripId': tripId,
        'scanImageBase64': imageBase64,
        'scanImageUrl': 'captured://${DateTime.now().millisecondsSinceEpoch}.jpg',
        'scanType': 'IN',
        'candidateStudentIds': _stops.map((s) => s.studentId).toList(),
      });
      final resp = await http.post(uri, headers: headers, body: payload);
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        return (hit: null, message: null, attemptId: 0);
      }

      final data = _coerceJsonMap(jsonDecode(resp.body));
      if (data == null) {
        return (hit: null, message: null, attemptId: 0);
      }
      final matchFound = data['matchFound'] == true;
      final matchedId = (data['matchedStudentId'] as num?)?.toInt();
      final attemptId = (data['attemptId'] as num?)?.toInt() ?? 0;
      final confidence = (data['confidence'] as num?)?.toDouble() ?? 0.0;
      final apiMessage = (data['message'] as String?)?.trim();

      if (!matchFound || matchedId == null || matchedId <= 0) {
        return (
          hit: null,
          message: (apiMessage != null && apiMessage.isNotEmpty) ? apiMessage : null,
          attemptId: attemptId,
        );
      }

      final student = _coerceJsonMap(data['student']) ?? _coerceJsonMap(data['Student']) ?? <String, dynamic>{};
      final stop = _stops.cast<_TripStop?>().firstWhere(
        (s) => s?.studentId == matchedId,
        orElse: () => null,
      );

      return (
        hit: _FaceIdentifyHit(
          studentId: matchedId,
          studentName: (student['name'] ?? stop?.studentName ?? 'Student').toString(),
          studentGrade: (student['grade'] ?? stop?.studentGrade ?? '').toString(),
          studentBirthdate: (student['birthdate'] ?? stop?.studentBirthdate ?? '').toString(),
          faceAttemptId: attemptId,
          matchConfidence: confidence,
          photoUrl: readPhotoUrlFromMap(student) ?? stop?.photoUrl,
        ),
        message: null,
        attemptId: attemptId,
      );
    } catch (e) {
      debugPrint('Face identify failed: $e');
      return (hit: null, message: null, attemptId: 0);
    }
  }

  /// Fetch a road-based route polyline between current and destination
  /// using OSRM public routing API.
  Future<void> _fetchRoute(
    latlng.LatLng start,
    latlng.LatLng destination,
  ) async {
    try {
      final url =
          'https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${destination.longitude},${destination.latitude}?overview=full&geometries=geojson';
      final uri = Uri.parse(url);
      final resp = await http.get(uri);
      if (resp.statusCode != 200) {
        debugPrint('Route fetch failed: ${resp.statusCode}');
        return;
      }
      final data = _coerceJsonMap(jsonDecode(resp.body));
      if (data == null) return;
      final routes = data['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return;
      final firstRoute = _coerceJsonMap(routes.first);
      if (firstRoute == null) return;

      final distanceMeters = firstRoute['distance'];
      final durationSeconds = firstRoute['duration'];
      if (distanceMeters is num) {
        _routeDistanceKm = distanceMeters.toDouble() / 1000.0;
      }
      if (durationSeconds is num) {
        _routeDurationSeconds = durationSeconds.toDouble();
      }
      _initialStraightDistanceKm = _coordinateDistance(
        start.latitude,
        start.longitude,
        destination.latitude,
        destination.longitude,
      );

      final geometry = _coerceJsonMap(firstRoute['geometry']);
      if (geometry == null) return;
      final coords = geometry['coordinates'] as List<dynamic>?;
      if (coords == null) return;

      final points = <latlng.LatLng>[];
      for (final coord in coords) {
        if (coord is List && coord.length >= 2) {
          final lon = coord[0] as num;
          final lat = coord[1] as num;
          points.add(latlng.LatLng(lat.toDouble(), lon.toDouble()));
        }
      }

      if (points.isNotEmpty && mounted) {
        setState(() {
          _routePoints = points;
          if (_currentLocation != null) {
            _routeProgressIndex =
                _closestRouteIndex(_currentLocation!, _routePoints!);
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching route: $e');
    }
  }

  Widget _disabledTripCtaBlur({
    required bool enabled,
    required BorderRadius borderRadius,
    required Widget child,
  }) {
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        if (!enabled)
          Positioned.fill(
            child: AbsorbPointer(
              child: ClipRRect(
                borderRadius: borderRadius,
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.32),
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: context.appScaffoldBackground,
      body: SafeArea(
        bottom: false,
        top: false,
        child: Center(
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                // --- TOP HEADER ---
                Container(
                  width: double.infinity,
                  height: 130,
                  padding: const EdgeInsets.fromLTRB(10, 7, 20, 0),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryBlue97,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.chevron_left,
                              color: Colors.white,
                              size: 35,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Expanded(
                            child: Center(
                              child: SizedBox(
                                height: 90,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Image.asset(
                                    AppImages.logo,
                                    height: 126,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                      Icons.directions_bus,
                                      color: Colors.white,
                                      size: 44,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _sendingSos ? null : _sendSos,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _sendingSos
                                    ? const Color(0xFFB91C1C)
                                    : const Color(0xFFE31E24),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: _sendingSos
                                  ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                                  : const Text(
                                'SOS',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const SizedBox(width: 15),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[300],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                AppImages.supervisorAvatar,
                                width: 24,
                                height: 24,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Text(
                              _supervisorName.isEmpty
                                  ? 'Welcome'
                                  : 'Welcome, $_supervisorName',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // --- CONTENT ---
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(15, 10, 15, 0),
                    child: Column(
                      children: [
                        // On Route Status Bar
                        Container(
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF1BD95D),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'On Route',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFE4BA14),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    'ETA : $_eta',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // --- MAP ---
                        ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: AspectRatio(
                            aspectRatio: 362 / 279,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: _currentLocation == null
                                      ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                      : gmaps.GoogleMap(
                                    initialCameraPosition: gmaps.CameraPosition(
                                      target: toGoogleLatLng(_currentLocation!),
                                      zoom: _mapZoom,
                                    ),
                                    onMapCreated: (controller) {
                                      _mapController = controller;
                                    },
                                    onCameraMoveStarted: () {
                                      if (_isMiniMapFollowing) {
                                        setState(() {
                                          _isMiniMapFollowing = false;
                                        });
                                      }
                                    },
                                    onCameraMove: (position) {
                                      _mapZoom = position.zoom;
                                    },
                                    myLocationEnabled: false,
                                    zoomControlsEnabled: false,
                                    mapToolbarEnabled: false,
                                    markers: _buildTripMapMarkers(),
                                    polylines: _buildColoredRoutePolylines(),
                                  ),
                                ),
                                Positioned(
                                  left: 12,
                                  bottom: 12,
                                  child: GestureDetector(
                                    onTap: () {
                                      if (_currentLocation == null) return;
                                      setState(() {
                                        _isMiniMapFollowing = true;
                                      });
                                      _animateMapTo(
                                        _currentLocation!,
                                        targetZoom: 16.0,
                                      );
                                    },
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: context.appOverlayButtonBackground,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: context.appShadow,
                                            offset: const Offset(0, 2),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.my_location,
                                        color: context.appOverlayButtonIcon,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 12,
                                  bottom: 12,
                                  child: SizedBox(
                                    width: 168,
                                    height: 30,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: context.appPanelBackground,
                                        borderRadius: BorderRadius.circular(25),
                                        border: Border.all(
                                          color: AppColors.primaryBlue,
                                          width: 2,
                                        ),
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              fadeRoute(
                                                SupervisorFullMapScreen(
                                                  routeDestination:
                                                  _currentDestination,
                                                  tripId: _activeTripId,
                                                ),
                                              ),
                                            );
                                          },
                                          borderRadius: BorderRadius.circular(25),
                                          child: Center(
                                            child: Text(
                                              'View Full Map',
                                              style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 15,
                                                fontWeight: FontWeight.w500,
                                                height: 22 / 15,
                                                color: context.isDarkMode
                                                    ? Colors.white
                                                    : AppColors.primaryBlue97,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Statistics Card
                        Container(
                          height: 104,
                          padding: const EdgeInsets.fromLTRB(21, 7, 21, 7),
                          decoration: BoxDecoration(
                            color: context.appPanelBackground,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Students Boarded',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                      color: context.appPrimaryText,
                                    ),
                                  ),
                                  Text(
                                    '$_boardedCount / $_totalCount',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: context.appPrimaryText,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: SizedBox(
                                  height: 12,
                                  width: double.infinity,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Container(color: context.appProgressTrack),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: FractionallySizedBox(
                                          widthFactor: _totalCount <= 0
                                              ? 0.0
                                              : (_boardedCount / _totalCount)
                                              .clamp(0.0, 1.0),
                                          heightFactor: 1.0,
                                          child: Container(
                                            color: const Color(0xFF18A74A),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const CircleAvatar(
                                    backgroundColor: Color(0xFF1BD95D),
                                    radius: 10,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Boarded $_boardedCount',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: context.appPrimaryText,
                                    ),
                                  ),
                                  const SizedBox(width: 30),
                                  const CircleAvatar(
                                    backgroundColor: Color(0xFFE4BA14),
                                    radius: 10,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Remaining $_remainingCount',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: context.appPrimaryText,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Take Attendance Button
                        SizedBox(
                          width: 325,
                          height: 54,
                          child: _disabledTripCtaBlur(
                            enabled: !_allStudentStopsCompleted,
                            borderRadius: BorderRadius.circular(10),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryButtonGradient,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _allStudentStopsCompleted
                                      ? null
                                      : _takeAttendance,
                                  borderRadius: BorderRadius.circular(10),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        AppImages.attendance,
                                        width: 30,
                                        height: 30,
                                        color: const Color(0xFF8FBFFA),
                                        errorBuilder: (context, error, stackTrace) =>
                                        const Icon(
                                          Icons.fact_check,
                                          color: Color(0xFF8FBFFA),
                                          size: 30,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      const Text(
                                        'Take Attendance',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 20,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Make Absent Button
                        SizedBox(
                          width: 325,
                          height: 54,
                          child: _disabledTripCtaBlur(
                            enabled: !(_markingAbsent || _allStudentStopsCompleted),
                            borderRadius: BorderRadius.circular(10),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [Color(0xFFB8361E), Color(0xFF52180D)],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: (_markingAbsent || _allStudentStopsCompleted)
                                      ? null
                                      : _makeAbsent,
                                  borderRadius: BorderRadius.circular(10),
                                  child: Center(
                                    child: _markingAbsent
                                        ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                        : const Text(
                                      'Make Absent',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // --- BOTTOM NAV ---
                SupervisorBottomNavBar(
                  activeTab: SupervisorNavTab.attendance,
                  onHomeTap: () => Navigator.pushReplacement(
                    context,
                    fadeRoute(const SupervisorHomeScreen()),
                  ),
                  onAttendanceTap: _takeAttendance,
                  onProfileTap: () {
                    Navigator.push(
                      context,
                      fadeRoute(const SupervisorProfileScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}

/// Owns [TextEditingController] for the absent-reason field so it is not
/// disposed while the dialog route is still tearing down (avoids overlay /
/// inherited-widget assertions after confirm).
class _MarkAbsentReasonDialog extends StatefulWidget {
  const _MarkAbsentReasonDialog();

  @override
  State<_MarkAbsentReasonDialog> createState() => _MarkAbsentReasonDialogState();
}

class _MarkAbsentReasonDialogState extends State<_MarkAbsentReasonDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Mark Absent'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Reason (required)',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}

class _TripStop {
  final int studentId;
  final String studentName;
  final String studentGrade;
  final String studentBirthdate;
  final String? photoUrl;
  final latlng.LatLng location;
  final bool boarded;
  final bool completed;

  const _TripStop({
    required this.studentId,
    required this.studentName,
    required this.studentGrade,
    required this.studentBirthdate,
    this.photoUrl,
    required this.location,
    this.boarded = false,
    this.completed = false,
  });

  _TripStop copyWith({bool? boarded, bool? completed}) {
    return _TripStop(
      studentId: studentId,
      studentName: studentName,
      studentGrade: studentGrade,
      studentBirthdate: studentBirthdate,
      photoUrl: photoUrl,
      location: location,
      boarded: boarded ?? this.boarded,
      completed: completed ?? this.completed,
    );
  }
}

class _FaceIdentifyHit {
  final int studentId;
  final String studentName;
  final String studentGrade;
  final String studentBirthdate;
  final int faceAttemptId;
  final double matchConfidence;
  final String? photoUrl;

  const _FaceIdentifyHit({
    required this.studentId,
    required this.studentName,
    required this.studentGrade,
    required this.studentBirthdate,
    required this.faceAttemptId,
    required this.matchConfidence,
    this.photoUrl,
  });
}
