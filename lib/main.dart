import 'package:application/screens/onboarding/get_started_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    precacheImage(const AssetImage('assets/images/10.png'), context);
    precacheImage(const AssetImage('assets/images/1.png'), context);
    precacheImage(const AssetImage('assets/images/2.png'), context);
    precacheImage(const AssetImage('assets/images/3.png'), context);
    precacheImage(const AssetImage('assets/images/4.png'), context);
    precacheImage(const AssetImage('assets/images/5.png'), context);
    precacheImage(const AssetImage('assets/images/6.png'), context);
    precacheImage(const AssetImage('assets/images/7.png'), context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Busify App',
      theme: ThemeData(
        fontFamily: 'Inter',
        scaffoldBackgroundColor: const Color(0xFF0D1B2A),
      ),
      home: const GetStartedScreen(),
    );
  }
}
