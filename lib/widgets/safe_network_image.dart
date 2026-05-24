import 'package:flutter/widgets.dart';

class SafeNetworkImage extends StatefulWidget {
  const SafeNetworkImage({
    super.key,
    required this.url,
    required this.width,
    required this.height,
    required this.fit,
    required this.fallback,
  });

  final String? url;
  final double width;
  final double height;
  final BoxFit fit;
  final Widget fallback;

  @override
  State<SafeNetworkImage> createState() => _SafeNetworkImageState();
}

class _SafeNetworkImageState extends State<SafeNetworkImage> {
  @override
  Widget build(BuildContext context) {
    final url = widget.url?.trim();
    if (url == null || url.isEmpty) {
      return widget.fallback;
    }
    return Image.network(
      url,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      errorBuilder: (context, error, stackTrace) => widget.fallback,
    );
  }
}
