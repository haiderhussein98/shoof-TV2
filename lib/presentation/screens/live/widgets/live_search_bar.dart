import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoof_tv/presentation/screens/live/viewmodel/live_viewmodel.dart';
import 'package:shoof_tv/presentation/widgets/app_search_field.dart';

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
    return AppSearchField(
      controller: controller,
      hintAr: 'ابحث عن القناة...',
      hintEn: 'Search channels...',
      onChanged: (value) async {
        searchQuery.value = value;
        if (value.trim().isEmpty) {
          await ref
              .read(liveViewModelProvider.notifier)
              .fetchAllChannelsForSearch();
        }
      },
    );
  }
}
