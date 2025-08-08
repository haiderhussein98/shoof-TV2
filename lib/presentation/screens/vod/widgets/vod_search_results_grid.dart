import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shoof_tv/presentation/screens/vod/viewmodel/vod_viewmodel.dart';
import '../../../../data/models/movie_model.dart.dart';
import '../movie_details_screen.dart';

class VodSearchResultsGrid extends ConsumerStatefulWidget {
  final Future<List<MovieModel>> searchResults;

  const VodSearchResultsGrid({super.key, required this.searchResults});

  @override
  ConsumerState<VodSearchResultsGrid> createState() =>
      _VodSearchResultsGridState();
}

class _VodSearchResultsGridState extends ConsumerState<VodSearchResultsGrid> {
  int? loadingIndex;
  bool _isNavigating = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return FutureBuilder<List<MovieModel>>(
      future: widget.searchResults,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final results = snapshot.data!;
        if (results.isEmpty) {
          return const Center(
            child: Text('لا توجد نتائج', style: TextStyle(color: Colors.white)),
          );
        }

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
            final movie = results[index];
            final isLoading = loadingIndex == index;

            return GestureDetector(
              onTap: () async {
                if (_isNavigating) return;

                setState(() {
                  _isNavigating = true;
                  loadingIndex = index;
                });

                try {
                  final movieDetails = await ref
                      .read(vodViewModelProvider)
                      .getMovieDetails(movie.streamId);

                  if (!context.mounted) return;

                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MovieDetailsScreen(movie: movieDetails),
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('فشل تحميل تفاصيل الفيلم'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                } finally {
                  if (mounted) {
                    setState(() {
                      _isNavigating = false;
                      loadingIndex = null;
                    });
                  }
                }
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: movie.streamIcon,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error, color: Colors.red),
                    ),
                  ),
                  if (isLoading)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha((0.6 * 255).toInt()),
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
            );
          },
        );
      },
    );
  }
}
