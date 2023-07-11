import "package:flutter/material.dart";
import "package:flutter/services.dart";

final lightTheme = ThemeData(
  appBarTheme: const AppBarTheme(
    systemOverlayStyle: SystemUiOverlayStyle.dark,
  ),
  colorScheme: const ColorScheme(
    brightness: Brightness.light,
    primary: Color.fromARGB(255, 230, 175, 65),
    onPrimary: Color.fromARGB(255, 28, 28, 30),
    secondary: Color.fromARGB(255, 230, 175, 65),
    onSecondary: Color.fromARGB(255, 28, 28, 30),
    error: Color.fromARGB(255, 255, 59, 48),
    onError: Color.fromARGB(255, 28, 28, 30),
    background: Color.fromARGB(255, 242, 242, 242),
    onBackground: Color.fromARGB(255, 28, 28, 30),
    surface: Color.fromARGB(255, 255, 255, 255),
    onSurface: Color.fromARGB(255, 28, 28, 30),
  ),
  dialogTheme: const DialogTheme(
    backgroundColor: Color.fromARGB(255, 255, 255, 255),
    titleTextStyle: TextStyle(
      color: Color.fromARGB(255, 28, 28, 30),
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
    contentTextStyle: TextStyle(
      color: Color.fromARGB(255, 28, 28, 30),
      fontSize: 16,
      fontWeight: FontWeight.w400,
    ),
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: Color.fromARGB(255, 230, 175, 65),
  ),
  tabBarTheme: const TabBarTheme(
    indicatorColor: Color.fromARGB(255, 230, 175, 65),
    labelColor: Color.fromARGB(255, 28, 28, 30),
  ),
);

final darkTheme = ThemeData(
  appBarTheme: const AppBarTheme(
    systemOverlayStyle: SystemUiOverlayStyle.light,
  ),
  colorScheme: const ColorScheme(
    brightness: Brightness.dark,
    primary: Color.fromARGB(255, 240, 185, 65),
    onPrimary: Color.fromARGB(255, 229, 229, 231),
    secondary: Color.fromARGB(255, 240, 185, 65),
    onSecondary: Color.fromARGB(255, 229, 229, 231),
    error: Color.fromARGB(255, 255, 69, 58),
    onError: Color.fromARGB(255, 229, 229, 231),
    background: Color.fromARGB(255, 1, 1, 1),
    onBackground: Color.fromARGB(255, 229, 229, 231),
    surface: Color.fromARGB(255, 18, 18, 18),
    onSurface: Color.fromARGB(255, 229, 229, 231),
  ),
  dialogTheme: const DialogTheme(
    backgroundColor: Color.fromARGB(255, 18, 18, 18),
    titleTextStyle: TextStyle(
      color: Color.fromARGB(255, 229, 229, 231),
    ),
    contentTextStyle: TextStyle(
      color: Color.fromARGB(255, 229, 229, 231),
    ),
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: Color.fromARGB(255, 240, 185, 65),
  ),
  tabBarTheme: const TabBarTheme(
    indicatorColor: Color.fromARGB(255, 240, 185, 65),
    labelColor: Color.fromARGB(255, 229, 229, 231),
  ),
);
