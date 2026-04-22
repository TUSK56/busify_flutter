import 'dart:ui';
import 'dart:convert';
import 'package:application/helpers/fade_route.dart';
import 'package:application/models/parent_signup_data.dart';
import 'package:application/screens/parent/parent_signup_student_screen.dart';
import 'package:flutter/material.dart';
import 'package:application/constants/app_colors.dart';
import 'package:application/constants/app_images.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class ParentSignupInfoScreen extends StatefulWidget {
  const ParentSignupInfoScreen({super.key});

  @override
  State<ParentSignupInfoScreen> createState() => _ParentSignupInfoScreenState();
}

class _ParentSignupInfoScreenState extends State<ParentSignupInfoScreen> {
  // State to manage password visibility
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isResolvingLocation = false;
  double? _latitude;
  double? _longitude;
  String? _governorate;
  String? _street;
  Future<void> _pickLocationFromGps() async {
    setState(() => _isResolvingLocation = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Please enable location services.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission is required to continue.');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );

      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=${position.latitude}&lon=${position.longitude}&format=jsonv2',
      );
      final response = await http.get(
        url,
        headers: const {'User-Agent': 'busify-parent-signup/1.0'},
      );
      if (response.statusCode != 200) {
        throw Exception('Could not resolve address from location.');
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final address = (data['address'] as Map<String, dynamic>?) ?? const {};
      final governorate =
          (address['state'] ?? address['city'] ?? address['county'] ?? '')
              .toString()
              .trim();
      final street =
          (address['road'] ?? address['suburb'] ?? address['neighbourhood'] ?? '')
              .toString()
              .trim();
      if (governorate.isEmpty || street.isEmpty) {
        throw Exception('Could not detect governorate/street from GPS.');
      }

      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _governorate = governorate;
        _street = street;
        _addressController.text = '$governorate, $street';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isResolvingLocation = false);
    }
  }


  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              SizedBox(height: screenHeight * 0.01),

              // Top Logo (2.png)
              Image.asset(
                AppImages.logo,
                width: 126,
                height: 150,
                fit: BoxFit.contain,
              ),

              SizedBox(height: screenHeight * 0.02),

              // Header Row: Back Button & Title
              Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // Back Button (Chevron Backward)
                  Padding(
                    padding: EdgeInsets.only(left: 24),
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

                  // Create Account Title
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Create Account',
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

              SizedBox(height: screenHeight * 0.03),

              // Expanded Bottom Sheet for inputs
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
                        padding: const EdgeInsets.symmetric(vertical: 30),
                        child: Column(
                          children: [

                            // 1. Parent Name
                            _buildInputField(
                              label: 'Parent Name',
                              hintText: 'Enter your name',
                              controller: _nameController,
                            ),

                            // 2. Email
                            _buildInputField(
                              label: 'Email',
                              hintText: 'Enter your email',
                              keyboardType: TextInputType.emailAddress,
                              controller: _emailController,
                            ),

                            // 3. Mobile Number
                            _buildInputField(
                              label: 'Mobile Number',
                              hintText: 'Enter your mobile number',
                              keyboardType: TextInputType.phone,
                              controller: _phoneController,
                            ),

                            // 4. Address
                            _buildInputField(
                              label: 'Address',
                              hintText: 'Use GPS icon to detect address',
                              controller: _addressController,
                              readOnly: true,
                              customSuffixIcon: _isResolvingLocation
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : GestureDetector(
                                      onTap: _pickLocationFromGps,
                                      child: Icon(
                                        Icons.my_location,
                                        color: AppColors.white.withOpacity(0.8),
                                        size: 20,
                                      ),
                                    ),
                            ),

                            // 5. Password
                            _buildInputField(
                              label: 'Password',
                              hintText: 'Enter password',
                              isPassword: true,
                              obscureText: _obscurePassword,
                              controller: _passwordController,
                              onToggleVisibility: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),

                            // 6. Confirm Password
                            _buildInputField(
                              label: 'Confirm password',
                              hintText: 'Confirm your password',
                              isPassword: true,
                              obscureText: _obscureConfirmPassword,
                              controller: _confirmPasswordController,
                              onToggleVisibility: () {
                                setState(() {
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                });
                              },
                            ),

                            SizedBox(height: screenHeight * 0.04),

                            // Continue Button
                            GestureDetector(
                              onTap: () {
                                final name = _nameController.text.trim();
                                final email = _emailController.text.trim();
                                final phone = _phoneController.text.trim();
                                final address = _addressController.text.trim();
                                final password = _passwordController.text;
                                final confirm = _confirmPasswordController.text;

                                if (name.isEmpty || email.isEmpty || phone.isEmpty ||
                                    address.isEmpty || password.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please fill all fields.')),
                                  );
                                  return;
                                }
                                if (_latitude == null ||
                                    _longitude == null ||
                                    _governorate == null ||
                                    _street == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please use the location icon to get your exact address.'),
                                    ),
                                  );
                                  return;
                                }
                                if (password != confirm) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Passwords do not match.')),
                                  );
                                  return;
                                }
                                if (password.length < 6) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Password must be at least 6 characters.')),
                                  );
                                  return;
                                }

                                final data = ParentSignupData(
                                  name: name,
                                  email: email,
                                  phone: phone,
                                  address: address,
                                  latitude: _latitude!,
                                  longitude: _longitude!,
                                  governorate: _governorate!,
                                  street: _street!,
                                  password: password,
                                );
                                Navigator.push(
                                  context,
                                  fadeRoute(ParentSignupStudentScreen(parentData: data)),
                                );
                              },
                              child: Container(
                                width: 291,
                                height: 62,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryButtonGradient,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: const Text(
                                  'Continue',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w600, // SemiBold 32
                                    fontSize: 32,
                                    color: AppColors.white, // ffffff 100%
                                  ),
                                ),
                              ),
                            ),

                            // Bottom padding to ensure scroll clears the keyboard nicely
                            SizedBox(height: screenHeight * 0.05),
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

  // Reusable builder for the complex Label + Text Field combination
  Widget _buildInputField({
    required String label,
    required String hintText,
    TextEditingController? controller,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    Widget? customSuffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0), // Spacing between each input block
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Aligns elements to the left inside the column
        children: [
          // The Pill-shaped Label
          Padding(
            padding: EdgeInsets.only(left: 19), // Offsets the label perfectly over the field
            child: Container(
              width: 154, // Fixed width from Figma
              height: 24, // Fixed height from Figma
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400, // Regular 14
                  fontSize: 14,
                  color: AppColors.lightGray, // f5f5f5 100%
                ),
              ),
            ),
          ),

          const SizedBox(height: 8), // Slight gap between label and field

          // The Input Field
          Container(
            width: 291,
            height: 40, // Height restricted to 40 per Figma spec
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.21), // ffffff 21%
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: AppColors.white.withOpacity(0.79), // ffffff 79%
                width: 1,
              ),
            ),
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              readOnly: readOnly,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                border: InputBorder.none,
                isCollapsed: true, // Condenses the padding to fit inside 40px height
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), // Centers text vertically
                hintText: hintText,
                hintStyle: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  color: AppColors.white.withOpacity(0.50), // Subtle hint text
                ),
                // Only show suffix icon if it's a password field
                suffixIcon: customSuffixIcon ??
                    (isPassword
                    ? GestureDetector(
                  onTap: onToggleVisibility,
                  child: Icon(
                    obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.white.withOpacity(0.66),
                    size: 20,
                  ),
                )
                    : null),
              ),
            ),
          ),
        ],
      ),
    );
  }
}