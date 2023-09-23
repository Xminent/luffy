import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:luffy/screens/login_mobile.dart";
import "package:luffy/screens/login_windows.dart";

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return const LoginWindowsScreen();
    }

    return const LoginMobileScreen();
  }
}
