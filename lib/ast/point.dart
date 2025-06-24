
import 'package:sew_ml/ast/coordinate.dart';
import 'package:sew_ml/ast/parser_element.dart';

class Point extends ParserElement {
  Coordinate coordinate;

  Point({
    required super.label,
    required this.coordinate,
  });

  @override
  void offset(double x, double y) {
    coordinate = coordinate.offset(x, y);
  }

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is Point &&
    runtimeType == other.runtimeType &&
    label == other.label &&
    coordinate == other.coordinate;

  @override
  int get hashCode => super.hashCode ^ label.hashCode ^ coordinate.hashCode;
}