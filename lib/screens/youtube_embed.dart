import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:luffy/screens/youtube_embed_mobile.dart";
import "package:luffy/screens/youtube_embed_windows.dart";

class YouTubeEmbed extends StatelessWidget {
  const YouTubeEmbed({
    super.key,
    required this.url,
  });

  final String url;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      return YouTubeEmbedWindows(
        url: url,
      );
    }

    return YouTubeEmbedMobile(
      url: url,
    );
  }
}
