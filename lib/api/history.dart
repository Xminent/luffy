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
  });

  HistoryEntry.fromJson(Map<String, dynamic> json)
      : id = json["id"],
        title = json["title"],
        imageUrl = json["image_url"],
        progress = json["progress"];

  // The ID of the anime (if a normie show/movie will be formatted like so: "$sourceName-$showId")
  final int? id;
  //  The title of the anime/show/movie
  final String title;
  // The image URL of the anime/show/movie
  final String imageUrl;
  // The stored progress of the media (is indexed by the episode number)
  final Map<int, double> progress;

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "title": title,
      "image_url": imageUrl,
      "progress": progress.map((key, value) => MapEntry(key.toString(), value)),
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
    if (_instance == null) {
      final historyStr = await _storage.read(key: "history");
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

    // History must be reversed to show the latest media first.
    return instance._history.reversed.toList();
  }

  static Future<void> clearHistory() async {
    final instance = await _getInstance();

    instance._history.clear();
    _storage.delete(key: "history");
  }

  static Future<HistoryEntry?> getMedia(int id) async {
    final instance = await _getInstance();

    return instance._history.firstWhereOrNull((element) => element.id == id);
  }
}
