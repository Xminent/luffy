import "package:flutter/material.dart";

class ClickableText extends StatefulWidget {
  const ClickableText(
    this.text, {
    super.key,
    required this.style,
    required this.textAlign,
    required this.maxLines,
    required this.overflow,
  });

  final String text;
  final TextStyle style;
  final TextAlign textAlign;
  final int maxLines;
  final TextOverflow overflow;

  @override
  State<ClickableText> createState() => _ClickableTextState();
}

class _ClickableTextState extends State<ClickableText> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: Text(
        widget.text,
        style: widget.style,
        textAlign: widget.textAlign,
        maxLines: _isExpanded ? null : widget.maxLines,
        overflow: _isExpanded ? TextOverflow.visible : widget.overflow,
      ),
    );
  }
}
