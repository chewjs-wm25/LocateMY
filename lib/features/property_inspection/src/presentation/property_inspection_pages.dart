import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:locatemy/features/map_location/map_location.dart';

const Color _propertyBlue = Color(0xFF155EEF);
const Color _propertyInk = Color(0xFF172033);
const Color _propertyMuted = Color(0xFF667085);
const Color _propertyCard = Colors.white;
const Color _propertyBackground = Color(0xFFF6F8FB);
const Color _propertyBorder = Color(0xFFD9E0EA);

final class PropertyInspectionService {
  factory PropertyInspectionService() => _instance;

  PropertyInspectionService._internal();

  static final PropertyInspectionService _instance =
      PropertyInspectionService._internal();

  final List<PropertyInspectionRecord> _records = <PropertyInspectionRecord>[];

  List<PropertyInspectionRecord> get records =>
      List<PropertyInspectionRecord>.unmodifiable(_records);

  void add(PropertyInspectionRecord record) {
    _records.insert(0, record);
  }
}

final class PropertyInspectionRecord {
  PropertyInspectionRecord({
    required this.id,
    required this.name,
    required this.address,
    required this.price,
    required this.rating,
    required this.notes,
    required this.location,
    required this.createdAt,
    required this.drainage,
    required this.waterproofing,
    required this.humidity,
    required this.lighting,
    this.floodRisk = false,
  });

  final String id;
  final String name;
  final String address;
  final int price;
  final double rating;
  final String notes;
  final ValidLocationReference location;
  final DateTime createdAt;
  final int drainage;
  final int waterproofing;
  final int humidity;
  final int lighting;
  final bool floodRisk;

  double get averageScore {
    return (drainage + waterproofing + humidity + lighting) / 4;
  }

  static String formatCurrency(BuildContext context, int price) {
    final NumberFormat formatter = NumberFormat.currency(
      locale: Localizations.localeOf(context).toString(),
      symbol: 'RM ',
      decimalDigits: 0,
    );
    return formatter.format(price);
  }
}

final class PropertyInspectionPage extends StatelessWidget {
  const PropertyInspectionPage({
    this.location,
    this.initialRecords = const <PropertyInspectionRecord>[],
    super.key,
  });

  final ValidLocationReference? location;
  final List<PropertyInspectionRecord> initialRecords;

  @override
  Widget build(BuildContext context) {
    return PropertyInspectionPortfolioPage(
      location: location,
      initialRecords: initialRecords,
    );
  }
}

final class PropertyInspectionPortfolioPage extends StatefulWidget {
  const PropertyInspectionPortfolioPage({
    this.location,
    this.initialRecords = const <PropertyInspectionRecord>[],
    super.key,
  });

  final ValidLocationReference? location;
  final List<PropertyInspectionRecord> initialRecords;

  @override
  State<PropertyInspectionPortfolioPage> createState() {
    return _PropertyInspectionPortfolioPageState();
  }
}

final class _PropertyInspectionPortfolioPageState
    extends State<PropertyInspectionPortfolioPage> {
  final PropertyInspectionService _service = PropertyInspectionService();
  late List<PropertyInspectionRecord> _records;

  @override
  void initState() {
    super.initState();
    _records = <PropertyInspectionRecord>[...widget.initialRecords];
    if (_records.isEmpty) {
      _records = <PropertyInspectionRecord>[..._service.records];
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isZh = Localizations.localeOf(context).languageCode == 'zh';
    final String title = isZh ? '房产实勘档案' : 'Property inspection portfolio';
    final String add = isZh ? '新增实勘' : 'Add inspection';
    return Scaffold(
      backgroundColor: _propertyBackground,
      appBar: AppBar(
        backgroundColor: _propertyBackground,
        surfaceTintColor: Colors.transparent,
        title: Text(title),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '${_records.length} ${isZh ? '份记录' : 'records'}',
                    style: const TextStyle(
                      color: _propertyMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () async {
                    final PropertyInspectionRecord? result =
                        await Navigator.of(context)
                            .push<PropertyInspectionRecord>(
                              MaterialPageRoute<PropertyInspectionRecord>(
                                builder: (BuildContext context) {
                                  return PropertyInspectionFormPage(
                                    location:
                                        widget.location ??
                                        const ValidLocationReference(
                                          locationId: 'draft-location',
                                          point: GeographicPoint(
                                            latitude: 3.0,
                                            longitude: 101.0,
                                          ),
                                          displayName: 'Selected location',
                                        ),
                                  );
                                },
                              ),
                            );
                    if (!mounted || result == null) {
                      return;
                    }
                    _service.add(result);
                    setState(() {
                      _records = <PropertyInspectionRecord>[
                        result,
                        ..._records,
                      ];
                    });
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: Text(add),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_records.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _propertyBorder),
                ),
                child: Text(
                  isZh
                      ? '暂无房产实勘记录，先新增第一份。'
                      : 'No property inspections yet. Save your first record.',
                  style: const TextStyle(color: _propertyMuted, fontSize: 14),
                ),
              )
            else
              ..._records.map((PropertyInspectionRecord record) {
                return _PropertyCard(record: record);
              }),
          ],
        ),
      ),
    );
  }
}

