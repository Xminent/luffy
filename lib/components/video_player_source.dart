import "package:flutter/material.dart";
import "package:luffy/api/anime.dart";
import "package:luffy/components/video_player_icon.dart";

class VideoPlayerSourceIcon extends StatefulWidget {
  const VideoPlayerSourceIcon({
    super.key,
    required this.source,
    required this.sources,
    required this.subtitle,
    required this.subtitles,
    required this.onSourceChanged,
    required this.onSubtitleChanged,
  });

  final VideoSource source;
  final List<VideoSource> sources;
  final Subtitle? subtitle;
  final List<Subtitle?>? subtitles;
  final ValueChanged<VideoSource> onSourceChanged;
  final ValueChanged<Subtitle?> onSubtitleChanged;

  @override
  State<VideoPlayerSourceIcon> createState() => _VideoPlayerSourceIconState();
}

class _VideoPlayerSourceIconState extends State<VideoPlayerSourceIcon> {
  late var _selectedSource = widget.source;

  Widget _buildSourceListTile(VideoSource source) {
    return ListTile(
      title: Text(source.description),
      onTap: () => Navigator.of(context).pop(source),
      selected: _selectedSource == source,
    );
  }

  Future<void> _showSourceDialog() async {
    final selectedSource = await showDialog<VideoSource>(
      context: context,
      builder: (context) {
        final scrollController = ScrollController();

        return AlertDialog(
          title: const Text("Sources"),
          content: SingleChildScrollView(
            controller: scrollController,
            child: ListBody(
              children: widget.sources
                  .map((source) => _buildSourceListTile(source))
                  .toList(),
            ),
          ),
        );
      },
    );

    if (selectedSource != null) {
      setState(() {
        _selectedSource = selectedSource;
      });

      widget.onSourceChanged(_selectedSource);
    }
  }

  @override
  Widget build(BuildContext context) {
    return VideoPlayerIcon(
      icon: Icons.playlist_play,
      onPressed: _showSourceDialog,
      label: "Source",
    );
  }
}
