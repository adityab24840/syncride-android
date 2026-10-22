import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:syncride/ui/home_screen.dart';

void main() {
  testWidgets('Home screen shows create/join actions', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    expect(find.text('Create trip'), findsOneWidget);
    expect(find.text('Join trip'), findsOneWidget);
  });
}
