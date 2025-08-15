import 'dart:convert';
import 'package:http/http.dart' as http;

class UserService {
  final String serverUrl;
  final String username;
  final String password;

  UserService(this.serverUrl, this.username, this.password);

  dynamic _decodeUtf8(http.Response r) => jsonDecode(utf8.decode(r.bodyBytes));

  bool _asBool(dynamic v) {
    if (v is bool) return v;
    final s = v?.toString().toLowerCase();
    return s == '1' || s == 'true' || s == 'yes';
  }

  Future<bool> validateLogin() async {
    final url = Uri.parse(
      '$serverUrl/player_api.php?username=$username&password=$password',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = _decodeUtf8(response);

      dynamic auth;
      if (data is Map) {
        final userInfo = data['user_info'];
        if (userInfo is Map) {
          auth = userInfo['auth'];
        }
      }

      return _asBool(auth);
    }
    return false;
  }

  Future<Map<String, dynamic>> getUserInfo() async {
    final url = Uri.parse(
      '$serverUrl/player_api.php?username=$username&password=$password',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = _decodeUtf8(response);
      if (data is! Map || data['user_info'] == null) {
        throw Exception('الحساب منتهي أو غير صالح');
      }
      final userInfo = Map<String, dynamic>.from(data['user_info'] as Map);
      return userInfo;
    } else {
      throw Exception('فشل تحميل بيانات المستخدم (رمز ${response.statusCode})');
    }
  }
}
