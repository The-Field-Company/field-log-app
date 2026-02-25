import 'package:flutter_test/flutter_test.dart';

import 'package:fieldlog_mobile/main.dart';

void main() {
  testWidgets('App renders login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const FieldLogApp(initialRoute: '/login'));
    expect(find.text('Scientific Field Data Collection'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
