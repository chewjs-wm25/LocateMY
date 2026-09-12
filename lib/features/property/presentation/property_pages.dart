import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:locatemy/core/app_state.dart';
import 'package:locatemy/core/models/location.dart';
import 'package:locatemy/core/models/property.dart';
import 'package:locatemy/core/widgets/app_scaffold.dart';
import 'package:locatemy/core/widgets/common_widgets.dart';

Color photoTint(InspectionPhoto photo) {
  if (photo.label.contains('排水')) return const Color(0xffdff4ef);
  if (photo.label.contains('厨房')) return const Color(0xffffedcf);
  if (photo.label.contains('阳台') || photo.label.contains('窗')) {
    return const Color(0xffeaf2ff);
  }
  return photo.source == PhotoSource.camera
      ? const Color(0xfff3e8ff)
      : const Color(0xffeef1f5);
}

IconData photoIcon(InspectionPhoto photo) {
  if (photo.label.contains('排水')) return Icons.water_damage_outlined;
  if (photo.label.contains('厨房') || photo.label.contains('水槽')) {
    return Icons.kitchen_outlined;
  }
  if (photo.label.contains('入口')) return Icons.door_front_door_outlined;
  return photo.source == PhotoSource.camera
      ? Icons.camera_alt_outlined
      : Icons.photo_library_outlined;
}

Widget photoPlaceholder(
  InspectionPhoto photo, {
  double width = double.infinity,
  double height = 150,
  bool showLabel = true,
}) => Container(
  width: width,
  height: height,
  decoration: BoxDecoration(
    color: photoTint(photo),
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: const Color(0xffd9e0ea)),
  ),
  child: Stack(
    children: [
      Center(
        child: Icon(
          photoIcon(photo),
          size: height * .34,
          color: const Color(0xff155eef),
        ),
      ),
      if (showLabel)
        Positioned(
          left: 10,
          right: 10,
          bottom: 8,
          child: Text(
            '${photo.label} · 演示视觉占位',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Color(0xff667085)),
          ),
        ),
    ],
  ),
);

Widget syncStatus(InspectionPhoto photo) {
  final data = switch (photo.syncStatus) {
    PhotoSyncStatus.synced => (
      '同步完成',
      const Color(0xff16865c),
      Icons.cloud_done_outlined,
    ),
    PhotoSyncStatus.pending => (
      '待同步',
      const Color(0xffb76e00),
      Icons.cloud_upload_outlined,
    ),
    PhotoSyncStatus.failed => (
      '同步失败',
      const Color(0xffc9362b),
      Icons.cloud_off_outlined,
    ),
  };
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(data.$3, size: 16, color: data.$2),
      const SizedBox(width: 4),
      Text(data.$1, style: TextStyle(fontSize: 12, color: data.$2)),
    ],
  );
}

Widget coverThumbnail(Property property, {double size = 58}) {
  final photo = property.coverPhoto;
  if (photo == null) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xfff1f5f9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.add_a_photo_outlined, color: Color(0xff667085)),
    );
  }
  return ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: photoPlaceholder(photo, width: size, height: size, showLabel: false),
  );
}

