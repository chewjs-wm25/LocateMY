import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:locate_my/core/app_colors.dart';
import 'package:locate_my/modules/module_b/models/property/property_inspection.dart';
import 'package:locate_my/shared/widgets/bento_card.dart';
import 'package:locate_my/shared/widgets/status_badge.dart';

class PropertyComparisonScreen extends StatelessWidget {
  final List<PropertyInspection> inspections;

  const PropertyComparisonScreen({super.key, required this.inspections});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Property Comparison'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimaryLight,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildPhotoGallery(),
            _buildComparisonTable(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoGallery() {
    return Container(
      height: 160,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: inspections.length,
        itemBuilder: (context, index) {
          final inspection = inspections[index];
          return Container(
            width: 140,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppColors.surfaceSubLight,
              border: Border.all(color: AppColors.borderLight, width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.home_work_outlined,
                  size: 40,
                  color: AppColors.textMutedDark,
                ),
                const SizedBox(height: 8),
                Text(
                  inspection.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildComparisonTable(BuildContext context) {
    return BentoCard(
      margin: const EdgeInsets.all(16),
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 24,
          headingRowColor: WidgetStateProperty.all(
            AppColors.surfaceSubLight.withOpacity(0.5),
          ),
          columns: [
            const DataColumn(
              label: Text(
                'Metric',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ...inspections.map(
              (i) => DataColumn(
                label: Container(
                  constraints: const BoxConstraints(maxWidth: 100),
                  child: Text(
                    i.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
          rows: [
            _buildRow(
              'Price',
              (i) => 'RM ${NumberFormat('#,###').format(i.price)}',
            ),
            _buildRow(
              'Security Score',
              (i) => i.securityScore?.toStringAsFixed(1) ?? 'N/A',
            ),
            _buildRow(
              'Flood History',
              (i) => i.hasFloodHistory ? '🔴 Has History' : '🟢 No History',
            ),
            _buildRow('Nearby Hazards', (i) => '${i.nearbyHazardsCount}'),
            _buildRow(
              'Overall Rating',
              (i) => '${i.rating.toStringAsFixed(1)} / 5.0',
            ),
            _buildRow(
              'Drainage',
              (i) => '${i.monsoonChecklist['drainage_score'] ?? 0} ⭐',
            ),
            _buildRow(
              'Waterproofing',
              (i) => '${i.monsoonChecklist['waterproofing_score'] ?? 0} ⭐',
            ),
            _buildRow(
              'Humidity',
              (i) => '${i.monsoonChecklist['humidity_score'] ?? 0} ⭐',
            ),
            _buildRow(
              'Lighting',
              (i) => '${i.monsoonChecklist['lighting_score'] ?? 0} ⭐',
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildRow(
    String label,
    String Function(PropertyInspection) getValue,
  ) {
    return DataRow(
      cells: [
        DataCell(
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
        ...inspections.map((i) => DataCell(Text(getValue(i)))),
      ],
    );
  }
}
