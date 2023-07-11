import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_inappwebview/flutter_inappwebview.dart";
import "package:luffy/auth.dart";
import "package:luffy/screens/home_tab.dart";
import "package:luffy/screens/login.dart";
import "package:luffy/theme.dart";
import "package:media_kit/media_kit.dart";

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

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

  // final extractor = AnimeFlixExtractor();
  // final results = await extractor.search("naruto");
  // final episodes = await extractor.getEpisodes(results.first);
  // final source = await extractor.getVideoUrl(episodes.first);
  // prints(source?.videoUrl);
}

MaterialApp _buildMaterialApp({
  required bool isAuthenticated,
  required Widget home,
}) {
  return MaterialApp(
    title: "Luffy",
    theme: lightTheme,
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
          return const CircularProgressIndicator();
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return _buildMaterialApp(
            isAuthenticated: false,
            home: const LoginScreen(),
          );
        }

        return _buildMaterialApp(
          isAuthenticated: true,
          // home: const AnimeBrowser(),
          // home: const VideoPlayerScreen(
          //   showId: 0,
          //   episode: 0,
          //   title: "Video",
          //   url:
          //       "https://crunchy.animeflix.live/https://ta-005.agetcdn.com/1ab5d45273a9183bebb58eb74d5722d8ea6384f350caf008f08cf018f1f0566d0cb82a2a799830d1af97cd3f4b6a9a81ef3aed2fb783292b1abcf1b8560a1d1aa308008b88420298522a9f761e5aa1024fbe74e5aa853cfc933cd1219327d1232e91847a185021b184c027f97ae732b3708ee6beb80ba5db6628ced43f1196fe/027e9529af2b06fe7b4f47e507a787eb/ep.1.1677593055.m3u8",
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
