import 'dart:math' as math;
import 'dart:async';
import 'dart:convert';

import 'package:application/constants/app_colors.dart';
import 'package:application/constants/app_images.dart';
import 'package:application/helpers/app_theme.dart';
import 'package:application/helpers/api_json.dart';
import 'package:application/helpers/app_back_button.dart';
import 'package:application/helpers/supervisor_photo.dart';
import 'package:application/routes/fade_route.dart';
import 'package:application/widgets/parent/parent_bottom_nav_bar.dart';
import 'package:application/widgets/resilient_network_image.dart';
import 'package:flutter/material.dart';
import 'package:application/helpers/map_bus_marker.dart';
import 'package:application/helpers/map_lat_lng.dart';
import 'package:application/helpers/smoothed_lat_lng.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as latlng;
import 'package:application/services/service_locator.dart';
import 'package:application/services/trip_live_updates.dart';

import 'parent_home_screen.dart';
import 'parent_profile_screen.dart';

class _TrackBusLayout {
  _TrackBusLayout._();
  static const double etaLabelToTimeGap = 6;
  static const double navBarVerticalOffset = 0;
}

class ParentTrackBusScreen extends StatefulWidget {
  const ParentTrackBusScreen({
    super.key,
    this.studentId,
    this.studentName,
    this.studentPhotoUrl,
  });

  final int? studentId;
  final String? studentName;
  final String? studentPhotoUrl;

  @override
  State<ParentTrackBusScreen> createState() => _ParentTrackBusScreenState();
}

