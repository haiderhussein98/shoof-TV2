import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shoof_tv/domain/providers/core_providers.dart';
import 'package:shoof_tv/domain/providers/user_providers.dart';
import '../../presentation/viewmodels/auth_provider.dart';

Future<bool> loginUser({
  required WidgetRef ref,
  required String rawServer,
  required String username,
  required String password,
}) async {
  try {
    final cleanServer = rawServer
        .replaceAll(RegExp(r'^(https?:\/\/)'), '')
        .replaceAll(RegExp(r'/+$'), '')
        .trim();

    final urlsToTry = [
      'https://$cleanServer',
      'http://$cleanServer',
      'https://$cleanServer:80',
      'http://$cleanServer:80',
      'http://$cleanServer/c',
    ];

    String? workingServer;

    for (final base in urlsToTry) {
      final url = '$base/player_api.php?username=$username&password=$password';
      try {
        final res =
            await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
        final json = jsonDecode(res.body);
        if (json is Map && json.containsKey('user_info')) {
          workingServer = base;
          break;
        }
      } catch (_) {}
    }

    if (workingServer == null) return false;

    ref.read(serverProvider.notifier).state = workingServer;
    ref.read(usernameProvider.notifier).state = username;
    ref.read(passwordProvider.notifier).state = password;

    await ref
        .read(authProvider.notifier)
        .login(server: workingServer, username: username, password: password);
    await ref.read(userInfoInitializerProvider.future);

    return true;
  } catch (e) {
    return false;
  }
}
