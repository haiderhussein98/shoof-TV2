import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoof_iptv/presentation/screens/live/viewmodel/live_viewmodel.dart';

class LiveSearchBar extends ConsumerWidget {
  final TextEditingController controller;
  final ValueNotifier<String> searchQuery;

  const LiveSearchBar({
    super.key,
    required this.controller,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: controller,
        onChanged: (value) async {
          searchQuery.value = value;

          if (value.trim().isEmpty) {
            await ref
                .read(liveViewModelProvider.notifier)
                .fetchAllChannelsForSearch();
          }
        },
        decoration: InputDecoration(
          hintText: 'بحث عن القناة...',
          hintStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: Colors.grey[850],
          prefixIcon: const Icon(Icons.search, color: Colors.white),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}
