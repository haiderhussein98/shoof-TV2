import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class SeriesPlayerDesktop extends StatefulWidget {
  final String serverUrl;
  final String username;
  final String password;
  final int episodeId;
  final String containerExtension;
  final String title;

  const SeriesPlayerDesktop({
    super.key,
    required this.serverUrl,
    required this.username,
    required this.password,
    required this.episodeId,
    required this.containerExtension,
    required this.title,
  });

  @override
  State<SeriesPlayerDesktop> createState() => _SeriesPlayerDesktopState();
}

class _SeriesPlayerDesktopState extends State<SeriesPlayerDesktop> {
  late final Player _player;
  late final VideoController _videoController;

  bool _isPlaying = true;
  bool _showControls = true;
  bool _hasError = false;
  bool _isDisposed = false;

  bool _isOpening = false;
  bool _isReopening = false;
  bool _openedOnce = false;
  bool _connectivityStarted = false;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  Timer? _hideControlsTimer;
  Timer? _recoveryTimer;

  StreamSubscription<InternetStatus>? _connSub;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration>? _durSub;
  StreamSubscription<bool>? _playingSub;

  int _lastSavedSecond = -1;

  String get _normalizedServer => widget.serverUrl
      .replaceAll('https://', '')
      .replaceAll('http://', '')
      .trim()
      .replaceAll(RegExp(r'/$'), '');

  String get _episodeUrl {
    final u = Uri.encodeComponent(widget.username);
    final p = Uri.encodeComponent(widget.password);
    final ext = widget.containerExtension.startsWith('.')
        ? widget.containerExtension
        : '.${widget.containerExtension}';
    final url =
        'http://$_normalizedServer/series/$u/$p/${widget.episodeId}$ext';
    return url;
  }

  Map<String, String> get _headers => const {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
        'AppleWebKit/537.36 (KHTML, like Gecko) '
        'Chrome/124.0.0.0 Safari/537.36',
    'Connection': 'keep-alive',
  };

  String get _resumeKey =>
      'series_resume_${_normalizedServer}_${widget.episodeId}';

  @override
  void initState() {
    super.initState();
    _player = Player(configuration: const PlayerConfiguration());
    _videoController = VideoController(_player);

    _listenPlayerStreams();
    _openFromSaved();
    _toggleControls();
  }

  void _listenPlayerStreams() {
    _posSub = _player.stream.position.listen((d) {
      if (_isDisposed) return;
      _position = d;
      _maybeSaveLastPosition();
      setState(() {});
    });

    _durSub = _player.stream.duration.listen((d) {
      if (_isDisposed) return;
      _duration = d;
      setState(() {});
    });

    _playingSub = _player.stream.playing.listen((playing) {
      if (_isDisposed) return;
      _isPlaying = playing;
      setState(() {});
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
      await _player.open(
        Media(_episodeUrl, httpHeaders: _headers),
        play: false,
      );

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

      await _player.open(
        Media(_episodeUrl, httpHeaders: _headers),
        play: false,
      );

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

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours;
    final m = two(d.inMinutes.remainder(60));
    final s = two(d.inSeconds.remainder(60));
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  void dispose() {
    _isDisposed = true;

    _maybeSaveLastPosition();

    _hideControlsTimer?.cancel();
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
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ),

          if (_showControls)
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: screenSize.width > 900 ? 40 : 30,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPlaying = !_isPlaying;
                            _isPlaying ? _player.play() : _player.pause();
                          });
                        },
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.replay_10, color: Colors.white),
                        onPressed: () => _player.seek(
                          _position - const Duration(seconds: 10),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.forward_10, color: Colors.white),
                        onPressed: () => _player.seek(
                          _position + const Duration(seconds: 10),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${_fmt(_position)}  /  ${_duration.inSeconds > 0 ? _fmt(_duration) : "--:--"}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
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
      ),
    );
  }
}
