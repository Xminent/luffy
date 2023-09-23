import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_inappwebview/flutter_inappwebview.dart";
import "package:luffy/api/anime.dart";
import "package:luffy/auth.dart";
import "package:luffy/screens/home_tab.dart";
import "package:luffy/screens/login.dart";
import "package:luffy/theme.dart";
import "package:window_manager/window_manager.dart";

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (defaultTargetPlatform == TargetPlatform.windows) {
    await windowManager.ensureInitialized();
  }

  // MediaKit.ensureInitialized();

  if (!kIsWeb &&
      kDebugMode &&
      defaultTargetPlatform == TargetPlatform.android) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(kDebugMode);
  }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight
  ]);

  runApp(const MyApp());
}

MaterialApp _buildMaterialApp({
  required bool isAuthenticated,
  required Widget home,
}) {
  return MaterialApp(
    title: "Luffy",
    theme: darkTheme,
    darkTheme: darkTheme,
    home: home,
    routes: {
      "/home": (context) => const HomeTabScreen(),
      "/login": (context) => const LoginScreen(),
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MalToken?>(
      future: MalToken.getInstance(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return _buildMaterialApp(
            isAuthenticated: false,
            home: const LoginScreen(),
          );
        }

        final ep = Episode(
          title: "Video",
          url: "",
          thumbnailUrl: null,
        );

        return _buildMaterialApp(
          isAuthenticated: true,
          // home: const AnimeBrowser(),
          // home: VideoPlayerScreen(
          //   showId: "test",
          //   episode: ep,
          //   episodeNum: 1,
          //   imageUrl: null,
          //   episodes: [ep],
          //   sourceFetcher: (episode) {
          //     return Future.value([
          //       const VideoSource(
          //         videoUrl:
          //             "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
          //         description: "test",
          //       )
          //     ]);
          //   },
          //   showTitle: "Video",
          //   sourceName: "VizCloud",
          // ),
          home: const HomeTabScreen(),
          // home: GridScreen(),
          // home: const DetailsScreen(
          //   animeId: 21,
          //   watchedEpisodes: 0,
          //   totalEpisodes: 12,
          // ),
        );
      },
    );
  }
}
