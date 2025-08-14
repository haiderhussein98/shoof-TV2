import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class LiveAppBar extends PlatformAppBar {
  LiveAppBar({super.key})
    : super(
        title: const Text("Live Channels", style: TextStyle(fontSize: 15)),
        material: (_, __) => MaterialAppBarData(
          backgroundColor: Colors.black,
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 15.0),
              child: Image(image: AssetImage('assets/images/logo.png')),
            ),
          ],
        ),
        cupertino: (_, __) => CupertinoNavigationBarData(
          backgroundColor: Colors.black,
          trailing: const Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: Image(image: AssetImage('assets/images/logo.png')),
          ),
        ),
      );
}
