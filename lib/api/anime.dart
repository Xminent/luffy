import "package:luffy/util/subtitle.dart";

class Anime {
  Anime({
    required this.title,
    required this.imageUrl,
    required this.url,
  });

  final String title;
  final String imageUrl;
  final String url;
}

class Episode {
  Episode({
    required this.title,
    required this.url,
    required this.thumbnailUrl,
    this.rating,
    this.synopsis,
  });

  final String? title;
  final String url;
  final String? thumbnailUrl;
  final int? rating;
  final String? synopsis;
}

class Subtitle {
  const Subtitle({
    required this.text,
    required this.format,
  });

  final String text;
  final SubtitleFormat format;
}

class VideoSource {
  const VideoSource({
    required this.videoUrl,
    this.subtitle,
  });

  final String videoUrl;
  final Subtitle? subtitle;
}

abstract class AnimeExtractor {
  /// Returns the source name.
  /// Example: "GogoAnime"
  String get name;

  /// Search for anime by [query].
  /// Returns a list of [Anime].
  Future<List<Anime>> search(String query);

  /// Get a list of [Episode] for the given [anime].
  /// Returns a list of [Episode].
  Future<List<Episode>> getEpisodes(Anime anime);

  /// Get the video url for the given [episode].
  /// Returns a [Tuple2<String, Subtitle?] of the video url and its subtitle if available or null if not found.
  Future<VideoSource?> getVideoUrl(Episode episode);
}
