import 'package:flutter/material.dart';

ThemeData locateMyTheme() => ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff155eef)),
  useMaterial3: true,
  scaffoldBackgroundColor: const Color(0xfff7f9f8),
  cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    border: OutlineInputBorder(),
  ),
);
