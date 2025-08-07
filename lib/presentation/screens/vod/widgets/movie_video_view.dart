import 'package:flutter/material.dart';
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
      child: Center(
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: VlcPlayer(
            controller: controller,
            aspectRatio: aspectRatio,
            placeholder: const Center(child: CircularProgressIndicator()),
          ),
        ),
      ),
    );
  }
}
