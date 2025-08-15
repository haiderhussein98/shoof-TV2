﻿import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:shoof_tv/data/models/series_model.dart';

class SeriesOverviewTitle extends StatelessWidget {
  const SeriesOverviewTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return PlatformWidget(
      material: (_, __) => const Text(
        "ØªÙØ§ØµÙŠÙ„ Ø§Ù„Ù…Ø³Ù„Ø³Ù„",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      cupertino: (_, __) => const Text(
        "ØªÙØ§ØµÙŠÙ„ Ø§Ù„Ù…Ø³Ù„Ø³Ù„",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    );
  }
}

class SeriesOverviewText extends StatelessWidget {
  final SeriesModel series;
  final int? maxLines;

  const SeriesOverviewText({super.key, required this.series, this.maxLines});

  String _fallback(String? v) =>
      (v == null || v.trim().isEmpty) ? 'ØºÙŠØ± Ù…ØªÙˆÙØ±' : v.trim();

  @override
  Widget build(BuildContext context) {
    final overview = series.plot;
    final genre = series.genre;
    final director = series.director;
    final cast = series.cast;
    final rating = series.rating;
    final release = series.releaseDate;

    Widget line(String title, String? value) {
      final v = _fallback(value);
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: RichText(
          text: TextSpan(
            children: [
              const TextSpan(text: ""),
              TextSpan(
                text: "$title: ",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextSpan(
                text: v,
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final overviewWidget = (overview != null && overview.trim().isNotEmpty)
        ? Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 6),
            child: Text(
              overview.trim(),
              maxLines: maxLines,
              overflow: maxLines != null
                  ? TextOverflow.ellipsis
                  : TextOverflow.visible,
              style: const TextStyle(color: Colors.white70, height: 1.35),
            ),
          )
        : const SizedBox.shrink();

    return PlatformWidget(
      material: (_, __) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (overviewWidget is! SizedBox) ...[
            const Text(
              "Ø§Ù„Ù‚ØµØ©:",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            overviewWidget,
            const SizedBox(height: 10),
          ],
          line("Ø§Ù„Ù†ÙˆØ¹", genre),
          line("Ø§Ù„Ù…Ø®Ø±Ø¬", director),
          line("Ø§Ù„Ø£Ø¨Ø·Ø§Ù„", cast),
          line("Ø§Ù„ØªÙ‚ÙŠÙŠÙ…", rating),
          line("ØªØ§Ø±ÙŠØ® Ø§Ù„Ø¥ØµØ¯Ø§Ø±", release),
        ],
      ),
      cupertino: (_, __) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (overviewWidget is! SizedBox) ...[
            const Text(
              "Ø§Ù„Ù‚ØµØ©:",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            overviewWidget,
            const SizedBox(height: 10),
          ],
          line("Ø§Ù„Ù†ÙˆØ¹", genre),
          line("Ø§Ù„Ù…Ø®Ø±Ø¬", director),
          line("Ø§Ù„Ø£Ø¨Ø·Ø§Ù„", cast),
          line("Ø§Ù„ØªÙ‚ÙŠÙŠÙ…", rating),
          line("ØªØ§Ø±ÙŠØ® Ø§Ù„Ø¥ØµØ¯Ø§Ø±", release),
        ],
      ),
    );
  }
}

