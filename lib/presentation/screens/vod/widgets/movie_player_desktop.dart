import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class MoviePlayerDesktop extends StatefulWidget {
  final String url;
  final String title;

  const MoviePlayerDesktop({super.key, required this.url, required this.title});

  @override
  State<MoviePlayerDesktop> createState() => _MoviePlayerDesktopState();
}

class _MoviePlayerDesktopState extends State<MoviePlayerDesktop> {
  late final Player _player;
  late final VideoController _videoController;

  bool _hasError = false;
  bool _isDisposed = false;

  bool _isOpening = false;
  bool _isReopening = false;
  bool _openedOnce = false;
  bool _connectivityStarted = false;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  Timer? _recoveryTimer;

  StreamSubscription<InternetStatus>? _connSub;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration>? _durSub;
  StreamSubscription<bool>? _playingSub;

  int _lastSavedSecond = -1;

  String get _resumeKey => 'movie_resume_${widget.url}';

  @override
  void initState() {
    super.initState();
    _player = Player(configuration: const PlayerConfiguration());
    _videoController = VideoController(_player);

    _listenPlayerStreams();
    _openFromSaved();
  }

  void _listenPlayerStreams() {
    _posSub = _player.stream.position.listen((d) {
      if (_isDisposed) return;
      _position = d;
      _maybeSaveLastPosition();
      if (mounted) setState(() {});
    });

    _durSub = _player.stream.duration.listen((d) {
      if (_isDisposed) return;
      _duration = d;
      if (mounted) setState(() {});
    });

    _playingSub = _player.stream.playing.listen((playing) {
      if (_isDisposed) return;
      if (mounted) setState(() {});
    });
  }

  void _startConnectivityWatchOnce() {
    if (_connectivityStarted) return;
    _connectivityStarted = true;

    _connSub = InternetConnection().onStatusChange.listen((status) async {
      if (_isDisposed) return;
      if (status == InternetStatus.connected) {
        _ensureRecovery();
      }
    });
  }

  Future<void> _waitUntilSeekable({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final completer = Completer<void>();
    late StreamSubscription<Duration> sub;
    bool completed = false;

    sub = _player.stream.duration.listen((d) {
      if (!completed && d > Duration.zero) {
        completed = true;
        completer.complete();
      }
    });

    try {
      await completer.future.timeout(timeout, onTimeout: () {});
    } finally {
      await sub.cancel();
    }

    await Future.delayed(const Duration(milliseconds: 120));
  }

  Future<void> _seekSafely(int savedSec) async {
    if (savedSec <= 0) return;
    int target = savedSec;
    final dur = _duration.inSeconds;
    if (dur > 0 && target >= dur - 3) {
      target = (dur - 5).clamp(0, dur);
    }

    try {
      await _player.seek(Duration(seconds: target));
    } catch (_) {
      await Future.delayed(const Duration(milliseconds: 150));
      try {
        await _player.seek(Duration(seconds: target));
      } catch (_) {}
    }
  }

  Future<void> _maybeSaveLastPosition() async {
    final total = _duration.inSeconds;
    final currentSec = _position.inSeconds;

    if (total > 0 && currentSec >= (total * 0.95).floor()) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_resumeKey);
      } catch (_) {}
      return;
    }

    if (currentSec - _lastSavedSecond >= 5) {
      _lastSavedSecond = currentSec;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_resumeKey, currentSec);
      } catch (_) {}
    }
  }

  Future<void> _openFromSaved() async {
    if (_openedOnce || _isOpening || _isReopening || _isDisposed) return;
    _isOpening = true;

    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(_resumeKey) ?? 0;

    try {
      await _player.open(Media(widget.url), play: false);

      await _waitUntilSeekable();
      await _seekSafely(saved);
      await _player.play();

      _hasError = false;
      _openedOnce = true;
      if (mounted) setState(() {});
      _startConnectivityWatchOnce();
    } catch (_) {
      _hasError = true;
      if (mounted) setState(() {});
      _startConnectivityWatchOnce();
      _ensureRecovery();
    } finally {
      _isOpening = false;
    }
  }

  void _ensureRecovery() {
    if (_isReopening || _isOpening || _isDisposed) return;

    if (!_hasError && _player.state.playing && _openedOnce) return;

    if (_recoveryTimer != null) return;

    _recoveryTimer = Timer.periodic(const Duration(seconds: 3), (t) async {
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
    if (_isReopening || _isOpening || _isDisposed) return;
    _isReopening = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt(_resumeKey) ?? 0;

      await _player.stop();
      await _player.open(Media(widget.url), play: false);

      await _waitUntilSeekable();
      await _seekSafely(saved);
      await _player.play();

      _hasError = false;
    } catch (_) {
      _hasError = true;
    } finally {
      _isReopening = false;
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _isDisposed = true;

    _maybeSaveLastPosition();

    _recoveryTimer?.cancel();
    _connSub?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    _playingSub?.cancel();

    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Video(controller: _videoController, fit: BoxFit.contain),

        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: SafeArea(
            child: Row(
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
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),

        if (_hasError)
          const Center(
            child: Text(
              "انقطع الاتصال بالمشغّل... تتم إعادة المحاولة",
              style: TextStyle(color: Colors.redAccent, fontSize: 16),
            ),
          ),
      ],
    );
  }
}
