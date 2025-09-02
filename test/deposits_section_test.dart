import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neptune/dashboard.dart';

void main() {
  testWidgets('Deposits section shows four deposit options', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DashboardPage(userName: 'Tester', animateScanFab: false)));

    // Scroll to ensure all sections visible if needed
    await tester.pumpAndSettle();

    // We expect at least one 'Deposits' label (there will be two: balance row + section header)
    expect(find.text('Deposits'), findsWidgets);

    // Verify grid key present
    expect(find.byKey(const Key('deposits_quick_grid')), findsOneWidget);

    // Verify each option label
    expect(find.text('Fixed Deposit'), findsOneWidget);
    expect(find.text('Recurring Deposit'), findsOneWidget);
    expect(find.text('Certificates/Forms'), findsOneWidget);
    expect(find.text('Other Services'), findsOneWidget);
  });
}
