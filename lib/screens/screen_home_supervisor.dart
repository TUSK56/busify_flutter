import 'dart:ui';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    // 1. Get screen dimensions
    final Size size = MediaQuery.of(context).size;
    final double screenHeight = size.height;
    final double screenWidth = size.width;

    // 2. Responsive Scaling Logic
    // Cap the width for tablets so content doesn't stretch too far
    double effectiveWidth = screenWidth > 600 ? 600.0 : screenWidth;

    // Explicitly treat as double to avoid 'int' subtype errors
    final double widthRatio = effectiveWidth / 390.0;

    // Fixed Scaling helper: Input and Output are strictly double
    double sp(double fontSize) {
      return fontSize * widthRatio;
    }

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- TOP HEADER ---
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 24.0 * widthRatio,
                  vertical: 15.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset(
                      'assets/images/2.png',
                      width: 90.0 * widthRatio,
                      fit: BoxFit.contain,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.0),
                      ),
                      child: CircleAvatar(
                        radius: 20.0 * widthRatio,
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.person, color: Colors.white, size: 20.0 * widthRatio),
                      ),
                    ),
                  ],
                ),
              ),

              // --- WELCOME MESSAGE ---
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0 * widthRatio),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        fontSize: sp(18.0), // Explicit double
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    Text(
                      'Supervisor',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                        fontSize: sp(28.0), // Explicit double
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: screenHeight * 0.03),

              // --- MAIN DASHBOARD (Glassmorphism) ---
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(35.0),
                    topRight: Radius.circular(35.0),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(35.0),
                          topRight: Radius.circular(35.0),
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1.0,
                        ),
                      ),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.all(24.0 * widthRatio),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quick Actions',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: sp(20.0),
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // --- ACTION GRID ---
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: _buildFeatureIcon(Icons.school, "School", widthRatio, sp)),
                                Expanded(child: _buildFeatureIcon(Icons.calendar_month, "Events", widthRatio, sp)),
                                Expanded(child: _buildFeatureIcon(Icons.notifications, "Alerts", widthRatio, sp)),
                                Expanded(child: _buildFeatureIcon(Icons.settings, "Setup", widthRatio, sp)),
                              ],
                            ),

                            SizedBox(height: 30.0 * widthRatio),

                            Text(
                              'Linked Students',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: sp(20.0),
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 15),

                            _buildStudentCard(widthRatio, sp),

                            const SizedBox(height: 20),
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

  Widget _buildFeatureIcon(IconData icon, String label, double widthRatio, double Function(double) sp) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60.0 * widthRatio,
          height: 60.0 * widthRatio,
          decoration: BoxDecoration(
            color: const Color(0xFF214071).withOpacity(0.8),
            borderRadius: BorderRadius.circular(15.0),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Icon(icon, color: Colors.white, size: 24.0 * widthRatio),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: sp(12.0),
            fontFamily: 'Inter',
          ),
        )
      ],
    );
  }

  Widget _buildStudentCard(double widthRatio, double Function(double) sp) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.0 * widthRatio),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22.0 * widthRatio,
            backgroundColor: const Color(0xFF214071),
            child: Icon(Icons.person_outline, color: Colors.white, size: 22.0 * widthRatio),
          ),
          SizedBox(width: 12.0 * widthRatio),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'John Mason',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: sp(16.0),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Grade 4 - International School',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: sp(13.0),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 14.0 * widthRatio),
        ],
      ),
    );
  }
}