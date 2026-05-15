import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    colorSchemeSeed: Colors.indigo,
    brightness: Brightness.light,
    cardTheme: const CardThemeData(margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12)),
  );
}
