// Explicit parameter types and initialization follow Development Standard §7.
// ignore_for_file: prefer_initializing_formals

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../domain/location_models.dart';
import '../application/location_search.dart';
import '../application/map_workspace.dart';
import 'map_view_model.dart';
import 'coordinate_dialog.dart';
import 'save_location_dialog.dart';
import 'grouped_map_layer.dart';

class MapLocationPage extends StatefulWidget {
  final LocationCoordinator locations;
  final MapLayerHost layerHost;
  final MapWorkspace workspace;
  final void Function(ValidLocationReference) onAnalysis;
  final void Function(ValidLocationReference, ValidLocationReference)
  onComparison;
  final void Function(MapLayerIntent) onLayerSelected;
  final LocationSearch search;
  final bool showTiles;
  final void Function(String, GeographicPoint, GeographicPoint)? onViewport;
  final ValueNotifier<GeographicPoint?>? layerFocus;
  final Widget? detailAction;
  const MapLocationPage({
    required LocationCoordinator locations,
    required MapLayerHost layerHost,
    required MapWorkspace workspace,
    required void Function(ValidLocationReference) onAnalysis,
    required void Function(ValidLocationReference, ValidLocationReference)
    onComparison,
    required void Function(MapLayerIntent) onLayerSelected,
    required LocationSearch search,
    bool showTiles = true,
    void Function(String, GeographicPoint, GeographicPoint)? onViewport,
    ValueNotifier<GeographicPoint?>? layerFocus,
    Widget? detailAction,
    super.key,
  }) : locations = locations,
       layerHost = layerHost,
       workspace = workspace,
       onAnalysis = onAnalysis,
       onComparison = onComparison,
       onLayerSelected = onLayerSelected,
       search = search,
       showTiles = showTiles,
       onViewport = onViewport,
       layerFocus = layerFocus,
       detailAction = detailAction;
  @override
  State<MapLocationPage> createState() {
    return _MapLocationPageState();
  }
}

