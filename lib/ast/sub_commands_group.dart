import 'package:sew_ml/ast/parser_element.dart';

class SubCommandsGroup extends ParserElement {

  List<String> subCommands;

  SubCommandsGroup({
    required super.label,
    required this.subCommands,
  });

  static SubCommandsGroup fromJson(Map<String, dynamic> json) {
    List<String> commands = (json['subcommands'] as List).toList().map((e) => e as String).toList();
    return SubCommandsGroup(label: json['label'] as String, subCommands: commands);
  }

  Map<String, Object> toJson() {
    return {
      'label': label,
      'subcommands': subCommands
    };
  }

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