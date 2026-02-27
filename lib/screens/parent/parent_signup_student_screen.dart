import 'dart:ui';
import 'package:application/helpers/fade_route.dart';
import 'package:flutter/material.dart';
import 'package:application/constants/app_colors.dart';
import 'package:application/constants/app_images.dart';
import 'parent_signup_success_screen.dart';

class ParentSignupStudentScreen extends StatefulWidget {
  const ParentSignupStudentScreen({super.key});

  @override
  State<ParentSignupStudentScreen> createState() => _ParentSignupStudentScreenState();
}

class _ParentSignupStudentScreenState extends State<ParentSignupStudentScreen> {
  // Dummy data for dropdowns (you can replace these with API data later)
  final List<String> _schools = ['International School', 'National School', 'Language School'];
  final List<String> _grades = ['Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5', 'Grade 6'];

  String? _selectedSchool;
  String? _selectedGrade;

  @override
  Widget build(BuildContext context) {
    // Screen dimensions for responsive layout
    final size = MediaQuery.of(context).size;
    final screenHeight = size.height;

    // Cap the width for tablet/iPad support
    double effectiveWidth = size.width;
    if (effectiveWidth > 450) effectiveWidth = 450;

    // Calculate dynamic scaling ratios based on standard 390 width from Figma
    final double widthRatio = effectiveWidth / 390;

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
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.01),

              // Top Logo (2.png)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: 47 * widthRatio),
                  child: Image.asset(
                    AppImages.logo,
                    width: 104 * widthRatio,
                    height: 44 * widthRatio,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.01),

              // Header Row: Back Button & Title
              Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // Back Button (Chevron Backward)
                  Padding(
                    padding: EdgeInsets.only(left: 24 * widthRatio),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context); // Go back
                      },
                      child: Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
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
                padding: EdgeInsets.symmetric(horizontal: 43 * widthRatio),
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

              SizedBox(height: screenHeight * 0.04),

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
                        padding: const EdgeInsets.only(top: 32, bottom: 40),
                        child: Column(
                          children: [

                            // 1. Student's Full Name Text Field
                            _buildInputWrapper(
                              widthRatio: widthRatio,
                              label: 'Student’s Full Name',
                              child: TextField(
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
                                  hintText: 'As registered in the school records',
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

                            // 2. Select School Dropdown
                            _buildInputWrapper(
                              widthRatio: widthRatio,
                              label: 'School Name',
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedSchool,
                                  isExpanded: true,
                                  icon: Icon(
                                    Icons.expand_more_rounded, // Chevron rotated 90
                                    color: AppColors.grayText.withOpacity(0.72), // 595959 72%
                                    size: 30,
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  hint: Text(
                                    'Select School',
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
                                  items: _schools.map((String school) {
                                    return DropdownMenuItem<String>(
                                      value: school,
                                      child: Text(school),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _selectedSchool = newValue;
                                    });
                                  },
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // 3. Select Grade Dropdown
                            _buildInputWrapper(
                              widthRatio: widthRatio,
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

                            const SizedBox(height: 48), // Spacing before button

                            // Sign Up Button
                            // Sign Up Button
                            GestureDetector(
                              onTap: () {
                                // Optional: Add your validation logic here
                                if (_selectedSchool != null && _selectedGrade != null) {
                                  // Navigate to Success screen
                                  Navigator.push(
                                    context,
                                    fadeRoute(const ParentSignupSuccessScreen()),
                                  );
                                } else {
                                  // Show error if fields aren't selected
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please select School and Grade.')),
                                  );
                                }
                              },
                              child: Container(
                                width: 291 * widthRatio,
                                height: 62,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: const Text(
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
    required double widthRatio,
    required String label,
    required Widget child,
  }) {
    return SizedBox(
      width: 291 * widthRatio, // Constrains the label to align perfectly with the input box
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
            width: 291 * widthRatio,
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