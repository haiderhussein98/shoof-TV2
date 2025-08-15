import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class SeriesTopControls extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onRotate;

  const SeriesTopControls({
    super.key,
    required this.onBack,
    required this.onRotate,
  });

  @override
  Widget build(BuildContext context) {
    final backIcon = context.platformIcons.back;
    final rotateIcon = isCupertino(context)
        ? CupertinoIcons.refresh
        : Icons.screen_rotation;

    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                PlatformIconButton(
                  icon: Icon(backIcon, color: Colors.white),
                  onPressed: onBack,
                  material: (_, __) => MaterialIconButtonData(
                    splashRadius: 24,
                    constraints: BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                  cupertino: (_, __) => CupertinoIconButtonData(
                    padding: EdgeInsets.zero,
                    minimumSize: Size(0, 0),
                  ),
                ),
                const Spacer(),
                PlatformIconButton(
                  icon: Icon(rotateIcon, color: Colors.white),
                  onPressed: onRotate,
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
        ),
      ),
    );
  }
}

