import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../models/hazard_marker.dart';
import '../../providers/hazard_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../generated/app_localizations.dart';
import '../../widgets/bento_card.dart';

class ReportedHazardsScreen extends StatefulWidget {
  const ReportedHazardsScreen({super.key});

  @override
  State<ReportedHazardsScreen> createState() => _ReportedHazardsScreenState();
}

class _ReportedHazardsScreenState extends State<ReportedHazardsScreen> {
  List<HazardMarker>? _userHazards;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHazards();
  }

  Future<void> _loadHazards() async {
    setState(() => _isLoading = true);
    final hazards = await context.read<HazardProvider>().getUserHazards();
    if (mounted) {
      setState(() {
        _userHazards = hazards;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteHazard(String id) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除隐患报告'),
        content: const Text('确定要永久删除这条隐患报告吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await context.read<HazardProvider>().removeHazard(id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('报告已删除')),
        );
        _loadHazards();
      }
    }
  }

  void _viewOnMap(HazardMarker hazard) {
    // 1. 设置选中位置
    final locationProvider = context.read<LocationProvider>();
    locationProvider.setSelectedLocation(hazard.location, hazard.title);
    
    // 2. 移动地图视角
    locationProvider.moveTo(hazard.location, zoom: 15.0);
    
    // 3. 切换到底图 Tab (Index 1)
    context.read<NavigationProvider>().setIndex(1);
    
    // 4. 关闭当前页面和账号中心，回到 AppShell
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('我报告的隐患'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadHazards,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_userHazards == null || _userHazards!.isEmpty)
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.report_off_rounded, size: 64, color: AppColors.textMutedLight),
                      const SizedBox(height: 16),
                      const Text('暂无报告记录', style: TextStyle(color: AppColors.textSecondaryLight)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _userHazards!.length,
                  itemBuilder: (context, index) {
                    final hazard = _userHazards![index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => _viewOnMap(hazard),
                        borderRadius: BorderRadius.circular(16),
                        child: BentoCard(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: hazard.type.color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(hazard.type.icon, color: hazard.type.color, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    hazard.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    hazard.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textMutedLight),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${hazard.createdAt.year}-${hazard.createdAt.month}-${hazard.createdAt.day}',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textMutedLight),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20),
                                        onPressed: () => _deleteHazard(hazard.id),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
