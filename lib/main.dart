import 'package:application/screens/onboarding/get_started_screen.dart';
import 'package:flutter/material.dart';

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
      home: const GetStartedScreen(),
    );
  }
}