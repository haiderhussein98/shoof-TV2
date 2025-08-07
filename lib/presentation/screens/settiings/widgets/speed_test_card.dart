import 'dart:io';
import 'package:flutter/material.dart';

class SpeedTestCard extends StatefulWidget {
  const SpeedTestCard({super.key});

  @override
  State<SpeedTestCard> createState() => _SpeedTestCardState();
}

class _SpeedTestCardState extends State<SpeedTestCard> {
  bool _testing = false;
  double _bps = 0;
  String _error = '';

  final List<Uri> _testUrls = [
    Uri.parse('http://ipv4.download.thinkbroadband.com/10MB.zip'),
    Uri.parse(
      'https://download.microsoft.com/download/3/5/1/3516D3EC-93A2-4D4B-B30F-EB247D94EA17/10MB.zip',
    ),
  ];

  static const Duration _testDuration = Duration(seconds: 8);
  static const Duration _timeout = Duration(seconds: 10);

  @override
  void initState() {
    super.initState();
    Future.microtask(_runTest);
  }

  Future<void> _runTest() async {
    if (_testing) return;
    setState(() {
      _testing = true;
      _error = '';
      _bps = 0;
    });

    double bestBps = 0;
    final client = HttpClient()..connectionTimeout = _timeout;

    try {
      for (final url in _testUrls) {
        final sw = Stopwatch()..start();
        int bytes = 0;
        try {
          final req = await client.getUrl(url);
          req.followRedirects = true;
          final res = await req.close();
          if (res.statusCode >= 400) continue;

          await for (final chunk in res.timeout(_timeout)) {
            bytes += chunk.length;
            if (sw.elapsed >= _testDuration) break;
          }

          final seconds = sw.elapsedMilliseconds / 1000.0;
          if (seconds > 0) {
            final bps = bytes * 8 / seconds;
            if (bps > bestBps) bestBps = bps;
          }
        } catch (_) {}
        if (bestBps > 0) break;
      }
    } catch (_) {
      _error = 'تعذّر الاختبار';
    } finally {
      client.close(force: true);
    }

    if (!mounted) return;
    setState(() {
      _testing = false;
      if (bestBps > 0) {
        _bps = bestBps;
      } else if (_error.isEmpty) {
        _error = 'تعذّر القياس. تحقق من الشبكة.';
      }
    });
  }

  String _formatBps(double bps) {
    if (bps <= 0) return '--';
    const kb = 1000.0;
    const mb = 1000.0 * 1000.0;
    const gb = 1000.0 * 1000.0 * 1000.0;
    if (bps >= gb) return '${(bps / gb).toStringAsFixed(2)} Gb/s';
    if (bps >= mb) return '${(bps / mb).toStringAsFixed(2)} Mb/s';
    if (bps >= kb) return '${(bps / kb).toStringAsFixed(2)} Kb/s';
    return '${bps.toStringAsFixed(0)} b/s';
  }

  Color _speedColor(double bps) {
    final mbps = bps / 1e6;
    if (_testing) return Colors.blue;
    if (mbps >= 10) return Colors.green;
    if (mbps >= 3) return Colors.orange;
    return Colors.red;
  }

  ({double icon, double label, double value}) _sizes(BoxConstraints c) {
    final w = c.maxWidth;
    if (w >= 700) {
      return (icon: 34, label: 15, value: 26);
    } else if (w >= 450) {
      return (icon: 30, label: 14, value: 22);
    } else {
      return (icon: 26, label: 13, value: 20);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, cons) {
        final sizes = _sizes(cons);
        final color = _error.isNotEmpty ? Colors.redAccent : _speedColor(_bps);
        final compact = cons.maxWidth < 340;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF141414), Color(0xFF0F0F0F)],
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.speed, color: Colors.white, size: sizes.icon),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'اختبار سرعة الإنترنت',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: sizes.label + 2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  compact
                      ? IconButton(
                          tooltip: 'إعادة الاختبار',
                          onPressed: _testing ? null : _runTest,
                          icon: const Icon(Icons.refresh),
                          color: Colors.white,
                        )
                      : TextButton.icon(
                          onPressed: _testing ? null : _runTest,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('إعادة الاختبار'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            backgroundColor: Colors.white10,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.network_check_rounded,
                    color: color,
                    size: sizes.icon + 6,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _testing
                          ? Row(
                              key: const ValueKey('loading'),
                              children: [
                                SizedBox(
                                  width: sizes.label + 5,
                                  height: sizes.label + 5,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'جارِ الاختبار...',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: sizes.label,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              _error.isNotEmpty ? _error : _formatBps(_bps),
                              key: const ValueKey('value'),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _error.isNotEmpty
                                    ? Colors.redAccent
                                    : Colors.white,
                                fontSize: sizes.value,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              Text(
                'القيمة تُمثل سرعة التنزيل التقريبية (قد تختلف حسب الخادم/الشبكة).',
                style: TextStyle(color: Colors.white38, fontSize: sizes.label),
              ),
            ],
          ),
        );
      },
    );
  }
}
