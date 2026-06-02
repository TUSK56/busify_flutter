import 'dart:convert';
import 'dart:io';

import 'package:application/constants/app_colors.dart';
import 'package:application/constants/app_images.dart';
import 'package:application/helpers/app_theme.dart';
import 'package:application/helpers/app_back_button.dart';
import 'package:application/helpers/app_feedback.dart';
import 'package:application/helpers/supervisor_photo.dart';
import 'package:application/routes/fade_route.dart';
import 'package:application/screens/parent/parent_home_screen.dart';
import 'package:application/screens/parent/parent_profile_screen.dart';
import 'package:application/screens/parent/parent_track_bus_screen.dart';
import 'package:application/services/service_locator.dart';
import 'package:application/widgets/parent/parent_bottom_nav_bar.dart';
import 'package:application/widgets/parent/parent_face_enrollment.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

class ParentAddChildScreen extends StatefulWidget {
  const ParentAddChildScreen({
    super.key,
    this.readOnly = false,
    this.details,
    this.resubmitStudentId,
  });

  final bool readOnly;
  final Map<String, dynamic>? details;
  /// When set, updates a rejected student back to pending instead of creating a new row.
  final int? resubmitStudentId;

  @override
  State<ParentAddChildScreen> createState() => _ParentAddChildScreenState();
}

class _ParentAddChildScreenState extends State<ParentAddChildScreen> {
  final _nameController = TextEditingController();

  bool _saving = false;

  List<Map<String, dynamic>> _schools = const [];
  int? _selectedSchoolId;

  final _grades = const ['Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5'];
  String? _selectedGrade;

  DateTime? _dob;

  File? _studentPhotoFile;
  XFile? _facePhoto;
  bool _faceVerified = false;
  bool _faceChecking = false;
  String? _faceStatusMessage;
  String? _faceRejectReason;
  final ParentFaceEnrollmentSession _faceEnrollment = ParentFaceEnrollmentSession();
  String? _embeddingJson;

  bool get _canAdd =>
      !widget.readOnly &&
      _faceVerified &&
      !_faceChecking &&
      !_saving &&
      _facePhoto != null &&
      _faceEnrollment.isComplete;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (widget.readOnly) {
      final details = widget.details ?? const <String, dynamic>{};
      final name = (details['name'] ?? details['Name'])?.toString() ?? '';
      final grade = (details['grade'] ?? details['Grade'])?.toString();
      final dobRaw = (details['birthdate'] ?? details['Birthdate'])?.toString();
      final reason = (details['linkRejectReason'] ??
              details['link_reject_reason'] ??
              details['LinkRejectReason'])
          ?.toString();
      final photo = (details['photoUrl'] ?? details['photo_url'])?.toString();
      DateTime? parsedDob;
      if (dobRaw != null && dobRaw.isNotEmpty) {
        parsedDob = DateTime.tryParse(dobRaw);
      }
      if (!mounted) return;
      setState(() {
        _nameController.text = name;
        _selectedGrade = grade ?? _grades.first;
        _dob = parsedDob;
        _faceRejectReason = (reason == null || reason.trim().isEmpty)
            ? 'Rejected by school'
            : reason.trim();
        if (photo != null && photo.trim().isNotEmpty) {
          _faceStatusMessage = supervisorPhotoFullUrl(photo.trim()) ?? photo.trim();
        }
      });
      return;
    }

