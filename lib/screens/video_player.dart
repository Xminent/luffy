import "package:flutter/material.dart";
import "package:flutter/scheduler.dart";
import "package:flutter/services.dart";
import "package:flutter_secure_storage/flutter_secure_storage.dart";
import "package:luffy/api/anime.dart";
import "package:luffy/components/video_controls.dart";
import "package:luffy/util.dart";
import "package:media_kit/media_kit.dart";
import "package:media_kit_video/media_kit_video.dart";
import "package:wakelock/wakelock.dart";

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({
    super.key,
    required this.showId,
    required this.showTitle,
    required this.episode,
    required this.episodeTitle,
    required this.url,
    required this.sourceName,
    this.subtitle,
    this.savedProgress,
  });

  final int showId;
  final String showTitle;
  final int episode;
  final String episodeTitle;
  final String url;
  final String sourceName;
  final Subtitle? subtitle;
  final double? savedProgress;

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with TickerProviderStateMixin {
  final Player _player = Player();
  VideoController? _controller;
  BoxFit _fit = BoxFit.contain;
  bool _isBuffering = true;
  bool _isPlaying = false;
  Duration _buffered = Duration.zero;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _speed = 1.0;
  Ticker? _ticker;
  int _secondsOnScreen = 0;
  bool _hasResumed = false;

  void _onRewind() {
    _player.seek(
      Duration(
        milliseconds: (_position.inMilliseconds - 10000).clamp(
          0,
          _duration.inMilliseconds,
        ),
      ),
    );
  }

  void _onPlayPause() {
    _isPlaying ? _player.pause() : _player.play();
  }

  void _onFastForward() {
    _player.seek(
      Duration(
        milliseconds: (_position.inMilliseconds + 10000).clamp(
          0,
          _duration.inMilliseconds,
        ),
      ),
    );
  }

  void _onProgressChanged(Duration position) {
    _player.seek(position);
  }

  void _onFitChanged(BoxFit fit) {
    setState(() {
      _fit = fit;
    });
  }

  void _onSpeedChanged(double speed) {
    _player.setRate(speed);
  }

  @override
  void initState() {
    super.initState();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    Wakelock.enable();

    Future.microtask(() async {
      _controller = await VideoController.create(
        _player,
      );

      _player.streams.buffering.listen((event) {
        setState(() {
          _isBuffering = event;

          final savedProgress = widget.savedProgress;

          if (!event &&
              !_hasResumed &&
              _duration != Duration.zero &&
              savedProgress != null) {
            prints("Seeking to $savedProgress");
            _player.seek(
              Duration(
                milliseconds:
                    (_duration.inMilliseconds * savedProgress).toInt(),
              ),
            );

            setState(() {
              _hasResumed = true;
            });
          }
        });
      });

      _player.streams.buffer.listen((event) {
        setState(() {
          _buffered = event;
        });
      });

      _player.streams.duration.listen((event) {
        setState(() {
          _duration = event;
        });
      });

      _player.streams.playing.listen((event) {
        setState(() {
          // Start counting the user's time on screen.

          if (_ticker == null) {
            _ticker = createTicker((elapsed) {
              setState(() {
                _secondsOnScreen = elapsed.inSeconds;
              });
            });

            _ticker?.start();
          }

          _isPlaying = event;
        });
      });

      _player.streams.position.listen((event) {
        setState(() {
          _position = event;
        });
      });

      _player.streams.rate.listen((event) {
        setState(() {
          _speed = event;
        });
      });

      await _player.open(
        Media(
          widget.url,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        prints("VideoPlayerScreen: onWillPop");

        // Pop it manually.
        final progress = _position.inMilliseconds / _duration.inMilliseconds;

        Navigator.pop(context, progress.isFinite ? progress : null);

        return false;
      },
      child: SafeArea(
        child: Scaffold(
          body: Container(
            color: Colors.black,
            child: Stack(
              children: [
                SizedBox.expand(
                  child: FittedBox(
                    fit: _fit,
                    child: SizedBox(
                      width: _controller?.rect.value?.width ??
                          MediaQuery.of(context).size.width,
                      height: _controller?.rect.value?.height ??
                          MediaQuery.of(context).size.height,
                      child: Video(
                        controller: _controller,
                      ),
                    ),
                  ),
                ),
                ControlsOverlay(
                  isBuffering: _isBuffering,
                  isPlaying: _isPlaying,
                  duration: _duration,
                  position: _position,
                  buffered: _buffered,
                  size: _controller?.rect.value?.size ?? Size.zero,
                  showTitle: widget.showTitle,
                  episodeTitle: widget.episodeTitle,
                  episode: widget.episode,
                  sourceName: widget.sourceName,
                  fit: _fit,
                  speed: _speed,
                  subtitle: widget.subtitle,
                  onProgressChanged: _onProgressChanged,
                  onRewind: _onRewind,
                  onPlayPause: _onPlayPause,
                  onFastForward: _onFastForward,
                  onFitChanged: _onFitChanged,
                  onSpeedChanged: _onSpeedChanged,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    final progress =
        (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0);

    // We will only update if you have watched at least 5% of the video.
    final minSecondsOnScreen = 0.05 * _duration.inSeconds;

    if (progress.isFinite &&
        progress > 0 &&
        _secondsOnScreen <= minSecondsOnScreen) {
      prints("Watched enough of the video to save progress.");

      // Store our video progress in storage.
      const storage = FlutterSecureStorage();

      storage.write(
        key: "anime_${widget.showId}_episode_${widget.episode}",
        value: progress.toString(),
      );

      prints(
        "Saved video progress for episode ${widget.episode} | Progress: $progress",
      );
    }

    _controller?.dispose();
    _player.dispose();
    _ticker?.dispose();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    Wakelock.disable();

    super.dispose();
  }
}
