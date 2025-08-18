import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:shoof_tv/presentation/screens/login/login_form.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  // روابط صفحاتك
  static final Uri _facebook = Uri.parse(
    'https://www.facebook.com/share/16m1ReXZKH/?mibextid=wwXIfr',
  );
  static final Uri _instagram = Uri.parse(
    'https://www.instagram.com/shoof_tv?igsh=MWNlM3BzazE3Y3FsZA%3D%3D&utm_source=qr',
  );
  static final Uri _telegram = Uri.parse('https://t.me/shoof_tv');
  static final Uri _tiktok =
      Uri.parse('https://www.tiktok.com/@shoof__tv?_t=ZS-8yWmutNILBA&_r=1');

  // واتساب برسالة جاهزة
  static final Uri _whatsapp = Uri.parse(
    'https://wa.me/9647718093023?text=${Uri.encodeComponent("أريد تجديد الاشتراك")}',
  );

  Future<void> _open(Uri url) async {
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // في حال فشل الفتح (اختياري: اعرض SnackBar)
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final physics = isCupertino(context)
        ? const BouncingScrollPhysics()
        : const ClampingScrollPhysics();

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return PlatformScaffold(
      backgroundColor: Colors.black,
      material: (_, __) => MaterialScaffoldData(resizeToAvoidBottomInset: true),
      cupertino: (_, __) =>
          CupertinoPageScaffoldData(resizeToAvoidBottomInset: true),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return AnimatedPadding(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: bottomInset),
              child: SingleChildScrollView(
                physics: physics,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: (constraints.maxHeight - bottomInset)
                        .clamp(0, constraints.maxHeight),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const LoginForm(),
                        const SizedBox(height: 24),

                        // فاصل بسيط
                        Opacity(
                          opacity: 0.2,
                          child: Divider(height: 1, color: Colors.white),
                        ),
                        const SizedBox(height: 16),

                        // صف الأيقونات
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 16,
                          runSpacing: 12,
                          children: [
                            _SocialIcon(
                              icon: FontAwesomeIcons.facebook,
                              label: 'Facebook',
                              onTap: () => _open(_facebook),
                            ),
                            _SocialIcon(
                              icon: FontAwesomeIcons.instagram,
                              label: 'Instagram',
                              onTap: () => _open(_instagram),
                            ),
                            _SocialIcon(
                              icon: FontAwesomeIcons.telegram,
                              label: 'Telegram',
                              onTap: () => _open(_telegram),
                            ),
                            _SocialIcon(
                              icon: FontAwesomeIcons.tiktok,
                              label: 'TikTok',
                              onTap: () => _open(_tiktok),
                            ),
                            _SocialIcon(
                              icon: FontAwesomeIcons.whatsapp,
                              label: 'WhatsApp',
                              onTap: () => _open(_whatsapp),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// زر أيقونة اجتماعية موحّد مع تأثير ضغط بسيط
class _SocialIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SocialIcon({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkResponse(
          onTap: onTap,
          highlightShape: BoxShape.circle,
          radius: 28,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: FaIcon(
              icon,
              size: 26,
              color: Colors.white.withValues(alpha: 0.95),
            ),
          ),
        ),
      ),
    );
  }
}
