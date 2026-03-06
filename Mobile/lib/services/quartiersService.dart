import 'package:google_maps_flutter/google_maps_flutter.dart';

class QuartiersService {
  static const Map<String, List<LatLng>> polygons = {
    'Gentilly-du Tremblay': [
      LatLng(45.57534, -73.4722),
      LatLng(45.56752, -73.45283),
      LatLng(45.55607, -73.43032),
      LatLng(45.5445, -73.43969),
      LatLng(45.53811, -73.44163),
      LatLng(45.53311, -73.43213),
      LatLng(45.52258, -73.43396),
      LatLng(45.52707, -73.44807),
      LatLng(45.53251, -73.46132),
      LatLng(45.53886, -73.45587),
      LatLng(45.54557, -73.45487),
      LatLng(45.55874, -73.47068),
      LatLng(45.56241, -73.47547),
      LatLng(45.56715, -73.48186),
    ],
    'Fatima': [
      LatLng(45.5754, -73.47241),
      LatLng(45.57814, -73.47621),
      LatLng(45.56801, -73.48813),
      LatLng(45.55162, -73.50038),
      LatLng(45.54599, -73.49234),
      LatLng(45.55106, -73.48435),
      LatLng(45.55265, -73.48546),
      LatLng(45.5557, -73.48458),
      LatLng(45.55844, -73.48678),
      LatLng(45.56056, -73.48542),
      LatLng(45.5655, -73.48351),
      LatLng(45.56912, -73.47989),
      LatLng(45.5754, -73.47241),
    ],
    'Sacré-Cœur': [
      LatLng(45.52484, -73.44308),
      LatLng(45.51982, -73.44553),
      LatLng(45.51716, -73.45163),
      LatLng(45.52928, -73.48146),
      LatLng(45.53718, -73.47729),
      LatLng(45.5369, -73.46841),
      LatLng(45.53285, -73.46299),
      LatLng(45.52484, -73.44308),
    ],
    'Bellerive-Collectivité Nouvelle': [
      LatLng(45.56695, -73.48204),
      LatLng(45.54557, -73.45515),
      LatLng(45.53915, -73.456),
      LatLng(45.53287, -73.46167),
      LatLng(45.53712, -73.46813),
      LatLng(45.53747, -73.47678),
      LatLng(45.54065, -73.48689),
      LatLng(45.54104, -73.49016),
      LatLng(45.54579, -73.49175),
      LatLng(45.55097, -73.48415),
      LatLng(45.55247, -73.48488),
      LatLng(45.55585, -73.48426),
      LatLng(45.55863, -73.48604),
      LatLng(45.56695, -73.48204),
    ],
    'Carillon-Saint-Pie-X': [
      LatLng(45.53734, -73.47766),
      LatLng(45.52965, -73.48167),
      LatLng(45.53579, -73.49685),
      LatLng(45.54128, -73.49133),
      LatLng(45.53734, -73.47766),
    ],
    'Vieux-Longueuil': [
      LatLng(45.55158, -73.50066),
      LatLng(45.54486, -73.49193),
      LatLng(45.54186, -73.4915),
      LatLng(45.53562, -73.49748),
      LatLng(45.53316, -73.4911),
      LatLng(45.5261, -73.49634),
      LatLng(45.52941, -73.50579),
      LatLng(45.53149, -73.51148),
      LatLng(45.52923, -73.51309),
      LatLng(45.53354, -73.52329),
      LatLng(45.5352, -73.52225),
    ],
    'Notre-Dame-de-Grâces': [
      LatLng(45.52927, -73.48174),
      LatLng(45.5331, -73.49087),
      LatLng(45.52582, -73.49629),
      LatLng(45.53122, -73.51132),
      LatLng(45.52904, -73.51283),
      LatLng(45.52002, -73.48795),
    ],
    'Saint-Vincent-de-Paul': [
      LatLng(45.52238, -73.48595),
      LatLng(45.52906, -73.4816),
      LatLng(45.52207, -73.46455),
      LatLng(45.51916, -73.46403),
      LatLng(45.51567, -73.46654),
    ],
    'Roberval': [
      LatLng(45.52235, -73.434),
      LatLng(45.51217, -73.43994),
      LatLng(45.51692, -73.45138),
      LatLng(45.51948, -73.44521),
      LatLng(45.52475, -73.44265),
      LatLng(45.52235, -73.434),
    ],
    'Saint-Jean-Vianney': [
      LatLng(45.52211, -73.48606),
      LatLng(45.51552, -73.46678),
      LatLng(45.50638, -73.47356),
      LatLng(45.50555, -73.48128),
      LatLng(45.50484, -73.48865),
      LatLng(45.51082, -73.4938),
    ],
    'Saint-Jude': [
      LatLng(45.53338, -73.52334),
      LatLng(45.53412, -73.52692),
      LatLng(45.51856, -73.52411),
      LatLng(45.51179, -73.5039),
      LatLng(45.51444, -73.50543),
      LatLng(45.52899, -73.51311),
    ],
    'Notre-Dame-de-la-Garde': [
      LatLng(45.51436, -73.50514),
      LatLng(45.51089, -73.4942),
      LatLng(45.51991, -73.48821),
      LatLng(45.52881, -73.51274),
    ],
    'Le Moyne': [
      LatLng(45.51408, -73.5049),
      LatLng(45.51173, -73.50351),
      LatLng(45.50966, -73.49811),
      LatLng(45.50824, -73.49691),
      LatLng(45.50241, -73.49231),
      LatLng(45.4951, -73.50002),
      LatLng(45.49301, -73.49708),
      LatLng(45.50175, -73.48797),
      LatLng(45.50471, -73.489),
      LatLng(45.51064, -73.49442),
    ],
    'Saint-Robert': [
      LatLng(45.50634, -73.47319),
      LatLng(45.50779, -73.44103),
      LatLng(45.51174, -73.44014),
      LatLng(45.52091, -73.46199),
      LatLng(45.52187, -73.46407),
      LatLng(45.51931, -73.46353),
    ],
  };

  static bool _pointInPolygon(LatLng p, List<LatLng> poly) {
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

  static String? fromLatLng(double lat, double lng) {
    final p = LatLng(lat, lng);
    for (final e in polygons.entries) {
      if (_pointInPolygon(p, e.value)) return e.key;
    }
    return null;
  }

  static LatLngBounds? boundsFor(String? quartier) {
    if (quartier == null) return null;
    final pts = polygons[quartier];
    if (pts == null || pts.isEmpty) return null;

    var minLat = pts.first.latitude;
    var maxLat = pts.first.latitude;
    var minLng = pts.first.longitude;
    var maxLng = pts.first.longitude;

    for (final p in pts) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
}