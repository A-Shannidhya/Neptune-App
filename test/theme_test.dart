import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neptune/main.dart';
import 'package:neptune/theme.dart';

void main() {
  testWidgets('NeptuneTheme light primary color is applied', (tester) async {
    await tester.pumpWidget(const MyApp());
    // Advance splash to reach home so a Scaffold exists.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    // Find a widget to get context.
    final context = tester.element(find.byType(Scaffold));
    final scheme = Theme.of(context).colorScheme;
    expect(scheme.primary, NeptuneTheme.light().colorScheme.primary);
    expect(scheme.primary.value, equals(0xFF1565C0));
  });
}

