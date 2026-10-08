import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailtrack/models/trail.dart';
import 'package:trailtrack/widgets/difficulty_style.dart';

void main() {
  test('each difficulty has its own colour', () {
    final colours = Difficulty.values.map(difficultyColour).toSet();

    expect(colours, hasLength(Difficulty.values.length));
  });

  test('easy is solid, moderate dashed and challenging dotted', () {
    expect(difficultyPattern(Difficulty.easy), const StrokePattern.solid());
    expect(difficultyPattern(Difficulty.moderate).segments, isNotNull);
    expect(difficultyPattern(Difficulty.challenging).spacingFactor, isNotNull);
  });
}
