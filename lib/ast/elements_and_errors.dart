
import 'package:sew_ml/ast/parser_element.dart';
import 'package:sew_ml/ast/parser_error.dart';

class ElementsAndErrors {
  final List<ParserElement> _elements = [];
  final List<ParserError> _errors = [];

  List<ParserElement> get elements => List.from(_elements);
  List<ParserError> get errors => List.from(_errors);

  void addElement(ParserElement element) {
    _elements.add(element);
  }

  void addAllElements(Iterable<ParserElement> newElements) {
    _elements.addAll(newElements);
  }

  void addError(ParserError error) {
    _errors.add(error);
  }

  void addAllErrors(Iterable<ParserError> errors) {
    _errors.addAll(errors);
  }

  void addAll(ElementsAndErrors other) {
    _elements.addAll(other._elements);
    _errors.addAll(other._errors);
  }
}