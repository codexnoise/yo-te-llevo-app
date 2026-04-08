import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:yo_te_llevo/app.dart';

void main() {
  testWidgets('App renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    // Verify the app renders
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
