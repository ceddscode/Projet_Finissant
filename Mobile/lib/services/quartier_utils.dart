import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:municipalgo/services/quartiersService.dart';

Set<Polygon> buildQuartierPolygons(String? selectedNeighborhood) {
  final polygonsMap = QuartiersService.polygons;
  final q = selectedNeighborhood;
  if (q == null) return {};
  final pts = polygonsMap[q];
  if (pts == null || pts.isEmpty) return {};

  return {
    Polygon(
      polygonId: PolygonId(q),
      points: pts,
      strokeWidth: 4,
      strokeColor: const Color(0xFF448AFF),
      geodesic: true,
      fillColor: Colors.transparent,
    ),
  };
}

bool pointInPolygon(LatLng p, List<LatLng> poly) {
  final x = p.longitude;
  final y = p.latitude;
  var inside = false;

  for (int i = 0, j = poly.length - 1; i < poly.length; j = i++) {
    final xi = poly[i].longitude, yi = poly[i].latitude;
    final xj = poly[j].longitude, yj = poly[j].latitude;

    final intersect = ((yi > y) != (yj > y)) &&
        (x < (xj - xi) * (y - yi) / (yj - yi + 0.0) + xi);

    if (intersect) inside = !inside;
  }

  return inside;
}

String? quartierFromPolygons(double lat, double lng) {
  final p = LatLng(lat, lng);
  for (final e in QuartiersService.polygons.entries) {
    if (pointInPolygon(p, e.value)) return e.key;
  }
  return null;
}
