import 'package:flutter_test/flutter_test.dart';

import 'package:ga_laundry_app/frontend/app.dart';

void main() {
  testWidgets('G A Laundry Shop app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const GALaundryAppContainer());
    expect(find.byType(GALaundryAppContainer), findsOneWidget);
  });
}
