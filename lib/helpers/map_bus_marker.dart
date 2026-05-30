import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

/// Same 🚌 marker as the Busify website map (32px emoji, not the large bus asset).
class MapBusMarker {
  MapBusMarker._();

  static gmaps.BitmapDescriptor? _icon;
  static Future<gmaps.BitmapDescriptor>? _loading;

  static Future<gmaps.BitmapDescriptor> icon() {
    final cached = _icon;
    if (cached != null) return Future.value(cached);
    return _loading ??= _load();
  }

  static Future<gmaps.BitmapDescriptor> _load() async {
    const size = 32.0;
    const emoji = '🚌';

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        fontSize: 22,
        textAlign: TextAlign.center,
      ),
    )..addText(emoji);
    final paragraph = builder.build()
      ..layout(ui.ParagraphConstraints(width: size));
    canvas.drawParagraph(paragraph, Offset.zero);

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.ceil(), size.ceil());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      return gmaps.BitmapDescriptor.defaultMarkerWithHue(
        gmaps.BitmapDescriptor.hueOrange,
      );
    }

    final loaded = gmaps.BitmapDescriptor.bytes(
      byteData.buffer.asUint8List(),
      width: size,
      height: size,
    );
    _icon = loaded;
    return loaded;
  }
}
