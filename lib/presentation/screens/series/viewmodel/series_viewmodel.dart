import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoof_iptv/data/services/series_service.dart';
import 'package:shoof_iptv/domain/providers/series_providers.dart';
import '../../../../data/models/series_model.dart';

final seriesViewModelProvider = Provider<SeriesViewModel>((ref) {
  return SeriesViewModel(ref.read(seriesServiceProvider));
});

class SeriesViewModel {
  final SeriesService _apiService;

  SeriesViewModel(this._apiService);

  Future<List<Map<String, String>>> getSeriesCategories() {
    return _apiService.getSeriesCategories();
  }

  Future<List<SeriesModel>> getSeries({int offset = 0, int limit = 1000}) {
    return _apiService.getSeries(offset: offset, limit: limit);
  }

  Future<List<SeriesModel>> searchSeries(String query) async {
    final allSeries = await getSeries();
    return allSeries
        .where((s) => s.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}
