import 'dart:io';
import 'package:application/constants/app_colors.dart';
import 'package:application/constants/app_images.dart';
import 'package:application/helpers/app_theme.dart';
import 'package:application/helpers/supervisor_photo.dart';
import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';


class SupervisorQrConfirmationScreen extends StatelessWidget {
  final String imagePath;
  /// When set (e.g. manual pick), show enrolled/profile photo instead of the camera file.
  final String? studentPhotoUrl;
  final String studentName;
  final String studentGrade;
  final String studentBirthdate;
  final String busNumber;
  final int boarded;
  final int remaining;
  final int tripId;
  final int studentId;
  final String scanTimeLabel;
  final String tripTypeLabel;

  const SupervisorQrConfirmationScreen({
    super.key,
    required this.imagePath,
    this.studentPhotoUrl,
    required this.studentName,
    required this.studentGrade,
    required this.studentBirthdate,
    required this.busNumber,
    required this.boarded,
    required this.remaining,
    required this.tripId,
    required this.studentId,
    required this.scanTimeLabel,
    required this.tripTypeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appScaffoldBackground,
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: double.infinity,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Blue Header Frame (y:-1, h:139)
                  Container(
                    width: double.infinity,
                    height: 105,
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
                        height: 126,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  const SizedBox(height: 0),

                  // Success Image (16.png)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        FluentIcons.checkmark_20_filled,
                        size: 100,
                        color: Color(0xFF22C55E),
                      ),
                      Container(
                        width: 80,
                        height: 10,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF22C55E).withOpacity(0.8),
                              blurRadius: 16,
                              spreadRadius: 4,
                            ),
                          ],
                          color: Colors.transparent,
                        ),
                      ),
                    ],
                  ),

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

                  // Captured or enrolled (manual pick) image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _confirmationPhoto(
                      imagePath: imagePath,
                      studentPhotoUrl: studentPhotoUrl,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Student Name
                  Text(
                    studentName,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: context.appPrimaryText,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Trip Details Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• Trip Details :',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: context.appPrimaryText,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _detailRow(
                          context,
                          "Scan Time :",
                          scanTimeLabel,
                          context.appPrimaryText,
                        ),
                        _detailRow(
                          context,
                          "Trip Type :",
                          tripTypeLabel,
                          context.appPrimaryText,
                        ),
                        _detailRow(
                          context,
                          "Bus :",
                          '#$busNumber',
                          context.appPrimaryText,
                        ),
                        const SizedBox(height: 10),
                        _detailRow(
                          context,
                          "Grade :",
                          studentGrade,
                          context.appPrimaryText,
                        ),
                        _detailRow(
                          context,
                          "Birthdate :",
                          studentBirthdate,
                          context.appPrimaryText,
                        ),
                        const SizedBox(height: 15),
                        _detailRow(
                          context,
                          "• Boarded Students :",
                          '$boarded',
                          const Color(0xFF18A74A),
                        ),
                        _detailRow(
                          context,
                          "• Remaining :",
                          '$remaining',
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
                            onTap: () => Navigator.of(context).pop(true),
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

  Widget _confirmationPhoto({
    required String imagePath,
    required String? studentPhotoUrl,
  }) {
    final full = supervisorPhotoFullUrl(studentPhotoUrl);
    if (full != null && full.isNotEmpty) {
      return Image.network(
        full,
        width: 100,
        height: 97,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Image.file(
          File(imagePath),
          width: 100,
          height: 97,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const SizedBox(width: 100, height: 97),
        ),
      );
    }
    return Image.file(
      File(imagePath),
      width: 100,
      height: 97,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const SizedBox(width: 100, height: 97),
    );
  }

  Widget _detailRow(
    BuildContext context,
    String title,
    String value,
    Color valueColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: context.appPrimaryText,
            ),
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
