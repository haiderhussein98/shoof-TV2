import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoof_iptv/domain/providers/vod_providers.dart';
import '../../../../data/models/movie_model.dart.dart';

final vodViewModelProvider = ChangeNotifierProvider<VodViewModel>((ref) {
  return VodViewModel(ref);
});

class VodViewModel extends ChangeNotifier {
  final Ref ref;

  VodViewModel(this.ref);

  Future<List<Map<String, String>>> getVodCategories() {
    return ref.read(vodServiceProvider).getVodCategories();
  }

  Future<List<MovieModel>> searchMovies(String query) {
    return ref
        .read(vodServiceProvider)
        .getVOD(offset: 0, limit: 300, searchQuery: query);
  }

  Future<MovieModel> getMovieDetails(int streamId) {
    return ref.read(vodServiceProvider).getMovieDetails(streamId);
  }

  Future<List<MovieModel>> getMoviesByCategory(String categoryId) {
    return ref
        .read(vodServiceProvider)
        .getMoviesByCategory(categoryId, offset: 0, limit: 20);
  }
}
