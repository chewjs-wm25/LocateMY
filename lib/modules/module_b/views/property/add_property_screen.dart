import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:locate_my/core/app_colors.dart';
import 'package:locate_my/shared/widgets/bento_card.dart';
import 'package:locate_my/shared/widgets/status_badge.dart';
import 'package:locate_my/shared/widgets/star_rating_selector.dart';
import 'package:locate_my/modules/module_b/view_models/property/property_view_model.dart';
import 'package:locate_my/modules/module_a/location_api.dart';
import 'package:locate_my/app/view_models/navigation_view_model.dart';
import 'package:locate_my/generated/app_localizations.dart';
import 'package:locate_my/modules/module_b/models/property/property_inspection.dart';

class AddPropertyScreen extends StatefulWidget {
  final PropertyInspection? existingInspection;

  const AddPropertyScreen({super.key, this.existingInspection});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _notesController;

  SavedLocation? _selectedSavedLocation;
  late Map<String, int> _monsoonChecklist;
  List<String> _selectedPhotos = [];
  int _mainPhotoIndex = 0;
  bool _hasFloodHistory = false;
  bool _isSubmitting = false;

  late MapController _previewMapController;
  late ScrollController _photoScrollController;

  @override
  void initState() {
    super.initState();
    _previewMapController = MapController();
    _photoScrollController = ScrollController();

    final propertyViewModel = Provider.of<PropertyViewModel>(
      context,
      listen: false,
    );
    final locationProvider = Provider.of<LocationViewModel>(
      context,
      listen: false,
    );

    if (widget.existingInspection != null) {
      // Editing mode
      final inspection = widget.existingInspection!;
      _nameController = TextEditingController(text: inspection.name);
      _priceController = TextEditingController(
        text: inspection.price.toString(),
      );
      _notesController = TextEditingController(text: inspection.notes);
      _hasFloodHistory = inspection.hasFloodHistory;
      _monsoonChecklist = Map.from(inspection.monsoonChecklist);
      _selectedPhotos = List.from(inspection.photos);
      _mainPhotoIndex = inspection.mainPhotoIndex;

      // Try to match saved location
      if (inspection.latitude != null && inspection.longitude != null) {
        try {
          _selectedSavedLocation = locationProvider.savedLocations.firstWhere(
            (loc) =>
                (loc.location.latitude - inspection.latitude!).abs() < 0.0001 &&
                (loc.location.longitude - inspection.longitude!).abs() < 0.0001,
          );
        } catch (_) {}
      }
    } else {
      // Initialize from draft
      _nameController = TextEditingController(
        text: propertyViewModel.draftName,
      );
      _priceController = TextEditingController(
        text: propertyViewModel.draftPrice,
      );
      _notesController = TextEditingController();
      _monsoonChecklist = Map.from(propertyViewModel.draftMonsoonChecklist);
      _selectedPhotos = []; // In a real app, we might draft photos too

      if (propertyViewModel.draftSavedLocationId != null) {
        try {
          _selectedSavedLocation = locationProvider.savedLocations.firstWhere(
            (loc) => loc.id == propertyViewModel.draftSavedLocationId,
          );
        } catch (_) {}
      }

      // Setup listeners to update draft
      _nameController.addListener(() {
        propertyViewModel.updateDraft(name: _nameController.text);
      });
      _priceController.addListener(() {
        propertyViewModel.updateDraft(price: _priceController.text);
      });
    }

    // Auto-select logic if draft is empty but map has a selection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.existingInspection == null &&
          _selectedSavedLocation == null &&
          locationProvider.selectedLocation != null) {
        try {
          final matched = locationProvider.savedLocations.firstWhere(
            (loc) =>
                (loc.location.latitude -
                            locationProvider.selectedLocation!.latitude)
                        .abs() <
                    0.0001 &&
                (loc.location.longitude -
                            locationProvider.selectedLocation!.longitude)
                        .abs() <
                    0.0001,
          );
          setState(() {
            _selectedSavedLocation = matched;
            propertyViewModel.updateDraft(savedLocationId: matched.id);
            _previewMapController.move(matched.location, 14);
          });
        } catch (_) {}
      } else if (_selectedSavedLocation != null) {
        _previewMapController.move(_selectedSavedLocation!.location, 14);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    _previewMapController.dispose();
    _photoScrollController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate() && _selectedSavedLocation != null) {
      setState(() => _isSubmitting = true);
      final provider = Provider.of<PropertyViewModel>(context, listen: false);

      // Calculate overall rating based on checklist
      double totalScore = 0;
      _monsoonChecklist.forEach((key, value) => totalScore += value);
      double avgRating = totalScore / _monsoonChecklist.length;

      if (widget.existingInspection != null) {
        // Update existing
        await provider.updateInspection(
          widget.existingInspection!.id,
          name: _nameController.text,
          address: _selectedSavedLocation!.name,
          price: double.tryParse(_priceController.text) ?? 0.0,
          rating: avgRating,
          notes: _notesController.text,
          hasFloodHistory: _hasFloodHistory,
          monsoonChecklist: _monsoonChecklist,
          photos: _selectedPhotos,
          mainPhotoIndex: _mainPhotoIndex,
          latitude: _selectedSavedLocation!.location.latitude,
          longitude: _selectedSavedLocation!.location.longitude,
        );
      } else {
        // Add new
        await provider.addInspection(
          name: _nameController.text,
          address: _selectedSavedLocation!.name,
          price: double.tryParse(_priceController.text) ?? 0.0,
          latitude: _selectedSavedLocation!.location.latitude,
          longitude: _selectedSavedLocation!.location.longitude,
          monsoonChecklist: _monsoonChecklist,
          rating: avgRating,
          notes: _notesController.text,
          photos: _selectedPhotos,
          mainPhotoIndex: _mainPhotoIndex,
          hasFloodHistory: _hasFloodHistory,
        );
        // Clear draft on success
        provider.clearDraft();
      }

      if (mounted) {
        setState(() => _isSubmitting = false);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingInspection != null
                  ? 'Property updated successfully'
                  : 'Property added successfully',
            ),
          ),
        );
      }
    } else if (_selectedSavedLocation == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a location')));
    }
  }

  void _goToMapToPick() {
    // Close analysis report drawer
    Provider.of<LocationViewModel>(
      context,
      listen: false,
    ).setAnalysisReportOpen(false);

    // Switch to Map Tab (Index 1)
    Provider.of<NavigationViewModel>(context, listen: false).setIndex(1);
    // Pop back to root (AppShell)
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locationProvider = Provider.of<LocationViewModel>(context);
    final propertyViewModel = Provider.of<PropertyViewModel>(
      context,
    ); // Listen for draft/loading state changes
    final savedLocations = locationProvider.savedLocations;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingInspection != null
              ? 'Edit Property'
              : l10n.addProperty,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimaryLight,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(l10n.propertyDetails),
              const SizedBox(height: 12),
              _buildBasicInfoForm(l10n),
              const SizedBox(height: 24),

              _buildSectionTitle(l10n.locationSelection),
              const SizedBox(height: 12),
              _buildLocationSelector(l10n, savedLocations),
              const SizedBox(height: 16),

              if (_selectedSavedLocation != null) ...[
                _buildMapPreview(),
                const SizedBox(height: 24),
                _buildSectionTitle(l10n.securityRiskAssessment),
                const SizedBox(height: 12),
                _buildRiskAssessmentBento(l10n),
                const SizedBox(height: 12),
                _buildFloodHistoryToggle(),
                const SizedBox(height: 24),
              ],

              _buildSectionTitle(l10n.monsoonChecklist),
              const SizedBox(height: 12),
              _buildChecklist(l10n),
              const SizedBox(height: 24),

              _buildSectionTitle('Property Photos'),
              const SizedBox(height: 12),
              _buildPhotoUploader(),
              const SizedBox(height: 24),

              _buildSectionTitle('Notes'),
              const SizedBox(height: 12),
              _buildNotesField(),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBaseAlternative,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          widget.existingInspection != null
                              ? 'Update Property'
                              : l10n.saveProperty,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimaryLight,
      ),
    );
  }

  Widget _buildBasicInfoForm(AppLocalizations l10n) {
    return BentoCard(
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: l10n.propertyName,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) => value!.isEmpty ? 'Please enter name' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _priceController,
            decoration: InputDecoration(
              labelText: l10n.price,
              prefixText: 'RM ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            keyboardType: TextInputType.number,
            validator: (value) => value!.isEmpty ? 'Please enter price' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSelector(
    AppLocalizations l10n,
    List<SavedLocation> savedLocations,
  ) {
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<SavedLocation>(
            value: _selectedSavedLocation,
            decoration: InputDecoration(
              labelText: l10n.selectSavedLocation,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: savedLocations.map((loc) {
              return DropdownMenuItem(
                value: loc,
                child: Text(loc.name, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                _selectedSavedLocation = val;
                if (val != null) {
                  _previewMapController.move(val.location, 14);
                  Provider.of<PropertyViewModel>(
                    context,
                    listen: false,
                  ).updateDraft(savedLocationId: val.id);
                }
              });
            },
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _goToMapToPick,
            icon: const Icon(Icons.map_outlined),
            label: Text(l10n.pickOnMap),
            style: TextButton.styleFrom(foregroundColor: AppColors.primaryBase),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPreview() {
    return BentoCard(
      height: 200,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: FlutterMap(
          mapController: _previewMapController,
          options: MapOptions(
            initialCenter:
                _selectedSavedLocation?.location ??
                const LatLng(3.1390, 101.6869),
            initialZoom: 14,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
            ),
            if (_selectedSavedLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedSavedLocation!.location,
                    alignment: Alignment.bottomCenter,
                    child: const Icon(
                      Icons.location_on,
                      color: AppColors.danger,
                      size: 40,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskAssessmentBento(AppLocalizations l10n) {
    // In a real app, these values would come from a preview call to the risk repository
    // based on _selectedSavedLocation. Using mock values that 'look' dynamic.
    final bool isSentul =
        _selectedSavedLocation?.name.contains('Sentul') ?? false;

    return Column(
      children: [
        BentoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.securityScore,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isSentul ? '7.8' : '8.5',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isSentul ? AppColors.warning : AppColors.success,
                    ),
                  ),
                  StatusBadge(
                    label: isSentul ? 'Moderate' : 'Safe',
                    type: isSentul ? StatusType.warning : StatusType.success,
                    icon: Icons.security,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        BentoCard(
          child: Row(
            children: [
              const Icon(
                Icons.local_police_outlined,
                color: AppColors.primaryBase,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.policeDistrict,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  Text(
                    isSentul ? 'Sentul District' : 'PJ District',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              StatusBadge(
                label: isSentul ? '5 Hazards nearby' : '0 Hazards nearby',
                type: isSentul ? StatusType.danger : StatusType.success,
                icon: isSentul
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_outline,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChecklist(AppLocalizations l10n) {
    return BentoCard(
      child: Column(
        children: [
          StarRatingSelector(
            label: l10n.drainage,
            rating: _monsoonChecklist['drainage_score'] ?? 3,
            onRatingChanged: (val) => _updateChecklist('drainage_score', val),
          ),
          const Divider(),
          StarRatingSelector(
            label: l10n.waterproofing,
            rating: _monsoonChecklist['waterproofing_score'] ?? 3,
            onRatingChanged: (val) =>
                _updateChecklist('waterproofing_score', val),
          ),
          const Divider(),
          StarRatingSelector(
            label: l10n.humidity,
            rating: _monsoonChecklist['humidity_score'] ?? 3,
            onRatingChanged: (val) => _updateChecklist('humidity_score', val),
          ),
          const Divider(),
          StarRatingSelector(
            label: l10n.lighting,
            rating: _monsoonChecklist['lighting_score'] ?? 3,
            onRatingChanged: (val) => _updateChecklist('lighting_score', val),
          ),
        ],
      ),
    );
  }

  void _updateChecklist(String key, int value) {
    setState(() {
      _monsoonChecklist[key] = value;
      Provider.of<PropertyViewModel>(
        context,
        listen: false,
      ).updateDraft(monsoonChecklist: _monsoonChecklist);
    });
  }

  Widget _buildPhotoUploader() {
    final l10n = AppLocalizations.of(context)!;
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selectedPhotos.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.tapToSetMainImage,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMutedDark,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Text(
                  l10n.totalPhotos(_selectedPhotos.length.toString()),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBase,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            RawScrollbar(
              controller: _photoScrollController,
              thumbColor: AppColors.primaryBase.withOpacity(0.3),
              radius: const Radius.circular(8),
              thickness: 4,
              thumbVisibility: true,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  height: 120,
                  child: ListView.builder(
                    controller: _photoScrollController,
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedPhotos.length,
                    itemBuilder: (context, index) {
                      final bool isMain = _mainPhotoIndex == index;
                      return Stack(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _mainPhotoIndex = index;
                              });
                            },
                            child: Container(
                              width: 100,
                              margin: const EdgeInsets.only(right: 8, top: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: AppColors.surfaceSubLight,
                                border: isMain
                                    ? Border.all(
                                        color: AppColors.primaryBase,
                                        width: 2,
                                      )
                                    : null,
                              ),
                              child: const Icon(
                                Icons.image,
                                color: AppColors.textMutedDark,
                              ),
                            ),
                          ),
                          if (isMain)
                            Positioned(
                              left: 4,
                              top: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBase,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  l10n.mainImage.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          Positioned(
                            right: 12,
                            top: 4,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedPhotos.removeAt(index);
                                  if (_mainPhotoIndex >=
                                      _selectedPhotos.length) {
                                    _mainPhotoIndex = 0;
                                  }
                                });
                              },
                              child: const CircleAvatar(
                                radius: 10,
                                backgroundColor: AppColors.danger,
                                child: Icon(
                                  Icons.close,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            if (_selectedPhotos.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.swipe_left_rounded,
                      size: 14,
                      color: AppColors.textMutedDark,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n.swipeForMore,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textMutedDark,
                      ),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: () {
                // Mock adding a photo
                setState(() {
                  _selectedPhotos.add(
                    'mock_photo_${_selectedPhotos.length + 1}',
                  );
                  // If it's the first photo, it's automatically the main one by default (_mainPhotoIndex = 0)
                });
              },
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Add Inspection Photo'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryBase,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloodHistoryToggle() {
    return BentoCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: SwitchListTile(
        title: const Text(
          'Local Flood Signs Observed',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        subtitle: const Text(
          'e.g. water marks on walls, neighbor reports',
          style: TextStyle(fontSize: 12),
        ),
        value: _hasFloodHistory,
        onChanged: (val) => setState(() => _hasFloodHistory = val),
        activeColor: AppColors.primaryBase,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildNotesField() {
    return BentoCard(
      child: TextFormField(
        controller: _notesController,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: 'Add any extra observations...',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
