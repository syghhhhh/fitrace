// This is a basic Flutter widget test.
//
// To perform an interaction with a widget test, use the WidgetTester
// utility in the flutter_test package.

import 'package:flutter_test/flutter_test.dart';

import 'package:fitrace/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FitraceApp());

    // Verify that the app loads with the correct title
    expect(find.text('Fitrace'), findsOneWidget);
  });
}