import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_localizations.dart';

/// Device preference, independent of authentication and account data.
final class LanguageController extends ChangeNotifier {
  static const preferenceKey = 'locatemy.language';
  final SharedPreferences? _preferences;
  Locale _locale;
  Future<void>? _pendingSave;

  LanguageController({SharedPreferences? preferences})
    : _preferences = preferences,
      _locale = Locale(preferences?.get(preferenceKey) == 'en' ? 'en' : 'zh');

  Locale get locale => _locale;

  Future<bool> select(String languageCode) async {
    if (languageCode != 'zh' && languageCode != 'en') {
      throw ArgumentError.value(languageCode, 'languageCode');
    }
    _locale = Locale(languageCode);
    notifyListeners();
    if (_preferences == null) return true;
    var saved = true;
    _pendingSave = (_pendingSave ?? Future<void>.value()).then((_) async {
      try {
        saved = await _preferences.setString(preferenceKey, languageCode);
      } catch (_) {
        saved = false;
      }
    });
    await _pendingSave;
    return saved;
  }
}

final class LanguageScope extends InheritedNotifier<LanguageController> {
  const LanguageScope({
    required LanguageController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static LanguageController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LanguageScope>()!.notifier!;
}

final class LanguageButton extends StatelessWidget {
  const LanguageButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    key: const ValueKey('language-switch'),
    tooltip: AppLocalizations.of(context)!.language,
    icon: const Icon(Icons.language),
    onPressed: () async {
      final controller = LanguageScope.of(context);
      final saved = await controller.select(
        controller.locale.languageCode == 'zh' ? 'en' : 'zh',
      );
      if (!saved && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.languageSaveFailed),
          ),
        );
      }
    },
  );
}
