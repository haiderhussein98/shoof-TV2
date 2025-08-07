import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shoof_iptv/core/constants/colors.dart';
import 'package:shoof_iptv/data/models/series_model.dart';
import 'package:shoof_iptv/data/services/series_service.dart';
import 'package:shoof_iptv/domain/providers/series_providers.dart';
import 'package:shoof_iptv/presentation/screens/series/series_player_screen.dart';

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

  @override
  void initState() {
    super.initState();
    api = ref.read(seriesServiceProvider);
    _episodesFuture = api.getSeriesInfo(widget.series.seriesId);
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
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            SeriesPlayerScreen(url: videoUrl, title: title),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(opacity: anim, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final series = widget.series;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(series.name, style: TextStyle(fontSize: 15)),
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
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Hero(
                      tag: 'series_${series.seriesId}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: CachedNetworkImage(
                            imageUrl: series.cover,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.grey[800],
                              child: const Center(
                                child: Icon(
                                  Icons.tv,
                                  color: Colors.white54,
                                  size: 40,
                                ),
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
                  ],
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

                if (series.releaseDate != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            formatDate(series.releaseDate!),
                            style: const TextStyle(color: Colors.white70),
                            softWrap: true,
                            overflow: TextOverflow.visible,
                          ),
                        ),
                      ],
                    ),
                  ),

                if (series.genre != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.category,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          series.genre!,
                          style: const TextStyle(color: Colors.white70),
                          softWrap: true,
                          overflow: TextOverflow.visible,
                        ),
                      ),
                    ],
                  ),
                ],

                if (series.director?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 8),
                  Text(
                    "🎬 Director: ${series.director!}",
                    style: const TextStyle(color: Colors.white60),
                  ),
                ],
                if (series.cast?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 4),
                  Text(
                    "👤 Cast: ${series.cast!}",
                    style: const TextStyle(color: Colors.white60),
                  ),
                ],
                if (series.rating != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: AppColors.primaryRed,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        series.rating!,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ],
                if (series.plot?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 16),
                  const Text(
                    "Overview:",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    series.plot!,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
                const SizedBox(height: 30),
                ...episodesBySeason.entries.map((entry) {
                  final season = entry.key;
                  final episodes = entry.value;

                  return Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                      unselectedWidgetColor: Colors.white70,
                      colorScheme: const ColorScheme.dark(),
                    ),
                    child: ExpansionTile(
                      title: Text(
                        "Season $season",
                        style: const TextStyle(
                          color: AppColors.primaryRed,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      collapsedIconColor: Colors.white54,
                      iconColor: AppColors.primaryRed,
                      children: episodes.map((episode) {
                        final episodeName = episode['title'] ?? '';
                        final episodeId = episode['id'];
                        final videoUrl = series.getEpisodeUrl(
                          api.serverUrl,
                          api.username,
                          api.password,
                          int.tryParse(episodeId.toString()) ?? 0,
                        );

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                          leading: const Icon(
                            Icons.tv,
                            color: AppColors.primaryRed,
                          ),
                          title: Text(
                            episodeName,
                            style: const TextStyle(color: Colors.white),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.play_circle_fill,
                              color: AppColors.primaryRed,
                              size: 28,
                            ),
                            onPressed: () =>
                                _playEpisode(context, videoUrl, episodeName),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}
