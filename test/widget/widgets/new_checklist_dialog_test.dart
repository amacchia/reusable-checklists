import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reusable_checklists/core/constants/app_strings.dart';
import 'package:reusable_checklists/views/widgets/new_checklist_dialog.dart';

void main() {
  group('NewChecklistDialog', () {
    testWidgets('renders title and input', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const NewChecklistDialog(),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final textField = tester.widget<TextField>(find.byType(TextField)); 

      expect(find.text(AppStrings.newChecklist), findsOneWidget);
      expect(find.text(AppStrings.cancel), findsOneWidget);
      expect(find.text(AppStrings.create), findsOneWidget);
      expect(textField.textCapitalization, TextCapitalization.words);
    });

    testWidgets('create button disabled when text is empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const NewChecklistDialog(),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final createButton = tester.widget<TextButton>(
        find.widgetWithText(TextButton, AppStrings.create),
      );
      expect(createButton.onPressed, isNull);
    });

    testWidgets('create button enabled after entering text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const NewChecklistDialog(),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'My List');
      await tester.pump();

      final createButton = tester.widget<TextButton>(
        find.widgetWithText(TextButton, AppStrings.create),
      );
      expect(createButton.onPressed, isNotNull);
    });

    testWidgets('returns entered text when create is tapped', (tester) async {
      String? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  result = await showDialog<String>(
                    context: context,
                    builder: (_) => const NewChecklistDialog(),
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

      await tester.enterText(find.byType(TextField), 'My List');
      await tester.pump();
      await tester.tap(find.text(AppStrings.create));
      await tester.pumpAndSettle();

      expect(result, 'My List');
    });

    testWidgets('returns null when cancel is tapped', (tester) async {
      String? result = 'initial';
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  result = await showDialog<String>(
                    context: context,
                    builder: (_) => const NewChecklistDialog(),
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
                    builder: (_) => const NewChecklistDialog(),
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

      await tester.enterText(find.byType(TextField), 'Quick List');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(result, 'Quick List');
    });
  });
}
