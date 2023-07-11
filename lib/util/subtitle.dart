import "package:flutter/foundation.dart" show objectRuntimeType;

class Subtitle {
  const Subtitle({
    required this.number,
    required this.start,
    required this.end,
    required this.text,
  });

  final int number;
  final int start;
  final int end;
  final String text;

  static Subtitle get empty => const Subtitle(
        number: -1,
        start: -1,
        end: -1,
        text: "",
      );

  @override
  String toString() {
    return '${objectRuntimeType(this, 'Subtitle')}('
        "number: $number, "
        "start: $start, "
        "end: $end, "
        "text: $text)";
  }
}

enum SubtitleFormat {
  webvtt,

  srt,
}
