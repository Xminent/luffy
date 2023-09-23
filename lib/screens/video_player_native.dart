import "package:flutter/material.dart";
import "package:flutter/scheduler.dart";
import "package:flutter/services.dart";
import "package:luffy/api/anime.dart";
import "package:luffy/api/history.dart";
import "package:luffy/components/video_player/controls.dart";
import "package:luffy/util.dart";
import "package:video_player/video_player.dart";

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({
    super.key,
    required this.showId,
    required this.showTitle,
    required this.episode,
    required this.episodeNum,
    required this.sourceName,
    this.savedProgress,
    required this.imageUrl,
    required this.episodes,
    required this.sourceFetcher,
  });

  final String showId;
  final String showTitle;
  final Episode episode;
  final int episodeNum;
  final String sourceName;
  final double? savedProgress;
  final String? imageUrl;
  final List<Episode> episodes;
  final Future<List<VideoSource>> Function(Episode) sourceFetcher;

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with TickerProviderStateMixin {
  VideoPlayerController? _controller;
  BoxFit _fit = BoxFit.contain;
  bool _isBuffering = true;
  Ticker? _ticker;
  final int _secondsOnScreen = 0;
  bool _hasResumed = false;
  VideoSource? _currentSource;
  List<VideoSource>? _sources;
  Subtitle? _currentSubtitle;
  List<Subtitle?>? _subtitles;
  double? _subtitleOffset;
  Duration _positionBeforeSourceChange = Duration.zero;
  bool _hasResumedFromSourceChange = true;
  late int _currentEpisodeNum = widget.episodeNum;
  bool _isRequestInProgress = false;

  void _onRewind() {
    final controller = _controller;

    if (controller == null) {
      return;
    }

    controller.seekTo(
      Duration(
        milliseconds: (controller.value.position.inMilliseconds - 10000).clamp(
          0,
          controller.value.duration.inMilliseconds,
        ),
      ),
    );
  }

  void _onPlayPause() {
    final controller = _controller;

    if (controller == null) {
      return;
    }

    controller.value.isPlaying ? controller.pause() : controller.play();
  }

  void _onFastForward() {
    final controller = _controller;

    if (controller == null) {
      return;
    }

    controller.seekTo(
      Duration(
        milliseconds: (controller.value.position.inMilliseconds + 10000).clamp(
          0,
          controller.value.duration.inMilliseconds,
        ),
      ),
    );
  }

  void _onProgressChanged(Duration position) {
    _controller?.seekTo(position);
  }

  void _onFitChanged(BoxFit fit) {
    setState(() {
      _fit = fit;
    });
  }

  void _onSpeedChanged(double speed) {
    _controller?.setPlaybackSpeed(speed);
  }

  void _onSubtitleOffsetChanged(double subtitleOffset) {
    setState(() {
      _subtitleOffset = subtitleOffset;
    });
  }

  void _onSourceChanged(VideoSource source) {
    final oldPosition = _controller?.value.position;

    if (oldPosition == null) {
      return;
    }

    prints("VideoPlayer source changed to ${source.description}");
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(source.videoUrl),
    );

    setState(() {
      _positionBeforeSourceChange = oldPosition;
      _hasResumedFromSourceChange = false;
    });
  }

  void _onSubtitleChanged(Subtitle? subtitle) {
    setState(() {
      _currentSubtitle = subtitle;

      if (subtitle != null) {
        _subtitleOffset = 0.0;
      }
    });
  }

  void _onEpisodeNumChanged(int episodeNum) {
    if (!mounted || _isRequestInProgress) {
      return;
    }

    prints(
      "VideoPlayer episode changed to ${widget.episodes[episodeNum - 1].title}",
    );

    _currentEpisodeNum = episodeNum;
    _isRequestInProgress = true;

    setState(() {
      _positionBeforeSourceChange = Duration.zero;
      _hasResumedFromSourceChange = false;
      _isBuffering = true;
    });

    _controller?.dispose();

    // Really long network request.
    widget
        .sourceFetcher(
      widget.episodes[episodeNum - 1],
    )
        .then((sources) {
      if (!mounted) {
        return;
      }

      if (sources.isEmpty) {
        prints(
          "No sources found for ${widget.showTitle} episode $episodeNum",
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "No sources found for ${widget.showTitle} episode $episodeNum",
            ),
          ),
        );

        Navigator.pop(context);

        return;
      }

      setState(() {
        _currentSource = sources.first;
        _currentSubtitle = sources.first.subtitle;

        if (_currentSubtitle != null) {
          _subtitleOffset = 0.0;
        }

        _sources = sources;
        _subtitles = sources.map((source) => source.subtitle).toList();
        _isRequestInProgress = false;
      });

      _controller = VideoPlayerController.networkUrl(
        Uri.parse(sources.first.videoUrl),
      );
    });
  }

  void _syncProgress() {
    final controller = _controller;

    if (controller == null) {
      return;
    }

    final progress = (controller.value.position.inMilliseconds /
            controller.value.duration.inMilliseconds)
        .clamp(0.0, 1.0);

    // We will only update if you have watched at least 5% of the video.
    // final minSecondsOnScreen = 0.05 * _duration.inSeconds;
    const minSecondsOnScreen = 0;

    if (!progress.isFinite ||
        progress == 0 ||
        _secondsOnScreen <= minSecondsOnScreen) {
      return;
    }

    prints("Watched enough of the video to save progress.");

    final currentEpisode = widget.episodes[_currentEpisodeNum - 1];

    HistoryService.addProgress(
      HistoryEntry(
        id: widget.showId,
        title: widget.showTitle,
        imageUrl: currentEpisode.thumbnailUrl ?? "",
        progress: {},
        totalEpisodes: widget.episodes.length,
        sources: {
          _currentEpisodeNum: _sources ?? [],
        },
        subtitles: {
          widget.episodeNum: _subtitles?.whereType<Subtitle>().toList() ?? [],
        },
        sourceExpiration: DateTime.now().add(const Duration(hours: 1)),
      ),
      _currentEpisodeNum,
      progress,
    );

    prints(
      "Saved video progress for episode $_currentEpisodeNum | Progress: $progress",
    );
  }

  @override
  void initState() {
    super.initState();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    Future.microtask(() async {
      // Look up the history and see if the sources' lastSourceUpdated is within 1 hour.
      final history = await HistoryService.getMedia(widget.showId);

      final sources = await (() async {
        if (history != null &&
            history.sources.containsKey(widget.episodeNum) &&
            history.sources[widget.episodeNum]!.isNotEmpty &&
            history.sourceExpiration.isAfter(DateTime.now())) {
          // TODO: Remove debug (remove history).
          await HistoryService.removeMedia(history);
          prints(
            "Using cached sources for ${widget.showTitle} episode ${widget.episodeNum}",
          );
          return history.sources[widget.episodeNum]!;
        }

        return widget.sourceFetcher(widget.episodes[_currentEpisodeNum - 1]);
      })();

      // Sometimes it can take too long to fetch the sources and the user has already left the screen.
      if (!mounted) {
        return;
      }

      if (sources.isEmpty) {
        prints(
          "No sources found for ${widget.showTitle} episode ${widget.episodeNum}",
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "No sources found for ${widget.showTitle} episode ${widget.episodeNum}",
            ),
          ),
        );

        Navigator.pop(context);

        return;
      }

      setState(() {
        _currentEpisodeNum = widget.episodeNum;
        _currentSource = sources.first;
        _currentSubtitle = sources.first.subtitle;

        if (_currentSubtitle != null) {
          _subtitleOffset = 0.0;
        }

        _sources = sources;
        _subtitles = sources.map((source) => source.subtitle).toList();
      });

      // _player.stream.playing.listen((event) {
      //   if (!mounted) {
      //     return;
      //   }

      //   setState(() {
      //     // Start counting the user's time on screen.

      //     if (_ticker == null) {
      //       _ticker = createTicker((elapsed) {
      //         setState(() {
      //           _secondsOnScreen = elapsed.inSeconds;
      //         });
      //       });

      //       _ticker?.start();
      //     }

      //     _isPlaying = event;
      //   });
      // });

      prints("VideoPlayer source changed to ${sources.first.videoUrl}");

      _controller = VideoPlayerController.networkUrl(
        Uri.parse(
          sources.first.videoUrl,
        ),
      );

      _controller?.addListener(() {
        final controller = _controller;

        if (!mounted || controller == null) {
          return;
        }

        setState(() {
          _isBuffering = controller.value.isBuffering;

          final savedProgress = widget.savedProgress;

          if (!_isBuffering &&
              !_hasResumed &&
              controller.value.duration != Duration.zero &&
              savedProgress != null) {
            prints("Seeking to $savedProgress");

            controller.seekTo(
              Duration(
                milliseconds:
                    (controller.value.duration.inMilliseconds * savedProgress)
                        .toInt(),
              ),
            );

            setState(() {
              _hasResumed = true;
            });
          }

          if (!_isBuffering &&
              !_hasResumedFromSourceChange &&
              controller.value.duration != Duration.zero) {
            prints("Seeking to $_positionBeforeSourceChange");
            controller.seekTo(
              _positionBeforeSourceChange,
            );

            setState(() {
              _hasResumedFromSourceChange = true;
            });
          }
        });
      });

      _controller?.initialize().then((_) => setState(() {}));
      _controller?.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final isInitialized =
        (controller?.value.isInitialized ?? false) && controller != null;
    final buffered = controller?.value.buffered ?? [];

    return WillPopScope(
      onWillPop: () async {
        prints("VideoPlayerScreen: onWillPop");

        final controller = _controller;

        if (controller == null) {
          return true;
        }

        // Pop it manually.
        final progress = controller.value.position.inMilliseconds /
            controller.value.duration.inMilliseconds;

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
                      width: controller?.value.size.width,
                      height: controller?.value.size.height,
                      child: isInitialized
                          ? VideoPlayer(
                              controller,
                            )
                          : Container(),
                    ),
                  ),
                ),
                ControlsOverlay(
                  isBuffering: _isBuffering,
                  isPlaying: controller?.value.isPlaying ?? false,
                  duration: controller?.value.duration ?? Duration.zero,
                  position: controller?.value.position ?? Duration.zero,
                  buffered:
                      buffered.isNotEmpty ? buffered.first.end : Duration.zero,
                  size: controller?.value.size ?? Size.zero,
                  showTitle: widget.showTitle,
                  episodeTitle: widget.episodes[_currentEpisodeNum - 1].title ??
                      "Untitled",
                  episodeNum: _currentEpisodeNum,
                  sourceName: widget.sourceName,
                  fit: _fit,
                  speed: controller?.value.playbackSpeed ?? 1.0,
                  subtitleOffset: _subtitleOffset,
                  subtitle: _currentSubtitle,
                  subtitles: _subtitles,
                  onProgressChanged: _onProgressChanged,
                  onRewind: _onRewind,
                  onPlayPause: _onPlayPause,
                  onFastForward: _onFastForward,
                  onFitChanged: _onFitChanged,
                  onSpeedChanged: _onSpeedChanged,
                  episodes: widget.episodes,
                  source: _currentSource,
                  sources: _sources,
                  onSourceChanged: _onSourceChanged,
                  onSubtitleChanged: _onSubtitleChanged,
                  onSubtitleOffsetChanged: _onSubtitleOffsetChanged,
                  onEpisodeNumChanged: _onEpisodeNumChanged,
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
    _syncProgress();
    _controller?.dispose();
    _ticker?.dispose();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    super.dispose();
  }
}
