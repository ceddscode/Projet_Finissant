import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:municipalgo/http/dtos/transfer.dart';
import 'package:municipalgo/services/time_ago.dart';

class IncidentCard extends StatelessWidget {
  final Incident incident;
  final VoidCallback onLike;
  final double? distanceMeters;

  const IncidentCard({
    super.key,
    required this.incident,
    required this.onLike,
    this.distanceMeters,
  });

  static const String _placeholderUrl =
      "https://upload.wikimedia.org/wikipedia/commons/thumb/6/65/No-Image-Placeholder.svg/330px-No-Image-Placeholder.svg.png?20200912122019";

  @override
  Widget build(BuildContext context) {
    final d = distanceMeters ?? incident.distance?.toDouble();

    String? distanceLabel;
    if (d != null && d != double.infinity) {
      distanceLabel = d >= 1000
          ? '${(d / 1000).toStringAsFixed(0)} km'
          : '${d.toStringAsFixed(0)} m';
    }

    return RepaintBoundary(
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// IMAGE + HEART
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
                  child: incident.imagesUrl == null || incident.imagesUrl!.isEmpty
                      ? CachedNetworkImage(
                          imageUrl: _placeholderUrl,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.contain,
                          fadeInDuration: Duration.zero,
                          fadeOutDuration: Duration.zero,
                          useOldImageOnUrlChange: true,
                          placeholder: (ctx, url) => const SizedBox(
                            height: 160,
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                          errorWidget: (ctx, url, e) => const SizedBox(
                            height: 160,
                            child: Center(child: Icon(Icons.broken_image)),
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: incident.imagesUrl!.first,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          fadeInDuration: Duration.zero,
                          fadeOutDuration: Duration.zero,
                          useOldImageOnUrlChange: true,
                          placeholder: (ctx, url) => const SizedBox(
                            height: 160,
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                          errorWidget: (ctx, url, e) => CachedNetworkImage(
                            imageUrl: _placeholderUrl,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.contain,
                          ),
                        ),
                ),

                /// ❤️ LIKE BUTTON
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: onLike,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        incident.isLiked
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            /// TEXT CONTENT
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    incident.title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 6),

                  /// LOCATION
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(Icons.location_on,
                            size: 16, color: Colors.grey),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          incident.location,
                          style: const TextStyle(color: Colors.grey),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (distanceLabel != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          distanceLabel,
                          style: const TextStyle(
                              color: Colors.black, fontSize: 12),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 6),

                  /// DATE + LIKE COUNT
                  Row(
                    children: [
                      Text(
                        TimeAgo.format(context, incident.createdAt),
                        style: const TextStyle(
                            color: Colors.redAccent, fontSize: 12),
                      ),

                      const Spacer(),


                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
