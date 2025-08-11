import 'dart:async';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:dart_ping/dart_ping.dart';

enum ContentType { live, movie, series }

class UniversalPlayerMobile extends StatefulWidget {
  final ContentType type;
  final String? url;
  final String title;

  final String? serverUrl;
  final String? username;
  final String? password;
  final int? streamId;

  final Widget? logo;

  const UniversalPlayerMobile({
    super.key,
    required this.type,
    required this.title,
    this.url,
    this.serverUrl,
    this.username,
    this.password,
    this.streamId,
    required this.logo,
  });

  @override
  State<UniversalPlayerMobile> createState() => _UniversalPlayerMobileState();
}

class _UniversalPlayerMobileState extends State<UniversalPlayerMobile>
    with WidgetsBindingObserver {
  late VlcPlayerController _vlc;
  bool _isDisposed = false;

  bool _showControls = false;
  Timer? _hideTimer;

  bool get _isVod =>
      widget.type == ContentType.movie || widget.type == ContentType.series;
  String get _vodResumeKey => 'movie_resume_${widget.url ?? ''}';

  bool _vodIsPlaying = true;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  Timer? _trackTimer;
  StreamSubscription<InternetStatus>? _connSub;
  Timer? _recoveryTimer;
  bool _isReopening = false;
  bool _showBlockingLoader = false;
  double? _lockedAspectRatio;

  bool get _isLive => widget.type == ContentType.live;
  bool _hasError = false;
  bool _hasStarted = false;
  bool _sawFirstConnEvent = false;
  Timer? _retryTimer;
  int _retryCount = 0;
  final int _maxRetryCount = 10;
  Timer? _connectionCheckTimer;
  final ValueNotifier<int> _latencyNotifier = ValueNotifier(0);

  static bool? _isTvCached;
  bool _isTv = false;
  bool _orientationRestored = false;

  String get _liveStreamUrl {
    final encodedUser = Uri.encodeComponent(widget.username ?? '');
    final encodedPass = Uri.encodeComponent(widget.password ?? '');
    final encodedServer = (widget.serverUrl ?? '')
        .replaceAll('https://', '')
        .replaceAll('http://', '');
    final id = widget.streamId ?? 0;
    return 'http://$encodedServer/live/$encodedUser/$encodedPass/$id.m3u8';
  }

  Future<bool> _detectAndroidTV() async {
    if (_isTvCached != null) return _isTvCached!;
    if (defaultTargetPlatform != TargetPlatform.android) {
      _isTvCached = false;
      return false;
    }
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      final features = info.systemFeatures;
      final model = (info.model).toLowerCase();
      final brand = (info.brand).toLowerCase();
      final isTv =
          features.contains('android.software.leanback') ||
          features.contains('android.software.television') ||
          model.contains('tv') ||
          brand.contains('tv');
      _isTvCached = isTv;
      return isTv;
    } catch (_) {
      _isTvCached = false;
      return false;
    }
  }

  final FocusNode _playPauseFocus = FocusNode(debugLabel: 'play_pause_btn');
  final FocusNode _backButtonFocus = FocusNode(debugLabel: 'back_btn');
  bool get _isMobileOS =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _createController(initialForLive: _isLive);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _backButtonFocus.requestFocus();
        }
      });

      _isTv = await _detectAndroidTV();
      if (_isTv) {
        await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
      } else if (_isMobileOS) {
        await SystemChrome.setPreferredOrientations(const [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }

      if (_isVod) {
        _startVodTracking();
        _restoreLastPositionAndPlay();
      } else {
        _hasStarted = true;
        _startConnectionTracking();
      }

      _monitorInternet();
      _toggleControls();
    });
  }

  void _createController({required bool initialForLive}) {
    final source = initialForLive ? _liveStreamUrl : (widget.url ?? '');
    _vlc = VlcPlayerController.network(
      source,
      hwAcc: HwAcc.full,
      autoPlay: initialForLive,
      options: VlcPlayerOptions(
        advanced: VlcAdvancedOptions([VlcAdvancedOptions.networkCaching(1000)]),
        http: VlcHttpOptions([':http-user-agent=Mozilla/5.0']),
      ),
    );
    _vlc.addListener(_onVlcState);
  }

  void _onVlcState() {
    if (!mounted || _isDisposed) return;
    final v = _vlc.value;

    if (v.size.width > 0 && v.size.height > 0) {
      final ar = v.size.width / v.size.height;
      if (_lockedAspectRatio == null ||
          (_lockedAspectRatio! - ar).abs() > 0.01) {
        setState(() => _lockedAspectRatio = ar);
      }
    }

    if (_isVod) {
      setState(() => _vodIsPlaying = v.isPlaying);
      if (v.hasError) _ensureRecoveryVod();
    } else {
      if (v.hasError) _ensureRecoveryLive();
      if (_hasError != v.hasError) {
        setState(() => _hasError = v.hasError);
        if (_hasError) _startLiveRetryLoop();
      }
    }
  }

  final FocusNode _screenKbFocus = FocusNode(skipTraversal: true);

  void _startVodTracking() {
    _trackTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (_isDisposed) return;
      try {
        final pos = await _vlc.getPosition();
        final dur = await _vlc.getDuration();
        if (_isDisposed) return;
        setState(() {
          _position = pos;
          _duration = dur;
        });
        _saveLastPositionVod();
      } catch (_) {}
    });
  }

  Future<void> _restoreLastPositionAndPlay() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(_vodResumeKey) ?? 0;

    setState(() => _showBlockingLoader = true);

    try {
      await _vlc.setMediaFromNetwork(widget.url ?? '', autoPlay: false);
    } catch (_) {}
    try {
      await _vlc.play();
    } catch (_) {}

    await _waitUntilReadyForSeekVod();

    if (saved > 0 && _duration.inSeconds > 0) {
      try {
        await _vlc.pause();
        await _vlc.seekTo(Duration(seconds: saved));
        await Future.delayed(const Duration(milliseconds: 250));
      } catch (_) {}
    }

    try {
      await _vlc.play();
    } catch (_) {}

    if (saved > 0 && _duration.inSeconds > 0) {
      _ensureSeekAfterPlayVod(Duration(seconds: saved));
    }

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!_isDisposed && mounted) setState(() => _showBlockingLoader = false);
    });
  }

  Future<void> _saveLastPositionVod() async {
    if (_duration.inSeconds <= 0) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_vodResumeKey, _position.inSeconds);
    } catch (_) {}
  }

  void _ensureRecoveryVod() {
    if (_isDisposed) return;
    _recoveryTimer ??= Timer.periodic(const Duration(seconds: 3), (t) async {
      if (_isDisposed) {
        t.cancel();
        _recoveryTimer = null;
        return;
      }
      final online = await InternetConnection().hasInternetAccess;
      if (!online) return;

      if (!_showBlockingLoader) setState(() => _showBlockingLoader = true);

      final ok = await _reopenVodFromLast();
      if (ok) {
        t.cancel();
        _recoveryTimer = null;
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!_isDisposed) setState(() => _showBlockingLoader = false);
        });
      }
    });
  }

  Future<bool> _reopenVodFromLast() async {
    if (_isReopening || _isDisposed) return false;
    _isReopening = true;

    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(_vodResumeKey) ?? _position.inSeconds;
    final last = Duration(seconds: saved);

    try {
      try {
        await _vlc.stop();
      } catch (_) {}

      await _vlc.setMediaFromNetwork(widget.url ?? '', autoPlay: false);
      try {
        await _vlc.play();
      } catch (_) {}
      await _waitUntilReadyForSeekVod();

      if (last > Duration.zero && _duration.inSeconds > 0) {
        try {
          await _vlc.pause();
          await _vlc.seekTo(last);
          await Future.delayed(const Duration(milliseconds: 250));
        } catch (_) {}
      }

      await _vlc.play();

      if (last > Duration.zero && _duration.inSeconds > 0) {
        _ensureSeekAfterPlayVod(last);
      }

      _isReopening = false;
      return true;
    } catch (_) {
      try {
        _vlc.removeListener(_onVlcState);
        await _vlc.dispose();
      } catch (_) {}

      _createController(initialForLive: false);
      try {
        await _vlc.setMediaFromNetwork(widget.url ?? '', autoPlay: false);
        try {
          await _vlc.play();
        } catch (_) {}
        await _waitUntilReadyForSeekVod();
        if (last > Duration.zero && _duration.inSeconds > 0) {
          await _vlc.pause();
          await _vlc.seekTo(last);
          await Future.delayed(const Duration(milliseconds: 250));
        }
        await _vlc.play();
        if (last > Duration.zero && _duration.inSeconds > 0) {
          _ensureSeekAfterPlayVod(last);
        }
      } catch (_) {}
      _isReopening = false;
      return true;
    }
  }

  Future<void> _waitUntilReadyForSeekVod({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final sw = Stopwatch()..start();
    while (sw.elapsed < timeout) {
      if (_isDisposed) break;
      try {
        final dur = await _vlc.getDuration();
        final val = _vlc.value;
        final hasSize = val.size.width > 0 && val.size.height > 0;
        final ready =
            (dur.inSeconds > 0) || val.isPlaying || val.isBuffering || hasSize;
        if (ready) {
          _duration = dur;
          if (hasSize) {
            _lockedAspectRatio ??= val.size.width / val.size.height;
          }
          return;
        }
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  void _ensureSeekAfterPlayVod(Duration target) {
    Future<void> trySeek(int attempt) async {
      if (_isDisposed || _duration.inSeconds <= 0) return;
      try {
        final current = await _vlc.getPosition();
        if ((current - target).inSeconds.abs() >= 2) {
          await _vlc.seekTo(target);
        }
      } catch (_) {}
      if (attempt < 2) {
        Future.delayed(
          const Duration(milliseconds: 500),
          () => trySeek(attempt + 1),
        );
      }
    }

    trySeek(0);
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

  void _startLiveRetryLoop() {
    _retryTimer?.cancel();
    _retryCount = 0;

    _retryTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!mounted || _isDisposed) {
        timer.cancel();
        return;
      }

      final connected = await _checkInternetConnection();
      if (connected) {
        try {
          await _vlc.stop();
        } catch (_) {}
        try {
          await _vlc.setMediaFromNetwork(_liveStreamUrl, autoPlay: true);
          _retryCount = 0;
          setState(() => _hasError = false);
          timer.cancel();
        } catch (_) {}
      } else {
        _retryCount++;
        if (_retryCount >= _maxRetryCount) {
          timer.cancel();
          if (mounted) setState(() {});
        }
      }
    });
  }

  void _ensureRecoveryLive() {
    if (_isDisposed) return;

    if (_hasStarted && !_vlc.value.hasError && _vlc.value.isPlaying) return;

    _recoveryTimer ??= Timer.periodic(const Duration(seconds: 3), (t) async {
      if (_isDisposed) {
        t.cancel();
        _recoveryTimer = null;
        return;
      }
      final online = await InternetConnection().hasInternetAccess;
      if (!online) return;

      final ok = await _reopenLive();
      if (ok) {
        t.cancel();
        _recoveryTimer = null;
      }
    });
  }

  Future<bool> _reopenLive() async {
    if (_isReopening || _isDisposed) return false;

    if (_hasStarted && !_vlc.value.hasError && _vlc.value.isPlaying) {
      return false;
    }

    _isReopening = true;
    try {
      try {
        await _vlc.stop();
      } catch (_) {}

      await _vlc.setMediaFromNetwork(_liveStreamUrl, autoPlay: true);
      _isReopening = false;
      _hasStarted = true;
      if (mounted) setState(() => _hasError = false);
      return true;
    } catch (_) {
      try {
        _vlc.removeListener(_onVlcState);
        await _vlc.dispose();
      } catch (_) {}

      try {
        _createController(initialForLive: true);
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

  void _monitorInternet() {
    _connSub = InternetConnection().onStatusChange.listen((status) async {
      if (_isDisposed) return;

      if (_isLive) {
        if (!_sawFirstConnEvent) {
          _sawFirstConnEvent = true;
          return;
        }
      }

      if (status == InternetStatus.connected) {
        if (_isVod) {
          _ensureRecoveryVod();
        } else {
          _ensureRecoveryLive();
        }
      }
    });
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
    _hideTimer?.cancel();
    if (_showControls) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _playPauseFocus.requestFocus();
      });
      _hideTimer = Timer(const Duration(seconds: 4), () {
        if (!mounted || _isDisposed) return;
        setState(() => _showControls = false);
      });
    }
  }

  void _seekBy(int seconds) async {
    if (_isLive) return;
    if (_isDisposed) return;
    try {
      final current = await _vlc.getPosition();
      if (_isDisposed) return;
      await _vlc.seekTo(current + Duration(seconds: seconds));
    } catch (_) {}
  }

  String _formatTime(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours;
    final m = two(d.inMinutes.remainder(60));
    final s = two(d.inSeconds.remainder(60));
    return h > 0 ? '${two(h)}:$m:$s' : '$m:$s';
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
          child: Icon(icon, color: color, size: 26),
        );
      },
    );
  }

  Future<void> _restoreSystemOrientationOnce() async {
    if (_orientationRestored) return;
    _orientationRestored = true;

    if (_isTv) {
      await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    } else if (_isMobileOS) {
      await SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  void _toggleOrientationManually() async {
    if (_isTv) return;
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;
    await SystemChrome.setPreferredOrientations(
      isPortrait
          ? const [
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ]
          : const [
              DeviceOrientation.portraitUp,
              DeviceOrientation.portraitDown,
            ],
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed) return;
    if (state == AppLifecycleState.paused) {
      _vlc.pause();
    } else if (state == AppLifecycleState.resumed) {
      if (_vlc.value.hasError || !_vlc.value.isPlaying) {
        if (_isVod) {
          _ensureRecoveryVod();
        } else {
          _ensureRecoveryLive();
        }
      } else {
        _vlc.play();
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);

    if (_isVod) {
      _saveLastPositionVod();
    }

    _trackTimer?.cancel();
    _hideTimer?.cancel();
    _connSub?.cancel();
    _recoveryTimer?.cancel();
    _retryTimer?.cancel();
    _connectionCheckTimer?.cancel();
    _playPauseFocus.dispose();

    try {
      _vlc.removeListener(_onVlcState);
      _vlc.stop();
    } catch (_) {}
    _vlc.dispose();

    _latencyNotifier.dispose();

    _restoreSystemOrientationOnce();
    _backButtonFocus.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final ar = _lockedAspectRatio ?? (screen.width / screen.height);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        focusNode: _screenKbFocus,
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;

          final key = event.logicalKey;
          final isOk =
              key == LogicalKeyboardKey.select ||
              key == LogicalKeyboardKey.enter ||
              key == LogicalKeyboardKey.numpadEnter ||
              key == LogicalKeyboardKey.space;

          if (isOk) {
            _toggleControls();
            if (_showControls) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _playPauseFocus.requestFocus();
              });
            }
            return KeyEventResult.handled;
          }

          if (_showControls && key == LogicalKeyboardKey.arrowUp) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _backButtonFocus.requestFocus();
            });
            return KeyEventResult.handled;
          }

          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleControls,
          child: Stack(
            children: [
              Positioned.fill(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: ar,
                    child: VlcPlayer(
                      controller: _vlc,
                      aspectRatio: ar,
                      placeholder: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
                ),
              ),

              if (_isVod)
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: true,
                    child: ValueListenableBuilder<VlcPlayerValue>(
                      valueListenable: _vlc,
                      builder: (context, v, _) {
                        final isLoading =
                            _showBlockingLoader ||
                            v.isBuffering ||
                            _isReopening;
                        return AnimatedOpacity(
                          opacity: isLoading ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            color: Colors.black45,
                            alignment: Alignment.center,
                            child: const CircularProgressIndicator(),
                          ),
                        );
                      },
                    ),
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
                          focusNode: _backButtonFocus,
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () async {
                            if (_isVod) {
                              await _saveLastPositionVod();
                            }
                            await _restoreSystemOrientationOnce();

                            if (!context.mounted) {
                              return;
                            }
                            Navigator.of(context).pop();
                          },
                        ),
                        if (_isLive)
                          Padding(
                            padding: const EdgeInsets.only(right: 40),
                            child: _signalIndicator(),
                          )
                        else
                          IconButton(
                            icon: const Icon(
                              Icons.screen_rotation,
                              color: Colors.white,
                            ),
                            onPressed: _toggleOrientationManually,
                          ),
                      ],
                    ),
                  ),
                ),

              if (_showControls)
                Align(
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isVod)
                        IconButton(
                          icon: const Icon(
                            Icons.replay_10,
                            color: Colors.white,
                            size: 36,
                          ),
                          onPressed: () => _seekBy(-10),
                        ),
                      const SizedBox(width: 20),
                      IconButton(
                        focusNode: _playPauseFocus,
                        icon: Icon(
                          (_isVod ? _vodIsPlaying : _vlc.value.isPlaying)
                              ? Icons.pause_circle
                              : Icons.play_circle,
                          color: Colors.white,
                          size: 50,
                        ),
                        onPressed: () {
                          if (_isVod) {
                            if (_vodIsPlaying) {
                              _vlc.pause();
                            } else {
                              _vlc.play();
                            }
                            setState(() => _vodIsPlaying = !_vodIsPlaying);
                          } else {
                            if (_vlc.value.isPlaying) {
                              _vlc.pause();
                            } else {
                              _vlc.play();
                            }
                            setState(() {});
                          }
                        },
                      ),
                      const SizedBox(width: 20),
                      if (_isVod)
                        IconButton(
                          icon: const Icon(
                            Icons.forward_10,
                            color: Colors.white,
                            size: 36,
                          ),
                          onPressed: () => _seekBy(10),
                        ),
                    ],
                  ),
                ),

              if (_showControls)
                Positioned(
                  bottom: 16,
                  left: 12,
                  right: 12,
                  child: _isVod
                      ? Column(
                          children: [
                            Slider(
                              value: _position.inSeconds.toDouble(),
                              max:
                                  (_duration.inSeconds > 0
                                          ? _duration.inSeconds
                                          : _position.inSeconds + 1)
                                      .toDouble(),
                              onChanged: _duration.inSeconds > 0
                                  ? (v) => _vlc.seekTo(
                                      Duration(seconds: v.toInt()),
                                    )
                                  : null,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatTime(_position),
                                  style: const TextStyle(color: Colors.white),
                                ),
                                Text(
                                  _duration.inSeconds > 0
                                      ? _formatTime(_duration)
                                      : '--:--',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ],
                        )
                      : Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(
                                (0.6 * 255).toInt(),
                              ),
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
                                  valueListenable: _vlc,
                                  builder: (context, value, _) {
                                    return Text(
                                      _formatTime(value.position),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 20),
                                IconButton(
                                  icon: Icon(
                                    _vlc.value.isPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    color: Colors.white,
                                    size: screen.width > 700 ? 40 : 30,
                                  ),
                                  onPressed: () {
                                    if (!mounted || _isDisposed) return;
                                    if (_vlc.value.isPlaying) {
                                      _vlc.pause();
                                    } else {
                                      _vlc.play();
                                    }
                                    setState(() {});
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
                child: Opacity(opacity: 0.4, child: widget.logo),
              ),

              if (_isLive && _hasError)
                const Center(
                  child: Text(
                    "انقطع الاتصال بالبث... تتم إعادة المحاولة",
                    style: TextStyle(color: Colors.redAccent, fontSize: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
