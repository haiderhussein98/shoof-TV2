import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';

import 'widgets/series_player_desktop.dart';
import 'widgets/series_player_mobile.dart';

class SeriesPlayerScreen extends StatelessWidget {
  final String serverUrl;
  final String username;
  final String password;
  final int episodeId;
  final String containerExtension;
  final String title;

  const SeriesPlayerScreen({
    super.key,
    required this.serverUrl,
    required this.username,
    required this.password,
    required this.episodeId,
    required this.containerExtension,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux) {
      return SeriesPlayerDesktop(
        serverUrl: serverUrl,
        username: username,
        password: password,
        episodeId: episodeId,
        containerExtension: containerExtension,
        title: title,
      );
    } else {
      final cleanServer = serverUrl.replaceAll(RegExp(r'^https?://'), '');
      final url =
          'http://$cleanServer/series/'
          '${Uri.encodeComponent(username)}/'
          '${Uri.encodeComponent(password)}/'
          '$episodeId.$containerExtension';

      return SeriesPlayerMobile(url: url, title: title);
    }
  }
}
