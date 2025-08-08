import 'package:flutter/material.dart';
import 'package:shoof_tv/presentation/widgets/app_search_field.dart';

class SeriesAppBar extends StatelessWidget implements PreferredSizeWidget {
  final TextEditingController searchController;
  final bool isSearching;
  final VoidCallback onClear;
  final ValueChanged<String> onSearch;

  const SeriesAppBar({
    super.key,
    required this.searchController,
    required this.isSearching,
    required this.onClear,
    required this.onSearch,
  });

  bool _isRTL(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    return const {'ar', 'fa', 'ur', 'he'}.contains(code) ||
        Directionality.of(context) == TextDirection.rtl;
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = _isRTL(context);

    return AppBar(
      backgroundColor: Colors.black,
      title: const Text("Series", style: TextStyle(fontSize: 15)),
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
          child: SizedBox(
            height: 50,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AppSearchField(
                  controller: searchController,
                  hintAr: 'ابحث عن مسلسل...',
                  hintEn: 'Search series...',
                  padding: EdgeInsets.zero,
                  onSubmitted: onSearch,
                ),

                if (isSearching)
                  Positioned(
                    right: isRtl ? null : 6,
                    left: isRtl ? 6 : null,
                    child: IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white54),
                      onPressed: onClear,
                      tooltip: isRtl ? 'مسح' : 'Clear',
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(100);
}
