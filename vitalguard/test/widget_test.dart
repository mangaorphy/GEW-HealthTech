// VitalGuard Widget Tests

import 'package:flutter_test/flutter_test.dart';

import 'package:vitalguard/main.dart';

void main() {
  testWidgets('VitalGuard app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const VitalGuardApp());

    // Verify that the home page loads with the title
    expect(find.text('Your Personal'), findsOneWidget);
    expect(find.text('Life Guardian'), findsOneWidget);

    // Verify Start Monitoring button exists
    expect(find.text('Start Monitoring'), findsOneWidget);
  });
}
