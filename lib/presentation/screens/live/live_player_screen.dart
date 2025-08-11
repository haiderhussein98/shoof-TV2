import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:shoof_tv/presentation/widgets/universal_player_desktop.dart';
import 'package:shoof_tv/presentation/widgets/universal_player_mobile.dart';

class LivePlayerScreen extends StatelessWidget {
  final String serverUrl;
  final String username;
  final String password;
  final int streamId;
  final String title;

  const LivePlayerScreen({
    super.key,
    required this.serverUrl,
    required this.username,
    required this.password,
    required this.streamId,
    required this.title,
  });

  bool get _isDesktop =>
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;

  @override
  Widget build(BuildContext context) {
    if (_isDesktop) {
      return UniversalPlayerDesktop.live(
        title: title,
        serverUrl: serverUrl,
        username: username,
        password: password,
        streamId: streamId,
      );
    } else {
      return UniversalPlayerMobile(
        type: ContentType.live,
        title: title,
        serverUrl: serverUrl,
        username: username,
        password: password,
        streamId: streamId,
        logo: Image.asset('assets/images/logo.png', width: 40),
      );
    }
  }
}
