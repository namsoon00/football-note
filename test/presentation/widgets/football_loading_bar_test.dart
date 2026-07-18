import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/presentation/widgets/football_loading_bar.dart';

void main() {
  testWidgets('football loading bar renders a soccer ball indicator', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: FootballLoadingBar(),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.sports_soccer), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 750));
    expect(tester.takeException(), isNull);
  });
}
