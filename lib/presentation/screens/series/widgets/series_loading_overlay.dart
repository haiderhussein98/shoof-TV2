﻿import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

class SeriesLoadingOverlay extends StatelessWidget {
  final VlcPlayerController controller;
  final bool showBlockingLoader;
  final bool isReopening;

  const SeriesLoadingOverlay({
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
                  children: [
                    const PlatformCircularProgressIndicator(),
                    const SizedBox(height: 12),
                    const Text(
                      'Ø¬Ø§Ø±ÙŠ Ø§Ù„ØªØ­Ù…ÙŠÙ„...',
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

