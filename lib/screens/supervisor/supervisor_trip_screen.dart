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
        // You can handle the captured image here
        debugPrint("Photo captured: ${photo.path}");
      }
    } catch (e) {
      debugPrint("Error opening camera: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          // --- TOP BLUE FRAME ---
          Positioned(
            left: -19,
            top: -1,
            child: Container(
              width: 422,
              height: 249,
              decoration: BoxDecoration(
                color: const Color(0xF7214071),
                borderRadius: BorderRadius.circular(40),
              ),
            ),
          ),

          // --- HEADER ELEMENTS ---
          Positioned(
            left: 15,
            top: 40, // Adjusted for status bar padding
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 22.5),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          Positioned(
            left: 157,
            top: 62,
            child: Image.asset('assets/2.png', width: 104, height: 44,
                errorBuilder: (context, _, __) => const Icon(Icons.bus_alert, color: Colors.white)),
          ),

          Positioned(
            left: 331,
            top: 53,
            child: Image.asset('assets/11.png', width: 73, height: 73,
                errorBuilder: (context, _, __) => const CircleAvatar(backgroundColor: Colors.white24)),
          ),

          // User Welcome Row
          Positioned(
            left: 42,
            top: 141,
            child: Row(
              children: [
                Image.asset('assets/13.png', width: 24, height: 42,
                    errorBuilder: (context, _, __) => const Icon(Icons.person, color: Colors.white)),
                const SizedBox(width: 16),
                const Text(
                  'Welcome, Supervisor Name',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white, // Specification says 000000 but it's on a blue background
                  ),
                ),
              ],
            ),
          ),

          // --- MAIN CONTENT FRAME (F5F5F5) ---
          Positioned(
            left: -15,
            top: 191,
            child: Container(
              width: 413,
              height: 653,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Stack(
                children: [
                  // --- ROUTE STATUS BAR ---
                  Positioned(
                    left: 27 + 15,
                    top: 6,
                    child: Container(
                      width: 362,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFF214071),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 24),
                          const CircleAvatar(backgroundColor: Color(0xFF1BD95D), radius: 10),
                          const SizedBox(width: 15),
                          const Text('On Route', style: TextStyle(color: Colors.white, fontSize: 16)),
                          const Spacer(),
                          const CircleAvatar(backgroundColor: Color(0xE0FFCA07), radius: 10),
                          const SizedBox(width: 20),
                          const Text('ETA: 5 min', style: TextStyle(color: Colors.white, fontSize: 16)),
                          const SizedBox(width: 24),
                        ],
                      ),
                    ),
                  ),

                  // --- MAP/IMAGE BOX ---
                  Positioned(
                    left: 27 + 15,
                    top: 48,
                    child: Container(
                      width: 362,
                      height: 279,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        image: const DecorationImage(
                          image: AssetImage('assets/12.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'Bus #7',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),

                  // --- BOARDING STATISTICS BOX ---
                  Positioned(
                    left: 44 + 15,
                    top: 359,
                    child: Container(
                      width: 332,
                      height: 104,
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
                          // Custom Progress Bar
                          Row(
                            children: [
                              Expanded(flex: 20, child: Container(height: 12, decoration: BoxDecoration(color: const Color(0xFF18A74A), borderRadius: BorderRadius.circular(30)))),
                              const SizedBox(width: 4),
                              Expanded(flex: 6, child: Container(height: 12, decoration: BoxDecoration(color: const Color(0xBCB4B4B4), borderRadius: BorderRadius.circular(30)))),
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
                  ),

                  // --- TAKE ATTENDANCE BUTTON ---
                  Positioned(
                    left: 51 + 15,
                    top: 483,
                    child: SizedBox(
                      width: 325,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: () => _takeAttendance(context),
                        icon: const Icon(Icons.camera_alt, color: Color(0xFF8FBFFA)),
                        label: const Text(
                          'Take attendance',
                          style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xF7214071),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- BOTTOM NAVIGATION BAR ---
          Positioned(
            left: 12,
            right: 12,
            bottom: 20,
            child: Container(
              height: 84,
              decoration: BoxDecoration(
                color: const Color(0xFFE6E9ED),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(Icons.home, 'Home', const Color(0xFF2859C5), true),
                  _buildNavItem(Icons.fact_check_outlined, 'Attendance', const Color(0xFF595959), false),
                  _buildNavItem(Icons.person_outline, 'Profile', const Color(0xFF595959), false),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, Color color, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: isActive ? const Color(0xFF2859C5) : const Color(0xFF333333), size: 28),
        Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: color)),
      ],
    );
  }
}