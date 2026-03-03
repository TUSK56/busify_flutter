import 'package:application/constants/app_colors.dart';
import 'package:application/constants/app_images.dart';
import 'package:application/helpers/fade_route.dart';
import 'package:application/screens/supervisor/supervisor_trip_screen.dart';
import 'package:flutter/material.dart';

class SupervisorHomeScreen extends StatelessWidget {
  const SupervisorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenHeight = size.height;
    double effectiveWidth = size.width;
    if (effectiveWidth > 450) effectiveWidth = 450;

    return Scaffold(
      backgroundColor: AppColors.lightGray,
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: effectiveWidth,
            child: Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  constraints: BoxConstraints(
                    minHeight: 200,
                    maxHeight: screenHeight * 0.32,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.asset(
                            AppImages.logo,
                            width: 104,
                            height: 44,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.bus_alert, color: Colors.white, size: 40),
                          ),
                          const Spacer(),
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              image: const DecorationImage(
                                image: AssetImage(AppImages.supervisorAvatar),
                                fit: BoxFit.cover,
                              ),
                              color: Colors.grey[300],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Welcome, Supervisor',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Main content + fixed bottom nav
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: AppColors.lightGray,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                            child: Column(
                              children: [
                                Container(
                                  width: double.infinity,
                                  constraints: const BoxConstraints(maxWidth: 342),
                                  height: 188,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.49),
                                    borderRadius: BorderRadius.circular(29),
                                  ),
                                  child: const _StatusCardContent(),
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  height: 62,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        fadeRoute(const SupervisorTripScreen()),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryBlue,
                                      foregroundColor: AppColors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        side: const BorderSide(color: Colors.transparent),
                                      ),
                                    ),
                                    child: const Text(
                                      'Start Trip',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 24,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          child: Container(
                            height: 84,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6E9ED),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildNavItem(Icons.home, 'Home', AppColors.linkBlue, true),
                                _buildNavItem(Icons.fact_check_outlined, 'Attendance', AppColors.grayText, false),
                                _buildNavItem(Icons.person_outline, 'Profile', AppColors.grayText, false),
                              ],
                            ),
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

  Widget _buildNavItem(IconData icon, String label, Color color, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isActive ? AppColors.linkBlue : const Color(0xFF333333),
          size: 28,
        ),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// Sub-widget for the Status Card inner elements
class _StatusCardContent extends StatelessWidget {
  const _StatusCardContent();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned(
          left: 20,
          top: 15,
          child: Text('Students Status', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        ),
        const Positioned(
          right: 20,
          top: 15,
          child: Text('Bus #7', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
        ),
        // Divider line
        Positioned(
          left: 20,
          right: 20,
          top: 50,
          child: Container(height: 1, color: Colors.black.withOpacity(0.2)),
        ),
        // Statistics Row
        Positioned(
          left: 0,
          right: 0,
          top: 80,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStat('25', 'Assigned'),
              _buildVerticalDivider(),
              _buildStat('0', 'Boarded'),
              _buildVerticalDivider(),
              _buildStat('25', 'Not Yet'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(width: 1, height: 60, color: Colors.black.withOpacity(0.2));
  }
}