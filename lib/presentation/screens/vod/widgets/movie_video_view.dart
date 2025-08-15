import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

class MovieVideoView extends StatelessWidget {
  final VlcPlayerController controller;
  final double aspectRatio;

  const MovieVideoView({
    super.key,
    required this.controller,
    required this.aspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxW = constraints.maxWidth;
          final maxH = constraints.maxHeight;

          if (aspectRatio <= 0 || aspectRatio.isNaN) {
            return VlcPlayer(
              controller: controller,
              aspectRatio: maxW / maxH,
              placeholder: const Center(
                child: PlatformCircularProgressIndicator(),
              ),
            );
          }

          final containerAR = maxW / maxH;
          final videoAR = aspectRatio;

          double childW, childH;

          if (videoAR >= containerAR) {
            childH = maxH;
            childW = childH * videoAR;
          } else {
            childW = maxW;
            childH = childW / videoAR;
          }

          return ClipRect(
            child: Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: childW,
                height: childH,
                child: VlcPlayer(
                  controller: controller,
                  aspectRatio: videoAR,
                  placeholder: const Center(
                    child: PlatformCircularProgressIndicator(),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

