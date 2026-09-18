// Explicit initialization follows Development Standard §7.
// ignore_for_file: prefer_initializing_formals
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:locatemy/features/map_location/map_location.dart';

import '../domain/hazard_models.dart';
import 'hazard_strings.dart';
import 'hazard_view_models.dart';

enum HazardPageKind { composer, mine, detail }

String hazardPageTitle(BuildContext context, HazardPageKind kind) {
  final HazardStrings l = HazardStrings(context);
  switch (kind) {
    case HazardPageKind.composer:
      return l.text('Report hazard', '上报隐患');
    case HazardPageKind.mine:
      return l.text('My reports', '我的隐患');
    case HazardPageKind.detail:
      return l.text('Hazard details', '隐患详情');
  }
}

const Color _blue = Color(0xFF155EEF);
const Color _ink = Color(0xFF172033);
const Color _muted = Color(0xFF667085);
const Color _background = Color(0xFFF6F8FB);

Widget _heading(String text, {double size = 20}) {
  return Text(
    text,
    style: TextStyle(
      fontFamily: 'SourceSansPro',
      fontSize: size,
      fontWeight: FontWeight.w700,
      color: _ink,
    ),
  );
}

Widget _card(Widget child, {Color color = Colors.white}) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFD9E0EA)),
    ),
    child: child,
  );
}

Widget _badge(String text, Color foreground, Color background) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: foreground,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

String _coordinates(GeographicPoint point) {
  return '${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}';
}

String _date(BuildContext context, DateTime time) {
  return DateFormat.yMMMd(Localizations.localeOf(context).languageCode)
      .add_Hm()
      .format(time.toLocal());
}

final class HazardComposerPage extends StatefulWidget {
  final HazardReporting hazards;
  final bool showHeading;
  final HazardCreateRequest Function(HazardType, String, String?) request;
  final ValidLocationReference? location;
  final VoidCallback? onCreated;
  const HazardComposerPage({
    required HazardReporting hazards,
    required HazardCreateRequest Function(HazardType, String, String?) request,
    ValidLocationReference? location,
    VoidCallback? onCreated,
    bool showHeading = true,
    super.key,
  }) : showHeading = showHeading,
       hazards = hazards,
       request = request,
       location = location,
       onCreated = onCreated;
  @override
  State<HazardComposerPage> createState() {
    return _HazardComposerPageState();
  }
}

