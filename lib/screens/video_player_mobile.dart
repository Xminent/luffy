import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_displaymode/flutter_displaymode.dart";
import "package:luffy/api/anime.dart";
import "package:luffy/api/history.dart";
import "package:luffy/components/video_player/controls.dart";
import "package:luffy/util.dart";
import "package:video_player/video_player.dart";
import "package:wakelock_plus/wakelock_plus.dart";

class VideoPlayerScreenMobile extends StatefulWidget {
  const VideoPlayerScreenMobile({
    super.key,
    required this.showId,
    required this.showTitle,
    required this.episode,
    required this.episodeNum,
    required this.sourceName,
    this.savedProgress,
    this.imageUrl,
    required this.episodes,
    required this.sourceFetcher,
    this.animeId,
    required this.showUrl,
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
  final int? animeId;
  final String showUrl;

  @override
  State<VideoPlayerScreenMobile> createState() =>
      _VideoPlayerScreenMobileState();
}

class _VideoPlayerScreenMobileState extends State<VideoPlayerScreenMobile> {
  VideoPlayerController? _controller;
  BoxFit _fit = BoxFit.contain;
  bool _isBuffering = true;
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

  void _onVideoControllerUpdate() {
    final controller = _controller;

    if (!mounted || controller == null) {
      return;
    }

    if (controller.value.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            controller.value.errorDescription ?? "Unknown error",
          ),
        ),
      );

      Navigator.pop(context);
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
  }

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
    final oldController = _controller;
    final oldPosition = oldController?.value.position;

    if (oldPosition == null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await oldController?.dispose();

      prints("VideoPlayer source changed to ${source.description}");

      _controller = VideoPlayerController.networkUrl(
        Uri.parse(source.videoUrl),
      );

      _controller?.addListener(_onVideoControllerUpdate);

      _controller?.initialize().then((_) {
        setState(() {
          _positionBeforeSourceChange = oldPosition;
          _hasResumedFromSourceChange = false;
        });

        _controller?.play();
      });
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
      "VideoPlayer episode changed to ${widget.episodes[episodeNum].title}",
    );

    _currentEpisodeNum = episodeNum;
    _isRequestInProgress = true;

    setState(() {
      _positionBeforeSourceChange = Duration.zero;
      _isBuffering = true;
    });

    // Really long network request.
    widget
        .sourceFetcher(
      widget.episodes[episodeNum],
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

      final oldController = _controller;

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await oldController?.dispose();

        _controller = VideoPlayerController.networkUrl(
          Uri.parse(sources.first.videoUrl),
        );

        _controller?.addListener(_onVideoControllerUpdate);

        _controller?.initialize().then((_) {
          setState(() {});
          _controller?.play();
        });
      });
    });
  }

  void _syncProgress(VideoPlayerController controller) {
    final pos = controller.value.position.inMilliseconds;
    final dur = controller.value.duration.inMilliseconds;
    final progress = (pos / dur).clamp(0.0, 1.0);

    if (!progress.isFinite || pos == 0) {
      return;
    }

    prints("Watched enough of the video to save progress.");

    final currentEpisode = widget.episodes[_currentEpisodeNum];

    HistoryService.addProgress(
      HistoryEntry(
        id: widget.showId,
        animeId: widget.animeId,
        title: widget.showTitle,
        imageUrl: currentEpisode.thumbnailUrl ?? widget.imageUrl,
        progress: {},
        totalEpisodes: widget.episodes.length,
        sources: {
          _currentEpisodeNum: _sources ?? [],
        },
        subtitles: {
          widget.episodeNum: _subtitles?.whereType<Subtitle>().toList() ?? [],
        },
        sourceExpiration: DateTime.now().add(const Duration(hours: 1)),
        showUrl: widget.showUrl,
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

    WakelockPlus.enable();

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      FlutterDisplayMode.setLowRefreshRate();
    }

    Future.microtask(() async {
      // Look up the history and see if the sources' lastSourceUpdated is within 1 hour.
      final history = await HistoryService.getMedia(widget.showId);

      final sources = await (() async {
        if (history != null &&
            history.sources.containsKey(widget.episodeNum) &&
            history.sources[widget.episodeNum]!.isNotEmpty &&
            history.sourceExpiration.isAfter(DateTime.now())) {
          prints(
            "Using cached sources for ${widget.showTitle} episode ${widget.episodeNum}",
          );
          return history.sources[widget.episodeNum];
        }

        return widget.sourceFetcher(widget.episodes[_currentEpisodeNum]);
      })();

      // Sometimes it can take too long to fetch the sources and the user has already left the screen.
      if (!mounted) {
        return;
      }

      if (sources == null) {
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

        return Navigator.pop(context);
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

      prints("VideoPlayer source changed to ${sources.first.videoUrl}");

      _controller = VideoPlayerController.networkUrl(
        Uri.parse(
          sources.first.videoUrl,
        ),
      );

      _controller?.addListener(_onVideoControllerUpdate);

      _controller?.initialize().then((_) {
        setState(() {});
        _controller?.play();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final isInitialized =
        (controller?.value.isInitialized ?? false) && controller != null;
    final buffered = controller?.value.buffered ?? [];

    return PopScope(
      canPop: controller == null,
      onPopInvoked: (didPop) async {
        final controller = _controller;

        if (!didPop || controller == null) {
          return;
        }

        // Pop it manually.
        final progress = controller.value.position.inMilliseconds /
            controller.value.duration.inMilliseconds;

        Navigator.pop(context, progress.isFinite ? progress : null);
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
                  episodeTitle:
                      widget.episodes[_currentEpisodeNum].title ?? "Untitled",
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
    if (_controller != null) {
      _syncProgress(_controller!);
    }

    _controller?.dispose();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    WakelockPlus.disable();

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      FlutterDisplayMode.setHighRefreshRate();
    }

    super.dispose();
  }
}
