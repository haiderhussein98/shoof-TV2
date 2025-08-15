﻿import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:shoof_tv/presentation/widgets/universal_player_desktop.dart';
import 'package:shoof_tv/presentation/widgets/universal_player_mobile.dart';

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
    final body = _isDesktop
        ? UniversalPlayerDesktop.movie(title: title, movieUrl: url)
        : UniversalPlayerMobile(
            type: ContentType.movie,
            title: title,
            url: url,
            logo: Image.asset('assets/images/logo.png', width: 40),
          );

    return PlatformScaffold(
      material: (_, __) => MaterialScaffoldData(backgroundColor: Colors.black),
      cupertino: (_, __) =>
          CupertinoPageScaffoldData(backgroundColor: Colors.black),
      body: body,
    );
  }
}

