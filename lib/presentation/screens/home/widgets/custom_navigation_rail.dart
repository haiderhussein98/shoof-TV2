import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoof_tv/presentation/screens/home/viewmodel/home_viewmodel.dart';

class CustomNavigationRail extends ConsumerWidget {
  const CustomNavigationRail({super.key});

  static const double _railWidth = 96.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(homeIndexProvider);

    final liveIcon = isCupertino(context) ? CupertinoIcons.tv : Icons.live_tv;
    final moviesIcon = isCupertino(context) ? CupertinoIcons.film : Icons.movie;
    final seriesIcon = isCupertino(context)
        ? CupertinoIcons.tv_music_note
        : Icons.tv;
    final settingsIcon = isCupertino(context)
        ? CupertinoIcons.gear_alt
        : Icons.settings;

    final mainItems = [
      _RailItem(icon: liveIcon, label: 'Live', tabIndex: 0),
      _RailItem(icon: moviesIcon, label: 'Movies', tabIndex: 1),
      _RailItem(icon: seriesIcon, label: 'Series', tabIndex: 2),
    ];

    final settingsItem = _RailItem(
      icon: settingsIcon,
      label: 'Settings',
      tabIndex: 3,
    );

    return SizedBox(
      width: _railWidth,
      child: const ColoredBox(
        color: Colors.black,
        child: _RailContent(railWidth: _railWidth),
      ),
    )._withContent(context, ref, index, mainItems, settingsItem);
  }
}

class _RailItem {
  final IconData icon;
  final String label;
  final int tabIndex;
  const _RailItem({
    required this.icon,
    required this.label,
    required this.tabIndex,
  });
}

class _RailContent extends StatelessWidget {
  final double railWidth;
  const _RailContent({required this.railWidth});

  @override
  Widget build(BuildContext context) {
    return SizedBox.shrink();
  }
}

extension _RailBuilder on Widget {
  Widget _withContent(
    BuildContext context,
    WidgetRef ref,
    int index,
    List<_RailItem> mainItems,
    _RailItem settingsItem,
  ) {
    return LayoutBuilder(
      builder: (ctx, _) {
        final sized = this as SizedBox;
        final width = sized.width!;

        return SizedBox(
          width: width,
          child: ColoredBox(
            color: Colors.black,
            child: Column(
              children: [
                const SizedBox(height: 12),
                const SizedBox(height: 12),

                const SizedBox(height: 40, width: 40),

                const SizedBox(height: 8),
                const SizedBox(height: 8),

                Expanded(
                  child: MediaQuery.removePadding(
                    context: context,
                    removeTop: true,
                    removeBottom: true,
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      physics: const ClampingScrollPhysics(),
                      itemCount: mainItems.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (context, i) {
                        final item = mainItems[i];
                        final selected = index == item.tabIndex;
                        return _RailTile(
                          width: width,
                          icon: item.icon,
                          label: item.label,
                          selected: selected,
                          onTap: () =>
                              ref.read(homeIndexProvider.notifier).state =
                                  item.tabIndex,
                        );
                      },
                    ),
                  ),
                ),

                SafeArea(
                  top: false,
                  child: _RailTile(
                    width: width,
                    icon: settingsItem.icon,
                    label: settingsItem.label,
                    selected: index == settingsItem.tabIndex,
                    onTap: () => ref.read(homeIndexProvider.notifier).state =
                        settingsItem.tabIndex,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RailTile extends StatelessWidget {
  final double width;
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RailTile({
    required this.width,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white12 : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.white10,
        highlightColor: Colors.white10,
        child: SizedBox(
          width: width,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: selected ? Colors.blueAccent : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: selected ? Colors.white : Colors.white70,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.white70,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
