import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shoof_iptv/domain/providers/series_providers.dart';
import '../../../../data/models/series_model.dart';
import '../series_details_screen.dart';
import '../category_series_screen.dart';

class SeriesCategorySection extends ConsumerStatefulWidget {
  final String categoryId;
  final String categoryName;
  final double screenWidth;

  const SeriesCategorySection({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.screenWidth,
  });

  @override
  ConsumerState<SeriesCategorySection> createState() =>
      _SeriesCategorySectionState();
}

class _SeriesCategorySectionState extends ConsumerState<SeriesCategorySection> {
  late Future<List<SeriesModel>> _seriesFuture;

  @override
  void initState() {
    super.initState();
    _seriesFuture = ref
        .read(seriesServiceProvider)
        .getSeriesByCategory(widget.categoryId, offset: 0, limit: 10);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.categoryName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CategorySeriesScreen(
                          categoryId: widget.categoryId,
                          categoryName: widget.categoryName,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.redAccent,
                  ),
                  label: const Text(
                    "مشاهدة الكل",
                    style: TextStyle(color: Colors.redAccent, fontSize: 13),
                  ),
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: widget.screenWidth > 600 ? 230 : 190,
            child: FutureBuilder<List<SeriesModel>>(
              future: _seriesFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final seriesList = snapshot.data!;
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: seriesList.length,
                  itemBuilder: (context, index) {
                    final series = seriesList[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SeriesDetailsScreen(series: series),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        width: widget.screenWidth > 900
                            ? 150
                            : widget.screenWidth > 600
                            ? 130
                            : 110,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CachedNetworkImage(
                            imageUrl: series.cover,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const ColoredBox(
                              color: Colors.black12,
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error, color: Colors.red),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
