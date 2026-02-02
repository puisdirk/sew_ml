import 'package:sew_ml/ast/coordinate.dart';
import 'package:sew_ml/ast/decoration.dart';
import 'package:sew_ml/ast/line.dart';
import 'package:sew_ml/ast/point.dart';
import 'package:sew_ml/ast/quadratic_bezier.dart';

enum DecorationMeasurementType {
  free,
  horizontal,
  vertical
}

enum DecorationMeasurementUnit {
  cm,
  mm,
  inches
}

class DecorationMeasurement extends Decoration {
  // A layoutmeasurement can be between two points, along a line, or along a set of curves
  final Coordinate? startCoord;
  final Coordinate? endCoord;
  final List<QuadraticBezier>? _curves;
  final DecorationMeasurementType decorationMeasurementType;
  final DecorationMeasurementUnit decorationMeasurementUnit;
  final bool fromPoints;
  final bool fromLine;
  final bool fromCurves;

  DecorationMeasurement.fromPoints({
    required super.label,
    required Point startPoint,
    required Point endPoint,
    required this.decorationMeasurementType,
    required this.decorationMeasurementUnit,
  }) : fromPoints = true, fromLine = false, fromCurves = false, startCoord = startPoint.coordinate, endCoord = endPoint.coordinate, _curves = null;

  DecorationMeasurement.fromLine({
    required super.label,
    required Line line,
    required this.decorationMeasurementType,
    required this.decorationMeasurementUnit,
  }) : fromPoints = false, fromLine = true, fromCurves = false, startCoord = line.startPoint, endCoord = line.endPoint, _curves = null;

  DecorationMeasurement.fromCurves({
    required super.label,
    required List<QuadraticBezier> curves,
    required this.decorationMeasurementType,
    required this.decorationMeasurementUnit,
  }) : fromPoints = false, fromLine = false, fromCurves = true, startCoord = curves.first.startPoint, endCoord = curves.last.endPoint, _curves = List.from(curves);

  @override
  void offset(double x, double y) {
    // TODO: implement offset
  }
}