import "package:http/http.dart" as http;
import "package:luffy/api/sources/nineanime.dart";
import "package:luffy/util.dart";

class Mp4uploadExtractor {
  Future<List<Video>> videosFromUrl(
    String url,
    String prefix,
  ) async {
    final id = url.substringAfterLast("embed-").substringBeforeLast(".html");

    final params = {
      "op": "download2",
      "id": id,
      "rand": "",
      "referer": url,
      "method_free": "+",
      "method_premiun": "",
    };

    final res = await http.post(
      Uri.parse(url),
      body: params,
    );

    // Return the location response header.
    final location = res.headers["location"];

    return [
      Video(
        location!,
        prefix,
        location,
        {},
      ),
    ];
  }
}
