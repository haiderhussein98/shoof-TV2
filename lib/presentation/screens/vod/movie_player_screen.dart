import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';

import 'widgets/movie_player_mobile.dart';
import 'widgets/movie_player_desktop.dart';

class MoviePlayerScreen extends StatelessWidget {
  final String url;
  final String title;

  const MoviePlayerScreen({super.key, required this.url, required this.title});

  bool get _isDesktop =>
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      body: LayoutBuilder(
        builder: (context, constraints) {
          if (_isDesktop) {
            return MoviePlayerDesktop(url: url, title: title);
          } else {
            return MoviePlayerMobile(url: url, title: title);
          }
        },
      ),
    );
  }
}
