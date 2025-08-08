import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoof_tv/domain/providers/live_providers.dart';
import '../../../../data/models/channel_model.dart';
import '../live_player_screen.dart';

class ChannelTile extends ConsumerWidget {
  final ChannelModel channel;
  final void Function()? onTap;

  const ChannelTile({super.key, required this.channel, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.watch(liveServiceProvider);

    final platformIsMobile =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    final isDesktop = !platformIsMobile && isWide;

    final double imageW = isDesktop
        ? 160
        : (channel.streamIcon.isEmpty ? 60 : 100);
    final double imageH = isDesktop ? 100 : 60;
    final double titleFontSize = isDesktop ? 16 : 12;
    final EdgeInsetsGeometry cardMargin = isDesktop
        ? const EdgeInsets.symmetric(horizontal: 24, vertical: 8)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
    final double maxWidth = isDesktop ? 1000 : double.infinity;
    final double playIconSize = isDesktop ? 32 : 28;
    final EdgeInsetsGeometry playIconPadding = isDesktop
        ? const EdgeInsets.only(right: 16)
        : const EdgeInsets.only(right: 12);
    final EdgeInsetsGeometry textPadding = isDesktop
        ? const EdgeInsets.symmetric(horizontal: 16)
        : const EdgeInsets.symmetric(horizontal: 12);

    void defaultNavigate() {
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
    }

    final card = Card(
      color: Colors.grey[900],
      margin: cardMargin,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          if (onTap != null) {
            onTap!();
          } else {
            defaultNavigate();
          }
        },
        borderRadius: BorderRadius.circular(12),
        hoverColor: isDesktop ? Colors.white.withValues(alpha: 0.04) : null,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(12),
              ),
              child: channel.streamIcon.isEmpty
                  ? Image.asset(
                      'assets/images/logo.png',
                      width: imageW,
                      height: imageH,
                      fit: BoxFit.cover,
                    )
                  : CachedNetworkImage(
                      imageUrl: channel.streamIcon,
                      width: imageW,
                      height: imageH,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Image.asset(
                        'assets/images/logo.png',
                        width: imageW,
                        height: imageH,
                        fit: BoxFit.cover,
                      ),
                      errorWidget: (context, url, error) => Image.asset(
                        'assets/images/logo.png',
                        width: imageW,
                        height: imageH,
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: textPadding,
                child: Text(
                  channel.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Padding(
              padding: playIconPadding,
              child: Icon(
                Icons.play_circle_fill,
                color: Colors.redAccent,
                size: playIconSize,
              ),
            ),
          ],
        ),
      ),
    );

    if (isDesktop) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: card,
        ),
      );
    }

    return card;
  }
}
