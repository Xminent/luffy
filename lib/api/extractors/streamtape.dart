import "dart:async";

import "package:http/http.dart" as http;

class Streamtape {
  static Future<String> getRedirectURL(String url) async {
    try {
      final http.Response response = await http.head(
        Uri.parse(url),
        headers: {
          "referer": "https://streamtape.com/e/zXpWQGbKy9Ce76/",
        },
      );
      return response.headers["location"]!;
    } catch (error) {
      rethrow;
    }
  }

  static Future<String?> extract(String id) async {
    var res = await http.get(
      Uri.parse("https://streamtape.com/e/$id"),
      headers: {"referer": "https://streamtape.com/e/zXpWQGbKy9Ce76/"},
    );
    var match = RegExp(r"robotlink'\).innerHTML = (.*);").firstMatch(res.body);
    final urlComp = match?.group(1);

    if (urlComp == null) {
      return null;
    }

    var offset = 3;
    var tempOffset = 0;
    final substrSplit = urlComp.split("substring(");

    for (var i = 1; i < substrSplit.length; i++) {
      tempOffset += int.parse(substrSplit[i]);
    }

    if (!tempOffset.isNaN) {
      offset = tempOffset;
    }

    match = RegExp(r"robotlink'\).innerHTML = '(.*)'").firstMatch(res.body);
    final mainUrlComp = match?.group(1);
    final mainUrlCompSplit = mainUrlComp?.split("'+ ('") ?? [];
    mainUrlCompSplit[1] = mainUrlCompSplit[1].substring(offset);

    final url = "https:${mainUrlCompSplit.join()}";

    res = await http.head(
      Uri.parse(url),
    );

    return res.headers["location"]!;
  }
}
