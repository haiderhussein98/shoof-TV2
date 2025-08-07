import 'package:flutter/material.dart';
import 'package:shoof_iptv/core/constants/colors.dart';

class EpisodeTile extends StatelessWidget {
  final String episodeName;
  final VoidCallback onPlay;

  const EpisodeTile({
    super.key,
    required this.episodeName,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: const Icon(Icons.tv, color: AppColors.primaryRed),
      title: Text(episodeName, style: const TextStyle(color: Colors.white)),
      trailing: IconButton(
        icon: const Icon(
          Icons.play_circle_fill,
          color: AppColors.primaryRed,
          size: 28,
        ),
        onPressed: onPlay,
      ),
    );
  }
}
