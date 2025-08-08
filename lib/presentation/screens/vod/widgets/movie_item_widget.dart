import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shoof_tv/data/models/movie_model.dart.dart';
import 'package:shoof_tv/presentation/screens/vod/movie_details_screen.dart';
import 'package:shoof_tv/presentation/screens/vod/viewmodel/vod_viewmodel.dart';

class MovieItemWidget extends ConsumerStatefulWidget {
  final MovieModel movie;

  const MovieItemWidget({super.key, required this.movie});

  @override
  ConsumerState<MovieItemWidget> createState() => _MovieItemWidgetState();
}

class _MovieItemWidgetState extends ConsumerState<MovieItemWidget> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (isLoading) return;

        setState(() => isLoading = true);

        try {
          final movieDetails = await ref
              .read(vodViewModelProvider)
              .getMovieDetails(widget.movie.streamId);

          if (!context.mounted) return;

          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MovieDetailsScreen(movie: movieDetails),
            ),
          );
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('فشل تحميل تفاصيل الفيلم'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        } finally {
          if (mounted) setState(() => isLoading = false);
        }
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CachedNetworkImage(
              imageUrl: widget.movie.streamIcon,
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
                child: CircularProgressIndicator(color: Colors.redAccent),
              ),
            ),
        ],
      ),
    );
  }
}
