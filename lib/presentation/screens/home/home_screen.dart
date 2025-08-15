import 'package:flutter/foundation.dart';
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
  late final PageController _pageController;

  final List<Widget> _screens = const [
    LiveScreen(),
    VodScreen(),
    SeriesScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: ref.read(homeIndexProvider));
    Future.microtask(_checkSubscriptionStatus);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
        ? "Ø¨Ø§Ù‚ÙŠ ${difference.inDays} ÙŠÙˆÙ… Ø¹Ù„Ù‰ Ø§Ù†ØªÙ‡Ø§Ø¡ Ø§Ù„Ø§Ø´ØªØ±Ø§Ùƒ"
        : "Ø¨Ø§Ù‚ÙŠ ${difference.inHours} Ø³Ø§Ø¹Ø© Ø¹Ù„Ù‰ Ø§Ù†ØªÙ‡Ø§Ø¡ Ø§Ù„Ø§Ø´ØªØ±Ø§Ùƒ";

    ref.read(timeLeftMessageProvider.notifier).state = message;
    ref.read(showSubscriptionAlertProvider.notifier).state = true;

    await prefs.setInt(lastShownKey, nowMillis);
  }

  bool _useRail(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final h = size.height;
    final ar = h > 0 ? w / h : 0;
    final isDesktop =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.linux);
    if (isDesktop) return true;
    final looksPhone = size.shortestSide < 600 && ar < 1.2;
    if (looksPhone) return false;
    if (w >= 720) return true;
    if (ar >= 1.3) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(homeIndexProvider);
    final showAlert = ref.watch(showSubscriptionAlertProvider);
    final useRail = _useRail(context);

    ref.listen<int>(homeIndexProvider, (prev, next) {
      if (!mounted) return;
      if (!_pageController.hasClients) return;
      final current = _pageController.page?.round();
      if (current == next) return;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (useRail) const CustomNavigationRail(),
                if (useRail)
                  const VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: Colors.white12,
                  ),
                Expanded(
                  child: SafeArea(
                    top: true,
                    bottom: false,
                    child: PageView(
                      controller: _pageController,
                      physics: useRail
                          ? const NeverScrollableScrollPhysics()
                          : const PageScrollPhysics(),
                      onPageChanged: (i) {
                        if (i != index) {
                          ref.read(homeIndexProvider.notifier).state = i;
                        }
                      },
                      children: _screens,
                    ),
                  ),
                ),
              ],
            ),
            if (showAlert) const SubscriptionAlert(),
          ],
        ),
      ),
      bottomNavigationBar: useRail ? null : const CustomNavigationBar(),
    );
  }
}

