import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MoviePlayerScreen extends StatefulWidget {
  final String url;
  final String title;

  const MoviePlayerScreen({super.key, required this.url, required this.title});

  @override
  State<MoviePlayerScreen> createState() => _MoviePlayerScreenState();
}

class _MoviePlayerScreenState extends State<MoviePlayerScreen> {
  late final VlcPlayerController _vlcController;
  bool _isPlaying = true;
  bool _showControls = false;
  Duration _position = Duration.zero;
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
        http: VlcHttpOptions([':http-user-agent=Mozilla/5.0']),
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
      final pos = await _vlcController.getPosition();
      final dur = await _vlcController.getDuration();
      if (_isDisposed) return;
      setState(() {
        _position = pos;
        _duration = dur;
      });
    });
  }

  Future<void> _restoreLastPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt('movie_resume_${widget.url}') ?? 0;
    if (saved > 0) {
      await Future.delayed(const Duration(seconds: 2));
      if (_isDisposed) return;
      await _vlcController.seekTo(Duration(seconds: saved));
    }
  }

  Future<void> _saveLastPosition() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('movie_resume_${widget.url}', _position.inSeconds);
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
        if (mounted && !_isDisposed) {
          setState(() => _showControls = false);
        }
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
                        child: Column(
                          children: [
                            Slider(
                              value: _position.inSeconds.toDouble(),
                              max: (_duration.inSeconds + 1).toDouble(),
                              onChanged: (value) {
                                _vlcController.seekTo(
                                  Duration(seconds: value.toInt()),
                                );
                              },
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  formatTime(_position),
                                  style: const TextStyle(color: Colors.white),
                                ),
                                Text(
                                  formatTime(_duration),
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
    );
  }
}
