import "dart:convert";

import "package:flutter_secure_storage/flutter_secure_storage.dart";

class HistoryEntry {
  const HistoryEntry({
    this.id,
    required this.title,
    required this.imageUrl,
    required this.url,
    required this.progress,
  });

  final int? id;
  final String title;
  final String imageUrl;
  final String url;
  final double progress;
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
                  title: e["title"],
                  imageUrl: e["image_url"],
                  url: e["url"],
                  progress: e["progress"],
                ),
              )
              .toList()
          : [] as List<HistoryEntry>;

      _instance = HistoryService._internal(history);
    }

    return _instance!;
  }

  List<HistoryEntry> _history = [];

  List<HistoryEntry> get history => _history;

  static Future<void> addMedia(HistoryEntry media) async {
    final instance = await _getInstance();
    final history = instance._history;

    history.add(media);
    _storage.write(key: "history", value: jsonEncode(history));
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
}
