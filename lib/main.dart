import 'package:application/helpers/app_theme.dart';
import 'package:application/screens/onboarding/launch_splash_screen.dart';
import 'package:application/services/service_locator.dart';
import 'package:application/services/push_notifications_service.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ServiceLocator.init();
  await PushNotificationsService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ServiceLocator.themeController,
      builder: (context, child) {
        return MaterialApp(
          navigatorKey: ServiceLocator.navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'Busify App',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ServiceLocator.themeController.themeMode,
          home: child,
        );
      },
      child: const LaunchSplashScreen(),
    );
  }
}
