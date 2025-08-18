import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

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
    final playIcon = isCupertino(context)
        ? CupertinoIcons.play_fill
        : Icons.play_arrow_rounded;

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
                    onPressed: onPlayFirst,
                    material: (_, __) => MaterialIconButtonData(
                      splashRadius: 34,
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
      ),
    );
  }
}
