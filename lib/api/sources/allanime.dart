import "dart:convert";

import "package:http/http.dart" as http;
import "package:luffy/api/anime.dart";
import "package:luffy/util.dart";

const _baseUrl = "https://allanime.ai";
const _apiUrl = "https://api.allanime.day/api";

class AllAnime {
  Future<List<Anime>> search(String query) async {
    final params = {
      "variables": {
        "search": {
          "allowAdult": false,
          "query": query,
        },
        "translationType": "sub",
      },
      // "extensions": {
      //   "persistedQuery": {
      //     "version": 1,
      //     "sha256Hash":
      //         "06327bc10dd682e1ee7e07b6db9c16e9ad2fd56c1b769e47513128cd5c9fc77a"
      //   }
      // }
    };

    final ret = <Anime>[];

    try {
      final res = await http.get(Uri.https(_apiUrl, "/api", params));

      final data = jsonDecode(res.body);

      for (final item in data["data"]?["shows"]?["edges"] ?? []) {
        ret.add(
          Anime(
            title: item["name"],
            url: item["_id"],
            imageUrl: item["thumbnail"],
          ),
        );
      }
    } catch (e) {
      prints("Failed to search anime: $e");
    }

    return ret;
  }
}
