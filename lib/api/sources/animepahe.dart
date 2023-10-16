import "dart:convert";
import "dart:io";

import "package:cookie_jar/cookie_jar.dart";
import "package:html/parser.dart";
import "package:http/http.dart" as http;
import "package:luffy/api/anime.dart";
import "package:luffy/js_unpacker.dart";
import "package:luffy/util.dart";

const _mainUrl = "https://animepahe.ru";
final _cookieJar = CookieJar();
final _headers = {"referer": "$_mainUrl/"};

Future<bool> _generateSession() async {
  final uri = Uri.parse(_mainUrl);
  var cookies = await _cookieJar.loadForRequest(uri);

  if (cookies.isNotEmpty) {
    return true;
  }

  try {
    final httpClient = HttpClient();

    final req = await httpClient.openUrl(
      "GET",
      uri,
    );

    req.cookies.addAll(cookies);

    final res = await req.close();

    await _cookieJar.saveFromResponse(
      uri,
      res.cookies,
    );

    cookies = await _cookieJar.loadForRequest(uri);

    return cookies.isNotEmpty;
  } catch (e) {
    return false;
  }
}

final RegExp _ytsm = RegExp(r"ysmm = '([^']+)");
final RegExp _kwikParamsRe = RegExp(r'\("(\w+)",\d+,"(\w+)",(\d+),(\d+),\d+\)');
final RegExp _kwikDUrl = RegExp(r'action=\"([^"]+)"');
final RegExp _kwikDToken = RegExp('value="([^"]+)"');
final RegExp _youtubeVideoLink = RegExp(
  r"(^(?:https?:)?(?://)?(?:www\.)?(?:youtu\.be/|youtube(?:-nocookie)?\.(?:[A-Za-z]{2,4}|[A-Za-z]{2,3}\.[A-Za-z]{2})/)(?:watch|embed/|vi?/)*(?:\?[\w=&]*vi?=)?[^#&?/]{11}.*${'$'})",
);

class AnimePaheSearchData {
  AnimePaheSearchData.fromJson(Map<String, dynamic> json)
      : id = json["id"],
        slug = json["slug"],
        title = json["title"],
        type = json["type"],
        episodes = json["episodes"],
        status = json["status"],
        season = json["season"],
        year = json["year"],
        score = json["score"],
        poster = json["poster"],
        session = json["session"],
        relevance = json["relevance"];

  final int? id;
  final String? slug;
  final String title;
  final String? type;
  final int? episodes;
  final String? status;
  final String? season;
  final int? year;
  final double? score;
  final String? poster;
  final String session;
  final String? relevance;
}

class AnimePaheSearch {
  AnimePaheSearch.fromJson(Map<String, dynamic> json)
      : total = json["total"],
        data = List<AnimePaheSearchData>.from(
          json["data"].map((x) => AnimePaheSearchData.fromJson(x)),
        );

  final int total;
  final List<AnimePaheSearchData> data;
}

class LoadData {
  LoadData({
    required this.session,
    required this.sessionDate,
    required this.name,
  });

  LoadData.fromJson(Map<String, dynamic> json)
      : session = json["session"],
        sessionDate = json["session_date"],
        name = json["name"];

  final String session;
  final int sessionDate;
  final String name;

  Map<String, dynamic> toJson() => {
        "session": session,
        "session_date": sessionDate,
        "name": name,
      };
}

class SearchResponse {}

class AnimeData {
  AnimeData.fromJson(Map<String, dynamic> json)
      : id = json["id"] as int,
        animeId = json["anime_id"] as int,
        episode = json["episode"] as int,
        title = json["title"] as String,
        snapshot = json["snapshot"] as String,
        session = json["session"] as String,
        filler = json["filler"] as int,
        createdAt = json["created_at"] as String;

  final int id;
  final int animeId;
  final int episode;
  final String title;
  final String snapshot;
  final String session;
  final int filler;
  final String createdAt;
}

class AnimePaheAnimeData {
  AnimePaheAnimeData.fromJson(Map<String, dynamic> json)
      : total = json["total"] as int,
        perPage = json["per_page"] as int,
        currentPage = json["current_page"] as int,
        lastPage = json["last_page"] as int,
        nextPageUrl = json["next_page_url"] as String?,
        prevPageUrl = json["prev_page_url"] as String?,
        from = json["from"] as int,
        to = json["to"] as int,
        data = (json["data"] as List<dynamic>)
            .map((e) => AnimeData.fromJson(e))
            .toList();

  final int total;
  final int perPage;
  final int currentPage;
  final int lastPage;
  final String? nextPageUrl;
  final String? prevPageUrl;
  final int from;
  final int to;
  final List<AnimeData> data;
}

