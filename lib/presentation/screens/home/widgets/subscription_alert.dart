import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shoof_tv/core/constants/colors.dart';
import 'package:shoof_tv/presentation/screens/home/viewmodel/home_viewmodel.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionAlert extends ConsumerWidget {
  const SubscriptionAlert({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.watch(timeLeftMessageProvider);

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
                    ElevatedButton(
                      onPressed: () =>
                          ref
                                  .read(showSubscriptionAlertProvider.notifier)
                                  .state =
                              false,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text("OK"),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _launchWhatsApp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text("تجديد الاشتراك"),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _iconButton(
                      FontAwesomeIcons.telegram,
                      'https://t.me/shoof_tv',
                    ),
                    _iconButton(
                      FontAwesomeIcons.instagram,
                      'https://www.instagram.com/shoof_tv',
                    ),
                    _iconButton(
                      FontAwesomeIcons.facebookF,
                      'https://www.facebook.com/share/16m1ReXZKH/?mibextid=wwXIfr',
                    ),
                    _iconButton(
                      FontAwesomeIcons.tiktok,
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

  Widget _iconButton(IconData icon, String url) {
    return IconButton(
      icon: Icon(icon, color: AppColors.primaryBlue, size: 20),
      onPressed: () async {
        final uri = Uri.parse(url);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      },
    );
  }

  void _launchWhatsApp() async {
    const phone = '+9647718093023';
    const message = 'أريد تجديد الاشتراك';
    final url = 'https://wa.me/$phone?text=${Uri.encodeComponent(message)}';
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
