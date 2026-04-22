import 'dart:io';
import 'dart:convert';
import 'dart:ui';
import 'package:application/constants/app_colors.dart';
import 'package:application/constants/app_images.dart';
import 'package:application/helpers/app_theme.dart';
import 'package:application/helpers/fade_route.dart';
import 'package:application/screens/supervisor/supervisor_home_screen.dart';
import 'package:application/screens/supervisor/supervisor_profile_screen.dart';
import 'package:application/screens/supervisor/supervisor_qr_confirmation_screen.dart';
import 'package:application/services/service_locator.dart';
import 'package:application/utils/api_config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SupervisorAttendanceScreen extends StatefulWidget {
  final String imagePath;
  final int? tripId;
  final int studentId;
  final String studentName;
  final String studentGrade;
  final String studentBirthdate;
  final String busNumber;
  final int faceAttemptId;
  final double matchConfidence;

  /// When false (face did not match), show [noMatchMessage] instead of a student name and block Confirm.
  final bool allowConfirmAttendance;

  /// Shown under the title when [allowConfirmAttendance] is false; falls back to "N/A".
  final String? noMatchMessage;

  const SupervisorAttendanceScreen({
    super.key,
    required this.imagePath,
    required this.tripId,
    required this.studentId,
    required this.studentName,
    required this.studentGrade,
    required this.studentBirthdate,
    required this.busNumber,
    required this.faceAttemptId,
    required this.matchConfidence,
    this.allowConfirmAttendance = true,
    this.noMatchMessage,
  });

  @override
  State<SupervisorAttendanceScreen> createState() =>
      _SupervisorAttendanceScreenState();
}

