import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shoof_tv/data/models/channel_model.dart';

/// خدمة القنوات المباشرة (Live) مع دعم UTF-8
class LiveService {
  final String serverUrl;
  final String username;
  final String password;

  LiveService(this.serverUrl, this.username, this.password);

  /// نفك JSON من البايتات كـ UTF-8 لتجنّب مشاكل الترميز
  dynamic _decodeUtf8(http.Response r) => jsonDecode(utf8.decode(r.bodyBytes));

  /// تنظيف النص: إزالة NUL وضمان تحويله إلى String
  String _clean(Object? v) => (v?.toString() ?? '').replaceAll('\u0000', '');

  Future<List<ChannelModel>> getLiveChannels({
    required int offset,
    int limit = 30,
  }) async {
    final url = Uri.parse(
      '$serverUrl/player_api.php?username=$username&password=$password&action=get_live_streams',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonList = _decodeUtf8(response) as List;
      final paged = jsonList.skip(offset).take(limit).toList();
      return paged
          .map((json) =>
              ChannelModel.fromJson(json, serverUrl, username, password))
          .toList();
    } else {
      throw Exception(
          'فشل تحميل قنوات البث المباشر (رمز ${response.statusCode})');
    }
  }

  Future<List<Map<String, String>>> getLiveCategories() async {
    final url = Uri.parse(
      '$serverUrl/player_api.php?username=$username&password=$password&action=get_live_categories',
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
          'فشل تحميل أصناف البث المباشر (رمز ${response.statusCode})');
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
      final jsonList = _decodeUtf8(response) as List;
      final filtered = jsonList
          .where(
              (json) => (json as Map)['category_id'].toString() == categoryId)
          .toList();
      final paged = filtered.skip(offset).take(limit).toList();
      return paged
          .map((json) =>
              ChannelModel.fromJson(json, serverUrl, username, password))
          .toList();
    } else {
      throw Exception('فشل تحميل قنوات التصنيف (رمز ${response.statusCode})');
    }
  }
}
