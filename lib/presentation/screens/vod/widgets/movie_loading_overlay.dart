import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

class MovieLoadingOverlay extends StatelessWidget {
  final VlcPlayerController controller;
  final bool showBlockingLoader;
  final bool isReopening;

  const MovieLoadingOverlay({
    super.key,
    required this.controller,
    required this.showBlockingLoader,
    required this.isReopening,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: true,
        child: ValueListenableBuilder<VlcPlayerValue>(
          valueListenable: controller,
          builder: (context, v, _) {
            final isLoading =
                showBlockingLoader || v.isBuffering || isReopening;
            return AnimatedOpacity(
              opacity: isLoading ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                color: Colors.black45,
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    PlatformCircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text(
                      'جاري التحميل...',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