class LinkLoadData {
  LinkLoadData({
    required this.mainUrl,
    required this.isPlayPage,
    required this.episodeNum,
    required this.page,
    required this.session,
    required this.episodeSession,
  });

  LinkLoadData.fromJson(Map<String, dynamic> json)
      : mainUrl = json["mainUrl"] as String,
        isPlayPage = json["is_play_page"] as bool,
        episodeNum = json["episode_num"] as int,
        page = json["page"] as int,
        session = json["session"] as String,
        episodeSession = json["episode_session"] as String;

  final String mainUrl;
  final bool isPlayPage;
  final int episodeNum;
  final int page;
  final String session;
  final String episodeSession;

  Future<String?> getUrl() async {
    if (isPlayPage) {
      return "$mainUrl/play/$session/$episodeSession";
    }

    final url =
        "$mainUrl/api?m=release&id=$session&sort=episode_asc&page=$page";
    final res = await http.get(Uri.parse(url));

    if (res.statusCode != 200) {
      return null;
    }

    final data = jsonDecode(res.body);
    final episode =
        data["data"].firstWhere((e) => e["episode"] == episodeNum)["session"];

    return "$mainUrl/play/$session/$episode";
  }

  Map<String, dynamic> toJson() {
    return {
      "mainUrl": mainUrl,
      "is_play_page": isPlayPage,
      "episode_num": episodeNum,
      "page": page,
      "session": session,
      "episode_session": episodeSession,
    };
  }
}

Future<List<Episode>> generateListOfEpisodes(String session) async {
  try {
    final res = await http.get(
      Uri.parse(
        "$_mainUrl/api?m=release&id=$session&sort=episode_asc&page=1",
      ),
      headers: _headers,
    );

    final data = AnimePaheAnimeData.fromJson(jsonDecode(res.body));

    final lastPage = data.lastPage;
    final perPage = data.perPage;
    final total = data.total;
    var ep = 1;
    final episodes = <Episode>[];

    if (lastPage == 1 && perPage > total) {
      for (final it in data.data) {
        episodes.add(
          Episode(
            title: it.title.isEmpty ? "Episode ${it.episode}" : it.title,
            url: jsonEncode(
              LinkLoadData(
                mainUrl: _mainUrl,
                isPlayPage: true,
                episodeNum: 0,
                page: 0,
                session: session,
                episodeSession: it.session,
              ).toJson(),
            ),
            thumbnailUrl: it.snapshot,
          ),
        );
      }

      return episodes;
    }

    for (int page = 0; page < lastPage; page++) {
      for (int i = 0; i < perPage; i++) {
        if (ep > total) {
          break;
        }

        episodes.add(
          Episode(
            title: "",
            url: jsonEncode(
              LinkLoadData(
                mainUrl: _mainUrl,
                isPlayPage: false,
                episodeNum: ep,
                page: page + 1,
                session: session,
                episodeSession: "",
              ).toJson(),
            ),
            thumbnailUrl: "",
          ),
        );

        ep++;
      }
    }

    return episodes;
  } catch (e) {
    return [];
  }
}

// Future<String?> _getStreamUrlFromKwik(String? url) async {
//   if (url == null) {
//     return null;
//   }

//   try {
//     final req = await HttpClient().openUrl(
//       "GET",
//       Uri.parse(url),
//     );

//     req.cookies.addAll(await _cookieJar.loadForRequest(Uri.parse(_mainUrl)));
//     req.headers.add("Connection", "keep-alive");
//     req.headers.add("referer", "$_mainUrl/");

//     final res = await req.close();
//     final body = await res.transform(utf8.decoder).join();
//     final unpacked = JsUnpacker.unpackAndComb(body);

//     for (final it in unpacked) {
//       final match = RegExp(r"source=\'(.*?)\'").firstMatch(it ?? "")?.group(1);

//       if (match != null) {
//         return match;
//       }
//     }

//     return null;
//   } catch (e) {
//     prints("Failed to get stream url from kwik $e");
//     return null;
//   }
// }

Future<String?> _getHlsStreamUrl(Uri kwikUrl, String referer) async {
  try {
    final res = await http.get(
      kwikUrl,
      headers: {
        "referer": referer,
      },
    );
    final document = parse(res.body);
    final script = document
        .querySelectorAll("script")
        .where((e) => e.text.contains("eval"))
        .first
        .text
        .substringAfter("eval(function(");
    final unpacked = JsUnpacker.unpackAndCombine("eval(function($script");
    final ret =
        unpacked?.substringAfter(r"const source=\'").substringBefore(r"\';");

    return ret;
  } catch (e) {
    prints("Failed to get stream url from kwik $e");
  }
  return null;
}

