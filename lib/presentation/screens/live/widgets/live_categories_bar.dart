import 'package:flutter/material.dart';

class LiveCategoriesBar extends StatelessWidget {
  final List<Map<String, String>> categories;
  final ScrollController controller;
  final String? selectedCategoryId;
  final List<GlobalKey> keys;
  final Map<String, int> countMap;
  final Function(String) onSelect;

  const LiveCategoriesBar({
    super.key,
    required this.categories,
    required this.controller,
    required this.selectedCategoryId,
    required this.keys,
    required this.countMap,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 45,
      child: ListView.builder(
        controller: controller,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = selectedCategoryId == cat['id'];
          final count = countMap[cat['id']] ?? 0;

          return Padding(
            key: keys[index],
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: ChoiceChip(
              label: Text(
                '${cat['name']}${cat['id'] != 'all' ? ' ($count)' : ''}',
              ),
              selected: isSelected,
              onSelected: (_) => onSelect(cat['id']!),
              selectedColor: Colors.redAccent,
              backgroundColor: Colors.grey[800],
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
              ),
            ),
          );
        },
      ),
    );
  }
}