    try {
      final profile = await ServiceLocator.parentService.getProfile();
      final sid = (profile['schoolAdminId'] as num?)?.toInt();
      final schools = await ServiceLocator.parentService.getSchools();
      int? firstSchoolId;
      if (schools.isNotEmpty) {
        final first = schools.first;
        final rawId = first['id'] ?? first['Id'];
        if (rawId is num) {
          firstSchoolId = rawId.toInt();
        } else if (rawId is String) {
          firstSchoolId = int.tryParse(rawId.trim());
        }
      }
      if (!mounted) return;
      setState(() {
        _schools = schools;
        _selectedSchoolId = sid ?? firstSchoolId;
        _selectedGrade ??= _grades.first;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _selectedGrade ??= _grades.first;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _formatDob() {
    final d = _dob;
    if (d == null) return 'DD/MM/YYYY';
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return '$dd/$mm/$yyyy';
  }

  String _dobForApi() {
    final d = _dob!;
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return '$yyyy-$mm-$dd';
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 8, now.month, now.day),
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (!mounted) return;
    if (picked == null) return;
    setState(() => _dob = picked);
  }

  Future<void> _pickFacePhoto() async {
    if (_faceEnrollment.isComplete) {
      _faceEnrollment.reset();
      setState(() {
        _facePhoto = null;
        _studentPhotoFile = null;
        _faceVerified = false;
        _faceStatusMessage = 'Starting enrollment scans again…';
        _faceRejectReason = null;
        _embeddingJson = null;
      });
    }
    setState(() {
      _faceChecking = true;
      _faceStatusMessage = _faceEnrollment.scansCompleted == 0
          ? 'Opening camera for scan 1 of ${kParentEnrollmentScanCount}…'
          : 'Opening camera for scan ${_faceEnrollment.scansCompleted + 1} of ${kParentEnrollmentScanCount}…';
      _faceRejectReason = null;
    });
    final result = await _faceEnrollment.captureNextScan();
    if (!mounted) return;
    final photo = _faceEnrollment.lastPhoto;
    setState(() {
      _faceChecking = false;
      _faceVerified = result.enrollmentComplete;
      _faceStatusMessage = result.statusMessage;
      _faceRejectReason = result.verified ? null : result.rejectReason;
      if (photo != null) {
        _facePhoto = photo;
        _studentPhotoFile = File(photo.path);
      }
      if (result.enrollmentComplete) {
        _embeddingJson = _faceEnrollment.averagedEmbeddingJson();
      }
    });
  }

  Color _faceBorderColor() {
    return parentFaceBorderColor(
      hasPhoto: _studentPhotoFile != null,
      verified: _faceVerified,
      rejected: _faceRejectReason != null,
      defaultColor: AppColors.white.withValues(alpha: 0.79),
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    final name = _nameController.text.trim();
    final grade = _selectedGrade ?? '';
    final dob = _dob;

    if (name.isEmpty || grade.isEmpty || dob == null || _selectedSchoolId == null) {
      await showAppFeedback(context, 'Please fill all fields', isError: true);
      return;
    }
    if (_studentPhotoFile == null || _facePhoto == null) {
      await showAppFeedback(
        context,
        'Please add a student face photo.',
        isError: true,
      );
      return;
    }
    if (!_faceVerified) {
      await showAppFeedback(
        context,
        _faceStatusMessage ??
            'Please wait for face verification or retake the photo.',
        isError: true,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final parentId = ServiceLocator.tokenStorage.getUserId();

      if (parentId == null || parentId <= 0) {
        throw Exception('Could not detect parent account');
      }

      String? photoB64;
      if (_studentPhotoFile != null && await _studentPhotoFile!.exists()) {
        final bytes = await _studentPhotoFile!.readAsBytes();
        if (bytes.isNotEmpty) {
          photoB64 = base64Encode(bytes);
        }
      }

      final resubmitId = widget.resubmitStudentId;
      if (resubmitId != null && resubmitId > 0) {
        await ServiceLocator.parentService.resubmitChild(
          studentId: resubmitId,
          name: name,
          birthdate: _dobForApi(),
          grade: grade,
          parentId: parentId,
          schoolId: _selectedSchoolId!,
          photoBase64: photoB64,
          embeddingJson: _embeddingJson,
        );
      } else {
        await ServiceLocator.parentService.addChild(
          name: name,
          birthdate: _dobForApi(),
          grade: grade,
          parentId: parentId,
          schoolId: _selectedSchoolId!,
          photoBase64: photoB64,
          embeddingJson: _embeddingJson,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      await showAppFeedback(context, 'Failed to add child: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final titleColor = context.isDarkMode ? context.appPrimaryText : AppColors.textBlack;

    return Scaffold(
      backgroundColor: context.appScaffoldBackground,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _TopHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(bottom: 8 + bottomInset),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        widget.readOnly
                            ? 'Rejected — Child Details'
                            : (widget.resubmitStudentId != null
                                ? 'Resubmit Child'
                                : 'Add Child'),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          height: 1.15,
                          color: titleColor,
                          shadows: [
                            Shadow(
                              offset: const Offset(0, 4),
                              blurRadius: 4,
                              color: AppColors.textBlack.withValues(alpha: 0.25),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: 364,
                      decoration: BoxDecoration(
                        color: AppColors.profileCardBackground,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.fromLTRB(19, 18, 19, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _IconLabel(
                            iconPath: AppImages.studentIcon,
                            iconSize: const Size(42, 43),
                            label: "Student's Full Name",
                          ),
                          const SizedBox(height: 10),
                          _InputBox(
                            child: TextField(
                              controller: _nameController,
                              readOnly: widget.readOnly,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                height: 22 / 16,
                                color: context.appPrimaryText,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Enter Name',
                                hintStyle: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  height: 22 / 16,
                                  color: AppColors.grayText.withValues(alpha: 0.68),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          _IconLabel(
                            iconPath: AppImages.schoolIcon,
                            iconSize: const Size(35, 35),
                            label: 'School',
                          ),
                          const SizedBox(height: 10),
                          _DropdownBox<int>(
                            value: _selectedSchoolId,
                            hint: 'Select School',
                            items: _schools
                                .map(
                                  (s) => DropdownMenuItem<int>(
                                    value: (s['id'] as num?)?.toInt(),
                                    child: Text(
                                      (s['name'] ?? 'School').toString(),
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        height: 22 / 16,
                                        color: context.appPrimaryText,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: widget.readOnly
                                ? (_) {}
                                : (v) => setState(() => _selectedSchoolId = v),
                            enabled: !widget.readOnly,
                          ),
                          const SizedBox(height: 18),
                          _IconLabel(
                            iconPath: AppImages.gradeIcon,
                            iconSize: const Size(36, 36),
                            label: 'Grade',
                          ),
                          const SizedBox(height: 10),
                          _DropdownBox<String>(
                            value: _selectedGrade,
                            hint: 'Select Grade',
                            items: _grades
                                .map(
                                  (g) => DropdownMenuItem<String>(
                                    value: g,
                                    child: Text(
                                      g,
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        height: 22 / 16,
                                        color: context.appPrimaryText,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: widget.readOnly
                                ? (_) {}
                                : (v) => setState(() => _selectedGrade = v),
                            enabled: !widget.readOnly,
                          ),
                          const SizedBox(height: 18),
                          _IconLabel(
                            iconPath: AppImages.blueCalendar,
                            iconSize: const Size(32, 30),
                            label: 'Date of Birth',
                          ),
                          const SizedBox(height: 10),
                          _InputBox(
                            onTap: widget.readOnly ? null : _pickDob,
                            child: Row(
                              children: [
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    _formatDob(),
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      height: 22 / 16,
                                      color: _dob == null
                                          ? AppColors.grayText.withValues(alpha: 0.68)
                                          : context.appPrimaryText,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: widget.readOnly ? null : _pickDob,
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 16),
                                    child: Icon(
                                      FluentIcons.calendar_20_filled,
                                      size: 25,
                                      color: AppColors.grayText.withValues(alpha: 0.72),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          _IconLabel(
                            iconPath: AppImages.studentIcon,
                            iconSize: const Size(40, 40),
                            label: 'Student Face Photo',
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: widget.readOnly || _faceChecking || _saving
                                ? null
                                : _pickFacePhoto,
                            child: Container(
                              width: double.infinity,
                              height: 140,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.white.withValues(alpha: 0.21),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: _faceBorderColor(),
                                  width: _faceVerified || _faceRejectReason != null ? 2 : 1,
                                ),
                              ),
                              child: widget.readOnly
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: _faceStatusMessage != null
                                          ? Image.network(
                                              _faceStatusMessage!,
                                              width: double.infinity,
                                              height: 140,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => Image.asset(
                                                AppImages.studentIcon,
                                                width: double.infinity,
                                                height: 140,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : Image.asset(
                                              AppImages.studentIcon,
                                              width: double.infinity,
                                              height: 140,
                                              fit: BoxFit.cover,
                                            ),
                                    )
                                  : _studentPhotoFile == null
                                      ? Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.face_outlined,
                                              size: 40,
                                              color: AppColors.grayText.withValues(alpha: 0.72),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              _faceEnrollment.scansCompleted == 0
                                                  ? 'Tap to start scan 1 of $kParentEnrollmentScanCount'
                                                  : 'Tap for scan ${_faceEnrollment.scansCompleted + 1} of $kParentEnrollmentScanCount',
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: AppColors.grayText.withValues(alpha: 0.68),
                                              ),
                                            ),
                                          ],
                                        )
                                      : ClipRRect(
                                          borderRadius: BorderRadius.circular(14),
                                          child: Image.file(
                                            _studentPhotoFile!,
                                            width: double.infinity,
                                            height: 140,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                            ),
                          ),
                          if (widget.readOnly) ...[
                            const SizedBox(height: 18),
                            _ReadOnlyDescriptionLabel(),
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.white.withValues(alpha: 0.58),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.textBlack.withValues(alpha: 0.20),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                (_faceRejectReason == null || _faceRejectReason!.trim().isEmpty)
                                    ? 'Rejected by school'
                                    : _faceRejectReason!,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: context.appPrimaryText,
                                ),
                              ),
                            ),
                          ],
                          if (!widget.readOnly && _studentPhotoFile != null) ...[
                            const SizedBox(height: 8),
                            ParentFaceStatusRow(
                              checking: _faceChecking,
                              verified: _faceVerified,
                              statusMessage: _faceStatusMessage,
                              messageStyle: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primaryBlue,
                              ),
                              loadingColor: AppColors.primaryBlue,
                            ),
                            if (_faceRejectReason != null) ...[
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: _faceChecking || _saving ? null : _pickFacePhoto,
                                child: Text(
                                  'Retake photo',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: parentSubmitDisabledBlur(
                          enabled: widget.readOnly ? true : _canAdd,
                          borderRadius: BorderRadius.circular(33),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryButtonGradient,
                              borderRadius: BorderRadius.circular(33),
                              boxShadow: [
                                BoxShadow(
                                  offset: const Offset(0, 4),
                                  blurRadius: 4,
                                  color: AppColors.textBlack.withValues(alpha: 0.25),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: widget.readOnly
                                    ? () {
                                        final details = widget.details ?? {};
                                        final sid = details['id'] ?? details['Id'];
                                        final studentId = sid is num
                                            ? sid.toInt()
                                            : int.tryParse('$sid');
                                        Navigator.of(context).pushReplacement(
                                          fadeRoute(
                                            ParentAddChildScreen(
                                              resubmitStudentId: studentId,
                                            ),
                                          ),
                                        );
                                      }
                                    : (!_canAdd ? null : _save),
                                borderRadius: BorderRadius.circular(33),
                                child: Center(
                                  child: _saving
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.white,
                                          ),
                                        )
                                      : Text(
                                          widget.readOnly
                                              ? 'Try again'
                                              : (widget.resubmitStudentId != null
                                                  ? 'Resubmit'
                                                  : 'Add'),
                                          style: GoogleFonts.inter(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w700,
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
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            ParentBottomNavBar(
              activeTab: ParentNavTab.profile,
              onHomeTap: () {
                Navigator.of(context).pushAndRemoveUntil(
                  fadeRoute(const ParentHomeScreen()),
                  (route) => false,
                );
              },
              onTrackBusTap: () {
                Navigator.of(context).pushAndRemoveUntil(
                  fadeRoute(const ParentTrackBusScreen()),
                  (route) => false,
                );
              },
              onProfileTap: () {
                Navigator.of(context).pushAndRemoveUntil(
                  fadeRoute(const ParentProfileScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(22),
        bottomRight: Radius.circular(22),
      ),
      child: SizedBox(
        height: 105,
        width: double.infinity,
        child: Stack(
          children: [
            const Positioned.fill(child: ColoredBox(color: AppColors.primaryBlue97)),
            Positioned(
              left: 24,
              top: 44,
              child: AppBackButton(
                onTap: () => Navigator.of(context).maybePop(),
                color: AppColors.white,
                icon: Icons.chevron_left,
                iconSize: 35,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 8,
              child: Center(
                child: Image.asset(
                  AppImages.logo,
                  width: 126,
                  height: 126,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconLabel extends StatelessWidget {
  const _IconLabel({
    required this.iconPath,
    required this.iconSize,
    required this.label,
  });

  final String iconPath;
  final Size iconSize;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: iconSize.width,
          height: iconSize.height,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(50),
          ),
          alignment: Alignment.center,
          child: Image.asset(
            iconPath,
            width: iconSize.width * 0.7,
            height: iconSize.height * 0.7,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 23),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              height: 22 / 20,
              color: AppColors.primaryBlue,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReadOnlyDescriptionLabel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(50),
          ),
          alignment: Alignment.center,
          child: const Icon(
            FluentIcons.document_text_20_filled,
            size: 22,
            color: AppColors.primaryBlue,
          ),
        ),
        const SizedBox(width: 23),
        Expanded(
          child: Text(
            'Description',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              height: 22 / 20,
              color: AppColors.primaryBlue,
            ),
          ),
        ),
      ],
    );
  }
}

class _InputBox extends StatelessWidget {
  const _InputBox({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 322,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.58),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.textBlack.withValues(alpha: 0.25), width: 1),
        ),
        child: child,
      ),
    );
  }
}

class _DropdownBox<T> extends StatelessWidget {
  const _DropdownBox({
    required this.value,
    required this.items,
    required this.onChanged,
    required this.hint,
    this.enabled = true,
  });

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String hint;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 322,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.textBlack.withValues(alpha: 0.25), width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: enabled ? onChanged : null,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 30,
            color: AppColors.grayText.withValues(alpha: 0.72),
          ),
          hint: Text(
            hint,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 22 / 16,
              color: AppColors.grayText.withValues(alpha: 0.68),
            ),
          ),
        ),
      ),
    );
  }
}