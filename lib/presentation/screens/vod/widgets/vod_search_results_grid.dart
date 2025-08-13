import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoof_tv/presentation/screens/vod/viewmodel/vod_viewmodel.dart';
import '../../../../data/models/movie_model.dart.dart';
import '../movie_details_screen.dart';

class VodSearchResultsGrid extends ConsumerStatefulWidget {
  final Future<List<MovieModel>> searchResults;

  const VodSearchResultsGrid({super.key, required this.searchResults});

  @override
  ConsumerState<VodSearchResultsGrid> createState() =>
      _VodSearchResultsGridState();
}

class _VodSearchResultsGridState extends ConsumerState<VodSearchResultsGrid> {
  int? loadingIndex;
  bool _isNavigating = false;
  final List<FocusNode> _focusNodes = [];

  @override
  void dispose() {
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  bool _isAndroidTV(BuildContext context) {
    return defaultTargetPlatform == TargetPlatform.android &&
        MediaQuery.of(context).navigationMode == NavigationMode.directional;
  }

  Future<void> _openMovie(MovieModel movie, int index) async {
    if (_isNavigating) return;

    setState(() {
      _isNavigating = true;
      loadingIndex = index;
    });

    try {
      final movieDetails = await ref
          .read(vodViewModelProvider)
          .getMovieDetails(movie.streamId);

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MovieDetailsScreen(movie: movieDetails),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('فشل تحميل تفاصيل الفيلم'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isNavigating = false;
          loadingIndex = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTv = _isAndroidTV(context);

    return FutureBuilder<List<MovieModel>>(
      future: widget.searchResults,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final results = snapshot.data!;
        if (results.isEmpty) {
          return const Center(
            child: Text('لا توجد نتائج', style: TextStyle(color: Colors.white)),
          );
        }

        if (_focusNodes.length != results.length) {
          _focusNodes
            ..forEach((n) => n.dispose())
            ..clear();
          _focusNodes.addAll(List.generate(results.length, (_) => FocusNode()));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: screenWidth > 900
                ? 5
                : screenWidth > 600
                ? 4
                : 3,
            childAspectRatio: 0.7,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final movie = results[index];
            final isLoading = loadingIndex == index;
            final focusNode = _focusNodes[index];

            return FocusableActionDetector(
              focusNode: focusNode,
              // تركيز تلقائي فقط على TV
              autofocus: isTv && index == 0,
              // اختصارات الريموت فقط على TV
              shortcuts: isTv
                  ? const {
                      SingleActivator(LogicalKeyboardKey.select):
                          ActivateIntent(),
                      SingleActivator(LogicalKeyboardKey.enter):
                          ActivateIntent(),
                    }
                  : const <ShortcutActivator, Intent>{},
              actions: isTv
                  ? {
                      ActivateIntent: CallbackAction<ActivateIntent>(
                        onInvoke: (_) {
                          _openMovie(movie, index);
                          return null;
                        },
                      ),
                    }
                  : const <Type, Action<Intent>>{},
              onShowFocusHighlight: (hasFocus) {
                if (isTv) {
                  setState(() {});
                }
              },
              child: GestureDetector(
                onTap: () => _openMovie(movie, index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    border: isTv && focusNode.hasFocus
                        ? Border.all(color: Colors.redAccent, width: 2)
                        : null,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl: movie.streamIcon,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error, color: Colors.red),
                        ),
                      ),
                      if (isLoading)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha((0.6 * 255).toInt()),
                            borderRadius: BorderRadius.circular(10),
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
            );
          },
        );
      },
    );
  }
}
