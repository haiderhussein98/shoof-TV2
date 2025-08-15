import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shoof_tv/data/models/series_model.dart';

class SeriesService {
  final String serverUrl;
  final String username;
  final String password;

  SeriesService(this.serverUrl, this.username, this.password);

  // نفك JSON دائمًا من البايتات كـ UTF-8 لتجنّب مشاكل الترميز (Ø..Ù..)
  dynamic _decodeUtf8(http.Response r) => jsonDecode(utf8.decode(r.bodyBytes));

  // تنظيف النص: إزالة NUL وضمان كونه String
  String _clean(Object? v) => (v?.toString() ?? '').replaceAll('\u0000', '');

  Future<Map<String, List<Map<String, dynamic>>>> getSeriesInfo(
    int seriesId,
  ) async {
    final url = Uri.parse(
      '$serverUrl/player_api.php?username=$username&password=$password&action=get_series_info&series_id=$seriesId',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = _decodeUtf8(response);

      final episodesJson =
          (data is Map<String, dynamic>) ? data['episodes'] as Map? : null;

      if (episodesJson == null) return {};

      final Map<String, List<Map<String, dynamic>>> grouped = {};

      episodesJson.forEach((seasonKey, episodeList) {
        final season = seasonKey.toString();
        final episodes = (episodeList as List?) ?? const [];

        grouped[season] = episodes.map<Map<String, dynamic>>((episode) {
          final m = episode as Map;
          final id = _clean(m['id']);
          final titleRaw = _clean(m['title']);
          final title = titleRaw.isEmpty ? 'بدون عنوان' : titleRaw;
          return {
            'id': id,
            'title': title,
          };
        }).toList();
      });

      return grouped;
    } else {
      throw Exception('فشل تحميل بيانات الحلقات (رمز ${response.statusCode})');
    }
  }

  Future<List<SeriesModel>> getSeries({
    required int offset,
    int limit = 3000,
  }) async {
    final url = Uri.parse(
      '$serverUrl/player_api.php?username=$username&password=$password&action=get_series',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonList = _decodeUtf8(response) as List;
      final paged = jsonList.skip(offset).take(limit).toList();
      return paged
          .map((json) =>
              SeriesModel.fromJson(json, serverUrl, username, password))
          .toList();
    } else {
      throw Exception('فشل تحميل المسلسلات (رمز ${response.statusCode})');
    }
  }

  Future<List<SeriesModel>> getSeriesByCategory(
    String categoryId, {
    required int offset,
    int limit = 2000,
  }) async {
    final url = Uri.parse(
      '$serverUrl/player_api.php?username=$username&password=$password&action=get_series',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonList = _decodeUtf8(response) as List;
      final filtered = jsonList
          .where(
              (json) => (json as Map)['category_id'].toString() == categoryId)
          .toList();
      final paged = filtered.skip(offset).take(limit).toList();
      return paged
          .map((json) =>
              SeriesModel.fromJson(json, serverUrl, username, password))
          .toList();
    } else {
      throw Exception('فشل تحميل مسلسلات التصنيف (رمز ${response.statusCode})');
    }
  }

  Future<List<Map<String, String>>> getSeriesCategories() async {
    final url = Uri.parse(
      '$serverUrl/player_api.php?username=$username&password=$password&action=get_series_categories',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonList = _decodeUtf8(response) as List;
      return jsonList.map<Map<String, String>>((json) {
        final m = json as Map;
        return {
          'id': _clean(m['category_id']),
          'name': _clean(m['category_name']),
        };
      }).toList();
    } else {
      throw Exception(
          'فشل تحميل تصنيفات المسلسلات (رمز ${response.statusCode})');
    }
  }
}
