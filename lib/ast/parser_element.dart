
abstract class ParserElement {
  String label;

  ParserElement({
    required this.label,  
  });

  void offset(double x, double y);

  @override
  int get hashCode => super.hashCode ^ label.hashCode;

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is ParserElement &&
    runtimeType == other.runtimeType &&
    label == other.label;
}