import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';
import '../core/app_colors.dart';
import '../generated/app_localizations.dart';

class AnalysisLocationSelector extends StatelessWidget {
  const AnalysisLocationSelector({super.key});

  void _showLocationPicker(BuildContext context, bool isOrigin, String currentName) {
    final l10n = AppLocalizations.of(context)!;
    final locationProvider = context.read<LocationProvider>();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.selectSavedLocation, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (locationProvider.savedLocations.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(l10n.noSavedLocations),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: locationProvider.savedLocations.length,
                  itemBuilder: (context, index) {
                    final loc = locationProvider.savedLocations[index];
                    final bool isSelected = loc.name == currentName;
                    
                    return ListTile(
                      leading: Icon(
                        isSelected ? Icons.check_circle_rounded : Icons.bookmark, 
                        color: isSelected ? AppColors.success : AppColors.primaryBase
                      ),
                      title: Text(loc.name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      onTap: () {
                        if (locationProvider.mode == MapMode.comparison) {
                          if (isOrigin) {
                            locationProvider.setOriginLocation(loc.location, loc.name);
                          } else {
                            locationProvider.setDestinationLocation(loc.location, loc.name);
                          }
                        } else {
                          locationProvider.setSelectedLocation(loc.location, loc.name);
                        }
                        locationProvider.moveTo(loc.location);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locationProvider = Provider.of<LocationProvider>(context);
    final isComparison = locationProvider.mode == MapMode.comparison;

    if (isComparison) {
      final originName = locationProvider.originName ?? l10n.kl;
      final destName = locationProvider.destinationName ?? l10n.jb;

      return Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _showLocationPicker(context, true, originName),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  border: Border.all(color: AppColors.borderLight),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.currentAddress, style: const TextStyle(fontSize: 10, color: AppColors.textMutedLight)),
                    const SizedBox(height: 4),
                    Text(originName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.swap_horiz_rounded, color: AppColors.primaryBase),
          ),
          Expanded(
            child: InkWell(
              onTap: () => _showLocationPicker(context, false, destName),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  border: Border.all(color: AppColors.borderLight),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.newAddress, style: const TextStyle(fontSize: 10, color: AppColors.textMutedLight)),
                    const SizedBox(height: 4),
                    Text(destName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      final selectedName = locationProvider.selectedName ?? l10n.kl;
      return InkWell(
        onTap: () => _showLocationPicker(context, false, selectedName),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            border: Border.all(color: AppColors.borderLight),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on_rounded, color: AppColors.danger),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.locationSelection, style: const TextStyle(fontSize: 10, color: AppColors.textMutedLight)),
                    Text(selectedName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textMutedLight),
            ],
          ),
        ),
      );
    }
  }
}
