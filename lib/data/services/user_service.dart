import 'dart:convert';
import 'package:http/http.dart' as http;

class UserService {
  final String serverUrl;
  final String username;
  final String password;

  UserService(this.serverUrl, this.username, this.password);

  Future<bool> validateLogin() async {
    final url = Uri.parse(
      '$serverUrl/player_api.php?username=$username&password=$password',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['user_info']?['auth'] == 1;
    }
    return false;
  }

  Future<Map<String, dynamic>> getUserInfo() async {
    final url = Uri.parse(
      '$serverUrl/player_api.php?username=$username&password=$password',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final userInfo = data['user_info'];
      if (userInfo == null) throw Exception("Ø§Ù„Ø­Ø³Ø§Ø¨ Ù…Ù†ØªÙ‡ÙŠ Ø£Ùˆ ØºÙŠØ± ØµØ§Ù„Ø­");
      return userInfo;
    } else {
      throw Exception("ÙØ´Ù„ ØªØ­Ù…ÙŠÙ„ Ø¨ÙŠØ§Ù†Ø§Øª Ø§Ù„Ù…Ø³ØªØ®Ø¯Ù…");
    }
  }
}

