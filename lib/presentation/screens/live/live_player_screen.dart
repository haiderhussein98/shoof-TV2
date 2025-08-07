import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:dart_ping/dart_ping.dart';

class LivePlayerScreen extends StatefulWidget {
  final String serverUrl;
  final String username;
  final String password;
  final int streamId;
  final String title;

  const LivePlayerScreen({
    super.key,
    required this.serverUrl,
    required this.username,
    required this.password,
    required this.streamId,
    required this.title,
  });

  @override
  State<LivePlayerScreen> createState() => _LivePlayerScreenState();
}

class _LivePlayerScreenState extends State<LivePlayerScreen>
    with WidgetsBindingObserver {
  late final VlcPlayerController _vlcController;
  bool _isPlaying = true;
  bool _showControls = false;
  bool _hasError = false;
  bool _isDisposed = false;

  final ValueNotifier<Duration> _positionNotifier = ValueNotifier(
    Duration.zero,
  );
  final ValueNotifier<int> _latencyNotifier = ValueNotifier(0);

  Timer? _positionTimer;
  Timer? _retryTimer;
  Timer? _hideControlsTimer;
  Timer? _connectionCheckTimer;

  int _retryCount = 0;
  final int _maxRetryCount = 10;

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
    WidgetsBinding.instance.addObserver(this);

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _vlcController = VlcPlayerController.network(
      streamUrl,
      hwAcc: HwAcc.full,
      autoPlay: true,
    );

    _vlcController.addListener(_handlePlaybackState);

    Future.microtask(() {
      if (_isDisposed) return;
      _startConnectionTracking();
      _toggleControls();
      _startPositionTimer();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed) return;
    if (state == AppLifecycleState.paused) {
      _vlcController.pause();
    } else if (state == AppLifecycleState.resumed) {
      _vlcController.play();
    }
  }

  void _startPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!mounted || _isDisposed) return;
      final pos = await _vlcController.getPosition();
      if (!mounted || _isDisposed) return;
      _positionNotifier.value = pos;
    });
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final ping = Ping('8.8.8.8', count: 1);
      final result = await ping.stream.first;
      return (result.response != null && result.response!.time != null);
    } catch (_) {
      return false;
    }
  }

  void _handlePlaybackState() {
    if (!mounted || _isDisposed) return;
    final state = _vlcController.value;

    if (_hasError != state.hasError) {
      if (!mounted || _isDisposed) return;
      setState(() => _hasError = state.hasError);

      if (_hasError) {
        _retryTimer?.cancel();
        _retryCount = 0;

        _retryTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
          if (!mounted || _isDisposed) {
            timer.cancel();
            return;
          }

          bool connected = await _checkInternetConnection();

          if (connected) {
            try {
              await _vlcController.stop();
              await _vlcController.setMediaFromNetwork(
                streamUrl,
                autoPlay: true,
              );
              _retryCount = 0;
              setState(() => _hasError = false);
              timer.cancel();
            } catch (_) {}
          } else {
            _retryCount++;
            if (_retryCount >= _maxRetryCount) {
              timer.cancel();
              if (mounted) {
                setState(() {});
              }
            }
          }
        });
      } else {
        _retryTimer?.cancel();
        _retryCount = 0;
      }
    }

    if (_isPlaying != state.isPlaying) {
      if (!mounted || _isDisposed) return;
      setState(() => _isPlaying = state.isPlaying);
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

  String _formatTime(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours;
    final m = two(d.inMinutes.remainder(60));
    final s = two(d.inSeconds.remainder(60));
    return h > 0 ? '$h:$m:$s' : '$m:$s';
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
  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _positionTimer?.cancel();
    _retryTimer?.cancel();
    _hideControlsTimer?.cancel();
    _connectionCheckTimer?.cancel();

    _vlcController.removeListener(_handlePlaybackState);
    _vlcController.stop();
    _vlcController.dispose();
    _positionNotifier.dispose();
    _latencyNotifier.dispose();

    Future.delayed(Duration(milliseconds: 300), () {
      if (mounted) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      }
    });

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          VlcPlayer(
            controller: _vlcController,
            aspectRatio: screenSize.width / screenSize.height,
            placeholder: const Center(child: CircularProgressIndicator()),
          ),
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) => _toggleControls(),
              child: const SizedBox.expand(),
            ),
          ),
          if (_showControls)
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
                        final navigator = Navigator.of(context);

                        SystemChrome.setPreferredOrientations([
                          DeviceOrientation.portraitUp,
                          DeviceOrientation.portraitDown,
                        ]).then((_) {
                          if (mounted) {
                            navigator.pop();
                          }
                        });
                      },
                    ),

                    _signalIndicator(),
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
                    color: Colors.black.withAlpha((0.6 * 255).toInt()),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.access_time,
                        color: Colors.white70,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      ValueListenableBuilder<Duration>(
                        valueListenable: _positionNotifier,
                        builder: (context, position, _) {
                          return Text(
                            _formatTime(position),
                            style: const TextStyle(color: Colors.white70),
                          );
                        },
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        icon: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: screenSize.width > 700 ? 40 : 30,
                        ),
                        onPressed: () {
                          if (!mounted || _isDisposed) return;
                          setState(() {
                            _isPlaying = !_isPlaying;
                            _isPlaying
                                ? _vlcController.play()
                                : _vlcController.pause();
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
