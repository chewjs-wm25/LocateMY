import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:locate_my/core/app_colors.dart';
import 'package:locate_my/shared/widgets/bento_card.dart';
import 'package:locate_my/modules/module_b/view_models/property/property_view_model.dart';
import 'package:locate_my/modules/module_b/models/property/property_inspection.dart';

class RecycleBinScreen extends StatelessWidget {
  const RecycleBinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final propertyViewModel = Provider.of<PropertyViewModel>(context);
    final deletedItems = propertyViewModel.recycleBin;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Recycle Bin'),
        actions: [
          if (deletedItems.isNotEmpty)
            TextButton(
              onPressed: () =>
                  _showClearConfirmation(context, propertyViewModel),
              child: const Text(
                'Clear All',
                style: TextStyle(color: AppColors.danger),
              ),
            ),
        ],
      ),
      body: deletedItems.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: deletedItems.length,
              itemBuilder: (context, index) {
                final inspection = deletedItems[index];
                return _buildDeletedCard(
                  context,
                  inspection,
                  propertyViewModel,
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.delete_outline,
            size: 80,
            color: AppColors.textMutedDark.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'Recycle bin is empty',
            style: TextStyle(fontSize: 18, color: AppColors.textSecondaryLight),
          ),
        ],
      ),
    );
  }

  Widget _buildDeletedCard(
    BuildContext context,
    PropertyInspection inspection,
    PropertyViewModel provider,
  ) {
    final currencyFormat = NumberFormat.currency(
      symbol: 'RM ',
      decimalDigits: 0,
    );

    return BentoCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: const CircleAvatar(
          backgroundColor: AppColors.surfaceSubLight,
          child: Icon(Icons.home_work_outlined, color: AppColors.textMutedDark),
        ),
        title: Text(
          inspection.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${inspection.address}\n${currencyFormat.format(inspection.price)}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.restore, color: AppColors.primaryBase),
          onPressed: () {
            provider.restoreInspection(inspection.id);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Property restored')));
          },
        ),
      ),
    );
  }

  void _showClearConfirmation(
    BuildContext context,
    PropertyViewModel provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Recycle Bin?'),
        content: const Text(
          'This action will permanently delete all items in the recycle bin and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.clearRecycleBin();
              Navigator.pop(context);
            },
            child: const Text(
              'Clear All',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}
