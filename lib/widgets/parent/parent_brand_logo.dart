import 'package:flutter/material.dart';

/// Parent brand logo: fixed logical size [width] × [height] (adjust only these two).
class ParentBrandLogo {
  ParentBrandLogo._();

  static const double width = 126;
  static const double height = 150;

  /// For blue headers ([Stack] + [Positioned.fill] or fixed height). Centers
  /// the logo vertically and horizontally; scales down with [FittedBox] if
  /// the header is shorter than [height] so it stays fully visible.
  static Widget headerImage(
    String asset, {
    EdgeInsetsGeometry padding = EdgeInsets.zero,
    BoxFit fit = BoxFit.contain,
    FilterQuality filterQuality = FilterQuality.high,
  }) {
    return Padding(
      padding: padding,
      child: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          alignment: Alignment.center,
          child: Image.asset(
            asset,
            width: width,
            height: height,
            fit: fit,
            alignment: Alignment.center,
            filterQuality: filterQuality,
          ),
        ),
      ),
    );
  }

  /// Centers the logo horizontally in the current line / header. Uses the
  /// tightest of [LayoutBuilder] width or safe-area body width so it works
  /// inside [Column], [Stack], and [SafeArea].
  static Widget image(
    String asset, {
    BoxFit fit = BoxFit.contain,
    FilterQuality filterQuality = FilterQuality.high,
    bool centered = true,
  }) {
    final img = Image.asset(
      asset,
      width: width,
      height: height,
      fit: fit,
      alignment: Alignment.center,
      filterQuality: filterQuality,
    );
    if (!centered) return img;

    return LayoutBuilder(
      builder: (context, constraints) {
        final mq = MediaQuery.of(context);
        final safeBodyW =
            mq.size.width - mq.padding.left - mq.padding.right;
        final w = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : safeBodyW;

        return SizedBox(
          width: w,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [img],
          ),
        );
      },
    );
  }
}
