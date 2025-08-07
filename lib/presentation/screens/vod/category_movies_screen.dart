import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shoof_iptv/data/models/movie_model.dart.dart';
import 'package:shoof_iptv/domain/providers/vod_providers.dart';
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
      final newMovies = await ref
          .read(vodServiceProvider)
          .getMoviesByCategory(
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
              child: TextField(
                controller: _searchController,
                onChanged: (val) => _searchQuery.value = val,
                decoration: InputDecoration(
                  hintText: 'ابحث عن فيلم...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.grey[850],
                  prefixIcon: const Icon(Icons.search, color: Colors.white),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(color: Colors.white),
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

                      final movie = filtered[index];

                      return GestureDetector(
                        onTap: () {
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
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: movie.streamIcon,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const ColoredBox(
                              color: Colors.black12,
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error, color: Colors.red),
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
