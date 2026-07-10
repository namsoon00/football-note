import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_note/presentation/utils/pdf_export.dart';

void main() {
  testWidgets('captureWidgetPng captures a fixed-size widget as png', (
    tester,
  ) async {
    late BuildContext capturedContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final bytes = await tester.runAsync(
      () => captureWidgetPng(
        capturedContext,
        size: const Size(240, 120),
        pixelRatio: 1,
        child: Container(color: Colors.red),
      ),
    );

    expect(bytes, isNotNull);
    expect(bytes, isNotEmpty);
    expect(bytes!.take(_pngSignature.length).toList(), _pngSignature);
  });
}

const List<int> _pngSignature = <int>[137, 80, 78, 71, 13, 10, 26, 10];
