import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final _storage = const FlutterSecureStorage();

  Future<void> saveLoginData({
    required String server,
    required String username,
    required String password,
  }) async {
    await _storage.write(key: 'server', value: server);
    await _storage.write(key: 'username', value: username);
    await _storage.write(key: 'password', value: password);
  }

  Future<Map<String, String?>> readLoginData() async {
    final server = await _storage.read(key: 'server');
    final username = await _storage.read(key: 'username');
    final password = await _storage.read(key: 'password');
    return {'server': server, 'username': username, 'password': password};
  }

  Future<void> clearLoginData() async {
    await _storage.deleteAll();
  }
}

