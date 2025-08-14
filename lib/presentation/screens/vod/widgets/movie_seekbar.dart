import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class MovieSeekbar extends StatelessWidget {
  final Duration position;
  final Duration duration;
  final String Function(Duration) formatTime;
  final ValueChanged<int> onSeek;

  const MovieSeekbar({
    super.key,
    required this.position,
    required this.duration,
    required this.formatTime,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    final int posSec = position.inSeconds;
    final int maxSec = duration.inSeconds > 0
        ? duration.inSeconds
        : (posSec + 1);
    final double value = posSec.clamp(0, maxSec).toDouble();
    final double max = maxSec.toDouble();

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16),
        child: Column(
          children: [
            PlatformWidget(
              material: (_, __) => Slider(
                value: value,
                max: max,
                onChanged: duration.inSeconds > 0
                    ? (v) => onSeek(v.toInt())
                    : null,
              ),
              cupertino: (_, __) => CupertinoSlider(
                value: value,
                min: 0,
                max: max,
                onChanged: duration.inSeconds > 0
                    ? (v) => onSeek(v.toInt())
                    : null,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatTime(Duration(seconds: value.toInt())),
                  style: const TextStyle(color: Colors.white),
                ),
                Text(
                  duration.inSeconds > 0 ? formatTime(duration) : '--:--',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
