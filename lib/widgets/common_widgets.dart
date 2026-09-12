import 'package:flutter/material.dart';

import '../app/locate_my_state.dart';
import '../models/location.dart';

Widget appCard(BuildContext context, Widget child, {Color? color}) => Card(
  color: color ?? Theme.of(context).colorScheme.surfaceContainerLowest,
  child: Padding(padding: const EdgeInsets.all(16), child: child),
);

Widget section(String text, [String? trailing, VoidCallback? tap]) => Row(
  children: [
    Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
    ),
    const Spacer(),
    if (trailing != null) TextButton(onPressed: tap, child: Text(trailing)),
  ],
);

Widget searchField(VoidCallback tap) => TextField(
  readOnly: true,
  onTap: tap,
  decoration: const InputDecoration(
    prefixIcon: Icon(Icons.search),
    hintText: '搜索马来西亚的城市或地区',
    suffixIcon: Icon(Icons.expand_more),
  ),
);

Widget placeRow(
  String title,
  String subtitle,
  String suffix,
  VoidCallback tap,
) => ListTile(
  contentPadding: EdgeInsets.zero,
  leading: const CircleAvatar(child: Icon(Icons.location_on_outlined)),
  title: Text(title),
  subtitle: Text(subtitle),
  trailing: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(suffix, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      const Icon(Icons.chevron_right),
    ],
  ),
  onTap: tap,
);

Widget selector(String label, Place? value, ValueChanged<Place> onChange) =>
    DropdownButtonFormField<Place>(
      initialValue: value,
      decoration: InputDecoration(labelText: label, hintText: '请选择地点'),
      items: Place.values
          .map(
            (p) => DropdownMenuItem(
              value: p,
              child: Text('${p.name} · ${p.area}'),
            ),
          )
          .toList(),
      onChanged: (p) {
        if (p != null) onChange(p);
      },
    );

Widget notice() => const DecoratedBox(
  decoration: BoxDecoration(
    color: Color(0xfffff3d7),
    borderRadius: BorderRadius.all(Radius.circular(10)),
  ),
  child: Padding(
    padding: EdgeInsets.all(10),
    child: Row(
      children: [
        Icon(Icons.science_outlined, size: 18),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'UI 原型：所有地图、数字、趋势和记录均为本地示例，不代表真实结论。',
            style: TextStyle(fontSize: 11),
          ),
        ),
      ],
    ),
  ),
);

Widget contextNote(String text) => DecoratedBox(
  decoration: const BoxDecoration(
    color: Color(0xffe6f2ef),
    borderRadius: BorderRadius.all(Radius.circular(10)),
  ),
  child: Padding(padding: const EdgeInsets.all(12), child: Text(text)),
);

Widget score(
  BuildContext context,
  String title,
  String value,
  IconData icon,
) => appCard(
  context,
  Row(
    children: [
      Icon(icon, color: Theme.of(context).colorScheme.primary, size: 34),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(value),
          ],
        ),
      ),
      const Text('示例', style: TextStyle(fontSize: 11, color: Colors.black54)),
    ],
  ),
);

Widget chart(String title, String caption) => Card(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 18),
        const SizedBox(
          height: 70,
          child: CustomPaint(
            size: Size(double.infinity, 70),
            painter: LinePainter(),
          ),
        ),
        Text(
          caption,
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
      ],
    ),
  ),
);

Widget bar(String label, int n, String value) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 7),
  child: Row(
    children: [
      SizedBox(width: 88, child: Text(label)),
      Expanded(child: LinearProgressIndicator(value: n / 100)),
      const SizedBox(width: 10),
      SizedBox(
        width: 68,
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    ],
  ),
);

Widget slider(String label, int value, ValueChanged<int> update) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text('$label  $value/10'),
    Slider(
      value: value.toDouble(),
      min: 1,
      max: 10,
      divisions: 9,
      label: '$value',
      onChanged: (v) => update(v.round()),
    ),
  ],
);

Widget amenity(
  BuildContext context,
  String title,
  String name,
  String distance,
) => Padding(
  padding: const EdgeInsets.only(bottom: 8),
  child: appCard(
    context,
    ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.place_outlined),
      title: Text(title),
      subtitle: Text(name),
      trailing: Text(distance, style: const TextStyle(fontSize: 12)),
    ),
  ),
);

