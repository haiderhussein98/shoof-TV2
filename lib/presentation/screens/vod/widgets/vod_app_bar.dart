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
          child: TextField(
            textDirection: TextDirection.rtl,
            controller: controller,
            onSubmitted: onSearch,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'ابحث عن فيلم...',
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