class AnimePahe {
  static Future<List<Anime>> search(String query) async {
    try {
      final res = await http.get(
        Uri.parse("$_mainUrl/api?m=search&l=8&q=$query"),
        headers: _headers,
      );

      final data = AnimePaheSearch.fromJson(jsonDecode(res.body));

      return data.data
          .map(
            (e) => Anime(
              title: e.title,
              imageUrl: e.poster ?? "",
              url: jsonEncode(
                LoadData(
                  session: e.session,
                  sessionDate: unixTime,
                  name: e.title,
                ).toJson(),
              ),
            ),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<List<Episode>> load(Anime anime) async {
    final session = await (() async {
      final data = LoadData.fromJson(jsonDecode(anime.url));

      if (data.sessionDate + 60 * 10 < unixTime) {
        return _generateSession().then((value) {
          if (value) {
            return data.session;
          }
        });
      }

      return data.session;
    })();

    if (session == null) {
      return [];
    }

    try {
      final res = await http.get(
        Uri.parse(
          "$_mainUrl/anime/$session",
        ),
      );

      final html = res.body;
      final doc = parse(html);

      final japTitle = doc.querySelector("h2.japanese")?.text;
      final animeTitle = doc.querySelector("span.sr-only.unselectable")?.text;
      final poster = doc.querySelector(".anime-poster a")?.attributes["href"];

      final tvType = doc.querySelector("""a[href*="/anime/type/"]""")?.text;

      final trailer = html.contains("https://www.youtube.com/watch")
          ? _youtubeVideoLink.firstMatch(html)?.group(0)
          : null;

      final episodes = generateListOfEpisodes(session);

      // final year = RegExp(r"<strong>Aired:</strong>[^,]*, (\d+)")
      //     .firstMatch(html)
      //     ?.group(1)
      //     ?.toIntOrNull();

      // final status = doc.querySelector("a[href='/anime/airing']") != null
      //     ? ShowStatus.Ongoing
      //     : doc.querySelector("a[href='/anime/completed']") != null
      //         ? ShowStatus.Completed
      //         : null;

      final synopsis = doc.querySelector(".anime-synopsis")?.text;

      int? anilistId;
      int? malId;

      doc.querySelectorAll(".external-links > a").forEach((aTag) {
        final href = aTag.attributes["href"];

        if (href == null) {
          return;
        }

        final split = href.split("/");

        if (href.contains("anilist.co")) {
          anilistId = int.tryParse(split.last);
        } else if (href.contains("myanimelist.net")) {
          malId = int.tryParse(split.last);
        }
      });

      return episodes;
    } catch (e) {
      return [];
    }
  }

  static Future<List<String>> extractVideoLinks(Episode episode) async {
    final data = LinkLoadData.fromJson(jsonDecode(episode.url));
    final episodeUrl = await data.getUrl();
    final ret = <String>[];

    if (episodeUrl == null) {
      return ret;
    }

    try {
      final res = await http.get(
        Uri.parse(episodeUrl),
        headers: _headers,
      );

      final document = parse(res.body);
      final downloadLinks = document.querySelectorAll("div#pickDownload > a");
      final buttons = document.querySelectorAll("div#resolutionMenu > button");

      for (var i = 0; i < downloadLinks.length; i++) {
        final btn = buttons[i];
        final kwikLink = btn.attributes["data-src"];

        if (kwikLink == null) {
          continue;
        }

        // final quality = btn.text;
        // final paheWinLink = downloadLinks[i].attributes["href"];
        final streamUrl = await _getHlsStreamUrl(Uri.parse(kwikLink), _mainUrl);

        if (streamUrl == null) {
          continue;
        }

        ret.add(
          streamUrl,
        );
      }
    } catch (e) {
      prints("Failed to extract video links: $e");
    }

    return ret;
  }
}

class AnimePaheExtractor extends AnimeExtractor {
  @override
  String get name => "AnimePahe";

  @override
  Future<List<Anime>> search(String query) async {
    return AnimePahe.search(query);
  }

  @override
  Future<List<Episode>> getEpisodes(Anime anime) async {
    return AnimePahe.load(anime);
  }

  @override
  Future<List<VideoSource>> getSources(Episode episode) async {
    final links = await AnimePahe.extractVideoLinks(episode);
    return links
        .map(
          (e) => VideoSource(
            videoUrl: e,
            description: "AnimePahe",
          ),
        )
        .toList();
  }
}
