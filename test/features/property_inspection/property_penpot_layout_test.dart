import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/features/map_location/map_location.dart';
import 'package:locatemy/features/property_inspection/property_inspection.dart';
import 'package:locatemy/l10n/app_localizations.dart';

import 'property_service_test.dart'
    show MemoryPropertyStore, UnavailablePropertyRisk;

const ValidLocationReference location = ValidLocationReference(
  locationId: 'test-place',
  point: GeographicPoint(latitude: 3.14, longitude: 101.69),
);

PropertyInspectionRecord comparisonRecord(String id, {bool available = true}) {
  return PropertyInspectionRecord(
    id: id,
    draft: PropertyInspectionDraft(
      name: 'Property $id',
      address: 'Petaling Jaya',
      price: 520000,
      location: location,
      drainage: 4,
      waterproofing: 4,
      humidity: 3,
      lighting: 5,
    ),
    createdAt: DateTime.utc(2026, 9, 18),
    snapshot: PropertyRiskSnapshot(<String, Object?>{
      'snapshot_availability': available ? 'available' : 'unavailable',
      'reporting_state': 'Selangor',
      'safety_index': 74,
      'hazard_pending_count': available ? 0 : 99,
      'snapshot_captured_at': '2026-09-18T08:00:00Z',
      'safety_source_year': 2024,
    }),
  );
}

Future<void> capture(
  WidgetTester tester,
  GlobalKey boundary,
  String name,
) async {
  if (!const bool.fromEnvironment('PROPERTY_UI_CAPTURE')) {
    return;
  }
  await tester.runAsync(() async {
    final RenderRepaintBoundary render =
        boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final ui.Image image = await render.toImage();
    final ByteData? data = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    final Directory directory = Directory('build/property-ui-evidence');
    await directory.create(recursive: true);
    await File('${directory.path}/$name.png')
        .writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final FontLoader loader = FontLoader('SourceSansPro');
    for (final String weight in <String>['Regular', 'Semibold', 'Bold']) {
      loader.addFont(
        rootBundle.load(
          'assets/fonts/source_sans_pro/SourceSansPro-$weight.ttf',
        ),
      );
    }
    await loader.load();
    final FontLoader icons = FontLoader('MaterialIcons');
    icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    
    if (const bool.fromEnvironment('PROPERTY_UI_CAPTURE')) {
      final File cjkFont = File(
        '/usr/share/fonts/noto-cjk/NotoSansCJK-Regular.ttc',
      );
      if (await cjkFont.exists()) {
        final FontLoader cjk = FontLoader('PropertyQaCjk');
        cjk.addFont(
          cjkFont.readAsBytes().then((Uint8List bytes) {
            return ByteData.sublistView(bytes);
          }),
        );
        await cjk.load();
      }
    }
  });
  for (final String language in <String>['en', 'zh']) {
    for (final bool large in <bool>[false, true]) {
      for (final String page in <String>['form', 'detail', 'comparison']) {
        testWidgets(
          '$page $language ${large ? '320dp 200%' : '390dp'} preserves readable content',
          (WidgetTester tester) async {
            await tester.binding.setSurfaceSize(Size(large ? 320 : 390, 844));
            addTearDown(() {
              return tester.binding.setSurfaceSize(null);
            });
            final MemoryPropertyStore store = MemoryPropertyStore();
            final PropertyInspectionService service = PropertyInspectionService(
              store: store,
              risk: UnavailablePropertyRisk(),
            );
            final PropertyInspectionRecord record = await service.save(
              comparisonRecord('A').draft,
            );
            Widget home;
            if (page == 'form') {
              home = PropertyInspectionFormPage(
                service: service,
                record: record,
              );
            } else if (page == 'detail') {
              home = PropertyInspectionDetailPage(
                service: service,
                id: record.id,
              );
            } else {
              home = PropertyInspectionComparisonPage(
                records: <PropertyInspectionRecord>[
                  comparisonRecord('A'),
                  comparisonRecord('B'),
                  comparisonRecord('C', available: false),
                ],
              );
            }
            final GlobalKey boundary = GlobalKey();
            await tester.pumpWidget(
              MaterialApp(
                locale: Locale(language),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                theme: ThemeData(
                  fontFamily: 'SourceSansPro',
                  fontFamilyFallback: const <String>['PropertyQaCjk'],
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: const Color(0xFF155EEF),
                  ),
                  appBarTheme: const AppBarTheme(
                    backgroundColor: Color(0xFFF5F7FA),
                    titleTextStyle: TextStyle(
                      fontFamily: 'SourceSansPro',
                      fontFamilyFallback: <String>['PropertyQaCjk'],
                      fontSize: 20,
                      color: Color(0xFF172033),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                builder: (BuildContext context, Widget? child) {
                  return MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(textScaler: TextScaler.linear(large ? 2 : 1)),
                    child: RepaintBoundary(key: boundary, child: child),
                  );
                },
                home: home,
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            await capture(
              tester,
              boundary,
              '$page-$language-${large ? 'large' : 'normal'}',
            );
            if (page == 'comparison') {
              
              expect(find.text('99'), findsNothing);
              expect(find.text('0'), findsNWidgets(2));
              expect(find.text('—'), findsNWidgets(3));
              await tester.dragFrom(
                const Offset(270, 350),
                const Offset(-220, 0),
              );
              await tester.pumpAndSettle();
              await tester.drag(find.byType(ListView), const Offset(0, -1600));
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
            } else if (page == 'detail') {
              await tester.scrollUntilVisible(
                find.text(language == 'zh' ? '移入回收站' : 'Move to recycle bin'),
                300,
                scrollable: find.byType(Scrollable).first,
                maxScrolls: 40,
              );
              expect(tester.takeException(), isNull);
            } else {
              
              final Finder lighting = find.byType(DropdownButton<int>).last;
              await tester.scrollUntilVisible(
                lighting,
                250,
                scrollable: find.byType(Scrollable).first,
                maxScrolls: 40,
              );
              await tester.ensureVisible(lighting);
              await tester.pumpAndSettle();
              await tester.tap(lighting);
              await tester.pumpAndSettle();
              await tester.tap(find.text('★ 2').last);
              await tester.pumpAndSettle();
              final String save = language == 'zh' ? '保存实勘' : 'Save inspection';
              await tester.scrollUntilVisible(
                find.text(save),
                250,
                scrollable: find.byType(Scrollable).first,
                maxScrolls: 40,
              );
              await tester.ensureVisible(find.text(save));
              await tester.pumpAndSettle();
              await tester.tap(find.text(save));
              await tester.pumpAndSettle();
              final PropertyInspectionRecord saved =
                  (await service.list()).single;
              expect(saved.draft.lighting, 2);
              expect(saved.rating, 3.25);
              expect(tester.takeException(), isNull);
            }
          },
        );
      }
    }
  }
}
