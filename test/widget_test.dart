import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:celenium_wallet/main.dart';

void main() {
  testWidgets('app smoke test builds', (WidgetTester tester) async {
    await tester.pumpWidget(const CenApp());
    // Splash screen has a 900ms delay before routing.
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
