import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoof_iptv/core/theme/app_theme.dart';
import 'package:shoof_iptv/data/services/cleanup_service.dart';
import 'package:shoof_iptv/presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ProviderScope(child: ShoofIPTVApp()));
}

class ShoofIPTVApp extends StatefulWidget {
  const ShoofIPTVApp({super.key});

  @override
  State<ShoofIPTVApp> createState() => _ShoofIPTVAppState();
}

class _ShoofIPTVAppState extends State<ShoofIPTVApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      CleanupService.performCleanup();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      showPerformanceOverlay: false,
      debugShowCheckedModeBanner: false,
      title: 'Shoof TV',
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
