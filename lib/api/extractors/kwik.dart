// import "package:html/parser.dart";
// import "package:http/http.dart" as http;
// import "package:http/http.dart";
// import "package:luffy/js_unpacker.dart";
// import "package:luffy/util.dart";

// class KwikExtractor {
//   String cookies = "";

//   RegExp kwikParamsRegex = RegExp(r'''\("(\w+)",\d+,"(\w+)",(\d+),(\d+),\d+\)''');
//   RegExp kwikDUrl = RegExp(r'action="([^"]+)"');
//   RegExp kwikDToken = RegExp(r'value="([^"]+)"');

//   bool isNumber(String? s) {
//     return int.tryParse(s ?? "") != null;
//   }

//   Future<String> getHlsStreamUrl(String kwikUrl, String referer) async {
//     final res = await http.get(Uri.parse(kwikUrl), headers: {"referer": referer});
//     final script = substringAfterLast(parse(res.body)
//         .querySelector(r"script:containsData(eval\(function)")!
//         .innerHtml, "eval(function(",);
//     final unpacked = JsUnpacker("eval(function($script").unpack()!;
//     return substringBefore(substringAfter(unpacked, r"const source=\'"), r"\';");
//   }

//   Future<String> getStreamUrlFromKwik(String paheUrl) async {
//     final noRedirects = http.Client();
//     final kwikUrl = "https://${substringAfterLast((await noRedirects.get(Uri.parse("$paheUrl/i"))).headers["location"]!
//             , "https://",)}";

//     final fContent = await http.get(Uri.parse(kwikUrl), headers: {"referer": "https://kwik.cx/"});
//     cookies += fContent.headers["set-cookie"] ?? "";
//     final fContentString = fContent.body;

//     final match = kwikParamsRegex.firstMatch(fContentString)!;
//     final fullString = match.group(0)!;
//     final key = match.group(1)!;
//     final v1 = int.parse(match.group(2)!);
//     final v2 = int.parse(match.group(3)!);
//     final decrypted = decrypt(fullString, key, v1, v2);
//     final uri = kwikDUrl.firstMatch(decrypted)!.group(1)!;
//     final tok = kwikDToken.firstMatch(decrypted)!.group(1)!;

//     Response? content;
//     var code = 419;
//     var tries = 0;

//     final noRedirectClient = http.Client();
//     while (code != 302 && tries < 20) {
//       content = await noRedirectClient.post(Uri.parse(uri),
//           headers: {
//             "referer": fContent.request!.url.toString(),
//             "cookie": fContent.headers["set-cookie"]!.replaceFirst("path=/;", ""),
//           },
//           body: {
//             "_token": tok,
//           },);
//       code = content.statusCode;
//       ++tries;
//     }
//     if (tries > 19) {
//       throw Exception("Failed to extract the stream uri from kwik.");
//     }
//     final location = content?.headers["location"].toString();
//     noRedirectClient.close();
//     return location!;
//   }

//   String decrypt(String fullString, String key, int v1, int v2) {
//     var r = "";
//     var i = 0;

//     while (i < fullString.length) {
//       var s = "";

//       while (fullString[i] != key[v2]) {
//         s += fullString[i];
//         ++i;
//       }
//       var j = 0;

//       while (j < key.length) {
//         s = s.replaceAll(key[j], j.toString());
//         ++j;
//       }
//       r += (getString(s, v2).toInt() - v1).toChar();
//       ++
