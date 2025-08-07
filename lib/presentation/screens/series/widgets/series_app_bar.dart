import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
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
          child: TextField(
            textDirection: TextDirection.rtl,
            controller: searchController,
            onSubmitted: onSearch,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'ابحث عن مسلسل...',
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Colors.grey[900],
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              suffixIcon: isSearching
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white54),
                      onPressed: onClear,
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(100);
}
