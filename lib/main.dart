import 'package:application/screens/onboarding/launch_splash_screen.dart';
import 'package:application/services/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:application/constants/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ServiceLocator.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Busify App',
      theme: ThemeData(
        fontFamily: 'Inter',
        scaffoldBackgroundColor: AppColors.scaffoldBackground,
      ),
      home: const LaunchSplashScreen(),
    );
  }
}
