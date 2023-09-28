import "package:flutter/material.dart";
import "package:luffy/api/anime.dart";
import "package:luffy/screens/video_player_mpv.dart";

class VideoPlayerScreen extends StatelessWidget {
  const VideoPlayerScreen({
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
  Widget build(BuildContext context) {
    // if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
    //   return VideoPlayerScreenMpv(
    //     showId: showId,
    //     showTitle: showTitle,
    //     episode: episode,
    //     episodeNum: episodeNum,
    //     sourceName: sourceName,
    //     savedProgress: savedProgress,
    //     imageUrl: imageUrl,
    //     episodes: episodes,
    //     sourceFetcher: sourceFetcher,
    //     animeId: animeId,
    //     showUrl: showUrl,
    //   );
    // }

    return VideoPlayerScreenMpv(
      showId: showId,
      showTitle: showTitle,
      episode: episode,
      episodeNum: episodeNum,
      sourceName: sourceName,
      savedProgress: savedProgress,
      imageUrl: imageUrl,
      episodes: episodes,
      sourceFetcher: sourceFetcher,
      animeId: animeId,
      showUrl: showUrl,
    );
  }
}
