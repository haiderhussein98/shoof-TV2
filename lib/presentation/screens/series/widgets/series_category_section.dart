import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shoof_tv/domain/providers/series_providers.dart';
import '../../../../data/models/series_model.dart';
import '../series_details_screen.dart';
import '../category_series_screen.dart';

class SeriesCategorySection extends ConsumerStatefulWidget {
  final String categoryId;
  final String categoryName;

  const SeriesCategorySection({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  ConsumerState<SeriesCategorySection> createState() =>
      _SeriesCategorySectionState();
}

class _SeriesCategorySectionState extends ConsumerState<SeriesCategorySection> {
  late Future<List<SeriesModel>> _seriesFuture;

  final List<FocusNode> _itemFocus = [];
  final Map<int, GlobalKey> _itemKeys = {};
  int _autofocusIndex = 0;

  final FocusNode _seeAllFocus = FocusNode(debugLabel: 'see_all_btn');
  bool _seeAllHasFocus = false;

  bool _pendingFocusToFirst = false;

  @override
  void initState() {
    super.initState();
    _seriesFuture = ref
        .read(seriesServiceProvider)
        .getSeriesByCategory(widget.categoryId, offset: 0, limit: 2000);
  }

  @override
  void dispose() {
    for (final n in _itemFocus) {
      n.dispose();
    }
    _seeAllFocus.dispose();
    super.dispose();
  }

  // TV-only: Android + ØªÙ†Ù‚Ù‘Ù„ Ø§ØªØ¬Ø§Ù‡ÙŠ
  bool _isAndroidTvLike(BuildContext context) {
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;
    final nav = MediaQuery.of(context).navigationMode;
    return isAndroid && nav == NavigationMode.directional;
  }

  Future<void> _openSeries(
    BuildContext context,
    SeriesModel series,
    int index,
  ) async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (_, __, ___) => SeriesDetailsScreen(series: series),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.98, end: 1).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
    if (mounted && _itemFocus.length > index) {
      _itemFocus[index].requestFocus();
    }
  }

