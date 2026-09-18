

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:locatemy/features/map_location/map_location.dart';

import '../../../../l10n/language_controller.dart';
import '../domain/property_models.dart';
import '../application/property_service.dart';
import 'property_view_model.dart';

String _text(BuildContext context, String en, String zh) {
  return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
}

String _failure(BuildContext context, Object failure) {
  if (failure is PropertyFailure) {
    switch (failure.code) {
      case 'permission':
        return _text(
          context,
          'Camera or gallery permission denied. Allow access and retry.',
          '相机或相册权限被拒绝，请允许后重试。',
        );
      case 'format':
        return _text(
          context,
          'Choose a supported static photo (JPEG, PNG, WebP or HEIC); compressed upload must be JPEG under 10 MB.',
          '请选择静态 JPEG、PNG、WebP 或 HEIC 图片；压缩后须为10MB以内JPEG。',
        );
      case 'photoLimit':
        return _text(
          context,
          'Each inspection allows at most 20 photos.',
          '每份实勘最多20张照片。',
        );
      case 'chooseAgain':
        return _text(
          context,
          'Choose this photo again; no local upload queue is kept.',
          '请重新选择该照片；未建立本地待传队列。',
        );
      case 'invalid':
        return _text(
          context,
          'Enter a name, address, valid location, nonnegative price and ratings from 1 to 5.',
          '请填写名称、地址、合法地点、非负价格与1–5评分。',
        );
      case 'upload':
        return _text(
          context,
          'Photo upload or metadata incomplete. Retry this photo.',
          '照片上传或元数据未完成，请重试该照片。',
        );
    }
  }
  return _text(
    context,
    'Online operation failed. Your current input is retained; retry.',
    '在线操作失败，当前输入已保留，请重试。',
  );
}

enum _PropertyNotice { completed, saved }

String _message(BuildContext context, Object message) {
  if (message == _PropertyNotice.saved) {
    return _text(context, 'Inspection saved online.', '实勘已在线保存。');
  }
  if (message == _PropertyNotice.completed) {
    return _text(context, 'Online operation completed.', '在线操作已完成。');
  }
  if (message is PropertyPurgeResult) {
    return message.remaining.isEmpty
        ? _text(context, 'Permanently deleted.', '已永久删除。')
        : '${_text(context, 'Completed', '已完成')}: ${message.completed.length}; ${_text(context, 'Still retained, retry', '仍保留，请重试')}: ${message.remaining.join(', ')}';
  }
  if (message is String) {
    return message;
  }
  return _failure(context, message);
}

Widget _box(Widget child) {
  return Container(
    padding: const EdgeInsets.all(16),
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFD5DEEF)),
    ),
    child: child,
  );
}


const Color _ink = Color(0xFF172033);
const Color _muted = Color(0xFF667085);
const Color _blue = Color(0xFF155EEF);

Widget _section(String title) {
  return Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 16),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: _ink,
      ),
    ),
  );
}

Widget _grid(List<Widget> cards) {
  return LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) {
      final bool stacked =
          constraints.maxWidth < 340 ||
          MediaQuery.textScalerOf(context).scale(14) > 20;
      final double width = stacked
          ? constraints.maxWidth
          : (constraints.maxWidth - 8) / 2;
      return Wrap(
        spacing: 8,
        children: <Widget>[
          for (final Widget card in cards) SizedBox(width: width, child: card),
        ],
      );
    },
  );
}

String _price(double value) {
  return NumberFormat('#,##0.##', 'en_MY').format(value);
}

String _captured(Object? value) {
  if (value == null) {
    return '—';
  }
  final DateTime? time = DateTime.tryParse(value.toString());
  if (time == null) {
    return value.toString();
  }
  return DateFormat('yyyy-MM-dd HH:mm').format(time.toLocal());
}

Widget _score(BuildContext context, double value) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF2FF),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          _text(context, 'On-site average', '综合现场评分'),
          style: const TextStyle(color: _muted, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Text(
          '${value.toStringAsFixed(1)} / 5',
          style: const TextStyle(
            color: _blue,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

Widget _rating(
  BuildContext context,
  String label,
  int value, {
  ValueChanged<int?>? onChanged,
}) {
  Widget score = Text(
    '$value / 5',
    style: const TextStyle(fontWeight: FontWeight.w700),
  );
  if (onChanged != null) {
    score = DropdownButton<int>(
      value: value,
      underline: const SizedBox(),
      iconEnabledColor: _blue,
      items: <DropdownMenuItem<int>>[
        for (int i = 1; i <= 5; i++)
          DropdownMenuItem<int>(
            value: i,
            child: Text(
              '★ $i',
              style: const TextStyle(color: Color(0xFFB76E00)),
            ),
          ),
      ],
      onChanged: onChanged,
    );
  }
  return Container(
    constraints: const BoxConstraints(minHeight: 48),
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFD5DEEF)),
    ),
    child: Row(
      children: <Widget>[
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        const SizedBox(width: 8),
        Semantics(label: label, child: score),
      ],
    ),
  );
}

