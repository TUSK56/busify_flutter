import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:math' show asin, cos, sqrt;

import 'package:application/constants/app_colors.dart';
import 'package:application/constants/app_images.dart';
import 'package:application/helpers/app_theme.dart';
import 'package:application/helpers/fade_route.dart';
import 'package:application/screens/supervisor/supervisor_attendance_screen.dart';
import 'package:application/screens/supervisor/supervisor_full_map_screen.dart';
import 'package:application/screens/supervisor/supervisor_home_screen.dart';
import 'package:application/screens/supervisor/supervisor_profile_screen.dart';
import 'package:application/services/service_locator.dart';
import 'package:application/utils/api_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
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
  Timer? _locationTimer;
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

  // Student destination (fixed point for now)
  // Dynamic trip destination (next parent stop, then school fallback).
  latlng.LatLng _currentDestination = const latlng.LatLng(
    30.127157,
    31.375660,
  );
  static const latlng.LatLng _schoolDestination = latlng.LatLng(
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

  int _routeProgressIndex = 0;

  String _supervisorName = '';

  final MapController _mapController = MapController();
  AnimationController? _recenterController;

  @override
  void initState() {
    super.initState();
    _supervisorName = ServiceLocator.tokenStorage.getUserName() ?? '';
    _loadSupervisorName();
    _loadTripStops();
    _startTripTracking();
  }

  Future<void> _loadSupervisorName() async {
    try {
      final d = await ServiceLocator.supervisorService.getMe();
      if (!mounted) return;
      final n = d.name.trim();
      if (n.isNotEmpty) setState(() => _supervisorName = n);
    } catch (_) {}
  }

  Future<void> _loadTripStops() async {
    final tripId = widget.tripId;
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

      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      final tripObj = body['trip'] as Map<String, dynamic>?;
      final busObj = tripObj?['bus'] as Map<String, dynamic>?;
      final busNo = (busObj?['busNumber'] ?? busObj?['bus_number'] ?? '').toString().trim();
      final students = (body['students'] as List<dynamic>? ?? const []);
      final summary = (body['attendanceSummary'] ?? body['summary'])
          as Map<String, dynamic>?;
      final boarded = (summary?['boarded'] as num?)?.toInt() ?? 0;
      final total = (summary?['total'] as num?)?.toInt() ?? students.length;
      final remaining =
          (summary?['remaining'] as num?)?.toInt() ?? math.max(total - boarded, 0);
      final parsed = <_TripStop>[];
      for (final raw in students) {
        if (raw is! Map<String, dynamic>) continue;
        final sid = _extractStudentId(raw);
        if (sid <= 0) continue;
        final point = _extractStudentPoint(raw);
        final boardedFlag = raw['boarded'] == true;
        final absentFlag = raw['absent'] == true;
        final completedExplicit = raw['completed'];
        final completedResolved = completedExplicit != null
            ? completedExplicit == true
            : (boardedFlag || absentFlag);
        parsed.add(
          _TripStop(
            studentId: sid,
            studentName: (raw['name'] ?? 'Student').toString(),
            studentGrade: (raw['grade'] ?? raw['studentGrade'] ?? '').toString(),
            studentBirthdate:
                (raw['birthdate'] ?? raw['studentBirthdate'] ?? '').toString(),
            // Keep stop even if address parsing fails, so attendance works anywhere.
            location: point ?? _currentLocation ?? _schoolDestination,
            completed: completedResolved,
          ),
        );
      }
      if (!mounted || parsed.isEmpty) return;
      setState(() {
        _stops
          ..clear()
          ..addAll(parsed);
        _currentDestination = parsed.first.location;
        if (busNo.isNotEmpty) _busNumber = busNo;
        _routeProgressIndex = 0;
        _boardedCount = boarded;
        _totalCount = total;
        _remainingCount = remaining;
      });
      _recomputeNearestNextStop();
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
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Mark Absent'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Reason (required)',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (result == null || result.trim().length < 2) return null;
    return result.trim();
  }

  Future<void> _makeAbsent() async {
    final tripId = widget.tripId;
    if (tripId == null || tripId <= 0) return;
    if (_markingAbsent) return;

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
        Map<String, dynamic>? decoded;
        try {
          decoded = jsonDecode(resp.body) as Map<String, dynamic>;
        } catch (_) {}
        final sum = decoded?['summary'] as Map<String, dynamic>?;
        if (!mounted) return;
        setState(() {
          _stops[idx] = _stops[idx].copyWith(completed: true);
          if (sum != null) {
            _boardedCount = (sum['boarded'] as num?)?.toInt() ?? _boardedCount;
            _totalCount = (sum['total'] as num?)?.toInt() ?? _totalCount;
            _remainingCount =
                (sum['remaining'] as num?)?.toInt() ?? _remainingCount;
          }
        });
        _recomputeNearestNextStop();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Marked absent')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mark absent failed (HTTP ${resp.statusCode})')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mark absent error: $e')),
      );
    } finally {
      if (mounted) setState(() => _markingAbsent = false);
    }
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
      await ServiceLocator.supervisorService.sendSos(
        latitude: lat,
        longitude: lng,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SOS sent to school and parents.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send SOS: $e')),
      );
    } finally {
      if (mounted) setState(() => _sendingSos = false);
    }
  }

  @override
  void dispose() {
    _locationTimer?.cancel(); // Stop tracking when leaving screen
    _recenterController?.dispose();
    _recenterController = null;
    super.dispose();
  }

  void _animateMapTo(latlng.LatLng target, {double? targetZoom}) {
    if (!mounted) return;
    _recenterController?.stop();
    _recenterController?.dispose();
    _recenterController = null;

    final camera = _mapController.camera;
    final startCenter = camera.center;
    final endZoom = targetZoom ?? camera.zoom;

    final latTween = Tween<double>(
      begin: startCenter.latitude,
      end: target.latitude,
    );
    final lngTween = Tween<double>(
      begin: startCenter.longitude,
      end: target.longitude,
    );
    final zoomTween = Tween<double>(begin: camera.zoom, end: endZoom);

    _recenterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    final curved = CurvedAnimation(
      parent: _recenterController!,
      curve: Curves.easeOutCubic,
    );

    _recenterController!.addListener(() {
      if (!mounted) return;
      final t = curved.value;
      _mapController.move(
        latlng.LatLng(latTween.transform(t), lngTween.transform(t)),
        zoomTween.transform(t),
      );
    });

    _recenterController!.forward();
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enable location services to track the trip.'),
          ),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location permission is required to track the trip.',
              ),
            ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location permission permanently denied. Enable it from Settings.',
            ),
          ),
        );
      }
      return;
    }

    // 2. Start the 2-second loop
    _locationTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

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

        // 3. Record to backend (DB)
        await _recordToDatabase(position.latitude, position.longitude);

        // 4. Move map camera to follow Supervisor
        if (_isMiniMapFollowing && _currentLocation != null) {
          _mapController.move(_currentLocation!, _mapController.camera.zoom);
        }
      } catch (e) {
        debugPrint('Error during location tracking loop: $e');
      }
    });
  }

  /// Send location to backend so it can be stored in DB.
  Future<void> _recordToDatabase(double lat, double lng) async {
    try {
      // Backend endpoint (see `backend/src/API/Controllers/SupervisorController.cs`)
      // POST /v1/Supervisor/live-location
      final uri = Uri.parse('${ApiConfig.baseUrl}/v1/Supervisor/live-location');
      final token = ServiceLocator.tokenStorage.getToken();
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      final body = jsonEncode({
        'latitude': lat,
        'longitude': lng,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });
      final resp = await http.post(uri, headers: headers, body: body);
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        debugPrint(
          'Location save failed: HTTP ${resp.statusCode} ${resp.body}',
        );
      }
    } catch (e) {
      debugPrint('Error sending location to backend: $e');
    }
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

  List<Polyline> _buildColoredRoutePolylines() {
    final points = _routePoints;
    if (points == null || points.length < 2) return const [];

    final idx = _routeProgressIndex.clamp(0, points.length - 1);
    final split = math.max(1, math.min(idx + 1, points.length - 1));
    final passed = points.sublist(0, split);
    final remaining = points.sublist(split - 1);

    final polylines = <Polyline>[];
    if (passed.length > 1) {
      polylines.add(
        Polyline(
          points: passed,
          color: Colors.grey.shade400,
          strokeWidth: 4,
        ),
      );
    }
    if (remaining.length > 1) {
      polylines.add(
        Polyline(
          points: remaining,
          color: const Color(0xFF2563EB),
          strokeWidth: 4,
        ),
      );
    }
    return polylines;
  }

  Future<void> _takeAttendance() async {
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

        if (widget.tripId == null || widget.tripId! <= 0) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Trip is not started correctly. Please restart trip.'),
            ),
          );
          return;
        }

        if (!mounted) return;
        final nav = Navigator.of(context);
        final result = await nav.push<bool>(
          fadeRoute(
            SupervisorAttendanceScreen(
              imagePath: photo.path,
              tripId: widget.tripId,
              studentId: matched ? identified.studentId : 0,
              studentName: matched ? identified.studentName : '',
              studentGrade: matched ? identified.studentGrade : '',
              studentBirthdate: matched ? identified.studentBirthdate : '',
              busNumber: _busNumber,
              faceAttemptId:
                  matched ? identified.faceAttemptId : identifyResult.attemptId,
              matchConfidence: matched ? identified.matchConfidence : 0,
              allowConfirmAttendance: matched,
              noMatchMessage: matched
                  ? null
                  : (identifyResult.message ??
                      'Face not recognized. Please rescan.'),
            ),
          ),
        );
        if (mounted && result == false) {
          // User explicitly chose "Rescan" from confirmation page.
          await _takeAttendance();
          return;
        }
        if (mounted && result == true && matched) {
          await _loadTripStops();
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
    final tripId = widget.tripId;
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

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
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

      final student = data['student'] is Map<String, dynamic>
          ? data['student'] as Map<String, dynamic>
          : <String, dynamic>{};
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
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final routes = data['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return;
      final firstRoute = routes.first as Map<String, dynamic>;

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

      final geometry = firstRoute['geometry'] as Map<String, dynamic>?;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appScaffoldBackground,
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                // --- TOP HEADER ---
                Container(
                  width: double.infinity,
                  height: 170,
                  padding: const EdgeInsets.fromLTRB(10, 0, 20, 0),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryBlue97,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(16.2),
                      bottomRight: Radius.circular(16.2),
                    ),
                  ),
                  child: Column(
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
                                height: 126,
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
                      const SizedBox(height: 0),
                      Row(
                        children: [
                          const SizedBox(width: 0),
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
                    padding: const EdgeInsets.all(15),
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

                        // --- DYNAMIC MAP BOX (OpenStreetMap via flutter_map) ---
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
                                      : FlutterMap(
                                          mapController: _mapController,
                                          options: MapOptions(
                                            initialCenter: _currentLocation!,
                                            initialZoom: 15,
                                            maxZoom: 18,
                                            minZoom: 3,
                                            onMapEvent: (event) {
                                              if (event is MapEventMove ||
                                                  event is MapEventRotate) {
                                                if (_isMiniMapFollowing) {
                                                  setState(() {
                                                    _isMiniMapFollowing = false;
                                                  });
                                                }
                                              }
                                            },
                                          ),
                                          children: [
                                            TileLayer(
                                              urlTemplate:
                                                  'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                                              subdomains: const ['a', 'b', 'c'],
                                              userAgentPackageName:
                                                  'com.busify.app',
                                            ),
                                            MarkerLayer(
                                              markers: [
                                                Marker(
                                                  point: _currentLocation!,
                                                  width: 18,
                                                  height: 18,
                                                  child: const Icon(
                                                    Icons.directions_car,
                                                    color: Color(0xFF2D7CFF),
                                                    size: 24,
                                                  ),
                                                ),
                                                Marker(
                                                  point: _currentDestination,
                                                  width: 40,
                                                  height: 40,
                                                  child: const Icon(
                                                    Icons.location_pin,
                                                    color: Colors.red,
                                                    size: 36,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (_routePoints != null)
                                              PolylineLayer(
                                                polylines:
                                                    _buildColoredRoutePolylines(),
                                              ),
                                          ],
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
                                        color:
                                            context.appOverlayButtonBackground,
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
                                                const SupervisorFullMapScreen(),
                                              ),
                                            );
                                          },
                                          borderRadius: BorderRadius.circular(
                                            25,
                                          ),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                    children: [
                                      Container(
                                        color: context.appProgressTrack,
                                      ),
                                      FractionallySizedBox(
                                        widthFactor: _totalCount <= 0
                                            ? 0
                                            : (_boardedCount / _totalCount)
                                                .clamp(0.0, 1.0),
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                          color: const Color(0xFF18A74A),
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

                        // Take attendance CTA (325x54 with icon + text)
                        SizedBox(
                          width: 325,
                          height: 54,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryButtonGradient,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _takeAttendance,
                                borderRadius: BorderRadius.circular(10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      AppImages.attendance,
                                      width: 30,
                                      height: 30,
                                      color: Color(0xFF8FBFFA),
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
                        const SizedBox(height: 12),
                        SizedBox(
                          width: 325,
                          height: 54,
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
                                onTap: _markingAbsent ? null : _makeAbsent,
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
                      ],
                    ),
                  ),
                ),

                // --- BOTTOM NAV ---
                _buildBottomNav(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    // README: Home active (2859C5), Attendance inactive (595959), Profile inactive (595959)
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: context.appPanelBackground,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _navItem(
              context,
              AppImages.navbarHomeActive,
              'Home',
              true,
              () => Navigator.pushReplacement(
                context,
                fadeRoute(const SupervisorHomeScreen()),
              ),
            ),
            _navItem(
              context,
              AppImages.navbarAttendance,
              'Attendance',
              false,
              _takeAttendance,
            ),
            _navItem(context, AppImages.navbarProfile, 'Profile', false, () {
              Navigator.push(
                context,
                fadeRoute(const SupervisorProfileScreen()),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _navItem(
    BuildContext context,
    String iconPath,
    String label,
    bool isActive,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          label == 'Profile'
              ? Icon(
                  Icons.person,
                  size: 28,
                  color: isActive ? AppColors.linkBlue : context.appInactiveNav,
                )
              : Image.asset(
                  iconPath,
                  width: 28,
                  height: 28,
                  color: isActive ? AppColors.linkBlue : context.appInactiveNav,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    label == 'Home' ? Icons.home : Icons.fact_check_outlined,
                    size: 28,
                    color: isActive
                        ? AppColors.linkBlue
                        : context.appInactiveNav,
                  ),
                ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isActive ? AppColors.linkBlue : context.appSecondaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class _TripStop {
  final int studentId;
  final String studentName;
  final String studentGrade;
  final String studentBirthdate;
  final latlng.LatLng location;
  final bool completed;

  const _TripStop({
    required this.studentId,
    required this.studentName,
    required this.studentGrade,
    required this.studentBirthdate,
    required this.location,
    this.completed = false,
  });

  _TripStop copyWith({bool? completed}) {
    return _TripStop(
      studentId: studentId,
      studentName: studentName,
      studentGrade: studentGrade,
      studentBirthdate: studentBirthdate,
      location: location,
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

  const _FaceIdentifyHit({
    required this.studentId,
    required this.studentName,
    required this.studentGrade,
    required this.studentBirthdate,
    required this.faceAttemptId,
    required this.matchConfidence,
  });
}
