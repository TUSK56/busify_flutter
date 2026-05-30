import 'package:application/constants/app_images.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

/// Cached bus marker icon for live trip maps (replaces default blue pin).
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
    final loaded = await gmaps.BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(56, 56)),
      AppImages.bus,
    );
    _icon = loaded;
    return loaded;
  }
}
