
import 'dart:math';

import 'package:sew_ml/ast/coordinate.dart';

class MathsHelper {

  static double degreesToRadians(double degrees) => degrees * (pi / 180.0);
  static double radiansToDegrees(double radians) => radians * (180.0 / pi);

  static double distance(Coordinate p0, Coordinate p1) => sqrt(pow(((p1.x - p0.x).abs()), 2.0) + pow(((p1.y - p0.y).abs()), 2.0));

  // Given a start coordinate, calculate a new coordinate at distance away in a given direction
  static Coordinate relativepointatangle(Coordinate p0, double distance, double angleInRadians) => Coordinate(p0.x + (distance * cos(angleInRadians)), p0.y + (distance * sin(angleInRadians)));

  // Given two coordinates, get the coordinate in the middle of those two
  static Coordinate middleOfLine(Coordinate p0, Coordinate p1) => Coordinate((p0.x + p1.x) / 2.0, (p0.y + p1.y) / 2.0);

  // Get the angle between two coordinates. (see https://www.mathsisfun.com/algebra/trig-finding-angle-right-triangle.html)
  static double angleOfLine(Coordinate p0, Coordinate p1) {
    final double opposite = p1.y - p0.y;
    final double adjacent = p1.x - p0.x;
    if (adjacent == 0) {
      return p0.x >= p1.x ? pi / 2.0 : (pi * 3.0) / 2.0; // 90 or 270
    }
    return atan(opposite / adjacent);
  }

  static double adjacentFromHypotenuseAndOpposite(double hypotenuse, double opposite) {
    // a2 + b2 = c2, so opp2 + adj2 = hyp2 => adj2 = hyp2 - opp2
    // could also do cos(asin(opposite/hypotenuse)) * hypotenuse?
    return sqrt(pow(hypotenuse, 2) - pow(opposite, 2));
  }
}