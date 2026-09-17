// Explicit initialization follows Development Standard §7.
// ignore_for_file: prefer_initializing_formals
import 'package:flutter/material.dart';
import 'package:locatemy/features/map_location/map_location.dart';

import '../application/hazard_map_layer.dart';
import '../domain/hazard_models.dart';
import 'hazard_strings.dart';

final class HazardMapPanel extends StatefulWidget {
  final HazardReporting hazards;
  final MapLayerHost host;
  final ValueNotifier<HazardPageRequest?> viewport;
  final ValueNotifier<int> revision;
  final Widget child;
  final VoidCallback? onMine;
  const HazardMapPanel({
    required HazardReporting hazards,
    required MapLayerHost host,
    required ValueNotifier<HazardPageRequest?> viewport,
    required ValueNotifier<int> revision,
    required Widget child,
    VoidCallback? onMine,
    super.key,
  }) : hazards = hazards,
       host = host,
       viewport = viewport,
       revision = revision,
       child = child,
       onMine = onMine;
  @override
  State<HazardMapPanel> createState() {
    return _HazardMapPanelState();
  }
}

final class _HazardMapPanelState extends State<HazardMapPanel> {
  late final HazardMapLayer layer = HazardMapLayer(widget.hazards, widget.host);
  @override
  void initState() {
    super.initState();
    widget.viewport.addListener(_refresh);
    widget.revision.addListener(_refresh);
    if (widget.viewport.value != null) {
      _refresh();
    }
  }

  void _refresh() {
    final HazardPageRequest? request = widget.viewport.value;
    if (request != null) {
      layer.refresh(request);
    }
  }

  @override
  void dispose() {
    widget.viewport.removeListener(_refresh);
    widget.revision.removeListener(_refresh);
    layer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final HazardStrings l = HazardStrings(context);
    return Column(
      children: [
        Expanded(child: widget.child),
        AnimatedBuilder(
          animation: layer,
          builder: (BuildContext context, Widget? child) {
            return Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFEAECF0))),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Column(
                children: [
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (widget.onMine != null)
                        IconButton(
                          tooltip: l.text('My hazard reports', '我的隐患报告'),
                          onPressed: widget.onMine,
                          icon: const Icon(Icons.assignment_outlined),
                        ),
                      if (layer.loading)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      if (layer.nextCursor != null)
                        TextButton.icon(
                          onPressed: layer.loading ? null : layer.more,
                          icon: const Icon(Icons.expand_more, size: 18),
                          label: Text(l.text('Load more hazards', '加载更多隐患')),
                        ),
                    ],
                  ),
                  if (layer.failure != null)
                    Row(
                      children: [
                        Expanded(
                          child: Semantics(
                            liveRegion: true,
                            child: Text(
                              l.readFailure(layer.failure!),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: layer.retry,
                          child: Text(l.text('Retry', '重试')),
                        ),
                      ],
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
