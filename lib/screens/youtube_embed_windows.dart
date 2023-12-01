import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:luffy/util.dart";
import "package:webview_windows/webview_windows.dart";

final navigatorKey = GlobalKey<NavigatorState>();

class YouTubeEmbedWindows extends StatefulWidget {
  const YouTubeEmbedWindows({super.key, required this.url});

  final String url;

  @override
  State<YouTubeEmbedWindows> createState() => YouTubeEmbedWindowsState();
}

class YouTubeEmbedWindowsState extends State<YouTubeEmbedWindows> {
  final _controller = WebviewController();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    try {
      await _controller.initialize();
      await _controller.setBackgroundColor(Colors.transparent);
      await _controller.setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);
      await _controller.loadUrl(widget.url);

      if (!mounted) {
        return;
      }

      setState(() {});
    } on PlatformException catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Error"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Code: ${e.code}"),
                Text("Message: ${e.message}"),
              ],
            ),
            actions: [
              TextButton(
                child: const Text("Continue"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    prints("YoutubeEmbed: ${widget.url}");

    if (!_controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Webview(
        _controller,
        permissionRequested: _onPermissionRequested,
      ),
    );
  }

  Future<WebviewPermissionDecision> _onPermissionRequested(
    String url,
    WebviewPermissionKind kind,
    bool isUserInitiated,
  ) async {
    final decision = await showDialog<WebviewPermissionDecision>(
      context: navigatorKey.currentContext!,
      builder: (BuildContext context) => AlertDialog(
        title: const Text("WebView permission requested"),
        content: Text("WebView has requested permission '$kind'"),
        actions: <Widget>[
          TextButton(
            onPressed: () =>
                Navigator.pop(context, WebviewPermissionDecision.deny),
            child: const Text("Deny"),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, WebviewPermissionDecision.allow),
            child: const Text("Allow"),
          ),
        ],
      ),
    );

    return decision ?? WebviewPermissionDecision.none;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
