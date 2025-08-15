import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class LiveCategoriesBar extends StatefulWidget {
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
  State<LiveCategoriesBar> createState() => _LiveCategoriesBarState();
}

class _LiveCategoriesBarState extends State<LiveCategoriesBar> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollSelectedIntoView(),
    );
  }

  @override
  void didUpdateWidget(covariant LiveCategoriesBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategoryId != widget.selectedCategoryId ||
        oldWidget.categories != widget.categories) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _scrollSelectedIntoView(),
      );
    }
  }

  Future<void> _scrollSelectedIntoView() async {
    if (!mounted) return;
    final selectedId = widget.selectedCategoryId;
    if (selectedId == null) return;

    final index = widget.categories.indexWhere((c) => c['id'] == selectedId);
    if (index < 0 || index >= widget.keys.length) return;

    if (widget.keys[index].currentContext == null &&
        widget.controller.hasClients &&
        widget.controller.position.hasContentDimensions) {
      final total = (widget.categories.length - 1).clamp(1, 9999);
      final fraction = index / total;
      final target = widget.controller.position.maxScrollExtent * fraction;
      try {
        await widget.controller.animateTo(
          target,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 16));
    }

    if (!mounted) return;
    final itemCtx = widget.keys[index].currentContext;
    if (itemCtx == null || !itemCtx.mounted) return;

    try {
      await Scrollable.ensureVisible(
        itemCtx,
        alignment: 0.0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final physics = isCupertino(context)
        ? const BouncingScrollPhysics()
        : const ClampingScrollPhysics();

    return SizedBox(
      height: 45,
      child: ScrollConfiguration(
        behavior: const MaterialScrollBehavior().copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
            PointerDeviceKind.stylus,
            PointerDeviceKind.unknown,
          },
        ),
        child: Listener(
          onPointerSignal: (event) {
            if (event is PointerScrollEvent) {
              final delta = event.scrollDelta.dy != 0
                  ? event.scrollDelta.dy
                  : event.scrollDelta.dx;
              final c = widget.controller;
              if (c.hasClients && c.position.hasContentDimensions) {
                final target = (c.offset + delta).clamp(
                  c.position.minScrollExtent,
                  c.position.maxScrollExtent,
                );
                c.jumpTo(target);
              }
            }
          },
          child: Scrollbar(
            controller: widget.controller,
            thumbVisibility: true,
            child: ListView.builder(
              controller: widget.controller,
              physics: physics,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              cacheExtent: 1000,
              itemCount: widget.categories.length,
              itemBuilder: (context, index) {
                final cat = widget.categories[index];
                final isSelected = widget.selectedCategoryId == cat['id'];
                final count = widget.countMap[cat['id']] ?? 0;

                return Padding(
                  key: widget.keys[index],
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: ChoiceChip(
                    label: Text(
                      '${cat['name']}${cat['id'] != 'all' ? ' ($count)' : ''}',
                    ),
                    selected: isSelected,
                    onSelected: (_) => widget.onSelect(cat['id']!),
                    selectedColor: Colors.redAccent,
                    backgroundColor: Colors.grey[800],
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

