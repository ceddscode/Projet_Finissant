import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

class CategoryIcon extends StatelessWidget {
  final int categoryIndex;
  final double size;

  static const Map<int, String> categoryIconUrls = {
    0: 'https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72/1f9f9.png', // Propreté
    1: 'https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72/1f6cb.png', // Mobilier
    2: 'https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72/1f6a6.png', // Signalisation
    3: 'https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72/1f333.png', // EspacesVerts
    4: 'https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72/1f342.png', // Saisonnier
    5: 'https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72/1f465.png', // Social
  };

  const CategoryIcon({ super.key, required this.categoryIndex, this.size = 24.0});

  @override
  Widget build(BuildContext context) {
    final url = categoryIconUrls[categoryIndex];
    if (url == null) {
      return Icon(Icons.category, size: size);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 4),
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(Icons.category, size: size),
      ),
    );
  }
}

/// Utilitaire pour obtenir un BitmapDescriptor Twemoji pour une catégorie
Future<BitmapDescriptor> getCategoryMarkerIcon(int categoryIndex, {double size = 64}) async {
  final url = CategoryIcon.categoryIconUrls[categoryIndex];
  if (url == null) {
    return BitmapDescriptor.defaultMarker;
  }
  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final bytes = response.bodyBytes;
      return BitmapDescriptor.fromBytes(bytes);
    }
  } catch (_) {}
  return BitmapDescriptor.defaultMarker;
}
