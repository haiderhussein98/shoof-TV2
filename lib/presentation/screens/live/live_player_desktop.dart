import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:media_kit/media_kit.dart';
import 'package:dart_ping/dart_ping.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:media_kit_video/media_kit_video.dart';

class LivePlayerDesktop extends StatefulWidget {
  final String serverUrl;
  final String username;
  final String password;
  final int streamId;
  final String title;

  const LivePlayerDesktop({
    super.key,
    required this.serverUrl,
    required this.username,
    required this.password,
    required this.streamId,
    required this.title,
  });

  @override
  State<LivePlayerDesktop> createState() => _LivePlayerDesktopState();
}

class _LivePlayerDesktopState extends State<LivePlayerDesktop> {
  late final Player _player;
  late final VideoController _videoController;
  bool _isPlaying = true;
  bool _showControls = true;
  bool _hasError = false;
  bool _isDisposed = false;
  bool _isReopening = false;

  bool _hasStarted = false;
  bool _sawFirstConnEvent = false;

  final ValueNotifier<int> _latencyNotifier = ValueNotifier(0);
  Timer? _connectionCheckTimer;
  Timer? _hideControlsTimer;
  Timer? _recoveryTimer;
  StreamSubscription<InternetStatus>? _connSub;

  String get streamUrl {
    final encodedUser = Uri.encodeComponent(widget.username);
    final encodedPass = Uri.encodeComponent(widget.password);
    final encodedServer = widget.serverUrl
        .replaceAll('https://', '')
        .replaceAll('http://', '');
    return 'http://$encodedServer/live/$encodedUser/$encodedPass/${widget.streamId}.m3u8';
  }

  @override
  void initState() {
    super.initState();
    _player = Player();
    _videoController = VideoController(_player);

    _startStream();
    _startConnectionTracking();
    _monitorInternet();
    _toggleControls();
  }

  Future<void> _startStream() async {
    try {
      if (_hasStarted && _player.state.playing) return;

      await _player.open(Media(streamUrl), play: true);
      _isPlaying = true;
      _hasError = false;
      _hasStarted = true;
      if (mounted) setState(() {});
    } catch (_) {
      _hasError = true;
      if (mounted) setState(() {});
      _ensureRecovery();
    }
  }

  void _monitorInternet() {
    _connSub = InternetConnection().onStatusChange.listen((status) async {
      if (_isDisposed) return;

      if (!_sawFirstConnEvent) {
        _sawFirstConnEvent = true;
        return;
      }

      if (status == InternetStatus.connected) {
        if (_hasStarted && !_hasError && _player.state.playing) return;
        _ensureRecovery();
      }
    });
  }

  void _ensureRecovery() {
    if (_isReopening || _isDisposed) return;

    if (!_hasError && _player.state.playing) return;

    _recoveryTimer ??= Timer.periodic(const Duration(seconds: 3), (t) async {
      if (_isDisposed) {
        t.cancel();
        _recoveryTimer = null;
        return;
      }
      final online = await InternetConnection().hasInternetAccess;
      if (!online) return;

      await _reopenStream();
      t.cancel();
      _recoveryTimer = null;
    });
  }

  Future<void> _reopenStream() async {
    if (_isReopening || _isDisposed) return;

    if (_hasStarted && _player.state.playing && !_hasError) return;

    _isReopening = true;
    try {
      await _player.stop();
      await _player.open(Media(streamUrl), play: true);
      _hasError = false;
      _isPlaying = true;
      _hasStarted = true;
    } catch (_) {
    } finally {
      _isReopening = false;
      if (mounted) setState(() {});
    }
  }

  void _startConnectionTracking() {
    _connectionCheckTimer?.cancel();
    _connectionCheckTimer = Timer.periodic(const Duration(seconds: 3), (
      _,
    ) async {
      try {
        final ping = Ping('8.8.8.8', count: 1);
        final result = await ping.stream.first;
        if (!mounted || _isDisposed) return;
        _latencyNotifier.value = result.response?.time?.inMilliseconds ?? -1;
      } catch (_) {
        if (!mounted || _isDisposed) return;
        _latencyNotifier.value = -1;
      }
    });
  }

  void _toggleControls() {
    if (!mounted || _isDisposed) return;
    setState(() => _showControls = !_showControls);
    _hideControlsTimer?.cancel();

    if (_showControls) {
      _hideControlsTimer = Timer(const Duration(seconds: 4), () {
        if (!mounted || _isDisposed) return;
        setState(() => _showControls = false);
      });
    }
  }

  Widget _signalIndicator() {
    return ValueListenableBuilder<int>(
      valueListenable: _latencyNotifier,
      builder: (context, latency, _) {
        IconData icon = FontAwesomeIcons.wifi;
        Color color = Colors.red;

        if (latency == -1) {
          color = Colors.red;
        } else if (latency < 70) {
          color = Colors.green;
        } else if (latency < 200) {
          color = Colors.orange;
        }

        return Tooltip(
          message: latency == -1 ? 'غير متصل' : 'Ping: ${latency}ms',
          child: FaIcon(icon, color: color, size: 26),
        );
      },
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _player.dispose();
    _latencyNotifier.dispose();
    _connectionCheckTimer?.cancel();
    _connSub?.cancel();
    _hideControlsTimer?.cancel();
    _recoveryTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Video(controller: _videoController, fit: BoxFit.contain),

          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) => _toggleControls(),
              child: const SizedBox.expand(),
            ),
          ),

          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        Navigator.of(context).maybePop();
                      }
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 40),
                    child: _signalIndicator(),
                  ),
                ],
              ),
            ),
          ),

          if (_showControls)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: screenSize.width > 700 ? 40 : 30,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPlaying = !_isPlaying;
                            _isPlaying ? _player.play() : _player.pause();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

          Positioned(
            bottom: 30,
            right: 60,
            child: Opacity(
              opacity: 0.4,
              child: Image.asset('assets/images/logo.png', width: 40),
            ),
          ),

          if (_hasError)
            const Center(
              child: Text(
                "انقطع الاتصال بالبث... تتم إعادة المحاولة",
                style: TextStyle(color: Colors.redAccent, fontSize: 16),
              ),
            ),
        ],
      ),
    );
  }
}
