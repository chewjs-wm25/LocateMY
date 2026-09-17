import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

import '../domain/location_models.dart';

class CoordinateDialog extends StatefulWidget {
  const CoordinateDialog({super.key});
  @override
  State<CoordinateDialog> createState() {
    return _CoordinateDialogState();
  }
}

class _CoordinateDialogState extends State<CoordinateDialog> {
  final TextEditingController latitude = TextEditingController();
  final TextEditingController longitude = TextEditingController();
  final FocusNode latFocus = FocusNode();
  final FocusNode lonFocus = FocusNode();
  String? latError;
  String? lonError;
  AppLocalizations get l10n {
    return AppLocalizations.of(context) ??
        lookupAppLocalizations(Localizations.localeOf(context));
  }

  @override
  void dispose() {
    latitude.dispose();
    longitude.dispose();
    latFocus.dispose();
    lonFocus.dispose();
    super.dispose();
  }

  void select() {
    final double? lat = double.tryParse(latitude.text);
    final double? lon = double.tryParse(longitude.text);
    final String? newLatError = _latitudeError(lat);
    final String? newLonError = _longitudeError(lon);
    setState(() {
      latError = newLatError;
      lonError = newLonError;
    });
    if (latError != null) {
      latFocus.requestFocus();
      return;
    }
    if (lonError != null) {
      lonFocus.requestFocus();
      return;
    }
    Navigator.pop(context, GeographicPoint(latitude: lat!, longitude: lon!));
  }

  String? _latitudeError(double? value) {
    if (value == null || !value.isFinite || value < -90 || value > 90) {
      return l10n.mapLatitudeMustBeBetween90And;
    }
    return null;
  }

  String? _longitudeError(double? value) {
    if (value == null || !value.isFinite || value < -180 || value > 180) {
      return l10n.mapLongitudeMustBeBetween180And;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(l10n.mapEnterCoordinates),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: latitude,
              focusNode: latFocus,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: InputDecoration(
                labelText: l10n.mapLatitude,
                errorText: latError,
                errorMaxLines: 3,
              ),
            ),
            TextField(
              controller: longitude,
              focusNode: lonFocus,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: InputDecoration(
                labelText: l10n.mapLongitude,
                errorText: lonError,
                errorMaxLines: 3,
              ),
              onSubmitted: (_) => select(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.mapCancel),
        ),
        FilledButton(onPressed: select, child: Text(l10n.mapSelect)),
      ],
    );
  }
}
