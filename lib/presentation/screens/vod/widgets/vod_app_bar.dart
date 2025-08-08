import 'package:flutter/material.dart';

class VodAppBar extends StatelessWidget implements PreferredSizeWidget {
  final TextEditingController controller;
  final bool isSearching;
  final Function(String) onSearch;
  final VoidCallback onClear;

  const VodAppBar({
    super.key,
    required this.controller,
    required this.isSearching,
    required this.onSearch,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    bool isRTL(BuildContext context) {
      final code = Localizations.localeOf(context).languageCode.toLowerCase();
      return const {'ar', 'fa', 'ur', 'he'}.contains(code) ||
          Directionality.of(context) == TextDirection.rtl;
    }

    final isRtl = isRTL(context);
    return AppBar(
      backgroundColor: Colors.black,
      title: const Text("Movies", style: TextStyle(fontSize: 15)),
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 15.0),
          child: Image(image: AssetImage('assets/images/logo.png')),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
          child: Directionality(
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            child: TextField(
              controller: controller,
              onSubmitted: onSearch,
              style: const TextStyle(color: Colors.white),
              cursorColor: Colors.white70,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: isRtl ? 'ابحث عن فيلم...' : 'Search movies...',
                hintStyle: const TextStyle(color: Colors.white60),
                filled: true,
                fillColor: const Color(0xFF1E1F25),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                suffixIcon: isSearching
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54),
                        onPressed: onClear,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0x22FFFFFF),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0x44FFFFFF),
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(100);
}
