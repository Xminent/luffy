// import "package:better_player/better_player.dart";
// import "package:flutter/foundation.dart";
// import "package:flutter/material.dart";
// import "package:flutter/services.dart";
// import "package:flutter_displaymode/flutter_displaymode.dart";
// import "package:luffy/api/anime.dart";
// import "package:luffy/api/history.dart";
// import "package:luffy/components/video_player/controls.dart";
// import "package:luffy/util.dart";

// class VideoPlayerScreenMobileBetter extends StatefulWidget {
//   const VideoPlayerScreenMobileBetter({
//     super.key,
//     required this.showId,
//     required this.showTitle,
//     required this.episode,
//     required this.episodeNum,
//     required this.sourceName,
//     this.savedProgress,
//     this.imageUrl,
//     required this.episodes,
//     required this.sourceFetcher,
//     this.animeId,
//     required this.showUrl,
//   });

//   final String showId;
//   final String showTitle;
//   final Episode episode;
//   final int episodeNum;
//   final String sourceName;
//   final double? savedProgress;
//   final String? imageUrl;
//   final List<Episode> episodes;
//   final Future<List<VideoSource>> Function(Episode) sourceFetcher;
//   final int? animeId;
//   final String showUrl;

//   @override
//   State<VideoPlayerScreenMobileBetter> createState() =>
//       _VideoPlayerScreenMobileBetterState();
// }

// class _VideoPlayerScreenMobileBetterState
//     extends State<VideoPlayerScreenMobileBetter> {
//   BetterPlayerController? _betterPlayerController;
//   BoxFit _fit = BoxFit.contain;
//   bool _isBuffering = true;
//   final bool _hasResumed = false;
//   VideoSource? _currentSource;
//   List<VideoSource>? _sources;
//   Subtitle? _currentSubtitle;
//   List<Subtitle?>? _subtitles;
//   double? _subtitleOffset;
//   Duration _positionBeforeSourceChange = Duration.zero;
//   bool _hasResumedFromSourceChange = true;
//   late int _currentEpisodeNum = widget.episodeNum;
//   bool _isRequestInProgress = false;

//   void _onRewind() {
//     final controller = _betterPlayerController?.videoPlayerController;
//     final pos = controller?.value.position.inMilliseconds;
//     final dur = controller?.value.duration?.inMilliseconds;

//     if (pos == null || dur == null) {
//       return;
//     }

//     controller?.seekTo(
//       Duration(
//         milliseconds: (pos - 10000).clamp(
//           0,
//           dur,
//         ),
//       ),
//     );
//   }

//   void _onPlayPause() {
//     final controller = _betterPlayerController?.videoPlayerController;

//     (controller?.value.isPlaying ?? false)
//         ? controller?.pause()
//         : controller?.play();
//   }

//   void _onFastForward() {
//     final controller = _betterPlayerController?.videoPlayerController;
//     final pos = controller?.value.position.inMilliseconds;
//     final dur = controller?.value.duration?.inMilliseconds;

//     if (pos == null || dur == null) {
//       return;
//     }

//     controller?.seekTo(
//       Duration(
//         milliseconds: (pos + 10000).clamp(
//           0,
//           dur,
//         ),
//       ),
//     );
//   }

//   void _onProgressChanged(Duration position) {
//     _betterPlayerController?.videoPlayerController?.seekTo(position);
//   }

//   void _onFitChanged(BoxFit fit) {
//     setState(() {
//       _fit = fit;
//     });
//   }

//   void _onSpeedChanged(double speed) {
//     _betterPlayerController?.videoPlayerController?.setSpeed(speed);
//   }

//   void _onSubtitleOffsetChanged(double subtitleOffset) {
//     setState(() {
//       _subtitleOffset = subtitleOffset;
//     });
//   }

//   Future<void> _onSourceChanged(VideoSource source) async {
//     final oldPosition =
//         _betterPlayerController?.videoPlayerController?.value.position;

//     if (oldPosition == null) {
//       return;
//     }

//     await _betterPlayerController?.videoPlayerController?.setNetworkDataSource(
//       source.videoUrl,
//     );

//     setState(() {
//       _positionBeforeSourceChange = oldPosition;
//       _hasResumedFromSourceChange = false;
//     });
//   }

//   void _onSubtitleChanged(Subtitle? subtitle) {
//     setState(() {
//       _currentSubtitle = subtitle;

