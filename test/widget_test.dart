import 'package:flutter_test/flutter_test.dart';
import 'package:locatemy/main.dart';

void main() {
  testWidgets('shows the LocateMY home page', (WidgetTester tester) async {
    await tester.pumpWidget(const LocateMyApp());

    expect(find.text('LocateMY'), findsOneWidget);
    expect(find.text('LocateMY is ready.'), findsOneWidget);
  });
}