Widget _photoActions(
  BuildContext context,
  bool enabled,
  void Function(PropertyPhotoSource) pick,
) {
  final ButtonStyle style = TextButton.styleFrom(
    foregroundColor: _blue,
    backgroundColor: Colors.white,
    minimumSize: const Size.fromHeight(54),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: Color(0xFFD5DEEF)),
    ),
  );
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: _grid(<Widget>[
      TextButton(
        style: style,
        onPressed: enabled
            ? () {
                pick(PropertyPhotoSource.camera);
              }
            : null,
        child: Text(_text(context, 'Take photo', '相机拍摄')),
      ),
      TextButton(
        style: style,
        onPressed: enabled
            ? () {
                pick(PropertyPhotoSource.gallery);
              }
            : null,
        child: Text(_text(context, 'Choose from gallery', '从相册选择')),
      ),
    ]),
  );
}

Widget _cover(
  BuildContext context,
  PropertyInspectionRecord record, {
  double height = 100,
  double width = 100,
}) {
  final String? url = record.cover?.url;
  return Semantics(
    label: _text(context, 'Property cover', '房产封面'),
    image: true,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: height,
        width: width,
        child: url == null
            ? const ColoredBox(
                color: Color(0xFFE7EBF1),
                child: Icon(Icons.home_outlined, color: Color(0xFF667085)),
              )
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder:
                    (BuildContext context, Object error, StackTrace? stack) {
                      return const Icon(Icons.broken_image_outlined);
                    },
              ),
      ),
    ),
  );
}

Widget _risk(BuildContext context, PropertyInspectionRecord record) {
  final Map<String, Object?> f = record.snapshot.fields;
  return _box(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          _text(context, 'Property risk snapshot', '房产风险快照'),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          record.snapshot.available
              ? '${f['reporting_state']} · ${_text(context, 'State safety index', '州级安全指数')} ${f['safety_index']} · ${_text(context, 'Nearby pending hazards', '附近待处理隐患')} ${f['hazard_pending_count']}'
              : _text(
                  context,
                  'Snapshot unavailable',
                  '风险快照不可用',
                ),
          style: const TextStyle(fontSize: 13, color: _ink),
        ),
        if (f['snapshot_captured_at'] != null)
          Text(
            '${_text(context, 'Captured', '采集于')} ${_captured(f['snapshot_captured_at'])}',
            style: const TextStyle(fontSize: 11, color: _muted),
          ),
        if (record.snapshot.available)
          Text(
            '${_text(context, 'Source year', '来源年份')} ${f['safety_source_year']} · 2,000 m',
            style: const TextStyle(fontSize: 11, color: _muted),
          ),
      ],
    ),
  );
}

final class PropertyInspectionPortfolioPage extends StatefulWidget {
  final PropertyInspectionService service;
  final PropertyPhotoPicker? photoPicker;
  final Future<ValidLocationReference?> Function(BuildContext)? chooseLocation;
  final ValidLocationReference? location;
  final bool deleted;
  const PropertyInspectionPortfolioPage({
    required PropertyInspectionService service,
    PropertyPhotoPicker? photoPicker,
    Future<ValidLocationReference?> Function(BuildContext)? chooseLocation,
    ValidLocationReference? location,
    bool deleted = false,
    super.key,
  }) : service = service,
       photoPicker = photoPicker,
       chooseLocation = chooseLocation,
       location = location,
       deleted = deleted;
  @override
  State<PropertyInspectionPortfolioPage> createState() {
    return _PortfolioState();
  }
}

final class _PortfolioState extends State<PropertyInspectionPortfolioPage> {
  late final PropertyPortfolioViewModel vm = PropertyPortfolioViewModel(
    widget.service,
    deleted: widget.deleted,
  );
  final Set<String> selected = <String>{};
  bool acting = false;
  Object? message;
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

