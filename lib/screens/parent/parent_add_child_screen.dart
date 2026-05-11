import 'dart:convert';
import 'dart:io';

import 'package:application/constants/app_colors.dart';
import 'package:application/constants/app_images.dart';
import 'package:application/helpers/app_theme.dart';
import 'package:application/routes/fade_route.dart';
import 'package:application/screens/parent/parent_home_screen.dart';
import 'package:application/screens/parent/parent_profile_screen.dart';
import 'package:application/screens/parent/parent_track_bus_screen.dart';
import 'package:application/services/service_locator.dart';
import 'package:application/widgets/parent/parent_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

class ParentAddChildScreen extends StatefulWidget {
  const ParentAddChildScreen({super.key});

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

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.map((k, v) => MapEntry(k.toString(), v));
    return null;
  }

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final profile = await ServiceLocator.parentService.getProfile();
      final sid = (profile['schoolAdminId'] as num?)?.toInt();
      final schools = await ServiceLocator.parentService.getSchools();
      if (!mounted) return;
      setState(() {
        _schools = schools;
        _selectedSchoolId = sid ?? (schools.isNotEmpty ? (schools.first['id'] as num?)?.toInt() : null);
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

  Future<void> _pickStudentPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: source,
      imageQuality: 88,
      maxWidth: 1280,
    );
    if (x == null || !mounted) return;
    setState(() => _studentPhotoFile = File(x.path));
  }

  Future<void> _save() async {
    if (_saving) return;
    final name = _nameController.text.trim();
    final grade = _selectedGrade ?? '';
    final dob = _dob;

    if (name.isEmpty || grade.isEmpty || dob == null || _selectedSchoolId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }
    if (_studentPhotoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a student face photo.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final overview = await ServiceLocator.parentService.getChildOverview();
      final parent = _asMap(overview['parent'] ?? overview['Parent']) ?? {};
      final parentId =
          (parent['id'] ?? parent['Id']) as int? ?? ServiceLocator.tokenStorage.getUserId();

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

      await ServiceLocator.parentService.addChild(
        name: name,
        birthdate: _dobForApi(),
        grade: grade,
        parentId: parentId,
        photoBase64: photoB64,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add child: $e')),
      );
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
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(bottom: 8 + bottomInset),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const _TopHeader(),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Add Child',
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
                            onChanged: (v) => setState(() => _selectedSchoolId = v),
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
                            onChanged: (v) => setState(() => _selectedGrade = v),
                          ),
                          const SizedBox(height: 18),
                          _IconLabel(
                            iconPath: AppImages.blueCalendar,
                            iconSize: const Size(32, 30),
                            label: 'Date of Birth',
                          ),
                          const SizedBox(height: 10),
                          _InputBox(
                            onTap: _pickDob,
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
                                  onTap: _pickDob,
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
                            onTap: _pickStudentPhoto,
                            child: Container(
                              width: double.infinity,
                              height: 140,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.white.withValues(alpha: 0.21),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: AppColors.white.withValues(alpha: 0.79),
                                  width: 1,
                                ),
                              ),
                              child: _studentPhotoFile == null
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
                                          'Tap to add a clear face photo',
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: SizedBox(
                        width: double.infinity,
                        height: 46,
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
                              onTap: _saving ? null : _save,
                              borderRadius: BorderRadius.circular(33),
                              child: Center(
                                child: Text(
                                  _saving ? 'Adding...' : 'Add',
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
              top: 35,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.of(context).maybePop(),
                  borderRadius: BorderRadius.circular(20),
                  child: const SizedBox(
                    width: 45,
                    height: 45,
                    child: Icon(
                      Icons.chevron_left,
                      color: AppColors.white,
                      size: 35,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: -7,
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
  });

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String hint;

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
          onChanged: onChanged,
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