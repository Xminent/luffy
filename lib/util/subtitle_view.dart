import "package:flutter/material.dart";
import "package:luffy/util/subtitle_controller.dart";

class SubtitleControlView extends StatelessWidget {
  const SubtitleControlView({
    super.key,
    required this.inMilliseconds,
    required this.subtitleController,
    this.padding = const EdgeInsets.all(4),
    this.backgroundColor = const Color.fromRGBO(0, 0, 0, 0.6),
    this.subtitleStyle = const SubtitleStyle(),
  });

  final SubtitleController subtitleController;
  final int inMilliseconds;

  final Color? backgroundColor;
  final SubtitleStyle subtitleStyle;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final text = subtitleController.textFromMilliseconds(
      inMilliseconds,
      subtitleController.subtitles,
    );

    if (text == "") {
      return const SizedBox.shrink();
    }

    return SubtitleView(
      text: text,
      padding: padding,
      subtitleStyle: subtitleStyle,
      backgroundColor: backgroundColor,
    );
  }
}

class SubtitleView extends StatelessWidget {
  const SubtitleView({
    super.key,
    required this.text,
    this.backgroundColor = const Color.fromRGBO(0, 0, 0, 0.6),
    this.subtitleStyle = const SubtitleStyle(),
    this.padding = const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2),
  });

  final Color? backgroundColor;
  final SubtitleStyle subtitleStyle;
  final EdgeInsets padding;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(2.0),
        ),
        child: Padding(
          padding: padding,
          child: Stack(
            children: [
              if (subtitleStyle.bordered)
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: subtitleStyle.fontSize,
                    foreground: Paint()
                      ..style = subtitleStyle.borderStyle.style
                      ..strokeWidth = subtitleStyle.borderStyle.strokeWidth
                      ..color = subtitleStyle.borderStyle.color,
                  ),
                ),
              Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: subtitleStyle.textColor,
                  fontSize: subtitleStyle.fontSize,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _defaultStrokeWidth = 2.0;

class SubtitleBorderStyle {
  const SubtitleBorderStyle({
    this.strokeWidth = _defaultStrokeWidth,
    this.style = PaintingStyle.stroke,
    this.color = Colors.black,
  });

  final double strokeWidth;
  final PaintingStyle style;
  final Color color;
}

const _defaultFontSize = 16.0;

class SubtitleStyle {
  const SubtitleStyle({
    this.bordered = false,
    this.borderStyle = const SubtitleBorderStyle(),
    this.fontSize = _defaultFontSize,
    this.textColor = Colors.white,
  });
  final bool bordered;
  final SubtitleBorderStyle borderStyle;
  final double fontSize;
  final Color textColor;
}