  Future<void> _open(Widget page) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return page;
        },
      ),
    );
    if (mounted) {
      selected.clear();
      await vm.load();
    }
  }

  Future<void> _restore(String id) async {
    if (acting) {
      return;
    }
    setState(() {
      acting = true;
    });
    try {
      await widget.service.restore(id);
      if (mounted) {
        await vm.load();
      }
    } catch (failure) {
      if (mounted) {
        setState(() {
          message = failure;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          acting = false;
        });
      }
    }
  }

  Future<void> _purge(List<String> ids) async {
    if (acting || ids.isEmpty) {
      return;
    }
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(_text(context, 'Permanently delete?', '确认永久删除？')),
          content: Text(
            _text(
              context,
              'Photos, metadata and inspections will be permanently deleted.',
              '将永久删除照片文件、元数据与实勘。',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: Text(_text(context, 'Cancel', '取消')),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: Text(
                _text(context, 'Confirm permanent deletion', '确认永久删除'),
              ),
            ),
          ],
        );
      },
    );
    if (!mounted || confirmed != true) {
      return;
    }
    setState(() {
      acting = true;
    });
    try {
      final PropertyPurgeResult result = await widget.service.purge(ids);
      if (!mounted) {
        return;
      }
      setState(() {
        message = result;
      });
      await vm.load();
    } finally {
      if (mounted) {
        setState(() {
          acting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: MediaQuery.textScalerOf(context).scale(20) > 28
            ? 144
            : 56,
        title: Text(
          widget.deleted
              ? _text(context, 'Recycle bin', '回收站')
              : _text(context, 'Property inspections', '房产实勘'),
          maxLines: 3,
          softWrap: true,
        ),
        actions: <Widget>[
          const LanguageButton(),
          if (!widget.deleted)
            TextButton(
              onPressed: () {
                _open(
                  PropertyInspectionPortfolioPage(
                    service: widget.service,
                    photoPicker: widget.photoPicker,
                    chooseLocation: widget.chooseLocation,
                    deleted: true,
                  ),
                );
              },
              child: MediaQuery.textScalerOf(context).scale(20) > 28
                  ? Icon(
                      Icons.delete_outline,
                      semanticLabel: _text(context, 'Recycle bin', '回收站'),
                    )
                  : Text(_text(context, 'Recycle bin', '回收站')),
            ),
        ],
      ),
      body: AnimatedBuilder(
        animation: vm,
        builder: (BuildContext context, Widget? child) {
          final List<Widget> items = <Widget>[];
          if (vm.busy || acting) {
            items.add(const LinearProgressIndicator());
          }
          if (vm.error != null) {
            items.add(Text(_failure(context, vm.error!)));
            items.add(
              TextButton(
                onPressed: vm.load,
                child: Text(_text(context, 'Retry', '重试')),
              ),
            );
          }
          if (message != null) {
            items.add(Text(_message(context, message!)));
          }
          if (widget.deleted) {
            items.add(
              FilledButton(
                onPressed: acting || vm.records.isEmpty
                    ? null
                    : () {
                        _purge(
                          vm.records.map((PropertyInspectionRecord r) {
                            return r.id;
                          }).toList(),
                        );
                      },
                child: Text(_text(context, 'Empty recycle bin', '永久清空回收站')),
              ),
            );
          } else {
            items.add(
              FilledButton.icon(
                onPressed: () {
                  _open(
                    PropertyInspectionFormPage(
                      service: widget.service,
                      photoPicker: widget.photoPicker,
                      chooseLocation: widget.chooseLocation,
                      location: widget.location,
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: Text(_text(context, 'New inspection', '新增房产实勘')),
              ),
            );
            items.add(const SizedBox(height: 24));
          }
          if (!vm.busy && vm.error == null && vm.records.isEmpty) {
            items.add(SizedBox(height: 20));
            items.add(
              _box(
                Text(
                  _text(context, 'No property inspections yet.', '暂无房产实勘记录。'),
                ),
              ),
            );
          }
          for (final PropertyInspectionRecord record in vm.records) {
            items.add(
              _box(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    InkWell(
                      onTap: widget.deleted
                          ? null
                          : () {
                              _open(
                                PropertyInspectionDetailPage(
                                  service: widget.service,
                                  id: record.id,
                                  photoPicker: widget.photoPicker,
                                  chooseLocation: widget.chooseLocation,
                                ),
                              );
                            },
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: <Widget>[
                          _cover(context, record),
                          SizedBox(
                            width: 190,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  record.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${record.address} · RM ${record.price.toStringAsFixed(2)}',
                                ),
                                Text(
                                  '${_text(context, 'On-site average', '现场评分')} ${record.rating.toStringAsFixed(1)} / 5',
                                  style: const TextStyle(
                                    color: Color(0xFF079455),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  record.snapshot.available
                                      ? _text(
                                          context,
                                          'Risk snapshot saved',
                                          '风险快照已保存',
                                        )
                                      : _text(
                                          context,
                                          'Risk snapshot unavailable',
                                          '风险快照不可用',
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.deleted)
                      Wrap(
                        children: <Widget>[
                          TextButton(
                            onPressed: acting
                                ? null
                                : () {
                                    _restore(record.id);
                                  },
                            child: Text(_text(context, 'Restore', '恢复')),
                          ),
                          TextButton(
                            onPressed: acting
                                ? null
                                : () {
                                    _purge(<String>[record.id]);
                                  },
                            child: Text(
                              _text(context, 'Permanently delete', '永久删除'),
                            ),
                          ),
                        ],
                      )
                    else
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          _text(context, 'Select for comparison', '选择并比较'),
                        ),
                        value: selected.contains(record.id),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true && selected.length < 3) {
                              selected.add(record.id);
                            } else {
                              selected.remove(record.id);
                            }
                          });
                        },
                      ),
                  ],
                ),
              ),
            );
          }
          if (!widget.deleted) {
            items.add(
              Text(
                _text(
                  context,
                  'Select 2–3 active inspections.',
                  '选择2–3份活动实勘临时并排比较',
                ),
              ),
            );
            items.add(
              OutlinedButton(
                onPressed: selected.length < 2
                    ? null
                    : () async {
                        try {
                          final List<PropertyInspectionRecord> records =
                              await widget.service.compare(selected.toList());
                          if (mounted) {
                            _open(
                              PropertyInspectionComparisonPage(
                                records: records,
                              ),
                            );
                          }
                        } catch (failure) {
                          if (mounted) {
                            setState(() {
                              message = failure;
                            });
                          }
                        }
                      },
                child: Text(_text(context, 'Compare selected', '比较所选实勘')),
              ),
            );
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: items,
              ),
            ),
          );
        },
      ),
    );
  }
}

