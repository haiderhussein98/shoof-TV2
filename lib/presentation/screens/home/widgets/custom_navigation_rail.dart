import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodel/home_viewmodel.dart';

class CustomNavigationRail extends ConsumerWidget {
  const CustomNavigationRail({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(homeIndexProvider);

    return NavigationRail(
      selectedIndex: index,
      onDestinationSelected: (value) =>
          ref.read(homeIndexProvider.notifier).state = value,
      labelType: NavigationRailLabelType.all,
      selectedIconTheme: const IconThemeData(color: Colors.redAccent),
      unselectedIconTheme: const IconThemeData(color: Colors.white60),
      backgroundColor: Colors.black,
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.live_tv),
          label: Text("Live"),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.movie),
          label: Text("Movies"),
        ),
        NavigationRailDestination(icon: Icon(Icons.tv), label: Text("Series")),
        NavigationRailDestination(
          icon: Icon(Icons.settings),
          label: Text("Settings"),
        ),
      ],
    );
  }
}
