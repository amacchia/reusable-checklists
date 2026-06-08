import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reusable_checklists/core/constants/app_strings.dart';
import 'package:reusable_checklists/views/widgets/text_input_dialog.dart';

void main() {
  group('TextInputDialog', () {
    testWidgets('submits on keyboard submit', (tester) async {
      String? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  result = await showDialog<String>(
                    context: context,
                    builder: (_) => const TextInputDialog(
                      title: 'Test',
                      hint: 'Enter value',
                      submitLabel: 'OK',
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(result, 'Hello');
    });

    testWidgets('pre-populates with initialValue', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const TextInputDialog(
                    title: 'Rename',
                    hint: 'Name',
                    submitLabel: 'Save',
                    initialValue: 'Existing',
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(tester.widget<TextField>(find.byType(TextField)).controller?.text,
          'Existing');
    });

    testWidgets('cancel dismisses dialog', (tester) async {
      String? result = 'initial';
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  result = await showDialog<String>(
                    context: context,
                    builder: (_) => const TextInputDialog(
                      title: 'Test',
                      hint: 'Enter',
                      submitLabel: 'OK',
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.cancel));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });

    testWidgets('submit button disabled when text is empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const TextInputDialog(
                    title: 'Test',
                    hint: 'Enter',
                    submitLabel: 'OK',
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final submitButton = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'OK'),
      );
      expect(submitButton.onPressed, isNull);
    });

    testWidgets('submit button enabled after entering text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const TextInputDialog(
                    title: 'Test',
                    hint: 'Enter',
                    submitLabel: 'OK',
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Some text');
      await tester.pump();

      final submitButton = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'OK'),
      );
      expect(submitButton.onPressed, isNotNull);
    });

    testWidgets('does not submit whitespace-only text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const TextInputDialog(
                    title: 'Test',
                    hint: 'Enter',
                    submitLabel: 'OK',
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '   ');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Dialog should still be showing because whitespace is trimmed to empty.
      expect(find.byType(TextInputDialog), findsOneWidget);
    });
  });
}