import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reusable_checklists/core/utils/responsive_utils.dart';

void main() {
  group('ResponsiveUtils', () {
    Widget buildWithWidth(double width) {
      return MediaQuery(
        data: MediaQueryData(size: Size(width, 800)),
        child: Builder(
          builder: (context) {
            return Column(
              children: [
                Text('compact:${ResponsiveUtils.isCompact(context)}'),
                Text('medium:${ResponsiveUtils.isMedium(context)}'),
                Text('expanded:${ResponsiveUtils.isExpanded(context)}'),
              ],
            );
          },
        ),
      );
    }

    testWidgets('isMedium returns true for medium width', (tester) async {
      await tester.pumpWidget(MaterialApp(home: buildWithWidth(700)));

      expect(find.text('compact:false'), findsOneWidget);
      expect(find.text('medium:true'), findsOneWidget);
      expect(find.text('expanded:false'), findsOneWidget);
    });

    testWidgets('isCompact returns true for narrow width', (tester) async {
      await tester.pumpWidget(MaterialApp(home: buildWithWidth(400)));

      expect(find.text('compact:true'), findsOneWidget);
      expect(find.text('medium:false'), findsOneWidget);
      expect(find.text('expanded:false'), findsOneWidget);
    });

    testWidgets('isExpanded returns true for wide width', (tester) async {
      await tester.pumpWidget(MaterialApp(home: buildWithWidth(900)));

      expect(find.text('compact:false'), findsOneWidget);
      expect(find.text('medium:false'), findsOneWidget);
      expect(find.text('expanded:true'), findsOneWidget);
    });

    testWidgets('boundary: compact edge (599)', (tester) async {
      await tester.pumpWidget(MaterialApp(home: buildWithWidth(599)));

      expect(find.text('compact:true'), findsOneWidget);
    });

    testWidgets('boundary: medium starts (600)', (tester) async {
      await tester.pumpWidget(MaterialApp(home: buildWithWidth(600)));

      expect(find.text('compact:false'), findsOneWidget);
      expect(find.text('medium:true'), findsOneWidget);
    });

    testWidgets('boundary: medium edge (839)', (tester) async {
      await tester.pumpWidget(MaterialApp(home: buildWithWidth(839)));

      expect(find.text('medium:true'), findsOneWidget);
    });

    testWidgets('boundary: expanded starts (840)', (tester) async {
      await tester.pumpWidget(MaterialApp(home: buildWithWidth(840)));

      expect(find.text('expanded:true'), findsOneWidget);
    });
  });
}