class PropertyArchivePage extends StatelessWidget {
  const PropertyArchivePage({required this.state, super.key});
  final LocateMyState state;

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
          state.changeArchiveVariant(-1),
      const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
          state.changeArchiveVariant(1),
    },
    child: Focus(
      autofocus: true,
      child: LocateMyScaffold(
        state: state,
        title: '房产实勘档案',
        actions: [
          TextButton.icon(
            onPressed: state.compared.length >= 2
                ? () => state.go(PageId.compare)
                : null,
            icon: const Icon(Icons.compare_arrows, size: 18),
            label: Text('对比 ${state.compared.length}/3'),
          ),
        ],
        fab: FloatingActionButton.extended(
          onPressed: state.startNewProperty,
          icon: const Icon(Icons.add),
          label: const Text('新增实勘'),
        ),
        bottomBar: kReleaseMode ? null : _VariantSwitcher(state: state),
        body: switch (state.archiveVariant) {
          0 => _overview(context),
          1 => _journal(context),
          _ => _compare(context),
        },
      ),
    ),
  );

  Widget _overview(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
    children: [
      const Text('把现场观察变成下一步判断。', style: TextStyle(color: Color(0xff667085))),
      const SizedBox(height: 16),
      appCard(
        context,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.folder_copy_outlined, color: Color(0xff155eef)),
                SizedBox(width: 8),
                Text('我的实勘概览', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _metric('档案', '${state.properties.length} 套')),
                Expanded(child: _metric('最高评分', '4.2 / 5')),
                Expanded(child: _metric('待复查', '1 套')),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '资料仅自己可见 · 最近更新 2026年9月11日',
              style: TextStyle(fontSize: 13, color: Color(0xff667085)),
            ),
          ],
        ),
        color: const Color(0xffeaf2ff),
      ),
      const SizedBox(height: 20),
      section('下一步值得确认'),
      const SizedBox(height: 8),
      appCard(
        context,
        InkWell(
          onTap: () => state.openProperty(1),
          child: const Row(
            children: [
              CircleAvatar(
                backgroundColor: Color(0xfffff3d7),
                child: Icon(
                  Icons.water_damage_outlined,
                  color: Color(0xffb76e00),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '海景花园排屋',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 3),
                    Text(
                      '雨季再看排水沟与水灾迹象',
                      style: TextStyle(color: Color(0xff667085)),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward),
            ],
          ),
        ),
      ),
      const SizedBox(height: 20),
      section('最近实勘', '查看全部'),
      const SizedBox(height: 8),
      ...List.generate(
        state.properties.length,
        (index) => _propertyItem(context, index),
      ),
    ],
  );

  Widget _journal(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
    children: [
      const Text(
        '按看房过程回顾当时的观察与结论。',
        style: TextStyle(color: Color(0xff667085)),
      ),
      const SizedBox(height: 14),
      const Wrap(
        spacing: 8,
        children: [
          Chip(label: Text('全部地点')),
          Chip(
            avatar: Icon(Icons.location_on_outlined, size: 16),
            label: Text('乔治市'),
          ),
          Chip(
            avatar: Icon(Icons.location_on_outlined, size: 16),
            label: Text('吉隆坡'),
          ),
        ],
      ),
      const SizedBox(height: 18),
      const Text(
        '2026年9月',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      const SizedBox(height: 10),
      ...List.generate(
        state.properties.length,
        (index) => _journalItem(context, index),
      ),
      const SizedBox(height: 6),
      const Text(
        '继续新增实勘，把下一次看房记录在这里。',
        style: TextStyle(color: Color(0xff667085)),
      ),
    ],
  );

  Widget _compare(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
    children: [
      appCard(
        context,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.compare_arrows, color: Color(0xff155eef)),
                SizedBox(width: 8),
                Text('挑选要比较的档案', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '已选 ${state.compared.length}/3 套 · 最少选择 2 套后开始对比',
              style: const TextStyle(color: Color(0xff667085)),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: state.compared.length >= 2
                    ? () => state.go(PageId.compare)
                    : null,
                icon: const Icon(Icons.table_chart_outlined),
                label: const Text('查看并列比较'),
              ),
            ),
          ],
        ),
        color: const Color(0xffeaf2ff),
      ),
      const SizedBox(height: 20),
      section('全部档案'),
      const SizedBox(height: 8),
      ...List.generate(
        state.properties.length,
        (index) => _selectItem(context, index),
      ),
      const SizedBox(height: 14),
      const Text(
        '比较将并列展示价格、四项现场评分、水灾迹象与风险摘要；不会替你推荐房产。',
        style: TextStyle(fontSize: 13, color: Color(0xff667085)),
      ),
    ],
  );

  Widget _metric(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 2),
      Text(
        label,
        style: const TextStyle(fontSize: 13, color: Color(0xff667085)),
      ),
    ],
  );

  Widget _propertyItem(BuildContext context, int index) {
    final property = state.properties[index];
    final statusColor = property.flood
        ? const Color(0xffb76e00)
        : const Color(0xff16865c);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: appCard(
        context,
        InkWell(
          onTap: () => state.openProperty(index),
          child: Row(
            children: [
              coverThumbnail(property),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${property.place.name} · RM ${property.price}',
                      style: const TextStyle(color: Color(0xff667085)),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        Text('★ ${property.score}/5'),
                        Text(
                          property.flood ? '需看水灾记录' : '已完成实勘',
                          style: TextStyle(fontSize: 12, color: statusColor),
                        ),
                        Text(
                          property.photos.isEmpty
                              ? '无照片'
                              : '${property.photos.length} 张照片',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xff667085),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _journalItem(BuildContext context, int index) {
    final property = state.properties[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: appCard(
        context,
        InkWell(
          onTap: () => state.openProperty(index),
          child: Row(
            children: [
              coverThumbnail(property),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '9月11日 · 下午',
                      style: TextStyle(fontSize: 13, color: Color(0xff667085)),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      property.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('${property.place.name} · RM ${property.price}'),
                    const SizedBox(height: 8),
                    Text(
                      '综合评分 ${property.score}/5 · ${property.photos.length} 张照片',
                    ),
                    if (property.photos.any(
                      (photo) => photo.syncStatus != PhotoSyncStatus.synced,
                    ))
                      const Text(
                        '照片同步状态待处理',
                        style: TextStyle(color: Color(0xffb76e00)),
                      ),
                    const Divider(height: 22),
                    Text(
                      '现场笔记：${property.note}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _selectItem(BuildContext context, int index) {
    final property = state.properties[index];
    final selected = state.compared.contains(index);
    void toggle() => state.toggleCompared(index);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected ? const Color(0xffeaf2ff) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: toggle,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Checkbox(value: selected, onChanged: (_) => toggle()),
                const SizedBox(width: 8),
                coverThumbnail(property, size: 54),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        property.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${property.place.name} · RM ${property.price}',
                        style: const TextStyle(color: Color(0xff667085)),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        children: [
                          Chip(
                            label: Text('评分 ${property.score}/5'),
                            visualDensity: VisualDensity.compact,
                          ),
                          Chip(
                            label: Text(property.flood ? '水灾迹象' : '未见水灾'),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => state.openProperty(index),
                  icon: const Icon(Icons.more_horiz),
                  tooltip: '查看档案',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VariantSwitcher extends StatelessWidget {
  const _VariantSwitcher({required this.state});
  final LocateMyState state;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      margin: const EdgeInsets.fromLTRB(24, 8, 24, 12),
      decoration: BoxDecoration(
        color: const Color(0xff172033),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => state.changeArchiveVariant(-1),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 18,
            ),
            tooltip: '上一个原型方案',
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ['A · 决策概览', 'B · 看房日志', 'C · 对比挑选'][state.archiveVariant],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '原型状态：${state.properties.length} 份档案 · 已选 ${state.compared.length}/3',
                  style: const TextStyle(
                    color: Color(0xffd9e0ea),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => state.changeArchiveVariant(1),
            icon: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 18,
            ),
            tooltip: '下一个原型方案',
          ),
        ],
      ),
    ),
  );
}

class PropertyEditorPage extends StatelessWidget {
  const PropertyEditorPage({required this.state, super.key});
  final LocateMyState state;

  Future<void> _confirmLeave(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('确定不保存并退出？'),
        content: const Text('当前实勘内容不会保存。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('继续编辑'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('不保存退出'),
          ),
        ],
      ),
    );
    if (confirmed == true) state.back();
  }

  @override
  Widget build(BuildContext context) => PopScope<void>(
    canPop: false,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) _confirmLeave(context);
    },
    child: LocateMyScaffold(
      state: state,
      title: state.editingProperty == null ? '新增房产实勘' : '编辑房产实勘',
      onBack: () => _confirmLeave(context),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          const Text(
            '这是一次性 UI 原型：照片来源、压缩、联网与同步均为本地模拟。',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: state.propertyNameController,
            decoration: const InputDecoration(
              labelText: '房产名称 *',
              hintText: '海风公寓',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: state.propertyPriceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '价格（RM）*',
              hintText: '598000',
            ),
          ),
          const SizedBox(height: 12),
          selector('地点 *', state.formPlace, state.setFormPlace),
          const SizedBox(height: 18),
          section('现场评分'),
          ...[
            '排水',
            '防水',
            '湿度',
            '照明',
          ].asMap().entries.map((entry) => _ratingRow(entry.key, entry.value)),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: state.formFlood,
            onChanged: (value) => state.setFormFlood(value ?? false),
            title: const Text('发现当地水灾历史或迹象'),
          ),
          TextField(
            controller: state.propertyNoteController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: '备注',
              hintText: '记录噪音、采光等观察…',
            ),
          ),
          const SizedBox(height: 18),
          _photoEditor(context),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: state.saveProperty,
            child: const Text('保存实勘'),
          ),
        ],
      ),
    ),
  );

  Widget _ratingRow(int index, String label) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    subtitle: Text('${state.formRatings[index]}/5'),
    trailing: Wrap(
      spacing: 0,
      children: List.generate(
        5,
        (star) => IconButton(
          tooltip: '$label ${star + 1} 星',
          onPressed: () => state.setFormRating(index, star + 1),
          icon: Icon(
            star < state.formRatings[index]
                ? Icons.star_rounded
                : Icons.star_outline_rounded,
            color: Colors.amber.shade700,
          ),
        ),
      ),
    ),
  );

  Widget _photoEditor(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      section('实勘照片'),
      const SizedBox(height: 4),
      Text(
        '照片 ${state.draftPhotos.length}/20 · 私人视觉证据 · 不读取或展示 EXIF',
        style: const TextStyle(color: Color(0xff667085)),
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          _photoButton(
            context,
            PhotoSource.camera,
            '相机',
            Icons.camera_alt_outlined,
          ),
          const SizedBox(width: 10),
          _photoButton(
            context,
            PhotoSource.gallery,
            '相册',
            Icons.photo_library_outlined,
          ),
        ],
      ),
      if (state.draftPhotos.length >= 20)
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Text(
            '已达 20 张上限，请先删除现有照片后再添加。',
            style: TextStyle(color: Color(0xffb76e00)),
          ),
        ),
      const SizedBox(height: 12),
      if (state.draftPhotos.isEmpty)
        appCard(
          context,
          const Column(
            children: [
              Icon(
                Icons.add_a_photo_outlined,
                size: 34,
                color: Color(0xff667085),
              ),
              SizedBox(height: 6),
              Text('还没有照片 · 可从相机或相册添加'),
              SizedBox(height: 3),
              Text(
                '没有照片时，档案会显示默认占位。',
                style: TextStyle(fontSize: 12, color: Color(0xff667085)),
              ),
            ],
          ),
        )
      else
        ...state.draftPhotos.map((photo) => _photoCard(context, photo)),
    ],
  );

  Widget _photoButton(
    BuildContext context,
    PhotoSource source,
    String label,
    IconData icon,
  ) => Expanded(
    child: OutlinedButton.icon(
      onPressed: () {
        if (state.draftPhotos.length >= 20) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('照片已达上限 20 张，请先删除现有照片。')),
          );
        } else {
          state.addDemoPhoto(source);
        }
      },
      icon: Icon(icon),
      label: Text(label),
    ),
  );

  Widget _photoCard(BuildContext context, InspectionPhoto photo) {
    final isCover = state.draftCoverPhotoId == photo.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: appCard(
        context,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            photoPlaceholder(photo, height: 120),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: syncStatus(photo)),
                if (isCover)
                  const Chip(
                    avatar: Icon(Icons.star, size: 15),
                    label: Text('封面'),
                    visualDensity: VisualDensity.compact,
                  )
                else
                  TextButton.icon(
                    onPressed: () => state.setDraftCover(photo.id),
                    icon: const Icon(Icons.star_border, size: 18),
                    label: const Text('设为封面'),
                  ),
              ],
            ),
            TextFormField(
              key: ValueKey('caption-${photo.id}'),
              initialValue: photo.caption,
              onChanged: (value) => state.updateDraftCaption(photo.id, value),
              decoration: const InputDecoration(
                labelText: '照片说明',
                hintText: '写下这张照片对应的现场观察…',
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _removePhoto(context, photo.id),
                icon: const Icon(
                  Icons.delete_outline,
                  color: Color(0xffc9362b),
                ),
                label: const Text(
                  '删除照片',
                  style: TextStyle(color: Color(0xffc9362b)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removePhoto(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除这张照片？'),
        content: const Text('只会移除实勘副本，不影响设备相册原图。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('删除照片'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final wasCover = state.draftCoverPhotoId == id;
    if (!context.mounted) return;
    state.removeDraftPhoto(id);
    if (wasCover && state.draftPhotos.isNotEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('已自动改用最早上传的照片作为封面')));
    }
  }
}

class PropertyDetailPage extends StatelessWidget {
  const PropertyDetailPage({required this.state, super.key});
  final LocateMyState state;

  @override
  Widget build(BuildContext context) {
    final property = state.properties[state.detail];
    return LocateMyScaffold(
      state: state,
      title: property.name,
      actions: [
        TextButton(
          onPressed: () => state.startEditProperty(state.detail),
          child: const Text('编辑实勘'),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (property.coverPhoto != null)
            photoPlaceholder(property.coverPhoto!, height: 180)
          else
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xfff1f5f9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo_outlined,
                    size: 48,
                    color: Color(0xff667085),
                  ),
                  SizedBox(height: 8),
                  Text('暂无实勘照片 · 默认占位'),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'RM ${property.price}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              Text(
                '${property.score}/5',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          Text(
            '${property.place.name} · ${state.detail == state.properties.length - 1 ? '刚刚保存的演示记录' : '更新于 2026/09/11'}',
          ),
          const SizedBox(height: 20),
          section('风险摘要'),
          appCard(
            context,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('安全 ${property.safety}/100 · 附近隐患 ${property.hazards}'),
                const SizedBox(height: 5),
                Text('水灾迹象：${property.flood ? '有，建议复查' : '未见（示例）'}'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          section('实勘照片'),
          Text(
            property.photos.isEmpty
                ? '暂无照片 · 可在编辑实勘时从相机或相册添加。'
                : '${property.photos.length}/20 张 · 封面删除后自动回退到最早上传的照片',
            style: const TextStyle(color: Color(0xff667085)),
          ),
          const SizedBox(height: 10),
          if (property.photos.isEmpty)
            appCard(context, const Text('当前仅显示默认占位，照片不会进入设备相册或云端服务。'))
          else
            ...property.photos.map(
              (photo) => _detailPhoto(context, property, photo),
            ),
          const SizedBox(height: 16),
          section('实勘评分'),
          dataTable(const [
            ('排水', '4/5', ''),
            ('防水', '3/5', ''),
            ('湿度', '4/5', ''),
            ('照明', '4/5', ''),
          ]),
          const SizedBox(height: 16),
          section('备注'),
          Text(property.note),
          const SizedBox(height: 22),
          OutlinedButton.icon(
            onPressed: () => state.startEditProperty(state.detail),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('编辑实勘'),
          ),
        ],
      ),
    );
  }

  Widget _detailPhoto(
    BuildContext context,
    Property property,
    InspectionPhoto photo,
  ) {
    final cover =
        property.coverPhotoId == photo.id ||
        (property.coverPhotoId == null && property.photos.first == photo);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: appCard(
        context,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    photo.label,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (cover)
                  const Chip(
                    avatar: Icon(Icons.star, size: 15),
                    label: Text('封面'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            photoPlaceholder(photo, height: 140),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: syncStatus(photo)),
                if (photo.syncStatus == PhotoSyncStatus.failed)
                  TextButton.icon(
                    onPressed: () =>
                        state.retryPropertyPhoto(state.detail, photo.id),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('重试同步'),
                  ),
              ],
            ),
            if (photo.caption.isNotEmpty) Text('照片说明：${photo.caption}'),
          ],
        ),
      ),
    );
  }
}

