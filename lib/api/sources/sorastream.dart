// import "package:http/http.dart" as http;
// import "dart:convert";

// import "package:luffy/util.dart";

// final String _tmdbApi = "https://api.themoviedb.org/3";

// class SoraStreamInner {
//   static Future<Map<String, dynamic>?> search(String query) async {
//     try {
//       final res = await http.get(Uri.parse(
//           "$_tmdbApi/search/multi?api_key=$apiKey&language=en-US&query=$query&page=1&include_adult=${settingsForProvider.enableAdult}"));
//     } catch (e) {
//       prints("Failed to get $url: $e");
//       return null;
//     }
//   }
// }
