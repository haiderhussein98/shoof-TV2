import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:shoof_tv/core/constants/colors.dart';

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
    final tvIcon = isCupertino(context) ? CupertinoIcons.tv : Icons.tv;
    final playIcon = isCupertino(context)
        ? CupertinoIcons.play_circle_fill
        : Icons.play_circle_fill;

    return PlatformWidget(
      material: (_, __) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        leading: Icon(tvIcon, color: AppColors.primaryRed),
        title: Text(episodeName, style: const TextStyle(color: Colors.white)),
        trailing: PlatformIconButton(
          icon: Icon(playIcon, color: AppColors.primaryRed, size: 28),
          onPressed: onPlay,
          material: (_, __) => MaterialIconButtonData(
            splashRadius: 24,
            constraints: BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          cupertino: (_, __) => CupertinoIconButtonData(
            padding: EdgeInsets.zero,
            minimumSize: Size(0, 0),
          ),
        ),
      ),
      cupertino: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(tvIcon, color: AppColors.primaryRed),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                episodeName,
                style: const TextStyle(color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            PlatformIconButton(
              icon: Icon(playIcon, color: AppColors.primaryRed, size: 28),
              onPressed: onPlay,
              material: (_, __) => MaterialIconButtonData(
                splashRadius: 24,
                constraints: BoxConstraints(minWidth: 40, minHeight: 40),
              ),
              cupertino: (_, __) => CupertinoIconButtonData(
                padding: EdgeInsets.zero,
                minimumSize: Size(0, 0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
