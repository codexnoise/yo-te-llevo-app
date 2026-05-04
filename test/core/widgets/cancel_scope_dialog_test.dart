import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yo_te_llevo/core/widgets/cancel_scope_dialog.dart';
import 'package:yo_te_llevo/features/trips/domain/entities/cancel_scope.dart';

void main() {
  Future<CancelScope?> showAndCapture(
    WidgetTester tester, {
    required bool showSeriesOption,
  }) async {
    CancelScope? captured;
    bool finished = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () async {
                  captured = await showCancelScopeDialog(
                    context,
                    showSeriesOption: showSeriesOption,
                  );
                  finished = true;
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(finished, isFalse);
    return Future.delayed(const Duration(milliseconds: 0)).then((_) async {
      // Devolvemos el captor — el caller usa pumpAndSettle tras cada tap
      // y luego lee captured.
      return captured;
    });
  }

  testWidgets('recurring: muestra ambas opciones y devuelve occurrence',
      (tester) async {
    CancelScope? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await showCancelScopeDialog(context);
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Sólo esta fecha'), findsOneWidget);
    expect(find.text('Toda la serie'), findsOneWidget);
    await tester.tap(find.text('Sólo esta fecha'));
    await tester.pumpAndSettle();
    expect(result, CancelScope.occurrence);
  });

  testWidgets('recurring: tap "Toda la serie" devuelve series',
      (tester) async {
    CancelScope? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await showCancelScopeDialog(context);
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Toda la serie'));
    await tester.pumpAndSettle();
    expect(result, CancelScope.series);
  });

  testWidgets('oneTime: muestra solo Confirmar/Volver', (tester) async {
    CancelScope? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await showCancelScopeDialog(
                    context,
                    showSeriesOption: false,
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Sólo esta fecha'), findsNothing);
    expect(find.text('Toda la serie'), findsNothing);
    expect(find.text('Confirmar'), findsOneWidget);
    expect(find.text('Volver'), findsOneWidget);
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();
    expect(result, CancelScope.occurrence);
  });

  testWidgets('"Volver" devuelve null', (tester) async {
    CancelScope? result = CancelScope.series;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await showCancelScopeDialog(context);
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Volver'));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });
}
