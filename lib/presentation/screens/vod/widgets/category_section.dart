import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoof_tv/data/models/movie_model.dart.dart';
import 'package:shoof_tv/domain/providers/vod_providers.dart';
import 'package:shoof_tv/presentation/screens/vod/category_movies_screen.dart';
import 'package:shoof_tv/presentation/screens/vod/movie_details_screen.dart';

class CategorySection extends ConsumerStatefulWidget {
  final String categoryId;
  final String categoryName;
  final double screenWidth;
  final int? loadingIndex;
  final void Function(int?) onSetLoading;

  const CategorySection({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.screenWidth,
    required this.loadingIndex,
    required this.onSetLoading,
  });

  @override
  ConsumerState<CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends ConsumerState<CategorySection> {
  final List<FocusNode> _itemFocus = [];
  final Map<int, GlobalKey> _itemKeys = {};
  int _autofocusIndex = 0;

  final FocusNode _seeAllFocus = FocusNode(debugLabel: 'see_all_btn');
  bool _seeAllHasFocus = false;

  bool _pendingFocusToFirst = false;

  @override
  void dispose() {
    for (final n in _itemFocus) {
      n.dispose();
    }
    _seeAllFocus.dispose();
    super.dispose();
  }

  Future<void> _openMovie(
    BuildContext context,
    MovieModel movie,
    int index,
  ) async {
    if (widget.loadingIndex != null) return;
    widget.onSetLoading(index);

    try {
      final details = await ref
          .read(vodServiceProvider)
          .getMovieDetails(movie.streamId);
      if (!context.mounted) return;

      await Navigator.of(context).push(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 260),
          pageBuilder: (_, __, ___) => MovieDetailsScreen(movie: details),
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
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('فشل تحميل تفاصيل الفيلم'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      widget.onSetLoading(null);
    }
  }

  void _openSeeAll() {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 240),
        pageBuilder: (_, __, ___) => CategoryMoviesScreen(
          categoryId: widget.categoryId,
          categoryName: widget.categoryName,
        ),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  void _focusFirstMovieSafely() {
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
    final moviesFuture = ref
        .read(vodServiceProvider)
        .getMoviesByCategory(widget.categoryId, offset: 0, limit: 20);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          SizedBox(
            height: widget.screenWidth > 600 ? 230 : 190,
            child: FutureBuilder<List<MovieModel>>(
              future: moviesFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final movies = snapshot.data!;
                if (_itemFocus.length != movies.length) {
                  for (final n in _itemFocus) {
                    n.dispose();
                  }
                  _itemFocus
                    ..clear()
                    ..addAll(List.generate(movies.length, (_) => FocusNode()));
                  _itemKeys.clear();
                  for (int i = 0; i < movies.length; i++) {
                    _itemKeys[i] = GlobalKey();
                  }
                  if (_autofocusIndex >= movies.length) {
                    _autofocusIndex = 0;
                  }

                  if (_pendingFocusToFirst) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) _focusFirstMovieSafely();
                    });
                  }
                }

                return FocusTraversalGroup(
                  policy: ReadingOrderTraversalPolicy(),
                  descendantsAreFocusable: true,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                    itemCount: movies.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final movie = movies[index];
                      final isLoading = widget.loadingIndex == index;
                      final focusNode = _itemFocus[index];
                      final itemKey = _itemKeys[index]!;

                      final itemWidth = widget.screenWidth > 900
                          ? 150.0
                          : widget.screenWidth > 600
                          ? 130.0
                          : 110.0;

                      return Focus(
                        onKeyEvent: (node, event) {
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
                          autofocus: index == _autofocusIndex,
                          shortcuts: const {
                            SingleActivator(LogicalKeyboardKey.select):
                                ActivateIntent(),
                            SingleActivator(LogicalKeyboardKey.enter):
                                ActivateIntent(),
                          },
                          actions: {
                            ActivateIntent: CallbackAction<ActivateIntent>(
                              onInvoke: (_) {
                                _openMovie(context, movie, index);
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
                            onTap: () => _openMovie(context, movie, index),
                            child: AnimatedScale(
                              duration: const Duration(milliseconds: 120),
                              scale: focusNode.hasFocus ? 1.06 : 1.0,
                              child: AnimatedContainer(
                                width: itemWidth,
                                height: double.infinity,
                                duration: const Duration(milliseconds: 120),
                                decoration: BoxDecoration(
                                  border: focusNode.hasFocus
                                      ? Border.all(
                                          color: Colors.redAccent,
                                          width: 2,
                                        )
                                      : null,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: focusNode.hasFocus
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
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CachedNetworkImage(
                                      imageUrl: movie.streamIcon,
                                      fit: BoxFit.cover,
                                      memCacheWidth: 420,
                                      placeholder: (context, url) =>
                                          const ColoredBox(
                                            color: Colors.black12,
                                            child: Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          ),
                                      errorWidget: (context, url, error) =>
                                          const Icon(
                                            Icons.error,
                                            color: Colors.red,
                                          ),
                                    ),
                                    if (isLoading)
                                      Container(
                                        color: Colors.black.withValues(
                                          alpha: 0.35,
                                        ),
                                        child: const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: CircularProgressIndicator(
                                            color: Colors.redAccent,
                                          ),
                                        ),
                                      ),
                                  ],
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              widget.categoryName,
              textAlign: TextAlign.start,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          Focus(
            focusNode: _seeAllFocus,
            canRequestFocus: true,
            onFocusChange: (f) => setState(() => _seeAllHasFocus = f),
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent) {
                final isSelect =
                    event.logicalKey == LogicalKeyboardKey.enter ||
                    event.logicalKey == LogicalKeyboardKey.select ||
                    event.logicalKey == LogicalKeyboardKey.space ||
                    event.logicalKey == LogicalKeyboardKey.numpadEnter;
                if (isSelect) {
                  _openSeeAll();
                  return KeyEventResult.handled;
                }
                if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                  _focusFirstMovieSafely();
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
                      ? Border.all(color: Colors.redAccent, width: 2)
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.redAccent,
                    ),
                    SizedBox(width: 6),
                    Text(
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
    );
  }
}
