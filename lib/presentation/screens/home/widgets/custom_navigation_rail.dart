import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoof_tv/presentation/screens/home/viewmodel/home_viewmodel.dart';

class CustomNavigationRail extends ConsumerWidget {
  const CustomNavigationRail({super.key});

  static const double _railWidth = 96.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(homeIndexProvider);

    const mainItems = [
      _RailItem(icon: Icons.live_tv, label: 'Live', tabIndex: 0),
      _RailItem(icon: Icons.movie, label: 'Movies', tabIndex: 1),
      _RailItem(icon: Icons.tv, label: 'Series', tabIndex: 2),
    ];

    const settingsItem = _RailItem(
      icon: Icons.settings,
      label: 'Settings',
      tabIndex: 3,
    );

    return SizedBox(
      width: _railWidth,
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
                      width: _railWidth,
                      icon: item.icon,
                      label: item.label,
                      selected: selected,
                      onTap: () => ref.read(homeIndexProvider.notifier).state =
                          item.tabIndex,
                    );
                  },
                ),
              ),
            ),

            SafeArea(
              top: false,
              child: _RailTile(
                width: _railWidth,
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
