import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../widgets/bento_card.dart';
import '../../widgets/status_badge.dart';
import '../../models/property_inspection.dart';
import '../../providers/property_provider.dart';
import '../../generated/app_localizations.dart';
import './add_property_screen.dart';

class PropertyDetailScreen extends StatelessWidget {
  final PropertyInspection inspection;

  const PropertyDetailScreen({super.key, required this.inspection});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    // Use Selector to rebuild only when this specific inspection changes
    return Selector<PropertyProvider, PropertyInspection>(
      selector: (_, provider) => provider.inspections.firstWhere(
        (i) => i.id == inspection.id,
        orElse: () => inspection,
      ),
      builder: (context, currentInspection, child) {
        return Scaffold(
          backgroundColor: AppColors.backgroundLight,
          appBar: AppBar(
            title: Text(currentInspection.name),
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: AppColors.textPrimaryLight,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddPropertyScreen(existingInspection: currentInspection),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                onPressed: () => _showDeleteConfirmation(context, currentInspection.id),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Flood History Warning Banner
                if (currentInspection.hasFloodHistory) ...[
                  _buildFloodWarningBanner(context),
                  const SizedBox(height: 16),
                ],

                // Hero Photo / Summary Card
                _buildHeroCard(context, currentInspection, l10n),
                const SizedBox(height: 16),
                
                // Location & Map Card
                _buildLocationCard(context, currentInspection, l10n),
                const SizedBox(height: 16),
                
                // Risk Summary Row
                Row(
                  children: [
                    Expanded(child: _buildSecurityCard(context, currentInspection, l10n)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildFloodRiskCard(context, currentInspection, l10n)),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Monsoon Checklist
                _buildChecklistCard(context, currentInspection, l10n),
                const SizedBox(height: 16),

                // Property Photos
                if (currentInspection.photos.isNotEmpty) ...[
                  _buildPhotoGallery(context, currentInspection),
                  const SizedBox(height: 16),
                ],
                
                // Notes
                if (currentInspection.notes.isNotEmpty) _buildNotesCard(context, currentInspection, l10n),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloodWarningBanner(BuildContext context) {
    return BentoCard(
      backgroundColor: AppColors.dangerContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: const Row(
        children: [
          Icon(Icons.warning_rounded, color: AppColors.danger, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CRITICAL FLOOD ALERT',
                  style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'Real-world flood evidence was observed during inspection or reported by locals.',
                  style: TextStyle(color: AppColors.danger, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Property?'),
        content: const Text('This property will be moved to the recycle bin. You can restore it later.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Provider.of<PropertyProvider>(context, listen: false).deleteInspection(id);
              Navigator.pop(context); // Pop dialog
              Navigator.pop(context); // Pop detail screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Moved to recycle bin')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, PropertyInspection inspection, AppLocalizations l10n) {
    return BentoCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (inspection.photos.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.network(
                'https://picsum.photos/seed/${inspection.id}_${inspection.mainPhotoIndex}/600/400',
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  width: double.infinity,
                  color: AppColors.surfaceSubLight,
                  child: const Icon(Icons.image, size: 60, color: AppColors.textMutedDark),
                ),
              ),
            )
          else
            Container(
              height: 120,
              width: double.infinity,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                color: AppColors.primaryContainer,
              ),
              child: const Icon(Icons.home_work_rounded, size: 48, color: AppColors.primaryBase),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RM ${inspection.price.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryBase),
                      ),
                      Text(
                        inspection.address,
                        style: TextStyle(color: AppColors.textSecondaryLight),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Text(
                      l10n.overallSafetyIndex,
                      style: const TextStyle(fontSize: 10, color: AppColors.textMutedDark),
                    ),
                    const SizedBox(height: 4),
                    StatusBadge(
                      label: inspection.rating.toStringAsFixed(1),
                      type: inspection.rating >= 4 ? StatusType.success : StatusType.warning,
                      icon: Icons.star,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(BuildContext context, PropertyInspection inspection, AppLocalizations l10n) {
    return BentoCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(l10n.locationSelection, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          if (inspection.latitude != null && inspection.longitude != null)
            SizedBox(
              height: 180,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(inspection.latitude!, inspection.longitude!),
                    initialZoom: 15,
                    interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c', 'd'],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(inspection.latitude!, inspection.longitude!),
                          child: const Icon(Icons.location_on, color: AppColors.danger, size: 40),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard(BuildContext context, PropertyInspection inspection, AppLocalizations l10n) {
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.securityScore, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
          const SizedBox(height: 8),
          Text(
            inspection.securityScore?.toStringAsFixed(1) ?? 'N/A',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.success),
          ),
          if (inspection.policeDistrict != null)
            Text(
              inspection.policeDistrict!,
              style: const TextStyle(fontSize: 10, color: AppColors.textMutedDark),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  Widget _buildFloodRiskCard(BuildContext context, PropertyInspection inspection, AppLocalizations l10n) {
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Flood Research', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
          const SizedBox(height: 8),
          StatusBadge(
            label: inspection.hasFloodHistory ? 'Has History' : 'No History',
            type: inspection.hasFloodHistory ? StatusType.danger : StatusType.success,
            icon: Icons.history_edu_rounded,
          ),
          const SizedBox(height: 4),
          const Text(
            'Based on local research',
            style: TextStyle(fontSize: 10, color: AppColors.textMutedDark),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistCard(BuildContext context, PropertyInspection inspection, AppLocalizations l10n) {
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.monsoonChecklist, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildChecklistItem(l10n.drainage, inspection.monsoonChecklist['drainage_score'] ?? 0),
          _buildChecklistItem(l10n.waterproofing, inspection.monsoonChecklist['waterproofing_score'] ?? 0),
          _buildChecklistItem(l10n.humidity, inspection.monsoonChecklist['humidity_score'] ?? 0),
          _buildChecklistItem(l10n.lighting, inspection.monsoonChecklist['lighting_score'] ?? 0),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(String label, int score) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Row(
            children: List.generate(5, (index) => Icon(
              index < score ? Icons.star : Icons.star_border,
              size: 16,
              color: Colors.amber,
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGallery(BuildContext context, PropertyInspection inspection) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Property Photos',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: inspection.photos.length,
            itemBuilder: (context, index) {
              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    'https://picsum.photos/seed/${inspection.id}_$index/400/300',
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: AppColors.surfaceSubLight,
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    },
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.surfaceSubLight,
                      child: const Icon(Icons.broken_image, color: AppColors.textMutedDark),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNotesCard(BuildContext context, PropertyInspection inspection, AppLocalizations l10n) {
    return BentoCard(
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(inspection.notes, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
