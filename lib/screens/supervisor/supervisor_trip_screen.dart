import 'dart:async';
import 'dart:convert';
import 'dart:math' show cos, sqrt, asin;

import 'package:application/constants/app_colors.dart';
import 'package:application/constants/app_images.dart';
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

class _SupervisorTripScreenState extends State<SupervisorTripScreen> {
  // --- LOGIC VARIABLES ---
  Timer? _locationTimer;
  latlng.LatLng? _currentLocation;
  String _eta = "Calculating...";
  List<latlng.LatLng>? _routePoints;
  latlng.LatLng? _lastLocation;
  DateTime? _lastSampleTime;
  DateTime? _lastValidEta;
  Duration _stoppedTime = Duration.zero;
  DateTime? _lastEtaEngineUpdateTime;

  // Student destination (fixed point for now)
  // 30.113451, 31.607125
  final latlng.LatLng _studentDestination = const latlng.LatLng(
    30.113451,
    31.607125,
  );

  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _startTripTracking();
  }

  @override
  void dispose() {
    _locationTimer?.cancel(); // Stop tracking when leaving screen
    super.dispose();
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
          const SnackBar(content: Text('Please enable location services to track the trip.')),
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
            const SnackBar(content: Text('Location permission is required to track the trip.')),
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
          const SnackBar(content: Text('Location permission permanently denied. Enable it from Settings.')),
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

        final nextLocation =
            latlng.LatLng(position.latitude, position.longitude);
        final now = DateTime.now();

        // Compute speed between last sample and this one (km/h)
        double speedKmh = 0;
        if (_lastLocation != null && _lastSampleTime != null) {
          final dtSeconds =
              now.difference(_lastSampleTime!).inMilliseconds / 1000.0;
          if (dtSeconds > 0) {
            final deltaKm = _coordinateDistance(
              _lastLocation!.latitude,
              _lastLocation!.longitude,
              nextLocation.latitude,
              nextLocation.longitude,
            );
            speedKmh = (deltaKm / dtSeconds) * 3600.0;
          }
        }
        _lastLocation = nextLocation;
        _lastSampleTime = now;

        // Remaining distance in km
        final remainingKm = _coordinateDistance(
          nextLocation.latitude,
          nextLocation.longitude,
          _studentDestination.latitude,
          _studentDestination.longitude,
        );

        final nextEta = _updateEtaEngine(now, remainingKm, speedKmh);

        if (mounted) {
          setState(() {
            _currentLocation = nextLocation;
            _eta = nextEta;
          });
        }

        // Fetch road-based route once when we get the first fix
        if (_routePoints == null) {
          await _fetchRoute(nextLocation, _studentDestination);
        }

        // 3. Record to backend (DB)
        await _recordToDatabase(position.latitude, position.longitude);

        // 4. Move map camera to follow Supervisor
        if (_currentLocation != null) {
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

  /// ETA engine implementing the rules:
  /// - If speed > 2 km/h: fresh ETA from distance / speed, reset stopped time.
  /// - If speed ≤ 2 km/h: freeze last valid ETA and add stopped time.
  String _updateEtaEngine(
    DateTime now,
    double remainingDistanceKm,
    double speedKmh,
  ) {
    const double speedThreshold = 2.0; // km/h

    // Delta since last ETA engine update (for stopped time accumulation)
    Duration delta = Duration.zero;
    if (_lastEtaEngineUpdateTime != null) {
      delta = now.difference(_lastEtaEngineUpdateTime!);
    }
    _lastEtaEngineUpdateTime = now;

    if (speedKmh > speedThreshold) {
      // MOVING
      _stoppedTime = Duration.zero;

      if (speedKmh <= 0) {
        // Safety: no division by zero; fall back to last ETA or Calculating
        if (_lastValidEta != null) {
          return _formatEta(_lastValidEta!);
        }
        return "Calculating...";
      }

      final travelHours = remainingDistanceKm / speedKmh;
      final travelSeconds = (travelHours * 3600).clamp(0, double.infinity);
      final eta = now.add(
        Duration(seconds: travelSeconds.isFinite ? travelSeconds.round() : 0),
      );

      _lastValidEta = eta;
      return _formatEta(eta);
    } else {
      // STOPPED
      if (_lastValidEta == null) {
        // No valid ETA yet; still calculating
        return "Calculating...";
      }

      _stoppedTime += delta;
      final eta = _lastValidEta!.add(_stoppedTime);
      return _formatEta(eta);
    }
  }

  String _formatEta(DateTime eta) {
    final hh = eta.hour.toString().padLeft(2, '0');
    final mm = eta.minute.toString().padLeft(2, '0');
    return "$hh:$mm";
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

  Future<void> _takeAttendance(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (photo != null && context.mounted) {
        Navigator.push(
          context,
          fadeRoute(SupervisorAttendanceScreen(imagePath: photo.path)),
        );
      }
    } catch (e) {
      debugPrint('Error opening camera: $e');
    }
  }

  Future<void> _endTrip() async {
    final tripId = widget.tripId;
    if (tripId == null || tripId <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trip ID missing. Please start a trip again.'),
        ),
      );
      return;
    }

    // Stop tracking immediately so we don't keep recording locations.
    _locationTimer?.cancel();

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/v1/Supervisor/end-trip');
      final token = ServiceLocator.tokenStorage.getToken();
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      final body = jsonEncode({'tripId': tripId});

      final resp = await http.post(uri, headers: headers, body: body);
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          fadeRoute(const SupervisorHomeScreen()),
          (route) => false,
        );
      } else {
        if (!mounted) return;
        // Even if the server responded with an error, the trip might have been ended
        // but failed during response serialization. Provide a helpful message and
        // keep the user from continuing to record locations.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'End trip failed: HTTP ${resp.statusCode} ${resp.body}',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('End trip error: $e')),
      );
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
      final geometry =
          (routes.first as Map<String, dynamic>)['geometry'] as Map<String, dynamic>?;
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
      debugPrint('Error fetching route: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    double effectiveWidth = size.width > 450 ? 450 : size.width;

    return Scaffold(
      backgroundColor: AppColors.lightGray,
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: effectiveWidth,
            child: Column(
              children: [
                // --- TOP HEADER ---
                Container(
                  width: double.infinity,
                  height: 182,
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
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
                              size: 28,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Expanded(
                            child: Center(
                              child: SizedBox(
                                height: 80,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Image.asset(
                                    AppImages.logo,
                                    height: 80,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.directions_bus,
                                      color: Colors.white,
                                      size: 44,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE31E24),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'SOS',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),
                      Row(
                        children: [
                          const SizedBox(width: 10),
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
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          const Expanded(
                            child: Text(
                              'welcome, Ali',
                              style: TextStyle(
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
                    padding: const EdgeInsets.all(16),
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
                                  color: Color(0xE0FFCA07),
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

                        const SizedBox(height: 12),

                        // End trip button (red) - requested behavior
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0xFFA90707),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _endTrip,
                                borderRadius: BorderRadius.circular(12),
                                child: const Center(
                                  child: Text(
                                    'End Trip',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            _currentLocation == null
                                ? 'Current Location: waiting for GPS...'
                                : 'Current Location: ${_currentLocation!.latitude.toStringAsFixed(6)}, ${_currentLocation!.longitude.toStringAsFixed(6)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF333333),
                            ),
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
                                          ),
                                          children: [
                                            TileLayer(
                                              urlTemplate:
                                                  'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                                              subdomains: const ['a', 'b', 'c'],
                                              userAgentPackageName:
                                                  'com.example.application',
                                            ),
                                      MarkerLayer(
                                        markers: [
                                          Marker(
                                            point: _currentLocation!,
                                            width: 40,
                                            height: 40,
                                            child: const Icon(
                                              Icons.directions_bus_filled,
                                              color: Colors.blueAccent,
                                              size: 32,
                                            ),
                                          ),
                                          Marker(
                                            point: _studentDestination,
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
                                ),
                                Positioned(
                                  right: 12,
                                  bottom: 12,
                                  child: SizedBox(
                                    width: 168,
                                    height: 30,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: AppColors.e6e9ed,
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
                                              fadeRoute(const SupervisorFullMapScreen()),
                                            );
                                          },
                                          borderRadius: BorderRadius.circular(
                                            25,
                                          ),
                                          child: const Center(
                                            child: Text(
                                              'View Full Map',
                                              style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 15,
                                                fontWeight: FontWeight.w500,
                                                height: 22 / 15,
                                                color: AppColors.primaryBlue97,
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
                            color: const Color(0xFFE6E9ED),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            children: [
                              const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Students Boarded',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    '20 / 25',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
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
                                        color: const Color(0xBCD4D4D4),
                                      ),
                                      FractionallySizedBox(
                                        widthFactor: 20 / 25,
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
                              const Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Color(0xFF18A74A),
                                    radius: 10,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Boarded 20',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(width: 30),
                                  CircleAvatar(
                                    backgroundColor: Color(0x87FFCA07),
                                    radius: 10,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Remaining 5',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
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
                                onTap: () => _takeAttendance(context),
                                borderRadius: BorderRadius.circular(10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      AppImages.attendance,
                                      width: 30,
                                      height: 30,
                                      color: Color(0xFF8FBFFA),
                                      errorBuilder: (_, __, ___) => const Icon(
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
          color: AppColors.e6e9ed,
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
              () {},
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
                  color: isActive ? AppColors.linkBlue : AppColors.gray333,
                )
              : Image.asset(
                  iconPath,
                  width: 28,
                  height: 28,
                  color: isActive ? AppColors.linkBlue : AppColors.gray333,
                  errorBuilder: (_, __, ___) => Icon(
                    label == 'Home'
                        ? Icons.home
                        : Icons.fact_check_outlined,
                    size: 28,
                    color: isActive ? AppColors.linkBlue : AppColors.gray333,
                  ),
                ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isActive ? AppColors.linkBlue : AppColors.grayText,
            ),
          ),
        ],
      ),
    );
  }
}
