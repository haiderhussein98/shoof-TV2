import 'package:flutter/material.dart';

class MoviePosterPlay extends StatelessWidget {
  final String imageUrl;
  final VoidCallback onPlay;
  final double borderRadius;
  final BoxFit fit;

  const MoviePosterPlay({
    super.key,
    required this.imageUrl,
    required this.onPlay,
    this.borderRadius = 14,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            color: Colors.black,
            child: Image.network(
              imageUrl,
              fit: fit,
              alignment: Alignment.center,
              errorBuilder: (_, __, ___) => const ColoredBox(
                color: Colors.black12,
                child: Center(
                  child: Icon(Icons.broken_image, color: Colors.white54),
                ),
              ),
            ),
          ),
        ),

        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPlay,
              child: const Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
