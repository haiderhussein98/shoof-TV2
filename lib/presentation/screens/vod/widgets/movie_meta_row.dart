import 'package:flutter/material.dart';

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
    return Wrap(
      runSpacing: 8,
      spacing: 16,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today, color: Colors.white70, size: 16),
            const SizedBox(width: 6),
            Text(releaseText, style: const TextStyle(color: Colors.white70)),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.access_time, color: Colors.white70, size: 16),
            const SizedBox(width: 6),
            Text(durationText, style: const TextStyle(color: Colors.white70)),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 18),
            const SizedBox(width: 6),
            Text(ratingText, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ],
    );
  }
}
