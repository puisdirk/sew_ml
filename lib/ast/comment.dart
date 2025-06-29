
import 'package:sew_ml/ast/parser_element.dart';

class Comment extends ParserElement {
  String comment;

  Comment({
    required this.comment
  }) :super(label: '');

  @override
  void offset(double x, double y) {
    // nothing to do
  }
}