import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart' as latlng;

gmaps.LatLng toGoogleLatLng(latlng.LatLng point) =>
    gmaps.LatLng(point.latitude, point.longitude);

List<gmaps.LatLng> toGoogleLatLngList(List<latlng.LatLng> points) =>
    points.map(toGoogleLatLng).toList();
