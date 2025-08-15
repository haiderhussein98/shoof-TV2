import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
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
    final IconData calIcon = isCupertino(context)
        ? CupertinoIcons.calendar
        : Icons.calendar_today;
    final IconData catIcon = isCupertino(context)
        ? CupertinoIcons.square_grid_2x2
        : Icons.category;
    final IconData dirIcon = isCupertino(context)
        ? CupertinoIcons.film
        : Icons.movie_creation_outlined;
    final IconData castIcon = isCupertino(context)
        ? CupertinoIcons.person_2_fill
        : Icons.people;
    final IconData starIcon = isCupertino(context)
        ? CupertinoIcons.star_fill
        : Icons.star;

    return Column(
      children: [
        if (releaseDateText != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _InfoRow(
              icon: calIcon,
              iconColor: Colors.white70,
              text: releaseDateText!,
            ),
          ),
        if (genreText != null) ...[
          const SizedBox(height: 8),
          _InfoRow(icon: catIcon, iconColor: Colors.white70, text: genreText!),
        ],
        if ((directorText?.isNotEmpty ?? false)) ...[
          const SizedBox(height: 8),
          _InfoRow(
            icon: dirIcon,
            iconColor: Colors.white60,
            text: directorText!,
            prefix: "Director: ",
          ),
        ],
        if ((castText?.isNotEmpty ?? false)) ...[
          const SizedBox(height: 4),
          _InfoRow(
            icon: castIcon,
            iconColor: Colors.white60,
            text: castText!,
            prefix: "Cast: ",
          ),
        ],
        if (ratingText != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(starIcon, color: AppColors.primaryRed, size: 18),
              const SizedBox(width: 6),
              Text(ratingText!, style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ],
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;
  final String? prefix;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.text,
    this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            (prefix ?? '') + text,
            style: const TextStyle(color: Colors.white70),
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
        ),
      ],
    );
  }
}

