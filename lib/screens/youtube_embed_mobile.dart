import "package:flutter/material.dart";
import "package:flutter_inappwebview/flutter_inappwebview.dart";
import "package:luffy/util.dart";

class YouTubeEmbedMobile extends StatefulWidget {
  const YouTubeEmbedMobile({super.key, required this.url});

  final String url;

  @override
  State<YouTubeEmbedMobile> createState() => _YouTubeEmbedMobileState();
}

class _YouTubeEmbedMobileState extends State<YouTubeEmbedMobile> {
  final _webViewKey = GlobalKey();

  final settings = InAppWebViewSettings(
    allowsInlineMediaPlayback: true,
    mediaPlaybackRequiresUserGesture: false,
  );

  @override
  Widget build(BuildContext context) {
    prints("YoutubeEmbed: ${widget.url}");

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: InAppWebView(
        key: _webViewKey,
        initialUrlRequest: URLRequest(url: WebUri(widget.url)),
        initialSettings: settings,
        onPermissionRequest: (controller, request) async {
          return PermissionResponse(
            resources: request.resources,
            action: PermissionResponseAction.GRANT,
          );
        },
      ),
    );
  }
}