class _SupervisorAttendanceScreenState
    extends State<SupervisorAttendanceScreen> {
  late String currentImagePath;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    currentImagePath = widget.imagePath;
  }

  // Rescan Function
  Future<void> _rescan() async {
    if (!mounted) return;
    Navigator.pop(context, false);
  }

  /// One line for the glass card: API message when meaningful, otherwise "N/A"
  /// (avoids stacking "N/A" + "This student is not in this bus" and overflow).
  String _noMatchDisplayText() {
    final m = widget.noMatchMessage?.trim() ?? '';
    if (m.isEmpty || m.toUpperCase() == 'N/A') {
      return 'N/A';
    }
    return m;
  }

  Future<void> _confirmAttendance() async {
    if (!widget.allowConfirmAttendance ||
        widget.studentId <= 0 ||
        widget.faceAttemptId <= 0) {
      return;
    }
    final tripId = widget.tripId;
    if (tripId == null || tripId <= 0) return;
    setState(() => _isSubmitting = true);
    try {
      final token = ServiceLocator.tokenStorage.getToken();
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      final uri = Uri.parse('${ApiConfig.baseUrl}/v1/Supervisor/attendance/face-confirm');
      final fakePhotoUrl = 'captured://${DateTime.now().millisecondsSinceEpoch}.jpg';
      final body = jsonEncode({
        'attemptId': widget.faceAttemptId,
        'tripId': tripId,
        'studentId': widget.studentId,
        'scanType': 'IN',
        'supervisorConfirmed': true,
        'scanImageUrl': fakePhotoUrl,
      });

      final resp = await http.post(uri, headers: headers, body: body);
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Attendance failed: HTTP ${resp.statusCode}')),
        );
        return;
      }
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final summary = (data['summary'] as Map<String, dynamic>? ?? {});
      if (!mounted) return;
      final done = await Navigator.push<bool>(
        context,
        fadeRoute(
          SupervisorQrConfirmationScreen(
            imagePath: currentImagePath,
            studentName: widget.studentName,
            studentGrade: widget.studentGrade,
            studentBirthdate: widget.studentBirthdate,
            busNumber: widget.busNumber,
            boarded: (summary['boarded'] as num?)?.toInt() ?? 0,
            remaining: (summary['remaining'] as num?)?.toInt() ?? 0,
            tripId: tripId,
            studentId: widget.studentId,
          ),
        ),
      );
      if (done == true && mounted) {
        Navigator.pop(context, true);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
                // Header (Figma Position x:-16 y:-14)
                Container(
                  width: double.infinity,
                  height: 235,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryBlue97,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.chevron_left,
                                color: Colors.white,
                                size: 38,
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
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.white,
                              backgroundImage: const AssetImage(
                                AppImages.supervisorAvatar,
                              ),
                              onBackgroundImageError: (_, __) {},
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              'Welcome, Ali',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Bus #${widget.busNumber}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Scanned Image + Glass Card
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: Image.file(
                            File(currentImagePath),
                            width: 366,
                            height: 355,
                            fit: BoxFit.cover,
                          ),
                        ),
                        // Glass Card (README: 355x154, radius 30, ffffff 37%, blur 30, shadow)
                        Positioned(
                          bottom: 20,
                          left: 15,
                          right: 15,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                              child: Container(
                                height: 154,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.37),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.25),
                                      offset: const Offset(0, 4),
                                      blurRadius: 4,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        if (widget.allowConfirmAttendance)
                                          Image.asset(
                                            AppImages.image14,
                                            width: 54,
                                            height: 24,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(
                                                  Icons.check_circle,
                                                  color: Color(0xFF16A34A),
                                                  size: 28,
                                                ),
                                          )
                                        else
                                          const Icon(
                                            Icons.cancel_outlined,
                                            color: Color(0xFFDC2626),
                                            size: 28,
                                          ),
                                        const SizedBox(width: 8),
                                        Text(
                                          widget.allowConfirmAttendance
                                              ? 'Attendance Recorded'
                                              : 'No match',
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF333333),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (widget.allowConfirmAttendance)
                                      Text(
                                        widget.studentName,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 20,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black,
                                        ),
                                      )
                                    else
                                      Builder(
                                        builder: (context) {
                                          final detail = _noMatchDisplayText();
                                          return Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  detail,
                                                  textAlign: TextAlign.center,
                                                  maxLines: 4,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontFamily: 'Inter',
                                                    fontSize:
                                                        detail.length > 42 ? 13 : 15,
                                                    fontWeight: FontWeight.w600,
                                                    color: const Color(0xFF6B7280),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    if (widget.allowConfirmAttendance)
                                      const Spacer(),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 15,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          _buildRescanBtn(context),
                                          _buildConfirmBtn(context),
                                        ],
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

                // Bottom nav (README: Attendance active - 2859c5)
                Padding(
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
                          AppImages.navbarHome,
                          'Home',
                          false,
                          () => Navigator.pushReplacement(
                            context,
                            fadeRoute(const SupervisorHomeScreen()),
                          ),
                        ),
                        _navItem(
                          context,
                          AppImages.navbarAttendanceActive,
                          'Attendance',
                          true,
                          () {},
                        ),
                        _navItem(
                          context,
                          AppImages.navbarProfile,
                          'Profile',
                          false,
                          () => Navigator.push(
                            context,
                            fadeRoute(const SupervisorProfileScreen()),
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

  Widget _buildRescanBtn(BuildContext context) {
    return GestureDetector(
      onTap: _rescan,
      child: Container(
        width: 148,
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.e6e9ed.withOpacity(0.94),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: AppColors.primaryBlue, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Rescan',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.camera_alt_outlined,
              size: 28,
              color: AppColors.primaryBlue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmBtn(BuildContext context) {
    final canConfirm = widget.allowConfirmAttendance &&
        widget.studentId > 0 &&
        widget.faceAttemptId > 0;
    final showPrimaryStyle = canConfirm;
    final tappable = canConfirm && !_isSubmitting;
    return SizedBox(
      width: 148,
      height: 46,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: showPrimaryStyle ? AppColors.primaryButtonGradient : null,
          color: showPrimaryStyle ? null : const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color:
                showPrimaryStyle ? Colors.transparent : const Color(0xFFD1D5DB),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: tappable ? _confirmAttendance : null,
            borderRadius: BorderRadius.circular(7),
            child: Center(
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Confirm',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: showPrimaryStyle
                            ? Colors.white
                            : const Color(0xFF9CA3AF),
                      ),
                    ),
            ),
          ),
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
                  errorBuilder: (_, __, ___) => Icon(
                    label == 'Home' ? Icons.home : Icons.fact_check,
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
