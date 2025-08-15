import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoof_tv/core/responsive.dart';
import 'package:shoof_tv/domain/providers/live_providers.dart';
import '../../../../data/models/channel_model.dart';
import '../live_player_screen.dart';

class ChannelTile extends ConsumerWidget {
  final ChannelModel channel;
  final void Function()? onTap;

  const ChannelTile({super.key, required this.channel, this.onTap});

  double _clamp(double v, double lo, double hi) =>
      v.clamp(math.min(lo, hi), math.max(lo, hi)).toDouble();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.watch(liveServiceProvider);

    void defaultNavigate() {
      final navigator = Navigator.of(context);
      navigator.push(
        platformPageRoute(
          context: context,
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

    const headers = {'User-Agent': 'Mozilla/5.0'};

    Widget thumb() {
      final fallback = Image.asset('assets/images/logo.png', fit: BoxFit.cover);
      if (channel.streamIcon.isEmpty) {
        return fallback;
      }
      return CachedNetworkImage(
        imageUrl: channel.streamIcon,
        httpHeaders: headers,
        fit: BoxFit.cover,
        placeholder: (_, __) => fallback,
        errorWidget: (_, __, ___) => fallback,
      );
    }

    return LayoutBuilder(
      builder: (context, c) {
        final isDesktop = context.isDesktop || context.isTvLike;
        final gap = context.gap;
        final radius = 16.0;
        final cardPad = _clamp(gap, 8, 14);
        final titleSize = _clamp(c.maxWidth * 0.06, 11, isDesktop ? 14 : 13);
        final iconSize = _clamp(c.maxWidth * 0.10, 20, isDesktop ? 26 : 24);
        final double footerHeight = _clamp(c.maxHeight * 0.22, 44, 56);
        final double padH = _clamp(cardPad, 8, 14);
        final double padV = _clamp(cardPad * 0.6, 6, 10);

        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned.fill(child: thumb()),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.30),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: footerHeight,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        channel.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: titleSize,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    SizedBox(width: _clamp(gap * 0.5, 6, 10)),
                    Icon(
                      Icons.play_circle_fill,
                      color: Colors.redAccent,
                      size: iconSize,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );

        return Card(
          color: const Color(0xFF161616),
          elevation: 0,
          margin: EdgeInsets.symmetric(
            horizontal: _clamp(gap * 0.5, 6, 12),
            vertical: _clamp(gap * 0.4, 5, 10),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
            side: BorderSide(color: Colors.black.withValues(alpha: 0.30)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap ?? defaultNavigate,
            splashColor: Colors.white10,
            highlightColor: Colors.black.withValues(alpha: 0.30),
            child: content,
          ),
        );
      },
    );
  }
}

