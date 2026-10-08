import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../models/trail.dart';

/// Line colour for a trail of the given difficulty.
///
/// @param difficulty the trail's difficulty
/// @return the colour to draw it in
Color difficultyColour(Difficulty difficulty) => switch (difficulty) {
  Difficulty.easy => const Color(0xFF2E7D32),
  Difficulty.moderate => const Color(0xFFEF6C00),
  Difficulty.challenging => const Color(0xFFC62828),
  Difficulty.unknown => const Color(0xFF616161),
};

/// Line pattern for a trail of the given difficulty. Each difficulty has its
/// own pattern as well as its own colour, so it can be told apart without
/// colour vision.
///
/// @param difficulty the trail's difficulty
/// @return the pattern to draw it with
StrokePattern difficultyPattern(Difficulty difficulty) => switch (difficulty) {
  // Not const: the dashed constructor's asserts fail in a const context.
  Difficulty.moderate => StrokePattern.dashed(segments: const [12, 8]),
  Difficulty.challenging => const StrokePattern.dotted(spacingFactor: 2),
  Difficulty.easy || Difficulty.unknown => const StrokePattern.solid(),
};
