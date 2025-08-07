import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class SeriesHeaderPoster extends StatelessWidget {
  final String heroTag;
  final String coverUrl;
  final VoidCallback onPlayFirst;

  const SeriesHeaderPoster({
    super.key,
    required this.heroTag,
    required this.coverUrl,
    required this.onPlayFirst,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Hero(
          tag: heroTag,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: CachedNetworkImage(
                imageUrl: coverUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                errorWidget: (_, __, ___) => Container(
                  color: Colors.grey[800],
                  child: const Center(
                    child: Icon(Icons.tv, color: Colors.white54, size: 40),
                  ),
                ),
              ),
            ),
          ),
        ),
        IconButton(
          iconSize: 64,
          icon: const Icon(Icons.play_circle_fill, color: Colors.white70),
          onPressed: onPlayFirst,
        ),
      ],
    );
  }
}
