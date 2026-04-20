import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yo_te_llevo/features/matching/presentation/screens/search_trip_screen.dart';

void main() {
  group('SearchTripScreen', () {
    testWidgets('submit button is disabled when no inputs are provided',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: SearchTripScreen()),
        ),
      );
      await tester.pump();

      final submit = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Buscar conductores'),
      );
      expect(submit.onPressed, isNull);
    });

    testWidgets('day chips render for the 7 weekdays', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: SearchTripScreen()),
        ),
      );
      await tester.pump();

      for (final label in ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom']) {
        expect(find.widgetWithText(FilterChip, label), findsOneWidget);
      }
    });

    testWidgets('tapping a day chip toggles its selected state',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: SearchTripScreen()),
        ),
      );
      await tester.pump();

      FilterChip chip() => tester.widget<FilterChip>(
            find.widgetWithText(FilterChip, 'Lun'),
          );

      expect(chip().selected, isFalse);

      await tester.tap(find.widgetWithText(FilterChip, 'Lun'));
      await tester.pump();

      expect(chip().selected, isTrue);
    });
  });
}
