
import 'package:sew_ml/ast/coordinate.dart';
import 'package:sew_ml/ast/parser_element.dart';

class QuadraticBezier extends ParserElement {

  Coordinate startPoint;
  Coordinate endPoint;
  Coordinate controlPoint;

  QuadraticBezier({
    required super.label,
    required this.startPoint,
    required this.endPoint,
    required this.controlPoint,
  });

  @override
  void offset(double x, double y) {
    startPoint = startPoint.offset(x, y);
    endPoint = endPoint.offset(x, y);
    controlPoint = controlPoint.offset(x, y);
  }

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is QuadraticBezier &&
    runtimeType == other.runtimeType &&
    label == other.label &&
    startPoint == other.startPoint &&
    endPoint == other.endPoint &&
    controlPoint == other.controlPoint;
  
  @override
  int get hashCode => super.hashCode ^ label.hashCode ^ startPoint.hashCode ^ endPoint.hashCode ^ controlPoint.hashCode;
}