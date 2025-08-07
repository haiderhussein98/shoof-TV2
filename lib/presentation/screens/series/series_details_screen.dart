import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shoof_iptv/core/constants/colors.dart';
import 'package:shoof_iptv/data/models/series_model.dart';
import 'package:shoof_iptv/data/services/series_service.dart';
import 'package:shoof_iptv/domain/providers/series_providers.dart';
import 'package:shoof_iptv/presentation/screens/series/series_player_screen.dart';

import 'widgets/series_header_poster.dart';
import 'widgets/series_meta_info.dart';
import 'widgets/series_overview.dart';
import 'widgets/season_expansion_list.dart';

class SeriesDetailsScreen extends ConsumerStatefulWidget {
  final SeriesModel series;

  const SeriesDetailsScreen({super.key, required this.series});

  @override
  ConsumerState<SeriesDetailsScreen> createState() =>
      _SeriesDetailsScreenState();
}

class _SeriesDetailsScreenState extends ConsumerState<SeriesDetailsScreen> {
  late Future<Map<String, List<Map<String, dynamic>>>> _episodesFuture;
  late final SeriesService api;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    api = ref.read(seriesServiceProvider);

    _episodesFuture = api.getSeriesInfo(widget.series.seriesId).catchError((e) {
      return <String, List<Map<String, dynamic>>>{};
    });
  }

  String formatDate(String dateStr) {
    try {
      final parsed = DateFormat('EEEE, dd MMMM yyyy').parse(dateStr);
      return DateFormat('EEEE, dd MMMM yyyy', 'en_US').format(parsed);
    } catch (_) {
      return dateStr;
    }
  }

  void _playEpisode(BuildContext context, String videoUrl, String title) {
    if (!mounted || _disposed) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            SeriesPlayerScreen(url: videoUrl, title: title),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final series = widget.series;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(series.name, style: const TextStyle(fontSize: 15)),
        backgroundColor: Colors.black,
      ),
      body: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
        future: _episodesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'حدث خطأ أثناء تحميل تفاصيل المسلسل',
                style: TextStyle(color: Colors.redAccent),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'لا توجد حلقات متاحة لهذا المسلسل',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final episodesBySeason = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SeriesHeaderPoster(
                  heroTag: 'series_${series.seriesId}',
                  coverUrl: series.cover,
                  onPlayFirst: () {
                    if (!mounted || _disposed) return;
                    final firstSeason = episodesBySeason.entries.first;
                    final firstEpisode = firstSeason.value.first;
                    final videoUrl = series.getEpisodeUrl(
                      api.serverUrl,
                      api.username,
                      api.password,
                      int.tryParse(firstEpisode['id'].toString()) ?? 0,
                    );
                    _playEpisode(
                      context,
                      videoUrl,
                      firstEpisode['title'] ?? '',
                    );
                  },
                ),
                const SizedBox(height: 20),

                Text(
                  series.name,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),

                SeriesMetaInfo(
                  releaseDateText: series.releaseDate == null
                      ? null
                      : formatDate(series.releaseDate!),
                  genreText: series.genre,
                  directorText: series.director,
                  castText: series.cast,
                  ratingText: series.rating,
                ),

                if (series.plot?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 16),
                  const SeriesOverviewTitle(),
                  const SizedBox(height: 4),
                  SeriesOverviewText(text: series.plot!),
                ],

                const SizedBox(height: 30),

                SeasonExpansionList(
                  episodesBySeason: episodesBySeason,
                  titleColor: AppColors.primaryRed,
                  onPlayEpisode: (episodeId, episodeName) {
                    if (!mounted || _disposed) return;
                    final videoUrl = series.getEpisodeUrl(
                      api.serverUrl,
                      api.username,
                      api.password,
                      int.tryParse(episodeId.toString()) ?? 0,
                    );
                    _playEpisode(context, videoUrl, episodeName);
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