final class PropertyInspectionFormPage extends StatefulWidget {
  final PropertyInspectionService service;
  final PropertyPhotoPicker? photoPicker;
  final Future<ValidLocationReference?> Function(BuildContext)? chooseLocation;
  final ValidLocationReference? location;
  final PropertyInspectionRecord? record;
  const PropertyInspectionFormPage({
    required PropertyInspectionService service,
    PropertyPhotoPicker? photoPicker,
    Future<ValidLocationReference?> Function(BuildContext)? chooseLocation,
    ValidLocationReference? location,
    PropertyInspectionRecord? record,
    super.key,
  }) : service = service,
       photoPicker = photoPicker,
       chooseLocation = chooseLocation,
       location = location,
       record = record;
  @override
  State<PropertyInspectionFormPage> createState() {
    return _FormState();
  }
}

final class _FormState extends State<PropertyInspectionFormPage> {
  final TextEditingController name = TextEditingController(),
      address = TextEditingController(),
      price = TextEditingController(),
      notes = TextEditingController();
  ValidLocationReference? location;
  List<int> ratings = <int>[3, 3, 3, 3];
  bool flood = false;
  late final PropertyInspectionViewModel vm = PropertyInspectionViewModel(
    service: widget.service,
    picker: widget.photoPicker,
  );
  bool get busy {
    return vm.busy;
  }

  void _changed() {
    if (mounted) {
      setState(() {});
    }
  }

  Object? error;
  final List<PropertyPickedPhoto> picked = <PropertyPickedPhoto>[];
  @override
  void initState() {
    super.initState();
    vm.addListener(_changed);
    final PropertyInspectionRecord? record = widget.record;
    location = record?.location ?? widget.location;
    if (record != null) {
      name.text = record.name;
      address.text = record.address;
      price.text = record.price.toStringAsFixed(2);
      notes.text = record.notes;
      ratings = <int>[
        record.draft.drainage,
        record.draft.waterproofing,
        record.draft.humidity,
        record.draft.lighting,
      ];
      flood = record.draft.floodRisk;
    }
  }

  @override
  void dispose() {
    vm.removeListener(_changed);
    vm.dispose();
    name.dispose();
    address.dispose();
    price.dispose();
    notes.dispose();
    super.dispose();
  }

  Future<void> _pick(PropertyPhotoSource source) async {
    if (busy || widget.photoPicker == null) {
      return;
    }
    if (picked.length + (widget.record?.photos.length ?? 0) >= 20) {
      setState(() {
        error = const PropertyFailure('photoLimit');
      });
      return;
    }
    final PropertyPickedPhoto? photo = await vm.pick(source);
    if (!mounted) {
      return;
    }
    setState(() {
      if (photo != null) {
        picked.add(photo);
      }
      if (vm.failure != null) {
        error = vm.failure!;
      }
    });
  }