Widget dataTable(List<(String, String, String)> rows) => Card(
  child: DataTable(
    columns: const [
      DataColumn(label: Text('项目')),
      DataColumn(label: Text('吉隆坡')),
      DataColumn(label: Text('乔治市')),
    ],
    rows: rows
        .map(
          (r) => DataRow(
            cells: [
              DataCell(Text(r.$1)),
              DataCell(Text(r.$2)),
              DataCell(Text(r.$3)),
            ],
          ),
        )
        .toList(),
  ),
);

Widget actionCard(
  BuildContext context,
  IconData icon,
  String title,
  String subtitle,
  String verb,
  VoidCallback tap,
) => Card(
  color: Theme.of(context).colorScheme.secondaryContainer,
  child: InkWell(
    onTap: tap,
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, size: 34),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(subtitle),
              ],
            ),
          ),
          Text(verb),
          const Icon(Icons.arrow_forward),
        ],
      ),
    ),
  ),
);

Widget route(LocateMyState state) => Row(
  children: [
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '地点 A',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          Text(
            state.locationA?.name ?? '未选择',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    ),
    const Icon(Icons.arrow_forward),
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text(
            '地点 B',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          Text(
            state.locationB?.name ?? '未选择',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    ),
  ],
);

Widget mapArt(
  LocateMyState state,
  Place place, {
  bool compare = false,
}) => Container(
  height: 230,
  decoration: BoxDecoration(
    color: const Color(0xffdcefe8),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: const Color(0xff9ccdc1)),
  ),
  child: Stack(
    children: [
      const Positioned(
        left: 22,
        top: 18,
        child: Text(
          '马来西亚地图 · 示意',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      const Positioned(
        right: 14,
        top: 18,
        child: Text(
          '非真实比例',
          style: TextStyle(fontSize: 11, color: Colors.black54),
        ),
      ),
      const Center(
        child: Icon(Icons.public, size: 140, color: Color(0x3373a998)),
      ),
      if (!compare || state.locationA != null) ...[
        Positioned(
          left: 76,
          top: 65,
          child: Icon(
            Icons.location_on,
            color: compare ? const Color(0xff1758a6) : const Color(0xffbd342f),
            size: 42,
          ),
        ),
        Positioned(
          left: 98,
          top: 110,
          child: Text(compare ? 'A · ${state.locationA!.short}' : place.short),
        ),
      ],
      if (compare && state.locationB != null) ...[
        const Positioned(
          right: 70,
          bottom: 61,
          child: Icon(Icons.location_on, color: Color(0xffbd342f), size: 42),
        ),
        Positioned(
          right: 28,
          bottom: 37,
          child: Text('B · ${state.locationB!.short}'),
        ),
        const Positioned(
          left: 118,
          right: 105,
          top: 96,
          child: Divider(thickness: 2, color: Color(0xff1758a6)),
        ),
      ],
    ],
  ),
);

class Metric extends StatelessWidget {
  const Metric(
    this.label,
    this.value, {
    this.caption,
    this.status,
    this.trend,
    this.date,
    this.direction,
    this.score,
    this.isScore = true,
    super.key,
  });
  final String label;
  final String value;
  final String? caption;
  final String? status;
  final String? trend;
  final String? date;
  final String? direction;
  final int? score;
  final bool isScore;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isScore ? '$value/100' : value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          if (isScore && score != null) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: (score! / 100).clamp(0, 1).toDouble(),
              minHeight: 6,
            ),
          ],
          if (status != null || trend != null || direction != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                if (status != null) Text('状态：$status'),
                if (trend != null) Text('趋势：$trend'),
                if (direction != null) Text(direction!),
              ],
            ),
          ],
          if (caption != null) ...[
            const SizedBox(height: 4),
            Text(caption!, style: const TextStyle(color: Colors.black54)),
          ],
          if (date != null)
            Text(
              date!,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
        ],
      ),
    ),
  );
}

class LinePainter extends CustomPainter {
  const LinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xff006c68)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height * .72)
        ..lineTo(size.width * .17, size.height * .52)
        ..lineTo(size.width * .34, size.height * .62)
        ..lineTo(size.width * .52, size.height * .26)
        ..lineTo(size.width * .72, size.height * .44)
        ..lineTo(size.width, size.height * .15),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter old) => false;
}
