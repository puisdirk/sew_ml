
import 'package:sew_ml/ast/parser_element.dart';

class Measurement extends ParserElement {
  final double valueInMMorRad;

  Measurement({
    required super.label,
    required this.valueInMMorRad,
  });

  @override
  void offset(double x, double y) {
    // nothing to do
  }

  @override
  int get hashCode => super.hashCode ^ label.hashCode ^ valueInMMorRad.hashCode;

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is Measurement &&
      runtimeType == other.runtimeType &&
      label == other.label &&
      valueInMMorRad == other.valueInMMorRad;
      
}