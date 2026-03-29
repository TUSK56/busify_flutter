import 'package:application/constants/app_images.dart';
import 'package:application/screens/onboarding/onboarding_screen_two.dart';
import 'package:flutter/material.dart';

class LaunchSplashScreen extends StatefulWidget {
  const LaunchSplashScreen({super.key});

  @override
  State<LaunchSplashScreen> createState() => _LaunchSplashScreenState();
}

class _LaunchSplashScreenState extends State<LaunchSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _topFade;
  late final Animation<double> _topScale;
  late final Animation<double> _bottomFade;
  late final Animation<Offset> _bottomSlide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _topFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
    );
    _topScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.72, curve: Curves.easeOutBack),
      ),
    );
    _bottomFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 1.0, curve: Curves.easeOut),
    );
    _bottomSlide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _controller.forward();
    _goNext();
  }

  Future<void> _goNext() async {
    await Future<void>.delayed(const Duration(milliseconds: 3100));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const OnboardingScreenTwo(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 700),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const designWidth = 390.0;
    const designHeight = 844.0;
    final widthRatio = size.width / designWidth;
    final heightRatio = size.height / designHeight;

    final topX = 65 * widthRatio;
    final topY = 165 * heightRatio;
    final topWidth = 260 * widthRatio;
    final topHeight = 260 * heightRatio;

    final bottomX = 59 * widthRatio;
    final bottomY = 425 * heightRatio;
    final bottomWidth = 271 * widthRatio;
    final bottomHeight = 231 * heightRatio;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppImages.background),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Stack(
          children: [
            Positioned(
              left: topX,
              top: topY,
              child: FadeTransition(
                opacity: _topFade,
                child: ScaleTransition(
                  scale: _topScale,
                  child: SizedBox(
                    width: topWidth,
                    height: topHeight,
                    child: Image.asset(AppImages.busIcon, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
            Positioned(
              left: bottomX,
              top: bottomY,
              child: SlideTransition(
                position: _bottomSlide,
                child: FadeTransition(
                  opacity: _bottomFade,
                  child: SizedBox(
                    width: bottomWidth,
                    height: bottomHeight,
                    child: Image.asset(AppImages.logo, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
