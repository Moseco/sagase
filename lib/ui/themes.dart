import 'package:flutter/material.dart';
import 'package:stacked_services/stacked_services.dart';

ThemeData getDarkTheme(bool useJapaneseSerifFont) {
  return ThemeData(
    brightness: Brightness.dark,
    colorSchemeSeed: Colors.deepPurple,
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Colors.white,
    ),
    checkboxTheme: CheckboxThemeData(
      checkColor: MaterialStateProperty.all(Colors.white),
      fillColor: MaterialStateProperty.resolveWith(
        (states) =>
            states.contains(MaterialState.selected) ? Colors.deepPurple : null,
      ),
    ),
    appBarTheme: const AppBarTheme(color: Colors.deepPurple),
    fontFamily: _getFontName(useJapaneseSerifFont),
    useMaterial3: false,
  );
}

ThemeData getLightTheme(bool useJapaneseSerifFont) {
  return ThemeData(
    brightness: Brightness.light,
    colorSchemeSeed: Colors.deepPurple,
    scaffoldBackgroundColor: const Color(0xFFF0F0F0),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Colors.black,
    ),
    checkboxTheme: CheckboxThemeData(
      checkColor: MaterialStateProperty.all(Colors.white),
      fillColor: MaterialStateProperty.resolveWith(
        (states) =>
            states.contains(MaterialState.selected) ? Colors.deepPurple : null,
      ),
    ),
    appBarTheme: const AppBarTheme(color: Colors.deepPurple),
    fontFamily: _getFontName(useJapaneseSerifFont),
    useMaterial3: false,
  );
}

String _getFontName(bool useJapaneseSerifFont) {
  return useJapaneseSerifFont ? 'NotoSansWithSerifJP' : 'NotoSansJP';
}

SnackbarConfig getSnackbarConfig() => SnackbarConfig(
      borderRadius: 8,
      backgroundColor: const Color(0xFF323232),
    );