  Future<void> _save() async {
    if (busy) {
      return;
    }
    final ValidLocationReference? point = location;
    if (point == null) {
      setState(() {
        error = const PropertyFailure('invalid');
      });
      return;
    }
    final double? value = double.tryParse(price.text.trim());
    if (value == null) {
      setState(() {
        error = const PropertyFailure('invalid');
      });
      return;
    }
    final PropertyInspectionDraft draft = PropertyInspectionDraft(
      name: name.text,
      address: address.text,
      price: value,
      location: point,
      notes: notes.text,
      drainage: ratings[0],
      waterproofing: ratings[1],
      humidity: ratings[2],
      lighting: ratings[3],
      floodRisk: flood,
    );
    setState(() {
      error = null;
    });
    final PropertyInspectionRecord? saved = await vm.save(
      draft,
      id: widget.record?.id,
    );
    if (!mounted) {
      return;
    }
    if (saved == null) {
      setState(() {
        error = vm.failure ?? const PropertyFailure('save');
      });
      return;
    }
    Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return PropertyInspectionDetailPage(
            service: widget.service,
            id: saved.id,
            photoPicker: widget.photoPicker,
            chooseLocation: widget.chooseLocation,
            initialPhotos: picked,
            savedNotice: true,
          );
        },
      ),
    );
  }

  Widget _field(
    String en,
    String zh,
    TextEditingController controller, {
    TextInputType? keyboard,
    int lines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        enabled: !busy,
        controller: controller,
        keyboardType: keyboard,
        maxLines: lines,
        decoration: InputDecoration(
          labelText: _text(context, en, zh),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD5DEEF)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> fields = <Widget>[
      _field('Property name', '房产名称', name),
      _field(
        'Price (RM)',
        '价格（RM）',
        price,
        keyboard: const TextInputType.numberWithOptions(decimal: true),
      ),
      _field('Place name', '地点名称', address),
      OutlinedButton.icon(
        onPressed: busy || widget.chooseLocation == null
            ? null
            : () async {
                final ValidLocationReference? result =
                    await widget.chooseLocation!(context);
                if (mounted && result != null) {
                  setState(() {
                    location = result;
                    address.text = result.displayName ?? '';
                  });
                }
              },
        icon: const Icon(Icons.map_outlined),
        label: Text(
          location == null
              ? _text(
                  context,
                  'Choose location on map or from saved places',
                  '从地图或收藏选择地点',
                )
              : '${location!.point.latitude.toStringAsFixed(5)}, ${location!.point.longitude.toStringAsFixed(5)}',
        ),
      ),
      const SizedBox(height: 16),
      Text(
        _text(context, 'On-site ratings (1–5)', '现场评分（1–5）'),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ];
    final List<String> labels = <String>[
      _text(context, 'Drainage', '排水'),
      _text(context, 'Waterproofing', '防水'),
      _text(context, 'Humidity', '湿度'),
      _text(context, 'Lighting', '照明'),
    ];
    final List<Widget> ratingCards = <Widget>[];
    for (int i = 0; i < 4; i++) {
      ratingCards.add(
        _rating(
          context,
          labels[i],
          ratings[i],
          onChanged: (int? value) {
            if (!busy && value != null) {
              setState(() {
                ratings[i] = value;
              });
            }
          },
        ),
      );
    }
    fields.add(AbsorbPointer(absorbing: busy, child: _grid(ratingCards)));
    fields.addAll(<Widget>[
      _score(context, (ratings[0] + ratings[1] + ratings[2] + ratings[3]) / 4),
      const SizedBox(height: 16),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(_text(context, 'Flood evidence', '发现当地水灾迹象')),
        value: flood,
        onChanged: busy
            ? null
            : (bool value) {
                setState(() {
                  flood = value;
                });
              },
      ),
      _field('Notes', '备注', notes, lines: 3),
      _section(_text(context, 'Photos', '照片')),
      Text(
        '${_text(context, 'Photos', '照片')}: ${picked.length + (widget.record?.photos.length ?? 0)} / 20',
      ),
      _photoActions(context, !busy && widget.photoPicker != null, (
        PropertyPhotoSource source,
      ) {
        _pick(source);
      }),
      for (int i = 0; i < picked.length; i++)
        _box(
          Column(
            children: <Widget>[
              Image.memory(picked[i].bytes, height: 120),
              TextButton(
                onPressed: busy
                    ? null
                    : () {
                        setState(() {
                          picked.removeAt(i);
                        });
                      },
                child: Text(_text(context, 'Remove selected photo', '移除已选照片')),
              ),
            ],
          ),
        ),
      if (error != null)
        Text(
          _failure(context, error!),
          style: const TextStyle(color: Colors.red),
        ),
      if (busy) const LinearProgressIndicator(),
      _box(
        Text(
          _text(
            context,
            'Photos upload after saving. If an upload fails, retry on this page.',
            '保存后才会上传照片；失败可在当前页重试。',
          ),
          style: const TextStyle(color: Color(0xFFB76E00)),
        ),
      ),
      const SizedBox(height: 16),
      FilledButton(
        onPressed: busy ? null : _save,
        child: Text(_text(context, 'Save inspection', '保存实勘')),
      ),
    ]);
    return PopScope(
      canPop: !busy,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          toolbarHeight: MediaQuery.textScalerOf(context).scale(20) > 28
              ? 144
              : 56,
          title: Text(
            widget.record == null
                ? _text(context, 'New inspection', '新增实勘')
                : _text(context, 'Edit inspection', '编辑实勘'),
          ),
          actions: const <Widget>[LanguageButton()],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: fields,
            ),
          ),
        ),
      ),
    );
  }
}

final class PropertyInspectionDetailPage extends StatefulWidget {
  final PropertyInspectionService service;
  final String id;
  final PropertyPhotoPicker? photoPicker;
  final Future<ValidLocationReference?> Function(BuildContext)? chooseLocation;
  final bool savedNotice;
  final List<PropertyPickedPhoto> initialPhotos;
  PropertyInspectionDetailPage({
    required PropertyInspectionService service,
    required String id,
    PropertyPhotoPicker? photoPicker,
    Future<ValidLocationReference?> Function(BuildContext)? chooseLocation,
    bool savedNotice = false,
    List<PropertyPickedPhoto> initialPhotos = const <PropertyPickedPhoto>[],
    super.key,
  }) : service = service,
       id = id,
       photoPicker = photoPicker,
       chooseLocation = chooseLocation,
       savedNotice = savedNotice,
       initialPhotos = List<PropertyPickedPhoto>.unmodifiable(initialPhotos);
  @override
  State<PropertyInspectionDetailPage> createState() {
    return _DetailState();
  }
}

final class _DetailState extends State<PropertyInspectionDetailPage> {
  late final PropertyInspectionViewModel vm = PropertyInspectionViewModel(
    service: widget.service,
    picker: widget.photoPicker,
  );
  PropertyInspectionRecord? get record {
    return vm.record;
  }

  void _changed() {
    if (mounted) {
      setState(() {});
    }
  }

  Object? message;
  bool get busy {
    return vm.busy;
  }

