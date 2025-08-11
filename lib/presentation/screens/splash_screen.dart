import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'home/home_screen.dart';
import 'login/login_screen.dart';
import 'package:shoof_tv/presentation/viewmodels/auth_provider.dart';
import 'package:shoof_tv/core/responsive.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return authState.when(
      loading: () => Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Padding(
            padding: context.pagePadding,
            child: CenteredMaxWidth(
              child: const Center(child: CircularProgressIndicator.adaptive()),
            ),
          ),
        ),
      ),
      error: (_, __) => const LoginScreen(),
      data: (isLoggedIn) =>
          isLoggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}
