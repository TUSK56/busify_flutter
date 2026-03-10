import 'package:application/constants/app_colors.dart';
import 'package:application/constants/app_images.dart';
import 'package:application/helpers/fade_route.dart';
import 'package:application/screens/supervisor/supervisor_attendance_screen.dart';
import 'package:application/screens/supervisor/supervisor_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class SupervisorTripScreen extends StatelessWidget {
  const SupervisorTripScreen({super.key});

  /// Function to open the camera and navigate to the Attendance Screen
  Future<void> _takeAttendance(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (photo != null && context.mounted) {
        // Navigate to the next screen with the captured image path
        Navigator.push(
          context,
          fadeRoute(SupervisorAttendanceScreen(imagePath: photo.path)),
        );
      }
    } catch (e) {
      debugPrint('Error opening camera: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Standardize width for mobile feel on larger devices
    double effectiveWidth = size.width > 450 ? 450 : size.width;

    return Scaffold(
      backgroundColor: AppColors.lightGray, // f5f5f5
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: effectiveWidth,
            child: Column(
              children: [
                // --- TOP HEADER (Figma: x:-16 y:-14, h:235) ---
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 25),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryBlue,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Status Bar / Nav Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 22),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Image.asset(AppImages.logo, width: 104, height: 44),
                          Image.asset(AppImages.supervisorProfile, width: 56, height: 56),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Welcome Row
                      Row(
                        children: [
                          const SizedBox(width: 10),
                          Image.asset(AppImages.supervisorAvatar, width: 24, height: 42),
                          const SizedBox(width: 15),
                          const Expanded(
                            child: Text(
                              'Welcome, Supervisor Name',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // --- SCROLLABLE CONTENT ---
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // On Route Status Bar
                        Container(
                          width: double.infinity,
                          height: 45,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: const Row(
                            children: [
                              CircleAvatar(backgroundColor: Color(0xFF1BD95D), radius: 6),
                              SizedBox(width: 10),
                              Text('On Route', style: TextStyle(color: Colors.white, fontSize: 16)),
                              Spacer(),
                              CircleAvatar(backgroundColor: Color(0xFFFFCA07), radius: 6),
                              SizedBox(width: 10),
                              Text('ETA: 5 min', style: TextStyle(color: Colors.white, fontSize: 16)),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Map Box
                        ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: AspectRatio(
                            aspectRatio: 362 / 279,
                            child: Container(
                              decoration: const BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage(AppImages.supervisorMap),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(20),
                                child: Text(
                                  'Bus #7',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Boarding Statistics Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6E9ED),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            children: [
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Students Boarded', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                                  Text('20 / 6', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                ],
                              ),
                              const SizedBox(height: 15),
                              // Progress Bar
                              Stack(
                                children: [
                                  Container(
                                    height: 12,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: const Color(0xBCB4B4B4),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  Container(
                                    height: 12,
                                    width: (effectiveWidth - 72) * 0.75, // 75% progress example
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF18A74A),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              const Row(
                                children: [
                                  CircleAvatar(backgroundColor: Color(0xFF18A74A), radius: 6),
                                  SizedBox(width: 8),
                                  Text('Boarded 20'),
                                  SizedBox(width: 30),
                                  CircleAvatar(backgroundColor: Color(0xFFFFCA07), radius: 6),
                                  SizedBox(width: 8),
                                  Text('Remaining 5'),
                                ],
                              )
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // TAKE ATTENDANCE BUTTON
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: () => _takeAttendance(context),
                            icon: const Icon(Icons.camera_alt, color: Color(0xFF8FBFFA)),
                            label: const Text(
                              'Take attendance',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // --- BOTTOM NAVIGATION BAR ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Container(
                    height: 84,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6E9ED),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              fadeRoute(const SupervisorHomeScreen()),
                            );
                          },
                          child: _buildNavItem(Icons.home, 'Home', AppColors.grayText, false),
                        ),
                        GestureDetector(
                          onTap: () => _takeAttendance(context),
                          child: _buildNavItem(Icons.fact_check_outlined, 'Attendance', AppColors.linkBlue, true),
                        ),
                        _buildNavItem(Icons.person_outline, 'Profile', AppColors.grayText, false),
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
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}