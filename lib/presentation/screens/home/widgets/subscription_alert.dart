import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:shoof_tv/core/constants/colors.dart';
import 'package:shoof_tv/presentation/screens/home/viewmodel/home_viewmodel.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionAlert extends ConsumerWidget {
  const SubscriptionAlert({super.key});

  bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.watch(timeLeftMessageProvider);
    final isAndroid = _isAndroid;

    return Center(
      child: Material(
        color: Colors.black,
        elevation: 10,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 350),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _FocusElevatedButton(
                      isAndroid: isAndroid,
                      onPressed: () {
                        ref.read(showSubscriptionAlertProvider.notifier).state =
                            false;
                      },
                      color: Colors.red,
                      label: 'OK',
                    ),
                    const SizedBox(width: 16),
                    _FocusElevatedButton(
                      isAndroid: isAndroid,
                      onPressed: _launchWhatsApp,
                      color: Colors.green,
                      label: 'تجديد الاشتراك',
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _FocusableIconButton(
                      isAndroid: isAndroid,
                      icon: FontAwesomeIcons.telegram,
                      color: AppColors.primaryBlue,
                      url: 'https://t.me/shoof_tv',
                    ),
                    _FocusableIconButton(
                      isAndroid: isAndroid,
                      icon: FontAwesomeIcons.instagram,
                      color: AppColors.primaryBlue,
                      url: 'https://www.instagram.com/shoof_tv',
                    ),
                    _FocusableIconButton(
                      isAndroid: isAndroid,
                      icon: FontAwesomeIcons.facebookF,
                      color: AppColors.primaryBlue,
                      url:
                          'https://www.facebook.com/share/16m1ReXZKH/?mibextid=wwXIfr',
                    ),
                    _FocusableIconButton(
                      isAndroid: isAndroid,
                      icon: FontAwesomeIcons.tiktok,
                      color: AppColors.primaryBlue,
                      url:
                          'https://www.tiktok.com/@shoof__tv?_t=ZS-8yWmutNILBA&_r=1',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _launchWhatsApp() async {
    const phone = '+9647718093023';
    const message = 'أريد تجديد الاشتراك';
    final url = 'https://wa.me/$phone?text=${Uri.encodeComponent(message)}';
    await _openUrl(url);
  }
}

class _FocusElevatedButton extends StatelessWidget {
  final bool isAndroid;
  final VoidCallback onPressed;
  final Color color;
  final String label;

  const _FocusElevatedButton({
    required this.isAndroid,
    required this.onPressed,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style:
          ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ).copyWith(
            side: WidgetStateProperty.resolveWith<BorderSide?>((states) {
              if (isAndroid && states.contains(WidgetState.focused)) {
                return const BorderSide(color: Colors.redAccent, width: 2);
              }
              return null;
            }),
            elevation: WidgetStateProperty.resolveWith<double?>((states) {
              if (isAndroid && states.contains(WidgetState.focused)) return 6;
              return null;
            }),
          ),
      child: Text(label),
    );
  }
}

/// IconButton قابل للتركيز مع تمييز بصري على Android/TV فقط
class _FocusableIconButton extends StatefulWidget {
  final bool isAndroid;
  final IconData icon;
  final Color color;
  final String url;

  const _FocusableIconButton({
    required this.isAndroid,
    required this.icon,
    required this.color,
    required this.url,
  });

  @override
  State<_FocusableIconButton> createState() => _FocusableIconButtonState();
}

class _FocusableIconButtonState extends State<_FocusableIconButton> {
  bool _hasFocus = false;

  @override
  Widget build(BuildContext context) {
    final highlight = widget.isAndroid && _hasFocus;

    return Focus(
      onFocusChange: (f) => setState(() => _hasFocus = f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: highlight
              ? Border.all(color: Colors.redAccent, width: 2)
              : null,
        ),
        child: IconButton(
          icon: Icon(widget.icon, color: widget.color, size: 20),
          onPressed: () async {
            final uri = Uri.parse(widget.url);
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          },
        ),
      ),
    );
  }
}
