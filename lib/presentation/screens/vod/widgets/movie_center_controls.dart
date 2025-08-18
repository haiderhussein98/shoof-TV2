import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class MovieCenterControls extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onReplay10;
  final VoidCallback onTogglePlay;
  final VoidCallback onForward10;

  const MovieCenterControls({
    super.key,
    required this.isPlaying,
    required this.onReplay10,
    required this.onTogglePlay,
    required this.onForward10,
  });

  @override
  Widget build(BuildContext context) {
    final backIcon =
        isCupertino(context) ? CupertinoIcons.gobackward_10 : Icons.replay_10;
    final fwdIcon =
        isCupertino(context) ? CupertinoIcons.goforward_10 : Icons.forward_10;
    final playIcon = isCupertino(context)
        ? CupertinoIcons.play_circle_fill
        : Icons.play_circle;
    final pauseIcon = isCupertino(context)
        ? CupertinoIcons.pause_circle_fill
        : Icons.pause_circle;

    return Positioned.fill(
      child: Column(
        children: [
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PlatformIconButton(
                icon: Icon(backIcon, color: Colors.white, size: 36),
                onPressed: onReplay10,
                material: (_, __) => MaterialIconButtonData(
                  splashRadius: 28,
                  constraints: BoxConstraints(minWidth: 48, minHeight: 48),
                ),
                cupertino: (_, __) => CupertinoIconButtonData(
                  padding: EdgeInsets.zero,
                  minimumSize: Size(0, 0),
                ),
              ),
              const SizedBox(width: 20),
              PlatformIconButton(
                icon: Icon(
                  isPlaying ? pauseIcon : playIcon,
                  color: Colors.white,
                  size: 50,
                ),
                onPressed: onTogglePlay,
                material: (_, __) => MaterialIconButtonData(
                  splashRadius: 32,
                  constraints: BoxConstraints(minWidth: 56, minHeight: 56),
                ),
                cupertino: (_, __) => CupertinoIconButtonData(
                  padding: EdgeInsets.zero,
                  minimumSize: Size(0, 0),
                ),
              ),
              const SizedBox(width: 20),
              PlatformIconButton(
                icon: Icon(fwdIcon, color: Colors.white, size: 36),
                onPressed: onForward10,
                material: (_, __) => MaterialIconButtonData(
                  splashRadius: 28,
                  constraints: BoxConstraints(minWidth: 48, minHeight: 48),
                ),
                cupertino: (_, __) => CupertinoIconButtonData(
                  padding: EdgeInsets.zero,
                  minimumSize: Size(0, 0),
                ),
              ),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
