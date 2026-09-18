import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_localizations.dart';

final class LanguageController extends ChangeNotifier {
  static const preferenceKey = 'locatemy.language';
  late final SharedPreferences? _preferences;
  late Locale _locale;
  Future<bool>? _pendingSave;

  LanguageController({SharedPreferences? preferences}) {
    _preferences = preferences;
    final Object? savedLanguage = preferences?.get(preferenceKey);
    if (savedLanguage == 'zh') {
      _setLocale('zh');
    } else {
      _setLocale('en');
    }
  }

  Locale get locale {
    return _locale;
  }

  Future<bool> select(String languageCode) async {
    _validateLanguageCode(languageCode);
    _setLocale(languageCode);
    notifyListeners();

    if (_preferences == null) {
      return true;
    }
    return _savePreference(languageCode);
  }

  void _setLocale(String languageCode) {
    _locale = Locale(languageCode);
  }

  void _validateLanguageCode(String languageCode) {
    final isSupported = languageCode == 'zh' || languageCode == 'en';
    if (!isSupported) {
      throw ArgumentError.value(languageCode, 'languageCode');
    }
  }

  Future<bool> _savePreference(String languageCode) {
    final previousSave = _pendingSave;
    final currentSave = _saveAfter(previousSave, languageCode);
    _pendingSave = currentSave;
    return currentSave;
  }

  Future<bool> _saveAfter(
    Future<bool>? previousSave,
    String languageCode,
  ) async {
    if (previousSave != null) {
      await previousSave;
    }

    try {
      return await _preferences!.setString(preferenceKey, languageCode);
    } catch (_) {
      return false;
    }
  }
}

final class LanguageButton extends StatelessWidget {
  const LanguageButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const ValueKey('language-switch'),
      tooltip: AppLocalizations.of(context)!.language,
      icon: const Icon(Icons.language),
      onPressed: () async {
        final controller = context.read<LanguageController>();
        final nextLanguage = controller.locale.languageCode == 'zh'
            ? 'en'
            : 'zh';
        final saved = await controller.select(nextLanguage);
        if (!saved && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                lookupAppLocalizations(controller.locale).languageSaveFailed,
              ),
            ),
          );
        }
      },
    );
  }
}
