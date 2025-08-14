import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class SpeedTestCard extends StatefulWidget {
  const SpeedTestCard({super.key});

  @override
  State<SpeedTestCard> createState() => _SpeedTestCardState();
}

class _SpeedTestCardState extends State<SpeedTestCard> {
  bool _testing = false;

  double _bps = 0;
  String _error = '';

  double _pingMs = 0.0;
  double _jitterMs = 0.0;

  final List<Uri> _testUrls = [
    Uri.parse('https://ipv4.download.thinkbroadband.com/20MB.zip'),
    Uri.parse('https://speed.cloudflare.com/__down?bytes=20000000'),
    Uri.parse('https://speed.hetzner.de/20MB.bin'),
    Uri.parse(
      'https://objectstorage.eu-frankfurt-1.oraclecloud.com/p/speedtest/example.bin?size=20000000',
    ),
    Uri.parse(
      'https://download.microsoft.com/download/3/5/1/3516D3EC-93A2-4D4B-B30F-EB247D94EA17/10MB.zip',
    ),
  ];

  static const Duration _testDuration = Duration(seconds: 10);
  static const Duration _timeout = Duration(seconds: 20);

  static const int _pingCount = 6;
  static const Duration _pingTimeout = Duration(seconds: 2);
  static const Duration _pingGap = Duration(milliseconds: 200);
  final List<(String host, int port)> _pingTargets = const [
    ('1.1.1.1', 443),
    ('8.8.8.8', 443),
    ('www.microsoft.com', 443),
    ('www.google.com', 443),
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(_runTest);
  }

  HttpClient _makeClient() {
    final c = HttpClient()
      ..connectionTimeout = _timeout
      ..idleTimeout = const Duration(seconds: 5)
      ..maxConnectionsPerHost = 2;
    return c;
  }

