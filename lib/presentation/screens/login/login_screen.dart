import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:shoof_tv/presentation/screens/login/login_form.dart';
import 'package:shoof_tv/presentation/widgets/markdown_page.dart';

const kFacebookUrl = 'https://www.facebook.com/profile.php?id=61574300182496';
const kInstagramUrl =
    'https://www.instagram.com/shoof_tv?igsh=MWNlM3BzazE3Y3FsZA%3D%3D&utm_source=qr';
const kTelegramUrl = 'https://t.me/shoof_tv';
const kWhatsappUrl = 'https://wa.me/+9647718093023';
const kTiktok = 'https://www.tiktok.com/@shoof__tv?_t=ZS-8z1A5RKWz00&_r=1s';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final physics = isCupertino(context)
        ? const BouncingScrollPhysics()
        : const ClampingScrollPhysics();

    return PlatformScaffold(
      backgroundColor: Colors.black,
      material: (_, __) => MaterialScaffoldData(resizeToAvoidBottomInset: true),
      cupertino: (_, __) =>
          CupertinoPageScaffoldData(resizeToAvoidBottomInset: true),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: physics,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // (اختياري) لوغو أعلى الصفحة
              // Image.asset('assets/images/logo.png', height: 64),
              const SizedBox(height: 12),

              // نموذج تسجيل الدخول
              const LoginForm(),

              const SizedBox(height: 24),

              Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        _PolicyLink(
                          title: 'اتفاقية المستخدم',
                          asset: 'assets/policies/user_agreement.md',
                        ),
                        _PolicyDot(),
                        _PolicyLink(
                          title: 'شروط الاستخدام',
                          asset: 'assets/policies/terms.md',
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        _PolicyLink(
                          title: 'سياسة الخصوصية',
                          asset: 'assets/policies/privacy.md',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ===== صف أيقونات السوشيال (Font Awesome) =====
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SocialIcon(
                    icon: FontAwesomeIcons.facebookF,
                    onTap: () => _open(kFacebookUrl),
                    tooltip: 'Facebook',
                  ),
                  const SizedBox(width: 14),
                  _SocialIcon(
                    icon: FontAwesomeIcons.instagram,
                    onTap: () => _open(kInstagramUrl),
                    tooltip: 'Instagram',
                  ),
                  const SizedBox(width: 14),
                  _SocialIcon(
                    icon: FontAwesomeIcons.telegram,
                    onTap: () => _open(kTelegramUrl),
                    tooltip: 'Telegram',
                  ),
                  const SizedBox(width: 14),
                  _SocialIcon(
                    icon: FontAwesomeIcons.whatsapp,
                    onTap: () => _open(kWhatsappUrl),
                    tooltip: 'WhatsApp',
                  ),
                  const SizedBox(width: 14),
                  _SocialIcon(
                    icon: FontAwesomeIcons.tiktok,
                    onTap: () => _open(kTiktok),
                    tooltip: 'tiktok',
                  ),
                ],
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

// رابط سياسة واحد (يفتح MarkdownPage)
class _PolicyLink extends StatelessWidget {
  final String title;
  final String asset;
  const _PolicyLink({required this.title, required this.asset});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        Navigator.push(
          context,
          platformPageRoute(
            context: context,
            builder: (_) => MarkdownPage(title: title, assetPath: asset),
          ),
        );
      },
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _PolicyDot extends StatelessWidget {
  const _PolicyDot();
  @override
  Widget build(BuildContext context) =>
      const Text('•', style: TextStyle(color: Colors.white54, fontSize: 13));
}

class _SocialIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  const _SocialIcon({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: FaIcon(icon, color: Colors.white, size: 22),
      onPressed: onTap,
      tooltip: tooltip,
      splashRadius: 22,
    );
  }
}
