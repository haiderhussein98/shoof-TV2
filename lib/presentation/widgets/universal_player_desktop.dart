import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:dart_ping/dart_ping.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

enum DesktopContentType { live, movie, series }

class UniversalPlayerDesktop extends StatefulWidget {
  final DesktopContentType type;
  final String title;

  final String? serverUrl;
  final String? username;
  final String? password;
  final int? streamId;

  final String? movieUrl;

  final String? serverUrlSeries;
  final String? usernameSeries;
  final String? passwordSeries;
  final int? episodeId;
  final String? containerExtension;

  const UniversalPlayerDesktop.live({
    super.key,
    required this.title,
    required this.serverUrl,
    required this.username,
    required this.password,
    required this.streamId,
  })  : type = DesktopContentType.live,
        movieUrl = null,
        serverUrlSeries = null,
        usernameSeries = null,
        passwordSeries = null,
        episodeId = null,
        containerExtension = null;

  const UniversalPlayerDesktop.movie({
    super.key,
    required this.title,
    required this.movieUrl,
  })  : type = DesktopContentType.movie,
        serverUrl = null,
        username = null,
        password = null,
        streamId = null,
        serverUrlSeries = null,
        usernameSeries = null,
        passwordSeries = null,
        episodeId = null,
        containerExtension = null;

  const UniversalPlayerDesktop.series({
    super.key,
    required this.title,
    required this.serverUrlSeries,
    required this.usernameSeries,
    required this.passwordSeries,
    required this.episodeId,
    required this.containerExtension,
  })  : type = DesktopContentType.series,
        serverUrl = null,
        username = null,
        password = null,
        streamId = null,
        movieUrl = null;

  @override
  State<UniversalPlayerDesktop> createState() => _UniversalPlayerDesktopState();
}

class _UniversalPlayerDesktopState extends State<UniversalPlayerDesktop> {
  late final Player _player;
  late final VideoController _video;

  bool _isDisposed = false;
  bool _hasError = false;
  Timer? _recoveryTimer;

  bool _liveisPlaying = true;
  bool _liveshowControls = true;
  bool _liveisReopening = false;
  bool _livehasStarted = false;
  bool _livesawFirstConnEvent = false;
  final ValueNotifier<int> _latencyNotifier = ValueNotifier(0);
  Timer? _connectionCheckTimer;
  StreamSubscription<InternetStatus>? _connSub;
  Timer? _hideControlsTimer;

  bool _vodisOpening = false;
  bool _vodisReopening = false;
  bool _vodopenedOnce = false;
  bool _vodconnectivityStarted = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  int _lastSavedSecond = -1;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration>? _durSub;
  StreamSubscription<bool>? _playingSub;

  void _toggleControls() {
    setState(() => _liveshowControls = !_liveshowControls);
    _hideControlsTimer?.cancel();
    if (_liveshowControls) {
      _hideControlsTimer = Timer(const Duration(seconds: 4), () {
        if (!mounted || _isDisposed) return;
        setState(() => _liveshowControls = false);
      });
    }
  }

  String get _liveUrl {
    final encodedServer = (widget.serverUrl ?? '')
        .replaceAll('https://', '')
        .replaceAll('http://', '')
        .trim()
        .replaceAll(RegExp(r'/$'), '');
    final u = Uri.encodeComponent(widget.username ?? '');
    final p = Uri.encodeComponent(widget.password ?? '');
    final id = widget.streamId ?? 0;
    return 'http://$encodedServer/live/$u/$p/$id.m3u8';
  }

  String get _normalizedServerSeries => (widget.serverUrlSeries ?? '')
      .replaceAll('https://', '')
      .replaceAll('http://', '')
      .trim()
      .replaceAll(RegExp(r'/$'), '');

  String get _seriesUrl {
    final u = Uri.encodeComponent(widget.usernameSeries ?? '');
    final p = Uri.encodeComponent(widget.passwordSeries ?? '');
    final ext = (widget.containerExtension ?? '').startsWith('.')
        ? (widget.containerExtension ?? '')
        : '.${widget.containerExtension ?? ''}';
    final id = widget.episodeId ?? 0;
    return 'http://$_normalizedServerSeries/series/$u/$p/$id$ext';
  }

  Map<String, String> get _seriesHeaders => const {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
            'AppleWebKit/537.36 (KHTML, like Gecko) '
            'Chrome/124.0.0.0 Safari/537.36',
        'Connection': 'keep-alive',
      };

  String get _seriesResumeKey =>
      'series_resume_${_normalizedServerSeries}_${widget.episodeId}';
  String get _movieResumeKey => 'movie_resume_${widget.movieUrl ?? ''}';

  @override
  void initState() {
    super.initState();
    MediaKit.ensureInitialized();
    _player = Player(configuration: const PlayerConfiguration());
    _video = VideoController(_player);

    if (widget.type == DesktopContentType.live) {
      _initLive();
    } else {
      _initVod();
    }
  }

  void _initLive() {
    _startLive();
    _startConnectionTracking();
    _monitorInternet();
    _toggleControls();
  }

  Future<void> _startLive() async {
    try {
      if (_livehasStarted && _player.state.playing) return;
      await _player.open(Media(_liveUrl), play: true);
      _liveisPlaying = true;
      _hasError = false;
      _livehasStarted = true;
      if (mounted) setState(() {});
    } catch (_) {
      _hasError = true;
      if (mounted) setState(() {});
      _ensureRecovery();
    }
  }

  void _initVod() {
    _listenVodStreams();
    _openVodFromSaved();
  }

  void _listenVodStreams() {
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

    _playingSub = _player.stream.playing.listen((_) {
      if (_isDisposed) return;
      if (mounted) setState(() {});
    });
  }

