import 'package:flutter/material.dart';

class SeriesSeekbar extends StatelessWidget {
  final Duration position;
  final Duration duration;
  final String Function(Duration) formatTime;
  final void Function(int seconds) onSeek;

  const SeriesSeekbar({
    super.key,
    required this.position,
    required this.duration,
    required this.formatTime,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
        child: Column(
          children: [
            Slider(
              value: position.inSeconds.toDouble(),
              max:
                  (duration.inSeconds > 0
                          ? duration.inSeconds
                          : position.inSeconds + 1)
                      .toDouble(),
              onChanged: duration.inSeconds > 0
                  ? (v) => onSeek(v.toInt())
                  : null,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatTime(position),
                  style: const TextStyle(color: Colors.white),
                ),
                Text(
                  duration.inSeconds > 0 ? formatTime(duration) : '--:--',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
