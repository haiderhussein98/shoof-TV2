import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:shoof_tv/data/models/channel_model.dart';
import 'package:shoof_tv/presentation/screens/live/widgets/channel_tile.dart';

class LiveChannelsGrid extends StatelessWidget {
  final List<ChannelModel> channels;
  final ScrollController scrollController;
  final double bottomInset;
  final ValueNotifier<String> searchQuery;
  final void Function(ChannelModel) onTap;

  const LiveChannelsGrid({
    super.key,
    required this.channels,
    required this.scrollController,
    required this.bottomInset,
    required this.searchQuery,
    required this.onTap,
  });

  int _cols(double w, Orientation o) {
    if (w >= 2400) return 12;
    if (w >= 2100) return 11;
    if (w >= 1900) return 10;
    if (w >= 1700) return 9;
    if (w >= 1500) return 8;
    if (w >= 1300) return 7;
    if (w >= 1100) return 6;
    if (w >= 900) return 5;
    if (w >= 700) return 4;
    if (o == Orientation.landscape && w >= 580) return 3;
    return 2;
  }

  double _ratio(double w, Orientation o) {
    if (w >= 2000) return 1.95;
    if (w >= 1500) return 1.90;
    if (w >= 1100) return 1.85;
    if (w >= 900) return 1.80;
    if (w >= 700) return 1.75;
    return (o == Orientation.landscape) ? 1.75 : 1.55;
  }

  double _gap(double w) {
    if (w >= 1600) return 14;
    if (w >= 1200) return 12;
    if (w >= 900) return 10;
    return 8;
  }

  @override
  Widget build(BuildContext context) {
    final o = MediaQuery.of(context).orientation;
    final physics = isCupertino(context)
        ? const BouncingScrollPhysics()
        : const ClampingScrollPhysics();

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final crossAxisCount = _cols(w, o);
          final ratio = _ratio(w, o);
          final gap = _gap(w);

          return ValueListenableBuilder<String>(
            valueListenable: searchQuery,
            builder: (context, query, _) {
              final filtered = query.isEmpty
                  ? channels
                  : channels
                      .where(
                        (c) => c.name.toLowerCase().contains(
                              query.toLowerCase(),
                            ),
                      )
                      .toList();

              if (filtered.isEmpty) {
                return const Center(
                  child: Text(
                    'لم يتم العثور على قنوات.',
                    style: TextStyle(color: Colors.white70),
                  ),
                );
              }

              return GridView.builder(
                controller: scrollController,
                physics: physics,
                padding: const EdgeInsets.all(8),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: gap,
                  mainAxisSpacing: gap,
                  childAspectRatio: ratio,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final channel = filtered[index];
                  return ChannelTile(
                    channel: channel,
                    onTap: () => onTap(channel),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
