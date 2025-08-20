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
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _AnimatedGradientBackground(),
          SafeArea(
            child: SingleChildScrollView(
              physics: physics,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // بطاقة معلومات المستخدم (كما هي)
                  _FrostedCard(
                    // ← الاسم نفسه لكن تصميم صلب
                    child: UserInfoCard(
                      username: username,
                      isActive: isActive,
                      isTablet: isTablet,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // بطاقة الاشتراك (كما هي)
                  _SectionHeader(title: 'Subscription'),
                  const SizedBox(height: 8),
                  _FrostedCard(
                    child: SubscriptionInfoCard(
                      startDate: formattedStart,
                      endDate: formattedEnd,
                      isTablet: isTablet,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // اختبار السرعة (كما هو)
                  _SectionHeader(title: 'Speed Test'),
                  const SizedBox(height: 8),
                  const _FrostedCard(
                    child: SpeedTestCard(),
                  ),
                  const SizedBox(height: 16),

                  // الوضع الداكن
                  _SectionHeader(title: 'Appearance'),
                  const SizedBox(height: 8),
                  _FrostedCard(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: PlatformWidget(
                      material: (_, __) => Column(
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.color_lens,
                                color: Colors.white),
                            title: const Text(
                              "الوضع الداكن",
                              style: TextStyle(color: Colors.white),
                            ),
                            trailing: PlatformSwitch(
                              value: true,
                              onChanged: (_) {},
                              material: (_, __) =>
                                  MaterialSwitchData(activeColor: Colors.green),
                            ),
                          ),
                          const Divider(color: Colors.white24, height: 1),
                        ],
                      ),
                      cupertino: (_, __) => Column(
                        children: [
                          CupertinoListTile(
                            padding: EdgeInsets.zero,
                            backgroundColor: Colors.transparent,
                            leading: const Icon(CupertinoIcons.paintbrush,
                                color: Colors.white),
                            title: const Text("الوضع الداكن",
                                style: TextStyle(color: Colors.white)),
                            trailing:
                                PlatformSwitch(value: true, onChanged: (_) {}),
                          ),
                          const Divider(color: Colors.white24, height: 1),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // تسجيل الخروج
                  _SectionHeader(title: 'Account'),
                  const SizedBox(height: 8),
                  _FrostedCard(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: PlatformWidget(
                      material: (_, __) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.logout, color: Colors.white),
                        title: const Text("Logout",
                            style: TextStyle(color: Colors.white)),
                        trailing: const Icon(Icons.chevron_right,
                            color: Colors.white54),
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
                        leading: const Icon(CupertinoIcons.square_arrow_right,
                            color: Colors.white),
                        title: const Text("Logout",
                            style: TextStyle(color: Colors.white)),
                        trailing: const Icon(CupertinoIcons.chevron_forward,
                            color: Colors.white54),
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
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// خلفية متدرجة ناعمة
class _AnimatedGradientBackground extends StatefulWidget {
  const _AnimatedGradientBackground();

  @override
  State<_AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState
    extends State<_AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 12))
        ..repeat(reverse: true);
  late final Animation<double> _t =
      CurvedAnimation(parent: _c, curve: Curves.easeInOut);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (_, __) {
        final stops = [0.0, 0.55 + 0.2 * _t.value, 1.0];
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: stops,
              colors: const [
                Color(0xFF0D0D0F),
                Color(0xFF16161A),
                Color(0xFF1F1B24),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// عنوان قسم صغير أبيض
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: TextAlign.start,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Colors.white70,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
    );
  }
}

/// بطاقة “صلبة” داكنة (اسمها بقي _FrostedCard لكن بلا أي زجاج)
class _FrostedCard extends StatelessWidget {
  const _FrostedCard({
    required this.child,
    this.padding = const EdgeInsets.all(12),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFF121212), // داكن صلب
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: Colors.white.withValues(alpha: .08), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 14,
            spreadRadius: -4,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