final class _PropertyCard extends StatelessWidget {
  const _PropertyCard({required this.record});

  final PropertyInspectionRecord record;

  @override
  Widget build(BuildContext context) {
    final bool isZh = Localizations.localeOf(context).languageCode == 'zh';
    final String title = record.name.isNotEmpty
        ? record.name
        : (isZh ? '未命名房源' : 'Unnamed property');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _propertyCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _propertyBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _propertyInk,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (record.location.displayName != null)
                      Text(
                        record.location.displayName!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _propertyBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      record.address,
                      style: const TextStyle(
                        fontSize: 14,
                        color: _propertyMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF1FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${record.rating.toStringAsFixed(1)} ★',
                  style: const TextStyle(
                    color: _propertyBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              _InfoLabel(
                label: isZh ? '估值' : 'Price',
                value: PropertyInspectionRecord.formatCurrency(
                  context,
                  record.price,
                ),
              ),
              _InfoLabel(
                label: isZh ? '风险快照' : 'Risk',
                value: isZh ? '可用' : 'Ready',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            record.notes.isNotEmpty
                ? record.notes
                : (isZh ? '未添加备注。' : 'No notes added.'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, color: _propertyInk),
          ),
          const SizedBox(height: 12),
          Text(
            '${record.location.point.latitude.toStringAsFixed(4)}, ${record.location.point.longitude.toStringAsFixed(4)}',
            style: const TextStyle(fontSize: 12, color: _propertyMuted),
          ),
        ],
      ),
    );
  }
}

final class _InfoLabel extends StatelessWidget {
  const _InfoLabel({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: _propertyMuted),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _propertyInk,
          ),
        ),
      ],
    );
  }
}

final class PropertyInspectionFormPage extends StatefulWidget {
  const PropertyInspectionFormPage({this.location, this.record, super.key});

  final ValidLocationReference? location;
  final PropertyInspectionRecord? record;

  @override
  State<PropertyInspectionFormPage> createState() {
    return _PropertyInspectionFormPageState();
  }
}