  Future<double> _measureUrl(Uri baseUrl) async {
    final cacheBuster =
        '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(1 << 32)}';
    final url = baseUrl.replace(
      queryParameters: {...baseUrl.queryParameters, 't': cacheBuster},
    );
    final client = _makeClient();
    final sw = Stopwatch()..start();
    int bytes = 0;
    try {
      final req = await client.getUrl(url).timeout(_timeout);
      req.followRedirects = true;
      req.headers.set(HttpHeaders.userAgentHeader, 'ShoofTV-SpeedTest/1.0');
      req.headers.set(HttpHeaders.rangeHeader, 'bytes=0-');
      final res = await req.close().timeout(_timeout);
      if (res.statusCode >= 400) {
        if (kDebugMode) debugPrint('SpeedTest: $url status ${res.statusCode}');
        return 0;
      }
      await for (final chunk in res.timeout(_timeout)) {
        bytes += chunk.length;
        if (sw.elapsed >= _testDuration) break;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('SpeedTest error for $url: $e');
      return 0;
    } finally {
      sw.stop();
      client.close(force: true);
    }
    final seconds = max(sw.elapsedMilliseconds / 1000.0, 0.001);
    return (bytes * 8) / seconds;
  }

  Future<double> _runDownloadTest() async {
    double best = 0;
    for (final u in _testUrls) {
      final v = await _measureUrl(u);
      best = max(best, v);
      if (best > 0) break;
    }
    if (best == 0) {
      final results = await Future.wait(_testUrls.map(_measureUrl));
      for (final v in results) {
        best = max(best, v);
      }
    }
    return best;
  }

  Future<void> _runPing() async {
    (String host, int port)? target;
    for (final t in _pingTargets) {
      try {
        final s = Stopwatch()..start();
        final socket = await Socket.connect(t.$1, t.$2, timeout: _pingTimeout);
        s.stop();
        await socket.close();
        target = t;
        break;
      } catch (_) {}
    }
    if (target == null) {
      if (!mounted) return;
      setState(() {
        _pingMs = 0;
        _jitterMs = 0;
      });
      return;
    }
    final samples = <double>[];
    for (var i = 0; i < _pingCount; i++) {
      try {
        final sw = Stopwatch()..start();
        final socket = await Socket.connect(
          target.$1,
          target.$2,
          timeout: _pingTimeout,
        );
        sw.stop();
        await socket.close();
        samples.add(sw.elapsedMicroseconds / 1000.0);
      } catch (_) {
        samples.add(_pingTimeout.inMilliseconds.toDouble());
      }
      await Future.delayed(_pingGap);
    }
    final avg = samples.isEmpty
        ? 0.0
        : samples.reduce((a, b) => a + b) / samples.length;
    final mean = avg;
    final variance = samples.isEmpty
        ? 0.0
        : samples.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
              samples.length;
    final stddev = sqrt(variance);
    if (!mounted) return;
    setState(() {
      _pingMs = double.parse(mean.toStringAsFixed(1));
      _jitterMs = double.parse(stddev.toStringAsFixed(1));
    });
  }

  Future<void> _runTest() async {
    if (_testing) return;
    setState(() {
      _testing = true;
      _error = '';
      _bps = 0;
    });
    try {
      final results = await Future.wait([_runDownloadTest(), _runPing()]);
      final best = (results.first as double);
      if (!mounted) return;
      setState(() {
        _bps = best;
        if (best == 0) _error = 'تعذّر القياس. تحقق من الشبكة.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذّر الاختبار';
      });
    } finally {
      if (mounted) {
        setState(() => _testing = false);
      }
    }
  }

  String _formatBps(double bps) {
    if (bps <= 0) return '--';
    const kb = 1e3, mb = 1e6, gb = 1e9;
    if (bps >= gb) return '${(bps / gb).toStringAsFixed(2)} Gb/s';
    if (bps >= mb) return '${(bps / mb).toStringAsFixed(2)} Mb/s';
    if (bps >= kb) return '${(bps / kb).toStringAsFixed(2)} Kb/s';
    return '${bps.toStringAsFixed(0)} b/s';
  }

  Color _speedColor(double bps) {
    final mbps = bps / 1e6;
    if (_testing) return Colors.blue;
    if (mbps >= 50) return Colors.green;
    if (mbps >= 10) return Colors.orange;
    return Colors.red;
  }

  Color _latencyColor(double ms) {
    if (_testing) return Colors.blue;
    if (ms <= 30) return Colors.green;
    if (ms <= 80) return Colors.orange;
    return Colors.red;
  }

  ({double icon, double label, double value}) _sizes(BoxConstraints c) {
    final w = c.maxWidth;
    if (w >= 1000) return (icon: 38, label: 16, value: 28);
    if (w >= 700) return (icon: 34, label: 15, value: 26);
    if (w >= 450) return (icon: 30, label: 14, value: 22);
    if (w >= 320) return (icon: 26, label: 13, value: 20);
    return (icon: 24, label: 12, value: 18);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, cons) {
        final sizes = _sizes(cons);
        final color = _error.isNotEmpty ? Colors.redAccent : _speedColor(_bps);
        final narrow = cons.maxWidth < 420;

        return ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 220),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(narrow ? 12 : 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(narrow ? 12 : 16),
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
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Icon(Icons.speed, color: Colors.white, size: sizes.icon),
                    SizedBox(
                      width: narrow ? double.infinity : null,
                      child: Text(
                        'اختبار سرعة الإنترنت (تنزيل)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: narrow ? TextAlign.start : TextAlign.left,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: sizes.label + 2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      height: 36,
                      child: PlatformElevatedButton(
                        onPressed: _testing ? null : _runTest,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.refresh, size: 18),
                            SizedBox(width: 6),
                            Text('إعادة الاختبار'),
                          ],
                        ),
                        material: (_, __) => MaterialElevatedButtonData(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.white10,
                            padding: EdgeInsets.symmetric(
                              horizontal: narrow ? 10 : 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                        ),
                        cupertino: (_, __) => CupertinoElevatedButtonData(
                          padding: EdgeInsets.symmetric(
                            horizontal: narrow ? 10 : 12,
                            vertical: 8,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          minimumSize: const Size(0, 36),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: narrow ? 10 : 12),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.download_rounded,
                      color: color,
                      size: sizes.icon + 6,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: _testing
                            ? Row(
                                key: const ValueKey('loading'),
                                children: [
                                  SizedBox(
                                    width: sizes.label + 6,
                                    height: sizes.label + 6,
                                    child: PlatformCircularProgressIndicator(
                                      material: (_, __) =>
                                          MaterialProgressIndicatorData(
                                            strokeWidth: 2,
                                          ),
                                      cupertino: (_, __) =>
                                          CupertinoProgressIndicatorData(
                                            radius: 10,
                                          ),
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

                SizedBox(height: narrow ? 6 : 8),

                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.network_ping_rounded,
                          color: _latencyColor(_pingMs),
                          size: sizes.icon - 2,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _pingMs > 0
                              ? 'Ping: ${_pingMs.toStringAsFixed(1)} ms'
                              : 'Ping: --',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: sizes.label,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.show_chart_rounded,
                          color: _latencyColor(_jitterMs),
                          size: sizes.icon - 4,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _jitterMs > 0
                              ? 'Jitter: ${_jitterMs.toStringAsFixed(1)} ms'
                              : 'Jitter: --',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: sizes.label,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: narrow ? 8 : 10),

                Text(
                  'القيمة تقديرية لأقصى سرعة تنزيل خلال ${_testDuration.inSeconds} ثوانٍ. Ping = زمن الاستجابة، Jitter = تذبذب التأخير.',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: sizes.label,
                  ),
                  textAlign: TextAlign.start,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
