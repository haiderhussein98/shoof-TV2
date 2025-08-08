import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoof_tv/data/models/movie_model.dart.dart';
import 'package:shoof_tv/domain/providers/vod_providers.dart';
import 'package:shoof_tv/presentation/screens/vod/category_movies_screen.dart';
import 'package:shoof_tv/presentation/screens/vod/movie_details_screen.dart';

class CategorySection extends ConsumerWidget {
  final String categoryId;
  final String categoryName;
  final double screenWidth;
  final int? loadingIndex;
  final void Function(int?) onSetLoading;

  const CategorySection({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.screenWidth,
    required this.loadingIndex,
    required this.onSetLoading,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moviesFuture = ref
        .read(vodServiceProvider)
        .getMoviesByCategory(categoryId, offset: 0, limit: 20);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          SizedBox(
            height: screenWidth > 600 ? 230 : 190,
            child: FutureBuilder<List<MovieModel>>(
              future: moviesFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final movies = snapshot.data!;
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: movies.length,
                  itemBuilder: (context, index) {
                    final movie = movies[index];
                    final isLoading = loadingIndex == index;

                    return GestureDetector(
                      onTap: () async {
                        if (loadingIndex != null) return;

                        onSetLoading(index);

                        try {
                          final movieDetails = await ref
                              .read(vodServiceProvider)
                              .getMovieDetails(movie.streamId);

                          if (!context.mounted) return;

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  MovieDetailsScreen(movie: movieDetails),
                            ),
                          );
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('فشل تحميل تفاصيل الفيلم'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        } finally {
                          onSetLoading(null);
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        width: screenWidth > 900
                            ? 150
                            : screenWidth > 600
                            ? 130
                            : 110,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: CachedNetworkImage(
                                imageUrl: movie.streamIcon,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const ColoredBox(
                                  color: Colors.black12,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.error, color: Colors.red),
                              ),
                            ),
                            if (isLoading)
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(
                                    (0.6 * 255).toInt(),
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ),
                          ],
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              categoryName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CategoryMoviesScreen(
                    categoryId: categoryId,
                    categoryName: categoryName,
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
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              minimumSize: Size.zero,
            ),
          ),
        ],
      ),
    );
  }
}
