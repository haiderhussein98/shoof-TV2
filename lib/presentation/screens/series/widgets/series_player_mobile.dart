import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class SeriesPlayerMobile extends StatefulWidget {
  final String url;
  final String title;

  const SeriesPlayerMobile({super.key, required this.url, required this.title});

  @override
  State<SeriesPlayerMobile> createState() => _SeriesPlayerMobileState();
}

class _SeriesPlayerMobileState extends State<SeriesPlayerMobile> {
  late VlcPlayerController _vlcController;
  bool _isPlaying = true;
  bool _showControls = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  Timer? _timer;
  Timer? _hideTimer;
  StreamSubscription<InternetStatus>? _connectionSub;
  Timer? _recoveryTimer;
  bool _isDisposed = false;
  bool _isReopening = false;
  bool _isExiting = false;

  bool _showBlockingLoader = false;
  double? _lockedAspectRatio;

  String get _resumeKey => 'series_resume_${widget.url}';

  @override
  void initState() {
    super.initState();
    _createController();
    _startTracking();
    _restoreLastPositionAndPlay();
    _monitorConnection();
  }

  void _createController() {
    _vlcController = VlcPlayerController.network(
      widget.url,
      hwAcc: HwAcc.full,
      autoPlay: false,
      options: VlcPlayerOptions(
        advanced: VlcAdvancedOptions([VlcAdvancedOptions.networkCaching(1000)]),
        http: VlcHttpOptions([':http-user-agent=Mozilla/5.0']),
      ),
    );
    _vlcController.addListener(_updateState);
  }

  void _monitorConnection() {
    _connectionSub = InternetConnection().onStatusChange.listen((status) async {
      if (_isDisposed) return;
      if (status == InternetStatus.connected) {
        _ensureRecovery();
      }
    });
  }

  void _updateState() {
    if (_isDisposed) return;
    final v = _vlcController.value;

    if (v.size.width > 0 && v.size.height > 0) {
      final ar = v.size.width / v.size.height;
      if (_lockedAspectRatio == null ||
          (_lockedAspectRatio! - ar).abs() > 0.01) {
        setState(() => _lockedAspectRatio = ar);
      }
    }

    if (mounted) setState(() => _isPlaying = v.isPlaying);
    if (v.hasError) _ensureRecovery();
  }

