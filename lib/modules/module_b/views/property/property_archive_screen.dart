import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:locate_my/core/app_colors.dart';
import 'package:locate_my/shared/widgets/bento_card.dart';
import 'package:locate_my/shared/widgets/status_badge.dart';
import 'package:locate_my/modules/module_b/view_models/property/property_view_model.dart';
import 'package:locate_my/modules/module_b/models/property/property_inspection.dart';
import 'package:locate_my/generated/app_localizations.dart';
import 'package:locate_my/modules/module_b/views/property/property_comparison_screen.dart';
import 'package:locate_my/modules/module_b/views/property/property_detail_screen.dart';
import 'package:locate_my/modules/module_b/views/property/recycle_bin_screen.dart';

class PropertyArchiveScreen extends StatefulWidget {
  const PropertyArchiveScreen({super.key});

  @override
  State<PropertyArchiveScreen> createState() => _PropertyArchiveScreenState();
}

class _PropertyArchiveScreenState extends State<PropertyArchiveScreen> {
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _enterSelectionMode() {
    setState(() {
      _isSelectionMode = true;
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  void _compareSelected() {
    if (_selectedIds.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least 2 properties to compare'),
        ),
      );
      return;
    }

    final inspections = Provider.of<PropertyViewModel>(
      context,
      listen: false,
    ).inspections;
    final selectedInspections = inspections
        .where((i) => _selectedIds.contains(i.id))
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PropertyComparisonScreen(inspections: selectedInspections),
      ),
    );
  }

  void _navigateToDetail(PropertyInspection inspection) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PropertyDetailScreen(inspection: inspection),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final propertyViewModel = Provider.of<PropertyViewModel>(context);
    final inspections = propertyViewModel.inspections;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          _isSelectionMode
              ? '${_selectedIds.length} Selected'
              : 'Property Archive',
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimaryLight,
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelectionMode,
              )
            : null,
        actions: [
          if (!_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RecycleBinScreen(),
                ),
              ),
            ),
            if (inspections.isNotEmpty)
              TextButton(
                onPressed: _enterSelectionMode,
                child: const Text(
                  'Compare',
                  style: TextStyle(color: AppColors.primaryBase),
                ),
              ),
          ],
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(
                Icons.compare_arrows,
                color: AppColors.primaryBase,
              ),
              onPressed: _compareSelected,
            ),
        ],
      ),
      body: inspections.isEmpty
          ? _buildEmptyState(l10n)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: inspections.length,
              itemBuilder: (context, index) {
                final inspection = inspections[index];
                return _buildPropertyCard(inspection, l10n);
              },
            ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: AppColors.textMutedDark.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No inspections yet',
            style: TextStyle(fontSize: 18, color: AppColors.textSecondaryLight),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add properties from the map or home screen\nto start your portfolio.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMutedDark),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyCard(
    PropertyInspection inspection,
    AppLocalizations l10n,
  ) {
    final bool isSelected = _selectedIds.contains(inspection.id);
    final currencyFormat = NumberFormat.currency(
      symbol: 'RM ',
      decimalDigits: 0,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Dismissible(
        key: Key(inspection.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          return await _showDeleteConfirmation(context);
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: AppColors.danger,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.delete_outline, color: Colors.white, size: 28),
              SizedBox(height: 4),
              Text(
                'Delete',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        onDismissed: (_) {
          Provider.of<PropertyViewModel>(
            context,
            listen: false,
          ).deleteInspection(inspection.id);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Moved to recycle bin')));
        },
        child: GestureDetector(
          onTap: _isSelectionMode
              ? () => _toggleSelection(inspection.id)
              : () => _navigateToDetail(inspection),
          child: BentoCard(
            margin: EdgeInsets.zero,
            padding: EdgeInsets.zero,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_isSelectionMode)
                    Container(
                      width: 48,
                      alignment: Alignment.center,
                      child: Checkbox(
                        value: isSelected,
                        activeColor: AppColors.primaryBase,
                        onChanged: (_) => _toggleSelection(inspection.id),
                      ),
                    ),
                  // Thumbnail
                  Container(
                    width: 100,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSubLight,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(20),
                      ),
                      image: inspection.photos.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(
                                'https://picsum.photos/seed/${inspection.id}_${inspection.mainPhotoIndex}/200/200',
                              ),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: inspection.photos.isEmpty
                        ? const Icon(
                            Icons.home_work_outlined,
                            color: AppColors.textMutedDark,
                            size: 40,
                          )
                        : null,
                  ),
                  // Info
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  inspection.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                currencyFormat.format(inspection.price),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryBase,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            inspection.address,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondaryLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildMiniRating(inspection),
                              const Spacer(),
                              if (inspection.hasFloodHistory)
                                StatusBadge(
                                  label: 'FLOOD ALERT',
                                  type: StatusType.danger,
                                  icon: Icons.warning_amber_rounded,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Property?'),
        content: const Text(
          'This property will be moved to the recycle bin. You can restore it later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniRating(PropertyInspection inspection) {
    return Row(
      children: [
        const Icon(Icons.star, color: Colors.amber, size: 14),
        const SizedBox(width: 4),
        Text(
          inspection.rating.toStringAsFixed(1),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        Text(
          '(${DateFormat('MM/dd').format(inspection.updatedAt)})',
          style: const TextStyle(fontSize: 10, color: AppColors.textMutedDark),
        ),
      ],
    );
  }
}
