import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoof_iptv/domain/providers/live_providers.dart';
import '../../../../data/models/channel_model.dart';
import '../live_player_screen.dart';

class ChannelTile extends ConsumerWidget {
  final ChannelModel channel;
  final void Function()? onTap;

  const ChannelTile({super.key, required this.channel, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.watch(liveServiceProvider);

    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LivePlayerScreen(
                serverUrl: api.serverUrl,
                username: api.username,
                password: api.password,
                streamId: channel.streamId,
                title: channel.name,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(12),
              ),
              child: channel.streamIcon.isEmpty
                  ? Image.asset(
                      'assets/images/logo.png',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    )
                  : CachedNetworkImage(
                      imageUrl: channel.streamIcon,
                      width: 100,
                      height: 60,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Image.asset(
                        'assets/images/logo.png',
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                      errorWidget: (context, url, error) => Image.asset(
                        'assets/images/logo.png',
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  channel.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(
                Icons.play_circle_fill,
                color: Colors.redAccent,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
