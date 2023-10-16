// import "dart:convert";

// import "package:html/parser.dart";
// import "package:http/http.dart" as http;
// import "package:luffy/api/anime.dart";
// import "package:luffy/api/extractors/streamtape.dart";

// const _baseUrl = "https://kaido.to";
// final _headers = {"X-Requested-With": "XMLHttpRequest", "referer": _baseUrl};

// class Kaido {
//   static Future<List<Anime>> search(String query) async {
//     /* sanitize the query like this:
//     var url = URLEncoder.encode(query, "utf-8")
//         if (query.startsWith("$!")) {
//             val a = query.replace("$!", "").split(" | ")
//             url = URLEncoder.encode(a[0], "utf-8") + a[1]
//         }
//     */

//     query = Uri.encodeComponent(query);

//     final url = Uri.parse("$_baseUrl/search?keyword=$query");
//     final res = await http.get(url);
//     final document = parse(res.body);

//     /* perform the equivalent of this:
//     return document.select(".film_list-wrap > .flw-item > .film-poster").map {
//             val link = it.select("a").attr("data-id")
//             val title = it.select("a").attr("title")
//             val cover = it.select("img").attr("data-src")
//             ShowResponse(title, link, FileUrl(cover))
//         }
//     */

//     final items =
//         document.querySelectorAll(".film_list-wrap > .flw-item > .film-poster");

//     final ret = <Anime>[];

//     for (final item in items) {
//       final aTag = item.querySelector("a");

//       if (aTag == null) {
//         continue;
//       }

//       final title = aTag.attributes["title"];
//       final url = aTag.attributes["data-id"];
//       final imageUrl = aTag.attributes["data-src"];

//       if (title == null || url == null) {
//         continue;
//       }

//       ret.add(
//         Anime(
//           title: title,
//           url: url,
//           // TODO: Make parameter optional
//           imageUrl: imageUrl ?? "",
//         ),
//       );
//     }

//     return ret;
//   }

//   static Future<List<Episode>> loadEpisodes(
//     Anime anime,
//     Map<String, dynamic> extra,
//   ) async {
//     final res = await http.get(
//       Uri.parse("$_baseUrl/ajax/episode/list/${anime.url}"),
//       headers: _headers,
//     );

//     final document = parse(jsonDecode(res.body)["html"]);
//     final items = document.querySelectorAll(".ep-item");
//     final ret = <Episode>[];

//     for (final item in items) {
//       final href = item.attributes["href"];
//       final title = item.attributes["data-number"];

//       if (href == null || title == null) {
//         continue;
//       }

//       final link =
//           "${href.replaceFirst("/watch", "").replaceFirst("?ep=", "&ep=")}&engine=3";
//       // final number = aTag.attributes["data-number"];
//       // final filler =
//       //     aTag.attributes["class"]?.contains("ssl-item-filler") ?? false;

//       ret.add(
//         Episode(
//           title: title,
//           url: link,
//         ),
//       );
//     }

//     return ret;
//   }

//   static Future<void> addSource(
//     String type,
//     String id,
//     List<Subtitle> subtitles,
//     List<VideoSource> sourcesRef, {
//     String serverType = "Streamtape",
//   }) async {
//     final res = await http.get(
//       Uri.parse("$_baseUrl/ajax/episode/sources?id=$id"),
//     );
//     final sources = Uri.parse(jsonDecode(res.body)["link"]);

//     if (serverType == "Streamtape") {
//       final url = await Streamtape.extract(sources.pathSegments[2]);
//     }
//   }

//   static Future<List<VideoSource>> getSources(Episode episode) async {
//     final url = episode.url;
//     final animeId =
//         url.replaceFirst("?watch=", "").split("-").last.split("&").first;
//     final episodeId = url.split("&ep=").last;
//     final sources = <VideoSource>[];
//     final subtitles = <Subtitle>[];

//     final res = await http.get(
//       Uri.parse("$_baseUrl/ajax/episode/servers?episodeId=$episodeId"),
//     );
//     final document = parse(jsonDecode(res.body)["html"]);
//     var items = document.querySelectorAll('[data-server-id="4"]');
//     final hasSource = items.isNotEmpty;

//     for (final item in items) {
//       final type = item.attributes["data-type"];
//       final id = item.attributes["data-id"];

//       if (type == null || id == null) {
//         continue;
//       }

//       addSource(type, id, subtitles, sources, serverType: "Vidstreaming");
//     }

//     items = document.querySelectorAll('[data-server-id="1"]');

//     for (final item in items) {
//       final type = item.attributes["data-type"];
//       final id = item.attributes["data-id"];

//       if (type == null || id == null) {
//         continue;
//       }

//       addSource(type, id, subtitles, sources, serverType: "Megacloud");
//     }
//   }
// }
