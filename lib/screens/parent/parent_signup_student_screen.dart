import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:application/helpers/fade_route.dart';
import 'package:application/helpers/app_back_button.dart';
import 'package:application/helpers/app_feedback.dart';
import 'package:application/models/child.dart';
import 'package:application/models/parent_signup_data.dart';
import 'package:application/models/school.dart';
import 'package:application/screens/parent/parent_login_screen.dart';
import 'package:application/services/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:application/constants/app_colors.dart';
import 'package:application/constants/app_images.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

class ParentSignupStudentScreen extends StatefulWidget {
  final ParentSignupData parentData;

  const ParentSignupStudentScreen({super.key, required this.parentData});

  @override
  State<ParentSignupStudentScreen> createState() => _ParentSignupStudentScreenState();
}

class _ParentSignupStudentScreenState extends State<ParentSignupStudentScreen> {
  final List<String> _grades = ['Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5', 'Grade 6'];
  final _studentNameController = TextEditingController();
  final _birthdateController = TextEditingController();
  late final Future<List<School>> _schoolsFuture;

  School? _selectedSchool;
  String? _selectedGrade;
  DateTime? _selectedBirthdate;
  bool _isLoading = false;
  XFile? _facePhoto;

  @override
  void initState() {
    super.initState();
    _schoolsFuture = ServiceLocator.schoolService.getSchools();
  }

  @override
  void dispose() {
    _studentNameController.dispose();
    _birthdateController.dispose();
    super.dispose();
  }

  Future<void> _pickFacePhoto() async {
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
    setState(() => _facePhoto = x);
  }

  Future<bool> _validateFacePhoto(XFile photo) async {
    try {
      final bytes = await File(photo.path).readAsBytes();
      if (bytes.length < 20 * 1024) {
        if (!mounted) return false;
        await showAppFeedback(
          context,
          'Face photo is too small. Please retake clearly.',
          isError: true,
        );
        return false;
      }
      final codec = await instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final ratio = image.width / image.height;
      if (image.width < 240 || image.height < 240 || ratio < 0.6 || ratio > 1.8) {
        if (!mounted) return false;
        await showAppFeedback(
          context,
          'Use a clear front face photo (good lighting).',
          isError: true,
        );
        return false;
      }
      return true;
    } catch (_) {
      if (!mounted) return false;
      await showAppFeedback(
        context,
        'Could not process face photo. Please try another image.',
        isError: true,
      );
      return false;
    }
  }

  String _birthdateForApi(DateTime date) {
    final y = date.year.toString();
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _birthdateDisplay(DateTime? date) {
    if (date == null) return 'DD/MM/YYYY';
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return '$d/$m/$y';
  }

  Future<void> _pickBirthdate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthdate ?? DateTime(now.year - 8, now.month, now.day),
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (!mounted || picked == null) return;
    setState(() {
      _selectedBirthdate = picked;
      _birthdateController.text = _birthdateForApi(picked);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Screen dimensions for responsive layout
    final size = MediaQuery.of(context).size;
    final screenHeight = size.height;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppImages.background),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          bottom: false, // Let the bottom sheet extend to the very bottom
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: screenHeight * 0.01),

              // Top Logo (2.png)
              Image.asset(
                AppImages.logo,
                width: 126,
                height: 126,
                fit: BoxFit.contain,
              ),

              // Header Row: Back Button & Title
              Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // Back Button (Chevron Backward)
                  Padding(
                    padding: EdgeInsets.only(left: 24),
                    child: AppBackButton(
                      onTap: () => Navigator.pop(context),
                      color: Colors.white,
                      icon: Icons.arrow_back_ios,
                      iconSize: 28,
                    ),
                  ),

                  // Connect Student Title
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Connect Student',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600, // SemiBold 24
                        fontSize: 24,
                        color: AppColors.white, // ffffff 100%
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: screenHeight * 0.02),

