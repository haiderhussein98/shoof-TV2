import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoof_tv/data/models/movie_model.dart';
import 'package:shoof_tv/domain/providers/vod_providers.dart';
import 'movie_details_screen.dart';

class CategoryMoviesScreen extends ConsumerStatefulWidget {
  final String categoryId;
  final String categoryName;

  const CategoryMoviesScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  ConsumerState<CategoryMoviesScreen> createState() =>
      _CategoryMoviesScreenState();
}

class _CategoryMoviesScreenState extends ConsumerState<CategoryMoviesScreen>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<String> _searchQuery = ValueNotifier('');

  final List<MovieModel> _movies = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _offset = 0;
  final int _limit = 30;

  final Map<int, FocusNode> _focusMap = {};
  final Set<int> _focusedIds = <int>{};

  FocusNode _nodeFor(MovieModel m) => _focusMap.putIfAbsent(
        m.streamId,
        () => FocusNode(debugLabel: 'movie_${m.streamId}'),
      );

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadMore();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading) return;
    _isLoading = true;

    try {
      final newMovies = await ref.read(vodServiceProvider).getMoviesByCategory(
            widget.categoryId,
            offset: _offset,
            limit: _limit,
          );

      if (!mounted) return;

      setState(() {
        _movies.addAll(newMovies);
        _offset += _limit;
        _hasMore = newMovies.length == _limit;
      });
    } catch (_) {
      setState(() => _hasMore = false);
    }

    _isLoading = false;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchQuery.dispose();
    for (final node in _focusMap.values) {
      node.dispose();
    }
    _focusMap.clear();
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

    final appBar = PlatformAppBar(
      title: Text(widget.categoryName, style: const TextStyle(fontSize: 12)),
      material: (_, __) => MaterialAppBarData(
        backgroundColor: Colors.black,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 15.0),
            child: Image(image: AssetImage('assets/images/logo.png')),
          ),
        ],
      ),
      cupertino: (_, __) => CupertinoNavigationBarData(
        backgroundColor: Colors.black,
        trailing: const Padding(
          padding: EdgeInsets.only(right: 8.0),
          child: Image(image: AssetImage('assets/images/logo.png')),
        ),
      ),
    );

    return PlatformScaffold(
      appBar: appBar,
      material: (_, __) => MaterialScaffoldData(backgroundColor: Colors.black),
      cupertino: (_, __) =>
          CupertinoPageScaffoldData(backgroundColor: Colors.black),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: _SearchField(
                controller: _searchController,
                onSubmit: (val) => _searchQuery.value = val,
                onClear: () {
                  _searchController.clear();
                  _searchQuery.value = '';
                },
              ),
            ),
            Expanded(
              child: ValueListenableBuilder<String>(
                valueListenable: _searchQuery,
                builder: (context, query, _) {
                  final filtered = query.isEmpty
                      ? _movies
                      : _movies
                          .where(
                            (m) => m.name.toLowerCase().contains(
                                  query.toLowerCase(),
                                ),
                          )
                          .toList();

                  if (filtered.isEmpty && !_isLoading) {
                    return const Center(
                      child: Text(
                        'لم يتم العثور على أفلام.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  return GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    itemCount: filtered.length + (_hasMore ? 1 : 0),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: getCrossAxisCount(),
                      crossAxisSpacing: 5,
                      mainAxisSpacing: 5,
                      childAspectRatio: 0.7,
                    ),
                    itemBuilder: (context, index) {
                      if (index >= filtered.length) {
                        return const Center(
                          child: SizedBox(
                            height: 40,
                            width: 40,
                            child: PlatformCircularProgressIndicator(),
                          ),
                        );
                      }

                      final movie = filtered[index];
                      final node = _nodeFor(movie);
                      final hasFocus = _focusedIds.contains(movie.streamId);

                      void openDetails() {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) =>
                                MovieDetailsScreen(movie: movie),
                            transitionsBuilder: (_, animation, __, child) =>
                                FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                            transitionDuration: const Duration(
                              milliseconds: 300,
                            ),
                          ),
                        );
                      }

                      return FocusableActionDetector(
                        focusNode: node,
                        autofocus: index == 0,
                        onShowFocusHighlight: (f) {
                          setState(() {
                            if (f) {
                              _focusedIds.add(movie.streamId);
                            } else {
                              _focusedIds.remove(movie.streamId);
                            }
                          });
                        },
                        shortcuts: const {
                          SingleActivator(LogicalKeyboardKey.select):
                              ActivateIntent(),
                          SingleActivator(LogicalKeyboardKey.enter):
                              ActivateIntent(),
                        },
                        actions: {
                          ActivateIntent: CallbackAction<ActivateIntent>(
                            onInvoke: (_) {
                              openDetails();
                              return null;
                            },
                          ),
                        },
                        child: InkWell(
                          onTap: openDetails,
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            curve: Curves.easeOut,
                            transform: hasFocus
                                ? (Matrix4.identity()..scale(1.00))
                                : Matrix4.identity(),
                            decoration: BoxDecoration(
                              border: hasFocus
                                  ? Border.all(
                                      color: Colors.redAccent,
                                      width: 2,
                                    )
                                  : null,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: hasFocus
                                  ? [
                                      BoxShadow(
                                        color: Colors.redAccent.withValues(
                                          alpha: 0.2,
                                        ),
                                        blurRadius: 12,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: movie.streamIcon,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const ColoredBox(
                                  color: Colors.black12,
                                  child: Center(
                                    child: PlatformCircularProgressIndicator(),
                                  ),
                                ),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.error, color: Colors.red),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
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

class _SearchField extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSubmit;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.onSubmit,
    required this.onClear,
  });

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final FocusNode _wrapperNode = FocusNode(debugLabel: 'search_wrapper');
  final FocusNode _textNode = FocusNode(debugLabel: 'search_text');

  bool _editing = false;

  bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  @override
  void dispose() {
    _wrapperNode.dispose();
    _textNode.dispose();
    super.dispose();
  }

  void _startEditing() {
    if (_editing) return;
    setState(() => _editing = true);
    _textNode.requestFocus();
    Future.microtask(
      () => SystemChannels.textInput.invokeMethod('TextInput.show'),
    );
  }

  void _stopEditing() {
    if (!_editing) return;
    setState(() => _editing = false);
    _textNode.unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (!_isAndroid) return KeyEventResult.ignored;
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.space) {
      _startEditing();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.goBack) {
      _stopEditing();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _wrapperNode,
      onKeyEvent: _handleKey,
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: widget.controller,
        builder: (context, value, _) {
          final showClear = value.text.isNotEmpty;
          return TextField(
            controller: widget.controller,
            focusNode: _textNode,
            readOnly: _isAndroid ? !_editing : false,
            onTap: _startEditing,
            onSubmitted: (val) {
              widget.onSubmit(val);
              _stopEditing();
            },
            onEditingComplete: _stopEditing,
            style: const TextStyle(color: Colors.white),
            cursorColor: Colors.white70,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'ابحث عن فيلم...',
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Colors.grey[850],
              prefixIcon: const Icon(Icons.search, color: Colors.white),
              suffixIcon: showClear
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white54),
                      onPressed: () {
                        widget.onClear();
                        if (_editing) _textNode.requestFocus();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          );
        },
      ),
    );
  }
}
