import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

import 'package:shoof_tv/presentation/screens/series/viewmodel/series_viewmodel.dart';
import '../../../data/models/series_model.dart';
import 'widgets/series_app_bar.dart';
import 'widgets/series_category_list.dart';
import 'series_details_screen.dart';

class SeriesScreen extends ConsumerStatefulWidget {
  const SeriesScreen({super.key});

  @override
  ConsumerState<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends ConsumerState<SeriesScreen>
    with AutomaticKeepAliveClientMixin {
  late Future<List<Map<String, String>>> _categoriesFuture;
  final TextEditingController _searchController = TextEditingController();
  Future<List<SeriesModel>>? _searchResults;
  bool _isSearching = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = ref.read(seriesViewModelProvider).getSeriesCategories();
  }

  void _onSearch(String query) {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      if (mounted) {
        setState(() {
          _searchResults = null;
          _isSearching = false;
        });
      }
      return;
    }
    if (mounted) {
      setState(() {
        _isSearching = true;
        _searchResults = ref
            .read(seriesViewModelProvider)
            .searchSeries(trimmedQuery);
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    if (mounted) {
      setState(() {
        _searchResults = null;
        _isSearching = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isAndroidTvLike(BuildContext context) {
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;
    return isAndroid &&
        MediaQuery.of(context).navigationMode == NavigationMode.directional;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final physics = isCupertino(context)
        ? const BouncingScrollPhysics()
        : const ClampingScrollPhysics();

    final content = SafeArea(
      child: _isSearching && _searchResults != null
          ? _SeriesSearchResultsGrid(
              resultsFuture: _searchResults!,
              isTv: _isAndroidTvLike(context),
              physics: physics,
            )
          : FutureBuilder<List<Map<String, String>>>(
              future: _categoriesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: PlatformCircularProgressIndicator(),
                  );
                }
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'ÙØ´Ù„ ØªØ­Ù…ÙŠÙ„ Ø§Ù„ØªØµÙ†ÙŠÙØ§Øª',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }
                final categories =
                    snapshot.data ?? const <Map<String, String>>[];
                return SeriesCategoryList(categories: categories);
              },
            ),
    );

    return PlatformScaffold(
      backgroundColor: Colors.black,
      material: (_, __) => MaterialScaffoldData(
        backgroundColor: Colors.black,
        appBar: SeriesAppBar(
          searchController: _searchController,
          isSearching: _isSearching,
          onClear: _clearSearch,
          onSearch: _onSearch,
        ),
      ),
      cupertino: (_, __) => CupertinoPageScaffoldData(),
      body: isCupertino(context)
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SeriesAppBar(
                  searchController: _searchController,
                  isSearching: _isSearching,
                  onClear: _clearSearch,
                  onSearch: _onSearch,
                ),
                Expanded(child: content),
              ],
            )
          : content,
    );
  }
}

class _SeriesSearchResultsGrid extends StatefulWidget {
  final Future<List<SeriesModel>> resultsFuture;
  final bool isTv;
  final ScrollPhysics physics;

  const _SeriesSearchResultsGrid({
    required this.resultsFuture,
    required this.isTv,
    required this.physics,
  });

  @override
  State<_SeriesSearchResultsGrid> createState() =>
      _SeriesSearchResultsGridState();
}

class _SeriesSearchResultsGridState extends State<_SeriesSearchResultsGrid> {
  final List<FocusNode> _nodes = [];
  int? _loadingIndex;

  @override
  void dispose() {
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  Future<void> _openDetails(SeriesModel s, int index) async {
    if (_loadingIndex != null) return;
    setState(() => _loadingIndex = index);

    try {
      await Navigator.of(context).push(
        platformPageRoute(
          context: context,
          builder: (_) => SeriesDetailsScreen(series: s),
        ),
      );
    } finally {
      if (mounted) setState(() => _loadingIndex = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    int cross() {
      if (w >= 1200) return 6;
      if (w >= 900) return 5;
      if (w >= 600) return 4;
      return 3;
    }

    return FutureBuilder<List<SeriesModel>>(
      future: widget.resultsFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: PlatformCircularProgressIndicator());
        }
        if (snap.hasError) {
          return const Center(
            child: Text(
              'Ø­Ø¯Ø« Ø®Ø·Ø£ Ø£Ø«Ù†Ø§Ø¡ Ø§Ù„Ø¨Ø­Ø«',
              style: TextStyle(color: Colors.white),
            ),
          );
        }
        final results = snap.data ?? const <SeriesModel>[];
        if (results.isEmpty) {
          return const Center(
            child: Text(
              'Ù„Ø§ ØªÙˆØ¬Ø¯ Ù†ØªØ§Ø¦Ø¬',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        if (_nodes.length != results.length) {
          for (final n in _nodes) {
            n.dispose();
          }
          _nodes
            ..clear()
            ..addAll(List.generate(results.length, (_) => FocusNode()));
        }

        return GridView.builder(
          physics: widget.physics,
          padding: const EdgeInsets.all(12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cross(),
            childAspectRatio: 0.7,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: results.length,
          itemBuilder: (context, i) {
            final s = results[i];
            final node = _nodes[i];
            final loading = _loadingIndex == i;

            final card = ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.network(
                    s.cover,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.error, color: Colors.redAccent),
                    loadingBuilder: (ctx, child, evt) {
                      if (evt == null) return child;
                      return const ColoredBox(
                        color: Colors.black12,
                        child: Center(
                          child: PlatformCircularProgressIndicator(),
                        ),
                      );
                    },
                  ),
                  if (loading)
                    Container(
                      color: Colors.black.withValues(alpha: 0.35),
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: PlatformCircularProgressIndicator(),
                      ),
                    ),
                ],
              ),
            );

            final tile = AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              decoration: BoxDecoration(
                border: widget.isTv && node.hasFocus
                    ? Border.all(color: Colors.redAccent, width: 2)
                    : null,
                borderRadius: BorderRadius.circular(12),
                boxShadow: widget.isTv && node.hasFocus
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              clipBehavior: Clip.antiAlias,
              child: card,
            );

            return FocusableActionDetector(
              focusNode: widget.isTv ? node : null,
              autofocus: widget.isTv && i == 0,
              shortcuts: widget.isTv
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
                    _openDetails(s, i);
                    return null;
                  },
                ),
              },
              child: GestureDetector(
                onTap: () => _openDetails(s, i),
                child: tile,
              ),
            );
          },
        );
      },
    );
  }
}

