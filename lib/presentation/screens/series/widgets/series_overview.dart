import 'package:flutter/material.dart';

class SeriesOverviewTitle extends StatelessWidget {
  const SeriesOverviewTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      "Overview:",
      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    );
  }
}

class SeriesOverviewText extends StatelessWidget {
  final String text;
  const SeriesOverviewText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(color: Colors.white70));
  }
}
