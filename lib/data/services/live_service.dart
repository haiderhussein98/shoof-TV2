import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shoof_tv/data/models/channel_model.dart';

class LiveService {
  final String serverUrl;
  final String username;
  final String password;

  LiveService(this.serverUrl, this.username, this.password);

  Future<List<ChannelModel>> getLiveChannels({
    required int offset,
    int limit = 30,
  }) async {
    final url = Uri.parse(
      '$serverUrl/player_api.php?username=$username&password=$password&action=get_live_streams',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonList = jsonDecode(response.body) as List;
      final paged = jsonList.skip(offset).take(limit).toList();
      return paged
          .map(
            (json) =>
                ChannelModel.fromJson(json, serverUrl, username, password),
          )
          .toList();
    } else {
      throw Exception("فشل تحميل قنوات البث المباشر");
    }
  }

  Future<List<Map<String, String>>> getLiveCategories() async {
    final url = Uri.parse(
      '$serverUrl/player_api.php?username=$username&password=$password&action=get_live_categories',
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
      throw Exception("فشل تحميل أصناف البث المباشر");
    }
  }

  Future<List<ChannelModel>> getLiveChannelsByCategory(
    String categoryId, {
    required int offset,
    int limit = 30,
  }) async {
    final url = Uri.parse(
      '$serverUrl/player_api.php?username=$username&password=$password&action=get_live_streams',
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
            (json) =>
                ChannelModel.fromJson(json, serverUrl, username, password),
          )
          .toList();
    } else {
      throw Exception("فشل تحميل قنوات التصنيف");
    }
  }
}
