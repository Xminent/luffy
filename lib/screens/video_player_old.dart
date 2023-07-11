import "package:flutter/material.dart";
import "package:flutter/scheduler.dart";
import "package:flutter/services.dart";
import "package:flutter_secure_storage/flutter_secure_storage.dart";
import "package:flutter_vlc_player/flutter_vlc_player.dart";
import "package:luffy/api/anime.dart";
import "package:luffy/components/video_controls.dart";
import "package:luffy/util.dart";

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
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  late final VlcPlayerController _controller;
  BoxFit _fit = BoxFit.contain;
  final double _speed = 1.0;
  Ticker? _ticker;
  int _secondsOnScreen = 0;
  bool _isBuffering = true;

  void _onRewind() {
    _controller.seekTo(
      _controller.value.position - const Duration(seconds: 10),
    );
  }

  void _onPlayPause() {
    _controller.value.isPlaying ? _controller.pause() : _controller.play();
  }

  void _onFastForward() {
    _controller
        .seekTo(_controller.value.position + const Duration(seconds: 10));
  }

  void _onProgressChanged(Duration position) {
    _controller.seekTo(position);
  }

  void _onFitChanged(BoxFit fit) {
    setState(() {
      _fit = fit;
    });
  }

  void _onSpeedChanged(double speed) {
    _controller.setPlaybackSpeed(speed);
  }

  @override
  void initState() {
    super.initState();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    prints("Playing ${widget.url}");

    _controller = VlcPlayerController.network(
      widget.url,
    );

    _controller.addOnInitListener(() {
      _controller.addListener(() {
        setState(() {
          if (_controller.value.size != Size.zero) {
            _isBuffering = _controller.value.isBuffering;
          }
        });
      });

      final savedProgress = widget.savedProgress;

      if (savedProgress != null) {
        _controller.seekTo(
          Duration(
            milliseconds:
                (_controller.value.duration.inMilliseconds * savedProgress)
                    .toInt(),
          ),
        );
      }

      setState(() {
        _controller.play();
        _controller = _controller;
      });
    });

    if (_ticker == null) {
      _ticker = createTicker((elapsed) {
        setState(() {
          _secondsOnScreen = elapsed.inSeconds;
        });
      });

      _ticker?.start();
    }

    _controller.initialize();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return WillPopScope(
      onWillPop: () async {
        prints("VideoPlayerScreen: onWillPop");

        // Pop it manually.

        final progress = _controller.value.position.inMilliseconds /
            _controller.value.duration.inMilliseconds;

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
                      width: _controller.value.aspectRatio,
                      height: 1,
                      child: VlcPlayer(
                        controller: _controller,
                        aspectRatio: 16 / 9,
                      ),
                    ),
                  ),
                ),
                ControlsOverlay(
                  isBuffering: _isBuffering,
                  isPlaying: _controller.value.isPlaying,
                  duration: _controller.value.duration,
                  position: _controller.value.position,
                  buffered: Duration.zero,
                  size: _controller.value.size,
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
  Future<void> dispose() async {
    final progress = (_controller.value.position.inMilliseconds /
            _controller.value.duration.inMilliseconds)
        .clamp(0.0, 1.0);

    // We will only update if you have watched at least 5% of the video.
    final minSecondsOnScreen = 0.05 * _controller.value.duration.inSeconds;

    if (progress.isFinite &&
        progress > 0 &&
        _secondsOnScreen <= minSecondsOnScreen) {
      prints("Watched enough of the video to save progress.");

      // Store our video progress in storage.
      const storage = FlutterSecureStorage();

      await storage.write(
        key: "anime_${widget.showId}_episode_${widget.episode}",
        value: progress.toString(),
      );

      prints(
        "Saved video progress for episode ${widget.episode} | Progress: $progress",
      );
    }

    await _controller.stopRendererScanning();
    await _controller.dispose();

    _ticker?.dispose();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;
}
