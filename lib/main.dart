import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shoof_tv/core/theme/app_theme.dart';
import 'package:shoof_tv/data/services/cleanup_service.dart';
import 'package:shoof_tv/presentation/screens/splash_screen.dart';
import 'package:media_kit/media_kit.dart' as mk;
import 'package:window_manager/window_manager.dart';

Future<bool> _isAndroidTV() async {
  if (kIsWeb) return false;
  if (defaultTargetPlatform != TargetPlatform.android) return false;
  final info = await DeviceInfoPlugin().androidInfo;
  final features = info.systemFeatures;
  final model = (info.model).toLowerCase();
  final brand = (info.brand).toLowerCase();
  if (features.contains('android.software.leanback')) return true;
  if (features.contains('android.software.television')) return true;
  if (model.contains('tv') || brand.contains('tv')) return true;
  return false;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  PaintingBinding.instance.imageCache.maximumSize = 100; // Ø¹Ø¯Ø¯ Ø§Ù„ØµÙˆØ±
  PaintingBinding.instance.imageCache.maximumSizeBytes = 60 << 20; // ~60MB

  final bool isDesktop =
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS);

  if (isDesktop) {
    mk.MediaKit.ensureInitialized();
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      minimumSize: Size(1100, 700),
      center: true,
      titleBarStyle: TitleBarStyle.normal,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  } else {
    final tv = await _isAndroidTV();
    if (!tv) {
      await SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } else {
      await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    }
  }

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

