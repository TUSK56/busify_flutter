import 'package:flutter/material.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton({
    super.key,
    required this.onTap,
    this.color = Colors.white,
    this.icon = Icons.arrow_back_ios,
    this.iconSize = 24,
  });

  final VoidCallback onTap;
  final Color color;
  final IconData icon;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        containedInkWell: true,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Icon(icon, color: color, size: iconSize),
          ),
        ),
      ),
    );
  }
}
