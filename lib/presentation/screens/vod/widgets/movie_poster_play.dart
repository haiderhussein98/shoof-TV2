import 'package:flutter/material.dart';

class MoviePosterPlay extends StatelessWidget {
  final String imageUrl;
  final VoidCallback onPlay;

  const MoviePosterPlay({
    super.key,
    required this.imageUrl,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
              imageUrl,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey[800],
                child: const Center(
                  child: Icon(Icons.movie, color: Colors.white54, size: 40),
                ),
              ),
            ),
          ),
        ),
        IconButton(
          iconSize: 64,
          icon: const Icon(Icons.play_circle_fill, color: Colors.white70),
          onPressed: onPlay,
        ),
      ],
    );
  }
}
