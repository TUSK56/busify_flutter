import 'package:flutter/material.dart';
import 'screens/onboarding/get_started_screen.dart'; // Import your new screen here!

void main() {
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
      ),
      home: const GetStartedScreen(), // This now loads from get_started_screen.dart
    );
  }
}