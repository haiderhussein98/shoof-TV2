import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'widgets/movie_video_view.dart';
import 'widgets/movie_loading_overlay.dart';
import 'widgets/movie_top_controls.dart';
import 'widgets/movie_center_controls.dart';
import 'widgets/movie_seekbar.dart';

class MoviePlayerScreen extends StatefulWidget {
  final String url;
  final String title;

  const MoviePlayerScreen({super.key, required this.url, required this.title});

  @override
  State<MoviePlayerScreen> createState() => _MoviePlayerScreenState();
}

class _MoviePlayerScreenState extends State<MoviePlayerScreen> {
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

  bool _showBlockingLoader = false;

  double? _lockedAspectRatio;

  String get _resumeKey => 'movie_resume_${widget.url}';

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
      final pos = await _vlcController.getPosition();
      final dur = await _vlcController.getDuration();
      if (_isDisposed) return;
      setState(() {
        _position = pos;
        _duration = dur;
      });
      _saveLastPosition();
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_resumeKey, _position.inSeconds);
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
    if (isPortrait) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    _hideTimer?.cancel();
    if (_showControls) {
      _hideTimer = Timer(const Duration(seconds: 4), () {
        if (mounted && !_isDisposed) setState(() => _showControls = false);
      });
    }
  }

  void _seekBy(int seconds) async {
    if (_isDisposed) return;
    final current = await _vlcController.getPosition();
    if (_isDisposed) return;
    _vlcController.seekTo(current + Duration(seconds: seconds));
  }

  String formatTime(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours;
    final m = two(d.inMinutes.remainder(60));
    final s = two(d.inSeconds.remainder(60));
    return h > 0 ? '${two(h)}:$m:$s' : '$m:$s';
  }

  @override
  void dispose() {
    _isDisposed = true;
    _saveLastPosition();

    _timer?.cancel();
    _hideTimer?.cancel();
    _connectionSub?.cancel();
    _recoveryTimer?.cancel();
    try {
      _vlcController.removeListener(_updateState);
      _vlcController.stop();
    } catch (_) {}
    _vlcController.dispose();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didpop, result) async {
        if (!didpop) {
          await _saveLastPosition();
        } else {
          await _saveLastPosition();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleControls,
          child: Stack(
            children: [
              MovieVideoView(
                controller: _vlcController,
                aspectRatio:
                    _lockedAspectRatio ?? (screen.width / screen.height),
              ),

              MovieLoadingOverlay(
                controller: _vlcController,
                showBlockingLoader: _showBlockingLoader,
                isReopening: _isReopening,
              ),

              if (_showControls)
                MovieTopControls(
                  onBack: () async {
                    final navigator = Navigator.of(context);

                    await _saveLastPosition();

                    if (!mounted) return;
                    navigator.pop();
                  },
                  onRotate: _toggleOrientation,
                ),

              if (_showControls)
                MovieCenterControls(
                  isPlaying: _isPlaying,
                  onReplay10: () => _seekBy(-10),
                  onTogglePlay: () {
                    if (_isPlaying) {
                      _vlcController.pause();
                    } else {
                      _vlcController.play();
                    }
                    setState(() => _isPlaying = !_isPlaying);
                  },
                  onForward10: () => _seekBy(10),
                ),

              if (_showControls)
                MovieSeekbar(
                  position: _position,
                  duration: _duration,
                  formatTime: formatTime,
                  onSeek: (sec) =>
                      _vlcController.seekTo(Duration(seconds: sec)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
