import 'package:flutter/material.dart';
import 'package:shoof_tv/core/constants/colors.dart';

class SeriesMetaInfo extends StatelessWidget {
  final String? releaseDateText;
  final String? genreText;
  final String? directorText;
  final String? castText;
  final String? ratingText;

  const SeriesMetaInfo({
    super.key,
    this.releaseDateText,
    this.genreText,
    this.directorText,
    this.castText,
    this.ratingText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (releaseDateText != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: Colors.white70,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    releaseDateText!,
                    style: const TextStyle(color: Colors.white70),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ],
            ),
          ),
        if (genreText != null) ...[
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.category, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  genreText!,
                  style: const TextStyle(color: Colors.white70),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
              ),
            ],
          ),
        ],
        if ((directorText?.isNotEmpty ?? false)) ...[
          const SizedBox(height: 8),
          Text(
            "🎬 Director: $directorText",
            style: const TextStyle(color: Colors.white60),
          ),
        ],
        if ((castText?.isNotEmpty ?? false)) ...[
          const SizedBox(height: 4),
          Text(
            "👤 Cast: $castText",
            style: const TextStyle(color: Colors.white60),
          ),
        ],
        if (ratingText != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.star, color: AppColors.primaryRed, size: 18),
              const SizedBox(width: 6),
              Text(ratingText!, style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ],
      ],
    );
  }
}
