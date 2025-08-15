import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoof_tv/domain/providers/core_providers.dart';
import 'package:shoof_tv/presentation/screens/settiings/widgets/speed_test_card.dart';
import 'package:shoof_tv/presentation/screens/splash_screen.dart';
import 'package:shoof_tv/presentation/viewmodels/auth_provider.dart';
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

    final physics = isCupertino(context)
        ? const BouncingScrollPhysics()
        : const ClampingScrollPhysics();

    return PlatformScaffold(
      backgroundColor: Colors.black,
      appBar: PlatformAppBar(
        title: const Text("Setting", style: TextStyle(fontSize: 15)),
        material: (_, __) => MaterialAppBarData(
          backgroundColor: Colors.black,
          elevation: 0,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 15.0),
              child: Image.asset('assets/images/logo.png'),
            ),
          ],
        ),
        cupertino: (_, __) => CupertinoNavigationBarData(
          backgroundColor: Colors.black,
          trailing: Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Image.asset('assets/images/logo.png'),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: physics,
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
            const SizedBox(height: 20),
            const SpeedTestCard(),
            const SizedBox(height: 30),

            // Dark mode row
            PlatformWidget(
              material: (_, __) => Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.color_lens, color: Colors.white),
                    title: const Text(
                      "Ø§Ù„ÙˆØ¶Ø¹ Ø§Ù„Ø¯Ø§ÙƒÙ†",
                      style: TextStyle(color: Colors.white),
                    ),
                    trailing: PlatformSwitch(
                      value: true,
                      onChanged: (_) {},
                      material: (_, __) =>
                          MaterialSwitchData(activeColor: Colors.green),
                    ),
                  ),
                  const Divider(color: Colors.white24),
                ],
              ),
              cupertino: (_, __) => Column(
                children: [
                  CupertinoListTile(
                    padding: EdgeInsets.zero,
                    backgroundColor: Colors.transparent,
                    leading: const Icon(
                      CupertinoIcons.paintbrush,
                      color: Colors.white,
                    ),
                    title: const Text(
                      "Ø§Ù„ÙˆØ¶Ø¹ Ø§Ù„Ø¯Ø§ÙƒÙ†",
                      style: TextStyle(color: Colors.white),
                    ),
                    trailing: PlatformSwitch(value: true, onChanged: (_) {}),
                  ),
                  const Divider(color: Colors.white24, height: 1),
                ],
              ),
            ),

            // Logout row
            PlatformWidget(
              material: (_, __) => ListTile(
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
                  if (!context.mounted) return;
                  container.invalidate(authProvider);

                  navigator.pushAndRemoveUntil(
                    platformPageRoute(
                      context: context,
                      builder: (_) => const SplashScreen(),
                    ),
                    (route) => false,
                  );
                },
              ),
              cupertino: (_, __) => CupertinoListTile(
                padding: EdgeInsets.zero,
                backgroundColor: Colors.transparent,
                leading: const Icon(
                  CupertinoIcons.square_arrow_right,
                  color: Colors.white,
                ),
                title: const Text(
                  "Logout",
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  final navigator = Navigator.of(context);
                  final container = ProviderScope.containerOf(context);

                  await ref.read(authProvider.notifier).logout();
                  if (!context.mounted) return;
                  container.invalidate(authProvider);

                  navigator.pushAndRemoveUntil(
                    platformPageRoute(
                      context: context,
                      builder: (_) => const SplashScreen(),
                    ),
                    (route) => false,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

