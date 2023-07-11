import "package:flutter/material.dart";

class BlinkingWidget extends StatefulWidget {
  const BlinkingWidget({
    super.key,
    this.blinkDuration = const Duration(seconds: 1),
    required this.child,
  });

  final Duration? blinkDuration;
  final Widget child;

  @override
  State<BlinkingWidget> createState() => _BlinkingWidgetState();
}

class _BlinkingWidgetState extends State<BlinkingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    _animationController =
        AnimationController(vsync: this, duration: widget.blinkDuration);
    _animationController.repeat(reverse: true);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animationController,
      child: widget.child,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
