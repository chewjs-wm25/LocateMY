// Explicit parameter types and initialization follow Development Standard §7.
// ignore_for_file: prefer_initializing_formals

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app/application_shell.dart';
import '../domain/location_models.dart';
import '../domain/location_intents.dart';
import '../application/location_search.dart';
import '../application/map_workspace.dart';
import 'map_view_model.dart';
import 'coordinate_dialog.dart';
import 'save_location_dialog.dart';

class MapLocationPage extends StatefulWidget {
  final LocationCoordinator locations;
  final MapLayerHost layerHost;
  final MapWorkspace workspace;
  final ApplicationShell applicationShell;
  final LocationSearch search;
  final bool showTiles;
  const MapLocationPage({
    required LocationCoordinator locations,
    required MapLayerHost layerHost,
    required MapWorkspace workspace,
    required ApplicationShell applicationShell,
    required LocationSearch search,
    bool showTiles = true,
    super.key,
  }) : locations = locations,
       layerHost = layerHost,
       workspace = workspace,
       applicationShell = applicationShell,
       search = search,
       showTiles = showTiles;
  @override
  State<MapLocationPage> createState() {
    return _MapLocationPageState();
  }
}

class _MapLocationPageState extends State<MapLocationPage>
    with WidgetsBindingObserver {
  late final MapViewModel vm = MapViewModel(
    widget.locations,
    widget.applicationShell,
    widget.search,
    widget.layerHost,
    widget.workspace,
  );
  final MapController controller = MapController();
  AppLocalizations get l10n {
    return AppLocalizations.of(context) ??
        lookupAppLocalizations(Localizations.localeOf(context));
  }

  String message(String code) {
    switch (code) {
      case 'invalidCoordinate':
        return l10n.mapEnterAValidWGS84LatitudeAnd;
      case 'outsideMalaysia':
        return l10n.mapChooseAPointOnMalaysianLand;
      case 'sameComparisonPoint':
        return l10n.mapAAndBMustBeDifferent;
      case 'invalidName':
        return l10n.mapNameMustContain1120Characters;
      case 'invalidLocation':
        return l10n.mapSelectAValidatedLocationFirst;
      case 'offlineDeleteUnsupported':
        return l10n.mapDeletionRequiresAConnectionTheLocation;
      case 'permissionDenied':
        return l10n.mapPermissionDeniedSignInAgain;
      case 'conflict':
        return l10n.mapTheLocationChangedOnAnotherDevice;
      case 'notFound':
        return l10n.mapThisSavedLocationNoLongerExists;
      case 'queued':
        return l10n.mapQueuedOnThisDeviceNotSynchronized;
      case 'saved':
        return l10n.mapSavedAndSynchronized;
      case 'deleted':
        return l10n.mapDeletedAndSynchronized;
      case 'scopeUnavailable':
      case 'authenticationRequired':
      case 'unauthenticated':
        return l10n.mapAccountScopeUnavailableSignInAgain;
      case 'staleInput':
      case 'staleViewport':
        return l10n.mapThisRequestIsOutdatedSelectOr;
      default:
        return l10n.mapTemporarilyUnavailableTryAgain;
    }
  }

  String locationSummary(LocationRole role, ValidLocationReference location) {
    // Exhaustive enum matching makes a newly added role a compile-time error here.
    final String label = switch (role) {
      LocationRole.single => l10n.mapSelectedAnalysisLocation,
      LocationRole.locationA => l10n.mapLocationA,
      LocationRole.locationB => l10n.mapLocationB,
      LocationRole.property => l10n.mapPropertyLocation,
    };
    return l10n.mapLocationSummary(
      label,
      location.displayName ?? '',
      location.point.latitude.toStringAsFixed(5),
      location.point.longitude.toStringAsFixed(5),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      vm.refresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    vm.dispose();
    controller.dispose();
    super.dispose();
  }

  Future<void> coordinates() async {
    final GeographicPoint? point = await showDialog<GeographicPoint>(
      context: context,
      useRootNavigator: false,
      builder: (_) => const CoordinateDialog(),
    );
    if (point != null) {
      final bool selected = await vm.select(point);
      if (mounted && selected) {
        controller.move(LatLng(point.latitude, point.longitude), 13);
      }
    }
  }

  Future<void> selectCandidate(LocationSearchCandidate candidate) async {
    final bool selected = await vm.select(
      candidate.point,
      candidate.displayName,
    );
    if (mounted && selected) {
      controller.move(
        LatLng(candidate.point.latitude, candidate.point.longitude),
        13,
      );
    }
  }

  void toolbarAction(String action) {
    if (action == l10n.mapSaved) {
      savedLocations();
    } else if (action == l10n.mapRefresh) {
      vm.refresh();
    } else if (action == l10n.mapClear) {
      vm.clear();
    } else {
      toggleLayers();
    }
  }

  void toggleLayers() {
    setState(() => vm.layerVisible = !vm.layerVisible);
  }

  Future<void> saveLocation(ValidLocationReference location) async {
    final String? value = await showDialog<String>(
      context: context,
      useRootNavigator: false,
      builder: (_) => SaveLocationDialog(initialName: location.displayName),
    );
    if (value != null) {
      await vm.save(location, value);
    }
  }

  Future<void> chooseComparisonRole(ValidLocationReference location) async {
    final LocationRole? role = await showDialog<LocationRole>(
      context: context,
      useRootNavigator: false,
      builder: (c) => SimpleDialog(
        title: Text(l10n.mapSetCurrentLocationAs),
        children: [
          for (final r in [LocationRole.locationA, LocationRole.locationB])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(c, r),
              child: Text(
                r == LocationRole.locationA
                    ? l10n.mapLocationA
                    : l10n.mapLocationB,
              ),
            ),
        ],
      ),
    );
    if (role != null) {
      vm.mode(true);
      vm.setRole(role);
      await vm.select(location.point, location.displayName);
      vm.setRole(
        role == LocationRole.locationA
            ? LocationRole.locationB
            : LocationRole.locationA,
      );
    }
  }

  Future<void> savedLocations() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (c) => ListenableBuilder(
        listenable: vm,
        builder: (c, _) => SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.mapSavedLocations,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (vm.saved is SavedLocationsUnavailable)
                    Text(l10n.mapSavedLocationsUnavailableRetrySynchronization),
                  if (vm.saved is SavedLocationsAvailable &&
                      (vm.saved as SavedLocationsAvailable).locations.isEmpty)
                    Text(l10n.mapNoSavedLocations),
                  for (final saved in vm.savedRows)
                    ListTile(
                      title: Text(saved.name),
                      subtitle: Text(
                        saved.syncState == SavedLocationSyncState.synchronized
                            ? vm.saved is SavedLocationsUnavailable
                                  ? l10n.mapCachedRetrySynchronization
                                  : l10n.mapSynchronized
                            : l10n.mapQueuedNotSynchronized,
                      ),
                      onTap: () async {
                        Navigator.pop(c);
                        final bool selected = await vm.select(
                          saved.location.point,
                          saved.name,
                        );
                        if (mounted && selected) {
                          controller.move(
                            LatLng(
                              saved.location.point.latitude,
                              saved.location.point.longitude,
                            ),
                            13,
                          );
                        }
                      },
                      trailing: IconButton(
                        tooltip: l10n.mapDelete,
                        onPressed: vm.busy ? null : () => vm.remove(saved.id),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ),
                  TextButton(
                    onPressed: vm.busy ? null : vm.refresh,
                    child: Text(l10n.mapRetrySynchronization),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        final ValidLocationReference? location = vm.read(LocationRole.single);
        final double textScale =
            (MediaQuery.textScalerOf(context).scale(12) / 12).clamp(1.0, 2.0);
        final double extraHeight = 24 * (textScale - 1);
        final List<String> summaries = [];
        for (final LocationRole role in LocationRole.values) {
          final ValidLocationReference? selected = vm.read(role);
          if (selected != null) {
            summaries.add(locationSummary(role, selected));
          }
        }
        final String summary = summaries.join('; ');
        return Semantics(
          container: true,
          explicitChildNodes: true,
          label: summary.isEmpty ? l10n.mapNoLocationSelected : summary,
          child: Theme(
            data: Theme.of(context).copyWith(
              textTheme: Theme.of(context).textTheme
                  .apply(fontFamily: 'SourceSansPro'),
              chipTheme: Theme.of(context).chipTheme.copyWith(
                selectedColor: const Color(0xFFEAF2FF),
                backgroundColor: Colors.white,
                shape: const StadiumBorder(),
                side: const BorderSide(color: Color(0xFFD9E0EA)),
                showCheckmark: false,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF155EEF),
                ),
              ),
            ),
            child: Material(
              child: SafeArea(
                child: Column(
                  children: [
                    _mapWorkspace(textScale, extraHeight),
                    if (vm.message != null)
                      Semantics(
                        liveRegion: true,
                        child: Text(message(vm.message!)),
                      ),
                    _detailCard(location),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailCard(ValidLocationReference? location) {
    return Flexible(
      flex: 1,
      child: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 52,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9E0EA),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (vm.compare) ...[
                Wrap(
                  spacing: 8,
                  children: [
                    for (final role in [
                      LocationRole.locationA,
                      LocationRole.locationB,
                    ])
                      ChoiceChip(
                        label: Text(
                          '${role == LocationRole.locationA ? l10n.mapLocationA : l10n.mapLocationB}${vm.read(role) == null ? '' : ' ✓'}',
                        ),
                        selected: vm.role == role,
                        onSelected: (_) => vm.setRole(role),
                      ),
                    IconButton(
                      tooltip: l10n.mapSwapAB,
                      onPressed: vm.swap,
                      icon: const Icon(Icons.swap_horiz),
                    ),
                  ],
                ),
                for (final role in [
                  LocationRole.locationA,
                  LocationRole.locationB,
                ])
                  Text(
                    '${role == LocationRole.locationA ? 'A' : 'B'}: ${vm.read(role)?.displayName ?? vm.read(role)?.locationId ?? l10n.mapNotSelected}',
                  ),
                FilledButton(
                  onPressed:
                      vm.read(LocationRole.locationA) != null &&
                          vm.read(LocationRole.locationB) != null
                      ? vm.comparison
                      : null,
                  child: Text(l10n.mapViewComparison),
                ),
              ] else ...[
                Text(
                  location == null
                      ? l10n.mapSelectALocation
                      : location.displayName ??
                            '${location.point.latitude}, ${location.point.longitude}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (location != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.mapSelectedAnalysisLocation,
                    style: const TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF2FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      l10n.mapPersonalizedSuitabilityUnavailable,
                      style: const TextStyle(color: Color(0xFF155EEF)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 7,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: vm.analyze,
                          child: Text(l10n.mapViewFullAnalysis),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 4,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: const BorderSide(color: Color(0xFFD9E0EA)),
                          ),
                          onPressed: vm.busy
                              ? null
                              : () => saveLocation(location),
                          child: Text(l10n.mapSaveLocation),
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => chooseComparisonRole(location),
                    child: Text(l10n.mapStartComparison),
                  ),
                  TextButton(
                    onPressed: () => setState(() => vm.expanded = !vm.expanded),
                    child: Text(
                      vm.expanded ? l10n.mapHideSummary : l10n.mapShowSummary,
                    ),
                  ),
                  if (vm.expanded)
                    for (final name in [
                      l10n.mapSafetyIndex,
                      l10n.mapCostOfLivingIndex,
                      l10n.mapNearbyFacilities2Km,
                      l10n.mapPublicTransportation15Km,
                      l10n.mapInfrastructure,
                    ])
                      Text(
                        '$name: ${l10n.mapProviderNotConnectedDateSourceUnavailable}',
                      ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _mapWorkspace(double textScale, double extraHeight) {
    return Expanded(
      flex: 2,
      child: Stack(
        children: [
          FlutterMap(
            mapController: controller,
            options: MapOptions(
              initialCenter: const LatLng(4.2, 109.5),
              initialZoom: 4.5,
              onTap: (_, p) => vm.select(
                GeographicPoint(latitude: p.latitude, longitude: p.longitude),
              ),
              onLongPress: (_, p) => vm.longPress(
                GeographicPoint(latitude: p.latitude, longitude: p.longitude),
              ),
              onPositionChanged: (_, gesture) {
                if (gesture) {
                  vm.viewport(DateTime.now().microsecondsSinceEpoch.toString());
                }
              },
            ),
            children: [
              if (widget.showTiles)
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.locatemy.app',
                ),
              MarkerLayer(
                markers: [
                  for (final role in LocationRole.values)
                    if (vm.read(role) != null)
                      Marker(
                        point: LatLng(
                          vm.read(role)!.point.latitude,
                          vm.read(role)!.point.longitude,
                        ),
                        child: Semantics(
                          label: locationSummary(role, vm.read(role)!),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF155EEF),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFEAF2FF),
                                width: 8,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                role == LocationRole.locationA
                                    ? 'A'
                                    : role == LocationRole.locationB
                                    ? 'B'
                                    : '•',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  for (final item in vm.layerItems)
                    Marker(
                      point: LatLng(item.point.latitude, item.point.longitude),
                      child: IconButton(
                        tooltip: l10n.mapLayerPoint(
                          item.point.latitude.toStringAsFixed(5),
                          item.point.longitude.toStringAsFixed(5),
                        ),
                        onPressed: () =>
                            vm.navigate(OpenMapLayerIntent(item.intent)),
                        icon: const Icon(Icons.place),
                      ),
                    ),
                ],
              ),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            top: 16,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(16),
              child: TextField(
                onChanged: vm.query,
                decoration: InputDecoration(
                  hintText: l10n.mapSearchPlacesInMalaysia,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    tooltip: l10n.mapEnterCoordinates,
                    onPressed: coordinates,
                    icon: const Icon(Icons.pin_drop_outlined),
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            top: 82 + extraHeight,
            child: Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text(l10n.mapSingle),
                  selected: !vm.compare,
                  onSelected: (_) => vm.mode(false),
                ),
                ChoiceChip(
                  label: Text(l10n.mapCompareLocations),
                  selected: vm.compare,
                  onSelected: (_) => vm.mode(true),
                ),
              ],
            ),
          ),
          Positioned(
            right: 16,
            top: 144 + extraHeight,
            bottom: 36,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (final action in [
                    l10n.mapLayers,
                    l10n.mapSaved,
                    l10n.mapRefresh,
                    l10n.mapClear,
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SizedBox(
                        width: 64 * textScale,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 48),
                          child: Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            child: TextButton(
                              style: TextButton.styleFrom(
                                minimumSize: const Size(0, 48),
                                padding: const EdgeInsets.all(12),
                              ),
                              onPressed: () => toolbarAction(action),
                              child: Text(
                                action,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (vm.searchOutcome != null)
            Positioned(
              left: 16,
              right: 90,
              top: 128,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (vm.searchOutcome is LocationSearchUnavailable)
                          ListTile(
                            title: Text(l10n.mapSearchUnavailableTryAgain),
                          ),
                        if (vm.searchOutcome is LocationSearchAvailable &&
                            (vm.searchOutcome as LocationSearchAvailable)
                                .candidates
                                .isEmpty)
                          ListTile(title: Text(l10n.mapNoPlacesFound)),
                        if (vm.searchOutcome is LocationSearchAvailable)
                          for (final candidate
                              in (vm.searchOutcome as LocationSearchAvailable)
                                  .candidates)
                            ListTile(
                              title: Text(candidate.displayName),
                              onTap: () => selectCandidate(candidate),
                            ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            left: 8,
            bottom: 0,
            child: Text(
              '© OpenStreetMap contributors',
              style: const TextStyle(
                fontSize: 11,
                backgroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
