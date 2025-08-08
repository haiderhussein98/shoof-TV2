import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoof_tv/domain/providers/core_providers.dart';
import 'package:shoof_tv/presentation/screens/home/viewmodel/home_viewmodel.dart';
import 'package:shoof_tv/presentation/screens/home/widgets/custom_navigation_bar.dart';
import 'package:shoof_tv/presentation/screens/home/widgets/custom_navigation_rail.dart';
import 'package:shoof_tv/presentation/screens/home/widgets/subscription_alert.dart';
import 'package:shoof_tv/presentation/viewmodels/auth_provider.dart';

import '../live/live_screen.dart';
import '../vod/vod_screen.dart';
import '../series/series_screen.dart';
import '../settiings/settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final List<Widget> screens = const [
    LiveScreen(),
    VodScreen(),
    SeriesScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(_checkSubscriptionStatus);
  }

  Future<void> _checkSubscriptionStatus() async {
    final expiryDate = ref.read(subscriptionEndProvider);
    final username = ref.read(usernameProvider);
    final now = DateTime.now();

    if (now.isAfter(expiryDate)) {
      await ref.read(authProvider.notifier).logout();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
      return;
    }

    final difference = expiryDate.difference(now);
    if (difference.inDays > 3) return;

    final prefs = await SharedPreferences.getInstance();
    final lastShownKey = 'last_subscription_alert_$username';
    final lastShown = prefs.getInt(lastShownKey) ?? 0;
    final nowMillis = now.millisecondsSinceEpoch;

    if (nowMillis - lastShown < const Duration(hours: 24).inMilliseconds) {
      return;
    }

    final message = difference.inDays >= 1
        ? "باقي ${difference.inDays} يوم على انتهاء الاشتراك"
        : "باقي ${difference.inHours} ساعة على انتهاء الاشتراك";

    ref.read(timeLeftMessageProvider.notifier).state = message;
    ref.read(showSubscriptionAlertProvider.notifier).state = true;

    await prefs.setInt(lastShownKey, nowMillis);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 700;
    final index = ref.watch(homeIndexProvider);
    final showAlert = ref.watch(showSubscriptionAlertProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isWide) const CustomNavigationRail(),
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Colors.white12,
                ),
                Expanded(
                  child: SafeArea(
                    top: true,
                    bottom: false,
                    child: screens[index],
                  ),
                ),
              ],
            ),
            if (showAlert) const SubscriptionAlert(),
          ],
        ),
      ),
      bottomNavigationBar: isWide ? null : const CustomNavigationBar(),
    );
  }
}
