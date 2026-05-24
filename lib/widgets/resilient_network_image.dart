import 'package:application/services/service_locator.dart';
import 'package:flutter/material.dart';

/// Loads [urls] in order until one succeeds. Helps when the API path differs
/// slightly from how static files are hosted (e.g. `/uploads/` vs `/upload/`).
class ResilientNetworkImage extends StatefulWidget {
  const ResilientNetworkImage({
    super.key,
    required this.urls,
    required this.width,
    required this.height,
    required this.fit,
    required this.fallback,
    this.sendAuthBearer = true,
  });

  final List<String> urls;
  final double width;
  final double height;
  final BoxFit fit;
  final Widget fallback;

  /// When true and a JWT is stored, sends `Authorization: Bearer …` (harmless for public static files).
  final bool sendAuthBearer;

  @override
  State<ResilientNetworkImage> createState() => _ResilientNetworkImageState();
}

class _ResilientNetworkImageState extends State<ResilientNetworkImage> {
  int _attempt = 0;

  @override
  void didUpdateWidget(covariant ResilientNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_listEquals(oldWidget.urls, widget.urls)) {
      _attempt = 0;
    }
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Map<String, String>? _headers() {
    final h = <String, String>{
      'User-Agent': 'Busify/1.0 (Flutter)',
    };
    if (widget.sendAuthBearer) {
      final t = ServiceLocator.tokenStorage.getToken();
      if (t != null && t.isNotEmpty) {
        h['Authorization'] = 'Bearer $t';
      }
    }
    return h;
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.urls;
    if (urls.isEmpty) return widget.fallback;

    final idx = _attempt.clamp(0, urls.length - 1);
    final url = urls[idx];

    return Image.network(
      url,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      headers: _headers(),
      errorBuilder: (context, error, stackTrace) {
        if (idx < urls.length - 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _attempt = idx + 1);
          });
          return ColoredBox(
            color: Colors.transparent,
            child: SizedBox(
              width: widget.width,
              height: widget.height,
            ),
          );
        }
        return widget.fallback;
      },
    );
  }
}
