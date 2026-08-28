import 'package:flutter_test/flutter_test.dart';
import 'package:locate_my/main.dart';

void main() {
  testWidgets('LocateMyApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const LocateMyApp());

    // Verify that the title appears.
    expect(find.text('宏观时机仪表盘'), findsOneWidget);
  });
}