class PropertyComparePage extends StatelessWidget {
  const PropertyComparePage({required this.state, super.key});
  final LocateMyState state;

  @override
  Widget build(BuildContext context) {
    final picks = state.compared
        .map((index) => state.properties[index])
        .toList();
    return LocateMyScaffold(
      state: state,
      title: '房产对比',
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            '以下为个人实勘记录的示例对比。',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 16),
          Card(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  const DataColumn(label: Text('项目')),
                  ...picks.map(
                    (property) => DataColumn(
                      label: SizedBox(
                        width: 100,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            coverThumbnail(property, size: 44),
                            Text(property.name),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                rows: [
                  _row('价格', picks.map((property) => 'RM ${property.price}')),
                  _row('综合评分', picks.map((property) => '${property.score}/5')),
                  _row(
                    '安全指数',
                    picks.map((property) => '${property.safety}/100'),
                  ),
                  _row('附近隐患', picks.map((property) => '${property.hazards}')),
                  _row(
                    '水灾迹象',
                    picks.map((property) => property.flood ? '有' : '未见'),
                  ),
                  _row(
                    '封面照片',
                    picks.map(
                      (property) => property.photos.isEmpty ? '无照片' : '已展示',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  DataRow _row(String name, Iterable<String> values) => DataRow(
    cells: [
      DataCell(Text(name)),
      ...values.map((value) => DataCell(Text(value))),
    ],
  );
}
