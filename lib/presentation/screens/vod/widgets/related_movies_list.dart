import 'package:flutter/material.dart';
import 'package:shoof_iptv/data/models/movie_model.dart.dart';

class RelatedMoviesList extends StatelessWidget {
  final Future<List<MovieModel>> future;
  final void Function(MovieModel movie) onTapMovie;

  const RelatedMoviesList({
    super.key,
    required this.future,
    required this.onTapMovie,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MovieModel>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text(
            'لا توجد أفلام مشابهة حالياً',
            style: TextStyle(color: Colors.white70),
          );
        }

        final relatedMovies = snapshot.data!;
        final count = relatedMovies.length > 10 ? 10 : relatedMovies.length;

        return SizedBox(
          height: 190,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: count,
            itemBuilder: (context, index) {
              final related = relatedMovies[index];
              return GestureDetector(
                onTap: () => onTapMovie(related),
                child: Container(
                  width: 120,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[850],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                          child: Image.network(
                            related.streamIcon,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey,
                              child: const Icon(
                                Icons.broken_image,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text(
                          related.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
