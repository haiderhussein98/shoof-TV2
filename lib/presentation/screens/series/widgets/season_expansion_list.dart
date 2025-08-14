import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
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

        return PlatformWidget(
          material: (_, __) => Theme(
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
          ),
          cupertino: (_, __) => _CupertinoExpandableSeason(
            title: "Season $season",
            titleColor: titleColor,
            episodes: episodes,
            onPlayEpisode: onPlayEpisode,
          ),
        );
      }).toList(),
    );
  }
}

class _CupertinoExpandableSeason extends StatefulWidget {
  final String title;
  final Color titleColor;
  final List<Map<String, dynamic>> episodes;
  final void Function(dynamic episodeId, String episodeName) onPlayEpisode;

  const _CupertinoExpandableSeason({
    required this.title,
    required this.titleColor,
    required this.episodes,
    required this.onPlayEpisode,
  });

  @override
  State<_CupertinoExpandableSeason> createState() =>
      _CupertinoExpandableSeasonState();
}

class _CupertinoExpandableSeasonState
    extends State<_CupertinoExpandableSeason> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final IconData chevron = isCupertino(context)
        ? (_expanded
              ? CupertinoIcons.chevron_down
              : CupertinoIcons.chevron_right)
        : (_expanded ? Icons.expand_more : Icons.chevron_right);

    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      color: widget.titleColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Icon(chevron, color: widget.titleColor),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Column(
            children: widget.episodes.map((episode) {
              final episodeName = episode['title'] ?? '';
              final episodeId = episode['id'];
              return EpisodeTile(
                episodeName: episodeName,
                onPlay: () => widget.onPlayEpisode(episodeId, episodeName),
              );
            }).toList(),
          ),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 220),
        ),
      ],
    );
  }
}
