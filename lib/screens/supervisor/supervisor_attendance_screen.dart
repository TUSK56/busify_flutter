import 'dart:io';
import 'dart:convert';
import 'dart:ui';
import 'package:application/constants/app_colors.dart';
import 'package:application/constants/app_images.dart';
import 'package:application/helpers/api_json.dart';
import 'package:application/helpers/app_theme.dart';
import 'package:application/helpers/app_feedback.dart';
import 'package:application/helpers/fade_route.dart';
import 'package:application/screens/supervisor/supervisor_home_screen.dart';
import 'package:application/screens/supervisor/supervisor_profile_screen.dart';
import 'package:application/screens/supervisor/supervisor_qr_confirmation_screen.dart';
import 'package:application/services/service_locator.dart';
import 'package:application/services/trip_live_updates.dart';
import 'package:application/utils/api_config.dart';
import 'package:application/widgets/supervisor/supervisor_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Row for manual attendance when face match fails repeatedly.
class SupervisorManualStudentOption {
  final int studentId;
  final String name;
  final String grade;
  final String birthdate;
  final String? photoUrl;

  const SupervisorManualStudentOption({
    required this.studentId,
    required this.name,
    required this.grade,
    required this.birthdate,
    this.photoUrl,
  });
}

class SupervisorAttendanceScreen extends StatefulWidget {
  final String imagePath;
  final int? tripId;
  final int studentId;
  final String studentName;
  final String studentGrade;
  final String studentBirthdate;
  final String? studentPhotoUrl;
  final String busNumber;
  final int faceAttemptId;
  final double matchConfidence;

  /// When false (face did not match), show [noMatchMessage] instead of a student name and block Confirm.
  final bool allowConfirmAttendance;

  /// Shown under the title when [allowConfirmAttendance] is false; falls back to "N/A".
  final String? noMatchMessage;

  /// After repeated failed matches, supervisor picks the student from [manualStudentOptions].
  final bool allowManualStudentPick;

  final List<SupervisorManualStudentOption> manualStudentOptions;

  const SupervisorAttendanceScreen({
    super.key,
    required this.imagePath,
    required this.tripId,
    required this.studentId,
    required this.studentName,
    required this.studentGrade,
    required this.studentBirthdate,
    this.studentPhotoUrl,
    required this.busNumber,
    required this.faceAttemptId,
    required this.matchConfidence,
    this.allowConfirmAttendance = true,
    this.noMatchMessage,
    this.allowManualStudentPick = false,
    this.manualStudentOptions = const [],
  });

  @override
  State<SupervisorAttendanceScreen> createState() =>
      _SupervisorAttendanceScreenState();
}

