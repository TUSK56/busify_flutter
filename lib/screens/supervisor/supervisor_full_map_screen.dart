import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:application/constants/app_colors.dart';
import 'package:application/helpers/api_json.dart';
import 'package:application/helpers/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:application/constants/location_tracking.dart';
import 'package:application/helpers/live_gps_tracker.dart';
import 'package:application/helpers/map_bus_marker.dart';
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

  /// Seed from trip screen so the map renders immediately (no spinner stall).
  final latlng.LatLng? initialLocation;

  /// Optional cached route from the trip mini-map.
  final List<latlng.LatLng>? initialRoutePoints;

  const SupervisorFullMapScreen({
    super.key,
    required this.routeDestination,
    this.tripId,
    this.initialLocation,
    this.initialRoutePoints,
  });

  @override
  State<SupervisorFullMapScreen> createState() =>
      _SupervisorFullMapScreenState();
}

class _SupervisorFullMapScreenState extends State<SupervisorFullMapScreen>
    with TickerProviderStateMixin {
  gmaps.GoogleMapController? _mapController;
  gmaps.BitmapDescriptor? _busMarkerIcon;
  double _mapZoom = 15;
  final LiveGpsTracker _gpsTracker = LiveGpsTracker();
  int _routeProgressIndex = 0;
  latlng.LatLng? _currentLocation;
  bool _isFollowing = true;
  bool _isRecentering = false;
  AnimationController? _recenterController;

  List<latlng.LatLng>? _routePoints;
  latlng.LatLng? _routeBuiltForStart;
  latlng.LatLng? _routeBuiltForDestination;

  @override
  void initState() {
    super.initState();
    _currentLocation = widget.initialLocation;
    if (widget.initialRoutePoints != null &&
        widget.initialRoutePoints!.length >= 2) {
      _routePoints = List<latlng.LatLng>.from(widget.initialRoutePoints!);
      _routeBuiltForStart = widget.initialLocation;
      _routeBuiltForDestination = widget.routeDestination;
    }
    unawaited(_loadBusMarkerIcon());
    unawaited(_startLocationLoop());
  }

  Future<void> _loadBusMarkerIcon() async {
    try {
      final icon = await MapBusMarker.icon();
      if (mounted) setState(() => _busMarkerIcon = icon);
    } catch (e) {
      debugPrint('Bus map marker load failed: $e');
    }
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
    unawaited(_gpsTracker.stop());
    _recenterController?.dispose();
    _recenterController = null;
    super.dispose();
  }

  void _animateMapTo(latlng.LatLng target, {double? targetZoom}) {
    final controller = _mapController;
    if (!mounted || controller == null) return;
    _isRecentering = true;
    final zoom = targetZoom ?? _mapZoom;
    _mapZoom = zoom;
    controller
        .animateCamera(
          gmaps.CameraUpdate.newLatLngZoom(toGoogleLatLng(target), zoom),
        )
        .whenComplete(() {
      if (mounted) _isRecentering = false;
    });
  }

  void _recenterMap() {
    final target = _currentLocation ?? widget.initialLocation ?? widget.routeDestination;
    setState(() => _isFollowing = true);
    _animateMapTo(target, targetZoom: 16.0);
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

    final dest = widget.routeDestination;
    final seed = _currentLocation;
    if (seed != null && _needsRouteRefetch(seed, dest)) {
      await _fetchRoute(seed, dest);
    }

    try {
      final initial = await Geolocator.getCurrentPosition(
        desiredAccuracy: kLiveTrackingAccuracy,
      );
      final loc = latlng.LatLng(initial.latitude, initial.longitude);
      if (!mounted) return;
      setState(() => _currentLocation = loc);
      if (_needsRouteRefetch(loc, dest)) {
        await _fetchRoute(loc, dest);
      }
      if (_isFollowing) {
        _animateMapTo(loc, targetZoom: _mapZoom);
      }
    } catch (e) {
      debugPrint('Full map initial GPS fix failed: $e');
    }

    await _gpsTracker.start((position) async {
      try {
        final nextLocation = latlng.LatLng(
          position.latitude,
          position.longitude,
        );

        if (_needsRouteRefetch(nextLocation, dest)) {
          await _fetchRoute(nextLocation, dest);
        }

        if (!mounted) return;

        setState(() {
          _currentLocation = nextLocation;
          if (_routePoints != null && _routePoints!.isNotEmpty) {
            _routeProgressIndex =
                _closestRouteIndex(nextLocation, _routePoints!);
          }
        });

        if (_isFollowing && !_isRecentering) {
          _animateMapTo(nextLocation, targetZoom: _mapZoom);
        }
      } catch (e) {
        debugPrint('Full map location loop error: $e');
      }
    });
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
          if (_currentLocation != null) {
            _routeProgressIndex =
                _closestRouteIndex(_currentLocation!, _routePoints!);
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching full map route: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final dest = widget.routeDestination;
    final busPos = _currentLocation ?? widget.initialLocation;
    final cameraTarget = busPos ?? dest;

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
            gmaps.GoogleMap(
              initialCameraPosition: gmaps.CameraPosition(
                target: toGoogleLatLng(cameraTarget),
                zoom: _mapZoom,
              ),
              onMapCreated: (controller) => _mapController = controller,
              onCameraMoveStarted: () {
                if (_isRecentering) return;
                if (_isFollowing) {
                  setState(() => _isFollowing = false);
                }
              },
              onCameraMove: (position) => _mapZoom = position.zoom,
              scrollGesturesEnabled: true,
              zoomGesturesEnabled: true,
              rotateGesturesEnabled: true,
              tiltGesturesEnabled: true,
              myLocationEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              markers: {
                if (busPos != null)
                  gmaps.Marker(
                    markerId: const gmaps.MarkerId('bus'),
                    position: toGoogleLatLng(busPos),
                    icon: _busMarkerIcon ??
                        gmaps.BitmapDescriptor.defaultMarkerWithHue(
                          gmaps.BitmapDescriptor.hueOrange,
                        ),
                    anchor: const Offset(0.5, 0.5),
                  ),
                gmaps.Marker(
                  markerId: const gmaps.MarkerId('destination'),
                  position: toGoogleLatLng(dest),
                  icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
                    gmaps.BitmapDescriptor.hueRed,
                  ),
                ),
              },
              polylines: () {
                final points = _routePoints;
                if (points == null || points.length < 2) {
                  return const <gmaps.Polyline>{};
                }
                final idx = _routeProgressIndex.clamp(0, points.length - 1);
                final remaining = points.sublist(idx);
                if (remaining.length < 2) return const <gmaps.Polyline>{};
                return {
                  gmaps.Polyline(
                    polylineId: const gmaps.PolylineId('remaining'),
                    points: toGoogleLatLngList(remaining),
                    color: const Color(0xFF2563EB),
                    width: 4,
                  ),
                };
              }(),
            ),
            if (busPos == null)
              const Positioned.fill(
                child: IgnorePointer(
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            Positioned(
              left: 16,
              bottom: 24,
              child: GestureDetector(
                onTap: _recenterMap,
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
                  child: const Icon(
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
