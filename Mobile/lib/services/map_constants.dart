import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapConstants {
  MapConstants._();

  static final LatLngBounds longueuilBounds = LatLngBounds(
    southwest: const LatLng(45.45, -73.58),
    northeast: const LatLng(45.60, -73.36),
  );

  static const CameraPosition initialPosition = CameraPosition(
    target: LatLng(45.53, -73.45),
    zoom: 11.6,
  );

  static final CameraTargetBounds cameraBounds = CameraTargetBounds(longueuilBounds);
  static const MinMaxZoomPreference zoomPreference = MinMaxZoomPreference(10.8, 17);

  static const String mapStyle = '''
[
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]}
]
''';
}