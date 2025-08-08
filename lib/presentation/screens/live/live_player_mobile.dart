import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:dart_ping/dart_ping.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class LivePlayerMobile extends StatefulWidget {
  final String serverUrl;
  final String username;
  final String password;
  final int streamId;
  final String title;

  const LivePlayerMobile({
    super.key,
    required this.serverUrl,
    required this.username,
    required this.password,
    required this.streamId,
    required this.title,
  });

  @override
  State<LivePlayerMobile> createState() => _LivePlayerMobileState();
}

class _LivePlayerMobileState extends State<LivePlayerMobile>
    with WidgetsBindingObserver {
  late VlcPlayerController _vlcController;
  bool _isPlaying = true;
  bool _showControls = false;
  bool _hasError = false;
  bool _isDisposed = false;

  final ValueNotifier<int> _latencyNotifier = ValueNotifier(0);

  Timer? _retryTimer;
  Timer? _hideControlsTimer;
  Timer? _connectionCheckTimer;
  StreamSubscription<InternetStatus>? _connSub;
  Timer? _recoveryTimer;
  bool _isReopening = false;

  bool _hasStarted = false;
  bool _sawFirstConnEvent = false;

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

    _hasStarted = true;

    Future.microtask(() {
      if (_isDisposed) return;
      _startConnectionTracking();
      _monitorInternet();
      _toggleControls();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed) return;
    if (state == AppLifecycleState.paused) {
      _vlcController.pause();
    } else if (state == AppLifecycleState.resumed) {
      if (_vlcController.value.hasError || !_vlcController.value.isPlaying) {
        _ensureRecovery();
      } else {
        _vlcController.play();
      }
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
        if (_hasStarted &&
            !_vlcController.value.hasError &&
            _vlcController.value.isPlaying) {
          return;
        }
        _ensureRecovery();
      }
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

    if (state.hasError) {
      _ensureRecovery();
    }

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

  void _ensureRecovery() {
    if (_isDisposed) return;

    if (_hasStarted &&
        !_vlcController.value.hasError &&
        _vlcController.value.isPlaying) {
      return;
    }

    _recoveryTimer ??= Timer.periodic(const Duration(seconds: 3), (t) async {
      if (_isDisposed) {
        t.cancel();
        _recoveryTimer = null;
        return;
      }
      final online = await InternetConnection().hasInternetAccess;
      if (!online) return;

      final ok = await _reopenStream();
      if (ok) {
        t.cancel();
        _recoveryTimer = null;
      }
    });
  }

  Future<bool> _reopenStream() async {
    if (_isReopening || _isDisposed) return false;

    if (_hasStarted &&
        !_vlcController.value.hasError &&
        _vlcController.value.isPlaying) {
      return false;
    }

    _isReopening = true;
    try {
      try {
        await _vlcController.stop();
      } catch (_) {}

      await _vlcController.setMediaFromNetwork(streamUrl, autoPlay: true);
      _isReopening = false;
      _hasStarted = true;
      if (mounted) setState(() => _hasError = false);
      return true;
    } catch (_) {
      try {
        _vlcController.removeListener(_handlePlaybackState);
        await _vlcController.dispose();
      } catch (_) {}

      try {
        _vlcController = VlcPlayerController.network(
          streamUrl,
          hwAcc: HwAcc.full,
          autoPlay: true,
        );
        _vlcController.addListener(_handlePlaybackState);
        _isReopening = false;
        _hasStarted = true;
        if (mounted) setState(() => _hasError = false);
        return true;
      } catch (_) {
        _isReopening = false;
        return false;
      }
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
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _retryTimer?.cancel();
    _hideControlsTimer?.cancel();
    _connectionCheckTimer?.cancel();
    _connSub?.cancel();
    _recoveryTimer?.cancel();

    _vlcController.removeListener(_handlePlaybackState);
    try {
      _vlcController.stop();
    } catch (_) {}
    _vlcController.dispose();
    _latencyNotifier.dispose();

    Future.delayed(const Duration(milliseconds: 300), () {
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
                      ValueListenableBuilder<VlcPlayerValue>(
                        valueListenable: _vlcController,
                        builder: (context, value, _) {
                          return Text(
                            _formatTime(value.position),
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
