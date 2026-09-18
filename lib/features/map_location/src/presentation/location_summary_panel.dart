

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../application/location_summary_reader.dart';
import '../domain/location_models.dart';

final class LocationSummaryPanel extends StatefulWidget {
  final LocationSummaryReader? reader;
  final ValidLocationReference location;
  const LocationSummaryPanel({
    required LocationSummaryReader? reader,
    required ValidLocationReference location,
    super.key,
  }) : reader = reader,
       location = location;
  @override
  State<LocationSummaryPanel> createState() {
    return _LocationSummaryPanelState();
  }
}

final class _LocationSummaryPanelState extends State<LocationSummaryPanel> {
  late Future<List<LocationSummaryReading>> _readings = _load();
  Future<List<LocationSummaryReading>> _load() {
    return widget.reader?.read(
          widget.location,
          DateUtils.dateOnly(DateTime.now()),
        ) ??
        Future<List<LocationSummaryReading>>.value(<LocationSummaryReading>[]);
  }

  @override
  void didUpdateWidget(LocationSummaryPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reader != oldWidget.reader ||
        widget.location.point != oldWidget.location.point) {
      _readings = _load();
    }
  }

  String _title(AppLocalizations strings, LocationSummaryMetric metric) {
    switch (metric) {
      case LocationSummaryMetric.safety:
        return strings.mapSafetyIndex;
      case LocationSummaryMetric.cost:
        return strings.mapCostOfLivingIndex;
      case LocationSummaryMetric.facilities:
        return strings.mapNearbyFacilities2Km;
      case LocationSummaryMetric.transportation:
        return strings.mapPublicTransportation15Km;
      case LocationSummaryMetric.infrastructure:
        return strings.mapInfrastructure;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context)!;
    final bool zh = Localizations.localeOf(context).languageCode == 'zh';
    return FutureBuilder<List<LocationSummaryReading>>(
      future: _readings,
      builder:
          (
            BuildContext context,
            AsyncSnapshot<List<LocationSummaryReading>> snapshot,
          ) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final List<Widget> rows = <Widget>[];
            bool unavailable = snapshot.hasError;
            for (final LocationSummaryMetric metric
                in LocationSummaryMetric.values) {
              String? value;
              for (final LocationSummaryReading reading
                  in snapshot.data ?? <LocationSummaryReading>[]) {
                if (reading.metric == metric) {
                  value = zh ? reading.chinese : reading.english;
                  break;
                }
              }
              if (value == null) {
                unavailable = true;
              }
              rows.add(
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        _title(strings, metric),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        value ?? strings.mapSummaryUnavailable,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF667085),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (unavailable && widget.reader != null) {
              rows.add(
                TextButton(
                  onPressed: () {
                    setState(() {
                      _readings = _load();
                    });
                  },
                  child: Text(zh ? '重试摘要' : 'Retry summary'),
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: rows,
            );
          },
    );
  }
}
