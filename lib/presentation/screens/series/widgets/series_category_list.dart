import 'package:flutter/material.dart';
import 'series_category_section.dart';

class SeriesCategoryList extends StatelessWidget {
  final List<Map<String, String>> categories;
  final double screenWidth;

  const SeriesCategoryList({
    super.key,
    required this.categories,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return SeriesCategorySection(
          categoryId: category['id']!,
          categoryName: category['name']!,
          screenWidth: screenWidth,
        );
      },
    );
  }
}
