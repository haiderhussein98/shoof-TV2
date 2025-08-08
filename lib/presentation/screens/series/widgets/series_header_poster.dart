import 'package:flutter/material.dart';

class SeriesHeaderPoster extends StatelessWidget {
  final String heroTag;
  final String? coverUrl;
  final VoidCallback onPlayFirst;
  final double borderRadius;
  final BoxFit fit;
  final double aspectRatio;

  const SeriesHeaderPoster({
    super.key,
    required this.heroTag,
    required this.coverUrl,
    required this.onPlayFirst,
    this.borderRadius = 14,
    this.fit = BoxFit.cover,
    this.aspectRatio = 2 / 3,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Container(
              color: Colors.black,
              child: (coverUrl == null || coverUrl!.isEmpty)
                  ? const SizedBox.expand()
                  : Image.network(
                      coverUrl!,
                      fit: fit,
                      alignment: Alignment.center,
                    ),
            ),
          ),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPlayFirst,
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
      ),
    );
  }
}
