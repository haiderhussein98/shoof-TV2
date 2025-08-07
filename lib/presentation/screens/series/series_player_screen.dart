import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SeriesPlayerScreen extends StatefulWidget {
  final String url;
  final String title;

  const SeriesPlayerScreen({super.key, required this.url, required this.title});

  @override
  State<SeriesPlayerScreen> createState() => _SeriesPlayerScreenState();
}

class _SeriesPlayerScreenState extends State<SeriesPlayerScreen> {
  late VlcPlayerController _vlcController;
  final ValueNotifier<Duration> _positionNotifier = ValueNotifier(
    Duration.zero,
  );
  bool _isPlaying = true;
  bool _showControls = true;
  Duration _duration = const Duration(minutes: 1);
  Timer? _timer;
  Timer? _hideTimer;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();

    _vlcController = VlcPlayerController.network(
      widget.url,
      hwAcc: HwAcc.full,
      autoPlay: true,
      options: VlcPlayerOptions(
        advanced: VlcAdvancedOptions([VlcAdvancedOptions.networkCaching(1000)]),
        http: VlcHttpOptions([':http-user-agent=VLC/3.0.16 LibVLC/3.0.16']),
      ),
    );

    _vlcController.addListener(_updateState);
    _startTracking();
    _restoreLastPosition();
  }

  void _updateState() {
    if (_isDisposed) return;
    final state = _vlcController.value;
    if (mounted) {
      setState(() => _isPlaying = state.isPlaying);
    }
  }

  void _startTracking() {
    _timer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (_isDisposed) return;
      try {
        final pos = await _vlcController.getPosition();
        final dur = await _vlcController.getDuration();
        if (_isDisposed) return;
        _positionNotifier.value = pos;
        _duration = dur;
      } catch (_) {}
    });
  }

  Future<void> _restoreLastPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt('series_resume_${widget.url}') ?? 0;
      if (saved > 0 && !_isDisposed) {
        await Future.delayed(const Duration(seconds: 2));
        if (_isDisposed) return;
        await _vlcController.seekTo(Duration(seconds: saved));
      }
    } catch (_) {}
  }

  Future<void> _saveLastPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        'series_resume_${widget.url}',
        _positionNotifier.value.inSeconds,
      );
    } catch (_) {}
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
      final newDuration = current + Duration(seconds: seconds);
      await _vlcController.seekTo(newDuration);
    } catch (_) {}
  }

  String formatTime(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final m = twoDigits(d.inMinutes.remainder(60));
    final s = twoDigits(d.inSeconds.remainder(60));
    return '${d.inHours > 0 ? '${twoDigits(d.inHours)}:' : ''}$m:$s';
  }

  @override
  @override
  void dispose() {
    _isDisposed = true;
    _saveLastPosition();
    _timer?.cancel();
    _hideTimer?.cancel();
    _positionNotifier.dispose();
    _vlcController.removeListener(_updateState);

    try {
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggleControls,
        child: Stack(
          children: [
            Positioned.fill(
              child: VlcPlayer(
                controller: _vlcController,
                aspectRatio: 16 / 9,
                placeholder: const Center(child: CircularProgressIndicator()),
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
                            onPressed: () => Navigator.pop(context),
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
                        child: ValueListenableBuilder<Duration>(
                          valueListenable: _positionNotifier,
                          builder: (context, position, _) {
                            return Column(
                              children: [
                                Slider(
                                  value: position.inSeconds.toDouble(),
                                  max: (_duration.inSeconds + 1).toDouble(),
                                  onChanged: (value) {
                                    _vlcController.seekTo(
                                      Duration(seconds: value.toInt()),
                                    );
                                  },
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      formatTime(position),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      formatTime(_duration),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
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
    );
  }
}