  void _openSeeAll() {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 240),
        pageBuilder: (_, __, ___) => CategorySeriesScreen(
          categoryId: widget.categoryId,
          categoryName: widget.categoryName,
        ),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  void _focusFirstItemSafely() {
    if (_itemFocus.isNotEmpty) {
      (_itemFocus[_autofocusIndex.clamp(0, _itemFocus.length - 1)])
          .requestFocus();
      _pendingFocusToFirst = false;
    } else {
      _pendingFocusToFirst = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final isTv = _isAndroidTvLike(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ø§Ù„Ø¹Ù†ÙˆØ§Ù† + Ø²Ø± Ù…Ø´Ø§Ù‡Ø¯Ø© Ø§Ù„ÙƒÙ„
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.categoryName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Focus(
                  focusNode: _seeAllFocus,
                  canRequestFocus: isTv, // ØªØ±ÙƒÙŠØ² ÙÙ‚Ø· Ø¹Ù„Ù‰ TV
                  onFocusChange: (f) => setState(() => _seeAllHasFocus = f),
                  onKeyEvent: (node, event) {
                    if (!isTv) return KeyEventResult.ignored;
                    if (event is KeyDownEvent) {
                      final isSelect = event.logicalKey ==
                              LogicalKeyboardKey.enter ||
                          event.logicalKey == LogicalKeyboardKey.select ||
                          event.logicalKey == LogicalKeyboardKey.space ||
                          event.logicalKey == LogicalKeyboardKey.numpadEnter;
                      if (isSelect) {
                        _openSeeAll();
                        return KeyEventResult.handled;
                      }
                      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                        _focusFirstItemSafely();
                        return KeyEventResult.handled;
                      }
                    }
                    return KeyEventResult.ignored;
                  },
                  child: InkWell(
                    onTap: _openSeeAll,
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: _seeAllHasFocus
                            ? Border.all(color: Colors.redAccent)
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            context.platformIcons.rightChevron,
                            size: 14,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            "مشاهدة الكل",
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(
            height: w > 600 ? 230 : 190,
            child: FutureBuilder<List<SeriesModel>>(
              future: _seriesFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final seriesList = snapshot.data!;
                if (_itemFocus.length != seriesList.length) {
                  for (final n in _itemFocus) {
                    n.dispose();
                  }
                  _itemFocus
                    ..clear()
                    ..addAll(
                      List.generate(seriesList.length, (_) => FocusNode()),
                    );
                  _itemKeys.clear();
                  for (int i = 0; i < seriesList.length; i++) {
                    _itemKeys[i] = GlobalKey();
                  }
                  if (_autofocusIndex >= seriesList.length) {
                    _autofocusIndex = 0;
                  }
                  if (_pendingFocusToFirst) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) _focusFirstItemSafely();
                    });
                  }
                }

                return FocusTraversalGroup(
                  descendantsAreFocusable: isTv,
                  policy: ReadingOrderTraversalPolicy(),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: seriesList.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final series = seriesList[index];
                      final itemW = w > 900 ? 150.0 : (w > 600 ? 130.0 : 110.0);
                      final memW = (itemW * dpr).round();
                      final memH = (itemW * 1.5 * dpr).round();
                      final focusNode = _itemFocus[index];
                      final itemKey = _itemKeys[index]!;

                      return Focus(
                        canRequestFocus: isTv,
                        skipTraversal: !isTv,
                        onKeyEvent: (node, event) {
                          if (!isTv) return KeyEventResult.ignored;
                          if (event is KeyDownEvent &&
                              event.logicalKey == LogicalKeyboardKey.arrowUp) {
                            _seeAllFocus.requestFocus();
                            return KeyEventResult.handled;
                          }
                          return KeyEventResult.ignored;
                        },
                        child: FocusableActionDetector(
                          key: itemKey,
                          focusNode: focusNode,
                          autofocus: isTv && index == _autofocusIndex,
                          shortcuts: isTv
                              ? const {
                                  SingleActivator(LogicalKeyboardKey.select):
                                      ActivateIntent(),
                                  SingleActivator(LogicalKeyboardKey.enter):
                                      ActivateIntent(),
                                }
                              : const <ShortcutActivator, Intent>{},
                          actions: {
                            ActivateIntent: CallbackAction<ActivateIntent>(
                              onInvoke: (_) {
                                _openSeries(context, series, index);
                                return null;
                              },
                            ),
                          },
                          onFocusChange: (hasFocus) {
                            if (hasFocus) {
                              _autofocusIndex = index;
                              final ctx = itemKey.currentContext;
                              if (ctx != null) {
                                Scrollable.ensureVisible(
                                  ctx,
                                  duration: const Duration(milliseconds: 140),
                                  alignment: 0.5,
                                );
                              }
                            }
                            setState(() {});
                          },
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _openSeries(context, series, index),
                            child: AnimatedScale(
                              duration: const Duration(milliseconds: 120),
                              scale: isTv && focusNode.hasFocus ? 1.06 : 1.0,
                              child: AnimatedContainer(
                                width: itemW,
                                height: double.infinity,
                                duration: const Duration(milliseconds: 120),
                                decoration: BoxDecoration(
                                  border: isTv && focusNode.hasFocus
                                      ? Border.all(
                                          color: Colors.redAccent,
                                          width: 2,
                                        )
                                      : null,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: isTv && focusNode.hasFocus
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.35,
                                            ),
                                            blurRadius: 16,
                                            offset: const Offset(0, 6),
                                          ),
                                        ]
                                      : null,
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: CachedNetworkImage(
                                  imageUrl: series.cover,
                                  fit: BoxFit.cover,
                                  memCacheWidth: memW,
                                  memCacheHeight: memH,
                                  filterQuality: FilterQuality.low,
                                  fadeInDuration: Duration.zero,
                                  fadeOutDuration: Duration.zero,
                                  placeholderFadeInDuration: Duration.zero,
                                  placeholder: (context, url) =>
                                      const ColoredBox(
                                    color: Colors.black12,
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      const Icon(
                                    Icons.error,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
