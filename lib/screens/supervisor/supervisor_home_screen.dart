import 'package:application/constants/app_colors.dart';
import 'package:application/constants/app_images.dart';
import 'package:application/helpers/app_theme.dart';
import 'package:application/helpers/fade_route.dart';
import 'package:application/screens/supervisor/supervisor_profile_screen.dart';
import 'package:application/screens/supervisor/supervisor_trip_screen.dart';
import 'package:application/utils/api_config.dart';
import 'package:application/services/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SupervisorHomeScreen extends StatefulWidget {
  const SupervisorHomeScreen({super.key});

  @override
  State<SupervisorHomeScreen> createState() => _SupervisorHomeScreenState();
}

class _SupervisorHomeScreenState extends State<SupervisorHomeScreen> {
  int? _activeTripId;
  String _supervisorName = '';
  String _busNumber = '—';
  int _assigned = 0;
  int _boarded = 0;
  int _notYet = 0;

  bool _loading = true;
  bool _endingTrip = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final me = await ServiceLocator.supervisorService.getMe();
      if (!mounted) return;
      setState(() {
        _supervisorName = me.name;
        _busNumber = me.busNumber ?? '—';
        _activeTripId = me.activeTripId;
        _assigned = me.assignedCount;
        _boarded = me.boardedCount;
        _notYet = me.notYetCount;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _supervisorName = ServiceLocator.tokenStorage.getUserName() ?? 'Supervisor';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _goToTrip() async {
    Navigator.push(
      context,
      fadeRoute(SupervisorTripScreen(tripId: _activeTripId)),
    );
  }

  Future<void> _startTrip() async {
    try {
      final token = ServiceLocator.tokenStorage.getToken();
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/v1/Supervisor/start-current-trip',
      );
      final resp = await http.post(uri, headers: headers);
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        await _load();
        if (!mounted) return;
        await _goToTrip();
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Start trip failed (HTTP ${resp.statusCode})')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting trip: $e')),
      );
    }
  }

  Future<void> _endTrip() async {
    final tripId = _activeTripId;
    if (tripId == null || tripId <= 0) return;
    if (_endingTrip) return;
    setState(() => _endingTrip = true);
    try {
      final token = ServiceLocator.tokenStorage.getToken();
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      final uri = Uri.parse('${ApiConfig.baseUrl}/v1/Supervisor/end-trip?tripId=$tripId');
      final resp = await http.post(uri, headers: headers);
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        await _load();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trip ended')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('End trip failed (HTTP ${resp.statusCode})')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error ending trip: $e')),
      );
    } finally {
      if (mounted) setState(() => _endingTrip = false);
    }
  }

  bool get _canEndTrip =>
      _activeTripId != null && _activeTripId! > 0 && !_endingTrip;

  Widget _endTripDisabledBlur({
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
      backgroundColor: context.appScaffoldBackground,
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    child: Stack(
                      children: [
                        SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: 200),
                          child: Column(
                            children: [
                              Container(
                                width: double.infinity,
                                height: 200,
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  0,
                                  20,
                                  0,
                                ),
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryBlue97,
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(40),
                                    bottomRight: Radius.circular(40),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Image.asset(
                                          AppImages.logo,
                                          height: 126,
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error, stackTrace) =>
                                              const Icon(
                                                Icons.bus_alert,
                                                color: AppColors.white,
                                                size: 40,
                                              ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 0),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Welcome, ${_supervisorName.isEmpty ? 'Supervisor' : _supervisorName}',
                                            style: const TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 20,
                                              fontWeight: FontWeight.w600,
                                              height: 22 / 32,
                                              color: AppColors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Container(
                                          width: 52,
                                          height: 52,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: context.appAvatarPlaceholder,
                                          ),
                                          child: ClipOval(
                                            child: Image.asset(
                                              AppImages.supervisorAvatar,
                                              width: 52,
                                              height: 52,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) =>
                                                  const Icon(
                                                    Icons.person,
                                                    color: AppColors.white,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  10,
                                  30,
                                  10,
                                  0,
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      height: 188,
                                      decoration: BoxDecoration(
                                        color: context.appCardBackground,
                                        borderRadius: BorderRadius.circular(29),
                                      ),
                                      child: _StatusCardContent(
                                        busNumber: _busNumber,
                                        assigned: _assigned,
                                        boarded: _boarded,
                                        notYet: _notYet,
                                      ),
                                    ),
                                    const SizedBox(height: 28),
                                    SizedBox(
                                      width: 291,
                                      height: 62,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          gradient:
                                              AppColors.primaryButtonGradient,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: _loading
                                                ? null
                                                : (_activeTripId != null && _activeTripId! > 0)
                                                    ? _goToTrip
                                                    : _startTrip,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            child: Center(
                                              child: Text(
                                                (_activeTripId != null && _activeTripId! > 0)
                                                    ? 'Go To Trip'
                                                    : 'Start Trip',
                                                style: const TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.w600,
                                                  height: 22 / 24,
                                                  color: AppColors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: 291,
                                      height: 62,
                                      child: _endTripDisabledBlur(
                                        enabled: _canEndTrip,
                                        borderRadius: BorderRadius.circular(10),
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            gradient: AppColors.endTripGradient,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: _canEndTrip ? _endTrip : null,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: Center(
                                                child: _endingTrip
                                                    ? const SizedBox(
                                                        width: 24,
                                                        height: 24,
                                                        child:
                                                            CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Colors.white,
                                                        ),
                                                      )
                                                    : const Text(
                                                        'End Trip',
                                                        style: TextStyle(
                                                          fontFamily: 'Inter',
                                                          fontSize: 24,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          height: 22 / 24,
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
                            ],
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  height: 70,
                                  decoration: BoxDecoration(
                                    color: context.appPanelBackground,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildNavItem(
                                        context: context,
                                        iconPath: AppImages.navbarHomeActive,
                                        label: 'Home',
                                        isActive: true,
                                        onTap: () {},
                                      ),
                                      _buildNavItem(
                                        context: context,
                                        iconPath: AppImages.navbarAttendance,
                                        label: 'Attendance',
                                        isActive: false,
                                        onTap: _loading
                                            ? () {}
                                            : (_activeTripId != null &&
                                                    _activeTripId! > 0)
                                                ? _goToTrip
                                                : _startTrip,
                                      ),
                                      _buildNavItem(
                                        context: context,
                                        iconPath: AppImages.navbarProfile,
                                        label: 'Profile',
                                        isActive: false,
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            fadeRoute(
                                              const SupervisorProfileScreen(),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required String iconPath,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
                    label == 'Home' ? Icons.home : Icons.grid_view_rounded,
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

// Sub-widget for the Status Card inner elements
class _StatusCardContent extends StatelessWidget {
  const _StatusCardContent({
    required this.busNumber,
    required this.assigned,
    required this.boarded,
    required this.notYet,
  });

  final String busNumber;
  final int assigned;
  final int boarded;
  final int notYet;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Text(
              'Students Status',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: context.appPrimaryText,
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Text(
              'Bus #$busNumber',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: context.appPrimaryText,
              ),
            ),
          ),
          // Divider line
          Positioned(
            left: 0,
            right: 0,
            top: 38,
            child: Container(height: 1, color: context.appLine),
          ),
          // Statistics Row
          Positioned(
            left: 0,
            right: 0,
            top: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStat(context, '$assigned', 'Assigned'),
                _buildVerticalDivider(),
                _buildStat(context, '$boarded', 'Boarded'),
                _buildVerticalDivider(),
                _buildStat(context, '$notYet', 'Not Yet'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: context.appPrimaryText,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: context.appPrimaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Builder(
      builder: (context) =>
          Container(width: 1, height: 96, color: context.appLine),
    );
  }
}
