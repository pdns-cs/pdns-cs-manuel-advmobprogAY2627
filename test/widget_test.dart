import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:manuel_mobile/main.dart';

void main() {
  testWidgets('Counter increments and settings page toggles app theme', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => ThemeModel(),
        child: const StateManagementActivity(),
      ),
    );

    expect(find.text('Ephemeral State Example'), findsOneWidget);
    expect(
      find.text('You have pushed the button this many times:'),
      findsOneWidget,
    );
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);
    expect(find.byTooltip('Change theme'), findsOneWidget);
    expect(find.byType(Switch), findsNothing);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).theme?.brightness,
      Brightness.light,
    );

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.byTooltip('Change theme'));
    await tester.pumpAndSettle();

    expect(find.text('App State Example'), findsOneWidget);
    expect(find.text('Light Mode'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);

    await tester.tap(find.text('Dark').last);
    await tester.pumpAndSettle();

    expect(find.text('Light Mode'), findsNothing);
    expect(find.text('Dark Mode'), findsOneWidget);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).theme?.brightness,
      Brightness.dark,
    );
  });
}
