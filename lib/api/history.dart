import "dart:convert";

import "package:collection/collection.dart";
import "package:flutter_secure_storage/flutter_secure_storage.dart";
import "package:luffy/util.dart";

class HistoryEntry {
  const HistoryEntry({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.progress,
    required this.totalEpisodes,
  });

  HistoryEntry.fromJson(Map<String, dynamic> json)
      : id = json["id"],
        title = json["title"],
        imageUrl = json["image_url"],
        progress = json["progress"],
        totalEpisodes = json["total_episodes"];

  // The ID of the anime (if a normie show/movie will be formatted like so: "$sourceName-$showId")
  final String? id;
  //  The title of the anime/show/movie
  final String title;
  // The image URL of the anime/show/movie
  final String imageUrl;
  // The stored progress of the media (is indexed by the episode number)
  final Map<int, double> progress;
  // The total number of episodes of the media
  final int totalEpisodes;

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "title": title,
      "image_url": imageUrl,
      "progress": progress.map((key, value) => MapEntry(key.toString(), value)),
      "total_episodes": totalEpisodes,
    };
  }
}

const _storage = FlutterSecureStorage();

class HistoryService {
  HistoryService._internal(List<HistoryEntry> history) {
    _history = history;
  }

  static HistoryService? _instance;

  static Future<HistoryService> _getInstance() async {
    // TODO: Debug delete.
    // await _storage.delete(key: "history");

    if (_instance == null) {
      final historyStr = await _storage.read(key: "history");

      prints("History: $historyStr");

      final history = historyStr != null
          ? (jsonDecode(historyStr) as List)
              .map(
                (e) => HistoryEntry(
                  id: e["id"],
                  title: e["title"],
                  imageUrl: e["image_url"],
                  progress: e["progress"] != null
                      ? Map.fromEntries(
                          (e["progress"] as Map<String, dynamic>).entries.map(
                                (e) => MapEntry(int.parse(e.key), e.value),
                              ),
                        )
                      : {},
                  totalEpisodes: e["total_episodes"],
                ),
              )
              .toList()
          : <HistoryEntry>[];

      _instance = HistoryService._internal(history);
    }

    return _instance!;
  }

  List<HistoryEntry> _history = [];

  List<HistoryEntry> get history => _history;

  static Future<void> addProgress(
    HistoryEntry media,
    int episodeNum,
    double progress,
  ) async {
    final instance = await _getInstance();
    final history = instance._history;

    // If the entry is not in the history, add it.
    if (!history.contains(media)) {
      history.add(media);
    }

    // Update the progress of the media.
    history
        .firstWhere((element) => element.id == media.id)
        .progress[episodeNum] = progress;

    _storage.write(
      key: "history",
      value: jsonEncode(history.map((e) => e.toJson()).toList()),
    );

    // Print the current history.
    prints("History: $history");
  }

  static Future<void> removeMedia(HistoryEntry media) async {
    final instance = await _getInstance();
    final history = instance._history;

    history.remove(media);
    _storage.write(key: "history", value: jsonEncode(history));
  }

  static Future<List<HistoryEntry>> getHistory() async {
    final instance = await _getInstance();
    return instance._history;
  }

  static Future<void> clearHistory() async {
    final instance = await _getInstance();

    instance._history.clear();
    _storage.delete(key: "history");
  }

  static Future<HistoryEntry?> getMedia(String id) async {
    final instance = await _getInstance();

    return instance._history.firstWhereOrNull((element) => element.id == id);
  }
}
