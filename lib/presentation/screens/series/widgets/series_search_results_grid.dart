import 'package:flutter/material.dart';
import '../../../../data/models/series_model.dart';
import '../series_details_screen.dart';

class SeriesSearchResultsGrid extends StatelessWidget {
  final List<SeriesModel> results;
  final double screenWidth;

  const SeriesSearchResultsGrid({
    super.key,
    required this.results,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: screenWidth > 900
            ? 5
            : screenWidth > 600
            ? 4
            : 3,
        childAspectRatio: 0.7,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final series = results[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SeriesDetailsScreen(series: series),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              series.cover,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.error, color: Colors.red),
            ),
          ),
        );
      },
    );
  }
}
