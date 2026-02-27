import 'dart:ui';
import 'package:flutter/material.dart';
import 'role_selection_screen.dart';
// Onboarding page four that have 1 pic of parent with phone and get started arrow back
class OnboardingScreenFour extends StatelessWidget {
  const OnboardingScreenFour({super.key});

  @override
  Widget build(BuildContext context) {
    // Screen dimensions for responsive layout
    final size = MediaQuery.of(context).size;
    final screenHeight = size.height;

    // Cap the width for tablet/iPad support
    double effectiveWidth = size.width;
    if (effectiveWidth > 450) effectiveWidth = 450;

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
                  // Top Header Spacing (~3% of height)
                  SizedBox(height: screenHeight * 0.03),

                  // Header (Back Arrow Only - Skip is removed on this screen)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: effectiveWidth * 0.06),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context); // Goes back to the previous screen
                        },
                        child: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                          size: 22.5,
                        ),
                      ),
                    ),
                  ),

                  // Spacing between Header and Glass Card
                  SizedBox(height: screenHeight * 0.06),

                  // Glassmorphism Card (w: 331, h: 427)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                      child: Container(
                        width: effectiveWidth * 0.85, // ~331 max
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFFFF).withOpacity(0.14), // ffffff 14%
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: const Color(0xFFFFFFFF).withOpacity(0.76), // ffffff 76% stroke
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Image 5.png
                            Image.asset(
                              'assets/images/5.png',
                              width: effectiveWidth * 0.74, // ~290 max
                              height: screenHeight * 0.23, // ~196 max
                              fit: BoxFit.contain,
                            ),

                            SizedBox(height: screenHeight * 0.03),

                            // Title Text
                            const Text(
                              'Parents Track the Route',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600, // SemiBold
                                fontSize: 24,
                                height: 22 / 24,
                                letterSpacing: 0,
                                color: Color(0xFFFFFFFF),
                              ),
                            ),

                            SizedBox(height: screenHeight * 0.03),

                            // Divider Line (w: 254, weight: 2)
                            Container(
                              width: effectiveWidth * 0.65, // ~254 max
                              height: 2,
                              color: const Color(0xFFFFFFFF).withOpacity(0.66), // ffffff 66%
                            ),

                            SizedBox(height: screenHeight * 0.025),

                            // Subtitle Text
                            const Text(
                              "Monitor your child's journey in real-time on the map.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w400, // Regular
                                fontSize: 16,
                                height: 22 / 16,
                                letterSpacing: 0,
                                color: Color(0xFFFFFFFF),
                              ),
                            ),

                            SizedBox(height: screenHeight * 0.01),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Spacing between Card and Action Button
                  SizedBox(height: screenHeight * 0.055),

                  // "Get started" Button
                  SizedBox(
                    width: effectiveWidth * 0.74 > 291 ? 291 : effectiveWidth * 0.74,
                    height: 62,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF214071),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: const BorderSide(
                            color: Color(0xFF214071),
                            width: 1,
                          ),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
                        );
                      },
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: const Text(
                          'Get started',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.bold, // Bold
                            fontSize: 32,
                            height: 22 / 32,
                            letterSpacing: 0,
                            color: Color(0xFFFFFFFF),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Safe padding at the bottom
                  SizedBox(height: screenHeight * 0.04),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}