final class _HazardComposerPageState extends State<HazardComposerPage> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final FocusNode _titleFocus = FocusNode();
  final GlobalKey _typesKey = GlobalKey();
  late final HazardComposerViewModel vm = HazardComposerViewModel(
    widget.hazards,
  );
  @override
  void dispose() {
    vm.dispose();
    _title.dispose();
    _description.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final bool success = await vm.submit((HazardType type) {
      return widget.request(
        type,
        _title.text,
        _description.text.isEmpty ? null : _description.text,
      );
    });
    if (!mounted) {
      return;
    }
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            HazardStrings(context).text('Report published.', '报告已发布。'),
          ),
        ),
      );
      widget.onCreated?.call();
    } else if (vm.failure == HazardWriteFailure.invalidType) {
      final BuildContext? target = _typesKey.currentContext;
      if (target != null && target.mounted) {
        await Scrollable.ensureVisible(target);
      }
    } else if (vm.failure == HazardWriteFailure.emptyTitle ||
        vm.failure == HazardWriteFailure.titleTooLong) {
      _titleFocus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final HazardStrings l = HazardStrings(context);
    return AnimatedBuilder(
      animation: vm,
      builder: (BuildContext context, Widget? child) {
        final List<Widget> chips = [];
        for (final HazardType type in HazardType.values) {
          chips.add(
            ChoiceChip(
              label: Text(l.type(type)),
              selected: vm.type == type,
              selectedColor: _blue,
              backgroundColor: Colors.white,
              showCheckmark: false,
              side: BorderSide.none,
              shape: const StadiumBorder(),
              labelStyle: TextStyle(
                fontFamily: 'SourceSansPro',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: vm.type == type ? Colors.white : _ink,
              ),
              onSelected: vm.saving
                  ? null
                  : (bool selected) {
                      vm.choose(selected ? type : null);
                    },
            ),
          );
        }
        final HazardWriteFailure? failure = vm.failure;
        final bool titleError =
            failure == HazardWriteFailure.emptyTitle ||
            failure == HazardWriteFailure.titleTooLong;
        return ColoredBox(
          color: _background,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (widget.showHeading) _heading(l.text('Report hazard', '上报隐患')),
              const SizedBox(height: 20),
              Text(
                l.text(
                  'Published type, content, location and report time cannot be edited.',
                  '发布后类型、内容、位置与上报时间不可编辑',
                ),
                style: const TextStyle(fontSize: 13, color: _muted),
              ),
              const SizedBox(height: 24),
              Text(
                l.text('Hazard type *', '隐患类型 *'),
                key: _typesKey,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Wrap(spacing: 10, runSpacing: 6, children: chips),
              if (failure == HazardWriteFailure.invalidType)
                Semantics(
                  liveRegion: true,
                  child: Text(
                    l.failure(failure!),
                    style: const TextStyle(color: Color(0xFFC9362B)),
                  ),
                ),
              const SizedBox(height: 20),
              Text(
                l.text('Title *', '标题 *'),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _title,
                focusNode: _titleFocus,
                enabled: !vm.saving,
                maxLength: 120,
                decoration: InputDecoration(
                  hintText: l.text(
                    'For example: water on the sidewalk',
                    '例如：人行道积水',
                  ),
                  counterText: '',
                  errorText: titleError ? l.failure(failure!) : null,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l.text('Description (optional)', '描述（可选）'),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _description,
                enabled: !vm.saving,
                maxLength: 2000,
                minLines: 3,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: l.text(
                    'Describe the extent, duration or conditions…',
                    '补充发生范围、持续时间或现场情况…',
                  ),
                  counterText: '',
                  errorText: failure == HazardWriteFailure.descriptionTooLong
                      ? l.failure(failure!)
                      : null,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l.text('Location *', '位置 *'),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              _card(
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, color: _blue, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.location?.displayName ??
                                l.text('Selected map point', '已选地图位置'),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.location == null
                                ? l.text(
                                    'Validated by the map before submission',
                                    '提交前由地图验证',
                                  )
                                : _coordinates(widget.location!.point),
                            style: const TextStyle(fontSize: 12, color: _muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _card(
                Text(
                  l.text(
                    'Visible to all signed-in users. Pending / resolved is your own record and does not indicate platform verification.',
                    '发布后所有应用用户可见。处理状态仅是你自己的 pending / resolved 标记，不代表平台审核。',
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
                color: const Color(0xFFEAF1FF),
              ),
              if (failure != null &&
                  failure != HazardWriteFailure.invalidType &&
                  !titleError &&
                  failure != HazardWriteFailure.descriptionTooLong)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      l.failure(failure),
                      style: const TextStyle(color: Color(0xFFC9362B)),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: vm.saving ? null : _submit,
                child: vm.saving
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          semanticsLabel: l.text('Publishing', '正在发布'),
                        ),
                      )
                    : Text(l.text('Publish hazard report', '发布隐患报告')),
              ),
              const SizedBox(height: 12),
              Text(
                l.text(
                  'Failed submissions retain your input. Reports require an online connection.',
                  '提交失败会保留全部输入。报告须在线发布。',
                ),
                style: const TextStyle(fontSize: 12, color: _muted),
              ),
            ],
          ),
        );
      },
    );
  }
}

final class MyHazardsPage extends StatefulWidget {
  final List<HazardReport> reports;
  final bool showHeading;
  final ValueChanged<HazardReport> onOpen;
  final ValueChanged<HazardReport>? onLocate;
  final VoidCallback? onCreate;
  final HazardReporting? hazards;
  final HazardPageRequest? request;
  final Listenable? refreshSignal;
  const MyHazardsPage({
    List<HazardReport> reports = const [],
    required ValueChanged<HazardReport> onOpen,
    ValueChanged<HazardReport>? onLocate,
    VoidCallback? onCreate,
    HazardReporting? hazards,
    HazardPageRequest? request,
    Listenable? refreshSignal,
    bool showHeading = true,
    super.key,
  }) : showHeading = showHeading,
       reports = reports,
       onOpen = onOpen,
       onLocate = onLocate,
       onCreate = onCreate,
       hazards = hazards,
       request = request,
       refreshSignal = refreshSignal;
  @override
  State<MyHazardsPage> createState() {
    return _MyHazardsPageState();
  }
}

final class _MyHazardsPageState extends State<MyHazardsPage> {
  HazardListViewModel? vm;
  @override
  void initState() {
    super.initState();
    if (widget.hazards != null && widget.request != null) {
      vm = HazardListViewModel(widget.hazards!, widget.request!);
      vm!.refresh();
    }
    widget.refreshSignal?.addListener(_refresh);
  }

  void _refresh() {
    vm?.refresh();
  }

  @override
  void dispose() {
    widget.refreshSignal?.removeListener(_refresh);
    vm?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (vm == null) {
      return _content(context);
    }
    return AnimatedBuilder(
      animation: vm!,
      builder: (BuildContext context, Widget? child) {
        return _content(context);
      },
    );
  }

  Widget _content(BuildContext context) {
    final HazardStrings l = HazardStrings(context);
    final List<HazardReport> reports = vm?.reports ?? widget.reports;
    int pending = 0;
    for (final HazardReport report in reports) {
      if (report.status == HazardAuthorStatus.pending) {
        pending++;
      }
    }
    final List<Widget> cards = [];
    for (final HazardReport report in reports) {
      final bool unresolved = report.status == HazardAuthorStatus.pending;
      cards.add(
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: _card(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _badge(l.type(report.type), _blue, const Color(0xFFEAF1FF)),
                    _badge(
                      l.status(report.status),
                      unresolved
                          ? const Color(0xFFB76E00)
                          : const Color(0xFF16865C),
                      unresolved
                          ? const Color(0xFFFFF5DC)
                          : const Color(0xFFE5F5ED),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _heading(report.title, size: 17),
                const SizedBox(height: 8),
                Text(
                  '${_coordinates(report.location)} · ${_date(context, report.reportedAt)}',
                  style: const TextStyle(fontSize: 12, color: _muted),
                ),
                Wrap(
                  spacing: 12,
                  children: [
                    if (widget.onLocate != null)
                      TextButton(
                        onPressed: () {
                          widget.onLocate!(report);
                        },
                        child: Text(l.text('Locate on map', '地图定位')),
                      ),
                    TextButton(
                      onPressed: () {
                        widget.onOpen(report);
                      },
                      child: Text(l.text('View details', '查看详情')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }
    return ColoredBox(
      color: _background,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: widget.showHeading
                    ? _heading(l.text('My reports', '我的隐患'))
                    : const SizedBox(),
              ),
              if (vm != null)
                TextButton(
                  onPressed: vm!.loading
                      ? null
                      : () {
                          vm!.refresh();
                        },
                  child: Text(l.text('Refresh', '刷新')),
                ),
            ],
          ),
          Text(
            l.text(
              '${reports.length} reports · $pending pending',
              '${reports.length} 项报告 · $pending 项待处理',
            ),
            style: const TextStyle(color: _muted, fontSize: 14),
          ),
          if (widget.onCreate != null)
            Padding(
              padding: const EdgeInsets.only(top: 18),
              child: FilledButton(
                onPressed: widget.onCreate,
                child: Text(l.text('+ New hazard report', '＋ 新建隐患报告')),
              ),
            ),
          if (vm?.loading == true)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (vm?.failure != null)
            _card(
              Column(
                children: [
                  Semantics(
                    liveRegion: true,
                    child: Text(l.readFailure(vm!.failure!)),
                  ),
                  TextButton(
                    onPressed: () {
                      vm!.refresh();
                    },
                    child: Text(l.text('Retry', '重试')),
                  ),
                ],
              ),
            ),
          if (reports.isEmpty && vm?.loading != true && vm?.failure == null)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(l.text('No reports yet.', '暂无报告。')),
            ),
          ...cards,
          if (vm?.nextCursor != null)
            TextButton(
              onPressed: vm!.loading
                  ? null
                  : () {
                      vm!.refresh(more: true);
                    },
              child: Text(l.text('Load more', '加载更多')),
            ),
          const SizedBox(height: 20),
          _card(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _heading(l.text('What you can manage', '你可以管理什么'), size: 15),
                const SizedBox(height: 8),
                Text(
                  l.text(
                    '• Mark your reports pending or resolved\n• Locate and view public details\n• Delete your reports after confirmation',
                    '• 将自己的报告标记为待处理或已解决\n• 在地图定位并查看公开详情\n• 确认后删除自己的报告',
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          if (vm?.refreshedAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _card(
                Text(
                  '${l.text('Last successful refresh', '最后成功刷新')}：${_date(context, vm!.refreshedAt!)}',
                  style: const TextStyle(fontSize: 12),
                ),
                color: const Color(0xFFEAF1FF),
              ),
            ),
        ],
      ),
    );
  }
}

final class HazardDetailPage extends StatefulWidget {
  final HazardReport report;
  final bool showHeading;
  final Future<void> Function(HazardVote) onVote;
  final Future<void> Function()? onResolve;
  final Future<void> Function()? onDelete;
  final Future<void> Function()? onPending;
  final VoidCallback? onLocate;
  const HazardDetailPage({
    required HazardReport report,
    required Future<void> Function(HazardVote) onVote,
    Future<void> Function()? onResolve,
    Future<void> Function()? onDelete,
    Future<void> Function()? onPending,
    VoidCallback? onLocate,
    bool showHeading = true,
    super.key,
  }) : showHeading = showHeading,
       report = report,
       onVote = onVote,
       onResolve = onResolve,
       onDelete = onDelete,
       onPending = onPending,
       onLocate = onLocate;
  @override
  State<HazardDetailPage> createState() {
    return _HazardDetailPageState();
  }
}

final class _HazardDetailPageState extends State<HazardDetailPage> {
  bool _busy = false;
  String? _error;
  Future<void> _act(Future<void> Function() action) async {
    if (_busy) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _delete() async {
    final HazardStrings l = HazardStrings(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l.text('Delete this report?', '删除此报告？')),
          content: Text(
            l.text(
              'The public report and its votes will be deleted.',
              '公开报告及其投票将被删除。',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: Text(l.text('Cancel', '取消')),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: Text(l.text('Delete', '删除')),
            ),
          ],
        );
      },
    );
    if (confirmed == true && mounted && widget.onDelete != null) {
      await _act(widget.onDelete!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final HazardStrings l = HazardStrings(context);
    final HazardReport report = widget.report;
    final bool pending = report.status == HazardAuthorStatus.pending;
    return ColoredBox(
      color: _background,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.showHeading) _heading(l.text('Hazard details', '隐患详情')),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            children: [
              _badge(l.type(report.type), _blue, const Color(0xFFEAF1FF)),
              _badge(
                l.status(report.status),
                pending ? const Color(0xFFB76E00) : const Color(0xFF16865C),
                pending ? const Color(0xFFFFF5DC) : const Color(0xFFE5F5ED),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _heading(report.title, size: 22),
          const SizedBox(height: 8),
          Text(
            _date(context, report.reportedAt),
            style: const TextStyle(fontSize: 13, color: _muted),
          ),
          const SizedBox(height: 20),
          _card(
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 92),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on, color: _blue),
                    Text(_coordinates(report.location)),
                    if (widget.onLocate != null)
                      TextButton(
                        onPressed: widget.onLocate,
                        child: Text(l.text('Locate on map', '地图定位')),
                      ),
                  ],
                ),
              ),
            ),
            color: const Color(0xFFEAF1FF),
          ),
          const SizedBox(height: 16),
          _card(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _heading(l.text('Description', '情况描述'), size: 14),
                const SizedBox(height: 10),
                Text(
                  report.description ?? l.text('No description.', '未填写描述。'),
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _heading(l.text('Community feedback', '社区反馈'), size: 18),
          const SizedBox(height: 4),
          Wrap(
            spacing: 12,
            children: [
              OutlinedButton(
                onPressed: _busy
                    ? null
                    : () {
                        _act(() {
                          return widget.onVote(
                            report.vote.mine == HazardVote.up
                                ? HazardVote.none
                                : HazardVote.up,
                          );
                        });
                      },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF16865C),
                  backgroundColor: report.vote.mine == HazardVote.up
                      ? const Color(0xFFE5F5ED)
                      : Colors.white,
                ),
                child: Text(
                  '${l.text('Support', '赞成')}  ${report.vote.upvotes}',
                ),
              ),
              OutlinedButton(
                onPressed: _busy
                    ? null
                    : () {
                        _act(() {
                          return widget.onVote(
                            report.vote.mine == HazardVote.down
                                ? HazardVote.none
                                : HazardVote.down,
                          );
                        });
                      },
                style: OutlinedButton.styleFrom(
                  backgroundColor: report.vote.mine == HazardVote.down
                      ? const Color(0xFFEAF1FF)
                      : Colors.white,
                ),
                child: Text(
                  '${l.text('Oppose', '反对')}  ${report.vote.downvotes}',
                ),
              ),
            ],
          ),
          if (report.vote.mine != HazardVote.none)
            TextButton(
              onPressed: _busy
                  ? null
                  : () {
                      _act(() {
                        return widget.onVote(HazardVote.none);
                      });
                    },
              child: Text(l.text('Withdraw vote', '撤回投票')),
            ),
          if (_busy) const Center(child: CircularProgressIndicator()),
          if (_error != null)
            Semantics(
              liveRegion: true,
              child: Text(
                _error!,
                style: const TextStyle(color: Color(0xFFC9362B)),
              ),
            ),
          if (report.author == HazardAuthorView.mine) ...[
            const SizedBox(height: 20),
            _card(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _heading(l.text('Your report', '你的报告'), size: 14),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 16,
                    children: [
                      if (pending && widget.onResolve != null)
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () {
                                  _act(widget.onResolve!);
                                },
                          child: Text(l.text('Mark resolved', '标记为已解决')),
                        ),
                      if (!pending && widget.onPending != null)
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () {
                                  _act(widget.onPending!);
                                },
                          child: Text(l.text('Mark pending', '标记为待处理')),
                        ),
                      if (widget.onDelete != null)
                        TextButton(
                          onPressed: _busy ? null : _delete,
                          child: Text(
                            l.text('Delete', '删除'),
                            style: const TextStyle(color: Color(0xFFC9362B)),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Loads through the Feature seam and refreshes authoritative details after writes.
final class HazardDetailLoader extends StatefulWidget {
  final HazardReporting hazards;
  final bool showHeading;
  final HazardReportId id;
  final VoidCallback onChanged;
  final VoidCallback onDeleted;
  final ValueChanged<HazardReport>? onLocate;
  const HazardDetailLoader({
    required HazardReporting hazards,
    required HazardReportId id,
    required VoidCallback onChanged,
    required VoidCallback onDeleted,
    ValueChanged<HazardReport>? onLocate,
    bool showHeading = true,
    super.key,
  }) : showHeading = showHeading,
       hazards = hazards,
       id = id,
       onChanged = onChanged,
       onDeleted = onDeleted,
       onLocate = onLocate;
  @override
  State<HazardDetailLoader> createState() {
    return _HazardDetailLoaderState();
  }
}

final class _HazardDetailLoaderState extends State<HazardDetailLoader> {
  late final HazardDetailViewModel vm = HazardDetailViewModel(
    widget.hazards,
    widget.id,
  );
  @override
  void initState() {
    super.initState();
    vm.load();
  }

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  Future<void> _vote(HazardVote vote) async {
    final HazardWriteFailure? failure = await vm.vote(vote);
    if (!mounted) {
      return;
    }
    if (failure != null) {
      throw HazardStrings(context).failure(failure);
    }
    widget.onChanged();
  }

  Future<void> _status(HazardAuthorStatus status) async {
    final HazardWriteFailure? failure = await vm.status(status);
    if (!mounted) {
      return;
    }
    if (failure != null) {
      throw HazardStrings(context).failure(failure);
    }
    widget.onChanged();
  }

  Future<void> _delete() async {
    final HazardWriteFailure? failure = await vm.delete();
    if (!mounted) {
      return;
    }
    if (failure != null) {
      throw HazardStrings(context).failure(failure);
    }
    widget.onChanged();
    widget.onDeleted();
  }

  @override
  Widget build(BuildContext context) {
    final HazardStrings l = HazardStrings(context);
    return AnimatedBuilder(
      animation: vm,
      builder: (BuildContext context, Widget? child) {
        return Column(
          children: [
            if (vm.loading) const LinearProgressIndicator(),
            if (vm.failure != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(l.readFailure(vm.failure!)),
                    TextButton(
                      onPressed: vm.load,
                      child: Text(l.text('Retry', '重试')),
                    ),
                  ],
                ),
              ),
            if (vm.report != null)
              Expanded(
                child: HazardDetailPage(
                  showHeading: widget.showHeading,
                  report: vm.report!,
                  onVote: _vote,
                  onResolve: () {
                    return _status(HazardAuthorStatus.resolved);
                  },
                  onPending: () {
                    return _status(HazardAuthorStatus.pending);
                  },
                  onDelete: _delete,
                  onLocate: widget.onLocate == null
                      ? null
                      : () {
                          widget.onLocate!(vm.report!);
                        },
                ),
              ),
          ],
        );
      },
    );
  }
}
