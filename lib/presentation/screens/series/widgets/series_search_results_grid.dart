import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../data/models/series_model.dart';
import '../series_details_screen.dart';

class SeriesSearchResultsGrid extends StatelessWidget {
  final List<SeriesModel> results;

  const SeriesSearchResultsGrid({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 900 ? 5 : (screenWidth > 600 ? 4 : 3);
    const spacing = 10.0;

    return GridView.builder(
      key: const PageStorageKey('series_search_grid'),
      padding: const EdgeInsets.all(12),
      cacheExtent: 150,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.7,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),

      itemCount: results.length,
      itemBuilder: (context, index) {
        final series = results[index];

        final gridWidth = screenWidth - (12 * 2);
        final tileW =
            (gridWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;
        final dpr = MediaQuery.of(context).devicePixelRatio;
        final memW = (tileW * dpr).clamp(220, 800).toInt();
        final memH = (memW * (3 / 2)).toInt();

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
            child: CachedNetworkImage(
              imageUrl: series.cover,
              fit: BoxFit.cover,
              memCacheWidth: memW,
              memCacheHeight: memH,
              maxWidthDiskCache: memW,
              maxHeightDiskCache: memH,
              fadeInDuration: Duration.zero,
              fadeOutDuration: Duration.zero,
              placeholderFadeInDuration: Duration.zero,
              filterQuality: FilterQuality.low,
              placeholder: (_, __) => const ColoredBox(
                color: Colors.black12,
                child: Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (_, __, ___) =>
                  const Icon(Icons.error, color: Colors.red),
            ),
          ),
        );
      },
    );
  }
}
