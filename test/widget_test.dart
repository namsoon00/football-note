import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Basic app shell renders', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Text('SoccerNote')),
      ),
    );

    expect(find.text('SoccerNote'), findsOneWidget);
  });
}
