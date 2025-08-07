import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shoof_iptv/data/models/series_model.dart';

class SeriesService {
  final String serverUrl;
  final String username;
  final String password;

  SeriesService(this.serverUrl, this.username, this.password);

  Future<Map<String, List<Map<String, dynamic>>>> getSeriesInfo(
    int seriesId,
  ) async {
    final url = Uri.parse(
      '$serverUrl/player_api.php?username=$username&password=$password&action=get_series_info&series_id=$seriesId',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);

      final episodesJson = json['episodes'] as Map<String, dynamic>?;

      if (episodesJson == null) {
        return {};
      }

      final Map<String, List<Map<String, dynamic>>> grouped = {};

      episodesJson.forEach((seasonKey, episodeList) {
        final season = seasonKey.toString();
        final episodes = episodeList as List<dynamic>;

        grouped[season] = episodes.map<Map<String, dynamic>>((episode) {
          return {
            'id': episode['id'].toString(),
            'title': episode['title'] ?? 'No Title',
          };
        }).toList();
      });

      return grouped;
    } else {
      throw Exception("فشل تحميل بيانات الحلقات");
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
      final jsonList = jsonDecode(response.body) as List;
      final paged = jsonList.skip(offset).take(limit).toList();
      return paged
          .map(
            (json) => SeriesModel.fromJson(json, serverUrl, username, password),
          )
          .toList();
    } else {
      throw Exception("فشل تحميل المسلسلات");
    }
  }

  Future<List<SeriesModel>> getSeriesByCategory(
    String categoryId, {
    required int offset,
    int limit = 30,
  }) async {
    final url = Uri.parse(
      '$serverUrl/player_api.php?username=$username&password=$password&action=get_series',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonList = jsonDecode(response.body) as List;
      final filtered = jsonList
          .where((json) => json['category_id'].toString() == categoryId)
          .toList();
      final paged = filtered.skip(offset).take(limit).toList();
      return paged
          .map(
            (json) => SeriesModel.fromJson(json, serverUrl, username, password),
          )
          .toList();
    } else {
      throw Exception("فشل تحميل مسلسلات التصنيف");
    }
  }

  Future<List<Map<String, String>>> getSeriesCategories() async {
    final url = Uri.parse(
      '$serverUrl/player_api.php?username=$username&password=$password&action=get_series_categories',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonList = jsonDecode(response.body) as List;
      return jsonList
          .map<Map<String, String>>(
            (json) => {
              'id': json['category_id'].toString(),
              'name': json['category_name'],
            },
          )
          .toList();
    } else {
      throw Exception("فشل تحميل تصنيفات المسلسلات");
    }
  }
}
