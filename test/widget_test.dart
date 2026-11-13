import 'package:flutter_test/flutter_test.dart';

import 'package:hap/main.dart';

void main() {
  testWidgets('Hap! branding is displayed', (WidgetTester tester) async {
    await tester.pumpWidget(const HapApp());

    expect(find.text('Hap!'), findsOneWidget);
  });
}
