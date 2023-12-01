import "package:html/dom.dart";
import "package:html/parser.dart";
import "package:luffy/api/sources/animeflix.dart";
import "package:luffy/api/sources/animepahe.dart";
import "package:luffy/api/sources/gogoanime.dart";
import "package:luffy/api/sources/nineanime.dart";
import "package:luffy/api/sources/superstream.dart";
import "package:luffy/util/subtitle.dart";

class Anime {
  Anime({
    required this.title,
    this.imageUrl,
    required this.url,
  });

  final String title;
  final String? imageUrl;
  final String url;
}

class Episode {
  Episode({
    this.title,
    required this.url,
    this.thumbnailUrl,
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
  Subtitle.fromJson(Map<String, dynamic> json)
      : text = json["text"],
        format = SubtitleFormat.values.firstWhere(
          (e) => e.toString() == json["format"],
        );

  final String text;
  final SubtitleFormat format;

  Map<String, dynamic> toJson() {
    return {
      "text": text,
      "format": format.toString(),
    };
  }
}

class VideoSource {
  const VideoSource({
    required this.videoUrl,
    required this.description,
    this.subtitle,
  });

  VideoSource.fromJson(Map<String, dynamic> json)
      : videoUrl = json["videoUrl"],
        description = json["description"],
        subtitle = json["subtitle"] != null
            ? Subtitle.fromJson(json["subtitle"])
            : null;

  final String videoUrl;
  final String description;
  final Subtitle? subtitle;

  Map<String, dynamic> toJson() {
    return {
      "videoUrl": videoUrl,
      "description": description,
      "subtitle": subtitle?.toJson(),
    };
  }
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
  Future<List<VideoSource>> getSources(Episode episode);
}

abstract class AnimeParser {
  /// Returns a selector for use in parsing the search results page.
  /// Example: "div.ani.items > div.item"
  String get searchAnimeSelector;

  /// Returns a function which converts a [Element] to a [Anime].
  /// Returns a [Anime].
  Anime searchAnimeFromElement(Element element);

  String get episodeSelector;

  Episode episodeFromElement(Element element, String url);
}

List<Anime> searchAnimeParse(AnimeParser parser, String response) {
  return parse(response)
      .querySelectorAll(parser.searchAnimeSelector)
      .map(parser.searchAnimeFromElement)
      .toList();
}

// List<Episode> episodeListParse(AnimeParser parser, String response) {
//   return parse(response)
//       .querySelectorAll(parser.episodeSelector)
//       .map(parser.episodeFromElement)
//       .toList();
// }

final sources = [
  AnimeFlixExtractor(),
  AnimePaheExtractor(),
  GogoAnimeExtractor(),
  SuperStreamExtractor(),
  NineAnimeExtractor(),
];
