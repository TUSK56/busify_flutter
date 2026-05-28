import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:application/constants/app_colors.dart';
import 'package:application/helpers/api_json.dart';
import 'package:application/helpers/app_theme.dart';
import 'package:application/services/service_locator.dart';
import 'package:application/utils/api_config.dart';
import 'package:flutter/material.dart';
import 'package:application/constants/location_tracking.dart';
import 'package:application/helpers/map_lat_lng.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as latlng;

/// Full-screen map aligned with [SupervisorTripScreen] routing: same OSRM
/// leg from supervisor GPS to [routeDestination] (nearest incomplete stop or school).
class SupervisorFullMapScreen extends StatefulWidget {
  /// Trip leg destination (must match trip screen `_currentDestination`).
  final latlng.LatLng routeDestination;

  /// Optional; reserved for parity with trip APIs / logging.
  final int? tripId;

  const SupervisorFullMapScreen({
    super.key,
    required this.routeDestination,
    this.tripId,
  });

  @override
  State<SupervisorFullMapScreen> createState() =>
      _SupervisorFullMapScreenState();
}

class _SupervisorFullMapScreenState extends State<SupervisorFullMapScreen>
    with TickerProviderStateMixin {
  gmaps.GoogleMapController? _mapController;
  double _mapZoom = 15;
  Timer? _locationTimer;
  latlng.LatLng? _currentLocation;
  bool _isFollowing = true;
  AnimationController? _recenterController;

  List<latlng.LatLng>? _routePoints;
  latlng.LatLng? _routeBuiltForStart;
  latlng.LatLng? _routeBuiltForDestination;

  @override
  void initState() {
    super.initState();
    _startLocationLoop();
  }

  @override
  void didUpdateWidget(covariant SupervisorFullMapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.routeDestination.latitude != widget.routeDestination.latitude ||
        oldWidget.routeDestination.longitude !=
            widget.routeDestination.longitude) {
      setState(() {
        _routePoints = null;
        _routeBuiltForStart = null;
        _routeBuiltForDestination = null;
      });
    }
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
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

  bool _needsRouteRefetch(latlng.LatLng start, latlng.LatLng destination) {
    if (_routePoints == null || _routePoints!.isEmpty) return true;
    if (_routeBuiltForDestination == null) return true;
    if (_routeBuiltForStart == null) return true;
    final dDest = _coordinateDistance(
      _routeBuiltForDestination!.latitude,
      _routeBuiltForDestination!.longitude,
      destination.latitude,
      destination.longitude,
    );
    final dStart = _coordinateDistance(
      _routeBuiltForStart!.latitude,
      _routeBuiltForStart!.longitude,
      start.latitude,
      start.longitude,
    );
    // Refetch if destination moved or supervisor moved a lot (new leg).
    return dDest > 0.0005 || dStart > 0.002;
  }

  double _coordinateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final p = 0.017453292519943295;
    final c = math.cos;
    final a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a.clamp(0.0, 1.0)));
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

    _locationTimer = Timer.periodic(kLiveLocationInterval, (
      Timer timer,
    ) async {
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: kLiveTrackingAccuracy,
        );

        final nextLocation = latlng.LatLng(
          position.latitude,
          position.longitude,
        );

        if (!mounted) return;

        setState(() {
          _currentLocation = nextLocation;
        });

        final dest = widget.routeDestination;
        if (_needsRouteRefetch(nextLocation, dest)) {
          await _fetchRoute(nextLocation, dest);
        }

        await _recordToDatabase(position.latitude, position.longitude);

        if (_isFollowing && _currentLocation != null) {
          _animateMapTo(_currentLocation!, targetZoom: _mapZoom);
        }
      } catch (e) {
        debugPrint('Full map location loop error: $e');
      }
    });
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
      final data = coerceJsonMap(jsonDecode(resp.body));
      if (data == null) return;
      final routes = data['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return;
      final firstRoute = coerceJsonMap(routes.first);
      if (firstRoute == null) return;
      final geometry = coerceJsonMap(firstRoute['geometry']);
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
          _routeBuiltForStart = start;
          _routeBuiltForDestination = destination;
        });
      }
    } catch (e) {
      debugPrint('Error fetching full map route: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final dest = widget.routeDestination;
    return Scaffold(
      backgroundColor: context.appScaffoldBackground,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(65),
        child: AppBar(
          backgroundColor: AppColors.primaryBlue97,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white, size: 45),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Trip Map',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 35,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          children: [
            if (_currentLocation == null)
              const Center(child: CircularProgressIndicator())
            else
              gmaps.GoogleMap(
                initialCameraPosition: gmaps.CameraPosition(
                  target: toGoogleLatLng(_currentLocation!),
                  zoom: _mapZoom,
                ),
                onMapCreated: (controller) => _mapController = controller,
                onCameraMoveStarted: () {
                  if (_isFollowing) {
                    setState(() => _isFollowing = false);
                  }
                },
                onCameraMove: (position) => _mapZoom = position.zoom,
                myLocationEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                markers: {
                  gmaps.Marker(
                    markerId: const gmaps.MarkerId('supervisor'),
                    position: toGoogleLatLng(_currentLocation!),
                    icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
                      gmaps.BitmapDescriptor.hueAzure,
                    ),
                  ),
                  gmaps.Marker(
                    markerId: const gmaps.MarkerId('destination'),
                    position: toGoogleLatLng(dest),
                    icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
                      gmaps.BitmapDescriptor.hueRed,
                    ),
                  ),
                },
                polylines: _routePoints == null
                    ? const {}
                    : {
                        gmaps.Polyline(
                          polylineId: const gmaps.PolylineId('route'),
                          points: toGoogleLatLngList(_routePoints!),
                          color: Colors.deepPurpleAccent,
                          width: 4,
                        ),
                      },
              ),
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
                    color: Color(0xff2859c5),
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
