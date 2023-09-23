import "package:flutter/material.dart";
import "package:luffy/components/video_player/control_icon.dart";

class SliderDialogIcon extends StatefulWidget {
  const SliderDialogIcon({
    super.key,
    required this.title,
    this.min = 0.0,
    this.max = 1.0,
    required this.value,
    required this.onValueChanged,
  });

  final String title;
  final double min;
  final double max;
  final double value;
  final ValueChanged<double> onValueChanged;

  @override
  State<SliderDialogIcon> createState() => _SliderDialogIconState();
}

class _SliderDialogIconState extends State<SliderDialogIcon> {
  double _selectedSpeed = 1.0;
  bool _isConfirmButtonVisible = false;

  Future<void> _showSpeedDialog() async {
    final selectedSpeed = await showDialog<double>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Player Speed"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Slider(
                    value: _selectedSpeed,
                    min: 0.5,
                    max: 5.0,
                    divisions: 45,
                    onChanged: (value) {
                      setState(() {
                        _selectedSpeed = value;
                        _isConfirmButtonVisible = true;
                      });
                    },
                    onChangeEnd: (value) {
                      setState(() {
                        _isConfirmButtonVisible = true;
                      });
                    },
                  ),
                  Text("${(_selectedSpeed * 100).toStringAsFixed(0)}%"),
                ],
              ),
              actions: <Widget>[
                if (_isConfirmButtonVisible)
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(_selectedSpeed),
                    child: const Text("Confirm"),
                  ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Cancel"),
                ),
              ],
            );
          },
        );
      },
    );

    if (selectedSpeed != null) {
      setState(() {
        _selectedSpeed = selectedSpeed;
      });

      widget.onValueChanged(_selectedSpeed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return VideoPlayerIcon(
      icon: Icons.speed,
      onPressed: _showSpeedDialog,
      label: "Speed (${widget.value.toStringAsFixed(2)}x)",
    );
  }
}

class VideoPlayerSpeedDialog extends StatefulWidget {
  const VideoPlayerSpeedDialog({
    super.key,
    required this.speed,
    required this.onSpeedChanged,
    required this.onShowConfirmButton,
  });

  final double speed;
  final ValueChanged<double> onSpeedChanged;
  final ValueChanged<bool> onShowConfirmButton;

  @override
  State<VideoPlayerSpeedDialog> createState() => _VideoPlayerSpeedDialogState();
}

class _VideoPlayerSpeedDialogState extends State<VideoPlayerSpeedDialog> {
  double selectedSpeed = 1.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Slider(
          value: selectedSpeed,
          min: 0.5,
          max: 5.0,
          divisions: 15,
          onChanged: (value) {
            setState(() {
              selectedSpeed = value;
              widget.onShowConfirmButton(true);
            });
          },
          onChangeEnd: (value) {
            setState(() {
              widget.onShowConfirmButton(true);
            });
          },
        ),
        Text("${(selectedSpeed * 100).toStringAsFixed(0)}%"),
      ],
    );
  }
}
