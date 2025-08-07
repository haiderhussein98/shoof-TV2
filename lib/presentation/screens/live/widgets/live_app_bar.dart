import 'package:flutter/material.dart';

class LiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  const LiveAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text("Live Channels", style: TextStyle(fontSize: 15)),
      backgroundColor: Colors.black,
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 15.0),
          child: Image(image: AssetImage('assets/images/logo.png')),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
