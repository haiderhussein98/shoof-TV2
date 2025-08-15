import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shoof_tv/data/models/movie_model.dart';

class VodService {
  final String serverUrl;
  final String username;
  final String password;

  VodService(this.serverUrl, this.username, this.password);

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
      final jsonList = jsonDecode(response.body) as List;

      final filteredList = searchQuery != null && searchQuery.trim().isNotEmpty
          ? jsonList.where((json) {
              final name = (json['name'] ?? '').toString().toLowerCase();
              return name.contains(searchQuery.toLowerCase());
            }).toList()
          : jsonList;

      final paged = filteredList.skip(offset).take(limit).toList();

      return paged
          .map(
            (json) => MovieModel.fromJson(json, serverUrl, username, password),
          )
          .toList();
    } else {
      throw Exception("ÙØ´Ù„ ØªØ­Ù…ÙŠÙ„ Ø§Ù„Ø£ÙÙ„Ø§Ù….");
    }
  }

  Future<MovieModel> getMovieDetails(int streamId) async {
    final url = Uri.parse(
      '$serverUrl/player_api.php?username=$username&password=$password&action=get_vod_info&vod_id=$streamId',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final info = json['info'];
      if (info == null) throw Exception("Ø§Ù„Ø¨ÙŠØ§Ù†Ø§Øª ØºÙŠØ± Ù…ØªÙˆÙØ±Ø©");

      final name = info['name'] ?? 'Unknown';
      final image = info['movie_image'] ?? '';
      final containerExtension = info['container_extension'] ?? 'mkv';
      final releaseDate = info['releasedate'] ?? info['Release Date'] ?? '';
      final duration = info['duration'] ?? '';
      final cast = info['cast'] ?? '';
      final director = info['director'] ?? '';
      final description = info['plot'] ?? '';
      final youtubeTrailer = info['youtube_trailer'] ?? '';
      final rating = info['rating']?.toString() ?? '';

      final realStreamUrl = info['movie_data']?['stream_url'];
      final fallbackStreamUrl =
          '$serverUrl/movie/$username/$password/$streamId.$containerExtension';

      String workingUrl = fallbackStreamUrl;
      if (realStreamUrl != null && realStreamUrl.isNotEmpty) {
        try {
          final headResp = await http.head(Uri.parse(realStreamUrl));
          if (headResp.statusCode == 200) {
            workingUrl = realStreamUrl;
          }
        } catch (_) {}
      }

      final movieMap = {
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
      throw Exception("ÙØ´Ù„ ØªØ­Ù…ÙŠÙ„ Ø¨ÙŠØ§Ù†Ø§Øª Ø§Ù„ÙÙŠÙ„Ù…");
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
      final jsonList = jsonDecode(response.body) as List;
      final filtered = jsonList
          .where((json) => json['category_id'].toString() == categoryId)
          .toList();
      final paged = filtered.skip(offset).take(limit).toList();
      return paged
          .map(
            (json) => MovieModel.fromJson(json, serverUrl, username, password),
          )
          .toList();
    } else {
      throw Exception("ÙØ´Ù„ ØªØ­Ù…ÙŠÙ„ Ø£ÙÙ„Ø§Ù… Ø§Ù„ØªØµÙ†ÙŠÙ");
    }
  }

  Future<List<Map<String, String>>> getVodCategories() async {
    final url = Uri.parse(
      '$serverUrl/player_api.php?username=$username&password=$password&action=get_vod_categories',
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
      throw Exception("ÙØ´Ù„ ØªØ­Ù…ÙŠÙ„ ØªØµÙ†ÙŠÙØ§Øª VOD");
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
      final jsonList = jsonDecode(response.body) as List;
      final related = jsonList
          .where((json) => json['category_id'].toString() == categoryId)
          .toList();
      final paged = related.skip(offset).take(limit).toList();
      return paged
          .map(
            (json) => MovieModel.fromJson(json, serverUrl, username, password),
          )
          .toList();
    } else {
      throw Exception("ÙØ´Ù„ ØªØ­Ù…ÙŠÙ„ Ø§Ù„Ø£ÙÙ„Ø§Ù… Ø§Ù„Ù…Ø´Ø§Ø¨Ù‡Ø©");
    }
  }
}

