// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chintufy/main.dart';

void main() {
  group('Counter App Widget Tests', () {
    testWidgets('Counter starts at 0 and increments correctly', 
      (WidgetTester tester) async {
      // Build our app and trigger a frame
      await tester.pumpWidget(
      MyApp(
          
        ),
      );

      // Verify initial state
      expect(find.text('0'), findsOneWidget);
      expect(find.text('1'), findsNothing);
      expect(find.byIcon(Icons.add), findsOneWidget);

      // Test increment functionality
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      // Verify counter incremented
      expect(find.text('0'), findsNothing);
      expect(find.text('1'), findsOneWidget);

      // Test another increment
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      // Verify counter incremented again
      expect(find.text('1'), findsNothing);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('App initializes with correct message', 
      (WidgetTester tester) async {
      await tester.pumpWidget(
        MyApp(
        
        ),
      );

      // Verify initialization parameters
      expect(find.text('check'), findsOneWidget);
    });
  });
}
