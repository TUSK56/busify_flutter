import 'package:flutter/material.dart';

class SupervisorHomeScreen extends StatelessWidget {
  const SupervisorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          // --- TOP BLUE FRAME ---
          Positioned(
            left: -19,
            top: -13,
            child: Container(
              width: 422,
              height: 262,
              decoration: BoxDecoration(
                color: const Color(0xF7214071), // 214071 with 97% opacity
                borderRadius: BorderRadius.circular(40),
              ),
            ),
          ),

          // --- LOGO (2.png) ---
          Positioned(
            left: 61,
            top: 62,
            child: Image.asset(
              'assets/2.png',
              width: 104,
              height: 44,
              errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.bus_alert, color: Colors.white, size: 40),
            ),
          ),

          // --- WELCOME TEXT ---
          const Positioned(
            left: 48,
            top: 150,
            child: Text(
              'Welcome, Supervisor',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),

          // --- PROFILE IMAGE (13.png) ---
          Positioned(
            left: 312,
            top: 135,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                image: const DecorationImage(
                  image: AssetImage('assets/13.png'),
                  fit: BoxFit.cover,
                ),
                color: Colors.grey[300],
              ),
            ),
          ),

          // --- MAIN CONTENT AREA (GRAY FRAME) ---
          Positioned(
            left: 0,
            right: 0,
            top: 221,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: Stack(
                children: [
                  // --- STUDENTS STATUS CARD ---
                  Positioned(
                    left: 24,
                    top: 58,
                    child: Container(
                      width: 342, // Adjusted to fit screen width
                      height: 188,
                      decoration: BoxDecoration(
                        color: const Color(0x7DD9D9D9), // d9d9d9 with 49% opacity
                        borderRadius: BorderRadius.circular(29),
                      ),
                      child: const _StatusCardContent(),
                    ),
                  ),

                  // --- START TRIP BUTTON ---
                  Positioned(
                    left: 50, // Center alignment adjustment
                    right: 50,
                    top: 332,
                    child: SizedBox(
                      width: 291,
                      height: 62,
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: Edit your onTap logic here
                          print("Trip Started!");
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xF7214071), // Fill color
                          foregroundColor: Colors.white, // Text color
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