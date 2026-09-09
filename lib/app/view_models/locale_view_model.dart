import 'package:flutter/material.dart';

class LocaleViewModel extends ChangeNotifier {
  Locale _locale = const Locale('zh'); // Default to Chinese as per original UI

  Locale get locale => _locale;

  static const List<Map<String, dynamic>> supportedLocales = [
    {'locale': Locale('en'), 'name': 'English'},
    {'locale': Locale('zh'), 'name': '中文'},
  ];

  void setLocale(Locale locale) {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
  }

  void toggleLocale() {
    if (_locale.languageCode == 'zh') {
      _locale = const Locale('en');
    } else {
      _locale = const Locale('zh');
    }
    notifyListeners();
  }
}
