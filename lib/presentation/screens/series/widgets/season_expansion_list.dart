import 'package:flutter/material.dart';
import 'episode_tile.dart';

class SeasonExpansionList extends StatelessWidget {
  final Map<String, List<Map<String, dynamic>>> episodesBySeason;
  final void Function(dynamic episodeId, String episodeName) onPlayEpisode;
  final Color titleColor;

  const SeasonExpansionList({
    super.key,
    required this.episodesBySeason,
    required this.onPlayEpisode,
    required this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: episodesBySeason.entries.map((entry) {
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
              style: TextStyle(
                color: titleColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            collapsedIconColor: Colors.white54,
            iconColor: titleColor,
            children: episodes.map((episode) {
              final episodeName = episode['title'] ?? '';
              final episodeId = episode['id'];
              return EpisodeTile(
                episodeName: episodeName,
                onPlay: () => onPlayEpisode(episodeId, episodeName),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}
