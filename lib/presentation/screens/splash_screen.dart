import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'home/home_screen.dart';
import 'login/login_screen.dart';

import 'package:shoof_tv/presentation/viewmodels/auth_provider.dart';
import 'package:shoof_tv/core/responsive.dart';

/// شاشة سبلـاش مع لاقط أخطاء + تايم آوت آمن.
/// لو authProvider بقي Loading لفترة طويلة، نرجع لصفحة تسجيل الدخول بدل شاشة سوداء.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  static const Duration _timeout = Duration(seconds: 8);

  Timer? _timer;
  bool _timedOut = false;

  @override
  void initState() {
    super.initState();
    // تايم آوت احترازي لمنع بقاء الشاشة سوداء إن حصل تعليق مبكر
    _timer = Timer(_timeout, () {
      if (mounted) {
        setState(() => _timedOut = true);
        debugPrint(
            '[SplashScreen] Timeout after ${_timeout.inSeconds}s → fallback to LoginScreen.');
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // لو انتهى التايم آوت وما وصلنا نتيجة من provider، نعرض تسجيل الدخول بفالـباك آمن.
    if (_timedOut) {
      return _ScaffoldContainer(
        child: const LoginScreen(),
        note: 'Initializing… (fallback)',
      );
    }

    // راقب حالة التوثيق
    final authState = ref.watch(authProvider);

    return authState.when(
      loading: () {
        debugPrint('[SplashScreen] authProvider: loading…');
        return PlatformScaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Padding(
              padding: context.pagePadding,
              child: CenteredMaxWidth(
                child: const Center(child: PlatformCircularProgressIndicator()),
              ),
            ),
          ),
        );
      },
      error: (err, stack) {
        // التقط وسجل أي خطأ من الـ provider بدل السقوط الصامت
        debugPrint('[SplashScreen] authProvider: ERROR → $err');
        debugPrint(stack.toString());
        // ارجع لتسجيل الدخول بدل شاشة سوداء
        return _ScaffoldContainer(
          note: 'Sign-in required',
          child: const LoginScreen(),
        );
      },
      data: (isLoggedIn) {
        debugPrint(
            '[SplashScreen] authProvider: data → isLoggedIn=$isLoggedIn');
        // ألغِ التايمر لأننا حصلنا على نتيجة
        _timer?.cancel();
        return isLoggedIn ? const HomeScreen() : const LoginScreen();
      },
    );
  }
}

/// حاوية بسيطة تضيف خلفية سوداء وهوامش موحّدة + ملاحظة صغيرة اختيارية
class _ScaffoldContainer extends StatelessWidget {
  final Widget child;
  final String? note;

  const _ScaffoldContainer({required this.child, this.note});

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: context.pagePadding,
          child: Stack(
            children: [
              // المحتوى الرئيسي
              Positioned.fill(
                child: CenteredMaxWidth(child: child),
              ),
              // ملاحظة صغيرة بأسفل الشاشة (اختياري)
              if (note != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 12,
                  child: Center(
                    child: Text(
                      note!,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