  void _startTracking() {
    _timer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (_isDisposed) return;
      try {
        final pos = await _vlcController.getPosition();
        final dur = await _vlcController.getDuration();
        if (_isDisposed) return;
        setState(() {
          _position = pos;
          _duration = dur;
        });
        _saveLastPosition();
      } catch (_) {}
    });
  }

  Future<void> _restoreLastPositionAndPlay() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(_resumeKey) ?? 0;

    setState(() => _showBlockingLoader = true);

    try {
      await _vlcController.setMediaFromNetwork(widget.url, autoPlay: false);
    } catch (_) {}

    try {
      await _vlcController.play();
    } catch (_) {}
    await _waitUntilReadyForSeek();

    if (saved > 0 && _duration.inSeconds > 0) {
      try {
        await _vlcController.pause();
        await _vlcController.seekTo(Duration(seconds: saved));
        await Future.delayed(const Duration(milliseconds: 250));
      } catch (_) {}
    }

    try {
      await _vlcController.play();
    } catch (_) {}

    if (saved > 0 && _duration.inSeconds > 0) {
      _ensureSeekAfterPlay(Duration(seconds: saved));
    }

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!_isDisposed) setState(() => _showBlockingLoader = false);
    });
  }

  Future<void> _saveLastPosition() async {
    if (_duration.inSeconds <= 0) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_resumeKey, _position.inSeconds);
    } catch (_) {}
  }

  void _ensureRecovery() {
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

      final ok = await _reopenStreamFromLast();
      if (ok) {
        t.cancel();
        _recoveryTimer = null;
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!_isDisposed) setState(() => _showBlockingLoader = false);
        });
      }
    });
  }

  Future<bool> _reopenStreamFromLast() async {
    if (_isReopening || _isDisposed) return false;
    _isReopening = true;

    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(_resumeKey) ?? _position.inSeconds;
    final last = Duration(seconds: saved);

    try {
      try {
        await _vlcController.stop();
      } catch (_) {}

      await _vlcController.setMediaFromNetwork(widget.url, autoPlay: false);

      try {
        await _vlcController.play();
      } catch (_) {}
      await _waitUntilReadyForSeek();

      if (last > Duration.zero && _duration.inSeconds > 0) {
        try {
          await _vlcController.pause();
          await _vlcController.seekTo(last);
          await Future.delayed(const Duration(milliseconds: 250));
        } catch (_) {}
      }

      await _vlcController.play();

      if (last > Duration.zero && _duration.inSeconds > 0) {
        _ensureSeekAfterPlay(last);
      }

      _isReopening = false;
      return true;
    } catch (_) {
      try {
        _vlcController.removeListener(_updateState);
        _vlcController.dispose();
      } catch (_) {}

      _createController();
      try {
        await _vlcController.setMediaFromNetwork(widget.url, autoPlay: false);
        try {
          await _vlcController.play();
        } catch (_) {}
        await _waitUntilReadyForSeek();
        if (last > Duration.zero && _duration.inSeconds > 0) {
          await _vlcController.pause();
          await _vlcController.seekTo(last);
          await Future.delayed(const Duration(milliseconds: 250));
        }
        await _vlcController.play();
        if (last > Duration.zero && _duration.inSeconds > 0) {
          _ensureSeekAfterPlay(last);
        }
      } catch (_) {}
      _isReopening = false;
      return true;
    }
  }

  Future<void> _waitUntilReadyForSeek({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final sw = Stopwatch()..start();
    while (sw.elapsed < timeout) {
      if (_isDisposed) break;
      final dur = await _vlcController.getDuration();
      final val = _vlcController.value;
      final hasSize = val.size.width > 0 && val.size.height > 0;
      final ready =
          (dur.inSeconds > 0) || val.isPlaying || val.isBuffering || hasSize;
      if (ready) {
        _duration = dur;

        if (val.size.width > 0 && val.size.height > 0) {
          final ar = val.size.width / val.size.height;
          _lockedAspectRatio ??= ar;
        }

        return;
      }
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  void _ensureSeekAfterPlay(Duration target) {
    Future<void> trySeek(int attempt) async {
      if (_isDisposed || _duration.inSeconds <= 0) return;
      try {
        final current = await _vlcController.getPosition();
        if ((current - target).inSeconds.abs() >= 2) {
          await _vlcController.seekTo(target);
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

  void _toggleOrientation() async {
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;
    await SystemChrome.setPreferredOrientations(
      isPortrait
          ? [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]
          : [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
    );
  }

  void _toggleControls() {
    if (_isDisposed) return;
    setState(() => _showControls = !_showControls);
    _hideTimer?.cancel();
    if (_showControls) {
      _hideTimer = Timer(const Duration(seconds: 4), () {
        if (!_isDisposed) {
          setState(() => _showControls = false);
        }
      });
    }
  }

  void _seekBy(int seconds) async {
    try {
      if (_isDisposed) return;
      final current = await _vlcController.getPosition();
      if (_isDisposed) return;
      await _vlcController.seekTo(current + Duration(seconds: seconds));
    } catch (_) {}
  }

  String formatTime(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours;
    final m = twoDigits(d.inMinutes.remainder(60));
    final s = twoDigits(d.inSeconds.remainder(60));
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  Future<void> _safeExit() async {
    if (_isExiting) return;
    _isExiting = true;

    await _saveLastPosition();

    _timer?.cancel();
    _hideTimer?.cancel();
    _connectionSub?.cancel();
    _recoveryTimer?.cancel();
    try {
      _vlcController.removeListener(_updateState);
      await _vlcController.pause();
      await _vlcController.stop();
    } catch (_) {}

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      } else {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      }
    });

    Future.delayed(const Duration(milliseconds: 360), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;

    _timer?.cancel();
    _hideTimer?.cancel();
    _connectionSub?.cancel();
    _recoveryTimer?.cancel();

    try {
      _vlcController.removeListener(_updateState);
      _vlcController.stop();
    } catch (_) {}
    _vlcController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;

    return PopScope(
      canPop: false,

      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await _safeExit();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleControls,
          child: Stack(
            children: [
              Positioned.fill(
                child: Center(
                  child: AspectRatio(
                    aspectRatio:
                        _lockedAspectRatio ?? (screen.width / screen.height),
                    child: VlcPlayer(
                      controller: _vlcController,
                      aspectRatio:
                          _lockedAspectRatio ?? (screen.width / screen.height),
                      placeholder: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
                ),
              ),

              Positioned.fill(
                child: IgnorePointer(
                  ignoring: true,
                  child: ValueListenableBuilder<VlcPlayerValue>(
                    valueListenable: _vlcController,
                    builder: (context, v, _) {
                      final isLoading =
                          _showBlockingLoader || v.isBuffering || _isReopening;
                      return AnimatedOpacity(
                        opacity: isLoading ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          color: Colors.black45,
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              CircularProgressIndicator(),
                              SizedBox(height: 12),
                              Text(
                                'جاري التحميل...',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              if (_showControls)
                Positioned.fill(
                  child: Container(
                    color: Colors.black54,
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                              onPressed: _safeExit,
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(
                                Icons.screen_rotation,
                                color: Colors.white,
                              ),
                              onPressed: _toggleOrientation,
                            ),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
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
                              icon: Icon(
                                _isPlaying
                                    ? Icons.pause_circle
                                    : Icons.play_circle,
                                color: Colors.white,
                                size: 50,
                              ),
                              onPressed: () {
                                if (_isPlaying) {
                                  _vlcController.pause();
                                } else {
                                  _vlcController.play();
                                }
                                setState(() => _isPlaying = !_isPlaying);
                              },
                            ),
                            const SizedBox(width: 20),
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
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Column(
                            children: [
                              Slider(
                                value: _position.inSeconds.toDouble(),
                                max:
                                    (_duration.inSeconds > 0
                                            ? _duration.inSeconds
                                            : _position.inSeconds + 1)
                                        .toDouble(),
                                onChanged: _duration.inSeconds > 0
                                    ? (v) => _vlcController.seekTo(
                                        Duration(seconds: v.toInt()),
                                      )
                                    : null,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    formatTime(_position),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  Text(
                                    _duration.inSeconds > 0
                                        ? formatTime(_duration)
                                        : '--:--',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
