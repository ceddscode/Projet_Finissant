class QuartierCoord {
  final String name;
  final double lat;
  final double lng;

  const QuartierCoord({required this.name, required this.lat, required this.lng});
}

class QuartierResolver {
  static const List<QuartierCoord> sectors = [
    QuartierCoord(name: "Bellerive-Collectivité Nouvelle", lat: 45.5175, lng: -73.5070),
    QuartierCoord(name: "Carillon-Saint-Pie-X", lat: 45.5160, lng: -73.4990),
    QuartierCoord(name: "Fatima", lat: 45.5130, lng: -73.4970),
    QuartierCoord(name: "Gentilly-du Tremblay", lat: 45.5090, lng: -73.4980),
    QuartierCoord(name: "Le Moyne", lat: 45.5019, lng: -73.4906),
    QuartierCoord(name: "Notre-Dame-de-Grâces", lat: 45.5180, lng: -73.4950),
    QuartierCoord(name: "Notre-Dame-de-la-Garde", lat: 45.5170, lng: -73.4940),
    QuartierCoord(name: "Roberval", lat: 45.5190, lng: -73.5000),
    QuartierCoord(name: "Sacré-Cœur", lat: 45.5140, lng: -73.5000),
    QuartierCoord(name: "Saint-Jean-Vianney", lat: 45.5150, lng: -73.5020),
    QuartierCoord(name: "Saint-Jude", lat: 45.5155, lng: -73.5040),
    QuartierCoord(name: "Saint-Robert", lat: 45.5120, lng: -73.4980),
    QuartierCoord(name: "Saint-Vincent-de-Paul", lat: 45.5145, lng: -73.5030),
    QuartierCoord(name: "Vieux-Longueuil", lat: 45.5167, lng: -73.5000),
  ];

  static String fromLatLng(double lat, double lng) {
    var best = sectors.first;
    var bestD = _dist2(lat, lng, best.lat, best.lng);

    for (var i = 1; i < sectors.length; i++) {
      final s = sectors[i];
      final d = _dist2(lat, lng, s.lat, s.lng);
      if (d < bestD) {
        best = s;
        bestD = d;
      }
    }

    return best.name;
  }

  static double _dist2(double lat1, double lng1, double lat2, double lng2) {
    final dx = lat1 - lat2;
    final dy = lng1 - lng2;
    return dx * dx + dy * dy;
  }
}