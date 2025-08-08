import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'live_player_mobile.dart';
import 'live_player_desktop.dart';

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

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux) {
      return LivePlayerDesktop(
        serverUrl: serverUrl,
        username: username,
        password: password,
        streamId: streamId,
        title: title,
      );
    } else {
      return LivePlayerMobile(
        serverUrl: serverUrl,
        username: username,
        password: password,
        streamId: streamId,
        title: title,
      );
    }
  }
}
