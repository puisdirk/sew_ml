import 'package:sew_ml/ast/parser_element.dart';

class SubCommandsGroup extends ParserElement {

  List<String> subCommands;

  SubCommandsGroup({
    required super.label,
    required this.subCommands,
  });

  @override
  void offset(double x, double y) {
    // nothing to do
  }

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is SubCommandsGroup &&
    runtimeType == other.runtimeType &&
    label == other.label &&
    subCommands == other.subCommands;

  @override
  int get hashCode => super.hashCode ^ subCommands.hashCode;
}