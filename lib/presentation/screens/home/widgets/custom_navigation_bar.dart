import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodel/home_viewmodel.dart';

class CustomNavigationBar extends ConsumerWidget {
  const CustomNavigationBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(homeIndexProvider);

    return BottomNavigationBar(
      currentIndex: index,
      onTap: (value) => ref.read(homeIndexProvider.notifier).state = value,
      selectedItemColor: Colors.redAccent,
      unselectedItemColor: Colors.white60,
      backgroundColor: Colors.black,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.live_tv), label: "Live"),
        BottomNavigationBarItem(icon: Icon(Icons.movie), label: "Movies"),
        BottomNavigationBarItem(icon: Icon(Icons.tv), label: "Series"),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
      ],
    );
  }
}
