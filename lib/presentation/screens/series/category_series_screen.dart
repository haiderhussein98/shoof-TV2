import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shoof_tv/domain/providers/series_providers.dart';
import '../../../data/models/series_model.dart';
import 'series_details_screen.dart';

class CategorySeriesScreen extends ConsumerStatefulWidget {
  final String categoryId;
  final String categoryName;

  const CategorySeriesScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  ConsumerState<CategorySeriesScreen> createState() =>
      _CategorySeriesScreenState();
}

class _CategorySeriesScreenState extends ConsumerState<CategorySeriesScreen>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<String> _searchQuery = ValueNotifier('');

  final List<SeriesModel> _seriesList = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _offset = 0;
  final int _limit = 30;

  final List<FocusNode> _itemFocus = [];
  final Map<int, GlobalKey> _itemKeys = {};
  int _autofocusIndex = 0;
  bool _pendingFocusToFirst = false;

  final FocusNode _searchFocus = FocusNode(debugLabel: 'series_search');
  bool _searchEnabled = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadNextPage();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _loadNextPage();
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoading) return;
    _isLoading = true;

    try {
      final newItems = await ref
          .read(seriesServiceProvider)
          .getSeriesByCategory(
            widget.categoryId,
            offset: _offset,
            limit: _limit,
          );

      if (!mounted) return;

      setState(() {
        _seriesList.addAll(newItems);
        _offset += _limit;
        _hasMore = newItems.length == _limit;
      });
    } catch (_) {
      setState(() => _hasMore = false);
    }

    _isLoading = false;
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
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchQuery.dispose();
    for (final n in _itemFocus) {
      n.dispose();
    }
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final screenWidth = MediaQuery.of(context).size.width;

    int getCrossAxisCount() {
      if (screenWidth >= 1200) return 6;
      if (screenWidth >= 900) return 5;
      if (screenWidth >= 600) return 4;
      return 3;
    }

    final isRtl =
        const {'ar', 'fa', 'ur', 'he'}.contains(
          Localizations.localeOf(context).languageCode.toLowerCase(),
        ) ||
        Directionality.of(context) == TextDirection.rtl;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName, style: const TextStyle(fontSize: 12)),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 15.0),
            child: Image(image: AssetImage('assets/images/logo.png')),
          ),
        ],
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Directionality(
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                child: Focus(
                  onKeyEvent: (node, event) {
                    if (event is KeyDownEvent) {
                      final isEnter =
                          event.logicalKey == LogicalKeyboardKey.enter ||
                          event.logicalKey == LogicalKeyboardKey.select ||
                          event.logicalKey == LogicalKeyboardKey.numpadEnter ||
                          event.logicalKey == LogicalKeyboardKey.space;
                      if (isEnter && !_searchEnabled) {
                        setState(() => _searchEnabled = true);
                        _searchFocus.requestFocus();
                        return KeyEventResult.handled;
                      }
                      if ((event.logicalKey == LogicalKeyboardKey.escape ||
                              event.logicalKey == LogicalKeyboardKey.goBack) &&
                          _searchEnabled) {
                        setState(() => _searchEnabled = false);
                        node.requestFocus();
                        return KeyEventResult.handled;
                      }
                    }
                    return KeyEventResult.ignored;
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: !_searchEnabled && Focus.of(context).hasFocus
                          ? Border.all(
                              color: Colors.redAccent.withValues(alpha: 0.2),
                              width: 2,
                            )
                          : null,
                    ),
                    child: Focus(
                      focusNode: _searchFocus,
                      canRequestFocus: _searchEnabled,
                      skipTraversal: !_searchEnabled,
                      child: TextField(
                        controller: _searchController,
                        readOnly: !_searchEnabled,
                        onChanged: (val) => _searchQuery.value = val,
                        decoration: InputDecoration(
                          hintText: isRtl
                              ? 'ابحث عن مسلسل...'
                              : 'Search series...',
                          hintStyle: const TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: Colors.grey[850],
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.white,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ValueListenableBuilder<String>(
                valueListenable: _searchQuery,
                builder: (context, query, _) {
                  final filtered = query.isEmpty
                      ? _seriesList
                      : _seriesList
                            .where(
                              (s) => s.name.toLowerCase().contains(
                                query.toLowerCase(),
                              ),
                            )
                            .toList();

                  if (filtered.isEmpty && !_isLoading) {
                    return const Center(
                      child: Text(
                        'No series found.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  if (_itemFocus.length != filtered.length) {
                    for (final n in _itemFocus) {
                      n.dispose();
                    }
                    _itemFocus
                      ..clear()
                      ..addAll(
                        List.generate(filtered.length, (_) => FocusNode()),
                      );
                    _itemKeys.clear();
                    for (int i = 0; i < filtered.length; i++) {
                      _itemKeys[i] = GlobalKey();
                    }
                    if (_autofocusIndex >= filtered.length) {
                      _autofocusIndex = 0;
                    }
                    if (_pendingFocusToFirst) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) _focusFirstItemSafely();
                      });
                    }
                  }

                  return FocusTraversalGroup(
                    policy: ReadingOrderTraversalPolicy(),
                    descendantsAreFocusable: true,
                    child: GridView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount: filtered.length + (_hasMore ? 1 : 0),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: getCrossAxisCount(),
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.7,
                      ),
                      itemBuilder: (context, index) {
                        if (index >= filtered.length) {
                          return const Center(
                            child: SizedBox(
                              height: 40,
                              width: 40,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }

                        final series = filtered[index];
                        final focusNode = _itemFocus[index];
                        final itemKey = _itemKeys[index]!;

                        return Focus(
                          onKeyEvent: (node, event) {
                            if (event is KeyDownEvent &&
                                event.logicalKey ==
                                    LogicalKeyboardKey.arrowUp) {
                              _searchFocus.requestFocus();
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
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      transitionDuration: const Duration(
                                        milliseconds: 260,
                                      ),
                                      pageBuilder: (_, __, ___) =>
                                          SeriesDetailsScreen(series: series),
                                      transitionsBuilder:
                                          (_, animation, __, child) {
                                            final curved = CurvedAnimation(
                                              parent: animation,
                                              curve: Curves.easeOutCubic,
                                            );
                                            return FadeTransition(
                                              opacity: curved,
                                              child: ScaleTransition(
                                                scale: Tween<double>(
                                                  begin: 0.98,
                                                  end: 1,
                                                ).animate(curved),
                                                child: child,
                                              ),
                                            );
                                          },
                                    ),
                                  );
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
                              onTap: () {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    transitionDuration: const Duration(
                                      milliseconds: 260,
                                    ),
                                    pageBuilder: (_, __, ___) =>
                                        SeriesDetailsScreen(series: series),
                                    transitionsBuilder:
                                        (_, animation, __, child) {
                                          final curved = CurvedAnimation(
                                            parent: animation,
                                            curve: Curves.easeOutCubic,
                                          );
                                          return FadeTransition(
                                            opacity: curved,
                                            child: ScaleTransition(
                                              scale: Tween<double>(
                                                begin: 0.98,
                                                end: 1,
                                              ).animate(curved),
                                              child: child,
                                            ),
                                          );
                                        },
                                  ),
                                );
                              },
                              child: AnimatedScale(
                                duration: const Duration(milliseconds: 120),
                                scale: focusNode.hasFocus ? 1.06 : 1.0,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 120),
                                  decoration: BoxDecoration(
                                    border: focusNode.hasFocus
                                        ? Border.all(
                                            color: Colors.redAccent,
                                            width: 2,
                                          )
                                        : null,
                                    borderRadius: BorderRadius.circular(10),
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
                                  child: CachedNetworkImage(
                                    imageUrl: series.cover,
                                    fit: BoxFit.cover,
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
      ),
    );
  }
}