class _MapLocationPageState extends State<MapLocationPage>
    with WidgetsBindingObserver {
  late final MapViewModel vm = MapViewModel(
    widget.locations,
    widget.search,
    widget.layerHost,
    widget.workspace,
    onAnalysis: widget.onAnalysis,
    onComparison: widget.onComparison,
    onLayerSelected: widget.onLayerSelected,
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
      case 'saved':
        return l10n.mapSavedOnline;
      case 'deleted':
        return l10n.mapDeletedOnline;
      case 'scopeUnavailable':
      case 'authenticationRequired':
      case 'unauthenticated':
        return l10n.mapAccountUnavailableSignInAgain;
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
    widget.layerFocus?.addListener(_focusLayer);
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
    widget.layerFocus?.removeListener(_focusLayer);
    vm.dispose();
    controller.dispose();
    super.dispose();
  }

  bool _mapReady = false;
  void _focusLayer() {
    final GeographicPoint? point = widget.layerFocus?.value;
    if (_mapReady && point != null) {
      controller.move(LatLng(point.latitude, point.longitude), 14);
    }
  }

  void _viewport(MapCamera camera) {
    final String version = DateTime.now().microsecondsSinceEpoch.toString();
    vm.viewport(version);
    final LatLngBounds bounds = camera.visibleBounds;
    widget.onViewport?.call(
      version,
      GeographicPoint(
        latitude: bounds.south,
        longitude: bounds.west.clamp(-180.0, 180.0),
      ),
      GeographicPoint(
        latitude: bounds.north,
        longitude: bounds.east.clamp(-180.0, 180.0),
      ),
    );
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
                    Text(l10n.mapSavedLocationsUnavailable),
                  if (vm.saved is SavedLocationsAvailable &&
                      (vm.saved as SavedLocationsAvailable).locations.isEmpty)
                    Text(l10n.mapNoSavedLocations),
                  for (final saved in vm.savedRows)
                    ListTile(
                      title: Text(saved.name),
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
                    child: Text(l10n.mapRetryLoading),
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
                  fontFamily: 'SourceSansPro',
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
                    _mapWorkspace(extraHeight),
                    if (vm.message != null)
                      Semantics(
                        liveRegion: true,
                        child: Text(message(vm.message!)),
                      ),
                    if (widget.detailAction != null) widget.detailAction!,
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

  String _locationTitle(ValidLocationReference location) {
    final String name = location.displayName?.trim() ?? '';
    if (name.isNotEmpty) {
      return name;
    }
    return l10n.mapSelectedLocation;
  }

  String _coordinates(ValidLocationReference location) {
    return '${location.point.latitude.toStringAsFixed(5)}, ${location.point.longitude.toStringAsFixed(5)}';
  }

  Widget _locationHeader(ValidLocationReference? location) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF2FF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.place_outlined, color: Color(0xFF155EEF)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                location == null
                    ? l10n.mapSelectALocation
                    : _locationTitle(location),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (location != null) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  _coordinates(location),
                  style: const TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _locationActions(ValidLocationReference location) {
    final Widget analyse = FilledButton.icon(
      style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
      onPressed: vm.analyze,
      icon: const Icon(Icons.analytics_outlined, size: 20),
      label: Text(
        l10n.mapViewFullAnalysis,
        style: const TextStyle(fontFamily: 'SourceSansPro'),
      ),
    );
    final Widget save = OutlinedButton.icon(
      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
      onPressed: vm.busy
          ? null
          : () {
              saveLocation(location);
            },
      icon: const Icon(Icons.bookmark_add_outlined, size: 20),
      label: Text(l10n.mapSaveLocation),
    );
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double scale = MediaQuery.textScalerOf(context).scale(14) / 14;
        if (constraints.maxWidth < 300 || scale > 1.3) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[analyse, const SizedBox(height: 8), save],
          );
        }
        return Row(
          children: <Widget>[
            Expanded(flex: 3, child: analyse),
            const SizedBox(width: 10),
            Expanded(flex: 2, child: save),
          ],
        );
      },
    );
  }

  Widget _comparisonLocation(LocationRole role) {
    final ValidLocationReference? location = vm.read(role);
    final String label;
    if (role == LocationRole.locationA) {
      label = l10n.mapLocationA;
    } else {
      label = l10n.mapLocationB;
    }
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.place_outlined, size: 20, color: Color(0xFF155EEF)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '$label: ${location == null ? l10n.mapNotSelected : _locationTitle(location)}',
                ),
                if (location != null)
                  Text(
                    _coordinates(location),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF667085),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailCard(ValidLocationReference? location) {
    return Flexible(
      flex: 2,
      child: Material(
        key: const ValueKey('map-location-detail-card'),
        color: Colors.white,
        elevation: 8,
        shadowColor: const Color(0x26000000),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (vm.compare) ...<Widget>[
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      for (final LocationRole role in <LocationRole>[
                        LocationRole.locationA,
                        LocationRole.locationB,
                      ])
                        ChoiceChip(
                          label: Text(
                            role == LocationRole.locationA
                                ? l10n.mapLocationA
                                : l10n.mapLocationB,
                          ),
                          selected: vm.role == role,
                          onSelected: (bool selected) {
                            vm.setRole(role);
                          },
                        ),
                      IconButton(
                        tooltip: l10n.mapSwapAB,
                        onPressed: vm.swap,
                        icon: const Icon(Icons.swap_horiz),
                      ),
                    ],
                  ),
                  _comparisonLocation(LocationRole.locationA),
                  _comparisonLocation(LocationRole.locationB),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                      onPressed:
                          vm.read(LocationRole.locationA) != null &&
                              vm.read(LocationRole.locationB) != null
                          ? vm.comparison
                          : null,
                      child: Text(l10n.mapViewComparison),
                    ),
                  ),
                ] else ...<Widget>[
                  _locationHeader(location),
                  if (location != null) ...<Widget>[
                    const SizedBox(height: 16),
                    _locationActions(location),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: <Widget>[
                        TextButton.icon(
                          onPressed: () {
                            chooseComparisonRole(location);
                          },
                          icon: const Icon(Icons.compare_arrows, size: 18),
                          label: Text(l10n.mapStartComparison),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              vm.expanded = !vm.expanded;
                            });
                          },
                          icon: Icon(
                            vm.expanded ? Icons.expand_less : Icons.expand_more,
                            size: 18,
                          ),
                          label: Text(
                            vm.expanded
                                ? l10n.mapHideSummary
                                : l10n.mapShowSummary,
                          ),
                        ),
                      ],
                    ),
                    if (vm.expanded) ...<Widget>[
                      const SizedBox(height: 12),
                      for (final String name in <String>[
                        l10n.mapSafetyIndex,
                        l10n.mapCostOfLivingIndex,
                        l10n.mapNearbyFacilities2Km,
                        l10n.mapPublicTransportation15Km,
                        l10n.mapInfrastructure,
                      ])
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                l10n.mapSummaryUnavailable,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF667085),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _toolbarButton(
    String label,
    IconData icon,
    VoidCallback onPressed, {
    bool selected = false,
  }) {
    return IconButton(
      tooltip: label,
      isSelected: selected,
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        foregroundColor: const Color(0xFF344054),
        backgroundColor: selected
            ? const Color(0xFFEAF2FF)
            : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 22),
      selectedIcon: Icon(icon, size: 22, color: const Color(0xFF155EEF)),
    );
  }

  Widget _mapWorkspace(double extraHeight) {
    return Expanded(
      flex: 3,
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
              onMapReady: () {
                _mapReady = true;
                _focusLayer();
                _viewport(controller.camera);
              },
              onPositionChanged: (MapCamera camera, bool gesture) {
                _viewport(camera);
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
                ],
              ),
              GroupedMapLayer(
                items: vm.layerItems,
                controller: controller,
                onSelected: (MapLayerIntent intent) {
                  widget.onLayerSelected(intent);
                },
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
            right: 88,
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
            top: 82 + extraHeight,
            bottom: 36,
            child: SingleChildScrollView(
              child: Material(
                elevation: 4,
                shadowColor: const Color(0x26000000),
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      _toolbarButton(
                        l10n.mapLayers,
                        Icons.layers_outlined,
                        toggleLayers,
                        selected: vm.layerVisible,
                      ),
                      _toolbarButton(
                        l10n.mapSaved,
                        Icons.bookmarks_outlined,
                        savedLocations,
                      ),
                      const SizedBox(width: 32, child: Divider(height: 8)),
                      _toolbarButton(
                        l10n.mapRefresh,
                        Icons.refresh,
                        vm.refresh,
                      ),
                      _toolbarButton(l10n.mapClear, Icons.deselect, vm.clear),
                    ],
                  ),
                ),
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
