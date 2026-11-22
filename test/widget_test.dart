import 'package:flutter_test/flutter_test.dart';

import 'package:hap/main.dart';

void main() {
  testWidgets('Splash Hap! tampil dengan tombol Mulai',
      (WidgetTester tester) async {
    await tester.pumpWidget(const HapApp());

    expect(find.text('Pesan, ambil, hap!'), findsOneWidget);
    expect(find.text('Mulai'), findsOneWidget);
  });
}
