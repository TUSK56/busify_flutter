import 'dart:convert';

import 'package:application/constants/app_colors.dart';
import 'package:application/constants/app_images.dart';
import 'package:application/helpers/app_theme.dart';
import 'package:application/helpers/fade_route.dart';
import 'package:application/screens/supervisor/supervisor_profile_screen.dart';
import 'package:application/screens/supervisor/supervisor_trip_screen.dart';
import 'package:application/utils/api_config.dart';
import 'package:application/services/service_locator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class SupervisorHomeScreen extends StatelessWidget {
  const SupervisorHomeScreen({super.key});

  static const int _fallbackBusId = 1;

  Map<String, String> _buildHeaders() {
    final token = ServiceLocator.tokenStorage.getToken();
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  String _todayDateOnly() {
    final today = DateTime.now();
    return '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
  }

  String _extractErrorMessage(http.Response resp) {
    if (resp.body.isEmpty) return 'HTTP ${resp.statusCode}';
    try {
      final decoded = jsonDecode(resp.body);
      if (decoded is Map<String, dynamic>) {
        final msg = decoded['message'];
        if (msg is String && msg.isNotEmpty) return msg;

        final title = decoded['title'];
        if (title is String && title.isNotEmpty) return title;

        final errors = decoded['errors'];
        if (errors is Map<String, dynamic> && errors.isNotEmpty) {
          final firstEntry = errors.entries.first;
          final first = firstEntry.value;
          if (first is List && first.isNotEmpty && first.first is String) {
            return '${firstEntry.key}: ${first.first as String}';
          }
        }
      }
    } catch (_) {}
    return 'HTTP ${resp.statusCode}: ${resp.body}';
  }

  int? _tryExtractTripId(http.Response resp) {
    if (resp.body.isEmpty) return null;
    try {
      final decoded = jsonDecode(resp.body);
      if (decoded is Map<String, dynamic>) {
        final id = decoded['id'] ?? decoded['Id'] ?? decoded['tripId'];
        if (id is int) return id;
        if (id is num) return id.toInt();
        final trip = decoded['trip'];
        if (trip is Map<String, dynamic>) {
          final tid = trip['id'] ?? trip['Id'];
          if (tid is int) return tid;
          if (tid is num) return tid.toInt();
        }
      }
    } catch (_) {}
    return null;
  }

  Future<_TripStartResult> _startTripResilient() async {
    final headers = _buildHeaders();

    final currentTripUri = Uri.parse(
      '${ApiConfig.baseUrl}/v1/Supervisor/start-current-trip',
    );
    final currentTripResp = await http.post(currentTripUri, headers: headers);
    if (currentTripResp.statusCode == 200 ||
        currentTripResp.statusCode == 201) {
      return _TripStartResult(
        success: true,
        tripId: _tryExtractTripId(currentTripResp),
      );
    }

    final startTripUri = Uri.parse(
      '${ApiConfig.baseUrl}/v1/Supervisor/start-trip',
    );
    final modernBody = jsonEncode({
      'busId': _fallbackBusId,
      'tripType': 'Morning',
      'date': _todayDateOnly(),
    });

    final modernResp = await http.post(
      startTripUri,
      headers: headers,
      body: modernBody,
    );
    if (modernResp.statusCode == 200 || modernResp.statusCode == 201) {
      return _TripStartResult(
        success: true,
        tripId: _tryExtractTripId(modernResp),
      );
    }

    // Legacy backend compatibility:
    // Some builds expect the payload wrapped inside "req" and enum values as numeric.
    final wrappedLegacyBody = jsonEncode({
      'req': {'busId': _fallbackBusId, 'tripType': 0, 'date': _todayDateOnly()},
    });
    final wrappedLegacyResp = await http.post(
      startTripUri,
      headers: headers,
      body: wrappedLegacyBody,
    );
    if (wrappedLegacyResp.statusCode == 200 ||
        wrappedLegacyResp.statusCode == 201) {
      return _TripStartResult(
        success: true,
        tripId: _tryExtractTripId(wrappedLegacyResp),
      );
    }

    // Last fallback: unwrapped legacy with numeric enum.
    final legacyBody = jsonEncode({
      'busId': _fallbackBusId,
      'tripType': 0,
      'date': _todayDateOnly(),
    });
    final legacyResp = await http.post(
      startTripUri,
      headers: headers,
      body: legacyBody,
    );
    if (legacyResp.statusCode == 200 || legacyResp.statusCode == 201) {
      return _TripStartResult(
        success: true,
        tripId: _tryExtractTripId(legacyResp),
      );
    }

    return _TripStartResult(
      success: false,
      message: _extractErrorMessage(legacyResp),
    );
  }

  Future<void> _handleStartTrip(BuildContext context) async {
    try {
      final result = await _startTripResilient();
      if (result.success && context.mounted) {
        Navigator.push(
          context,
          fadeRoute(SupervisorTripScreen(tripId: result.tripId)),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Start trip failed: ${result.message ?? 'Please try again.'}',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error starting trip: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    double effectiveWidth = size.width;
    if (effectiveWidth > 450) effectiveWidth = 450;

    return Scaffold(
      backgroundColor: context.appScaffoldBackground,
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: effectiveWidth,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    child: Stack(
                      children: [
                        SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: 112),
                          child: Column(
                            children: [
                              Container(
                                width: double.infinity,
                                height: 262,
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  18,
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
                                          height: 80,
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(
                                                Icons.bus_alert,
                                                color: AppColors.white,
                                                size: 40,
                                              ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 44),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        const Expanded(
                                          child: Text(
                                            'Welcome, Ali',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 32,
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
                                              errorBuilder: (_, __, ___) =>
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
                                  24,
                                  20,
                                  24,
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
                                      child: const _StatusCardContent(),
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
                                            onTap: () =>
                                                _handleStartTrip(context),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            child: const Center(
                                              child: Text(
                                                'Start Trip',
                                                style: TextStyle(
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
                                        onTap: () => _handleStartTrip(context),
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
                  errorBuilder: (_, __, ___) => Icon(
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
  const _StatusCardContent();

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
              'Bus #7',
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
                _buildStat(context, '25', 'Assigned'),
                _buildVerticalDivider(),
                _buildStat(context, '0', 'Boarded'),
                _buildVerticalDivider(),
                _buildStat(context, '25', 'Not Yet'),
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

class _TripStartResult {
  final bool success;
  final String? message;
  final int? tripId;

  const _TripStartResult({required this.success, this.message, this.tripId});
}
