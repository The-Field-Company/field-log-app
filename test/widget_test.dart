import 'package:flutter_test/flutter_test.dart';

import 'package:fieldlog_mobile/main.dart';

void main() {
  testWidgets('App renders entry screen', (WidgetTester tester) async {
    await tester.pumpWidget(const FieldLogApp(initialRoute: '/login'));
    expect(find.text('FieldLog'), findsOneWidget);
    expect(find.text('Load Form'), findsOneWidget);
  });
}
