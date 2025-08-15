import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shoof_tv/data/models/movie_model.dart';

class VodService {
  final String serverUrl;
  final String username;
  final String password;

  VodService(this.serverUrl, this.username, this.password);

  // فك JSON دائمًا من البايتات كـ UTF-8 لتجنّب "Ø..Ù.."
  dynamic _decodeUtf8(http.Response r) => jsonDecode(utf8.decode(r.bodyBytes));

  // تنظيف النص: إزالة NUL وضمان كونه String
  String _clean(Object? v) => (v?.toString() ?? '').replaceAll('\u0000', '');

  Future<List<MovieModel>> getVOD({
    required int offset,
    int limit = 300,
    String? searchQuery,
  }) async {
    final url = Uri.parse(
      '$serverUrl/player_api.php?username=$username&password=$password&action=get_vod_streams',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonList = _decodeUtf8(response) as List;

      // فلترة البحث (بعد تنظيف الاسم)
      final q = (searchQuery ?? '').trim().toLowerCase();
      final filteredList = q.isNotEmpty
          ? jsonList.where((json) {
              final name = _clean((json as Map)['name']).toLowerCase();
              return name.contains(q);
            }).toList()
          : jsonList;

      final paged = filteredList.skip(offset).take(limit).toList();

      // تنظيف الاسم قبل تمريره للموديل لضمان عرض صحيح
      return paged.map((j) {
        final m = Map<String, dynamic>.from(j as Map);
        m['name'] = _clean(m['name']);
        return MovieModel.fromJson(m, serverUrl, username, password);
      }).toList();
    } else {
      throw Exception('فشل تحميل الأفلام (رمز ${response.statusCode})');
    }
  }

  Future<MovieModel> getMovieDetails(int streamId) async {
    final url = Uri.parse(
      '$serverUrl/player_api.php?username=$username&password=$password&action=get_vod_info&vod_id=$streamId',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = _decodeUtf8(response) as Map;

      final info = data['info'] as Map?;
      if (info == null) {
        throw Exception('البيانات غير متوفرة');
      }

      final name = _clean(info['name']);
      final image = _clean(info['movie_image']);
      final containerExtension = _clean(info['container_extension']).isEmpty
          ? 'mkv'
          : _clean(info['container_extension']);

      final releaseDate = _clean(info['releasedate'] ?? info['Release Date']);
      final duration = _clean(info['duration']);
      final cast = _clean(info['cast']);
      final director = _clean(info['director']);
      final description = _clean(info['plot']);
      final youtubeTrailer = _clean(info['youtube_trailer']);
      final rating = _clean(info['rating']);

      final realStreamUrl = _clean((info['movie_data'] as Map?)?['stream_url']);
      final fallbackStreamUrl =
          '$serverUrl/movie/$username/$password/$streamId.$containerExtension';

      String workingUrl = fallbackStreamUrl;
      if (realStreamUrl.isNotEmpty) {
        try {
          final headResp = await http.head(Uri.parse(realStreamUrl));
          if (headResp.statusCode == 200) {
            workingUrl = realStreamUrl;
          }
        } catch (_) {
          // تجاهل الخطأ، استخدم رابط fallback
        }
      }

      final movieMap = <String, dynamic>{
        'stream_id': streamId,
        'name': name,
        'stream_type': 'movie',
        'stream_icon': image,
        'container_extension': containerExtension,
        'stream_url': workingUrl,
        'info': {
          'Release Date': releaseDate,
          'duration': duration,
          'cast': cast,
          'director': director,
          'plot': description,
          'youtube_trailer': youtubeTrailer,
          'rating': rating,
        },
      };

      return MovieModel.fromJson(movieMap, serverUrl, username, password);
    } else {
      throw Exception('فشل تحميل بيانات الفيلم (رمز ${response.statusCode})');
    }
  }

  Future<List<MovieModel>> getMoviesByCategory(
    String categoryId, {
    required int offset,
    int limit = 30,
  }) async {
    final url = Uri.parse(
      '$serverUrl/player_api.php?username=$username&password=$password&action=get_vod_streams',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonList = _decodeUtf8(response) as List;
      final filtered = jsonList
          .where(
              (json) => (json as Map)['category_id'].toString() == categoryId)
          .toList();
      final paged = filtered.skip(offset).take(limit).toList();

      return paged.map((j) {
        final m = Map<String, dynamic>.from(j as Map);
        m['name'] = _clean(m['name']);
        return MovieModel.fromJson(m, serverUrl, username, password);
      }).toList();
    } else {
      throw Exception('فشل تحميل أفلام التصنيف (رمز ${response.statusCode})');
    }
  }

  Future<List<Map<String, String>>> getVodCategories() async {
    final url = Uri.parse(
      '$serverUrl/player_api.php?username=$username&password=$password&action=get_vod_categories',
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
      throw Exception('فشل تحميل تصنيفات VOD (رمز ${response.statusCode})');
    }
  }

  Future<List<MovieModel>> getRelatedMovies(
    String categoryId, {
    required int offset,
    int limit = 30,
  }) async {
    final url = Uri.parse(
      '$serverUrl/player_api.php?username=$username&password=$password&action=get_vod_streams',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonList = _decodeUtf8(response) as List;
      final related = jsonList
          .where(
              (json) => (json as Map)['category_id'].toString() == categoryId)
          .toList();
      final paged = related.skip(offset).take(limit).toList();

      return paged.map((j) {
        final m = Map<String, dynamic>.from(j as Map);
        m['name'] = _clean(m['name']);
        return MovieModel.fromJson(m, serverUrl, username, password);
      }).toList();
    } else {
      throw Exception(
          'فشل تحميل الأفلام المشابهة (رمز ${response.statusCode})');
    }
  }
}
