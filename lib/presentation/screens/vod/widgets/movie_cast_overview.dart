import 'package:flutter/material.dart';

class MovieCastOverview extends StatelessWidget {
  final String? cast;
  final String? overview;

  const MovieCastOverview({
    super.key,
    required this.cast,
    required this.overview,
  });

  @override
  Widget build(BuildContext context) {
    final widgets = <Widget>[];

    if (cast != null && cast!.isNotEmpty) {
      widgets.addAll([
        const Text(
          "Cast:",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(cast!, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 10),
      ]);
    }

    if (overview != null && overview!.isNotEmpty) {
      widgets.addAll([
        const Text(
          "Overview:",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(overview!, style: const TextStyle(color: Colors.white70)),
      ]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}
