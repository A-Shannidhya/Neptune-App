import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neptune/dashboard.dart';

void main() {
  testWidgets('Loans section quick grid shows first 8; More sheet shows remaining', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DashboardPage(userName: 'Tester', animateScanFab: false)));
    await tester.pumpAndSettle();

    // Expect at least one Loans label (balance + section header)
    expect(find.text('Loans'), findsWidgets);

    // Grid present
    final gridFinder = find.byKey(const Key('loans_quick_grid'));
    expect(gridFinder, findsOneWidget);

    // Quick grid loan labels (first 8)
    const quickLoanLabels = [
      'Instant Overdraft',
      'Loan details',
      'Loan Repayment',
      'Loan Account Statement',
      'Loan Calculator',
      'Pre-Close Loan against Deposit',
      'Apply edu-loan',
      'personal loan',
    ];
    for (final l in quickLoanLabels) {
      expect(find.text(l), findsOneWidget, reason: 'Missing quick loan option: $l');
    }

    // Ensure car loan & gold loan not yet visible
    expect(find.text('car loan'), findsNothing);
    expect(find.text('gold loan'), findsNothing);

    // Scroll and open More sheet
    final moreFinder = find.byKey(const Key('loans_more_button'));
    await tester.scrollUntilVisible(
      moreFinder,
      300.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(moreFinder, warnIfMissed: false);
    await tester.pumpAndSettle();

    // Extra options now visible
    expect(find.text('car loan'), findsOneWidget);
    expect(find.text('gold loan'), findsOneWidget);
    expect(find.text('Track Loan Application'), findsOneWidget);
  });
}