  Future<void> _openVodFromSaved() async {
    if (_vodopenedOnce || _vodisOpening || _vodisReopening || _isDisposed) {
      return;
    }
    _vodisOpening = true;

    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(
          widget.type == DesktopContentType.series
              ? _seriesResumeKey
              : _movieResumeKey,
        ) ??
        0;

    try {
      if (widget.type == DesktopContentType.series) {
        await _player.open(
          Media(_seriesUrl, httpHeaders: _seriesHeaders),
          play: false,
        );
      } else {
        await _player.open(Media(widget.movieUrl ?? ''), play: false);
      }

      await _waitUntilSeekable();
      await _seekSafely(saved);
      await _player.play();

      _hasError = false;
      _vodopenedOnce = true;
      if (mounted) setState(() {});
      _startConnectivityWatchOnce();
    } catch (_) {
      _hasError = true;
      if (mounted) setState(() {});
      _startConnectivityWatchOnce();
      _ensureRecovery();
    } finally {
      _vodisOpening = false;
    }
  }

  void _monitorInternet() {
    _connSub = InternetConnection().onStatusChange.listen((status) async {
      if (_isDisposed) return;

      if (widget.type == DesktopContentType.live) {
        if (!_livesawFirstConnEvent) {
          _livesawFirstConnEvent = true;
          return;
        }
      }

      if (status == InternetStatus.connected) {
        _ensureRecovery();
      }
    });
  }

  void _ensureRecovery() {
    if (_isDisposed) return;

    if (widget.type == DesktopContentType.live) {
      if (_liveisReopening) return;
      if (_livehasStarted && !_hasError && _player.state.playing) return;
    } else {
      if (_vodisReopening || _vodisOpening) return;
      if (!_hasError && _player.state.playing && _vodopenedOnce) return;
    }

    if (_recoveryTimer != null) return;

    _recoveryTimer = Timer.periodic(const Duration(seconds: 3), (t) async {
      if (_isDisposed) {
        t.cancel();
        _recoveryTimer = null;
        return;
      }
      final online = await InternetConnection().hasInternetAccess;
      if (!online) return;

      if (widget.type == DesktopContentType.live) {
        await _reopenLive();
      } else {
        await _reopenVod();
      }
      t.cancel();
      _recoveryTimer = null;
    });
  }

  Future<void> _reopenLive() async {
    if (_liveisReopening || _isDisposed) return;

    if (_livehasStarted && _player.state.playing && !_hasError) return;

    _liveisReopening = true;
    try {
      await _player.stop();
      await _player.open(Media(_liveUrl), play: true);
      _hasError = false;
      _liveisPlaying = true;
      _livehasStarted = true;
    } catch (_) {
      _hasError = true;
    } finally {
      _liveisReopening = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _reopenVod() async {
    if (_vodisReopening || _vodisOpening || _isDisposed) return;
    _vodisReopening = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt(
            widget.type == DesktopContentType.series
                ? _seriesResumeKey
                : _movieResumeKey,
          ) ??
          0;

      await _player.stop();
      if (widget.type == DesktopContentType.series) {
        await _player.open(
          Media(_seriesUrl, httpHeaders: _seriesHeaders),
          play: false,
        );
      } else {
        await _player.open(Media(widget.movieUrl ?? ''), play: false);
      }

      await _waitUntilSeekable();
      await _seekSafely(saved);
      await _player.play();

      _hasError = false;
    } catch (_) {
      _hasError = true;
    } finally {
      _vodisReopening = false;
      if (mounted) setState(() {});
    }
  }

  void _startConnectivityWatchOnce() {
    if (_vodconnectivityStarted) return;
    _vodconnectivityStarted = true;
    _monitorInternet();
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
    if (widget.type == DesktopContentType.live) return;
    final total = _duration.inSeconds;
    final currentSec = _position.inSeconds;

    if (total > 0 && currentSec >= (total * 0.95).floor()) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(
          widget.type == DesktopContentType.series
              ? _seriesResumeKey
              : _movieResumeKey,
        );
      } catch (_) {}
      return;
    }

    if (currentSec - _lastSavedSecond >= 5) {
      _lastSavedSecond = currentSec;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(
          widget.type == DesktopContentType.series
              ? _seriesResumeKey
              : _movieResumeKey,
          currentSec,
        );
      } catch (_) {}
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

  @override
  void dispose() {
    _isDisposed = true;

    if (widget.type != DesktopContentType.live) {
      _maybeSaveLastPosition();
    }

    _connectionCheckTimer?.cancel();
    _connSub?.cancel();
    _hideControlsTimer?.cancel();
    _recoveryTimer?.cancel();

    _posSub?.cancel();
    _durSub?.cancel();
    _playingSub?.cancel();

    _latencyNotifier.dispose();

    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Video(controller: _video, fit: BoxFit.contain),
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) => _toggleControls(),
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  if (widget.type == DesktopContentType.live)
                    Padding(
                      padding: const EdgeInsets.only(right: 40),
                      child: _signalIndicator(),
                    ),
                ],
              ),
            ),
          ),
          if (widget.type == DesktopContentType.live && _liveshowControls)
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
                      IconButton(
                        icon: Icon(
                          _liveisPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: screen.width > 700 ? 40 : 30,
                        ),
                        onPressed: () {
                          setState(() {
                            _liveisPlaying = !_liveisPlaying;
                            _liveisPlaying ? _player.play() : _player.pause();
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
                "انقطع الاتصال بالمشغّل... تتم إعادة المحاولة",
                style: TextStyle(color: Colors.redAccent, fontSize: 16),
              ),
            ),
        ],
      ),
    );
  }
}