final class _PropertyInspectionFormPageState
    extends State<PropertyInspectionFormPage> {
  late final TextEditingController _name;
  late final TextEditingController _address;
  late final TextEditingController _price;
  late final TextEditingController _notes;
  late double _rating;
  late int _drainage;
  late int _waterproofing;
  late int _humidity;
  late int _lighting;
  late bool _floodRisk;

  @override
  void initState() {
    super.initState();
    final PropertyInspectionRecord? record = widget.record;
    _name = TextEditingController(text: record?.name ?? '');
    _address = TextEditingController(text: record?.address ?? '');
    _price = TextEditingController(
      text: record != null ? record.price.toString() : '650000',
    );
    _notes = TextEditingController(text: record?.notes ?? '');
    _rating = record?.rating ?? 4.0;
    _drainage = record?.drainage ?? 4;
    _waterproofing = record?.waterproofing ?? 4;
    _humidity = record?.humidity ?? 4;
    _lighting = record?.lighting ?? 4;
    _floodRisk = record?.floodRisk ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _price.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isZh = Localizations.localeOf(context).languageCode == 'zh';
    final String title = isZh ? '新增房产实勘' : 'Add property inspection';
    final String locationText =
        widget.location?.displayName ?? (isZh ? '所选地点' : 'Selected location');
    return Scaffold(
      backgroundColor: _propertyBackground,
      appBar: AppBar(
        backgroundColor: _propertyBackground,
        surfaceTintColor: Colors.transparent,
        title: Text(title),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF1FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.location_on_rounded, color: _propertyBlue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      locationText,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _propertyInk,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _InputField(
              label: isZh ? '房源名称' : 'Property name',
              controller: _name,
            ),
            const SizedBox(height: 12),
            _InputField(label: isZh ? '地址' : 'Address', controller: _address),
            const SizedBox(height: 12),
            _InputField(
              label: isZh ? '价格（RM）' : 'Price (RM)',
              controller: _price,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Text(
              isZh ? '现场评分（1-5）' : 'Inspection score (1-5)',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _propertyInk,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _propertyBorder),
              ),
              child: Column(
                children: <Widget>[
                  Slider(
                    value: _rating,
                    min: 1,
                    max: 5,
                    divisions: 8,
                    activeColor: _propertyBlue,
                    onChanged: (double value) {
                      setState(() {
                        _rating = value;
                      });
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      const Text('1', style: TextStyle(color: _propertyMuted)),
                      Text(
                        _rating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: _propertyBlue,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Text('5', style: TextStyle(color: _propertyMuted)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isZh ? '现场四项评分' : 'Inspection checklist',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _propertyInk,
              ),
            ),
            const SizedBox(height: 8),
            _ScoreRow(
              label: isZh ? '排水' : 'Drainage',
              value: _drainage,
              onChanged: (int value) => setState(() => _drainage = value),
            ),
            _ScoreRow(
              label: isZh ? '防水' : 'Waterproofing',
              value: _waterproofing,
              onChanged: (int value) => setState(() => _waterproofing = value),
            ),
            _ScoreRow(
              label: isZh ? '湿度' : 'Humidity',
              value: _humidity,
              onChanged: (int value) => setState(() => _humidity = value),
            ),
            _ScoreRow(
              label: isZh ? '照明' : 'Lighting',
              value: _lighting,
              onChanged: (int value) => setState(() => _lighting = value),
            ),
            const SizedBox(height: 16),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(isZh ? '水灾迹象' : 'Flood warning signs'),
              value: _floodRisk,
              activeColor: _propertyBlue,
              onChanged: (bool value) => setState(() => _floodRisk = value),
            ),
            const SizedBox(height: 8),
            _InputField(
              label: isZh ? '备注' : 'Notes',
              controller: _notes,
              minLines: 3,
              maxLines: 5,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_rounded),
              label: Text(isZh ? '保存实勘' : 'Save inspection'),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final String name = _name.text.trim();
    final String address = _address.text.trim();
    final String priceText = _price.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (name.isEmpty || address.isEmpty || priceText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Localizations.localeOf(context).languageCode == 'zh'
                ? '请填写房源名称、地址和价格。'
                : 'Please fill in the property name, address and price.',
          ),
        ),
      );
      return;
    }

    final PropertyInspectionRecord record = PropertyInspectionRecord(
      id: 'ins-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      address: address,
      price: int.tryParse(priceText) ?? 0,
      rating: _rating,
      notes: _notes.text.trim(),
      location:
          widget.location ??
          const ValidLocationReference(
            locationId: 'unsaved-location',
            point: GeographicPoint(latitude: 3.0, longitude: 101.0),
            displayName: 'Selected location',
          ),
      createdAt: DateTime.now(),
      drainage: _drainage,
      waterproofing: _waterproofing,
      humidity: _humidity,
      lighting: _lighting,
      floodRisk: _floodRisk,
    );
    Navigator.of(context).pop<PropertyInspectionRecord>(record);
  }
}

final class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _propertyBorder),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _propertyInk,
              ),
            ),
          ),
          DropdownButton<int>(
            value: value,
            items: const <DropdownMenuItem<int>>[
              DropdownMenuItem<int>(value: 1, child: Text('1')),
              DropdownMenuItem<int>(value: 2, child: Text('2')),
              DropdownMenuItem<int>(value: 3, child: Text('3')),
              DropdownMenuItem<int>(value: 4, child: Text('4')),
              DropdownMenuItem<int>(value: 5, child: Text('5')),
            ],
            onChanged: (int? selected) {
              if (selected != null) {
                onChanged(selected);
              }
            },
          ),
        ],
      ),
    );
  }
}

final class _InputField extends StatelessWidget {
  const _InputField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      minLines: minLines,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label),
    );
  }
}
