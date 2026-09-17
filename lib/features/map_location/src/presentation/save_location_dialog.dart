// Explicit parameter types and initialization follow Development Standard §7.
// ignore_for_file: prefer_initializing_formals

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

class SaveLocationDialog extends StatefulWidget {
  const SaveLocationDialog({String? initialName, super.key})
    : initialName = initialName;
  final String? initialName;
  @override
  State<SaveLocationDialog> createState() {
    return _SaveLocationDialogState();
  }
}

class _SaveLocationDialogState extends State<SaveLocationDialog> {
  late final TextEditingController name = TextEditingController(
    text: widget.initialName,
  );
  final FocusNode focus = FocusNode();
  String? error;
  AppLocalizations get l10n {
    return AppLocalizations.of(context) ??
        lookupAppLocalizations(Localizations.localeOf(context));
  }

  void save() {
    final String value = name.text.trim();
    if (value.isEmpty || value.runes.length > 120) {
      setState(() {
        error = l10n.mapNameMustContain1120Characters;
      });
      focus.requestFocus();
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  void dispose() {
    name.dispose();
    focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(l10n.mapSaveLocation),
      content: SingleChildScrollView(
        child: TextField(
          controller: name,
          focusNode: focus,
          maxLength: 120,
          decoration: InputDecoration(
            labelText: l10n.mapName,
            errorText: error,
            errorMaxLines: 3,
          ),
          onSubmitted: (_) => save(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.mapCancel),
        ),
        TextButton(onPressed: save, child: Text(l10n.mapSave)),
      ],
    );
  }
}
