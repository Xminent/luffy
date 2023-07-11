import "package:flutter/material.dart";

String formatTime(Duration duration) {
  final showHours = duration.inHours != 0;
  final str = duration.toString().split(".").first;
  final parts = str.split(":");

  return showHours
      ? "${parts[0]}:${parts[1]}:${parts[2]}"
      : "${parts[1]}:${parts[2]}";
}

class ProgressBar extends StatefulWidget {
  const ProgressBar({
    super.key,
    required this.duration,
    required this.position,
    required this.buffered,
    required this.onProgressChanged,
  });

  final Duration duration;
  final Duration position;
  final Duration buffered;
  final ValueChanged<Duration> onProgressChanged;

  @override
  State<ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<ProgressBar> {
  bool _dragging = false;
  late Duration _seek = widget.position;

  @override
  void didUpdateWidget(ProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_dragging) {
      return;
    }

    if (widget.position != oldWidget.position) {
      _seek = widget.position;
    }
  }

  void _onChangedStart(double value) {
    setState(() {
      _dragging = true;
    });
  }

  void _onChanged(double value) {
    setState(() {
      _seek = Duration(
        milliseconds: (value * widget.duration.inMilliseconds).round(),
      );
    });
  }

  void _onChangedEnd(double value) {
    widget.onProgressChanged(_seek);

    setState(() {
      _dragging = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final duration = widget.duration;
    final buffered = widget.buffered;

    final width = MediaQuery.of(context).size.width;
    double value = 0.0;

    if (_seek.inMilliseconds > 0 && duration.inMilliseconds > 0) {
      value = _seek.inMilliseconds / duration.inMilliseconds;
    }

    double bufferedValue = 0.0;

    if (buffered.inMilliseconds > 0 && duration.inMilliseconds > 0) {
      bufferedValue = buffered.inMilliseconds / duration.inMilliseconds;
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 0.035 * width),
      child: Row(
        children: [
          Text(
            formatTime(_seek),
            style: const TextStyle(color: Colors.white),
          ),
          Expanded(
            child: Slider(
              value: value.clamp(0, 1),
              onChangeStart: _onChangedStart,
              onChanged: _onChanged,
              onChangeEnd: _onChangedEnd,
              thumbColor: Theme.of(context).colorScheme.primary,
              secondaryTrackValue: bufferedValue.clamp(0, 1),
            ),
          ),
          Text(
            formatTime(duration),
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
