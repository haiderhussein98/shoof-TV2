import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'home/home_screen.dart';
import 'login/login_screen.dart';
import 'package:shoof_iptv/presentation/viewmodels/auth_provider.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return authState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const LoginScreen(),
      data: (isLoggedIn) =>
          isLoggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}