              // Subtitle Text
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 43),
                child: Text(
                  'Please enter the student’s information to link the account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400, // Regular 16
                    fontSize: 16,
                    height: 1.3,
                    color: AppColors.white.withOpacity(0.72), // ffffff 72%
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.02),

              // Expanded Glassmorphism Bottom Sheet for inputs
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0), // Background blur
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.37), // ffffff 37%
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                        border: Border(
                          top: BorderSide(
                            color: Colors.white.withOpacity(0.30), // Approximating linear stroke
                            width: 1,
                          ),
                        ),
                      ),
                      // ScrollView prevents keyboard overflow
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(top: 10, bottom: 10),
                        child: Column(
                          children: [

                            // 1. Student's Full Name Text Field
                            _buildInputWrapper(
                              label: 'Student’s Full Name',
                              child: TextField(
                                controller: _studentNameController,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                  color: AppColors.primaryBlue, // Typed text matches dark blue
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  isCollapsed: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                                  hintText: 'Student name',
                                  hintStyle: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w500, // Medium 16
                                    fontSize: 16,
                                    color: AppColors.grayText.withOpacity(0.68), // 595959 68%
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // 2. Select School Dropdown (FutureBuilder from API)
                            _buildInputWrapper(
                              label: 'School Name',
                              child: FutureBuilder<List<School>>(
                                future: _schoolsFuture,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 16),
                                      child: SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    );
                                  }
                                  if (snapshot.hasError) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Text(
                                        'Failed to load schools: ${snapshot.error}',
                                        style: TextStyle(
                                          color: Colors.red.shade300,
                                          fontSize: 14,
                                        ),
                                      ),
                                    );
                                  }
                                  final schools = snapshot.data ?? [];
                                  return DropdownButtonHideUnderline(
                                    child: DropdownButton<School>(
                                      value: _selectedSchool,
                                      isExpanded: true,
                                      icon: Icon(
                                        Icons.expand_more_rounded,
                                        color: AppColors.grayText.withOpacity(0.72),
                                        size: 30,
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      hint: Text(
                                        'Select School',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w500,
                                          fontSize: 16,
                                          color: AppColors.grayText.withOpacity(0.68),
                                        ),
                                      ),
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 16,
                                        color: AppColors.primaryBlue,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      items: schools.map((School school) {
                                        return DropdownMenuItem<School>(
                                          value: school,
                                          child: Text(school.name),
                                        );
                                      }).toList(),
                                      onChanged: (School? newValue) {
                                        setState(() {
                                          _selectedSchool = newValue;
                                        });
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),

                            const SizedBox(height: 24),

                            SizedBox(
                              width: 291,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Expanded(
                                        child: Text(
                                          'Date of Birth',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w600,
                                            fontSize: 20,
                                            color: AppColors.primaryBlue,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: _pickBirthdate,
                                    child: Container(
                                      width: 291,
                                      height: 55,
                                      decoration: BoxDecoration(
                                        color: AppColors.white.withOpacity(0.21),
                                        borderRadius: BorderRadius.circular(15),
                                        border: Border.all(
                                          color: AppColors.white.withOpacity(0.79),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Text(
                                              _birthdateDisplay(_selectedBirthdate),
                                              style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                                color: _selectedBirthdate == null
                                                    ? AppColors.grayText.withOpacity(0.68)
                                                    : AppColors.primaryBlue,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(right: 16),
                                            child: Icon(
                                              FluentIcons.calendar_20_filled,
                                              size: 24,
                                              color: AppColors.grayText.withOpacity(0.72),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // 3. Select Grade Dropdown
                            _buildInputWrapper(
                              label: 'Grade',
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedGrade,
                                  isExpanded: true,
                                  icon: Icon(
                                    Icons.expand_more_rounded, // Chevron rotated 90
                                    color: AppColors.grayText.withOpacity(0.72), // 595959 72%
                                    size: 30,
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  hint: Text(
                                    'Select Grade',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w500, // Medium 16
                                      fontSize: 16,
                                      color: AppColors.grayText.withOpacity(0.68), // 595959 68%
                                    ),
                                  ),
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 16,
                                    color: AppColors.primaryBlue, // Dark blue text when selected
                                    fontWeight: FontWeight.w500,
                                  ),
                                  items: _grades.map((String grade) {
                                    return DropdownMenuItem<String>(
                                      value: grade,
                                      child: Text(grade),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _selectedGrade = newValue;
                                    });
                                  },
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // 4. Student face photo (same label style as other fields)
                            SizedBox(
                              width: 291,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                                    child: Text(
                                      'Student Face Photo',
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 20,
                                        color: AppColors.primaryBlue,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _pickFacePhoto,
                                    child: Container(
                                      width: 291,
                                      height: 140,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: AppColors.white.withOpacity(0.21),
                                        borderRadius: BorderRadius.circular(15),
                                        border: Border.all(
                                          color: AppColors.white.withOpacity(0.79),
                                          width: 1,
                                        ),
                                      ),
                                      child: _facePhoto == null
                                          ? Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.face_outlined,
                                                  size: 40,
                                                  color: AppColors.grayText.withOpacity(0.72),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Tap to add a clear face photo',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontFamily: 'Inter',
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                    color: AppColors.grayText.withOpacity(0.68),
                                                  ),
                                                ),
                                              ],
                                            )
                                          : ClipRRect(
                                              borderRadius: BorderRadius.circular(14),
                                              child: Image.file(
                                                File(_facePhoto!.path),
                                                width: 291,
                                                height: 140,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 48), // Spacing before button

                            // Sign Up Button
                            GestureDetector(
                              onTap: _isLoading ? null : () async {
                                final studentName = _studentNameController.text.trim();
                                final birthdate = _birthdateController.text.trim();

                                if (studentName.isEmpty) {
                                  await showAppFeedback(
                                    context,
                                    'Please enter student name.',
                                    isError: true,
                                  );
                                  return;
                                }
                                if (_selectedSchool == null) {
                                  await showAppFeedback(
                                    context,
                                    'Please select a school.',
                                    isError: true,
                                  );
                                  return;
                                }
                                if (_selectedGrade == null) {
                                  await showAppFeedback(
                                    context,
                                    'Please select a grade.',
                                    isError: true,
                                  );
                                  return;
                                }
                                if (birthdate.isEmpty) {
                                  await showAppFeedback(
                                    context,
                                    'Please select birthdate.',
                                    isError: true,
                                  );
                                  return;
                                }
                                if (_facePhoto == null) {
                                  await showAppFeedback(
                                    context,
                                    'Please add a student face photo.',
                                    isError: true,
                                  );
                                  return;
                                }
                                final faceOk = await _validateFacePhoto(_facePhoto!);
                                if (!faceOk) return;

                                setState(() => _isLoading = true);
                                try {
                                  final bytes = await File(_facePhoto!.path).readAsBytes();
                                  final b64 = base64Encode(bytes);
                                  final child = Child(
                                    name: studentName,
                                    schoolId: _selectedSchool!.id,
                                    birthdate: birthdate,
                                    grade: _selectedGrade!,
                                    photoBase64: b64,
                                  );
                                  await ServiceLocator.parentService.register(
                                    name: widget.parentData.name,
                                    phone: widget.parentData.phone,
                                    email: widget.parentData.email,
                                    password: widget.parentData.password,
                                    latitude: widget.parentData.latitude,
                                    longitude: widget.parentData.longitude,
                                    governorate: widget.parentData.governorate,
                                    street: widget.parentData.street,
                                    children: [child],
                                  );
                                  if (!mounted) return;
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    fadeRoute(const ParentLoginScreen()),
                                    (route) => false,
                                  );
                                } catch (e) {
                                  if (!mounted) return;
                                  await showAppFeedback(
                                    context,
                                    e.toString(),
                                    isError: true,
                                  );
                                } finally {
                                  if (mounted) setState(() => _isLoading = false);
                                }
                              },
                              child: Container(
                                width: 291,
                                height: 62,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryButtonGradient,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 32,
                                    color: AppColors.white,
                                  ),
                                ),
                              ),
                            ),

                          ],
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
    );
  }

  // A helper method that builds the deep-blue text label over the specific 55px text field container
  Widget _buildInputWrapper({
    required String label,
    required Widget child,
  }) {
    return SizedBox(
      width: 291, // Constrains the label to align perfectly with the input box
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Input Label
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600, // SemiBold 20
                fontSize: 20,
                color: AppColors.primaryBlue, // Deep Blue 100%
              ),
            ),
          ),

          // The Input Box (TextField or Dropdown)
          Container(
            width: 291,
            height: 55, // Fixed height per Figma
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.21), // ffffff 21%
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: AppColors.white.withOpacity(0.79), // ffffff 79%
                width: 1,
              ),
            ),
            child: child, // Injects either the TextField or DropdownButton here
          ),
        ],
      ),
    );
  }
}