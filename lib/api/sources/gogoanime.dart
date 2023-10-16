import "dart:convert";

import "package:collection/collection.dart";
import "package:encrypt/encrypt.dart";
import "package:html/parser.dart";
import "package:http/http.dart" as http;
import "package:luffy/api/anime.dart";
import "package:luffy/util.dart";

const _baseUrl = "https://gogoanime.gr";
final _gogoSecretKey = Key.fromUtf8("37911490979715163134003223491201");
final _gogoSecretKey2 = Key.fromUtf8("54674138327930866480207815084989");
final _gogoSecretIv = IV.fromUtf8("3134003223491201");

class GogoAnimeExtractor extends AnimeExtractor {
  @override
  String get name => "GogoAnime";

  @override
  Future<List<Anime>> search(String query) async {
    final encoded = Uri.encodeComponent(query);

    final res = await http.get(
      Uri.parse("$_baseUrl/search.html?keyword=$encoded"),
      headers: {
        "x-requested-with": "XMLHttpRequest",
      },
    );

    final root = parse(res.body);
    final ret = <Anime>[];
    final aTags = root.querySelectorAll("a");
    final divs = root.querySelectorAll(".thumbnail-recent_search");

    for (final pairs in IterableZip([aTags, divs])) {
      final title = pairs[0].attributes["title"];
      final href = pairs[0].attributes["href"];
      final img = pairs[1].attributes["style"];

      final regExp = RegExp(r"url\('(.+?)'\)");
      final imageUrl = regExp.firstMatch(img ?? "")?.group(1);

      if (title == null || href == null || imageUrl == null) {
        continue;
      }

      ret.add(
        Anime(
          title: title,
          url: "$_baseUrl$href",
          imageUrl: imageUrl,
        ),
      );
    }

    return ret;
  }

  @override
  Future<List<Episode>> getEpisodes(Anime anime) async {
    final res = await http.get(
      Uri.parse(anime.url),
      headers: {
        "x-requested-with": "XMLHttpRequest",
      },
    );

    final root = parse(res.body);
    final ret = <Episode>[];
    final animeId = root
        .querySelector("input#movie_id")
        ?.attributes["value"]
        ?.replaceAll(" ", "")
        .replaceAll("\n", "");

    if (animeId == null) {
      return ret;
    }

    final lis = root.querySelector("#episode_page")?.querySelectorAll("li");

    if (lis == null) {
      return ret;
    }

    final lastEpisode = lis.last.querySelector("a")?.attributes["ep_end"];

    if (lastEpisode == null) {
      return ret;
    }

    final res2 = await http.get(
      Uri.parse(
        "https://ajax.gogo-load.com/ajax/load-list-episode?ep_start=0&ep_end=$lastEpisode&id=$animeId",
      ),
      headers: {
        "x-requested-with": "XMLHttpRequest",
      },
    );

    final root2 = parse(res2.body);
    final episodes = root2.querySelector("ul")?.querySelectorAll("li");

    if (episodes == null) {
      return ret;
    }

    // Episodes come in reverse order
    for (final episode in episodes.reversed) {
      final a = episode.querySelector("a");
      final title = a?.querySelector(".name")?.text;
      final href = a?.attributes["href"]?.trim();

      if (href == null) {
        continue;
      }

      ret.add(
        Episode(
          title: title,
          url: "$_baseUrl$href",
          thumbnailUrl: null,
        ),
      );
    }

    return ret;
  }

  @override
  Future<List<VideoSource>> getSources(Episode episode) async {
    final headers = {
      "x-requested-with": "XMLHttpRequest",
    };

    final res = await http.get(
      Uri.parse(episode.url),
      headers: headers,
    );

    final videoUrl = _parseUrls(res.body)?.videoUrl;

    if (videoUrl == null) {
      return [];
    }

    final id = RegExp(r"id=([^&]+)")
        .firstMatch(videoUrl)
        ?.group(1)
        ?.replaceFirst("id=", "");

    if (id == null) {
      return [];
    }

    final res2 = await http.get(
      Uri.parse(
        videoUrl,
      ),
      headers: headers,
    );

    final ajaxResponse = await _parseEncryptAjax(res2.body, id);

    if (ajaxResponse == null) {
      return [];
    }

    final streamUrl = "https://anihdplay.com/encrypt-ajax.php?$ajaxResponse";

    final res3 = await http.get(
      Uri.parse(streamUrl),
      headers: headers,
    );

    final sources = await _parseStreamUrl(jsonDecode(res3.body));

    prints(sources);

    return sources
        .map(
          (e) => VideoSource(
            videoUrl: e,
            description: "GogoAnime",
          ),
        )
        .toList();
  }
}

class EpisodeInfo {
  EpisodeInfo({
    this.nextEpisodeUrl,
    this.prevEpisodeUrl,
    this.videoUrl,
  });

  final String? nextEpisodeUrl;
  final String? prevEpisodeUrl;
  final String? videoUrl;
}

EpisodeInfo? _parseUrls(String body) {
  final root = parse(body);
  final info = root.querySelector(".vidcdn")?.querySelector("a");

  if (info == null) {
    return null;
  }

  var mediaUrl = info.attributes["data-video"];

  if (mediaUrl == null) {
    return null;
  }

  if (mediaUrl.startsWith("//")) {
    mediaUrl = "https:$mediaUrl";
  }

  final nextEpisodeUrl = root
      .querySelector(".anime_video_body_episodes_r")
      ?.querySelector("a")
      ?.attributes["href"];

  final previousEpisodeUrl = root
      .querySelector(".anime_video_body_episodes_l")
      ?.querySelector("a")
      ?.attributes["href"];

  return EpisodeInfo(
    nextEpisodeUrl: nextEpisodeUrl,
    prevEpisodeUrl: previousEpisodeUrl,
    videoUrl: mediaUrl,
  );
}

Future<String?> _parseEncryptAjax(
  String body,
  String id,
) async {
  final root = parse(body);
  // Return script who has a data-name and data-value attributes.
  final script = root.querySelector("script[data-name][data-value]");

  if (script == null) {
    return null;
  }

  final value = script.attributes["data-value"];

  if (value == null) {
    return null;
  }

  final decrypted = (await _decryptAes(value, _gogoSecretKey, _gogoSecretIv))
      .replaceAll("\t", "")
      .substring(id.length);

  final encrypted = await _encryptAes(id, _gogoSecretKey, _gogoSecretIv);

  return "id=$encrypted$decrypted&alias=$id";
}

Future<String> _encryptAes(String text, Key key, IV iv) async {
  final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
  final encrypted = encrypter.encrypt(text, iv: iv);
  return encrypted.base64;
}

Future<String> _decryptAes(String encrypted, Key key, IV iv) async {
  final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
  final decrypted = encrypter.decrypt64(encrypted, iv: iv);
  return decrypted;
}

Future<List<String>> _parseStreamUrl(Map<String, dynamic> body) async {
  final ret = <String>[];

  final decrypted = (await _decryptAes(
    body["data"],
    _gogoSecretKey2,
    _gogoSecretIv,
  ))
      .replaceAll('o"<P{#meme":"', 'e":[{"file":');

  final json = jsonDecode(decrypted);
  final sources = json["source"];

  if (sources == null) {
    return ret;
  }

  for (final source in sources) {
    final file = source["file"];

    if (file == null) {
      continue;
    }

    ret.add(file);
  }

  return ret;
}
