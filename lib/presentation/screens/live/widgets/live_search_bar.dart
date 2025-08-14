import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoof_tv/presentation/screens/live/viewmodel/live_viewmodel.dart';

class LiveSearchBar extends ConsumerWidget {
  final TextEditingController controller;
  final ValueNotifier<String> searchQuery;

  const LiveSearchBar({
    super.key,
    required this.controller,
    required this.searchQuery,
  });

  bool _isRTL(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    return const {'ar', 'fa', 'ur', 'he'}.contains(code) ||
        Directionality.of(context) == TextDirection.rtl;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRtl = _isRTL(context);
    final hint = isRtl ? 'ابحث عن القناة...' : 'Search channels...';

    Future<void> clearAndReload() async {
      controller.clear();
      searchQuery.value = '';
      await ref
          .read(liveViewModelProvider.notifier)
          .fetchAllChannelsForSearch();
    }

    final clearButtonBuilder = ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        if (value.text.isEmpty) return const SizedBox.shrink();
        return PlatformIconButton(
          icon: Icon(context.platformIcons.clear, color: Colors.white54),
          padding: EdgeInsets.zero,
          onPressed: clearAndReload,
        );
      },
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
      child: PlatformTextField(
        controller: controller,
        onChanged: (value) async {
          searchQuery.value = value;
          if (value.trim().isEmpty) {
            await ref
                .read(liveViewModelProvider.notifier)
                .fetchAllChannelsForSearch();
          }
        },
        onSubmitted: (value) => searchQuery.value = value,
        textInputAction: TextInputAction.search,
        cursorColor: Colors.white70,
        style: const TextStyle(color: Colors.white),

        // Android/Material
        material: (_, __) => MaterialTextFieldData(
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white60),
            filled: true,
            fillColor: const Color(0xFF1E1F25),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            prefixIcon: Icon(
              context.platformIcons.search,
              color: Colors.white70,
            ),
            suffixIcon: clearButtonBuilder,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0x22FFFFFF), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0x44FFFFFF), width: 1),
            ),
          ),
          textAlign: isRtl ? TextAlign.right : TextAlign.left,
        ),

        // iOS/Cupertino
        cupertino: (_, __) => CupertinoTextFieldData(
          placeholder: hint,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1F25),
            borderRadius: BorderRadius.circular(16),
          ),
          prefix: Padding(
            padding: const EdgeInsetsDirectional.only(start: 8),
            child: Icon(context.platformIcons.search, color: Colors.white70),
          ),
          suffix: Padding(
            padding: const EdgeInsetsDirectional.only(end: 6),
            child: clearButtonBuilder,
          ),
          placeholderStyle: const TextStyle(color: Colors.white60),
          textAlign: isRtl ? TextAlign.right : TextAlign.left,
        ),
      ),
    );
  }
}
