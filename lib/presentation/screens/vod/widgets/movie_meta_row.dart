import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class MovieMetaRow extends StatelessWidget {
  final String releaseText;
  final String durationText;
  final String ratingText;

  const MovieMetaRow({
    super.key,
    required this.releaseText,
    required this.durationText,
    required this.ratingText,
  });

  @override
  Widget build(BuildContext context) {
    final releaseIcon =
        isCupertino(context) ? CupertinoIcons.calendar : Icons.calendar_today;
    final durationIcon =
        isCupertino(context) ? CupertinoIcons.time : Icons.access_time;
    final ratingIcon =
        isCupertino(context) ? CupertinoIcons.star_fill : Icons.star;

    return Wrap(
      runSpacing: 8,
      spacing: 16,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(releaseIcon, color: Colors.white70, size: 16),
            const SizedBox(width: 6),
            Text(releaseText, style: const TextStyle(color: Colors.white70)),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(durationIcon, color: Colors.white70, size: 16),
            const SizedBox(width: 6),
            Text(durationText, style: const TextStyle(color: Colors.white70)),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(ratingIcon, color: Colors.amber, size: 18),
            const SizedBox(width: 6),
            Text(ratingText, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ],
    );
  }
}
