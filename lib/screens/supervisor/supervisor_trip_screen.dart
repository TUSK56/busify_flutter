import 'package:application/constants/app_colors.dart';
import 'package:application/constants/app_images.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class SupervisorTripScreen extends StatelessWidget {
  const SupervisorTripScreen({super.key});

  // Function to open the camera
  Future<void> _takeAttendance(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? photo = await picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        debugPrint('Photo captured: ${photo.path}');
      }
    } catch (e) {
      debugPrint('Error opening camera: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios, color: AppColors.white, size: 22.5),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Spacer(),
                          Image.asset(
                            AppImages.logo,
                            width: 104,
                            height: 44,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.bus_alert, color: AppColors.white),
                          ),
                          const Spacer(),
                          Image.asset(
                            AppImages.supervisorProfile,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const CircleAvatar(backgroundColor: Colors.white24),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Image.asset(
                            AppImages.supervisorAvatar,
                            width: 24,
                            height: 42,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.person, color: AppColors.white),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Text(
                              'Welcome, Supervisor Name',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Content + fixed bottom nav
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.lightGray,
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                            child: Column(
                              children: [
                                // Route status bar
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBlue,
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Row(
                                    children: const [
                                      CircleAvatar(backgroundColor: Color(0xFF1BD95D), radius: 10),
                                      SizedBox(width: 12),
                                      Text('On Route', style: TextStyle(color: AppColors.white, fontSize: 16)),
                                      Spacer(),
                                      CircleAvatar(backgroundColor: Color(0xE0FFCA07), radius: 10),
                                      SizedBox(width: 12),
                                      Text('ETA: 5 min', style: TextStyle(color: AppColors.white, fontSize: 16)),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Map box
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
                                        padding: EdgeInsets.all(16),
                                        child: Align(
                                          alignment: Alignment.topLeft,
                                          child: Text(
                                            'Bus #7',
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Boarding statistics
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE6E9ED),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Column(
                                    children: [
                                      const Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Students Boarded', style: TextStyle(fontWeight: FontWeight.w500)),
                                          Text('20 / 6', style: TextStyle(fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            flex: 20,
                                            child: Container(
                                              height: 12,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF18A74A),
                                                borderRadius: BorderRadius.circular(30),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            flex: 6,
                                            child: Container(
                                              height: 12,
                                              decoration: BoxDecoration(
                                                color: const Color(0xBCB4B4B4),
                                                borderRadius: BorderRadius.circular(30),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      const Row(
                                        children: [
                                          CircleAvatar(backgroundColor: Color(0xFF18A74A), radius: 10),
                                          SizedBox(width: 8),
                                          Text('Boarded 20'),
                                          SizedBox(width: 40),
                                          CircleAvatar(backgroundColor: Color(0x87FFCA07), radius: 10),
                                          SizedBox(width: 8),
                                          Text('Remaining 5'),
                                        ],
                                      )
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Take attendance
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
                                        color: AppColors.white,
                                        fontWeight: FontWeight.w500,
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
          style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: color),
        ),
      ],
    );
  }
}