//       if (subtitle != null) {
//         _subtitleOffset = 0.0;
//       }
//     });
//   }

//   void _onEpisodeNumChanged(int episodeNum) {
//     if (!mounted || _isRequestInProgress) {
//       return;
//     }

//     prints(
//       "VideoPlayer episode changed to ${widget.episodes[episodeNum].title}",
//     );

//     _currentEpisodeNum = episodeNum;
//     _isRequestInProgress = true;

//     setState(() {
//       _positionBeforeSourceChange = Duration.zero;
//       _isBuffering = true;
//     });

//     // Really long network request.
//     widget
//         .sourceFetcher(
//       widget.episodes[episodeNum],
//     )
//         .then((sources) {
//       if (!mounted) {
//         return;
//       }

//       if (sources.isEmpty) {
//         prints(
//           "No sources found for ${widget.showTitle} episode $episodeNum",
//         );

//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               "No sources found for ${widget.showTitle} episode $episodeNum",
//             ),
//           ),
//         );

//         Navigator.pop(context);

//         return;
//       }

//       setState(() {
//         _currentSource = sources.first;
//         _currentSubtitle = sources.first.subtitle;

//         if (_currentSubtitle != null) {
//           _subtitleOffset = 0.0;
//         }

//         _sources = sources;
//         _subtitles = sources.map((source) => source.subtitle).toList();
//         _isRequestInProgress = false;
//       });

//       _betterPlayerController?.videoPlayerController
//           ?.setNetworkDataSource(sources.first.videoUrl);
//     });
//   }

//   void _syncProgress(BetterPlayerController controller) {
//     final pos = controller.videoPlayerController?.value.position.inMilliseconds;
//     final dur =
//         controller.videoPlayerController?.value.duration?.inMilliseconds;

//     if (pos == null || dur == null) {
//       return;
//     }

//     final progress = (pos / dur).clamp(0.0, 1.0);

//     if (!progress.isFinite || pos == 0) {
//       return;
//     }

//     prints("Watched enough of the video to save progress.");

//     final currentEpisode = widget.episodes[_currentEpisodeNum];

//     HistoryService.addProgress(
//       HistoryEntry(
//         id: widget.showId,
//         animeId: widget.animeId,
//         title: widget.showTitle,
//         imageUrl: currentEpisode.thumbnailUrl ?? "",
//         progress: {},
//         totalEpisodes: widget.episodes.length,
//         sources: {
//           _currentEpisodeNum: _sources ?? [],
//         },
//         subtitles: {
//           widget.episodeNum: _subtitles?.whereType<Subtitle>().toList() ?? [],
//         },
//         sourceExpiration: DateTime.now().add(const Duration(hours: 1)),
//         showUrl: widget.showUrl,
//       ),
//       _currentEpisodeNum,
//       progress,
//     );

//     prints(
//       "Saved video progress for episode $_currentEpisodeNum | Progress: $progress",
//     );
//   }

//   @override
//   void initState() {
//     super.initState();

//     SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

//     SystemChrome.setPreferredOrientations([
//       DeviceOrientation.landscapeLeft,
//       DeviceOrientation.landscapeRight,
//     ]);

//     if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
//       FlutterDisplayMode.setLowRefreshRate();
//     }

//     Future.microtask(() async {
//       // Look up the history and see if the sources' lastSourceUpdated is within 1 hour.
//       final history = await HistoryService.getMedia(widget.showId);

//       final sources = await (() async {
//         if (history != null &&
//             history.sources.containsKey(widget.episodeNum) &&
//             history.sources[widget.episodeNum]!.isNotEmpty &&
//             history.sourceExpiration.isAfter(DateTime.now())) {
//           prints(
//             "Using cached sources for ${widget.showTitle} episode ${widget.episodeNum}",
//           );
//           return history.sources[widget.episodeNum];
//         }

//         return widget.sourceFetcher(widget.episodes[_currentEpisodeNum]);
//       })();

//       // Sometimes it can take too long to fetch the sources and the user has already left the screen.
//       if (!mounted) {
//         return;
//       }

//       if (sources == null) {
//         prints(
//           "No sources found for ${widget.showTitle} episode ${widget.episodeNum}",
//         );

//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               "No sources found for ${widget.showTitle} episode ${widget.episodeNum}",
//             ),
//           ),
//         );

