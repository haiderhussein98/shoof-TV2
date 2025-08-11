import 'package:flutter/material.dart';
import 'series_category_section.dart';

class SeriesCategoryList extends StatelessWidget {
  final List<Map<String, String>> categories;

  const SeriesCategoryList({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return ListView.builder(
      key: const PageStorageKey('series_category_list'),
      itemCount: categories.length,
      cacheExtent: w > 900 ? 300 : 500,
      itemBuilder: (context, index) {
        final category = categories[index];
        return SeriesCategorySection(
          categoryId: category['id']!,
          categoryName: category['name']!,
        );
      },
    );
  }
}
