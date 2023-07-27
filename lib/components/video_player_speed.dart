import "package:flutter/material.dart";
import "package:luffy/components/video_player_icon.dart";

class VideoPlayerSpeedIcon extends StatefulWidget {
  const VideoPlayerSpeedIcon({
    super.key,
    required this.speed,
    required this.onSpeedChanged,
  });

  final double speed;
  final ValueChanged<double> onSpeedChanged;

  @override
  State<VideoPlayerSpeedIcon> createState() => _VideoPlayerSpeedIconState();
}

class _VideoPlayerSpeedIconState extends State<VideoPlayerSpeedIcon> {
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

      widget.onSpeedChanged(_selectedSpeed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return VideoPlayerIcon(
      icon: Icons.speed,
      onPressed: _showSpeedDialog,
      label: "Speed (${widget.speed.toStringAsFixed(2)}x)",
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
