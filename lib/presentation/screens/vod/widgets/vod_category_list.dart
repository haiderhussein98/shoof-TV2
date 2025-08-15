﻿import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:shoof_tv/presentation/screens/vod/widgets/category_section.dart';

class VodCategoryList extends StatefulWidget {
  final Future<List<Map<String, String>>> categoriesFuture;
  final double screenWidth;

  const VodCategoryList({
    super.key,
    required this.categoriesFuture,
    required this.screenWidth,
  });

  @override
  State<VodCategoryList> createState() => _VodCategoryListState();
}

class _VodCategoryListState extends State<VodCategoryList> {
  int? loadingIndex;

  void setLoading(int? index) {
    setState(() => loadingIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final physics = isCupertino(context)
        ? const BouncingScrollPhysics()
        : const ClampingScrollPhysics();

    return FutureBuilder<List<Map<String, String>>>(
      future: widget.categoriesFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: PlatformCircularProgressIndicator());
        }

        final categories = snapshot.data!;
        return ListView.builder(
          physics: physics,
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return CategorySection(
              categoryId: category['id']!,
              categoryName: category['name']!,
              screenWidth: widget.screenWidth,
              loadingIndex: loadingIndex,
              onSetLoading: setLoading,
            );
          },
        );
      },
    );
  }
}

