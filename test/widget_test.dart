import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aurabeat/main.dart';

void main() {
  testWidgets('AuraBeatApp smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const AuraBeatApp());
    expect(find.text('Aura Beat'), findsWidgets);
  });
}
