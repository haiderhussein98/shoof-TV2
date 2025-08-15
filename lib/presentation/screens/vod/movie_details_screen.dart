import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:shoof_tv/data/models/movie_model.dart';
import 'package:shoof_tv/domain/providers/vod_providers.dart';
import 'package:shoof_tv/presentation/screens/vod/movie_player_screen.dart';
import 'package:shoof_tv/presentation/screens/vod/widgets/related_movies_list.dart';

import 'widgets/movie_poster_play.dart';
import 'widgets/movie_meta_row.dart';
import 'widgets/movie_cast_overview.dart';

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

  bool _isUnknownLike(String? s) {
    if (s == null) return true;
    final v = s.trim().toLowerCase();
    return v.isEmpty ||
        v == 'unknown' ||
        v == 'n/a' ||
        v == 'بدون عنوان' ||
        v == 'غير متاح';
  }

  Map<String, dynamic> _toMap(dynamic obj) {
    try {
      if (obj is Map<String, dynamic>) return obj;
      final dyn = obj as dynamic;
      if (dyn?.toJson is Function) {
        final m = dyn.toJson();
        if (m is Map<String, dynamic>) return m;
      }
    } catch (_) {}
    return const {};
  }

  String? _readPathFromMap(Map<String, dynamic> m, List<String> path) {
    dynamic cur = m;
    for (final key in path) {
      if (cur is Map && cur.containsKey(key)) {
        cur = cur[key];
      } else {
        return null;
      }
    }
    return cur is String ? cur : null;
  }

  String _bestTitle(dynamic model, {dynamic fallback}) {
    final modelMap = _toMap(model);
    final fbMap = _toMap(fallback);

    const paths = <List<String>>[
      ['name'],
      ['title'],
      ['movie_name'],
      ['movieName'],
      ['original_title'],
      ['originalTitle'],
      ['streamDisplayName'],
      ['stream_name'],
      ['info', 'name'],
      ['info', 'title'],
      ['info', 'movie_name'],
      ['info', 'movieName'],
    ];

    final candidates = <String?>[];

    for (final p in paths) {
      candidates.add(_readPathFromMap(modelMap, p));
    }

    try {
      final n = (model as dynamic).name as String?;
      candidates.add(n);
    } catch (_) {}

    if (fallback != null) {
      for (final p in paths) {
        candidates.add(_readPathFromMap(fbMap, p));
      }
      try {
        final n2 = (fallback as dynamic).name as String?;
        candidates.add(n2);
      } catch (_) {}
    }

    for (final c in candidates) {
      if (!_isUnknownLike(c)) return c!.trim();
    }
    return 'بدون عنوان';
  }

  String _safeText(BuildContext context, String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'غير متاح';
    if (v.toLowerCase() == 'unknown' || v.toLowerCase() == 'n/a') {
      if (v.isEmpty) return 'غير متاح';
    }
    return v;
  }

  String _formatDateLocalized(BuildContext context, String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return 'غير متاح';
    try {
      final date = DateTime.parse(dateStr);
      final locale = Localizations.localeOf(context).toLanguageTag();
      final df = DateFormat('EEEE, dd MMMM yyyy', locale);
      return df.format(date);
    } catch (_) {
      return 'غير متاح';
    }
  }

  String _formatDuration(BuildContext context, String? durationRaw) {
    if (durationRaw == null || durationRaw.trim().isEmpty) {
      return 'غير متاح';
    }
    final s = durationRaw.trim();

    final colon = RegExp(r'^\s*(\d{1,2}):(\d{2})(?::(\d{2}))?\s*$');
    final m = colon.firstMatch(s);
    if (m != null) {
      final h = int.tryParse(m.group(1)!) ?? 0;
      final mi = int.tryParse(m.group(2)!) ?? 0;
      final se = int.tryParse(m.group(3) ?? '0') ?? 0;
      final totalMins = h * 60 + mi + (se >= 30 ? 1 : 0);
      return _arabicDuration(totalMins);
    }

    final digits = RegExp(r'\d+').firstMatch(s)?.group(0);
    if (digits == null) return 'غير متاح';
    final n = int.tryParse(digits) ?? 0;
    if (n <= 0) return 'غير متاح';

    final lower = s.toLowerCase();
    final looksSeconds = lower.contains('sec') ||
        lower.contains('second') ||
        RegExp(r'\b\d+\s*s\b').hasMatch(lower);

    if (looksSeconds || (!lower.contains('min') && n > 300)) {
      final totalMins = (n / 60).round();
      return _arabicDuration(totalMins);
    }

    return _arabicDuration(n);
  }

  String _arabicDuration(int totalMins) {
    final h = totalMins ~/ 60;
    final mi = totalMins % 60;
    if (h > 0 && mi > 0) return '$h ساعة $mi دقيقة';
    if (h > 0) return '$h ساعة';
    return '$mi دقيقة';
  }

  String _formatRating(BuildContext context, String? ratingRaw) {
    final s = _safeText(context, ratingRaw);
    if (s == 'غير متاح') return s;
    final n = double.tryParse(s);
    if (n != null) {
      return '${n.toStringAsFixed(n.truncateToDouble() == n ? 0 : 1)}/10';
    }
    return s;
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
        transitionDuration: const Duration(milliseconds: 360),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, __, ___) => MoviePlayerScreen(
          url: videoUrl,
          title: _bestTitle(movie, fallback: widget.movie),
        ),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.98, end: 1).animate(curved),
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
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (_, __, ___) => MovieDetailsScreen(movie: related),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
      ),
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

    return PlatformScaffold(
      backgroundColor: Colors.black,
      appBar: PlatformAppBar(
        title: FutureBuilder<MovieModel>(
          future: _movieDetailsFuture,
          builder: (context, snap) {
            final title = snap.hasData
                ? _bestTitle(snap.data!, fallback: widget.movie)
                : _bestTitle(widget.movie);
            return Text(
              title,
              style: const TextStyle(fontSize: 15),
              overflow: TextOverflow.ellipsis,
            );
          },
        ),
        material: (_, __) =>
            MaterialAppBarData(backgroundColor: Colors.transparent),
        cupertino: (_, __) =>
            CupertinoNavigationBarData(backgroundColor: Colors.transparent),
      ),
      body: FutureBuilder<MovieModel>(
        future: _movieDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: PlatformCircularProgressIndicator());
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
          final resolvedTitle = _bestTitle(movie, fallback: widget.movie);

          final double posterMaxWidth = wideLayout
              ? screen.width.clamp(0, maxContentWidth) * 0.28
              : screen.width * 0.86;
          final double posterClamped =
              wideLayout ? posterMaxWidth.clamp(280.0, 420.0) : posterMaxWidth;

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
                        displayTitle: resolvedTitle,
                        releaseText: _formatDateLocalized(
                          context,
                          movie.releaseDate,
                        ),
                        durationText: _formatDuration(context, movie.duration),
                        ratingText: _formatRating(context, movie.rating),
                        relatedMoviesFuture: _relatedMoviesFuture,
                        onPlay: () => _playMovie(movie),
                        onTapRelated: _openDetails,
                      )
                    : _MobileDetailsLayout(
                        posterWidth: posterClamped,
                        movie: movie,
                        displayTitle: resolvedTitle,
                        releaseText: _formatDateLocalized(
                          context,
                          movie.releaseDate,
                        ),
                        durationText: _formatDuration(context, movie.duration),
                        ratingText: _formatRating(context, movie.rating),
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
  final String displayTitle;
  final String releaseText;
  final String durationText;
  final String ratingText;
  final Future<List<MovieModel>> relatedMoviesFuture;
  final VoidCallback onPlay;
  final void Function(MovieModel) onTapRelated;

  const _DesktopDetailsLayout({
    required this.posterWidth,
    required this.movie,
    required this.displayTitle,
    required this.releaseText,
    required this.durationText,
    required this.ratingText,
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
                    displayTitle,
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
                    releaseText: releaseText,
                    durationText: durationText,
                    ratingText: ratingText,
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
  final String displayTitle;
  final String releaseText;
  final String durationText;
  final String ratingText;
  final Future<List<MovieModel>> relatedMoviesFuture;
  final VoidCallback onPlay;
  final void Function(MovieModel) onTapRelated;

  const _MobileDetailsLayout({
    required this.posterWidth,
    required this.movie,
    required this.displayTitle,
    required this.releaseText,
    required this.durationText,
    required this.ratingText,
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
          displayTitle,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        MovieMetaRow(
          releaseText: releaseText,
          durationText: durationText,
          ratingText: ratingText,
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
