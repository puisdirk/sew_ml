
import 'package:sew_ml/ast/coordinate.dart';
import 'package:sew_ml/ast/infinite_line.dart';
import 'package:sew_ml/ast/maths_helper.dart';
import 'package:sew_ml/ast/parser_element.dart';

import 'package:vector_math/vector_math_64.dart';

class Line extends ParserElement {
  Coordinate startPoint;
  Coordinate endPoint;

  Line({
    required super.label,
    required this.startPoint,
    required this.endPoint,
  });

  @override
  void offset(double x, double y) {
    startPoint = startPoint.offset(x, y);
    endPoint = endPoint.offset(x, y);
  }

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is Line &&
    label == other.label &&
    runtimeType == other.runtimeType &&
    startPoint == other.startPoint &&
    endPoint == other.endPoint;

  @override
  int get hashCode => super.hashCode ^ startPoint.hashCode ^ endPoint.hashCode;

  double lengthInMM() => MathsHelper.distance(startPoint, endPoint);

  Coordinate middle() => coordAt(0.5);

  Coordinate coordAt(double fraction) => Coordinate(startPoint.x + ((endPoint.x - startPoint.x) * fraction), startPoint.y + (endPoint.y - startPoint.y) * fraction);

  List<Coordinate> intersections(Line otherSegment) {
    return _intersections(otherSegment).map((v) => Coordinate(v.x, v.y)).toList();
  } 

  List<Vector2> _intersections(Line otherSegment) {
    final from = Vector2(startPoint.x, startPoint.y);
    final to = Vector2(endPoint.x, endPoint.y);
    final otherFrom = Vector2(otherSegment.startPoint.x, otherSegment.startPoint.y);
    final otherTo = Vector2(otherSegment.endPoint.x, otherSegment.endPoint.y);

    final result = toInfiniteLine().intersections(otherSegment.toInfiniteLine());
    if (result.isNotEmpty) {
      // The lines are not parallel
      final intersection = result.first;
      if (containsPoint(intersection) &&
          otherSegment.containsPoint(intersection)) {
        // The intersection point is on both line segments
        return result;
      }
    } else {
      // In here we know that the lines are parallel
      final overlaps = {
        if (otherSegment.containsPoint(from)) from,
        if (otherSegment.containsPoint(to)) to,
        if (containsPoint(otherFrom)) otherFrom,
        if (containsPoint(otherTo)) otherTo,
      };
      if (overlaps.isNotEmpty) {
        final sum = Vector2.zero();
        overlaps.forEach(sum.add);
        return [sum..scale(1 / overlaps.length)];
      }
    }

    return [];
  }

  InfiniteLine toInfiniteLine() => InfiniteLine.fromCoordinates(startPoint, endPoint);

  bool containsPoint(Vector2 point, {double epsilon = 0.000001}) {
    final from = Vector2(startPoint.x, startPoint.y);
    final to = Vector2(endPoint.x, endPoint.y);

    final delta = to - from;
    final crossProduct =
        (point.y - from.y) * delta.x - (point.x - from.x) * delta.y;

    // compare versus epsilon for floating point values
    if (crossProduct.abs() > epsilon) {
      return false;
    }

    final dotProduct =
        (point.x - from.x) * delta.x + (point.y - from.y) * delta.y;
    if (dotProduct < 0) {
      return false;
    }

    final squaredLength = from.distanceToSquared(to);
    if (dotProduct > squaredLength) {
      return false;
    }

    return true;
  }
}