
enum RelativeConstraint {
  above,
  below,
  left,
  right,
  alignLeft,
  alignRight,
  alignTop,
  alignBottom,
}

class RelativePlacement {
  final String sourcePartLabel;
  final String targetPartLabel;
  final RelativeConstraint constraint;

  RelativePlacement({
    required this.sourcePartLabel,
    required this.targetPartLabel,
    required this.constraint,
  });
}