  int revision = 0;
  final List<PropertyPickedPhoto> selectedPhotos = <PropertyPickedPhoto>[];
  @override
  void initState() {
    super.initState();
    vm.addListener(_changed);
    message = widget.savedNotice ? _PropertyNotice.saved : null;
    selectedPhotos.addAll(widget.initialPhotos);
    _load();
    if (selectedPhotos.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((Duration time) {
        if (mounted) {
          _uploadSelected();
        }
      });
    }
  }

  @override
  void dispose() {
    vm.removeListener(_changed);
    vm.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await vm.load(widget.id);
    if (mounted && vm.failure != null) {
      setState(() {
        message = vm.failure!;
      });
    }
  }

  Future<bool> _act(Future<void> Function() action) async {
    if (busy) {
      return false;
    }
    setState(() {
      message = null;
    });
    final bool? completed = await vm.perform<bool>(() async {
      await action();
      return true;
    });
    if (!mounted) {
      return false;
    }
    setState(() {
      message = completed == true
          ? _PropertyNotice.completed
          : vm.failure ?? const PropertyFailure('write');
    });
    await _load();
    return completed == true;
  }

  Future<void> _add(PropertyPhotoSource source) async {
    await _act(() async {
      final PropertyPickedPhoto? photo = await widget.photoPicker?.pick(source);
      if (photo != null && mounted) {
        selectedPhotos.add(photo);
      }
    });
    if (mounted && selectedPhotos.isNotEmpty) {
      await _uploadSelected();
    }
  }

  Future<void> _uploadSelected() async {
    await _act(() async {
      final List<PropertyPickedPhoto> batch = List<PropertyPickedPhoto>.of(
        selectedPhotos,
      );
      int failed = 0;
      for (final PropertyPickedPhoto picked in batch) {
        if (!mounted) {
          return;
        }
        try {
          await widget.service.addPhoto(widget.id, picked);
          selectedPhotos.remove(picked);
        } catch (failure) {
          if (failure is PropertyFailure && failure.code == 'upload') {
            selectedPhotos.remove(picked);
          }
          failed++;
        }
      }
      if (failed > 0) {
        throw const PropertyFailure('upload');
      }
    });
  }

