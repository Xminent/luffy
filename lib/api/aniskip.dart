import "dart:convert";

import "package:http/http.dart" as http;
import "package:luffy/util.dart";

const _baseUrl = "https://api.aniskip.com/v1";

SkipType _skipTypeFromStr(String str) {
  switch (str.toLowerCase()) {
    case "op":
      return SkipType.opening;
    case "ed":
      return SkipType.ending;
    case "mixed-op":
      return SkipType.mixedOpening;
    case "mixed-ed":
      return SkipType.mixedEnding;
    case "recap":
      return SkipType.recap;
    default:
      throw ArgumentError("Invalid skip type: $str");
  }
}

class Skip {
  Skip.fromJson(Map<String, dynamic> json)
      : interval = Interval.fromJson(json["interval"]),
        type = _skipTypeFromStr(json["skip_type"]),
        id = json["skip_id"],
        episodeLength = json["episode_length"];

  final Interval interval;
  final SkipType type;
  final String id;
  final int episodeLength;
}

enum SkipType {
  opening,
  ending,
  mixedOpening,
  mixedEnding,
  recap,
}

class Interval {
  Interval.fromJson(Map<String, dynamic> json)
      : start = json["start_time"].toDouble(),
        end = json["end_time"].toDouble();

  final double start;
  final double end;
}

class AniSkip {
  static Future<List<Skip>> getSkips(int animeId, int episodeNum) async {
    final ret = <Skip>[];

    try {
      final res = await http.get(
        Uri.parse(
          "$_baseUrl/skip-times/$animeId/$episodeNum?types[]=op",
        ),
      );

      final data = jsonDecode(res.body);

      for (final item in data["results"]) {
        ret.add(
          Skip.fromJson(item),
        );
      }
    } catch (e) {
      prints("Failed to get skips: $e");
    }

    return ret;
  }
}
