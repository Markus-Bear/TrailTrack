import 'package:flutter/material.dart';

import 'screens/map_screen.dart';

void main() {
  runApp(const TrailTrackApp());
}

class TrailTrackApp extends StatelessWidget {
  const TrailTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrailTrack',
      theme: ThemeData(colorSchemeSeed: const Color(0xFF2E7D32)),
      home: const MapScreen(),
    );
  }
}
