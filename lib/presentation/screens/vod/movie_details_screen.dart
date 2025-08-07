import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:shoof_iptv/data/models/movie_model.dart.dart';
import 'package:shoof_iptv/domain/providers/vod_providers.dart';
import 'package:shoof_iptv/presentation/screens/vod/movie_player_screen.dart';

import 'widgets/movie_poster_play.dart';
import 'widgets/movie_meta_row.dart';
import 'widgets/movie_cast_overview.dart';
import 'widgets/related_movies_list.dart';

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
    final all = await api.getVOD(offset: 0, limit: 4000);
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

  void _playMovie(MovieModel movie) {
    final api = ref.read(vodServiceProvider);
    final videoUrl = movie.getMovieUrl(
      api.serverUrl,
      api.username,
      api.password,
    );

    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) =>
            MoviePlayerScreen(url: videoUrl, title: movie.name),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.98, end: 1.0).animate(animation),
              child: child,
            ),
          );
        },
      ),
    );
  }

  void _openDetails(MovieModel related) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => MovieDetailsScreen(movie: related)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(widget.movie.name, style: const TextStyle(fontSize: 15)),
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
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MoviePosterPlay(
                  imageUrl: movie.streamIcon,
                  onPlay: () => _playMovie(movie),
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

                MovieMetaRow(
                  releaseText: formatDate(movie.releaseDate),
                  durationText: movie.duration ?? '0 min',
                  ratingText: movie.rating ?? 'N/A',
                ),
                const SizedBox(height: 14),

                MovieCastOverview(
                  cast: movie.cast,
                  overview: movie.description,
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

                RelatedMoviesList(
                  future: _relatedMoviesFuture,
                  onTapMovie: _openDetails,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