class _ParentTrackBusScreenState extends State<ParentTrackBusScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _entranceFade;
  late final Animation<Offset> _entranceSlide;
  Timer? _pollTimer;
  StreamSubscription<String>? _liveUpdatesSub;
  static const Duration _pollInterval = Duration(milliseconds: 500);
  final SmoothedLatLng _smoothedBus = SmoothedLatLng(
    duration: const Duration(milliseconds: 400),
  );
  latlng.LatLng? _busLocation;
  latlng.LatLng? _destination;
  String _statusText = 'Loading';
  String _etaText = '--';
  String _studentName = '';
  String? _studentPhotoUrl;
  String _busNumber = '--';
  String _driverName = '--';
  List<latlng.LatLng> _polyline = [];
  bool _hasActiveTrip = true;
  gmaps.GoogleMapController? _mapController;
  double _mapZoom = 14;
  latlng.LatLng? _mapCameraCenter;
  int _routeProgressIndex = 0;
  String _routeDestinationKey = '';
  bool _isMiniMapFollowing = false;
  gmaps.BitmapDescriptor? _busMarkerIcon;
  AnimationController? _recenterController;
  int? _childStudentId;
  bool _isRecentering = false;

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
    _childStudentId = widget.studentId;
    _studentName = widget.studentName ?? '';
    _studentPhotoUrl = widget.studentPhotoUrl;
    unawaited(_loadBusMarkerIcon());
    _loadStudentOverview();
    _liveUpdatesSub = TripLiveUpdates.instance.stream.listen((_) {
      if (mounted) unawaited(_refreshLiveData());
    });
    _bootstrapLiveTracking();
  }

  Future<void> _loadBusMarkerIcon() async {
    try {
      final icon = await MapBusMarker.icon();
      if (mounted) setState(() => _busMarkerIcon = icon);
    } catch (_) {}
  }

  Future<void> _loadStudentOverview() async {
    try {
      final data = await ServiceLocator.parentService.getChildOverview(
        studentId: _childStudentId,
      );
      final students = coerceJsonMapList(data['students'] ?? data['Students']);
      if (students.isEmpty || !mounted) return;
      final selectedStudentId = _childStudentId ?? widget.studentId;
      final first = selectedStudentId == null
          ? students.first
          : students.firstWhere(
            (s) => (s['id'] ?? s['Id']) == selectedStudentId,
        orElse: () => students.first,
      );
      final name = (first['name'] ?? first['Name'])?.toString();
      final sid = first['id'] ?? first['Id'];
      final busIdRaw = first['busId'] ?? first['BusId'] ?? first['bus_id'];
      int? id;
      if (sid is num) id = sid.toInt();
      int? selectedBusId;
      if (busIdRaw is num) selectedBusId = busIdRaw.toInt();
      if (!mounted) return;
      final supervisor = data['supervisor'] as Map<String, dynamic>?;
      final driver = data['driver'] as Map<String, dynamic>?;
      final drv =
      (driver?['name'] ?? driver?['Name'] ?? supervisor?['name'] ?? supervisor?['Name'])
          ?.toString();
      final studentBusNo = (first['busNumber'] ?? first['BusNumber'] ?? first['bus_number'])
          ?.toString()
          .trim();
      final onAssignedBus =
          selectedBusId != null && selectedBusId > 0 && studentBusNo != null && studentBusNo.isNotEmpty;
      setState(() {
        if (name != null && name.isNotEmpty) _studentName = name;
        if (id != null && id > 0) _childStudentId = id;
        if (!onAssignedBus) {
          _busNumber = '--';
          _driverName = '--';
        } else {
          _busNumber = studentBusNo;
          final d = (drv != null && drv.trim().isNotEmpty)
              ? drv.trim()
              : ((supervisor?['name'] ?? supervisor?['Name'])?.toString().trim() ?? '');
          _driverName = d.isEmpty ? '--' : d;
        }
        final photo = readPhotoUrlFromMap(first);
        _studentPhotoUrl =
        (photo != null && photo.trim().isNotEmpty) ? photo.trim() : null;
      });
    } catch (_) {}
  }

  Future<void> _bootstrapLiveTracking() async {
    await _refreshLiveData();
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      _refreshLiveData();
    });
  }

  void _animateMapTo(
    latlng.LatLng target, {
    double? targetZoom,
  }) {
    final controller = _mapController;
    if (!mounted || controller == null) return;
    _isRecentering = true;
    final zoom = targetZoom ?? _mapZoom;
    _mapZoom = zoom;
    _mapCameraCenter = target;
    controller
        .animateCamera(
          gmaps.CameraUpdate.newLatLngZoom(toGoogleLatLng(target), zoom),
        )
        .whenComplete(() {
      if (mounted) _isRecentering = false;
    });
  }

  Future<void> _refreshLiveData() async {
    try {
      final current = await ServiceLocator.parentService.getCurrentTrip(
        studentId: _childStudentId,
      );
      final busInfo = current['bus'] as Map<String, dynamic>?;
      final driverInfo =
          (current['driver'] as Map<String, dynamic>?) ??
              (current['supervisor'] as Map<String, dynamic>?);
      final busNumber =
      (busInfo?['busNumber'] ?? busInfo?['BusNumber'] ?? busInfo?['id'])?.toString();
      final dName = (driverInfo?['name'] ?? driverInfo?['Name'])?.toString();
      final hasActive = current['has_active_trip'] == true;
      if (!hasActive) {
        if (!mounted) return;
        setState(() {
          _hasActiveTrip = false;
          _statusText = 'No active trip';
          _etaText = '--';
          if (busNumber != null && busNumber.trim().isNotEmpty) {
            _busNumber = busNumber.trim();
          }
          _driverName = (dName == null || dName.trim().isEmpty) ? '--' : dName.trim();
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

      final stops = current['stops'] as List<dynamic>? ?? const [];
      final tripTypeStr = (trip['tripType'] ?? trip['TripType']).toString().toLowerCase();
      final isAfternoon = tripTypeStr.contains('afternoon');
      final childDroppedAfternoon =
          current['child_afternoon_dropped_off'] == true ||
              current['childAfternoonDroppedOff'] == true;

      bool childPickedOnTrip = false;
      String? resolvedStudentName;
      for (final raw in stops) {
        if (raw is! Map<String, dynamic>) continue;
        final sidVal = raw['student_id'] ?? raw['studentId'];
        num? sidNum;
        if (sidVal is num) sidNum = sidVal;
        if (_childStudentId != null && sidNum != null && sidNum.toInt() == _childStudentId) {
          resolvedStudentName =
              (raw['student_name'] ?? raw['studentName'] ?? raw['StudentName'])?.toString();
          final pickedRaw = raw['picked'] ?? raw['Picked'];
          childPickedOnTrip = pickedRaw == true;
          break;
        }
      }
      resolvedStudentName ??= () {
        if (_childStudentId != null) return null;
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
          if (destType == 'school') {
            return childPickedOnTrip
                ? 'Your child is on the bus — heading to school'
                : 'Bus heading to school';
          }
          return childPickedOnTrip ? 'On the way home' : 'Bus on the way';
        }
        if (destType == 'school') {
          return childPickedOnTrip
              ? 'Your child is on the bus — heading to school'
              : 'Bus heading to school';
        }
        if (childPickedOnTrip) return 'Your child is on the bus';
        return 'Bus on the way to next stop';
      }();

      final live = await ServiceLocator.parentService.getLiveLocation(tripId);
      final latest = live['latest'] as Map<String, dynamic>?;
      final lat = (latest?['latitude'] as num?)?.toDouble();
      final lng = (latest?['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) return;
      final bus = latlng.LatLng(lat, lng);

      if (!mounted) return;

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
        _routeProgressIndex = _polyline.isNotEmpty ? _closestRouteIndex(bus, _polyline) : 0;
      }

      final nextBusNumber = () {
        if (busInfo == null) return _busNumber;
        final busNumber = busInfo['busNumber'] ?? busInfo['BusNumber'] ?? busInfo['id'];
        return busNumber?.toString() ?? _busNumber;
      }();
      final nextDriver =
          (dName == null || dName.trim().isEmpty) ? _driverName : dName.trim();
      final displayBus = _polyline.length >= 2 ? _snapToPolyline(bus, _polyline) : bus;
      final nextEta = _computeEta(displayBus, target);
      final changed = _hasActiveTrip != true ||
          _destination?.latitude != target?.latitude ||
          _destination?.longitude != target?.longitude ||
          _statusText != statusComputed ||
          _etaText != nextEta ||
          _busNumber != nextBusNumber ||
          _driverName != nextDriver ||
          (resolvedStudentName != null &&
              resolvedStudentName.isNotEmpty &&
              _studentName != resolvedStudentName);

      if (changed) {
        setState(() {
          _hasActiveTrip = true;
          _destination = target;
          _statusText = statusComputed;
          _etaText = nextEta;
          if (resolvedStudentName != null && resolvedStudentName.isNotEmpty) {
            _studentName = resolvedStudentName;
          }
          _busNumber = nextBusNumber;
          _driverName = nextDriver;
        });
      } else {
        _destination = target;
      }

      _applySnappedBusLocation(bus);
    } catch (_) {}
  }

  Future<List<latlng.LatLng>> _fetchRoute(latlng.LatLng from, latlng.LatLng to) async {
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

  latlng.LatLng _snapToPolyline(latlng.LatLng point, List<latlng.LatLng> polyline) {
    if (polyline.length < 2) return point;
    var best = polyline.first;
    var bestDist = double.infinity;
    for (var i = 0; i < polyline.length - 1; i++) {
      final projected = _projectOnSegment(point, polyline[i], polyline[i + 1]);
      final d = _distanceKm(
        point.latitude,
        point.longitude,
        projected.latitude,
        projected.longitude,
      );
      if (d < bestDist) {
        bestDist = d;
        best = projected;
      }
    }
    return best;
  }

  latlng.LatLng _projectOnSegment(
    latlng.LatLng point,
    latlng.LatLng start,
    latlng.LatLng end,
  ) {
    const p = 0.017453292519943295;
    final lat1 = start.latitude * p;
    final lon1 = start.longitude * p;
    final lat2 = end.latitude * p;
    final lon2 = end.longitude * p;
    final lat3 = point.latitude * p;
    final lon3 = point.longitude * p;

    final dx = lat2 - lat1;
    final dy = (lon2 - lon1) * math.cos((lat1 + lat2) / 2);
    final px = lat3 - lat1;
    final py = (lon3 - lon1) * math.cos((lat1 + lat3) / 2);
    final denom = dx * dx + dy * dy;
    final t = denom <= 0 ? 0.0 : (px * dx + py * dy) / denom;
    final clamped = t.clamp(0.0, 1.0);
    return latlng.LatLng(
      (lat1 + dx * clamped) / p,
      (lon1 + (lon2 - lon1) * clamped) / p,
    );
  }

  void _applySnappedBusLocation(latlng.LatLng raw) {
    final snapped = _polyline.length >= 2 ? _snapToPolyline(raw, _polyline) : raw;
    _smoothedBus.setTarget(snapped, onTick: () {
      if (!mounted) return;
      final display = _smoothedBus.value;
      if (display == null) return;
      setState(() {
        _busLocation = display;
        if (_polyline.isNotEmpty) {
          _routeProgressIndex = _closestRouteIndex(display, _polyline);
        }
      });
      if (_isMiniMapFollowing && !_isRecentering) {
        _animateMapTo(display, targetZoom: _mapZoom);
      }
    });
    final display = _smoothedBus.value ?? snapped;
    _busLocation = display;
    if (_polyline.isNotEmpty) {
      _routeProgressIndex = _closestRouteIndex(display, _polyline);
    }
  }

  Set<gmaps.Polyline> _buildColoredRoutePolylines() {
    if (_polyline.isEmpty || _polyline.length < 2) return const {};
    final idx = _routeProgressIndex.clamp(0, _polyline.length - 1);
    final remaining = _polyline.sublist(idx);
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

  Set<gmaps.Marker> _buildTrackMapMarkers() {
    if (_busLocation == null) return const {};
    final busIcon = _busMarkerIcon ??
        gmaps.BitmapDescriptor.defaultMarkerWithHue(
          gmaps.BitmapDescriptor.hueOrange,
        );
    return {
      gmaps.Marker(
        markerId: const gmaps.MarkerId('bus'),
        position: toGoogleLatLng(_busLocation!),
        icon: busIcon,
        anchor: const Offset(0.5, 0.5),
      ),
      if (_destination != null)
        gmaps.Marker(
          markerId: const gmaps.MarkerId('destination'),
          position: toGoogleLatLng(_destination!),
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
            gmaps.BitmapDescriptor.hueRed,
          ),
        ),
    };
  }

  @override
  void dispose() {
    _liveUpdatesSub?.cancel();
    _pollTimer?.cancel();
    _smoothedBus.dispose();
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
        bottom: false,
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ✅ Header is outside the scroll view — stays fixed
            buildHeader(context),

            Expanded(
              child: FadeTransition(
                opacity: _entranceFade,
                child: SlideTransition(
                  position: _entranceSlide,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: buildMapSection()),
                      const SizedBox(height: 12),
                      buildBusStatusCard(context, cardW),
                      const SizedBox(height: 10),
                    ],
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
                  Navigator.of(context).push(fadeRoute(const ParentProfileScreen()));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

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
              top: 35,
              child: AppBackButton(
                onTap: () => Navigator.of(context).pop(),
                color: AppColors.white,
                icon: Icons.arrow_back_ios,
                iconSize: 22.5,
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

  Widget buildMapSection() {
    return _busLocation == null
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
          Positioned.fill(
            child: gmaps.GoogleMap(
              initialCameraPosition: gmaps.CameraPosition(
                target: toGoogleLatLng(_busLocation!),
                zoom: _mapZoom,
              ),
              onMapCreated: (controller) => _mapController = controller,
              onCameraMoveStarted: () {
                if (_isMiniMapFollowing) {
                  setState(() => _isMiniMapFollowing = false);
                }
              },
              onCameraMove: (position) {
                _mapZoom = position.zoom;
                _mapCameraCenter = latlng.LatLng(
                  position.target.latitude,
                  position.target.longitude,
                );
              },
              scrollGesturesEnabled: true,
              zoomGesturesEnabled: true,
              rotateGesturesEnabled: true,
              tiltGesturesEnabled: true,
              myLocationEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              markers: _buildTrackMapMarkers(),
              polylines: _buildColoredRoutePolylines(),
            ),
          ),
          Positioned(
            left: 12,
            bottom: 12,
            child: GestureDetector(
              onTap: () {
                if (_busLocation == null) return;
                setState(() => _isMiniMapFollowing = true);
                _animateMapTo(_busLocation!, targetZoom: 17.4);
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
      );
  }

  Widget buildBusStatusCard(BuildContext context, double cardW) {
    return Center(
      child: Container(
        width: cardW,
        constraints: const BoxConstraints(minHeight: 187),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.trackBusCardTint,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.trackBusCardStroke, width: math.max(1.0, 1)),
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
                  child: _studentAvatar(),
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
                      _infoLine(context, 'Driver:', _driverName),
                      const SizedBox(height: 5),
                      _infoLine(
                        context,
                        'Bus:',
                        (_busNumber.isEmpty || _busNumber == '--')
                            ? 'Not attached on a bus'
                            : _busNumber,
                      ),
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

  Widget _infoLine(BuildContext context, String label, String value) {
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

  Widget _studentAvatar() {
    final urls = supervisorPhotoResolvedUrls(_studentPhotoUrl);
    final fallback = Container(
      width: 52,
      height: 51,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.person, color: Color(0xFF6B7280)),
    );
    if (urls.isNotEmpty) {
      return ResilientNetworkImage(
        urls: urls,
        width: 52,
        height: 51,
        fit: BoxFit.cover,
        fallback: fallback,
      );
    }
    return fallback;
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