  Future<void> _caption(PropertyPhoto photo) async {
    final TextEditingController input = TextEditingController(
      text: photo.caption,
    );
    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(_text(context, 'Photo caption', '照片说明')),
          content: TextField(controller: input, maxLength: 1000, maxLines: 3),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(_text(context, 'Cancel', '取消')),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, input.text);
              },
              child: Text(_text(context, 'Save caption', '保存说明')),
            ),
          ],
        );
      },
    );
    
    if (!mounted || result == null) {
      return;
    }
    await _act(() {
      return widget.service.editPhoto(widget.id, photo.id, caption: result);
    });
  }

  @override
  Widget build(BuildContext context) {
    final PropertyInspectionRecord? r = record;
    final List<Widget> children = <Widget>[];
    if (message != null) {
      children.add(Text(_message(context, message!)));
    }
    if (selectedPhotos.isNotEmpty) {
      children.add(
        Text(
          '${_text(context, 'Selected photos not uploaded', '尚未上传的已选照片')}: ${selectedPhotos.length}',
        ),
      );
      children.add(
        TextButton(
          onPressed: busy ? null : _uploadSelected,
          child: Text(_text(context, 'Retry selected photos', '重试已选照片')),
        ),
      );
    }
    if (busy) {
      children.add(const LinearProgressIndicator());
    }
    if (r == null) {
      children.add(
        TextButton(
          onPressed: _load,
          child: Text(_text(context, 'Retry loading inspection', '重试读取实勘')),
        ),
      );
    } else {
      children.addAll(<Widget>[
        Text(
          r.name,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          '${r.address} · RM ${_price(r.price)}',
          style: const TextStyle(color: _muted, fontSize: 13),
        ),
        const SizedBox(height: 16),
        _cover(context, r, height: 170, width: double.infinity),
        if (r.cover != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${_text(context, 'Cover', '封面')} · ${r.cover!.caption}',
              style: const TextStyle(color: _muted),
            ),
          ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            if (constraints.maxWidth < 340 ||
                MediaQuery.textScalerOf(context).scale(14) > 20) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _score(context, r.rating),
                  const SizedBox(height: 16),
                  _risk(context, r),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(flex: 1, child: _score(context, r.rating)),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: _risk(context, r)),
              ],
            );
          },
        ),
        _section(_text(context, 'On-site records', '现场记录')),
        _grid(<Widget>[
          _rating(context, _text(context, 'Drainage', '排水'), r.draft.drainage),
          _rating(
            context,
            _text(context, 'Waterproofing', '防水'),
            r.draft.waterproofing,
          ),
          _rating(context, _text(context, 'Humidity', '湿度'), r.draft.humidity),
          _rating(context, _text(context, 'Lighting', '照明'), r.draft.lighting),
        ]),
        _box(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '${_text(context, 'Flood evidence', '当地水灾迹象')}: ${r.draft.floodRisk ? _text(context, 'Yes', '有') : _text(context, 'Not observed', '未发现')}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                '${_text(context, 'Notes', '备注')}: ${r.notes}',
                style: const TextStyle(color: _muted),
              ),
              const SizedBox(height: 8),
              Text(
                '${r.location.point.latitude.toStringAsFixed(5)}, ${r.location.point.longitude.toStringAsFixed(5)}',
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
            ],
          ),
        ),
        Text(
          _text(
            context,
            'Viewing details does not update the risk snapshot.',
            '查看详情不会自动更新风险快照。',
          ),
          style: const TextStyle(color: _muted),
        ),
        _section(_text(context, 'Photo library', '照片库')),
        Text('${_text(context, 'Photos', '照片')}: ${r.photos.length} / 20'),
      ]);
      for (final PropertyPhoto photo in r.photos) {
        children.add(
          _box(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (photo.url != null)
                  Image.network(
                    photo.url!,
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (
                          BuildContext context,
                          Object error,
                          StackTrace? stack,
                        ) {
                          return Text(
                            _text(
                              context,
                              'Photo could not be loaded.',
                              '暂无法读取照片。',
                            ),
                          );
                        },
                  ),
                Text(
                  photo.uploaded
                      ? _text(context, 'Uploaded', '已上传')
                      : _text(
                          context,
                          'Photo incomplete: upload or metadata unfinished.',
                          '照片未完成：上传或元数据尚未完成。',
                        ),
                ),
                if (photo.isCover) Text(_text(context, 'Cover', '封面')),
                Text(photo.caption),
                Wrap(
                  spacing: 8,
                  children: <Widget>[
                    if (!photo.uploaded)
                      TextButton(
                        onPressed: busy
                            ? null
                            : () {
                                _act(() {
                                  return widget.service.retryPhoto(photo);
                                });
                              },
                        child: Text(
                          _text(context, 'Retry photo upload', '重试照片上传'),
                        ),
                      ),
                    if (photo.uploaded)
                      TextButton(
                        onPressed: busy
                            ? null
                            : () {
                                _act(() {
                                  return widget.service.editPhoto(
                                    widget.id,
                                    photo.id,
                                    cover: true,
                                  );
                                });
                              },
                        child: Text(_text(context, 'Set as cover', '设为封面')),
                      ),
                    if (photo.uploaded)
                      TextButton(
                        onPressed: busy
                            ? null
                            : () {
                                _caption(photo);
                              },
                        child: Text(_text(context, 'Edit caption', '编辑说明')),
                      ),
                    TextButton(
                      onPressed: busy
                          ? null
                          : () {
                              _act(() {
                                return widget.service.deletePhoto(
                                  widget.id,
                                  photo,
                                );
                              });
                            },
                      child: Text(_text(context, 'Delete photo', '删除照片')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }
      children.addAll(<Widget>[
        _photoActions(context, !busy && widget.photoPicker != null, (
          PropertyPhotoSource source,
        ) {
          _add(source);
        }),
        OutlinedButton(
          onPressed: busy
              ? null
              : () async {
                  final bool deleted = await _act(() async {
                    await widget.service.trash(widget.id);
                  });
                  if (context.mounted && deleted) {
                    Navigator.pop(context);
                  }
                },
          child: Text(_text(context, 'Move to recycle bin', '移入回收站')),
        ),
      ]);
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        toolbarHeight: MediaQuery.textScalerOf(context).scale(20) > 28
            ? 144
            : 56,
        title: Text(
          _text(context, 'Inspection details', '实勘详情'),
          maxLines: 3,
          softWrap: true,
        ),
        actions: <Widget>[
          const LanguageButton(),
          TextButton(
            onPressed: busy || r == null
                ? null
                : () async {
                    await Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) {
                          return PropertyInspectionFormPage(
                            service: widget.service,
                            record: r,
                            photoPicker: widget.photoPicker,
                            chooseLocation: widget.chooseLocation,
                          );
                        },
                      ),
                    );
                    if (mounted) {
                      await _load();
                    }
                  },
            child: MediaQuery.textScalerOf(context).scale(20) > 28
                ? Icon(
                    Icons.edit_outlined,
                    semanticLabel: _text(context, 'Edit', '编辑'),
                  )
                : Text(_text(context, 'Edit', '编辑')),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: children,
          ),
        ),
      ),
    );
  }
}

