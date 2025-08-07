import 'package:flutter/material.dart';
import 'package:shoof_iptv/data/models/channel_model.dart';
import 'package:shoof_iptv/presentation/screens/live/widgets/channel_tile.dart';

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

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            final crossAxisCount = isWide ? 3 : 1;

            return ValueListenableBuilder<String>(
              valueListenable: searchQuery,
              builder: (context, query, _) {
                final filtered = query.isEmpty
                    ? channels
                    : channels.where((channel) {
                        return channel.name.toLowerCase().contains(
                          query.toLowerCase(),
                        );
                      }).toList();

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
                  padding: const EdgeInsets.all(8),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: isWide ? 2.5 : 3.5,
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
      ),
    );
  }
}
