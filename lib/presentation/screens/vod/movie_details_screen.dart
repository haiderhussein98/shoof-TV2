import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:shoof_tv/data/models/movie_model.dart.dart';
import 'package:shoof_tv/domain/providers/vod_providers.dart';
import 'package:shoof_tv/presentation/screens/vod/movie_player_screen.dart';

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
          (MovieModel m) =>
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

  bool get _isDesktop =>
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    const double maxContentWidth = 1200.0;
    final bool wideLayout = _isDesktop || screen.width >= 900;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          widget.movie.name,
          style: const TextStyle(fontSize: 15),
          overflow: TextOverflow.ellipsis,
        ),
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

          final double posterMaxWidth = wideLayout
              ? screen.width.clamp(0, maxContentWidth) * 0.28
              : screen.width * 0.86;
          final double posterClamped = wideLayout
              ? posterMaxWidth.clamp(280.0, 420.0)
              : posterMaxWidth;

          final EdgeInsets contentPadding = EdgeInsets.symmetric(
            horizontal: wideLayout ? 24 : 16,
            vertical: 16,
          );

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: maxContentWidth),
              child: SingleChildScrollView(
                padding: contentPadding,
                child: wideLayout
                    ? _DesktopDetailsLayout(
                        posterWidth: posterClamped,
                        movie: movie,
                        formatDate: formatDate,
                        relatedMoviesFuture: _relatedMoviesFuture,
                        onPlay: () => _playMovie(movie),
                        onTapRelated: _openDetails,
                      )
                    : _MobileDetailsLayout(
                        posterWidth: posterClamped,
                        movie: movie,
                        formatDate: formatDate,
                        relatedMoviesFuture: _relatedMoviesFuture,
                        onPlay: () => _playMovie(movie),
                        onTapRelated: _openDetails,
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DesktopDetailsLayout extends StatelessWidget {
  final double posterWidth;
  final MovieModel movie;
  final String Function(String?) formatDate;
  final Future<List<MovieModel>> relatedMoviesFuture;
  final VoidCallback onPlay;
  final void Function(MovieModel) onTapRelated;

  const _DesktopDetailsLayout({
    required this.posterWidth,
    required this.movie,
    required this.formatDate,
    required this.relatedMoviesFuture,
    required this.onPlay,
    required this.onTapRelated,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: posterWidth,
              child: AspectRatio(
                aspectRatio: 2 / 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: MoviePosterPlay(
                    imageUrl: movie.streamIcon,
                    onPlay: onPlay,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.name,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  MovieMetaRow(
                    releaseText: formatDate(movie.releaseDate),
                    durationText: movie.duration ?? '0 min',
                    ratingText: movie.rating ?? 'N/A',
                  ),
                  const SizedBox(height: 16),

                  MovieCastOverview(
                    cast: movie.cast,
                    overview: movie.description,
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 30),

        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'أفلام مشابهة',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),

        RelatedMoviesList(
          future: relatedMoviesFuture,
          onTapMovie: onTapRelated,
        ),
      ],
    );
  }
}

class _MobileDetailsLayout extends StatelessWidget {
  final double posterWidth;
  final MovieModel movie;
  final String Function(String?) formatDate;
  final Future<List<MovieModel>> relatedMoviesFuture;
  final VoidCallback onPlay;
  final void Function(MovieModel) onTapRelated;

  const _MobileDetailsLayout({
    required this.posterWidth,
    required this.movie,
    required this.formatDate,
    required this.relatedMoviesFuture,
    required this.onPlay,
    required this.onTapRelated,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: posterWidth,
            child: AspectRatio(
              aspectRatio: 2 / 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: MoviePosterPlay(
                  imageUrl: movie.streamIcon,
                  onPlay: onPlay,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        Text(
          movie.name,
          style: const TextStyle(
            fontSize: 22,
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

        MovieCastOverview(cast: movie.cast, overview: movie.description),

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
          future: relatedMoviesFuture,
          onTapMovie: onTapRelated,
        ),
      ],
    );
  }
}
