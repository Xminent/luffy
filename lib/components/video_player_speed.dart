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

  Widget _buildSpeedListTile(double speed) {
    return ListTile(
      title: Text("${speed}x"),
      onTap: () => Navigator.of(context).pop(speed),
      selected: _selectedSpeed == speed,
    );
  }

  Future<void> _showSpeedDialog() async {
    final selectedSpeed = await showDialog<double>(
      context: context,
      builder: (context) {
        final scrollController = ScrollController();

        return AlertDialog(
          title: const Text("Player Speed"),
          content: SingleChildScrollView(
            controller: scrollController,
            child: ListBody(
              children: [
                _buildSpeedListTile(0.5),
                _buildSpeedListTile(0.75),
                _buildSpeedListTile(0.85),
                _buildSpeedListTile(1.0),
                _buildSpeedListTile(1.15),
                _buildSpeedListTile(1.25),
                _buildSpeedListTile(1.4),
                _buildSpeedListTile(1.5),
                _buildSpeedListTile(1.75),
                _buildSpeedListTile(2.0),
                _buildSpeedListTile(2.5),
                _buildSpeedListTile(3.0),
                _buildSpeedListTile(3.5),
                _buildSpeedListTile(4.0),
                _buildSpeedListTile(4.5),
                _buildSpeedListTile(5.0),
              ],
            ),
          ),
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
      label: "Speed (${_selectedSpeed.toStringAsFixed(2)}x)",
    );
  }
}
