import "package:luffy/util/subtitle.dart";
import "package:luffy/util/subtitle_parsers.dart";

class SubtitleController {
  SubtitleController.string(
    this.fileContents, {
    required this.format,
    int? offset,
  })  : _subtitles = parseSubtitleString(fileContents, format),
        offset = offset ?? 0;

  final String fileContents;

  final SubtitleFormat format;

  List<Subtitle> get subtitles => _subtitles;

  final List<Subtitle> _subtitles;

  bool get isEmpty => subtitles.isEmpty;

  bool get isNotEmpty => !isEmpty;

  final int offset;

  String textFromMilliseconds(int milliseconds, List<Subtitle> subtitls) {
    final normalizedMs = (milliseconds + offset).clamp(0, milliseconds);

    final subtitle = subtitls.lastWhere(
      (data) => normalizedMs >= (data.start) && milliseconds <= (data.end),
      orElse: () => Subtitle.empty,
    );

    return subtitle.text;
  }
}
