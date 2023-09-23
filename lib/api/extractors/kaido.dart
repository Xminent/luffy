import "dart:convert";

import "package:html/parser.dart";
import "package:http/http.dart" as http;

const _baseUrl = "https://kaido.to";
final _headers = {"X-Requested-With": "XMLHttpRequest", "referer": _baseUrl};

class Kaido {
  static Future<Map<String, dynamic>> search(String query) async {
    /* sanitize the query like this:
    var url = URLEncoder.encode(query, "utf-8")
        if (query.startsWith("$!")) {
            val a = query.replace("$!", "").split(" | ")
            url = URLEncoder.encode(a[0], "utf-8") + a[1]
        }
    */

    query = Uri.encodeComponent(query);

    final url = Uri.parse("$_baseUrl/search?keyword=$query");
    final res = await http.get(url);
    final document = parse(res.body);

    /* perform the equivalent of this:
    return document.select(".film_list-wrap > .flw-item > .film-poster").map {
            val link = it.select("a").attr("data-id")
            val title = it.select("a").attr("title")
            val cover = it.select("img").attr("data-src")
            ShowResponse(title, link, FileUrl(cover))
        }
    */

    final items = document
        .querySelectorAll(".film_list-wrap > .flw-item > .film-poster")
        .map((e) {
      return {
        "title": e.querySelector("a")?.attributes["title"],
        "link": e.querySelector("a")?.attributes["data-id"],
        "cover": e.querySelector("img")?.attributes["data-src"],
      };
    });

    return {"items": items};
  }

  static Future<Map<String, dynamic>> loadEpisodes(
    String animeLink,
    Map<String, dynamic> extra,
  ) async {
    final res = await http.get(
      Uri.parse("$_baseUrl/ajax/episode/list/$animeLink"),
      headers: _headers,
    );

    final document = parse(jsonDecode(res.body)["html"]);
    final items = document.querySelectorAll(".detail-infor-content > div > a");

    return {
      "items": items.map((e) {
        return {
          "title": e.attributes["title"],
          "link": e.attributes["data-id"],
          "number": e.attributes["data-number"],
          "filler": e.attributes["class"]?.contains("ssl-item-filler") ?? false,
        };
      })
    };
  }
}