class _SupervisorAttendanceScreenState
    extends State<SupervisorAttendanceScreen> {
  /// Frosted card height when face matched / normal flow (logical px).
  static const double _glassCardHeightNormal = 154;
  /// Frosted card height when manual "Choose student" list is shown (logical px).
  static const double _glassCardHeightManual = 195;

  /// Max width of the styled "Choose student" field (logical px). Lower = narrower dropdown.
  static const double _manualStudentDropdownMaxWidth = 220;

  late String currentImagePath;
  bool _isSubmitting = false;
  bool _sendingSos = false;
  int? _manualStudentId;

  @override
  void initState() {
    super.initState();
    currentImagePath = widget.imagePath;
  }

  bool get _manualConfirmReady =>
      widget.allowManualStudentPick &&
      widget.faceAttemptId > 0 &&
      (_manualStudentId ?? 0) > 0;

  bool get _matchedConfirmReady =>
      widget.allowConfirmAttendance &&
      widget.studentId > 0 &&
      widget.faceAttemptId > 0;

  SupervisorManualStudentOption? _selectedManualOption() {
    final id = _manualStudentId;
    if (id == null) return null;
    for (final o in widget.manualStudentOptions) {
      if (o.studentId == id) return o;
    }
    return null;
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
    if (!_matchedConfirmReady && !_manualConfirmReady) {
      return;
    }
    final tripId = widget.tripId;
    if (tripId == null || tripId <= 0) return;

    final effectiveStudentId =
        _manualConfirmReady ? _manualStudentId! : widget.studentId;
    final picked = _selectedManualOption();

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
        'studentId': effectiveStudentId,
        'scanType': 'IN',
        'supervisorConfirmed': true,
        'scanImageUrl': fakePhotoUrl,
      });

      final resp = await http.post(uri, headers: headers, body: body);
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        if (!mounted) return;
        await showAppFeedback(
          context,
          'Attendance failed: HTTP ${resp.statusCode}',
          isError: true,
        );
        return;
      }
      final data = coerceJsonMap(jsonDecode(resp.body));
      if (data == null) {
        if (!mounted) return;
        await showAppFeedback(
          context,
          'Attendance failed: invalid response',
          isError: true,
        );
        return;
      }
      final summary =
          coerceJsonMap(data['summary']) ?? coerceJsonMap(data['Summary']) ?? <String, dynamic>{};
      final scannedRaw = data['scannedAtUtc'] ?? data['scanned_at_utc'];
      DateTime? scannedUtc = scannedRaw == null
          ? null
          : DateTime.tryParse(scannedRaw.toString());
      final scannedLocal = scannedUtc?.toLocal() ?? DateTime.now();
      String fmtAmPm(DateTime dt) {
        final h = dt.hour;
        final m = dt.minute.toString().padLeft(2, '0');
        final ampm = h >= 12 ? 'PM' : 'AM';
        final hh = ((h + 11) % 12) + 1;
        return '$hh:$m $ampm';
      }

      final startedRaw = data['tripStartedAtUtc'] ?? data['trip_started_at_utc'];
      final startedLocal = startedRaw == null
          ? null
          : DateTime.tryParse(startedRaw.toString())?.toLocal();
      String tripLabel() {
        if (startedLocal != null) {
          return startedLocal.hour < 12 ? 'Morning Trip' : 'Afternoon Trip';
        }
        final tt = (data['tripType'] ?? '').toString().toLowerCase();
        if (tt == 'morning') return 'Morning Trip';
        if (tt == 'afternoon') return 'Afternoon Trip';
        return 'Trip';
      }

      int summaryInt(dynamic v) {
        if (v is num) return v.toInt();
        return int.tryParse(v?.toString() ?? '') ?? 0;
      }

      TripLiveUpdates.instance.notify(
        'attendance_in',
        studentId: effectiveStudentId,
      );

      if (!mounted) return;
      final confirmName = picked?.name ?? widget.studentName;
      final confirmGrade = picked?.grade ?? widget.studentGrade;
      final confirmBirth = picked?.birthdate ?? widget.studentBirthdate;
      final confirmPhoto = picked?.photoUrl ?? widget.studentPhotoUrl;
      final done = await Navigator.push<bool>(
        context,
        fadeRoute(
          SupervisorQrConfirmationScreen(
            imagePath: currentImagePath,
            studentPhotoUrl: confirmPhoto,
            preferEnrolledPhoto: picked != null,
            studentName: confirmName,
            studentGrade: confirmGrade,
            studentBirthdate: confirmBirth,
            busNumber: widget.busNumber,
            boarded: summaryInt(summary['boarded']),
            remaining: summaryInt(summary['remaining']),
            tripId: tripId,
            studentId: effectiveStudentId,
            scanTimeLabel: fmtAmPm(scannedLocal),
            tripTypeLabel: tripLabel(),
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

  Future<void> _sendSos() async {
    if (_sendingSos) return;
    setState(() => _sendingSos = true);
    try {
      final sos = await ServiceLocator.supervisorService.sendSos();
      if (!mounted) return;
      var msg = 'SOS processed; trip ended.';
      if (sos.recipients <= 0) {
        msg =
            '$msg No push: only parents whose child has boarded (IN scan) this trip are notified.';
      } else if (sos.fcmAttempted <= 0) {
        msg = '$msg Parents have no registered devices — open parent app after login.';
      } else if (sos.fcmDelivered <= 0) {
        msg =
            '$msg Push did not reach devices (${sos.fcmFailed} failed). Check Firebase config and tokens.';
      } else {
        msg = '$msg Notified ${sos.fcmDelivered} device(s).';
      }
      await showAppFeedback(context, msg);
    } catch (e) {
      if (!mounted) return;
      await showAppFeedback(context, 'Failed to send SOS: $e', isError: true);
    } finally {
      if (mounted) setState(() => _sendingSos = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appScaffoldBackground,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Center(
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                // Header (Figma Position x:-16 y:-14)
                Container(
                  width: double.infinity,
                  height: 190,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryBlue97,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
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
                      ),
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
                      const SizedBox(height: 5),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 65),
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

                Expanded(
                  child: _buildScanWithCard(context),
                ),

                // Bottom nav (README: Attendance active - 2859c5)
                SupervisorBottomNavBar(
                  activeTab: SupervisorNavTab.attendance,
                  onHomeTap: () => Navigator.pushReplacement(
                    context,
                    fadeRoute(const SupervisorHomeScreen()),
                  ),
                  onAttendanceTap: () {},
                  onProfileTap: () => Navigator.push(
                    context,
                    fadeRoute(const SupervisorProfileScreen()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _glassCardDecoration() {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.37),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: Colors.white, width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          offset: const Offset(0, 4),
          blurRadius: 4,
          spreadRadius: 0,
        ),
      ],
    );
  }

  /// Bottom overlay on the scan preview. Card height: [_glassCardHeightNormal] or [_glassCardHeightManual].
  Widget _buildScanWithCard(BuildContext context) {
    final detail = _noMatchDisplayText();
    final manual = widget.allowManualStudentPick;
    final glassHeight =
        manual ? _glassCardHeightManual : _glassCardHeightNormal;

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: Image.file(
              File(currentImagePath),
              width: 366,
              height: 360,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            bottom: 15,
            left: 10,
            right: 10,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  height: glassHeight,
                  decoration: _glassCardDecoration(),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.allowConfirmAttendance)
                            Image.asset(
                              AppImages.image14,
                              width: 54,
                              height: 24,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.check_circle,
                                color: Color(0xFF16A34A),
                                size: 28,
                              ),
                            )
                          else
                            const Icon(
                              Icons.highlight_off,
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
                              color: Color(0xFF000000),
                            ),
                          ),
                        ],
                      ),
                      if (widget.allowConfirmAttendance) ...[
                        Text(
                          widget.studentName,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        const Spacer(),
                      ] else if (manual) ...[
                        const SizedBox(height: 6),
                        Text(
                          detail,
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: detail.length > 42 ? 12 : 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF000000),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: _manualStudentDropdownMaxWidth,
                            ),
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                canvasColor:
                                    Colors.white.withValues(alpha: 0.96),
                              ),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  isDense: true,
                                  filled: true,
                                  fillColor:
                                      Colors.white.withValues(alpha: 0.42),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: Colors.white.withValues(alpha: 0.85),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: Colors.white.withValues(alpha: 0.85),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: AppColors.primaryBlue,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    isExpanded: true,
                                    isDense: true,
                                    borderRadius: BorderRadius.circular(12),
                                    value: _manualStudentId,
                                    hint: Text(
                                      'Choose student',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black.withValues(alpha: 0.55),
                                      ),
                                    ),
                                    items: widget.manualStudentOptions
                                        .map(
                                          (o) => DropdownMenuItem(
                                            value: o.studentId,
                                            child: Text(
                                              '${o.name} (${o.grade})',
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                              style: const TextStyle(fontSize: 13),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) {
                                      setState(() => _manualStudentId = v);
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                      ] else ...[
                        Expanded(
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
                                  fontSize: detail.length > 42 ? 13 : 15,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF000000),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                      Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
    );
  }

  Widget _buildRescanBtn(BuildContext context) {
    return GestureDetector(
      onTap: _rescan,
      child: Container(
        width: 148,
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.e6e9ed.withValues(alpha: 0.94),
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
    final canConfirm = _matchedConfirmReady || _manualConfirmReady;
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

}
