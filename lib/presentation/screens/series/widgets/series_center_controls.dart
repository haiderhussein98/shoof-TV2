import 'package:flutter/material.dart';

class SeriesCenterControls extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onReplay10;
  final VoidCallback onTogglePlay;
  final VoidCallback onForward10;

  const SeriesCenterControls({
    super.key,
    required this.isPlaying,
    required this.onReplay10,
    required this.onTogglePlay,
    required this.onForward10,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: false,
        child: Column(
          children: [
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.replay_10,
                    color: Colors.white,
                    size: 36,
                  ),
                  onPressed: onReplay10,
                ),
                const SizedBox(width: 20),
                IconButton(
                  icon: Icon(
                    isPlaying ? Icons.pause_circle : Icons.play_circle,
                    color: Colors.white,
                    size: 50,
                  ),
                  onPressed: onTogglePlay,
                ),
                const SizedBox(width: 20),
                IconButton(
                  icon: const Icon(
                    Icons.forward_10,
                    color: Colors.white,
                    size: 36,
                  ),
                  onPressed: onForward10,
                ),
              ],
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