//         return Navigator.pop(context);
//       }

//       if (sources.isEmpty) {
//         prints(
//           "No sources found for ${widget.showTitle} episode ${widget.episodeNum}",
//         );

//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               "No sources found for ${widget.showTitle} episode ${widget.episodeNum}",
//             ),
//           ),
//         );

//         Navigator.pop(context);

//         return;
//       }

//       setState(() {
//         _currentEpisodeNum = widget.episodeNum;
//         _currentSource = sources.first;
//         _currentSubtitle = sources.first.subtitle;

//         if (_currentSubtitle != null) {
//           _subtitleOffset = 0.0;
//         }

//         _sources = sources;
//         _subtitles = sources.map((source) => source.subtitle).toList();
//       });

//       prints("VideoPlayer source changed to ${sources.first.videoUrl}");

//       final BetterPlayerConfiguration betterPlayerConfiguration =
//           BetterPlayerConfiguration(
//         aspectRatio: 16 / 9,
//         fit: _fit,
//       );

//       final BetterPlayerDataSource dataSource = BetterPlayerDataSource(
//         BetterPlayerDataSourceType.network,
//         sources.first.videoUrl,
//         videoFormat: BetterPlayerVideoFormat.hls,
//       );

//       _betterPlayerController =
//           BetterPlayerController(betterPlayerConfiguration);
//       _betterPlayerController!.setupDataSource(dataSource);
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final controller = _betterPlayerController;
//     final isInitialized = controller != null;
//     final buffered = controller?.videoPlayerController?.value.buffered ?? [];
//     final pos = controller?.videoPlayerController?.value.position;
//     final dur = controller?.videoPlayerController?.value.duration;

//     return WillPopScope(
//       onWillPop: () async {
//         if (controller == null || pos == null || dur == null) {
//           return true;
//         }

//         // Pop it manually.
//         final progress =
//             (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0);

//         Navigator.pop(context, progress.isFinite ? progress : null);

//         return false;
//       },
//       child: SafeArea(
//         child: Scaffold(
//           body: Container(
//             color: Colors.black,
//             child: Stack(
//               children: [
//                 AspectRatio(
//                   aspectRatio: 16 / 9,
//                   child: isInitialized
//                       ? BetterPlayer(controller: controller)
//                       : Container(),
//                 ),
//                 ControlsOverlay(
//                   isBuffering: _isBuffering,
//                   isPlaying:
//                       controller?.videoPlayerController?.value.isPlaying ??
//                           false,
//                   duration: dur ?? Duration.zero,
//                   position: pos ?? Duration.zero,
//                   buffered:
//                       buffered.isNotEmpty ? buffered.first.end : Duration.zero,
//                   size: controller?.videoPlayerController?.value.size ??
//                       Size.zero,
//                   showTitle: widget.showTitle,
//                   episodeTitle:
//                       widget.episodes[_currentEpisodeNum].title ?? "Untitled",
//                   episodeNum: _currentEpisodeNum,
//                   sourceName: widget.sourceName,
//                   fit: _fit,
//                   speed: controller?.videoPlayerController?.value.speed ?? 1.0,
//                   subtitleOffset: _subtitleOffset,
//                   subtitle: _currentSubtitle,
//                   subtitles: _subtitles,
//                   onProgressChanged: _onProgressChanged,
//                   onRewind: _onRewind,
//                   onPlayPause: _onPlayPause,
//                   onFastForward: _onFastForward,
//                   onFitChanged: _onFitChanged,
//                   onSpeedChanged: _onSpeedChanged,
//                   episodes: widget.episodes,
//                   source: _currentSource,
//                   sources: _sources,
//                   onSourceChanged: _onSourceChanged,
//                   onSubtitleChanged: _onSubtitleChanged,
//                   onSubtitleOffsetChanged: _onSubtitleOffsetChanged,
//                   onEpisodeNumChanged: _onEpisodeNumChanged,
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     if (_betterPlayerController != null) {
//       _syncProgress(_betterPlayerController!);
//     }

//     SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

//     SystemChrome.setPreferredOrientations([
//       DeviceOrientation.portraitUp,
//       DeviceOrientation.landscapeLeft,
//       DeviceOrientation.landscapeRight,
//     ]);

//     if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
//       FlutterDisplayMode.setHighRefreshRate();
//     }

//     super.dispose();
//   }
// }
