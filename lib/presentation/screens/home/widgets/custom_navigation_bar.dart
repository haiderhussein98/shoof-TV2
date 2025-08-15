import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodel/home_viewmodel.dart';

class CustomNavigationBar extends ConsumerWidget {
  const CustomNavigationBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(homeIndexProvider);

    final liveIcon = isCupertino(context) ? CupertinoIcons.tv : Icons.live_tv;
    final moviesIcon = isCupertino(context) ? CupertinoIcons.film : Icons.movie;
    final seriesIcon = isCupertino(context)
        ? CupertinoIcons.tv_music_note
        : Icons.tv;
    final settingsIcon = isCupertino(context)
        ? CupertinoIcons.gear_alt
        : Icons.settings;

    return PlatformNavBar(
      currentIndex: index,
      itemChanged: (value) =>
          ref.read(homeIndexProvider.notifier).state = value,
      items: [
        BottomNavigationBarItem(icon: Icon(liveIcon), label: "Live"),
        BottomNavigationBarItem(icon: Icon(moviesIcon), label: "Movies"),
        BottomNavigationBarItem(icon: Icon(seriesIcon), label: "Series"),
        BottomNavigationBarItem(icon: Icon(settingsIcon), label: "Settings"),
      ],
      material: (_, __) => MaterialNavBarData(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.redAccent,
        unselectedItemColor: Colors.white60,
        backgroundColor: Colors.black,
      ),
      cupertino: (_, __) => CupertinoTabBarData(
        activeColor: Colors.redAccent,
        inactiveColor: Colors.white60,
        backgroundColor: Colors.black,
      ),
    );
  }
}

