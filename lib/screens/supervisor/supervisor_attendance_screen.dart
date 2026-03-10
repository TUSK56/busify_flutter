import 'dart:io';
import 'dart:ui';
import 'package:application/constants/app_colors.dart';
import 'package:application/constants/app_images.dart';
import 'package:application/helpers/fade_route.dart';
import 'package:application/screens/supervisor/supervisor_qr_confirmation_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class SupervisorAttendanceScreen extends StatefulWidget {
  final String imagePath;

  const SupervisorAttendanceScreen({super.key, required this.imagePath});

  @override
  State<SupervisorAttendanceScreen> createState() => _SupervisorAttendanceScreenState();
}

class _SupervisorAttendanceScreenState extends State<SupervisorAttendanceScreen> {
  late String currentImagePath;

  @override
  void initState() {
    super.initState();
    currentImagePath = widget.imagePath;
  }

  // Rescan Function
  Future<void> _rescan() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        currentImagePath = photo.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    double effectiveWidth = size.width > 450 ? 450 : size.width;

    return Scaffold(
      backgroundColor: AppColors.lightGray,
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: effectiveWidth,
            child: Column(
              children: [
                // Header (Figma Position x:-16 y:-14)
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryBlue,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left, color: Colors.white, size: 35),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Image.asset(AppImages.logo, width: 104, height: 44),
                            Image.asset(AppImages.supervisorProfile, width: 60, height: 60),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(AppImages.supervisorAvatar, width: 24, height: 42),
                          const SizedBox(width: 10),
                          const Text(
                            'Welcome Supervisor',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Scanned Image + Glass Card
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: Image.file(
                            File(currentImagePath),
                            width: 366,
                            height: 355,
                            fit: BoxFit.cover,
                          ),
                        ),
                        // Glass Card (Figma Position y:549)
                        Positioned(
                          bottom: 20,
                          left: 5,
                          right: 5,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                height: 160,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.37),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(color: Colors.white, width: 1),
                                ),
                                child: Column(
                                  children: [
                                    const SizedBox(height: 10),
                                    const Text(
                                      'Attendance Recorded',
                                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
                                    ),
                                    const Text(
                                      'Judy Ahmed',
                                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.black),
                                    ),
                                    const Spacer(),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 15),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          _buildBtn("Rescan", const Color(0xE6E9EDF0), Colors.black, _rescan),
                                          _buildBtn("Confirm", AppColors.primaryBlue, AppColors.white, () {
                                            Navigator.push(
                                              context,
                                              fadeRoute(SupervisorQrConfirmationScreen(imagePath: currentImagePath)),
                                            );
                                          }),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
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

  Widget _buildBtn(String label, Color bg, Color text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 148,
        height: 46,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(7), border: Border.all(color: AppColors.primaryBlue)),
        child: Center(child: Text(label, style: TextStyle(color: text, fontSize: 20, fontWeight: FontWeight.w500))),
      ),
    );
  }
}