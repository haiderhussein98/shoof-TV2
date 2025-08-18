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
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoof_tv/domain/providers/live_providers.dart';
import 'package:shoof_tv/data/models/channel_model.dart';

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
  // =================== حالة المشغّل ===================
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

  // مراقبة التعطل للبث
  Timer? _stallWatchTimer;
  int? _lastLivePosSec;
  DateTime? _lastLivePosTs;

  static bool? _isTvCached;
  bool _isTv = false;
  bool _orientationRestored = false;
  bool _routeAnimHooked = false;

  // ===== واجهة ستلايت =====
  double _leftPaneWidth = 280;
  bool _isFullscreen = false;

  // تحكم جانبي (صغّرنا الأشرطة)
  double _brightness = 1.0;
  double _volume = 70;
  bool _showSideSliders = false;

  // قناة حالية
  int? _currentStreamId;
  String? _currentCategoryId;
  String? _currentCategoryName;
  String? _currentChannelName;
  bool _isSwitchingChannel = false;

  final ScrollController _leftPaneScroll = ScrollController();

  // =================== Helpers ===================
  String _liveStreamUrlFor(int? streamId) {
    final encodedUser = Uri.encodeComponent(widget.username ?? '');
    final encodedPass = Uri.encodeComponent(widget.password ?? '');
    final encodedServer = (widget.serverUrl ?? '')
        .replaceAll('https://', '')
        .replaceAll('http://', '');
    final id = streamId ?? 0;
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
      final isTv = features.contains('android.software.leanback') ||
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

  // =================== Lifecycle ===================
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentStreamId = widget.streamId;

    _createController(initialForLive: _isLive);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _backButtonFocus.requestFocus();
      });

      if (_isVod) {
        _startVodTracking();
        _restoreLastPositionAndPlay();
      } else {
        _hasStarted = true;
        _startConnectionTracking();
        _startLiveStallWatch();
      }

      _monitorInternet();
      _toggleControls();
      try {
        await _vlc.setVolume(_volume.toInt());
      } catch (_) {}
    });
  }

  Future<void> _setupSystemUiAfterTransition() async {
    if (!mounted || _isDisposed) return;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _isTv = await _detectAndroidTV();
    if (_isTv) {
      await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    } else if (_isMobileOS) {
      await SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeAnimHooked) return;
    _routeAnimHooked = true;

    final anim = ModalRoute.of(context)?.animation;
    if (anim == null) {
      _setupSystemUiAfterTransition();
      return;
    }
    if (anim.status == AnimationStatus.completed) {
      _setupSystemUiAfterTransition();
    } else {
      void listener(AnimationStatus s) {
        if (s == AnimationStatus.completed) {
          anim.removeStatusListener(listener);
          _setupSystemUiAfterTransition();
        }
      }

      anim.addStatusListener(listener);
    }
  }

  void _createController({required bool initialForLive}) {
    final source = initialForLive
        ? _liveStreamUrlFor(_currentStreamId)
        : (widget.url ?? '');

    final liveOptions = VlcPlayerOptions(
      advanced: VlcAdvancedOptions([
        VlcAdvancedOptions.liveCaching(400),
        VlcAdvancedOptions.networkCaching(400),
      ]),
      http: VlcHttpOptions([':http-user-agent=Mozilla/5.0']),
    );

    final vodOptions = VlcPlayerOptions(
      advanced: VlcAdvancedOptions([VlcAdvancedOptions.networkCaching(1000)]),
      http: VlcHttpOptions([':http-user-agent=Mozilla/5.0']),
    );

    _vlc = VlcPlayerController.network(
      source,
      hwAcc: HwAcc.full,
      autoPlay: initialForLive,
      options: initialForLive ? liveOptions : vodOptions,
    );
    _vlc.addListener(_onVlcState);
  }

  Future<void> _switchLiveChannel(ChannelModel ch) async {
    if (_isSwitchingChannel || _isDisposed) return;
    _isSwitchingChannel = true;
    setState(() {
      _currentCategoryId = ch.categoryId;
      _currentCategoryName = ch.categoryId;
      _currentChannelName = ch.name;
    });

    try {
      final url = _liveStreamUrlFor(ch.streamId);
      try {
        await _vlc.pause();
      } catch (_) {}
      await _vlc.setMediaFromNetwork(url, autoPlay: true);
      _hasError = false;
      _retryCount = 0;
      setState(() => _currentStreamId = ch.streamId);
    } catch (_) {
      _ensureRecoveryLive();
    } finally {
      _isSwitchingChannel = false;
    }
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
      final currSec = v.position.inSeconds;
      if (_lastLivePosSec == null) {
        _lastLivePosSec = currSec;
        _lastLivePosTs = DateTime.now();
      } else {
        if (currSec != _lastLivePosSec) {
          _lastLivePosSec = currSec;
          _lastLivePosTs = DateTime.now();
        }
      }

      if (v.hasError) _ensureRecoveryLive();
      if (_hasError != v.hasError) {
        setState(() => _hasError = v.hasError);
        if (_hasError) _startLiveRetryLoop();
      }
    }
  }

  final FocusNode _screenKbFocus = FocusNode(skipTraversal: true);

  // =================== VOD helpers ===================
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

  Future<void> _waitUntilReadyForSeekVod(
      {Duration timeout = const Duration(seconds: 8)}) async {
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
          if (hasSize) _lockedAspectRatio ??= val.size.width / val.size.height;
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
            const Duration(milliseconds: 500), () => trySeek(attempt + 1));
      }
    }

    trySeek(0);
  }

  // =================== Live recovery/connection ===================
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
          await _vlc.setMediaFromNetwork(_liveStreamUrlFor(_currentStreamId),
              autoPlay: true);
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

      await _vlc.setMediaFromNetwork(_liveStreamUrlFor(_currentStreamId),
          autoPlay: true);
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
    _connectionCheckTimer =
        Timer.periodic(const Duration(seconds: 3), (_) async {
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

  void _startLiveStallWatch() {
    _stallWatchTimer?.cancel();
    _stallWatchTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || _isDisposed || !_isLive) return;
      final v = _vlc.value;
      if (v.isBuffering || v.hasError) return;
      final sec = v.position.inSeconds;
      final now = DateTime.now();
      if (_lastLivePosSec == null) {
        _lastLivePosSec = sec;
        _lastLivePosTs = now;
        return;
      }
      if (sec == _lastLivePosSec) {
        final stuckFor = now.difference(_lastLivePosTs ?? now);
        if (stuckFor > const Duration(seconds: 10)) {
          _ensureRecoveryLive();
          _lastLivePosTs = now;
        }
      } else {
        _lastLivePosSec = sec;
        _lastLivePosTs = now;
      }
    });
  }

  // =================== UI actions ===================
  void _toggleControls() {
    if (!mounted || _isDisposed) return;
    setState(() {
      _showControls = !_showControls;
      _showSideSliders = _showControls;
    });
    _hideTimer?.cancel();
    if (_showControls) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _playPauseFocus.requestFocus();
      });
      _hideTimer = Timer(const Duration(seconds: 3), () {
        if (!mounted || _isDisposed) return;
        setState(() {
          _showControls = false;
          _showSideSliders = false;
        });
      });
    }
  }

  void _seekBy(int seconds) async {
    if (_isLive || _isDisposed) return;
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

  Widget _signalIndicatorSized(double size) {
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
        return Icon(icon, color: color, size: size);
      },
    );
  }

  Future<void> _restoreSystemOrientationOnce() async {
    if (_orientationRestored) return;
    _orientationRestored = true;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    if (_isTv) {
      await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    } else if (_isMobileOS) {
      await SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  Future<void> _popSmooth() async {
    if (_isVod) await _saveLastPositionVod();
    await _restoreSystemOrientationOnce();
    if (!mounted) return;
    Navigator.of(context).maybePop();
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

    if (_isVod) _saveLastPositionVod();

    _trackTimer?.cancel();
    _hideTimer?.cancel();
    _connSub?.cancel();
    _recoveryTimer?.cancel();
    _retryTimer?.cancel();
    _connectionCheckTimer?.cancel();
    _stallWatchTimer?.cancel();
    _playPauseFocus.dispose();

    try {
      _vlc.removeListener(_onVlcState);
      _vlc.stop();
    } catch (_) {}
    _vlc.dispose();

    _latencyNotifier.dispose();

    _restoreSystemOrientationOnce();
    _backButtonFocus.dispose();
    _leftPaneScroll.dispose();

    super.dispose();
  }

  // ===== util صغير لتفادي firstWhere مع orElse=null =====
  ChannelModel? _findCurrent(List<ChannelModel> all, int? id) {
    if (id == null) return null;
    for (final c in all) {
      if (c.streamId == id) return c;
    }
    return null;
  }

  // ========= قياسات وودجت مُعاد استخدامها لأشرطة السطوع/الصوت القصيرة =========
  static const double kSideSliderWidth = 12; // كان 20
  static const double kSideSliderHeight = 160; // ارتفاع ثابت (قصير)
  static const double kSideTrackHeight = 1.0; // أنحف
  static const double kSideThumbRadius = 3.5; // مقبض أصغر

  Widget _buildSideSlider({
    required Alignment alignment,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    double bgAlpha = 0.28,
  }) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 0).copyWith(
          left: alignment == Alignment.centerLeft ? 4 : 0,
          right: alignment == Alignment.centerRight ? 4 : 0,
        ),
        child: Container(
          width: kSideSliderWidth,
          height: kSideSliderHeight,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: bgAlpha),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 1.5, vertical: 4),
          child: RotatedBox(
            quarterTurns: -1,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: kSideTrackHeight,
                thumbShape: RoundSliderThumbShape(
                  enabledThumbRadius: kSideThumbRadius,
                ),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
              ),
              child: Slider(
                value: value,
                min: min,
                max: max,
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =================== Widgets ===================
  Widget _buildChannelInfoBar() {
    final name = _currentChannelName ?? widget.title;
    final cat = _currentCategoryName ?? 'غير محدد';
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.30),
        border: const Border(top: BorderSide(color: Color(0x22FFFFFF))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Text('LIVE',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 10)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                Text(cat,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 6),
          _signalIndicatorSized(14),
          const SizedBox(width: 8),
          if (_currentStreamId != null)
            Text('#$_currentStreamId',
                style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildPlayerStack(double ar) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleControls,
      child: LayoutBuilder(
        builder: (context, cons) {
          final w = cons.maxWidth;
          final childW = w;
          final childH = childW / ar;

          return Stack(
            children: [
              Positioned.fill(
                child: ClipRect(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: childW,
                      height: childH,
                      child: VlcPlayer(
                        controller: _vlc,
                        aspectRatio: ar,
                        placeholder:
                            const Center(child: CircularProgressIndicator()),
                      ),
                    ),
                  ),
                ),
              ),

              // سطوع
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: true,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    color: Colors.black.withValues(
                      alpha: ((1 - _brightness) * 0.6).clamp(0.0, 1.0),
                    ),
                  ),
                ),
              ),

              // مؤشر الشبكة
              if (_isLive)
                Positioned(
                  right: 40,
                  top: MediaQuery.of(context).padding.top + 6,
                  child: IgnorePointer(
                      ignoring: true, child: _signalIndicatorSized(14)),
                ),

              // تحميل VOD
              if (_isVod)
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: true,
                    child: ValueListenableBuilder<VlcPlayerValue>(
                      valueListenable: _vlc,
                      builder: (context, v, _) {
                        final isLoading = _showBlockingLoader ||
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

              // Top bar
              if (_showControls)
                Positioned(
                  left: 8,
                  right: 8,
                  top: 8,
                  child: SafeArea(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          focusNode: _backButtonFocus,
                          iconSize: 20,
                          icon:
                              const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () {
                            if (_isLive && _isFullscreen) {
                              setState(() => _isFullscreen = false);
                            } else {
                              _popSmooth();
                            }
                          },
                        ),
                        if (!_isLive)
                          IconButton(
                            padding: EdgeInsets.zero,
                            iconSize: 20,
                            icon: const Icon(Icons.screen_rotation,
                                color: Colors.white),
                            onPressed: () {
                              final isPortrait =
                                  MediaQuery.of(context).orientation ==
                                      Orientation.portrait;
                              SystemChrome.setPreferredOrientations(
                                isPortrait
                                    ? const [
                                        DeviceOrientation.landscapeLeft,
                                        DeviceOrientation.landscapeRight
                                      ]
                                    : const [
                                        DeviceOrientation.portraitUp,
                                        DeviceOrientation.portraitDown
                                      ],
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),

              // شريط تقدم/وقت
              if (_showControls)
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: _isVod
                      ? Column(
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 1.4,
                                thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 5),
                                overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 9),
                              ),
                              child: Slider(
                                value: _position.inSeconds.toDouble(),
                                max: (_duration.inSeconds > 0
                                        ? _duration.inSeconds
                                        : _position.inSeconds + 1)
                                    .toDouble(),
                                onChanged: _duration.inSeconds > 0
                                    ? (v) => _vlc
                                        .seekTo(Duration(seconds: v.toInt()))
                                    : null,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_formatTime(_position),
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 12)),
                                Text(
                                  _duration.inSeconds > 0
                                      ? _formatTime(_duration)
                                      : '--:--',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        )
                      : ValueListenableBuilder<VlcPlayerValue>(
                          valueListenable: _vlc,
                          builder: (context, v, _) {
                            final secs = v.position.inSeconds;
                            return Column(
                              children: [
                                IgnorePointer(
                                  ignoring: true,
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 1.4,
                                      thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 4.5),
                                    ),
                                    child: Slider(
                                      value: secs.toDouble(),
                                      max: (secs + 1).toDouble(),
                                      onChanged: (_) {},
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(_formatTime(v.position),
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 12)),
                                ),
                              ],
                            );
                          },
                        ),
                ),

              // أزرار تشغيل/إيقاف
              if (_showControls)
                Align(
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isVod)
                        IconButton(
                          iconSize: 28,
                          icon:
                              const Icon(Icons.replay_10, color: Colors.white),
                          onPressed: () => _seekBy(-10),
                        ),
                      const SizedBox(width: 12),
                      IconButton(
                        focusNode: _playPauseFocus,
                        iconSize: 40,
                        icon: Icon(
                          (_isVod ? _vodIsPlaying : _vlc.value.isPlaying)
                              ? Icons.pause_circle
                              : Icons.play_circle,
                          color: Colors.white,
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
                      const SizedBox(width: 12),
                      if (_isVod)
                        IconButton(
                          iconSize: 28,
                          icon:
                              const Icon(Icons.forward_10, color: Colors.white),
                          onPressed: () => _seekBy(10),
                        ),
                    ],
                  ),
                ),

              if (_isLive && _showControls)
                Positioned(
                  right: 8,
                  bottom: 54,
                  child: SafeArea(
                    minimum: const EdgeInsets.only(right: 6, bottom: 6),
                    child: IconButton(
                      iconSize: 20,
                      tooltip: _isFullscreen ? 'وضع مقسوم' : 'ملء الشاشة',
                      icon: Icon(
                          size: 40,
                          _isFullscreen
                              ? Icons.fullscreen_exit
                              : Icons.fullscreen,
                          color: Colors.white),
                      onPressed: () {
                        setState(() => _isFullscreen = !_isFullscreen);
                        Future.microtask(() {
                          if (!_isDisposed) _vlc.play();
                        });
                      },
                    ),
                  ),
                ),

              if (widget.logo != null)
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Opacity(
                      opacity: 0.6,
                      child: SizedBox(height: 32, child: widget.logo!)),
                ),

              if (_isLive && _hasError)
                const Center(
                  child: Text('انقطع الاتصال بالبث... تتم إعادة المحاولة',
                      style: TextStyle(color: Colors.redAccent, fontSize: 14)),
                ),

              // أشرطة سطوع/صوت (قصيرة وثابتة الارتفاع)
              if (_showSideSliders) ...[
                _buildSideSlider(
                  alignment: Alignment.centerLeft,
                  value: _brightness,
                  min: 0.2,
                  max: 1.0,
                  onChanged: (v) => setState(() => _brightness = v),
                  bgAlpha: 0.30,
                ),
                _buildSideSlider(
                  alignment: Alignment.centerRight,
                  value: _volume,
                  min: 0,
                  max: 100,
                  onChanged: (v) async {
                    setState(() => _volume = v);
                    try {
                      await _vlc.setVolume(v.toInt());
                    } catch (_) {}
                  },
                  bgAlpha: 0.18,
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildLeftChannelsPane() {
    return Consumer(
      builder: (context, ref, _) {
        final api = ref.watch(liveServiceProvider);

        final future = api.getLiveChannels(offset: 20).then((all) {
          final current = _findCurrent(all, _currentStreamId);
          _currentCategoryId = current?.categoryId ?? _currentCategoryId;
          _currentCategoryName = current?.categoryId ?? _currentCategoryName;
          _currentChannelName ??= current?.name;

          if (_currentCategoryId == null) return all.take(50).toList();
          return all.where((c) => c.categoryId == _currentCategoryId).toList();
        });

        return FutureBuilder<List<ChannelModel>>(
          future: future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final channels = snapshot.data!;
            if (channels.isEmpty) {
              return const Center(
                child: Text('لا توجد قنوات لهذا التصنيف',
                    style: TextStyle(color: Colors.white70)),
              );
            }

            return Column(
              children: [
                // رأس القائمة
                Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.30),
                    border: const Border(
                        bottom: BorderSide(color: Color(0x22FFFFFF))),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: _popSmooth,
                        tooltip: 'رجوع',
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _currentCategoryName ?? 'قنوات التصنيف',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // القائمة
                Expanded(
                  child: ScrollbarTheme(
                    data: ScrollbarThemeData(
                      thumbVisibility: WidgetStateProperty.all(true),
                      thickness: WidgetStateProperty.all(2.0), // أنحف
                      radius: const Radius.circular(8),
                      trackColor: WidgetStateProperty.all(Colors.transparent),
                      trackBorderColor:
                          WidgetStateProperty.all(Colors.transparent),
                      thumbColor: WidgetStateProperty.resolveWith(
                        (states) => Colors.white.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Scrollbar(
                      controller: _leftPaneScroll,
                      child: ListView.separated(
                        controller: _leftPaneScroll,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        itemCount: channels.length,
                        separatorBuilder: (_, __) => Divider(
                            color: Colors.white.withValues(alpha: 0.07),
                            height: 1),
                        itemBuilder: (context, i) {
                          final ch = channels[i];
                          final bool isActive = ch.streamId == _currentStreamId;
                          final bool isLoadingThis = _isSwitchingChannel &&
                              ch.streamId == _currentStreamId;

                          return ListTile(
                            dense: true,
                            visualDensity: const VisualDensity(
                                horizontal: -2, vertical: -2),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            title: Text(
                              ch.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isActive ? Colors.white : Colors.white70,
                                fontSize: 13,
                                fontWeight: isActive
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                            // ignore: unnecessary_null_comparison
                            subtitle: (ch.categoryId) != null
                                ? Text(
                                    (ch.categoryId),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: Colors.white54, fontSize: 11),
                                  )
                                : null,
                            trailing: isActive
                                ? (isLoadingThis
                                    ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2))
                                    : const Icon(Icons.play_arrow,
                                        color: Colors.white, size: 16))
                                : const Icon(Icons.tv,
                                    color: Colors.white54, size: 16),
                            onTap: () async {
                              if (isActive) return;
                              await _switchLiveChannel(ch);
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final ar = _lockedAspectRatio ?? (screen.width / screen.height);

    const double kPaneMin = 200.0;
    final double kPaneMax = (screen.width * 0.7).clamp(220.0, 520.0);
    const double kDivider = 4.0;

    final double leftW = _isLive && !_isFullscreen
        ? _leftPaneWidth.clamp(kPaneMin, kPaneMax)
        : 0.0;
    final double dividerW = _isLive && !_isFullscreen ? kDivider : 0.0;

    final rightPane = Column(
      children: [
        Expanded(child: _buildPlayerStack(ar)),
        if (_isLive && !_isFullscreen) _buildChannelInfoBar(),
      ],
    );

    final body = Focus(
      focusNode: _screenKbFocus,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;

        final key = event.logicalKey;
        final isOk = key == LogicalKeyboardKey.select ||
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
      child: SafeArea(
        top: false,
        bottom: false,
        child: Row(
          children: [
            // اللوحة اليسرى
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: leftW,
              child: leftW == 0
                  ? const SizedBox.shrink()
                  : Container(
                      color: const Color(0xFF0E0E10),
                      child: _buildLeftChannelsPane()),
            ),
            // الفاصل
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: dividerW,
              color: dividerW == 0
                  ? Colors.transparent
                  : const Color.fromARGB(255, 218, 14, 14)
                      .withValues(alpha: 0.06),
              child: dividerW == 0
                  ? null
                  : GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onHorizontalDragUpdate: (d) {
                        setState(() => _leftPaneWidth =
                            (_leftPaneWidth + d.delta.dx)
                                .clamp(kPaneMin, kPaneMax));
                      },
                    ),
            ),
            // اللوحة اليمنى
            Expanded(child: rightPane),
          ],
        ),
      ),
    );

    return PopScope(
      canPop: !(_isLive && _isFullscreen),
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) {
          if (_isLive && _isFullscreen) {
            setState(() => _isFullscreen = false);
          }
          return;
        }
        _restoreSystemOrientationOnce();
      },
      child: PlatformScaffold(
        material: (_, __) =>
            MaterialScaffoldData(backgroundColor: Colors.black),
        cupertino: (_, __) =>
            CupertinoPageScaffoldData(backgroundColor: Colors.black),
        body: body,
      ),
    );
  }
}