final class PropertyInspectionComparisonPage extends StatelessWidget {
  final List<PropertyInspectionRecord> records;
  PropertyInspectionComparisonPage({
    required List<PropertyInspectionRecord> records,
    super.key,
  }) : records = List<PropertyInspectionRecord>.unmodifiable(records);
  Widget _metric(
    BuildContext context,
    String title,
    List<String> values,
    bool shaded,
    double labelWidth,
    double valueWidth,
  ) {
    final List<Widget> cells = <Widget>[
      SizedBox(
        width: labelWidth,
        child: Text(
          title,
          style: const TextStyle(
            color: _muted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ];
    for (int i = 0; i < values.length; i++) {
      cells.add(
        SizedBox(
          width: valueWidth,
          child: Semantics(
            label:
                '${String.fromCharCode(65 + i)} · ${records[i].name} · $title',
            child: Text(
              values[i],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      );
    }
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: shaded ? const Color(0xFFEEF2F7) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: cells),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        toolbarHeight: MediaQuery.textScalerOf(context).scale(20) > 28
            ? 144
            : 56,
        title: Text(
          _text(context, 'Property comparison', '房产实勘对比'),
          maxLines: 3,
          softWrap: true,
        ),
        actions: const <Widget>[LanguageButton()],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Text(
                _text(
                  context,
                  '2–3 active records. Comparison is not saved.',
                  '2–3份活动记录临时并列，比较结果不保存。',
                ),
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final bool largeText =
                      MediaQuery.textScalerOf(context).scale(14) > 20;
                  final double minimumWidth = largeText ? 640 : 340;
                  final double width = constraints.maxWidth < minimumWidth
                      ? minimumWidth
                      : constraints.maxWidth;
                  final double cardWidth =
                      (width - (records.length - 1) * 8) / records.length;
                  final double labelWidth = largeText ? 200 : 132;
                  final double valueWidth =
                      (width - 16 - labelWidth) / records.length;
                  final List<Widget> cards = <Widget>[];
                  const List<Color> colours = <Color>[
                    _blue,
                    Color(0xFF109488),
                    Color(0xFFB76E00),
                  ];
                  for (int i = 0; i < records.length; i++) {
                    final PropertyInspectionRecord record = records[i];
                    cards.add(
                      SizedBox(
                        width: cardWidth,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFD5DEEF)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: colours[i % colours.length],
                                child: Text(
                                  String.fromCharCode(65 + i),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              _cover(
                                context,
                                record,
                                height: 48,
                                width: double.infinity,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                record.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'RM ${_price(record.price)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  final List<Widget> content = <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 8,
                      children: cards,
                    ),
                    _section(_text(context, 'Risk snapshots', '风险快照')),
                    Text(
                      _text(
                        context,
                        'State safety and nearby pending hazards are saved snapshots for each inspection.',
                        '州级安全指数与附近待处理隐患为各实勘保存的快照。',
                      ),
                      style: const TextStyle(color: _muted, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                  ];
                  void metric(
                    String title,
                    String Function(PropertyInspectionRecord) value,
                    bool shaded,
                  ) {
                    final List<String> values = <String>[];
                    for (final PropertyInspectionRecord record in records) {
                      values.add(value(record));
                    }
                    content.add(
                      _metric(
                        context,
                        title,
                        values,
                        shaded,
                        labelWidth,
                        valueWidth,
                      ),
                    );
                  }

                  metric(_text(context, 'State safety index', '州级安全指数'), (
                    PropertyInspectionRecord r,
                  ) {
                    return r.snapshot.available
                        ? r.snapshot.fields['safety_index']?.toString() ?? '—'
                        : '—';
                  }, true);
                  metric(_text(context, 'Nearby pending hazards', '附近待处理隐患'), (
                    PropertyInspectionRecord r,
                  ) {
                    return r.snapshot.available
                        ? r.snapshot.fields['hazard_pending_count']
                                  ?.toString() ??
                              '—'
                        : '—';
                  }, false);
                  content.add(
                    _section(_text(context, 'On-site records', '现场记录')),
                  );
                  metric(_text(context, 'On-site average', '综合现场评分'), (
                    PropertyInspectionRecord r,
                  ) {
                    return '${r.rating.toStringAsFixed(1)} / 5';
                  }, true);
                  metric(_text(context, 'Flood evidence', '水灾迹象'), (
                    PropertyInspectionRecord r,
                  ) {
                    return r.draft.floodRisk
                        ? _text(context, 'Yes', '有')
                        : _text(context, 'Not observed', '未发现');
                  }, false);
                  metric(_text(context, 'Drainage', '排水'), (
                    PropertyInspectionRecord r,
                  ) {
                    return '${r.draft.drainage} / 5';
                  }, true);
                  metric(_text(context, 'Waterproofing', '防水'), (
                    PropertyInspectionRecord r,
                  ) {
                    return '${r.draft.waterproofing} / 5';
                  }, false);
                  metric(_text(context, 'Humidity', '湿度'), (
                    PropertyInspectionRecord r,
                  ) {
                    return '${r.draft.humidity} / 5';
                  }, true);
                  metric(_text(context, 'Lighting', '照明'), (
                    PropertyInspectionRecord r,
                  ) {
                    return '${r.draft.lighting} / 5';
                  }, false);
                  content.add(
                    _section(_text(context, 'Snapshot context', '快照采集信息')),
                  );
                  metric(_text(context, 'Reporting state', '统计州'), (
                    PropertyInspectionRecord r,
                  ) {
                    return r.snapshot.available
                        ? r.snapshot.fields['reporting_state']?.toString() ??
                              '—'
                        : '—';
                  }, true);
                  metric(_text(context, 'Captured', '采集时间'), (
                    PropertyInspectionRecord r,
                  ) {
                    return r.snapshot.fields['snapshot_captured_at']
                            ?.toString() ??
                        '—';
                  }, false);
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: width,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: content,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Text(
                _text(
                  context,
                  '— means unavailable, not zero. Each snapshot retains its own capture time.',
                  '—表示资料暂不可用，不等于0。风险快照保留各自采集时间。',
                ),
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
