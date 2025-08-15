import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:shoof_tv/presentation/widgets/universal_player_desktop.dart';
import 'package:shoof_tv/presentation/widgets/universal_player_mobile.dart';

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

  bool get _isDesktop =>
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isDesktop
          ? UniversalPlayerDesktop.series(
              title: title,
              serverUrlSeries: serverUrl,
              usernameSeries: username,
              passwordSeries: password,
              episodeId: episodeId,
              containerExtension: containerExtension,
            )
          : UniversalPlayerMobile(
              type: ContentType.series,
              title: title,
              url: _buildSeriesUrl(),
              logo: Image.asset('assets/images/logo.png', width: 40),
            ),
    );
  }

  String _buildSeriesUrl() {
    final cleanServer = serverUrl.replaceAll(RegExp(r'^https?://'), '');
    return 'http://$cleanServer/series/'
        '${Uri.encodeComponent(username)}/'
        '${Uri.encodeComponent(password)}/'
        '$episodeId.$containerExtension';
  }
}

