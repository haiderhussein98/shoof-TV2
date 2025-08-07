import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoof_iptv/domain/providers/core_providers.dart';
import 'package:shoof_iptv/presentation/screens/splash_screen.dart';
import 'package:shoof_iptv/presentation/viewmodels/auth_provider.dart';
import 'widgets/subscription_info_card.dart';
import 'widgets/user_info_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final username = ref.watch(usernameProvider);
    final startDate = ref.watch(subscriptionStartProvider);
    final endDate = ref.watch(subscriptionEndProvider);

    final now = DateTime.now();
    final isActive = now.isAfter(startDate) && now.isBefore(endDate);

    final formattedStart =
        '${startDate.day.toString().padLeft(2, '0')}/${startDate.month.toString().padLeft(2, '0')}/${startDate.year}';
    final formattedEnd =
        '${endDate.day.toString().padLeft(2, '0')}/${endDate.month.toString().padLeft(2, '0')}/${endDate.year}';

    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15.0),
            child: Image.asset('assets/images/logo.png'),
          ),
        ],
        title: const Text("Setting", style: TextStyle(fontSize: 15)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            UserInfoCard(
              username: username,
              isActive: isActive,
              isTablet: isTablet,
            ),
            const SizedBox(height: 20),
            SubscriptionInfoCard(
              startDate: formattedStart,
              endDate: formattedEnd,
              isTablet: isTablet,
            ),
            const SizedBox(height: 30),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.color_lens, color: Colors.white),
              title: const Text(
                "الوضع الداكن",
                style: TextStyle(color: Colors.white),
              ),
              trailing: Switch(
                value: true,
                onChanged: (_) {},
                activeColor: Colors.green,
              ),
            ),
            const Divider(color: Colors.white24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.logout, color: Colors.white),
              title: const Text(
                "Logout",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () async {
                final navigator = Navigator.of(context);
                final container = ProviderScope.containerOf(context);

                await ref.read(authProvider.notifier).logout();
                container.invalidate(authProvider);
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const SplashScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
