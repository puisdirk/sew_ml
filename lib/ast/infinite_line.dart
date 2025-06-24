
import 'package:sew_ml/ast/coordinate.dart';
import 'package:vector_math/vector_math_64.dart';

/// An infinite line on the 2D Cartesian space, represented in the form
/// of ax + by = c.
class InfiniteLine {
  final double a;
  final double b;
  final double c;

  const InfiniteLine(this.a, this.b, this.c);

  InfiniteLine.fromCoordinates(Coordinate p1, Coordinate p2) : this(
    p2.y - p1.y,
    p1.x - p2.x,
    p2.y * p1.x - p1.y * p2.x,
  );

  List<Vector2> intersections(InfiniteLine other) {
    final determinant = a * other.b - other.a * b;
    if (determinant == 0) {
      // the lines are parallel. no intersections
      return [];
    }

    return [
      Vector2(
        (other.b * c - b * other.c) / determinant, 
        (a * other.c - other.a * c) / determinant,
      )
    ];
  }
}