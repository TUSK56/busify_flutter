import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Single source of truth for responsive layout (Figma **390** pt width reference).
/// Use [scale] for **both** horizontal and vertical spacing so typography and boxes stay aligned.
abstract final class AppLayout {
  AppLayout._();

  static const double designWidth = 390;
  static const double designHeight = 1240;
  static const double maxContentWidth = 450;

  static LayoutMetrics metricsOf(BuildContext context) {
    final media = MediaQuery.of(context);
    final sw = media.size.width;
    final capped = math.min(sw, maxContentWidth);
    final scale = capped / designWidth;
    return LayoutMetrics(
      scale: scale,
      cappedWidth: capped,
      bottomInset: media.padding.bottom,
      topInset: media.padding.top,
    );
  }
}

class LayoutMetrics {
  const LayoutMetrics({
    required this.scale,
    required this.cappedWidth,
    required this.bottomInset,
    required this.topInset,
  });

  final double scale;
  final double cappedWidth;
  final double bottomInset;
  final double topInset;
}
