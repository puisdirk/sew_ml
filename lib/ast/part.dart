import 'package:sew_ml/ast/parser_element.dart';

class Part extends ParserElement {

  final List<ParserElement> elements;

  Part({
    required super.label,
    required this.elements,
  });

  @override
  void offset(double x, double y) {
    for (ParserElement element in elements) {
      element.offset(x, y);
    }
  }

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is Part &&
      runtimeType == other.runtimeType &&
      label == other.label &&
      elements == other.elements;

  @override
  int get hashCode => super.hashCode ^ label.hashCode ^ elements.hashCode;
}