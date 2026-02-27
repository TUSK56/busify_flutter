import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'supervisor_reset_password_screen.dart'; // Make sure you rename the previous code file to screen_9.dart!
// this page is supervisor otp verification
class SupervisorOtpScreen extends StatefulWidget {
  const SupervisorOtpScreen({super.key});

  @override
  State<SupervisorOtpScreen> createState() => _SupervisorOtpScreenState();
}

class _SupervisorOtpScreenState extends State<SupervisorOtpScreen> {
  // Controllers and FocusNodes for the 4 OTP boxes
  final List<TextEditingController> _controllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  // Error state for wrong OTP
  String? _errorMessage;

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _verifyOtp() {
    // Combine the text from all 4 boxes
    String otp = _controllers.map((c) => c.text).join();

    if (otp == '0000') {
      // Clear error if any
      setState(() {
        _errorMessage = null;
      });
      // Correct OTP! Navigate to Reset Password
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SupervisorResetPasswordScreen(), // Previously "ScreenEight"
        ),
      );
    } else {
      // Wrong OTP, show error message
      setState(() {
        _errorMessage = 'Wrong OTP. Please try 0000 for testing.';
      });

      // Optional: Clear fields on wrong attempt
      for (var controller in _controllers) {
        controller.clear();
      }
      _focusNodes[0].requestFocus(); // Go back to first box
    }
  }

  @override
  Widget build(BuildContext context) {
    // Screen dimensions for responsive layout
    final size = MediaQuery.of(context).size;
    final screenHeight = size.height;

    // Cap the width for tablet/iPad support
    double effectiveWidth = size.width;
    if (effectiveWidth > 450) effectiveWidth = 450;

    // Calculate dynamic scaling ratios based on standard 390 width
    final double widthRatio = effectiveWidth / 390;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/10.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: screenHeight * 0.02),

                  // Top Logo (2.png)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 47 * widthRatio),
                      child: Image.asset(
                        'assets/images/2.png',
                        width: 104 * widthRatio,
                        height: 100 * widthRatio,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.01),

                  // Back Button (Chevron Backward)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
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
                  ),

                  SizedBox(height: screenHeight * 0.03),

                  // Title Text
                  const Text(
                    'Enter your OTP',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600, // SemiBold 32
                      fontSize: 32,
                      color: Color(0xFFFFFFFF), // ffffff 100%
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Subtitle Text
                  Text(
                    "We've sent a code to your email",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500, // Medium 16
                      fontSize: 16,
                      color: const Color(0xFFFFFFFF).withOpacity(0.66), // ffffff 66%
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.05),

                  // 4 OTP Boxes Frame (Width 288, Gap 16)
                  SizedBox(
                    width: 288 * widthRatio,
                    height: 60,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(4, (index) {
                        return _buildOTPBox(index);
                      }),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Error Message Display (if wrong OTP)
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),

                  SizedBox(height: screenHeight * 0.04),

                  // Verify / Get OTP Button (Rectangle 221x45)
                  GestureDetector(
                    onTap: _verifyOtp,
                    child: Container(
                      width: 221 * widthRatio,
                      height: 45,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF214071), // 214071 100%
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Text(
                        'Verify OTP', // The prompt mentioned a button to click here
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600, // SemiBold
                          fontSize: 18,
                          color: Color(0xFFFFFFFF), // ffffff 100%
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.04),

                  // Resend OTP Text
                  GestureDetector(
                    onTap: () {
                      // TODO: Logic to resend email
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('OTP resent to email! (Test: 0000)')),
                      );
                    },
                    child: Text(
                      'Resend OTP',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500, // Medium 16
                        fontSize: 16,
                        color: const Color(0xFFFFFFFF).withOpacity(0.66), // ffffff 66%
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.05),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget to build individual 60x60 OTP Input box
  Widget _buildOTPBox(int index) {
    return Container(
      width: 60,
      height: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5).withOpacity(0.32), // f5f5f5 32%
        borderRadius: BorderRadius.circular(10), // Radius 10
        border: Border.all(
          color: const Color(0xFFFFFFFF), // ffffff 100%
          width: 2, // weight: 2
        ),
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1, // Only 1 digit per box
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly, // Enforce numbers
        ],
        decoration: const InputDecoration(
          border: InputBorder.none,
          counterText: '', // Hides the character counter below
        ),
        onChanged: (value) {
          // If a digit is typed, move to the NEXT box automatically
          if (value.isNotEmpty) {
            if (index < 3) {
              _focusNodes[index + 1].requestFocus();
            } else {
              _focusNodes[index].unfocus(); // Done typing
            }
          }
          // If deleted, move to the PREVIOUS box automatically
          else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }
}