import 'package:flutter/material.dart';

/// Widget réutilisable pour afficher une poignée de bottom sheet
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

/// Widget réutilisable pour afficher un avatar anonyme
class AnonymousAvatar extends StatelessWidget {
  final double radius;
  final double iconSize;

  const AnonymousAvatar({
    super.key,
    this.radius = 16,
    this.iconSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      child: Icon(Icons.person, size: iconSize),
    );
  }
}

/// Badge pour afficher le compteur de pages d'images
class ImagePageBadge extends StatelessWidget {
  final int currentPage;
  final int totalPages;

  const ImagePageBadge({
    super.key,
    required this.currentPage,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$currentPage/$totalPages',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
