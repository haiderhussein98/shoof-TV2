import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

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
    final playIcon = isCupertino(context)
        ? CupertinoIcons.play_fill
        : Icons.play_arrow_rounded;

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
          child: Center(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: PlatformIconButton(
                  icon: Icon(playIcon, color: Colors.white, size: 48),
                  onPressed: onPlay,
                  material: (_, __) => MaterialIconButtonData(
                    splashRadius: 32,
                    constraints: BoxConstraints(minWidth: 0, minHeight: 0),
                  ),
                  cupertino: (_, __) => CupertinoIconButtonData(
                    padding: EdgeInsets.zero,
                    minimumSize: Size(0, 0),
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
