import "dart:convert";

import "package:html/dom.dart";
import "package:html/parser.dart";
import "package:http/http.dart" as http;
import "package:http/http.dart";
import "package:luffy/api/anime.dart";

const _baseUrl = "https://9anime.to";

Future<String> _callConsumet(String query, String action) async {
  final res = await http.get(
    Uri.parse("https://9anime.eltik.net/$action?query=$query&apikey=aniyomi"),
  );

  switch (action) {
    case "rawVizCloud":
    case "rawMcloud":
      {
        final rawUrl = jsonDecode(res.body)["rawUrl"];
        final referer = action == "rawVizCloud"
            ? "https://vidstream.pro/"
            : "https://mcloud.to/";

        final apiRes = await http.get(
          Uri.parse(rawUrl),
          headers: {
            "Referer": referer,
          },
        );

        return apiRes.body.substring(
          apiRes.body.indexOf('file":"') + 7,
          apiRes.body.indexOf('"', apiRes.body.indexOf('file":"') + 7),
        );
      }

    case "decrypt":
      return jsonDecode(res.body)["url"];

    default:
      {
        final json = jsonDecode(res.body);
        return "${json["vrfQuery"]}=${Uri.encodeComponent(json["url"])}";
      }
  }
}

class NineAnimeExtractor extends AnimeExtractor implements AnimeParser {
  @override
  String get name => "9anime";

  @override
  String get searchAnimeSelector => "div.ani.items > div.item";

  @override
  String get episodeSelector => "div.episodes ul > li > a";

  Future<List<Anime>> searchAnime(String query) async {
    final vrf = await (query.isNotEmpty
        ? _callConsumet(query, "vrf")
        : Future.value(""));
    final url = "$_baseUrl/filter?keyword=$query&sort=most_relevance&vrf=$vrf";

    return http.get(
      Uri.parse(url),
      headers: {
        "Referer": _baseUrl,
      },
    ).then((res) {
      return searchAnimeParse(this, res.body);
    });
  }

  // @override
  Future<Response> getEpisodesRes(Anime anime) async {
    final document = await http
        .get(Uri.parse(_baseUrl + anime.url))
        .then((res) => parse(res.body));
    final id =
        document.querySelector("div[data-id]")?.attributes["data-id"] ?? "";
    final vrf = await _callConsumet(id, "vrf");

    return http.get(
      Uri.parse(
        "$_baseUrl/ajax/episode/list/$id?$vrf",
      ),
      headers: {"url": anime.url},
    );
  }

  @override
  Future<List<Episode>> getEpisodes(Anime anime) async {
    final res = await getEpisodesRes(anime);
    final json = jsonDecode(res.body);
    final document = parse(json["result"]);
    final elements = document.querySelectorAll(episodeSelector);
    final results = <Episode>[];

    for (final element in elements) {
      results.add(episodeFromElement(element, anime.url));
    }

    return results;
  }

  @override
  Future<VideoSource?> getVideoUrl(Episode episode) async {
    // get substring from episode.url before the & character.
    final ids = episode.url.substring(0, episode.url.indexOf("&"));
    final vrf = await _callConsumet(ids, "vrf");
    final url = "/ajax/server/list/$ids?$vrf";
    final epurl = episode.url.substring(episode.url.indexOf("epurl=") + 6);

    // return http.get(Uri.parse(_baseUrl + url), headers: {
    //   url: epurl
    // });

    return null;
  }

  @override
  Future<List<Anime>> search(String query) {
    // TODO: implement search
    throw UnimplementedError();
  }

  @override
  Anime searchAnimeFromElement(Element element) {
    final aTag = element.querySelector("a.name");
    final title = aTag?.text ?? "";
    final thumbnail =
        element.querySelector("div.poster img")?.attributes["src"];
    final url = aTag?.attributes["href"] ?? "";

    return Anime(
      title: title,
      imageUrl: thumbnail ?? "",
      url: url,
    );
  }

  @override
  Episode episodeFromElement(Element element, String url) {
    final episodeNum = element.attributes["data-num"] ?? "";
    final ids = element.attributes["data-ids"] ?? "";
    final sub = element.attributes["data-sub"] ?? "";
    final dub = element.attributes["data-dub"] ?? "";
    final name = element.parent?.querySelector("span.d-title")?.text;
    final namePrefix = "Episode $episodeNum";

    return Episode(
      title: name != null && name.startsWith(namePrefix)
          ? name
          : "$namePrefix - $name",
      thumbnailUrl: "",
      url: "$ids&epurl=$url/ep-$episodeNum",
    );
  }
}
