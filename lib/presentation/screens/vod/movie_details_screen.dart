import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shoof_iptv/data/models/movie_model.dart.dart';
import 'package:shoof_iptv/domain/providers/vod_providers.dart';
import 'package:shoof_iptv/presentation/screens/vod/movie_player_screen.dart';

class MovieDetailsScreen extends ConsumerStatefulWidget {
  final MovieModel movie;

  const MovieDetailsScreen({super.key, required this.movie});

  @override
  ConsumerState<MovieDetailsScreen> createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends ConsumerState<MovieDetailsScreen> {
  late Future<MovieModel> _movieDetailsFuture;
  late Future<List<MovieModel>> _relatedMoviesFuture;

  @override
  void initState() {
    super.initState();
    final api = ref.read(vodServiceProvider);
    _movieDetailsFuture = api.getMovieDetails(widget.movie.streamId);
    _relatedMoviesFuture = _fetchRelatedMovies();
  }

  Future<List<MovieModel>> _fetchRelatedMovies() async {
    final api = ref.read(vodServiceProvider);
    final all = await api.getVOD(offset: 0, limit: 100);
    return all
        .where(
          (m) =>
              m.categoryId == widget.movie.categoryId &&
              m.streamId != widget.movie.streamId,
        )
        .toList();
  }

  String formatDate(String? dateStr) {
    try {
      final date = DateTime.parse(dateStr!);
      return DateFormat('EEEE, dd MMMM yyyy', 'en_US').format(date);
    } catch (_) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(widget.movie.name, style: TextStyle(fontSize: 15)),
      ),
      body: FutureBuilder<MovieModel>(
        future: _movieDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.hasError) {
            return const Center(
              child: Text(
                'فشل تحميل تفاصيل الفيلم',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final movie = snapshot.data!;
          final api = ref.read(vodServiceProvider);

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.network(
                          movie.streamIcon,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[800],
                            child: const Center(
                              child: Icon(
                                Icons.movie,
                                color: Colors.white54,
                                size: 40,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      iconSize: 64,
                      icon: const Icon(
                        Icons.play_circle_fill,
                        color: Colors.white70,
                      ),
                      onPressed: () {
                        final videoUrl = movie.getMovieUrl(
                          api.serverUrl,
                          api.username,
                          api.password,
                        );
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            transitionDuration: const Duration(
                              milliseconds: 400,
                            ),
                            pageBuilder: (_, __, ___) => MoviePlayerScreen(
                              url: videoUrl,
                              title: movie.name,
                            ),
                            transitionsBuilder: (_, animation, __, child) {
                              return FadeTransition(
                                opacity: animation,
                                child: ScaleTransition(
                                  scale: Tween<double>(
                                    begin: 0.98,
                                    end: 1.0,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Text(
                  movie.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),

                Wrap(
                  runSpacing: 8,
                  spacing: 16,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          formatDate(movie.releaseDate),
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          movie.duration ?? '0 min',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          movie.rating ?? 'N/A',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                if (movie.cast != null && movie.cast!.isNotEmpty) ...[
                  const Text(
                    "Cast:",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    movie.cast!,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 10),
                ],

                if (movie.description != null && movie.description!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Overview:",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        movie.description!,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),

                const SizedBox(height: 30),

                const Text(
                  'أفلام مشابهة',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                FutureBuilder<List<MovieModel>>(
                  future: _relatedMoviesFuture,
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
                    return SizedBox(
                      height: 190,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: relatedMovies.length.clamp(0, 10),
                        itemBuilder: (context, index) {
                          final related = relatedMovies[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      MovieDetailsScreen(movie: related),
                                ),
                              );
                            },
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
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
