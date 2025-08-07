import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shoof_iptv/domain/providers/core_providers.dart';
import 'package:shoof_iptv/domain/providers/user_providers.dart';
import 'package:shoof_iptv/presentation/screens/live/viewmodel/live_viewmodel.dart';
import 'package:shoof_iptv/presentation/screens/series/viewmodel/series_viewmodel.dart';
import 'package:shoof_iptv/presentation/screens/vod/viewmodel/vod_viewmodel.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<bool>>(
  (ref) => AuthNotifier(ref),
);

const _secureStorage = FlutterSecureStorage();

class AuthNotifier extends StateNotifier<AsyncValue<bool>> {
  final Ref? ref;

  AuthNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadLoginStatus();
  }

  Future<void> _loadLoginStatus() async {
    if (ref == null) return;

    try {
      final server = await _secureStorage.read(key: 'server');
      final username = await _secureStorage.read(key: 'username');
      final password = await _secureStorage.read(key: 'password');

      if (server == null || username == null || password == null) {
        state = const AsyncValue.data(false);
        return;
      }

      ref!.read(serverProvider.notifier).state = server;
      ref!.read(usernameProvider.notifier).state = username;
      ref!.read(passwordProvider.notifier).state = password;

      await ref!.read(userInfoInitializerProvider.future);

      state = const AsyncValue.data(true);
    } catch (e, st) {
      await logout();
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> login({
    required String server,
    required String username,
    required String password,
  }) async {
    if (ref == null) return;

    try {
      ref!.read(serverProvider.notifier).state = server;
      ref!.read(usernameProvider.notifier).state = username;
      ref!.read(passwordProvider.notifier).state = password;

      await _secureStorage.write(key: 'server', value: server);
      await _secureStorage.write(key: 'username', value: username);
      await _secureStorage.write(key: 'password', value: password);

      ref!.invalidate(userInfoInitializerProvider);
      await ref!.read(userInfoInitializerProvider.future);

      state = const AsyncValue.data(true);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    if (ref == null) return;

    await _secureStorage.delete(key: 'server');
    await _secureStorage.delete(key: 'username');
    await _secureStorage.delete(key: 'password');

    ref!.invalidate(seriesViewModelProvider);
    ref!.invalidate(vodViewModelProvider);
    ref!.invalidate(liveViewModelProvider);

    ref!.read(serverProvider.notifier).state = "";
    ref!.read(usernameProvider.notifier).state = "";
    ref!.read(passwordProvider.notifier).state = "";
    ref!.read(subscriptionStartProvider.notifier).state = DateTime.now();
    ref!.read(subscriptionEndProvider.notifier).state = DateTime.now().add(
      const Duration(days: 90),
    );
    ref!.refresh(subscriptionTypeProvider.notifier).state = "غير معروف";

    state = const AsyncValue.data(false);
  }
}
