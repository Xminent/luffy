import "dart:convert";

import "package:html/dom.dart";
import "package:html/parser.dart";
import "package:http/http.dart" as http;
import "package:http/http.dart";
import "package:luffy/api/anime.dart";
import "package:luffy/api/extractors/filemoon.dart";
import "package:luffy/api/extractors/mp4upload.dart";
import "package:luffy/util.dart";
import "package:tuple/tuple.dart";

const _baseUrl = "https://aniwave.to";

Future<String> _callConsumet(String query, String action) async {
  final res = await http.get(
    Uri.parse("https://9anime.eltik.net/$action?query=$query&apikey=enimax"),
  );

  switch (action) {
    case "rawVizCloud":
    case "rawMcloud":
      {
        final rawUrl = jsonDecode(res.body)["rawURL"];
        final referer = action == "rawVizCloud"
            ? "https://vidstream.pro/"
            : "https://mcloud.to/";

        final apiRes = await http.get(
          Uri.parse(rawUrl),
          headers: {
            "Referer": referer,
          },
        );

        return apiRes.body
            .substring(
              apiRes.body.indexOf('file":"') + 7,
              apiRes.body.indexOf('"', apiRes.body.indexOf('file":"') + 7),
            )
            .unescapedJson();
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

Future<List<Video>> extractVideoConsumet(
  Tuple3<String, String, String> server,
  String epUrl,
) async {
  final vrf = await _callConsumet(server.item2, "rawVrf");
  final referer = {"referer": epUrl};
  final response = await http.get(
    Uri.parse("$_baseUrl/ajax/server/${server.item2}?$vrf"),
    headers: referer,
  );

  if (response.statusCode != 200) {
    return [];
  }

  final videoList = <Video>[];

  try {
    final parsed = jsonDecode(response.body);
    final embedLink = await _callConsumet(parsed["result"]["url"], "decrypt");

    switch (server.item3) {
      case "vidstream":
      case "mycloud":
        final embedReferer = {
          "referer": "https://${Uri.parse(embedLink).host}/"
        };

        final vidId = Uri.parse(embedLink).pathSegments.last.split("?").first;
        final serverName =
            server.item3 == "vidstream" ? "Vidstream" : "MyCloud";
        final action =
            server.item3 == "vidstream" ? "rawVizcloud" : "rawMcloud";
        final playlistUrl =
            (await _callConsumet(vidId, action)).unescapedJson();

        final playlist = await http.get(
          Uri.parse(playlistUrl),
          headers: embedReferer,
        );

        videoList.addAll(
          parseVizPlaylist(
            playlist.body,
            playlist.request!.url,
            "$serverName - ${server.item1}",
            embedReferer,
          ),
        );
        break;
      case "filemoon":
        videoList.addAll(
          await FilemoonExtractor()
              .videosFromUrl(embedLink, "Filemoon - ${server.item1}"),
        );
        break;
      // case "streamtape":
      //   final video = await StreamTapeExtractor(client)
      //       .videoFromUrl(embedLink, "StreamTape - ${server.first}");
      //   if (video != null) {
      //     videoList.add(video);
      //   }
      //   break;
      case "mp4upload":
        videoList.addAll(
          await Mp4uploadExtractor()
              .videosFromUrl(embedLink, "Mp4upload - ${server.item1}"),
        );
        break;
      default:
        break;
    }
  } catch (_) {
    // Handle error or return empty list
  }
  return videoList;
}

class Video {
  Video(
    this.videoUrl,
    this.quality,
    this.url,
    this.headers,
  );

  final String videoUrl;
  final String quality;
  final String url;
  final Map<String, String> headers;
}

List<Video> parseVizPlaylist(
  String masterPlaylist,
  Uri masterUrl,
  String prefix,
  Map<String, String> embedReferer,
) {
  final playlistHeaders = Map<String, String>.from(embedReferer)
    ..addAll({
      "host": masterUrl.host,
      "connection": "keep-alive",
    });

  return masterPlaylist
      .substringAfter("#EXT-X-STREAM-INF:")
      .split("#EXT-X-STREAM-INF:")
      .map((it) {
    final quality =
        "$prefix ${it.substringAfter("RESOLUTION=").substringAfter("x").substringBefore("\n")}p";

    final videoUrl =
        "${masterUrl.toString().substringBeforeLast("/")}/${it.substringAfter("\n").substringBefore("\n").trim()}";
    return Video(videoUrl, quality, videoUrl, playlistHeaders);
  }).toList();
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
  Future<List<VideoSource>> getSources(Episode episode) async {
    final videos = await getVideoList(episode);

    if (videos.isEmpty) {
      return [];
    }

    return videos.map((video) {
      return VideoSource(
        videoUrl: video.videoUrl,
        description: video.quality,
      );
    }).toList();
  }

  Future<Response> getVideoUrlRes(Episode episode) async {
    // get substring from episode.url before the & character.
    final ids = episode.url.substring(0, episode.url.indexOf("&"));
    final vrf = await _callConsumet(ids, "vrf");
    final url = "/ajax/server/list/$ids?$vrf";
    final epurl = episode.url.substring(episode.url.indexOf("epurl=") + 6);

    return http.get(
      Uri.parse(_baseUrl + url),
      headers: {"url": epurl},
    );
  }

  Future<List<Video>> getVideoList(Episode episode) async {
    final ids = episode.url.substring(0, episode.url.indexOf("&"));
    final vrf = await _callConsumet(ids, "vrf");
    final url = "/ajax/server/list/$ids?$vrf";
    final epurl = episode.url.substring(episode.url.indexOf("epurl=") + 6);
    final res = await http.get(
      Uri.parse(_baseUrl + url),
      headers: {"url": epurl},
    );

    final servers = <Tuple3<String, String, String>>[];
    final json = jsonDecode(res.body);
    final document = parse(json["result"]);
    final idsList = ids.split(",");

    if (idsList.isNotEmpty) {
      final subId = idsList[0];
      final serverElements =
          document.querySelectorAll('li[data-ep-id="$subId"]');

      for (final serverElement in serverElements) {
        final server = serverElement.text.toLowerCase();
        final serverId = serverElement.attributes["data-link-id"] ?? "";
        servers.add(Tuple3("Sub", serverId, server));
      }
    }

    if (idsList.length > 1) {
      final dubId = idsList[1];
      final serverElements =
          document.querySelectorAll('li[data-ep-id="$dubId"]');

      for (final serverElement in serverElements) {
        final server = serverElement.text.toLowerCase();
        final serverId = serverElement.attributes["data-link-id"] ?? "";
        servers.add(Tuple3("Dub", serverId, server));
      }
    }

    final videos = <Video>[];

    for (final server in servers) {
      videos.addAll(await extractVideoConsumet(server, epurl));
    }

    return videos;
  }

  @override
  Future<List<Anime>> search(String query) {
    return searchAnime(query);
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
    final sub = element.attributes["data-sub"] == "1";
    final dub = element.attributes["data-dub"] == "1";
    final name = element.parent?.querySelector("span.d-title")?.text;
    final namePrefix = "Episode $episodeNum";

    return Episode(
      title: name != null && name.startsWith(namePrefix) ? name : namePrefix,
      thumbnailUrl: "",
      url: "$ids&epurl=$url/ep-$episodeNum",
    );
  }
}
