import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailtrack/screens/map_screen.dart';

void main() {
  testWidgets('shows the map data attribution', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MapScreen()));
    await tester.pump();

    expect(find.textContaining('OpenStreetMap contributors'), findsOneWidget);
    expect(find.textContaining('Sport Ireland (CC BY 4.0)'), findsOneWidget);
  });
}
