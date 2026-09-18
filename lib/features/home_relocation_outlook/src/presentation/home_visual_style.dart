import 'package:flutter/material.dart';


abstract final class HomeVisualStyle {
  static const primary = Color(0xFF155EEF);
  static const ink = Color(0xFF172033);
  static const muted = Color(0xFF667085);
  static const canvas = Color(0xFFF6F8FB);
  static const border = Color(0xFFD9E0EA);
  static const hero = Color(0xFF0B1F44);
  static const heroLabel = Color(0xFFAFCBFF);
  static const heroUnit = Color(0xFFC8D7F2);
  static const heroSuccess = Color(0xFF68D5AE);
  static const warning = Color(0xFFB76E00);

  static TextStyle text(
    double size, {
    Color color = ink,
    FontWeight weight = FontWeight.w400,
  }) {
    return TextStyle(
      fontFamily: 'SourceSansPro',
      fontSize: size,
      height: 1.35,
      color: color,
      fontWeight: weight,
    );
  }
}
