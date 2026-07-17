// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carimakan/main.dart';
import 'package:carimakan/features/profile/presentation/widgets/menu_item.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('ProfileMenuItem renders correctly', (WidgetTester tester) async {
    // Build the ProfileMenuItem widget
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfileMenuItem(
            icon: Icons.person,
            title: 'Test Menu',
            showDivider: true,
            onTap: () {},
          ),
        ),
      ),
    );

    // Verify that the title text is displayed
    expect(find.text('Test Menu'), findsOneWidget);

    // Verify that the icon is displayed
    expect(find.byIcon(Icons.person), findsOneWidget);

    // Verify that the forward arrow icon is displayed
    expect(find.byIcon(Icons.arrow_forward_ios), findsOneWidget);
  });
}
