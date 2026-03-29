import 'dart:async';
import 'dart:convert';

import 'package:application/constants/app_colors.dart';
import 'package:application/helpers/app_theme.dart';
import 'package:application/services/service_locator.dart';
import 'package:application/utils/api_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as latlng;

/// Full-screen map that shows the current trip and lets the user
/// freely move the map. Pressing the recenter button (bottom-left)
/// jumps back to the current location and enables following again.
class SupervisorFullMapScreen extends StatefulWidget {
  const SupervisorFullMapScreen({super.key});

  @override
  State<SupervisorFullMapScreen> createState() =>
      _SupervisorFullMapScreenState();
}

class _SupervisorFullMapScreenState extends State<SupervisorFullMapScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  Timer? _locationTimer;
  latlng.LatLng? _currentLocation;
  bool _isFollowing = true;
  AnimationController? _recenterController;

  // Same fixed destination used in SupervisorTripScreen (student/home)
  // 30.113451, 31.607125
  final latlng.LatLng _destination = const latlng.LatLng(30.113451, 31.607125);
  List<latlng.LatLng>? _routePoints;

  @override
  void initState() {
    super.initState();
    _startLocationLoop();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
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

  Future<void> _startLocationLoop() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) {
      return;
    }

    _locationTimer = Timer.periodic(const Duration(seconds: 2), (
      Timer timer,
    ) async {
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        final nextLocation = latlng.LatLng(
          position.latitude,
          position.longitude,
        );

        if (!mounted) return;

        setState(() {
          _currentLocation = nextLocation;
        });

        if (_routePoints == null) {
          await _fetchRoute(nextLocation, _destination);
        }

        // Optionally keep sending live location while full map is open
        await _recordToDatabase(position.latitude, position.longitude);

        if (_isFollowing && _currentLocation != null) {
          _animateMapTo(
            _currentLocation!,
            targetZoom: _mapController.camera.zoom,
          );
        }
      } catch (e) {
        debugPrint('Full map location loop error: $e');
      }
    });
  }

  Widget _buildLiveLocationDot() {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF2D7CFF),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            offset: const Offset(0, 1),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }

  Future<void> _recordToDatabase(double lat, double lng) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/v1/Supervisor/live-location');
      final token = ServiceLocator.tokenStorage.getToken();
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      final body = {
        'latitude': lat,
        'longitude': lng,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      };
      final resp = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        debugPrint('Full map location save failed: ${resp.statusCode}');
      }
    } catch (e) {
      debugPrint('Error sending full map location: $e');
    }
  }

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
        debugPrint('Full map route fetch failed: ${resp.statusCode}');
        return;
      }
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final routes = data['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return;
      final geometry =
          (routes.first as Map<String, dynamic>)['geometry']
              as Map<String, dynamic>?;
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
        });
      }
    } catch (e) {
      debugPrint('Error fetching full map route: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appScaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue97,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Trip Map',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
        children: [
          if (_currentLocation == null)
            const Center(child: CircularProgressIndicator())
          else
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentLocation!,
                initialZoom: 15,
                maxZoom: 18,
                minZoom: 3,
                onMapEvent: (event) {
                  // When user interacts with the map (pan/zoom), stop following
                  if (event is MapEventMove || event is MapEventRotate) {
                    if (_isFollowing) {
                      setState(() {
                        _isFollowing = false;
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
                  userAgentPackageName: 'com.example.application',
                ),
                if (_currentLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _currentLocation!,
                        width: 18,
                        height: 18,
                        child: _buildLiveLocationDot(),
                      ),
                      Marker(
                        point: _destination,
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
                    polylines: [
                      Polyline(
                        points: _routePoints!,
                        color: Colors.deepPurpleAccent,
                        strokeWidth: 4,
                      ),
                    ],
                  ),
              ],
            ),

          // Recenter button bottom-left
          Positioned(
            left: 16,
            bottom: 24,
            child: GestureDetector(
              onTap: () {
                if (_currentLocation == null) return;
                setState(() {
                  _isFollowing = true;
                });
                _animateMapTo(_currentLocation!, targetZoom: 16.0);
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
        ],
      ),
      ),
    );
  }
}
