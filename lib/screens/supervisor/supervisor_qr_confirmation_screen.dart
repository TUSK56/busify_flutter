import 'dart:io';
import 'package:application/constants/app_colors.dart';
import 'package:application/constants/app_images.dart';
import 'package:application/helpers/fade_route.dart';
import 'package:application/screens/supervisor/supervisor_trip_screen.dart';
import 'package:flutter/material.dart';

class SupervisorQrConfirmationScreen extends StatelessWidget {
  final String imagePath;

  const SupervisorQrConfirmationScreen({super.key, required this.imagePath});

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
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Blue Header Frame (y:-1, h:139)
                  Container(
                    width: double.infinity,
                    height: 140,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryBlue,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                    ),
                    child: Center(
                      child: Image.asset(
                        AppImages.logo,
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Success Image (16.png)
                  Image.asset(AppImages.successCheck, width: 176, height: 138),

                  const SizedBox(height: 10),

                  // Attendance Confirmed Text
                  const Text(
                    'Attendance Confirmed',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppColors.linkBlue,
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Captured Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      File(imagePath),
                      width: 100,
                      height: 97,
                      fit: BoxFit.cover,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Student Name
                  const Text(
                    'Judy Ahmed',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Trip Details Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '• Trip Details :',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _detailRow("Scan Time :", "7:30 AM", Colors.black),
                        _detailRow("Trip Type :", "Morning Trip", Colors.black),
                        _detailRow("Bus :", "#7", Colors.black),
                        const SizedBox(height: 15),
                        _detailRow(
                          "• Boarded Students :",
                          "21",
                          const Color(0xFF18A74A),
                        ),
                        _detailRow(
                          "• Remaining :",
                          "4",
                          const Color(0xFFFFCA07),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Done Button (README: gradient)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 45),
                    child: SizedBox(
                      width: 291,
                      height: 62,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryButtonGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).pushAndRemoveUntil(
                                fadeRoute(const SupervisorTripScreen()),
                                (route) => route.isFirst,
                              );
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: const Center(
                              child: Text(
                                'Done',
                                style: TextStyle(
                                  fontFamily: 'Inter',
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
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String title, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
