import 'dart:math' as math;
import 'dart:async';
import 'dart:convert';

import 'package:application/constants/app_colors.dart';
import 'package:application/constants/app_images.dart';
import 'package:application/helpers/app_theme.dart';
import 'package:application/routes/fade_route.dart';
import 'package:application/widgets/parent/parent_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as latlng;
import 'package:application/services/service_locator.dart';

import 'parent_home_screen.dart';
import 'parent_profile_screen.dart';

/// Tune spacing on this screen without hunting through the widget tree.
class _TrackBusLayout {
  _TrackBusLayout._();

  /// Horizontal gap between the "ETA:" label and the time value (e.g. "7 minutes").
  /// Increase to separate them, decrease to bring them closer.
  static const double etaLabelToTimeGap = 6;

  /// Moves the bottom navigation bar vertically. Positive = higher on screen,
  /// negative = lower. Uses [Transform.translate] (does not change hit targets
  /// unless you wrap with a larger hit area — adjust if taps feel off).
  static const double navBarVerticalOffset = 0;
}

/// Parent track bus screen.
class ParentTrackBusScreen extends StatefulWidget {
  const ParentTrackBusScreen({super.key});

  @override
  State<ParentTrackBusScreen> createState() => _ParentTrackBusScreenState();
}

class _ParentTrackBusScreenState extends State<ParentTrackBusScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _entranceFade;
  late final Animation<Offset> _entranceSlide;
  Timer? _pollTimer;
  latlng.LatLng? _busLocation;
  latlng.LatLng? _destination;
  String _statusText = 'Loading';
  String _etaText = '--';
  String _studentName = '';
  String _busNumber = '--';
  List<latlng.LatLng> _polyline = [];
  bool _hasActiveTrip = true;
  final MapController _mapController = MapController();
  int _routeProgressIndex = 0;
  String _routeDestinationKey = '';
  bool _isMiniMapFollowing = true;
  AnimationController? _recenterController;
  int? _childStudentId;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _entranceFade = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _entranceSlide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );
    _entranceController.forward();
    _loadStudentOverview();
    _bootstrapLiveTracking();
  }

  Future<void> _loadStudentOverview() async {
    try {
      final data = await ServiceLocator.parentService.getChildOverview();
      final students =
          ((data['students'] ?? data['Students']) as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList();
      if (students.isEmpty || !mounted) return;
      final first = students.first;
      final name = (first['name'] ?? first['Name'])?.toString();
      final sid = first['id'] ?? first['Id'];
      int? id;
      if (sid is num) id = sid.toInt();
      if (!mounted) return;
      setState(() {
        if (name != null && name.isNotEmpty) _studentName = name;
        if (id != null && id > 0) _childStudentId = id;
      });
    } catch (_) {}
  }

  Future<void> _bootstrapLiveTracking() async {
    await _refreshLiveData();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _refreshLiveData();
    });
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

  Future<void> _refreshLiveData() async {
    try {
      final current = await ServiceLocator.parentService.getCurrentTrip();
      final hasActive = current['has_active_trip'] == true;
      if (!hasActive) {
        if (!mounted) return;
        setState(() {
          _hasActiveTrip = false;
          _statusText = 'No active trip';
          _etaText = '--';
          _busNumber = '--';
          _busLocation = null;
          _destination = null;
          _polyline = [];
          _routeDestinationKey = '';
          _routeProgressIndex = 0;
        });
        return;
      }

      final trip = (current['trip'] as Map<String, dynamic>? ?? {});
      final tripId = (trip['id'] as num?)?.toInt();
      if (tripId == null) return;

      latlng.LatLng? target;
      final destination = current['destination'] as Map<String, dynamic>? ?? {};
      final destType = destination['destination_type']?.toString();
      final destLat = (destination['latitude'] as num?)?.toDouble();
      final destLng = (destination['longitude'] as num?)?.toDouble();
      if (destLat != null && destLng != null) {
        target = latlng.LatLng(destLat, destLng);
      }

      final busInfo = current['bus'] as Map<String, dynamic>?;
      final stops = current['stops'] as List<dynamic>? ?? const [];

      final tripTypeStr =
          (trip['tripType'] ?? trip['TripType']).toString().toLowerCase();
      final isAfternoon = tripTypeStr.contains('afternoon');
      final childDroppedAfternoon =
          current['child_afternoon_dropped_off'] == true ||
              current['childAfternoonDroppedOff'] == true;

      String? resolvedStudentName;
      for (final raw in stops) {
        if (raw is! Map<String, dynamic>) continue;
        final sidVal = raw['student_id'] ?? raw['studentId'];
        num? sidNum;
        if (sidVal is num) sidNum = sidVal;
        if (_childStudentId != null &&
            sidNum != null &&
            sidNum.toInt() == _childStudentId) {
          resolvedStudentName =
              (raw['student_name'] ?? raw['studentName'] ?? raw['StudentName'])
                  ?.toString();
          break;
        }
      }
      resolvedStudentName ??= () {
        if (stops.isEmpty) return null;
        final first = stops.firstWhere(
          (s) => s is Map<String, dynamic>,
          orElse: () => stops.first,
        );
        if (first is Map<String, dynamic>) {
          return (first['student_name'] ?? first['studentName'] ?? first['StudentName'])
              ?.toString();
        }
        return null;
      }();

      final statusComputed = () {
        if (isAfternoon) {
          if (childDroppedAfternoon) return 'Arrived home';
          if (destType == 'school') return 'Heading to school';
          return 'On the way home';
        }
        return destType == 'school'
            ? 'On the way to school'
            : 'On the way';
      }();

      final live = await ServiceLocator.parentService.getLiveLocation(tripId);
      final latest = live['latest'] as Map<String, dynamic>?;
      final lat = (latest?['latitude'] as num?)?.toDouble();
      final lng = (latest?['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) return;
      final bus = latlng.LatLng(lat, lng);

      if (!mounted) return;

      // Only refetch route when destination changes.
      final destKey = target == null
          ? ''
          : '${target.latitude.toStringAsFixed(5)},${target.longitude.toStringAsFixed(5)}';
      bool destinationChanged = destKey != _routeDestinationKey;

      if (target == null) {
        _polyline = [];
        _routeDestinationKey = '';
        _routeProgressIndex = 0;
      } else if (destinationChanged || _polyline.isEmpty) {
        final line = await _fetchRoute(bus, target);
        if (!mounted) return;
        _polyline = line;
        _routeDestinationKey = destKey;
        _routeProgressIndex = _polyline.isNotEmpty
            ? _closestRouteIndex(bus, _polyline)
            : 0;
      } else if (_polyline.isNotEmpty) {
        _routeProgressIndex = _closestRouteIndex(bus, _polyline);
      }

      setState(() {
        _hasActiveTrip = true;
        _busLocation = bus;
        _destination = target;
        _statusText = statusComputed;
        _etaText = _computeEta(bus, target);
        if (resolvedStudentName != null && resolvedStudentName.isNotEmpty) {
          _studentName = resolvedStudentName;
        }
        if (busInfo != null) {
          final busNumber =
              busInfo['busNumber'] ?? busInfo['BusNumber'] ?? busInfo['id'];
          if (busNumber != null) {
            _busNumber = busNumber.toString();
          }
        }
      });

      // Follow bus automatically unless user moved the map.
      if (_isMiniMapFollowing) {
        _mapController.move(bus, _mapController.camera.zoom);
      }
    } catch (_) {}
  }

  Future<List<latlng.LatLng>> _fetchRoute(
    latlng.LatLng from,
    latlng.LatLng to,
  ) async {
    final uri = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/${from.longitude},${from.latitude};${to.longitude},${to.latitude}?overview=full&geometries=geojson',
    );
    final resp = await http.get(uri);
    if (resp.statusCode != 200) return [];
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final routes = data['routes'] as List<dynamic>? ?? const [];
    if (routes.isEmpty) return [];
    final geometry = (routes.first as Map<String, dynamic>)['geometry'] as Map<String, dynamic>?;
    final coords = geometry?['coordinates'] as List<dynamic>? ?? const [];
    return coords
        .whereType<List<dynamic>>()
        .where((c) => c.length >= 2)
        .map((c) => latlng.LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
        .toList();
  }

  String _computeEta(latlng.LatLng bus, latlng.LatLng? dest) {
    if (dest == null) return '--';
    final dKm = _distanceKm(bus.latitude, bus.longitude, dest.latitude, dest.longitude);
    final mins = ((dKm / 28.0) * 60).ceil();
    if (mins <= 0) return '0 min';
    return '$mins min';
  }

  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) * math.cos(lat2 * p) * (1 - math.cos((lon2 - lon1) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a));
  }

  int _closestRouteIndex(latlng.LatLng current, List<latlng.LatLng> points) {
    var bestIdx = 0;
    var bestDist = double.infinity;
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final d = _distanceKm(current.latitude, current.longitude, p.latitude, p.longitude);
      if (d < bestDist) {
        bestDist = d;
        bestIdx = i;
      }
    }
    return bestIdx;
  }

  List<Polyline> _buildColoredRoutePolylines() {
    if (_polyline.isEmpty || _polyline.length < 2) return const [];

    final idx = _routeProgressIndex.clamp(0, _polyline.length - 1);
    final split = math.max(1, math.min(idx + 1, _polyline.length - 1));
    final passed = _polyline.sublist(0, split);
    final remaining = _polyline.sublist(split - 1);

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

  @override
  void dispose() {
    _pollTimer?.cancel();
    _recenterController?.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final cardW = math.min(364.0, screenW - 26);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: context.appScaffoldBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.only(bottom: 12 + bottomInset),
                child: FadeTransition(
                  opacity: _entranceFade,
                  child: SlideTransition(
                    position: _entranceSlide,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        buildHeader(context),
                        buildMapSection(),
                        const SizedBox(height: 16),
                        buildBusStatusCard(context, cardW),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Transform.translate(
              offset: Offset(0, -_TrackBusLayout.navBarVerticalOffset),
              child: ParentBottomNavBar(
                activeTab: ParentNavTab.trackBus,
                onHomeTap: () {
                  final nav = Navigator.of(context);
                  if (nav.canPop()) {
                    nav.pop();
                  } else {
                    nav.pushReplacement(fadeRoute(const ParentHomeScreen()));
                  }
                },
                onTrackBusTap: () {},
                onProfileTap: () {
                  Navigator.of(context).push(
                    fadeRoute(const ParentProfileScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Blue header (h 139), radius 22, back + centered logo.
  Widget buildHeader(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(22),
        bottomRight: Radius.circular(22),
      ),
      child: SizedBox(
        height: 120,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: double.infinity,
              height: 139,
              color: AppColors.primaryBlue,
            ),
            Positioned.fill(
              child: Center(
                child: Image.asset(
                  AppImages.trackBusLogo,
                  width: 126,
                  height: 126,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              left: 15,
              top: 10,
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: AppColors.white,
                  size: 22.5,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 10,
              child: Center(child: _TrackBusTitle()),
            ),
          ],
        ),
      ),
    );
  }

  /// Full-width map, height 442.
  Widget buildMapSection() {
    return SizedBox(
      width: double.infinity,
      height: 442,
      child: _busLocation == null
          ? Center(
              child: _hasActiveTrip
                  ? const CircularProgressIndicator()
                  : const Text(
                      'There is no trip going right now.',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
            )
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _busLocation!,
                    initialZoom: 14,
                    maxZoom: 18,
                    minZoom: 3,
                    onMapEvent: (event) {
                      if (event is MapEventMove || event is MapEventRotate) {
                        if (_isMiniMapFollowing) {
                          setState(() => _isMiniMapFollowing = false);
                        }
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'com.busify.app',
                    ),
                    if (_polyline.isNotEmpty)
                      PolylineLayer(
                        polylines: _buildColoredRoutePolylines(),
                      ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _busLocation!,
                          width: 34,
                          height: 34,
                      child: const Icon(Icons.directions_car_filled, color: Colors.blue, size: 30),
                        ),
                        if (_destination != null)
                          Marker(
                            point: _destination!,
                            width: 34,
                            height: 34,
                            child: const Icon(Icons.location_pin, color: Colors.red, size: 30),
                          ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: GestureDetector(
                    onTap: () {
                      if (_busLocation == null) return;
                      setState(() => _isMiniMapFollowing = true);
                      _animateMapTo(_busLocation!, targetZoom: 16);
                    },
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.my_location, color: AppColors.primaryBlue),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  /// Status card 364×187, floating over layout flow (spacing handled by scroll).
  Widget buildBusStatusCard(BuildContext context, double cardW) {
    return Center(
      child: Container(
        width: cardW,
        constraints: const BoxConstraints(minHeight: 187),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.trackBusCardTint,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.trackBusCardStroke,
            width: math.max(1.0, 1),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.trackBusCardShadow,
              offset: const Offset(0, 4),
              blurRadius: 4,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: Image.asset(
                    AppImages.trackBusProfile,
                    width: 52,
                    height: 51,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _studentName.isEmpty ? '—' : _studentName,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          height: 22 / 20,
                          color: context.appPrimaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Status: ',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: context.appSecondaryText,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              _statusText,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.greenStatusBright,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Text(
                            'ETA: ',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: context.appSecondaryText,
                            ),
                          ),
                          SizedBox(width: _TrackBusLayout.etaLabelToTimeGap),
                          Text(
                            _etaText,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: context.appSecondaryText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Container(height: 1, color: AppColors.dividerTrackBus),
            ),
            Row(
              children: [
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoLine(context, 'Driver:', 'Ahmed Ali'),
                      const SizedBox(height: 5),
                      _infoLine(context, 'Bus:', _busNumber),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoLine(
    BuildContext context,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: context.appSecondaryText,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: context.appSecondaryText,
            ),
          ),
        ),
      ],
    );
  }
}

class _TrackBusTitle extends StatelessWidget {
  const _TrackBusTitle();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Track Bus',
      style: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 22 / 24,
        color: AppColors.white,
      ),
    );
  }
}
