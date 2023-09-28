import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_inappwebview/flutter_inappwebview.dart";
import "package:luffy/auth.dart";
import "package:luffy/screens/home_tab.dart";
import "package:luffy/screens/login.dart";
import "package:luffy/scroll_behavior.dart";
import "package:luffy/theme.dart";
import "package:media_kit/media_kit.dart";
import "package:window_manager/window_manager.dart";

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
    await windowManager.ensureInitialized();
  }

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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ThemeData _lightTheme = lightTheme;
  final ThemeData _darkTheme = darkTheme;

  MaterialApp _buildMaterialApp({
    required bool isAuthenticated,
    required Widget home,
  }) {
    return MaterialApp(
      title: "Luffy",
      theme: _lightTheme,
      darkTheme: _darkTheme,
      home: home,
      debugShowCheckedModeBanner: false,
      scrollBehavior: MyCustomScrollBehavior(),
      routes: {
        "/home": (context) => const HomeTabScreen(),
        "/login": (context) => const LoginScreen(),
      },
    );
  }

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

        return _buildMaterialApp(
          isAuthenticated: true,
          home: const HomeTabScreen(),
        );
      },
    );
  }
}
